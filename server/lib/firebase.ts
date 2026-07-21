// ─────────────────────────────────────────────────────────────────────────────
// Inisialisasi Firebase Admin SDK — dipakai bersama oleh SEMUA endpoint.
//
// Sebelumnya inisialisasi ini ditulis inline di dalam api/pakasir-webhook.ts.
// Setelah ada endpoint kedua (api/send-notification.ts), keduanya harus memakai
// instance yang sama — kalau masing-masing memanggil initializeApp() sendiri,
// Firebase Admin melempar error "app already exists" pada invoke yang warm.
//
// Admin SDK berjalan dengan kredensial service account, sehingga operasinya
// TIDAK terikat Firestore Security Rules. Itu memang tujuannya: server ini
// adalah pihak tepercaya, sementara app Flutter tidak.
// ─────────────────────────────────────────────────────────────────────────────

import * as admin from 'firebase-admin';

if (!admin.apps.length) {
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!raw) {
    throw new Error(
      'FIREBASE_SERVICE_ACCOUNT_JSON belum di-set di environment variables.',
    );
  }
  admin.initializeApp({
    credential: admin.credential.cert(JSON.parse(raw) as admin.ServiceAccount),
  });
}

export const db = admin.firestore();
export const auth = admin.auth();
export { admin };

/** Peran pengguna — harus sama persis dengan enum UserRole di Dart. */
export type UserRole = 'user' | 'admin' | 'satpam';

/**
 * Verifikasi Firebase ID Token dari header Authorization, lalu ambil peran
 * pengguna dari Firestore.
 *
 * Peran SENGAJA dibaca dari koleksi `users`, bukan dari body permintaan —
 * apa pun yang dikirim client bisa dipalsukan, isi Firestore tidak.
 *
 * Mengembalikan null bila token tidak ada / tidak sah / user tidak terdaftar.
 */
export interface Caller {
  uid: string;
  role: UserRole;
  /** Nama lengkap dari koleksi `users` — dipakai menyusun isi notifikasi. */
  nama: string;
}

export async function verifyCaller(
  authorizationHeader: string | undefined,
): Promise<Caller | null> {
  if (!authorizationHeader?.startsWith('Bearer ')) return null;

  const idToken = authorizationHeader.slice(7).trim();
  if (!idToken) return null;

  let uid: string;
  try {
    const decoded = await auth.verifyIdToken(idToken);
    uid = decoded.uid;
  } catch (err) {
    console.error('[auth] verifyIdToken gagal:', err);
    return null;
  }

  const snap = await db.collection('users').doc(uid).get();
  if (!snap.exists) {
    console.error('[auth] user terautentikasi tapi tidak ada di koleksi users:', uid);
    return null;
  }

  const role = snap.get('role') as string | undefined;
  if (role !== 'user' && role !== 'admin' && role !== 'satpam') {
    console.error('[auth] peran tidak dikenal:', role, 'uid:', uid);
    return null;
  }

  const nama = (snap.get('namaLengkap') as string | undefined)?.trim();

  return { uid, role, nama: nama && nama.length > 0 ? nama : 'Petugas' };
}
