import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/berita_doc.dart';

/// Akses data berita acara untuk sisi pembaca (warga).
///
/// Dipakai bersama oleh halaman beranda (ambil 3 teratas) dan halaman daftar
/// berita (ambil semua yang sudah publish) agar logika filter & urutannya
/// tidak diduplikasi di tiap halaman.
class BeritaRepository {
  BeritaRepository._();

  static final BeritaRepository instance = BeritaRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Ambil seluruh berita berstatus published, terurut dari yang terbaru.
  Future<List<BeritaDoc>> fetchPublished() async {
    final snap = await _db.collection('beritaacara').get();
    final all = snap.docs.map(BeritaDoc.fromDoc).toList();
    return all.where((b) => b.isPublished).toList()
      ..sort((a, b) {
        if (a.publishedAt == null && b.publishedAt == null) return 0;
        if (a.publishedAt == null) return 1;
        if (b.publishedAt == null) return -1;
        return b.publishedAt!.compareTo(a.publishedAt!);
      });
  }
}
