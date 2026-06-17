import 'package:cloud_firestore/cloud_firestore.dart';

/// Akses data layanan warga (mis. kontak pusat bantuan).
class LayananRepository {
  LayananRepository._();

  static final LayananRepository instance = LayananRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Ambil data kontak dari `settings/kontak`. Mengembalikan `null` bila
  /// dokumen tidak ada.
  Future<Map<String, dynamic>?> fetchKontak() async {
    final doc = await _db.collection('settings').doc('kontak').get();
    if (doc.exists) return doc.data();
    return null;
  }
}
