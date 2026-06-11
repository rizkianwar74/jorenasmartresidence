import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/auth/auth_repository.dart';

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
// SosService
// ─────────────────────────────────────────────────────────────────────────────

class SosService {
  SosService._();

  static final _col =
      FirebaseFirestore.instance.collection('sosalert');

  // ── Kirim SOS (darurat — hold 3 detik) ───────────────────────────────────
  static Future<SosAlert?> sendSos() => _send(SosType.sos);

  // ── Kirim CALL (panggil satpam biasa) ────────────────────────────────────
  static Future<SosAlert?> sendCall() => _send(SosType.call);

  // ── Internal: tulis dokumen baru ke Firestore ─────────────────────────────
  static Future<SosAlert?> _send(SosType type) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final user = AuthRepository.currentUser;

      if (uid == null || user == null) return null;

      final data = {
        'type': type == SosType.sos ? 'SOS' : 'CALL',
        'status': 'PENDING',
        'userId': uid,
        'namaWarga': user.namaLengkap,
        'blok': user.blok,
        'nomorUnit': user.nomorUnit,
        'createdAt': FieldValue.serverTimestamp(),
        'respondedBy': null,
        'resolvedAt': null,
      };

      final ref = await _col.add(data);

      // Kembalikan SosAlert dengan id dokumen yang baru dibuat
      return SosAlert(
        id: ref.id,
        type: type,
        status: SosStatus.pending,
        userId: uid,
        namaWarga: user.namaLengkap,
        blok: user.blok,
        nomorUnit: user.nomorUnit,
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
  static Stream<List<SosAlert>> watchActiveAlerts() {
    return _col
        .where('status', whereIn: ['PENDING', 'ON_MY_WAY'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(SosAlert.fromDoc).toList());
  }

  // ── Stream riwayat alert milik user tertentu ──────────────────────────────
  static Stream<List<SosAlert>> watchUserHistory(String uid) {
    return _col
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) => snap.docs.map(SosAlert.fromDoc).toList());
  }

  // ── Cek apakah user punya alert aktif (belum selesai) ────────────────────
  // Dipakai agar user tidak kirim SOS dobel
  static Future<SosAlert?> getActiveAlertForUser(String uid) async {
    try {
      final snap = await _col
          .where('userId', isEqualTo: uid)
          .where('status', whereIn: ['PENDING', 'ON_MY_WAY'])
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return null;
      return SosAlert.fromDoc(snap.docs.first);
    } catch (_) {
      return null;
    }
  }
}
