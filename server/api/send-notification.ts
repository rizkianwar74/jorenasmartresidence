// ─────────────────────────────────────────────────────────────────────────────
// Vercel serverless function — endpoint pengiriman push notification.
//
// Dibuat supaya ONESIGNAL_REST_API_KEY tidak lagi ikut terkemas ke dalam APK.
// Sebelumnya app Flutter memanggil REST API OneSignal langsung memakai key yang
// disimpan di .env, sedangkan .env didaftarkan sebagai asset di pubspec.yaml —
// artinya key tersebut ikut terdistribusi ke setiap pengguna.
//
// Alur:
//   1. Verifikasi Firebase ID Token pemohon                      → 401 bila gagal
//   2. Ambil peran pemohon dari Firestore (bukan dari body)      → 401 bila gagal
//   3. Cocokkan jenis notifikasi dengan peran                    → 403 bila tidak berwenang
//   4. Baca dokumen sumber, validasi kepemilikan                 → 404 / 403
//   5. Susun pesan dari isi dokumen, kirim ke OneSignal
//
// Body permintaan sengaja hanya memuat { type, docId }. App TIDAK mengirim
// judul, isi pesan, maupun daftar penerima — semuanya ditentukan server dari
// data yang dibaca sendiri dari Firestore.
// ─────────────────────────────────────────────────────────────────────────────

import type { VercelRequest, VercelResponse } from '@vercel/node';
import { db, verifyCaller } from '../lib/firebase';
import { NOTIFICATIONS, isNotifType } from '../lib/notifications';
import { sendPush } from '../lib/onesignal';

interface Body {
  type?: unknown;
  docId?: unknown;
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'POST') {
    res.status(405).json({ ok: false, message: 'Method not allowed' });
    return;
  }

  const { type, docId } = (req.body ?? {}) as Body;

  if (!isNotifType(type)) {
    res.status(400).json({ ok: false, message: 'Jenis notifikasi tidak dikenal' });
    return;
  }
  if (typeof docId !== 'string' || docId.trim().length === 0) {
    res.status(400).json({ ok: false, message: 'docId wajib diisi' });
    return;
  }

  try {
    // ── 1 & 2. Autentikasi + ambil peran ─────────────────────────────────────
    const caller = await verifyCaller(req.headers.authorization);
    if (!caller) {
      res.status(401).json({ ok: false, message: 'Token tidak sah' });
      return;
    }

    const spec = NOTIFICATIONS[type];

    // ── 3. Otorisasi berdasarkan peran ───────────────────────────────────────
    // Autentikasi hanya menjawab SIAPA pemohon; pemeriksaan ini menjawab
    // APAKAH dia berwenang memicu jenis notifikasi tersebut.
    if (!spec.roles.includes(caller.role)) {
      console.error(
        `[send-notification] 403 — uid=${caller.uid} role=${caller.role} mencoba type=${type}`,
      );
      res.status(403).json({ ok: false, message: 'Tidak berwenang untuk jenis notifikasi ini' });
      return;
    }

    // ── 4. Baca dokumen sumber ───────────────────────────────────────────────
    const snap = await db.collection(spec.collection).doc(docId).get();
    if (!snap.exists) {
      res.status(404).json({ ok: false, message: 'Dokumen tidak ditemukan' });
      return;
    }
    const doc = snap.data()!;

    // Untuk jenis yang dipicu pemiliknya sendiri (warga melapor, satpam memulai
    // patroli), pastikan dokumen itu memang miliknya. Ini mencegah seseorang
    // memicu notifikasi atas laporan orang lain.
    if (spec.requireOwner && doc[spec.ownerField] !== caller.uid) {
      console.error(
        `[send-notification] 403 — uid=${caller.uid} bukan pemilik ${spec.collection}/${docId}`,
      );
      res.status(403).json({ ok: false, message: 'Dokumen ini bukan milik Anda' });
      return;
    }

    // ── 5. Susun pesan & kirim ───────────────────────────────────────────────
    const built = spec.build(doc, caller);
    if (!built) {
      // Kondisi dokumen memang tidak menuntut notifikasi (mis. berita draft,
      // atau status yang tidak perlu diberitahukan). Bukan error.
      res.status(200).json({ ok: true, sent: false, message: 'Tidak ada notifikasi untuk kondisi ini' });
      return;
    }

    const sent = await sendPush(built.audience, built.message);

    console.log(
      `[send-notification] type=${type} doc=${spec.collection}/${docId} `
      + `oleh=${caller.role}/${caller.uid} terkirim=${sent}`,
    );
    res.status(200).json({ ok: true, sent });
  } catch (err) {
    console.error('[send-notification] Error tak terduga:', err);
    res.status(500).json({ ok: false, message: 'Internal error' });
  }
}
