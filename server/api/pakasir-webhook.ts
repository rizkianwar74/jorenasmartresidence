// ─────────────────────────────────────────────────────────────────────────────
// Vercel serverless function — webhook receiver Pakasir.
//
// Alur:
//   1. Pakasir POST ke endpoint ini setelah pembayaran QRIS selesai.
//   2. Payload webhook TIDAK langsung dipercaya — diverifikasi ulang ke API
//      transactiondetail Pakasir pakai PAKASIR_API_KEY (env var, hanya hidup
//      di server ini, tidak pernah dikirim/di-bundle ke app Flutter).
//   3. Kalau amount & order_id cocok dengan hasil verifikasi, DAN status
//      benar-benar "completed" → cari semua dokumen Firestore collection
//      `tagihan` dengan orderId tsb, tandai lunas lewat Firebase Admin SDK
//      (service account — bypass Firestore Security Rules, karena ini
//      server tepercaya, bukan klien).
//
// Referensi format webhook & API Pakasir: https://pakasir.com/p/docs
// ─────────────────────────────────────────────────────────────────────────────

import type { VercelRequest, VercelResponse } from '@vercel/node';
// Inisialisasi Firebase Admin dipindahkan ke ../lib/firebase agar dipakai
// bersama dengan endpoint send-notification — kalau tiap endpoint memanggil
// initializeApp() sendiri, Firebase melempar error pada invoke yang warm.
import { db } from '../lib/firebase';
import { sendPush } from '../lib/onesignal';

// ── Nama bulan singkat — HARUS sama persis dengan bulanSingkatList di Dart ──
// (lib/features/pembayaran/models/tagihan_model.dart) supaya format
// tanggalBayar konsisten antara tulisan server ini dan tulisan client admin.
const BULAN_SINGKAT = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

interface PakasirWebhookPayload {
  amount: number;
  order_id: string;
  project: string;
  status: string;
  payment_method?: string;
  completed_at?: string;
}

interface PakasirTransactionDetail {
  transaction?: {
    status?: string;
    amount?: number;
    order_id?: string;
    payment_method?: string;
    completed_at?: string;
  };
}

// ── Format tanggal "13 Jul 2026" di zona waktu Asia/Jakarta ──────────────────
function formatTanggalBayar(dateIso: string | undefined): string {
  const date = dateIso ? new Date(dateIso) : new Date();
  // Ambil komponen tanggal versi Asia/Jakarta, bukan waktu server.
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Asia/Jakarta',
    year: 'numeric',
    month: 'numeric',
    day: 'numeric',
  }).formatToParts(date);

  const day = parts.find((p) => p.type === 'day')!.value;
  const monthNum = Number(parts.find((p) => p.type === 'month')!.value);
  const year = parts.find((p) => p.type === 'year')!.value;

  return `${Number(day)} ${BULAN_SINGKAT[monthNum - 1]} ${year}`;
}

// ── Verifikasi ulang transaksi ke Pakasir API (bukan percaya payload mentah) ──
async function verifyWithPakasir(orderId: string, amount: number) {
  const slug = process.env.PAKASIR_SLUG;
  const apiKey = process.env.PAKASIR_API_KEY;
  if (!slug || !apiKey) {
    throw new Error('PAKASIR_SLUG / PAKASIR_API_KEY belum di-set di environment variables.');
  }

  const url = new URL('https://app.pakasir.com/api/transactiondetail');
  url.searchParams.set('project', slug);
  url.searchParams.set('amount', String(amount));
  url.searchParams.set('order_id', orderId);
  url.searchParams.set('api_key', apiKey);

  const res = await fetch(url.toString(), {
    headers: { Accept: 'application/json' },
  });

  if (!res.ok) {
    throw new Error(`Pakasir transactiondetail gagal: HTTP ${res.status}`);
  }

  const data = (await res.json()) as PakasirTransactionDetail;
  return data.transaction;
}

