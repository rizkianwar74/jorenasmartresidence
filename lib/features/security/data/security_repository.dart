import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../auth/auth_repository.dart';

/// Sumber tunggal akses data Firestore/Storage untuk halaman-halaman satpam
/// (feature `security`).
///
/// Tujuannya sama seperti [AdminRepository]: memindahkan seluruh pemanggilan
/// `FirebaseFirestore.instance`, `FirebaseStorage.instance`, dan
/// `FirebaseAuth.instance` dari lapisan UI ke satu tempat agar mudah dipakai
/// ulang, diubah, dan diuji.
class SecurityRepository {
  SecurityRepository._();

  static final SecurityRepository instance = SecurityRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ── Nama koleksi (terpusat) ────────────────────────────────────────────────
  static const String _users       = 'users';
  static const String _patroli     = 'patroli';
  static const String _bantuan     = 'bantuanrequest';
  static const String _insiden     = 'insiden';
  static const String _catatanTamu = 'catatantamu';
  static const String _sosAlert    = 'sosalert';

  // ── Identitas satpam yang sedang login ─────────────────────────────────────

  /// UID satpam aktif (string kosong bila tidak ada — mempertahankan perilaku
  /// lama `?? ''`).
  String get currentSatpamUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  /// UID satpam aktif yang boleh `null` (untuk pemanggil yang membedakan
  /// null vs string kosong).
  String? get currentSatpamUidOrNull => FirebaseAuth.instance.currentUser?.uid;

  /// Nama tampilan satpam: ambil dari profil aplikasi bila ada, jika tidak
  /// fallback ke displayName akun, lalu `'Satpam'`.
  String get satpamDisplayName {
    final appUser = AuthRepository.currentUser;
    if (appUser != null && appUser.namaLengkap.isNotEmpty) {
      return appUser.namaLengkap;
    }
    return FirebaseAuth.instance.currentUser?.displayName ?? 'Satpam';
  }

  // ── Profil & status bertugas satpam ────────────────────────────────────────

  /// Ambil dokumen profil user [uid] (mis. untuk membaca `isOnDuty`).
  Future<Map<String, dynamic>?> fetchUser(String uid) async {
    final doc = await _db.collection(_users).doc(uid).get();
    return doc.data();
  }

  /// Set status bertugas (`isOnDuty`) satpam [uid].
  Future<void> setOnDuty(String uid, bool value) =>
      _db.collection(_users).doc(uid).update({'isOnDuty': value});

  // ── Stream untuk dashboard security ────────────────────────────────────────

  /// Satpam yang sedang bertugas (role `satpam` & `isOnDuty == true`).
  Stream<QuerySnapshot<Map<String, dynamic>>> satpamOnDutyStream() => _db
      .collection(_users)
      .where('role', isEqualTo: 'satpam')
      .where('isOnDuty', isEqualTo: true)
      .snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> patroliTerbaruStream({int limit = 10}) => _db
      .collection(_patroli)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots();

  /// Semua patroli yang sedang `AKTIF` (mis. untuk menghitung jumlahnya).
  Stream<QuerySnapshot<Map<String, dynamic>>> patroliAktifStream() => _db
      .collection(_patroli)
      .where('status', isEqualTo: 'AKTIF')
      .snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> bantuanTerbaruStream({int limit = 10}) => _db
      .collection(_bantuan)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots();

  /// SOS alert terbaru (untuk feed aktivitas satpam).
  Stream<QuerySnapshot<Map<String, dynamic>>> sosTerbaruStream({int limit = 5}) => _db
      .collection(_sosAlert)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> insidenTerbaruStream({int limit = 10}) => _db
      .collection(_insiden)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots();

  /// Insiden berstatus `BARU` (untuk monitor jumlah insiden aktif).
  Stream<QuerySnapshot<Map<String, dynamic>>> insidenBaruStream() => _db
      .collection(_insiden)
      .where('status', isEqualTo: 'BARU')
      .snapshots();

  /// Semua insiden, terbaru di atas — untuk halaman list satpam.
  Stream<QuerySnapshot<Map<String, dynamic>>> insidenStream() => _db
      .collection(_insiden)
      .orderBy('createdAt', descending: true)
      .snapshots();

  /// Update status insiden.
  Future<void> updateInsidenStatus(String id, String status) =>
      _db.collection(_insiden).doc(id).update({'status': status});

  Stream<QuerySnapshot<Map<String, dynamic>>> tamuTerbaruStream({int limit = 10}) => _db
      .collection(_catatanTamu)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots();

  // ── Catatan tamu ───────────────────────────────────────────────────────────

  /// Catatan tamu pada rentang waktu [start]..[end] (terbaru di atas).
  Stream<QuerySnapshot<Map<String, dynamic>>> tamuRentangStream(
    DateTime start,
    DateTime end,
  ) => _db
      .collection(_catatanTamu)
      .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
      .where('createdAt', isLessThan: Timestamp.fromDate(end))
      .orderBy('createdAt', descending: true)
      .snapshots();

  Future<void> tandaiTamuKeluar(String id) =>
      _db.collection(_catatanTamu).doc(id).update({
        'status'     : 'KELUAR',
        'waktuKeluar': FieldValue.serverTimestamp(),
      });

  /// Catat tamu baru. [data] adalah field spesifik form; status & timestamp
  /// standar ditambahkan di sini.
  Future<void> catatTamu(Map<String, dynamic> data) =>
      _db.collection(_catatanTamu).add(data);

  // ── Patroli ──────────────────────────────────────────────────────────────────

  /// Cari patroli berstatus AKTIF milik [uid] (maks 1).
  Future<QuerySnapshot<Map<String, dynamic>>> patroliAktifByUid(String uid) => _db
      .collection(_patroli)
      .where('satpamUid', isEqualTo: uid)
      .where('status', isEqualTo: 'AKTIF')
      .limit(1)
      .get();

  /// Buat dokumen patroli baru, mengembalikan referensi dokumennya.
  Future<DocumentReference<Map<String, dynamic>>> mulaiPatroli(
          Map<String, dynamic> data) =>
      _db.collection(_patroli).add(data);

  Future<void> selesaiPatroli(String docId, Map<String, dynamic> data) =>
      _db.collection(_patroli).doc(docId).update(data);

  /// Unggah daftar foto patroli ke Storage, kembalikan URL unduhan yang sukses.
  Future<List<String>> uploadFotoPatroli(
    String uid,
    String docId,
    List<Uint8List> fotos,
  ) async {
    final urls = <String>[];
    for (int i = 0; i < fotos.length; i++) {
      try {
        final ref = _storage.ref().child('patroli/$uid/$docId/foto_$i.jpg');
        final task = await ref.putData(
          fotos[i],
          SettableMetadata(contentType: 'image/jpeg'),
        );
        urls.add(await task.ref.getDownloadURL());
      } catch (_) {
        // Lewati foto yang gagal diunggah.
      }
    }
    return urls;
  }

  // ── Insiden ─────────────────────────────────────────────────────────────────

  /// Kirim laporan insiden baru.
  Future<void> kirimInsiden(Map<String, dynamic> data) =>
      _db.collection(_insiden).add(data);
}
