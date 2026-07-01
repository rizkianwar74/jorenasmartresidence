import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/auth/auth_repository.dart';
import '../services/onesignal_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Enum
// ─────────────────────────────────────────────────────────────────────────────

enum SosType { sos, call }

enum SosStatus { pending, onMyWay, resolved, cancelled }

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

class SosAlert {
  const SosAlert({
    required this.id,
    required this.type,
    required this.status,
    required this.userId,
    required this.namaWarga,
    required this.blok,
    required this.nomorUnit,
    required this.createdAt,
    this.respondedBy,
    this.resolvedAt,
  });

  final String id;
  final SosType type;
  final SosStatus status;
  final String userId;
  final String namaWarga;
  final String blok;
  final String nomorUnit;
  final DateTime createdAt;
  final String? respondedBy;
  final DateTime? resolvedAt;

  // ── Label tipe untuk ditampilkan di UI ────────────────────────────────────
  String get typeLabel => type == SosType.sos ? 'SOS DARURAT' : 'Panggil Satpam';

  // ── Label status untuk ditampilkan di UI ──────────────────────────────────
  String get statusLabel {
    switch (status) {
      case SosStatus.pending:
        return 'Menunggu Respon';
      case SosStatus.onMyWay:
        return 'Satpam Menuju Lokasi';
      case SosStatus.resolved:
        return 'Selesai';
      case SosStatus.cancelled:
        return 'Dibatalkan';
    }
  }

  // ── Dari Firestore → SosAlert ─────────────────────────────────────────────
  factory SosAlert.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SosAlert(
      id: doc.id,
      type: data['type'] == 'SOS' ? SosType.sos : SosType.call,
      status: _parseStatus(data['status'] as String?),
      userId: data['userId'] as String? ?? '',
      namaWarga: data['namaWarga'] as String? ?? '',
      blok: data['blok'] as String? ?? '',
      nomorUnit: data['nomorUnit'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      respondedBy: data['respondedBy'] as String?,
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
    );
  }

