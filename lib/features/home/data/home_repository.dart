import 'package:cloud_firestore/cloud_firestore.dart';

/// Akses data untuk feed beranda warga.
///
/// Menyatukan semua query Firestore yang sebelumnya ditulis langsung di
/// `home_page.dart`, sehingga halaman cukup berlangganan stream dari sini.
class HomeRepository {
  HomeRepository._();

  static final HomeRepository instance = HomeRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _keluhan     = 'keluhan';
  static const String _bantuan     = 'bantuanrequest';
  static const String _catatanTamu = 'catatantamu';
  static const String _insiden     = 'insiden';
  static const String _patroli     = 'patroli';

  /// Keluhan milik warga [uid] (diurutkan di sisi klien agar tak butuh index).
  Stream<QuerySnapshot<Map<String, dynamic>>> keluhanByUidStream(String uid) =>
      _db.collection(_keluhan).where('uid', isEqualTo: uid).snapshots();

  /// Permintaan bantuan milik warga [uid].
  Stream<QuerySnapshot<Map<String, dynamic>>> bantuanByUidStream(String uid) =>
      _db.collection(_bantuan).where('uid', isEqualTo: uid).snapshots();

  /// Catatan tamu yang menuju unit warga ([blok] + [nomorUnit]).
  Stream<QuerySnapshot<Map<String, dynamic>>> tamuByUnitStream(
    String blok,
    String nomorUnit,
  ) =>
      _db
          .collection(_catatanTamu)
          .where('blok', isEqualTo: blok)
          .where('nomorUnit', isEqualTo: nomorUnit)
          .snapshots();

  /// Insiden terbaru di lingkungan (informasi umum).
  Stream<QuerySnapshot<Map<String, dynamic>>> insidenTerbaruStream({int limit = 5}) =>
      _db
          .collection(_insiden)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots();

  /// Patroli yang sudah selesai, terbaru (informasi keamanan).
  Stream<QuerySnapshot<Map<String, dynamic>>> patroliSelesaiStream({int limit = 5}) =>
      _db
          .collection(_patroli)
          .where('status', isEqualTo: 'SELESAI')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots();
}
