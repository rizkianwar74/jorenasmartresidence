import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Sumber tunggal akses data Firestore untuk seluruh fitur Admin.
///
/// Tujuan kelas ini adalah memisahkan logika akses data (Firestore) dari
/// lapisan UI (halaman/widget). Halaman admin cukup memanggil method di sini
/// dan tidak lagi menulis `FirebaseFirestore.instance` secara langsung.
/// Dengan begitu nama koleksi, query, dan operasi tulis terpusat di satu tempat
/// sehingga lebih mudah diuji, diubah, dan dipakai ulang.
class AdminRepository {
  AdminRepository._();

  /// Instance tunggal (singleton) yang dipakai semua halaman admin.
  static final AdminRepository instance = AdminRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Nama koleksi (terpusat) ────────────────────────────────────────────────
  static const String _users       = 'users';
  static const String _patroli     = 'patroli';
  static const String _insiden     = 'insiden';
  static const String _catatanTamu = 'catatantamu';
  static const String _beritaAcara = 'beritaacara';
  static const String _sosAlert    = 'sosalert';
  static const String _bantuan     = 'bantuanrequest';
  static const String _keluhan     = 'keluhan';

  /// UID admin yang sedang login (fallback `'admin'` bila tidak tersedia).
  String get currentAdminUid =>
      FirebaseAuth.instance.currentUser?.uid ?? 'admin';

  Timestamp _ts(DateTime d) => Timestamp.fromDate(d);

  // ── Warga (users dengan role == user) ──────────────────────────────────────

  /// Stream semua warga (role `user`) tanpa urutan khusus.
  Stream<QuerySnapshot<Map<String, dynamic>>> wargaStream() => _db
      .collection(_users)
      .where('role', isEqualTo: 'user')
      .snapshots();

  /// Stream warga terurut berdasarkan blok lalu nomor unit.
  Stream<QuerySnapshot<Map<String, dynamic>>> wargaSortedStream() => _db
      .collection(_users)
      .where('role', isEqualTo: 'user')
      .orderBy('blok')
      .orderBy('nomorUnit')
      .snapshots();

  Future<void> updateWarga(String uid, Map<String, dynamic> data) =>
      _db.collection(_users).doc(uid).update(data);

  Future<void> deleteWarga(String uid) =>
      _db.collection(_users).doc(uid).delete();

  // ── Satpam (users dengan role == satpam) ───────────────────────────────────

  Stream<QuerySnapshot<Map<String, dynamic>>> satpamStream() => _db
      .collection(_users)
      .where('role', isEqualTo: 'satpam')
      .snapshots();

  // ── Patroli ────────────────────────────────────────────────────────────────

  Stream<QuerySnapshot<Map<String, dynamic>>> patroliAktifStream() => _db
      .collection(_patroli)
      .where('status', isEqualTo: 'AKTIF')
      .snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> patroliSejakStream(DateTime start) => _db
      .collection(_patroli)
      .where('createdAt', isGreaterThanOrEqualTo: _ts(start))
      .snapshots();

  // ── SOS & Bantuan ──────────────────────────────────────────────────────────

  Stream<QuerySnapshot<Map<String, dynamic>>> sosSejakStream(DateTime start) => _db
      .collection(_sosAlert)
      .where('createdAt', isGreaterThanOrEqualTo: _ts(start))
      .snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> bantuanSejakStream(DateTime start) => _db
      .collection(_bantuan)
      .where('createdAt', isGreaterThanOrEqualTo: _ts(start))
      .snapshots();

  // ── Catatan tamu ───────────────────────────────────────────────────────────

  /// Stream seluruh catatan tamu (terbaru di atas).
  Stream<QuerySnapshot<Map<String, dynamic>>> tamuStream() => _db
      .collection(_catatanTamu)
      .orderBy('createdAt', descending: true)
      .snapshots();

  /// Stream catatan tamu sejak [start] (mis. untuk hitungan "tamu hari ini").
  Stream<QuerySnapshot<Map<String, dynamic>>> tamuSejakStream(DateTime start) => _db
      .collection(_catatanTamu)
      .where('createdAt', isGreaterThanOrEqualTo: _ts(start))
      .snapshots();

  Future<void> tandaiTamuKeluar(String id) =>
      _db.collection(_catatanTamu).doc(id).update({
        'status'     : 'KELUAR',
        'waktuKeluar': FieldValue.serverTimestamp(),
      });

  // ── Insiden ─────────────────────────────────────────────────────────────────

  /// Stream seluruh insiden (terbaru di atas).
  Stream<QuerySnapshot<Map<String, dynamic>>> insidenStream() => _db
      .collection(_insiden)
      .orderBy('createdAt', descending: true)
      .snapshots();

  /// Stream insiden terbaru dengan batas [limit].
  Stream<QuerySnapshot<Map<String, dynamic>>> insidenTerbaruStream({int limit = 10}) => _db
      .collection(_insiden)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots();

  Future<void> updateInsidenStatus(String id, String newStatus) =>
      _db.collection(_insiden).doc(id).update({
        'status'   : newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  // ── Keluhan ──────────────────────────────────────────────────────────────────

  Stream<QuerySnapshot<Map<String, dynamic>>> keluhanTerbaruStream({int limit = 20}) => _db
      .collection(_keluhan)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots();

  // ── Berita acara ─────────────────────────────────────────────────────────────

  Stream<QuerySnapshot<Map<String, dynamic>>> beritaStream() =>
      _db.collection(_beritaAcara).snapshots();

  Future<void> createBerita(Map<String, dynamic> data) =>
      _db.collection(_beritaAcara).add(data);

  Future<void> updateBerita(String id, Map<String, dynamic> data) =>
      _db.collection(_beritaAcara).doc(id).update(data);

  Future<void> deleteBerita(String id) =>
      _db.collection(_beritaAcara).doc(id).delete();
}