  SosAlert copyWith({
    String? id,
    SosStatus? status,
    String? respondedBy,
    DateTime? resolvedAt,
  }) {
    return SosAlert(
      id: id ?? this.id,
      type: type,
      status: status ?? this.status,
      userId: userId,
      namaWarga: namaWarga,
      blok: blok,
      nomorUnit: nomorUnit,
      createdAt: createdAt,
      respondedBy: respondedBy ?? this.respondedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper konversi
// ─────────────────────────────────────────────────────────────────────────────

SosStatus _parseStatus(String? raw) {
  switch (raw) {
    case 'ON_MY_WAY':
      return SosStatus.onMyWay;
    case 'RESOLVED':
      return SosStatus.resolved;
    case 'CANCELLED':
      return SosStatus.cancelled;
    default:
      return SosStatus.pending;
  }
}

String _statusString(SosStatus s) {
  switch (s) {
    case SosStatus.pending:
      return 'PENDING';
    case SosStatus.onMyWay:
      return 'ON_MY_WAY';
    case SosStatus.resolved:
      return 'RESOLVED';
    case SosStatus.cancelled:
      return 'CANCELLED';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SosRepository
// ─────────────────────────────────────────────────────────────────────────────

class SosRepository {
  SosRepository._();

  static final _col =
      FirebaseFirestore.instance.collection('sosalert');

  // ── Kirim SOS (darurat — hold 3 detik) ───────────────────────────────────
  static Future<SosAlert?> sendSos() => _send(SosType.sos);

  // ── Kirim CALL (panggil satpam biasa) ────────────────────────────────────
  static Future<SosAlert?> sendCall() => _send(SosType.call);

  // ── Internal: tulis dokumen baru ke Firestore ─────────────────────────────
  static Future<SosAlert?> _send(SosType type) async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return null;

      final uid = firebaseUser.uid;

      // Coba dari in-memory dulu (Android/normal flow).
      // Fallback ke Firestore kalau null — terjadi di web setelah page refresh
      // karena AuthRepository._currentUser adalah static in-memory variable.
      final inMemory = AuthRepository.currentUser;
      String namaWarga;
      String blok;
      String nomorUnit;

      if (inMemory != null) {
        namaWarga = inMemory.namaLengkap;
        blok      = inMemory.blok;
        nomorUnit = inMemory.nomorUnit;
      } else {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        if (!doc.exists) return null;
        final d = doc.data()!;
        namaWarga = (d['namaLengkap'] as String?)?.isNotEmpty == true
            ? d['namaLengkap'] as String
            : (firebaseUser.displayName ?? 'Pengguna');
        blok      = (d['blok']      as String?) ?? '-';
        nomorUnit = (d['nomorUnit'] as String?) ?? '-';
      }

      final data = {
        'type': type == SosType.sos ? 'SOS' : 'CALL',
        'status': 'PENDING',
        'userId': uid,
        'namaWarga': namaWarga,
        'blok': blok,
        'nomorUnit': nomorUnit,
        'createdAt': FieldValue.serverTimestamp(),
        'respondedBy': null,
        'resolvedAt': null,
      };

      final ref = await _col.add(data);

      // Kirim push ke satpam bertugas (fire-and-forget; dokumen SOS
      // sudah tersimpan, jadi kegagalan push tidak memblok alur).
      OneSignalService.instance.sendSosToOnDutySatpam(
        isSos: type == SosType.sos,
        namaWarga: namaWarga,
        blok: blok,
        nomorUnit: nomorUnit,
      );

      return SosAlert(
        id: ref.id,
        type: type,
        status: SosStatus.pending,
        userId: uid,
        namaWarga: namaWarga,
        blok: blok,
        nomorUnit: nomorUnit,
        createdAt: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  // ── Update status oleh satpam ─────────────────────────────────────────────
  static Future<bool> updateStatus({
    required String alertId,
    required SosStatus status,
    String? respondedBy,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'status': _statusString(status),
      };

      if (respondedBy != null) {
        data['respondedBy'] = respondedBy;
      }

      if (status == SosStatus.resolved) {
        data['resolvedAt'] = FieldValue.serverTimestamp();
      }

      await _col.doc(alertId).update(data);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Batalkan alert oleh user ──────────────────────────────────────────────
  static Future<bool> cancelAlert(String alertId) async {
    try {
      await _col.doc(alertId).update({
        'status': _statusString(SosStatus.cancelled),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Stream satu alert — user pantau status real-time ─────────────────────
  static Stream<SosAlert?> watchAlert(String alertId) {
    return _col.doc(alertId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return SosAlert.fromDoc(snap);
    });
  }

  // ── Stream alert aktif (PENDING / ON_MY_WAY) — satpam listen ─────────────
  // Tidak pakai orderBy agar tidak perlu composite index — sort client-side
  static Stream<List<SosAlert>> watchActiveAlerts() {
    return _col
        .where('status', whereIn: ['PENDING', 'ON_MY_WAY'])
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(SosAlert.fromDoc).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // ── Stream riwayat alert milik user tertentu ──────────────────────────────
  // Tidak pakai orderBy — sort client-side
  static Stream<List<SosAlert>> watchUserHistory(String uid) {
    return _col
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(SosAlert.fromDoc).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list.take(20).toList();
        });
  }

  // ── Cek apakah ADA satpam yang sedang bertugas (isOnDuty == true) ────────
  // Dipakai sebelum/saat kirim SOS/CALL untuk menampilkan warning ke warga
  // bila tidak ada satpam yang online sama sekali, supaya warga tahu bahwa
  // tidak ada yang akan langsung merespons.
  static Future<bool> hasSatpamOnDuty() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'satpam')
          .where('isOnDuty', isEqualTo: true)
          .limit(1)
          .get();
      return snap.docs.isNotEmpty;
    } catch (_) {
      // Fail-open: kalau query gagal (mis. offline), jangan munculkan
      // warning palsu — anggap saja statusnya tidak diketahui dan lanjutkan.
      return true;
    }
  }

  // ── Cek apakah user punya alert aktif (belum selesai) ────────────────────
  // Dipakai agar user tidak kirim SOS dobel — filter client-side
  static Future<SosAlert?> getActiveAlertForUser(String uid) async {
    try {
      final snap = await _col
          .where('userId', isEqualTo: uid)
          .get();

      final list = snap.docs.map(SosAlert.fromDoc).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list.firstWhere(
        (a) => a.status == SosStatus.pending || a.status == SosStatus.onMyWay,
        orElse: () => throw StateError('none'),
      );
    } catch (_) {
      return null;
    }
  }
}
