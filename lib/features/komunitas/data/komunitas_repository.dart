import 'package:cloud_firestore/cloud_firestore.dart';

/// Akses data daftar warga untuk halaman Komunitas.
class KomunitasRepository {
  KomunitasRepository._();

  static final KomunitasRepository instance = KomunitasRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream seluruh warga (role `user`) terurut berdasarkan blok lalu unit.
  Stream<QuerySnapshot<Map<String, dynamic>>> wargaStream() => _db
      .collection('users')
      .where('role', isEqualTo: 'user')
      .orderBy('blok')
      .orderBy('nomorUnit')
      .snapshots();
}
