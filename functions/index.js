/**
 * Firebase Cloud Functions — Jorena Smart Residence
 *
 * Dua fungsi otomatis:
 * 1. seedTagihanBulanan  — scheduled, jalan tiap tgl 1 jam 00:00 WIB
 *                          → buat tagihan bulan baru untuk semua warga
 * 2. onUserCreated       — Firestore onCreate trigger users/{uid}
 *                          → buat tagihan bulan ini saat user baru daftar
 *
 * STATUS: TIDAK DI-DEPLOY. Project ini sengaja tidak upgrade ke Firebase
 * Blaze plan, dan Cloud Functions 2nd-gen (firebase-functions/v2/...) —
 * baik yang scheduled (seedTagihanBulanan) MAUPUN Firestore trigger
 * (onUserCreated) — berjalan di atas Cloud Run/Eventarc, yang mensyaratkan
 * Blaze untuk SEMUA jenis trigger, bukan cuma yang scheduled. (Catatan lama
 * di sini pernah menyebut onUserCreated bisa jalan di Spark/free plan —
 * itu tidak akurat, sudah diperbaiki.)
 *
 * File ini disimpan sebagai referensi/dokumentasi logika saja, bukan untuk
 * dideploy. Penggantinya yang aktif berjalan dari sisi client:
 *   - PaymentRepository.ensureAllMissingTagihan() (lib/features/pembayaran/
 *     data/payment_repository.dart), dipanggil dari home_page.dart tiap
 *     warga buka app — backfill semua tagihan bulanan yang bolong (bukan
 *     cuma bulan berjalan), sehingga meng-cover fungsi seedTagihanBulanan
 *     DAN onUserCreated sekaligus, tanpa perlu Cloud Functions/Blaze.
 *   - Konsekuensinya: tagihan bulan berjalan baru muncul di dashboard admin
 *     setelah warga bersangkutan membuka app minimal sekali di bulan itu
 *     (bukan otomatis tanggal 1 seperti kalau pakai scheduled function).
 *
 * Deploy (kalau suatu saat upgrade ke Blaze dan ingin dipakai lagi):
 *   cd functions && npm install
 *   firebase deploy --only functions
 */

const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

initializeApp();

// ─── Konstanta ───────────────────────────────────────────────────────────────

const IURAN_BULANAN = 30000;

const MONTHS_LONG = [
  "Januari", "Februari", "Maret", "April", "Mei", "Juni",
  "Juli", "Agustus", "September", "Oktober", "November", "Desember",
];
const MONTHS_SHORT = [
  "Jan", "Feb", "Mar", "Apr", "Mei", "Jun",
  "Jul", "Agu", "Sep", "Okt", "Nov", "Des",
];

// ─── Helper ──────────────────────────────────────────────────────────────────

/**
 * Buat 1 dokumen tagihan untuk uid+bulan tertentu.
 * Return true kalau berhasil dibuat, false kalau sudah ada (skip).
 */
async function buatTagihanUntukUser(db, uid, userData, now) {
  const year = now.getFullYear();
  const month = now.getMonth(); // 0-indexed
  const monthNum = month + 1;

  const tagihanId =
    `tagihan-${year}-${String(monthNum).padStart(2, "0")}-${uid}`;

  const existing = await db.collection("tagihan").doc(tagihanId).get();
  if (existing.exists) return false;

  // Hari terakhir bulan ini
  const lastDay = new Date(year, monthNum, 0).getDate();
  const jatuhTempo = `${lastDay} ${MONTHS_SHORT[month]} ${year}`;

  const nama =
    (userData.namaLengkap && userData.namaLengkap.trim()) ||
    (userData.username && userData.username.trim()) ||
    "Warga";

  await db.collection("tagihan").doc(tagihanId).set({
    userId: uid,
    namaResiden: nama,
    nomorHp: userData.nomorHp || "6281234567890",
    blok: userData.blok || "Blok A",
    nomorUnit: userData.nomorUnit || "01",
    bulan: MONTHS_LONG[month],
    bulanIndex: monthNum,
    tahun: year,
    jumlah: IURAN_BULANAN,
    jatuhTempo: jatuhTempo,
    status: "belumBayar",
    tanggalBayar: null,
    metodeBayar: null,
    orderId: null,
    createdAt: FieldValue.serverTimestamp(),
  });

  return true;
}

// ─── 1. Scheduled: tiap tanggal 1 jam 00:00 WIB (= 17:00 UTC) ───────────────

exports.seedTagihanBulanan = onSchedule(
  {
    schedule: "0 17 1 * *", // cron: tiap tgl 1 jam 17:00 UTC = 00:00 WIB
    timeZone: "Asia/Jakarta",
    region: "asia-southeast2", // Jakarta
  },
  async () => {
    const db = getFirestore();
    const now = new Date();

    const usersSnap = await db.collection("users").get();
    if (usersSnap.empty) {
      console.log("[seedTagihanBulanan] Tidak ada user.");
      return;
    }

    let created = 0;
    let skipped = 0;

    for (const doc of usersSnap.docs) {
      const userData = doc.data();
      // Admin tidak perlu tagihan iuran
      if (userData.role === "admin") continue;

      const dibuat = await buatTagihanUntukUser(db, doc.id, userData, now);
      dibuat ? created++ : skipped++;
    }

    console.log(
      `[seedTagihanBulanan] Selesai. Dibuat: ${created}, Sudah ada: ${skipped}.`
    );
  }
);

// ─── 2. Firestore onCreate: langsung buat tagihan saat user baru registrasi ──

exports.onUserCreated = onDocumentCreated(
  {
    document: "users/{uid}",
    region: "asia-southeast2",
  },
  async (event) => {
    const db = getFirestore();
    const uid = event.params.uid;
    const userData = event.data?.data() || {};

    // Admin tidak perlu tagihan
    if (userData.role === "admin") {
      console.log(`[onUserCreated] uid=${uid} adalah admin, skip.`);
      return;
    }

    const now = new Date();
    const dibuat = await buatTagihanUntukUser(db, uid, userData, now);
    console.log(
      `[onUserCreated] uid=${uid} tagihan ${dibuat ? "dibuat" : "sudah ada"}.`
    );
  }
);
