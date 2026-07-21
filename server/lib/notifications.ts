// ─────────────────────────────────────────────────────────────────────────────
// Katalog jenis notifikasi.
//
// Ini adalah satu-satunya tempat yang menentukan:
//   • siapa yang berwenang memicu tiap jenis notifikasi,
//   • dari koleksi mana datanya dibaca,
//   • dan bagaimana bunyi pesannya.
//
// PRINSIPNYA: app Flutter hanya mengirim { type, docId }. Seluruh isi pesan dan
// penentuan penerima disusun DI SINI, dari data yang dibaca server langsung dari
// Firestore. App tidak pernah mengirim judul, isi, maupun daftar sasaran.
//
// Kalau app boleh mengirim payload mentah, warga dengan akun sah tetap dapat
// menyusun sasaran sendiri dan menyiarkan pesan ke seluruh kompleks — lolos
// autentikasi, tapi bobol di sisi otorisasi.
// ─────────────────────────────────────────────────────────────────────────────

import type { Caller, UserRole } from './firebase';
import type { Audience, PushMessage } from './onesignal';

export type NotifType =
  | 'sos_baru'
  | 'bantuan_baru'
  | 'keluhan_baru'
  | 'sos_update'
  | 'bantuan_update'
  | 'keluhan_update'
  | 'keluhan_assigned'
  | 'berita_baru'
  | 'patroli_update';

type DocData = FirebaseFirestore.DocumentData;

export interface NotifSpec {
  /** Peran yang boleh memicu jenis ini. */
  roles: UserRole[];
  /** Koleksi Firestore tempat dokumen sumber berada. */
  collection: string;
  /**
   * Nama field pemilik dokumen. Penamaannya TIDAK konsisten antar koleksi
   * (`sosalert` memakai userId, `bantuanrequest` dan `keluhan` memakai uid),
   * karena itu dipetakan eksplisit di sini alih-alih ditebak.
   */
  ownerField: string;
  /**
   * true  → pemohon wajib pemilik dokumen (jenis yang dipicu warga sendiri).
   * false → pemohon petugas yang menindaklanjuti dokumen milik orang lain.
   */
  requireOwner: boolean;
  /**
   * Susun pesan dari isi dokumen. Mengembalikan null bila pada kondisi dokumen
   * saat ini memang tidak ada yang perlu dikirim (mis. berita masih draft).
   */
  build(doc: DocData, caller: Caller): { audience: Audience; message: PushMessage } | null;
}

// ── Helper ───────────────────────────────────────────────────────────────────
const str = (v: unknown, fallback = '-'): string =>
  typeof v === 'string' && v.trim().length > 0 ? v.trim() : fallback;

const LABEL_KELUHAN: Record<string, string> = {
  MENUNGGU: 'Menunggu',
  DIPROSES: 'Sedang Diproses',
  SELESAI: 'Selesai',
  DITOLAK: 'Ditolak',
};