// ── Notifikasi "pembayaran berhasil" ke pemilik tagihan ──────────────────────
// Satu orderId bisa mencakup beberapa dokumen tagihan sekaligus (warga melunasi
// beberapa bulan tunggakan dalam satu transaksi). Semuanya milik satu warga,
// jadi cukup satu notifikasi yang merangkum seluruh periode.
async function notifyPembayaranLunas(
  docs: FirebaseFirestore.QueryDocumentSnapshot[],
): Promise<void> {
  try {
    const userId = docs[0].get('userId') as string | undefined;
    if (!userId) {
      console.error('[pakasir-webhook] tagihan tanpa userId — notifikasi dilewati');
      return;
    }

    // Dokumen tagihan tidak menyimpan field `periode`; label periodenya
    // dibentuk dari `bulan` + `tahun`, sama seperti getter periodeLabel di
    // lib/features/pembayaran/models/tagihan_model.dart.
    const periode = docs
      .map((d) => {
        const bulan = d.get('bulan') as string | undefined;
        const tahun = d.get('tahun') as number | undefined;
        return bulan && tahun ? `${bulan} ${tahun}` : '';
      })
      .filter((p) => p.length > 0);

    const rincian = periode.length === 0
      ? 'Iuran Anda'
      : periode.length === 1
        ? `Iuran ${periode[0]}`
        : `Iuran ${periode.length} periode (${periode.join(', ')})`;

    await sendPush(
      { kind: 'pengguna', uid: userId },
      {
        title: '✅ Pembayaran Berhasil!',
        body: `${rincian} telah dikonfirmasi.`,
      },
    );
  } catch (err) {
    // Notifikasi bersifat pelengkap — tagihan sudah lunas di Firestore dan app
    // akan menampilkannya lewat stream listener. Kegagalan di sini tidak boleh
    // membuat webhook membalas error, karena Pakasir akan mengulang kirim.
    console.error('[pakasir-webhook] notifikasi pembayaran gagal:', err);
  }
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'POST') {
    res.status(405).json({ ok: false, message: 'Method not allowed' });
    return;
  }

  const body = req.body as PakasirWebhookPayload;

  if (!body?.order_id || typeof body.amount !== 'number') {
    res.status(400).json({ ok: false, message: 'Payload tidak lengkap' });
    return;
  }

  try {
    // 1. Verifikasi ulang ke Pakasir — JANGAN percaya body webhook mentah.
    const verified = await verifyWithPakasir(body.order_id, body.amount);

    if (!verified) {
      console.error('[pakasir-webhook] Transaksi tidak ditemukan saat verifikasi', body.order_id);
      // Tetap balas 200 supaya Pakasir tidak retry terus — sudah dicatat di log.
      res.status(200).json({ ok: false, message: 'Transaksi tidak ditemukan saat verifikasi' });
      return;
    }

    const amountMatches = verified.amount === body.amount;
    const orderIdMatches = verified.order_id === body.order_id;
    const isCompleted = verified.status === 'completed';

    if (!amountMatches || !orderIdMatches || !isCompleted) {
      console.error('[pakasir-webhook] Verifikasi tidak cocok', {
        body,
        verified,
      });
      res.status(200).json({ ok: false, message: 'Verifikasi tidak cocok, diabaikan' });
      return;
    }

    // 2. Cari semua dokumen tagihan dengan orderId ini (bisa > 1 kalau bayar
    //    beberapa bulan tunggakan sekaligus — lihat markManyAsLunas di Dart).
    const snap = await db
      .collection('tagihan')
      .where('orderId', '==', body.order_id)
      .get();

    if (snap.empty) {
      console.error('[pakasir-webhook] Tidak ada dokumen tagihan dengan orderId', body.order_id);
      res.status(200).json({ ok: false, message: 'Tagihan tidak ditemukan' });
      return;
    }

    // 2b. Cocokkan nominal yang dibayar dengan TOTAL tagihan yang akan dilunasi.
    //
    // Tanpa langkah ini, verifikasi di atas hanya memastikan "jumlah yang
    // dibayar == jumlah yang dicatat Pakasir", BUKAN "== total tagihan yang
    // ditandai lunas". URL pembayaran Pakasir memuat nominal secara terbuka
    // (mis. .../pay/slug/210000?order_id=...) dan dibuka di browser biasa,
    // sehingga warga bisa menurunkannya (mis. jadi 30000) lalu membayar
    // seadanya — dan seluruh tagihan ber-orderId sama akan ikut dilunasi.
    //
    // Di sinilah nominal dikunci ke total tagihan sebenarnya. Kalau tidak
    // sama, JANGAN tandai lunas apa pun.
    const totalTagihan = snap.docs.reduce(
      (sum, doc) => sum + ((doc.get('jumlah') as number | undefined) ?? 0),
      0,
    );

    if (verified.amount !== totalTagihan) {
      console.error('[pakasir-webhook] Nominal tidak sama dengan total tagihan', {
        orderId: body.order_id,
        dibayar: verified.amount,
        totalTagihan,
        jumlahDokumen: snap.docs.length,
      });
      // Balas 200 supaya Pakasir tidak retry terus — kejadian sudah dicatat.
      res.status(200).json({
        ok: false,
        message: 'Nominal pembayaran tidak sesuai total tagihan',
      });
      return;
    }

    // 3. Tandai lunas — batch write, atomic untuk semua dokumen sekaligus.
    const tanggalBayar = formatTanggalBayar(verified.completed_at ?? body.completed_at);
    const metodeBayar = (verified.payment_method ?? body.payment_method ?? 'QRIS').toUpperCase();

    const batch = db.batch();
    snap.docs.forEach((doc) => {
      batch.update(doc.ref, {
        status: 'lunas',
        tanggalBayar,
        metodeBayar,
      });
    });
    await batch.commit();

    // 4. Beri tahu warga bahwa pembayarannya sudah dikonfirmasi.
    //
    // Notifikasi ini SENGAJA dipicu di sini, bukan di app Flutter. Sebelumnya
    // PakasirPaymentPage yang mengirimnya setelah pembayaran selesai — akibatnya
    // warga tidak menerima notifikasi apa pun bila menutup aplikasi sebelum
    // proses itu sempat berjalan, padahal tagihannya sudah lunas. Dipicu dari
    // sini, notifikasi tetap terkirim dalam kondisi apa pun.
    await notifyPembayaranLunas(snap.docs);

    console.log(
      `[pakasir-webhook] OK — ${snap.docs.length} tagihan ditandai lunas untuk orderId=${body.order_id}`,
    );
    res.status(200).json({ ok: true, updated: snap.docs.length });
  } catch (err) {
    console.error('[pakasir-webhook] Error tak terduga:', err);
    res.status(500).json({ ok: false, message: 'Internal error' });
  }
}
