import 'package:cloud_firestore/cloud_firestore.dart';

/// Akses data layanan warga.
///
/// Kontak darurat diambil langsung dari koleksi `users`
/// berdasarkan field `komunitasRole` ('KETUA RT' / 'KETUA STM').
/// Tidak lagi bergantung pada dokumen `settings/kontak`.
class LayananRepository {
  LayananRepository._();

  static final LayananRepository instance = LayananRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Ambil daftar kontak darurat: warga dengan komunitasRole
  /// 'KETUA RT' atau 'KETUA STM', diurutkan RT dulu baru STM.
  Future<List<Map<String, dynamic>>> fetchKontakDarurat() async {
    final snap = await _db
        .collection('users')
        .where('komunitasRole', whereIn: ['KETUA RT', 'KETUA STM'])
        .get();

    final docs = snap.docs.map((d) {
      final data = d.data();
      data['uid'] = d.id;
      return data;
    }).toList();

    // Urutkan: KETUA RT dulu, baru KETUA STM
    const order = ['KETUA RT', 'KETUA STM'];
    docs.sort((a, b) {
      final ia = order.indexOf(a['komunitasRole'] as String? ?? '');
      final ib = order.indexOf(b['komunitasRole'] as String? ?? '');
      return ia.compareTo(ib);
    });

    return docs;
  }
}