// ── Katalog ──────────────────────────────────────────────────────────────────
export const NOTIFICATIONS: Record<NotifType, NotifSpec> = {

  // ── Warga → satpam yang sedang bertugas ────────────────────────────────────
  sos_baru: {
    roles: ['user'],
    collection: 'sosalert',
    ownerField: 'userId',
    requireOwner: true,
    build(doc) {
      // Dokumen menyimpan type 'SOS' (darurat) atau 'CALL' (panggilan biasa).
      // Server yang menyimpulkan, bukan client yang mengirim flag.
      const darurat = doc.type === 'SOS';
      const nama = str(doc.namaWarga, 'Warga');
      const lokasi = `Blok ${str(doc.blok)} No. ${str(doc.nomorUnit)}`;
      return {
        audience: { kind: 'satpamOnDuty' },
        message: {
          title: darurat ? '🚨 SOS DARURAT!' : '📢 Panggilan Satpam',
          body: darurat
            ? `${nama} butuh bantuan darurat — ${lokasi}`
            : `${nama} memanggil satpam — ${lokasi}`,
          urgent: true,
        },
      };
    },
  },

  bantuan_baru: {
    roles: ['user'],
    collection: 'bantuanrequest',
    ownerField: 'uid',
    requireOwner: true,
    build(doc) {
      const nama = str(doc.namaWarga, 'Warga');
      const lokasi = `Blok ${str(doc.blok)} No. ${str(doc.nomorUnit)}`;
      return {
        audience: { kind: 'satpamOnDuty' },
        message: {
          title: '🆘 Permintaan Bantuan Baru',
          body: `${nama} (${lokasi}) meminta bantuan: ${str(doc.kategori, 'Umum')}.`,
          urgent: true,
        },
      };
    },
  },

  keluhan_baru: {
    roles: ['user'],
    collection: 'keluhan',
    ownerField: 'uid',
    requireOwner: true,
    build(doc) {
      return {
        audience: { kind: 'satpamOnDuty' },
        message: {
          title: '📋 Keluhan Baru Masuk',
          body: `${str(doc.namaWarga, 'Warga')} melaporkan keluhan `
            + `[${str(doc.kategori, 'Umum')}]: "${str(doc.judul, 'Tanpa judul')}".`,
        },
      };
    },
  },

  // ── Petugas → warga pemilik dokumen ────────────────────────────────────────
  sos_update: {
    roles: ['satpam'],
    collection: 'sosalert',
    ownerField: 'userId',
    requireOwner: false,
    build(doc, caller) {
      const uid = doc.userId as string | undefined;
      if (!uid) return null;
      // Status dibaca dari dokumen — client tidak mengirim flag onMyWay.
      if (doc.status === 'ON_MY_WAY') {
        return {
          audience: { kind: 'pengguna', uid },
          message: {
            title: '🚨 Satpam Menuju Lokasi',
            body: `${caller.nama} sedang dalam perjalanan menuju lokasi Anda.`,
            urgent: true,
          },
        };
      }
      if (doc.status === 'RESOLVED') {
        return {
          audience: { kind: 'pengguna', uid },
          message: {
            title: '✅ SOS Selesai Ditangani',
            body: `${caller.nama} telah menyelesaikan penanganan SOS Anda.`,
          },
        };
      }
      return null; // status lain tidak perlu diberitahukan
    },
  },

  bantuan_update: {
    roles: ['satpam'],
    collection: 'bantuanrequest',
    ownerField: 'uid',
    requireOwner: false,
    build(doc, caller) {
      const uid = doc.uid as string | undefined;
      if (!uid) return null;
      if (doc.status === 'ON_MY_WAY') {
        return {
          audience: { kind: 'pengguna', uid },
          message: {
            title: '🚶 Satpam Menuju Lokasi',
            body: `${caller.nama} sedang dalam perjalanan menuju lokasi Anda.`,
          },
        };
      }
      if (doc.status === 'RESOLVED') {
        return {
          audience: { kind: 'pengguna', uid },
          message: {
            title: '✅ Bantuan Selesai',
            body: `${caller.nama} telah menyelesaikan permintaan bantuan Anda.`,
          },
        };
      }
      return null;
    },
  },

  keluhan_update: {
    // Satpam mengubah status lewat halaman keamanan, admin lewat panel laporan.
    roles: ['satpam', 'admin'],
    collection: 'keluhan',
    ownerField: 'uid',
    requireOwner: false,
    build(doc) {
      const uid = doc.uid as string | undefined;
      if (!uid) return null;
      const label = LABEL_KELUHAN[str(doc.status, '')];
      if (!label) return null;
      return {
        audience: { kind: 'pengguna', uid },
        message: {
          title: '📋 Update Keluhan',
          body: `Keluhan "${str(doc.judul, 'Tanpa judul')}" kini berstatus: ${label}.`,
        },
      };
    },
  },

  // ── Admin → satpam tertentu ────────────────────────────────────────────────
  keluhan_assigned: {
    roles: ['admin'],
    collection: 'keluhan',
    ownerField: 'uid',
    requireOwner: false,
    build(doc) {
      // Sasaran diambil dari dokumen, bukan dari kiriman client — admin tidak
      // bisa mengarahkan notifikasi ini ke sembarang UID.
      const satpamUid = doc.assignedTo as string | undefined;
      if (!satpamUid) return null;
      return {
        audience: { kind: 'pengguna', uid: satpamUid },
        message: {
          title: '📌 Keluhan Ditugaskan ke Anda',
          body: `Keluhan dari ${str(doc.namaWarga, 'warga')}: `
            + `"${str(doc.judul, 'Tanpa judul')}" telah ditugaskan kepada Anda.`,
        },
      };
    },
  },

  // ── Siaran ke seluruh warga ────────────────────────────────────────────────
  berita_baru: {
    roles: ['admin'],
    collection: 'beritaacara',
    ownerField: 'authorUid',
    requireOwner: false,
    build(doc) {
      // Draft tidak disiarkan.
      if (doc.isPublished !== true) return null;
      return {
        audience: { kind: 'semuaWarga' },
        message: {
          title: '📰 Pengumuman Baru',
          body: str(doc.judul, 'Ada pengumuman baru dari pengelola.'),
        },
      };
    },
  },

  patroli_update: {
    roles: ['satpam'],
    collection: 'patroli',
    ownerField: 'satpamUid',
    requireOwner: true,
    build(doc) {
      const nama = str(doc.namaSatpam, 'Petugas keamanan');
      const blok = str(doc.blokPatroli);
      if (doc.status === 'AKTIF') {
        return {
          audience: { kind: 'semuaWarga' },
          message: {
            title: '🛡️ Patroli Dimulai',
            body: `${nama} sedang melakukan patroli di ${blok}.`,
          },
        };
      }
      if (doc.status === 'SELESAI') {
        return {
          audience: { kind: 'semuaWarga' },
          message: {
            title: '✅ Patroli Selesai',
            body: `${nama} telah menyelesaikan patroli di ${blok}.`,
          },
        };
      }
      return null;
    },
  },
};

export function isNotifType(v: unknown): v is NotifType {
  return typeof v === 'string' && Object.prototype.hasOwnProperty.call(NOTIFICATIONS, v);
}
