import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../../features/auth/auth_repository.dart';
import 'onesignal_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Enum
// ─────────────────────────────────────────────────────────────────────────────

enum BantuanStatus { pending, onMyWay, resolved, cancelled }

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

class BantuanRequest {
  const BantuanRequest({
    required this.id,
    required this.uid,
    required this.namaWarga,
    required this.blok,
    required this.nomorUnit,
    required this.kategori,
    required this.catatan,
    required this.status,
    required this.createdAt,
    this.fotoUrls = const [],
    this.respondedBy,
    this.resolvedAt,
  });

  final String id;
  final String uid;
  final String namaWarga;
  final String blok;
  final String nomorUnit;
  final String kategori;
  final String catatan;
  final BantuanStatus status;
  final DateTime createdAt;
  final List<String> fotoUrls;
  final String? respondedBy;
  final DateTime? resolvedAt;

  String get statusLabel {
    switch (status) {
      case BantuanStatus.pending:   return 'Menunggu Respon';
      case BantuanStatus.onMyWay:   return 'Satpam Menuju Lokasi';
      case BantuanStatus.resolved:  return 'Selesai';
      case BantuanStatus.cancelled: return 'Dibatalkan';
    }
  }

  // ── Dari Firestore → BantuanRequest (sama persis dengan SosAlert.fromDoc) ──
  factory BantuanRequest.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final rawFotos = d['fotoUrls'];
    return BantuanRequest(
      id          : doc.id,
      uid         : d['uid']       as String? ?? '',
      namaWarga   : d['namaWarga'] as String? ?? '',
      blok        : d['blok']      as String? ?? '',
      nomorUnit   : d['nomorUnit'] as String? ?? '',
      kategori    : d['kategori']  as String? ?? '',
      catatan     : d['catatan']   as String? ?? '',
      status      : _parseStatus(d['status'] as String?),
      createdAt   : (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fotoUrls    : rawFotos is List ? rawFotos.whereType<String>().toList() : const [],
      respondedBy : d['respondedBy'] as String?,
      resolvedAt  : (d['resolvedAt'] as Timestamp?)?.toDate(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper konversi — sama persis dengan SosService
// ─────────────────────────────────────────────────────────────────────────────

BantuanStatus _parseStatus(String? raw) {
  switch (raw) {
    case 'ON_MY_WAY':   return BantuanStatus.onMyWay;
    case 'RESOLVED':    return BantuanStatus.resolved;
    case 'CANCELLED':   return BantuanStatus.cancelled;
    default:            return BantuanStatus.pending;
  }
}

String _statusString(BantuanStatus s) {
  switch (s) {
    case BantuanStatus.pending:   return 'PENDING';
    case BantuanStatus.onMyWay:   return 'ON_MY_WAY';
    case BantuanStatus.resolved:  return 'RESOLVED';
    case BantuanStatus.cancelled: return 'CANCELLED';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BantuanService — struktur sama dengan SosService, versi lebih simple
//
// Collection: bantuanrequest
// Schema:
//   uid, namaWarga, blok, nomorUnit, kategori, catatan — String
//   status  — PENDING | ON_MY_WAY | RESOLVED | CANCELLED
//   createdAt, resolvedAt — Timestamp / null
//   respondedBy — String / null
// ─────────────────────────────────────────────────────────────────────────────

class BantuanService {
  BantuanService._();

  static final _col = FirebaseFirestore.instance.collection('bantuanrequest');

  // ── ID request aktif milik user saat ini (in-memory, seperti SOS) ─────────
  // Diset setelah sendRequest berhasil, dikosongkan setelah selesai/batal
  static String? _activeRequestId;
  static String? get activeRequestId => _activeRequestId;

  // ── Ambil lokasi user untuk form ─────────────────────────────────────────
  static Future<String> getUserLokasi() async {
    try {
      final m = AuthRepository.currentUser;
      if (m != null) return 'Blok ${m.blok} – Unit ${m.nomorUnit}';
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return '-';
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!doc.exists) return '-';
      final d = doc.data()!;
      return 'Blok ${d['blok'] ?? '-'} – Unit ${d['nomorUnit'] ?? '-'}';
    } catch (_) {
      return '-';
    }
  }

  // ── Kirim request bantuan baru ────────────────────────────────────────────
  // Setelah berhasil: _activeRequestId di-set otomatis (sama seperti SOS)
  //
  // [fotos] opsional — disimpan LANGSUNG sebagai data URI base64 di field
  // `fotoUrls` pada dokumen Firestore yang sama, TIDAK lewat Firebase
  // Storage. Ini sengaja disamakan dengan pola foto profil
  // (AuthRepository.updatePhotoUrl) dan berita (admin_berita_form_page) di
  // app ini — selain konsisten, ini juga menghindari error CORS Firebase
  // Storage yang muncul saat upload dari Flutter Web.
  //
  // Catatan: karena base64 disimpan langsung di dokumen, total ukuran ke-3
  // foto digabung sebaiknya tidak mendekati limit 1MB per dokumen Firestore
  // — image_picker di form sudah di-kompres (quality 60, max 800x600) untuk
  // menjaga ukurannya kecil.
  static Future<BantuanRequest?> sendRequest({
    required String kategori,
    String catatan = '',
    List<Uint8List> fotos = const [],
  }) async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return null;

      final uid = firebaseUser.uid;
      final m   = AuthRepository.currentUser;

      String namaWarga, blok, nomorUnit;
      if (m != null) {
        namaWarga = m.namaLengkap;
        blok      = m.blok;
        nomorUnit = m.nomorUnit;
      } else {
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (!doc.exists) return null;
        final d = doc.data()!;
        namaWarga = (d['namaLengkap'] as String?)?.isNotEmpty == true
            ? d['namaLengkap'] as String
            : (firebaseUser.displayName ?? 'Pengguna');
        blok      = (d['blok']      as String?) ?? '-';
        nomorUnit = (d['nomorUnit'] as String?) ?? '-';
      }

      final fotoDataUris = fotos
          .map((bytes) => 'data:image/jpeg;base64,${base64Encode(bytes)}')
          .toList();

      final ref = await _col.add({
        'uid'        : uid,
        'namaWarga'  : namaWarga,
        'blok'       : blok,
        'nomorUnit'  : nomorUnit,
        'kategori'   : kategori,
        'catatan'    : catatan,
        'status'     : 'PENDING',
        'fotoUrls'   : fotoDataUris,
        'createdAt'  : FieldValue.serverTimestamp(),
        'respondedBy': null,
        'resolvedAt' : null,
      });

      // Simpan ID — home page langsung watch satu dokumen ini
      _activeRequestId = ref.id;

      // Notifikasi ke satpam on duty (fire-and-forget).
      OneSignalService.instance.sendBantuanBaruToSatpam(
        namaWarga : namaWarga,
        blok      : blok,
        nomorUnit : nomorUnit,
        kategori  : kategori,
      );

      return BantuanRequest(
        id        : ref.id,
        uid       : uid,
        namaWarga : namaWarga,
        blok      : blok,
        nomorUnit : nomorUnit,
        kategori  : kategori,
        catatan   : catatan,
        status    : BantuanStatus.pending,
        createdAt : DateTime.now(),
        fotoUrls  : fotoDataUris,
      );
    } catch (_) {
      return null;
    }
  }

  // ── Update status oleh satpam ─────────────────────────────────────────────
  static Future<bool> updateStatus({
    required String requestId,
    required BantuanStatus status,
    String? respondedBy,
  }) async {
    try {
      final data = <String, dynamic>{'status': _statusString(status)};
      // Satpam yang merespons "mengklaim" request (keluar dari kolam bersama).
      if (respondedBy != null) {
        data['respondedBy'] = respondedBy;
      }
      if (status == BantuanStatus.resolved) {
        data['resolvedAt'] = FieldValue.serverTimestamp();
      }
      await _col.doc(requestId).update(data);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Batalkan oleh user ────────────────────────────────────────────────────
  static Future<bool> cancelRequest(String requestId) async {
    try {
      await _col.doc(requestId).update({'status': 'CANCELLED'});
      _activeRequestId = null; // bersihkan ID setelah batal
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Watch satu dokumen by ID — SAMA PERSIS dengan SosService.watchAlert ───
  static Stream<BantuanRequest?> watchRequest(String requestId) {
    return _col.doc(requestId).snapshots().map((snap) {
      if (!snap.exists) return null;
      try {
        return BantuanRequest.fromDoc(snap);
      } catch (_) {
        return null;
      }
    });
  }

  // ── Stream untuk kartu home user — watch satu dokumen by ID ──────────────
  // Sama dengan cara SosStatusPage watch alert nya
  // Fallback: kalau _activeRequestId null, cari dari Firestore dulu
  static Stream<BantuanRequest?> watchMyActiveRequest(String uid) async* {
    // Cari ID jika tidak ada di cache (mis. setelah app restart)
    if (_activeRequestId == null) {
      try {
        final snap = await _col
            .where('uid', isEqualTo: uid)
            .where('status', whereIn: ['PENDING', 'ON_MY_WAY'])
            .get();
        if (snap.docs.isNotEmpty) {
          // Ambil yang terbaru
          final sorted = snap.docs.toList()
            ..sort((a, b) {
              final at = (a.data() as Map)['createdAt'] as Timestamp?;
              final bt = (b.data() as Map)['createdAt'] as Timestamp?;
              if (at == null && bt == null) return 0;
              if (at == null) return 1;
              if (bt == null) return -1;
              return bt.compareTo(at);
            });
          _activeRequestId = sorted.first.id;
        }
      } catch (e) {
        debugPrint('[BantuanService] lookup error: $e');
      }
    }

    // Tidak ada request aktif
    if (_activeRequestId == null) {
      yield null;
      return;
    }

    // Watch satu dokumen by ID — tidak perlu scan collection
    yield* _col.doc(_activeRequestId!).snapshots().map((snap) {
      if (!snap.exists) {
        _activeRequestId = null;
        return null;
      }
      try {
        final req = BantuanRequest.fromDoc(snap);
        // Bersihkan ID kalau sudah selesai atau dibatalkan
        if (req.status == BantuanStatus.resolved ||
            req.status == BantuanStatus.cancelled) {
          _activeRequestId = null;
          return null;
        }
        return req;
      } catch (e) {
        debugPrint('[BantuanService] parse error: $e');
        return null;
      }
    });
  }

  // ── Stream request aktif — untuk satpam (sama persis dengan SOS) ──────────
  static Stream<List<BantuanRequest>> watchActiveRequests() {
    return _col
        .where('status', whereIn: ['PENDING', 'ON_MY_WAY'])
        .snapshots()
        .map((snap) {
          final list = <BantuanRequest>[];
          for (final doc in snap.docs) {
            try {
              list.add(BantuanRequest.fromDoc(doc));
            } catch (e) {
              debugPrint('[BantuanService] skip doc ${doc.id}: $e');
            }
          }
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // ── Kolam bersama: request PENDING yang belum direspons satpam mana pun ────
  static Stream<List<BantuanRequest>> watchUnrespondedPending() {
    return _col
        .where('status', isEqualTo: 'PENDING')
        .snapshots()
        .map((snap) {
          final list = <BantuanRequest>[];
          for (final doc in snap.docs) {
            try {
              final r = BantuanRequest.fromDoc(doc);
              if (r.respondedBy == null || r.respondedBy!.isEmpty) list.add(r);
            } catch (e) {
              debugPrint('[BantuanService] skip ${doc.id}: $e');
            }
          }
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // ── Request aktif yang sudah direspons satpam tertentu ────────────────────
  static Stream<List<BantuanRequest>> watchRespondedBy(String satpamUid) {
    return _col
        .where('respondedBy', isEqualTo: satpamUid)
        .snapshots()
        .map((snap) {
          final list = <BantuanRequest>[];
          for (final doc in snap.docs) {
            try {
              final r = BantuanRequest.fromDoc(doc);
              if (r.status == BantuanStatus.pending ||
                  r.status == BantuanStatus.onMyWay) list.add(r);
            } catch (e) {
              debugPrint('[BantuanService] skip ${doc.id}: $e');
            }
          }
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // ── Inbox satpam ──────────────────────────────────────────────────────────
  // includeShared=true (BERTUGAS): kolam bersama (PENDING belum direspons) +
  //   request yang sudah dia respons. includeShared=false (OFF-DUTY): hanya
  //   yang sudah dia respons (agar tetap bisa menyelesaikannya).
  static Stream<List<BantuanRequest>> watchSatpamInbox(
    String satpamUid, {
    required bool includeShared,
  }) {
    if (!includeShared) return watchRespondedBy(satpamUid);

    final controller = StreamController<List<BantuanRequest>>();
    var mine   = <BantuanRequest>[];
    var shared = <BantuanRequest>[];
    void emit() {
      final byId = <String, BantuanRequest>{};
      for (final r in [...mine, ...shared]) {
        byId[r.id] = r;
      }
      final merged = byId.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (!controller.isClosed) controller.add(merged);
    }
    final s1 = watchRespondedBy(satpamUid).listen((l) { mine = l; emit(); });
    final s2 = watchUnrespondedPending().listen((l) { shared = l; emit(); });
    controller.onCancel = () { s1.cancel(); s2.cancel(); };
    return controller.stream;
  }
}
