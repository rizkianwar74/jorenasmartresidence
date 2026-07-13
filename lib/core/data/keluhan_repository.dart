import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../../features/auth/data/auth_repository.dart';
import '../services/onesignal_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Enum status
// ─────────────────────────────────────────────────────────────────────────────

enum StatusKeluhan { menunggu, diproses, selesai, ditolak }

StatusKeluhan _parseStatus(String? raw) {
  switch (raw) {
    case 'DIPROSES': return StatusKeluhan.diproses;
    case 'SELESAI':  return StatusKeluhan.selesai;
    case 'DITOLAK':  return StatusKeluhan.ditolak;
    default:         return StatusKeluhan.menunggu;
  }
}

String _statusString(StatusKeluhan s) {
  switch (s) {
    case StatusKeluhan.menunggu: return 'MENUNGGU';
    case StatusKeluhan.diproses: return 'DIPROSES';
    case StatusKeluhan.selesai:  return 'SELESAI';
    case StatusKeluhan.ditolak:  return 'DITOLAK';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

class SatpamInfo {
  const SatpamInfo({required this.uid, required this.nama});
  final String uid;
  final String nama;
}

class KeluhanItem {
  const KeluhanItem({
    required this.id,
    required this.uid,
    required this.namaWarga,
    required this.blok,
    required this.nomorUnit,
    required this.kategori,
    required this.judul,
    required this.deskripsi,
    required this.status,
    required this.createdAt,
    this.fotoUrls = const [],
    this.adminNote,
    this.updatedAt,
    this.assignedTo,
    this.assignedName,
  });

  final String id;
  final String uid;
  final String namaWarga;
  final String blok;
  final String nomorUnit;
  final String kategori;
  final String judul;
  final String deskripsi;
  final StatusKeluhan status;
  final DateTime createdAt;
  final List<String> fotoUrls;
  final String? adminNote;
  final DateTime? updatedAt;
  /// UID satpam yang ditugaskan
  final String? assignedTo;
  /// Nama satpam yang ditugaskan (denormalisasi untuk display)
  final String? assignedName;

  // ── Label & warna status ──────────────────────────────────────────────────
  String get statusLabel {
    switch (status) {
      case StatusKeluhan.menunggu: return 'Menunggu';
      case StatusKeluhan.diproses: return 'Diproses';
      case StatusKeluhan.selesai:  return 'Selesai';
      case StatusKeluhan.ditolak:  return 'Ditolak';
    }
  }

  // ── fromDoc ───────────────────────────────────────────────────────────────
  factory KeluhanItem.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    List<String> parseFotos(dynamic raw) {
      if (raw is List) return raw.whereType<String>().toList();
      return [];
    }

    return KeluhanItem(
      id         : doc.id,
      uid        : d['uid']        as String? ?? '',
      namaWarga  : d['namaWarga']  as String? ?? '',
      blok       : d['blok']       as String? ?? '',
      nomorUnit  : d['nomorUnit']  as String? ?? '',
      kategori   : d['kategori']   as String? ?? '',
      judul      : d['judul']      as String? ?? '',
      deskripsi  : d['deskripsi']  as String? ?? '',
      status     : _parseStatus(d['status'] as String?),
      createdAt    : (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fotoUrls     : parseFotos(d['fotoUrls']),
      adminNote    : d['adminNote']   as String?,
      updatedAt    : (d['updatedAt']  as Timestamp?)?.toDate(),
      assignedTo   : d['assignedTo']  as String?,
      assignedName : d['assignedName'] as String?,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KeluhanRepository
//
// Collection : keluhan
// Foto       : disimpan langsung sebagai data URI base64 di field `fotoUrls`
//              pada dokumen yang sama — SAMA seperti foto profil
//              (AuthRepository.updatePhotoUrl) & BantuanRepository.sendRequest.
//              Tidak lagi lewat Firebase Storage, supaya konsisten dan
//              menghindari error CORS Storage di Flutter Web.
// ─────────────────────────────────────────────────────────────────────────────

class KeluhanRepository {
  KeluhanRepository._();

  static final _col = FirebaseFirestore.instance.collection('keluhan');

  // ── Kirim keluhan baru ────────────────────────────────────────────────────
  /// Returns `(item, fotoErrors)`:
  /// - `item` null bila gagal total
  /// - `fotoErrors` berisi pesan error encode per foto (kosong = semua berhasil)
  static Future<(KeluhanItem?, List<String>)> sendKeluhan({
    required String kategori,
    required String judul,
    required String deskripsi,
    List<Uint8List> fotos = const [],
  }) async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return (null, <String>[]);

      final uid = firebaseUser.uid;
      final m   = AuthRepository.currentUser;

      String namaWarga, blok, nomorUnit;
      if (m != null) {
        namaWarga = m.namaLengkap;
        blok      = m.blok;
        nomorUnit = m.nomorUnit;
      } else {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        if (!doc.exists) return (null, <String>[]);
        final d = doc.data()!;
        namaWarga = (d['namaLengkap'] as String?)?.isNotEmpty == true
            ? d['namaLengkap'] as String
            : (firebaseUser.displayName ?? 'Pengguna');
        blok      = (d['blok']      as String?) ?? '-';
        nomorUnit = (d['nomorUnit'] as String?) ?? '-';
      }

      // Konversi foto ke data URI base64 — kumpulkan error per foto (jarang
      // terjadi karena ini cuma encoding lokal, tapi tetap dijaga defensif).
      final urls       = <String>[];
      final fotoErrors = <String>[];
      for (int i = 0; i < fotos.length; i++) {
        try {
          urls.add('data:image/jpeg;base64,${base64Encode(fotos[i])}');
        } catch (e) {
          debugPrint('[KeluhanRepository] encode foto[$i] error: $e');
          fotoErrors.add('Foto ${i + 1}: $e');
        }
      }

      final ref = await _col.add({
        'uid'       : uid,
        'namaWarga' : namaWarga,
        'blok'      : blok,
        'nomorUnit' : nomorUnit,
        'kategori'  : kategori,
        'judul'     : judul,
        'deskripsi' : deskripsi,
        'status'    : 'MENUNGGU',
        'fotoUrls'  : urls,
        'adminNote' : null,
        'createdAt' : FieldValue.serverTimestamp(),
        'updatedAt' : null,
      });

      final item = KeluhanItem(
        id        : ref.id,
        uid       : uid,
        namaWarga : namaWarga,
        blok      : blok,
        nomorUnit : nomorUnit,
        kategori  : kategori,
        judul     : judul,
        deskripsi : deskripsi,
        status    : StatusKeluhan.menunggu,
        createdAt : DateTime.now(),
        fotoUrls  : urls,
      );

      // Notifikasi ke satpam on duty (fire-and-forget).
      OneSignalService.instance.sendKeluhanBaruToSatpam(
        namaWarga : namaWarga,
        judul     : judul,
        kategori  : kategori,
      );

      return (item, fotoErrors);
    } catch (e) {
      debugPrint('[KeluhanRepository] sendKeluhan error: $e');
      return (null, <String>[]);
    }
  }

  // ── Stream riwayat keluhan milik user ─────────────────────────────────────
  // Tidak pakai orderBy agar tidak butuh composite index — sort client-side
  static Stream<List<KeluhanItem>> watchMyKeluhan(String uid) {
    return _col
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snap) {
          final list = <KeluhanItem>[];
          for (final doc in snap.docs) {
            try {
              list.add(KeluhanItem.fromDoc(doc));
            } catch (e) {
              debugPrint('[KeluhanRepository] skip doc ${doc.id}: $e');
            }
          }
          // Sort terbaru di atas — client-side, tidak perlu composite index
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // ── Stream semua keluhan — untuk admin ───────────────────────────────────
  static Stream<List<KeluhanItem>> watchAllKeluhan() {
    return _col.snapshots().map((snap) {
      final list = <KeluhanItem>[];
      for (final doc in snap.docs) {
        try {
          list.add(KeluhanItem.fromDoc(doc));
        } catch (e) {
          debugPrint('[KeluhanRepository] skip doc ${doc.id}: $e');
        }
      }
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // ── Update status oleh admin ──────────────────────────────────────────────
  static Future<bool> updateStatus({
    required String keluhanId,
    required StatusKeluhan status,
    String? adminNote,
    String? assignToUid,
    String? assignToName,
  }) async {
    try {
      final data = <String, dynamic>{
        'status'    : _statusString(status),
        'updatedAt' : FieldValue.serverTimestamp(),
      };
      if (adminNote != null) data['adminNote'] = adminNote;
      // Saat satpam menangani keluhan dari kolam bersama, dia "mengklaim"-nya.
      if (assignToUid != null) {
        data['assignedTo']   = assignToUid;
        data['assignedName'] = assignToName;
      }
      await _col.doc(keluhanId).update(data);
      return true;
    } catch (e) {
      debugPrint('[KeluhanRepository] updateStatus error: $e');
      return false;
    }
  }

  // ── Tugaskan satpam — set DIPROSES + assignedTo ───────────────────────────
  static Future<bool> assignKeluhan({
    required String keluhanId,
    required String satpamUid,
    required String satpamNama,
  }) async {
    try {
      await _col.doc(keluhanId).update({
        'status'       : 'DIPROSES',
        'assignedTo'   : satpamUid,
        'assignedName' : satpamNama,
        'updatedAt'    : FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('[KeluhanRepository] assignKeluhan error: $e');
      return false;
    }
  }

  // ── Stream keluhan yang di-assign ke satpam tertentu ─────────────────────
  static Stream<List<KeluhanItem>> watchAssignedKeluhan(String satpamUid) {
    return _col
        .where('assignedTo', isEqualTo: satpamUid)
        .where('status', whereIn: ['DIPROSES', 'MENUNGGU'])
        .snapshots()
        .map((snap) {
          final list = <KeluhanItem>[];
          for (final doc in snap.docs) {
            try { list.add(KeluhanItem.fromDoc(doc)); }
            catch (e) { debugPrint('[KeluhanRepository] skip ${doc.id}: $e'); }
          }
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // ── Kolam bersama: keluhan MENUNGGU yang belum di-assign ke siapa pun ─────
  // Dipakai oleh satpam yang sedang bertugas (on-duty).
  static Stream<List<KeluhanItem>> watchUnassignedMenunggu() {
    return _col
        .where('status', isEqualTo: 'MENUNGGU')
        .snapshots()
        .map((snap) {
          final list = <KeluhanItem>[];
          for (final doc in snap.docs) {
            try {
              final k = KeluhanItem.fromDoc(doc);
              if (k.assignedTo == null || k.assignedTo!.isEmpty) list.add(k);
            } catch (e) {
              debugPrint('[KeluhanRepository] skip ${doc.id}: $e');
            }
          }
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // ── Inbox satpam ──────────────────────────────────────────────────────────
  // includeShared = true  (satpam sedang BERTUGAS): gabungan keluhan yang
  //   ditugaskan ke dia + kolam bersama (MENUNGGU belum di-assign).
  // includeShared = false (OFF-DUTY): hanya keluhan yang sudah ditugaskan ke dia
  //   (agar tetap bisa menyelesaikan yang sudah diambil).
  static Stream<List<KeluhanItem>> watchSatpamInbox(
    String satpamUid, {
    required bool includeShared,
  }) {
    if (!includeShared) return watchAssignedKeluhan(satpamUid);

    final controller = StreamController<List<KeluhanItem>>();
    var assigned = <KeluhanItem>[];
    var shared   = <KeluhanItem>[];
    void emit() {
      final byId = <String, KeluhanItem>{};
      for (final k in [...assigned, ...shared]) {
        byId[k.id] = k;
      }
      final merged = byId.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (!controller.isClosed) controller.add(merged);
    }

    final s1 = watchAssignedKeluhan(satpamUid).listen((l) { assigned = l; emit(); });
    final s2 = watchUnassignedMenunggu().listen((l) { shared = l; emit(); });
    controller.onCancel = () { s1.cancel(); s2.cancel(); };
    return controller.stream;
  }

  // ── Ambil daftar satpam aktif dari collection users ───────────────────────
  // Throws jika Firestore error, return [] jika memang tidak ada satpam.
  static Future<List<SatpamInfo>> getSatpamList() async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'satpam')
        .get();
    debugPrint('[KeluhanRepository] getSatpamList: ${snap.docs.length} docs found');
    return snap.docs.map((doc) {
      final d = doc.data();
      // Coba berbagai kemungkinan nama field
      final nama = (d['namaLengkap'] as String?)?.isNotEmpty == true
          ? d['namaLengkap'] as String
          : (d['nama'] as String?)?.isNotEmpty == true
              ? d['nama'] as String
              : (d['username'] as String? ?? 'Satpam');
      return SatpamInfo(uid: doc.id, nama: nama);
    }).toList();
  }
}
