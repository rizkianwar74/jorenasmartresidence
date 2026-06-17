import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../../features/auth/auth_repository.dart';

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
// KeluhanService
//
// Collection : keluhan
// Storage    : keluhan/{uid}/{docId}/{filename}
// ─────────────────────────────────────────────────────────────────────────────

class KeluhanService {
  KeluhanService._();

  static final _col     = FirebaseFirestore.instance.collection('keluhan');
  static final _storage = FirebaseStorage.instance;

  // ── Upload satu foto, return download URL (throw on error) ───────────────
  static Future<String> _uploadFoto(
    String uid,
    String docId,
    int index,
    Uint8List bytes,
  ) async {
    final ref = _storage
        .ref()
        .child('keluhan/$uid/$docId/foto_$index.jpg');
    final task = await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return task.ref.getDownloadURL();
  }

  // ── Kirim keluhan baru ────────────────────────────────────────────────────
  /// Returns `(item, fotoErrors)`:
  /// - `item` null bila gagal total
  /// - `fotoErrors` berisi pesan error upload per foto (kosong = semua berhasil)
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

      // Buat dokumen dulu (tanpa foto) untuk dapat ID-nya
      final ref = await _col.add({
        'uid'       : uid,
        'namaWarga' : namaWarga,
        'blok'      : blok,
        'nomorUnit' : nomorUnit,
        'kategori'  : kategori,
        'judul'     : judul,
        'deskripsi' : deskripsi,
        'status'    : 'MENUNGGU',
        'fotoUrls'  : <String>[],
        'adminNote' : null,
        'createdAt' : FieldValue.serverTimestamp(),
        'updatedAt' : null,
      });

      // Upload foto jika ada — kumpulkan error per foto
      final urls        = <String>[];
      final fotoErrors  = <String>[];
      for (int i = 0; i < fotos.length; i++) {
        try {
          final url = await _uploadFoto(uid, ref.id, i, fotos[i]);
          urls.add(url);
        } catch (e) {
          debugPrint('[KeluhanService] upload foto[$i] error: $e');
          fotoErrors.add('Foto ${i + 1}: $e');
        }
      }
      if (urls.isNotEmpty) {
        await ref.update({'fotoUrls': urls});
      }

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
      return (item, fotoErrors);
    } catch (e) {
      debugPrint('[KeluhanService] sendKeluhan error: $e');
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
              debugPrint('[KeluhanService] skip doc ${doc.id}: $e');
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
          debugPrint('[KeluhanService] skip doc ${doc.id}: $e');
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
  }) async {
    try {
      final data = <String, dynamic>{
        'status'    : _statusString(status),
        'updatedAt' : FieldValue.serverTimestamp(),
      };
      if (adminNote != null) data['adminNote'] = adminNote;
      await _col.doc(keluhanId).update(data);
      return true;
    } catch (e) {
      debugPrint('[KeluhanService] updateStatus error: $e');
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
      debugPrint('[KeluhanService] assignKeluhan error: $e');
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
            catch (e) { debugPrint('[KeluhanService] skip ${doc.id}: $e'); }
          }
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // ── Ambil daftar satpam aktif dari collection users ───────────────────────
  // Throws jika Firestore error, return [] jika memang tidak ada satpam.
  static Future<List<SatpamInfo>> getSatpamList() async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'satpam')
        .get();
    debugPrint('[KeluhanService] getSatpamList: ${snap.docs.length} docs found');
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
