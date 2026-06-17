import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' show DateFormat;

/// Model satu dokumen "berita acara".
///
/// Dipindahkan ke folder `models/` agar dapat dipakai bersama oleh halaman
/// daftar berita maupun form berita tanpa saling impor antar-halaman.
class BeritaDoc {
  BeritaDoc({
    required this.id,
    required this.judul,
    required this.kategori,
    required this.konten,
    required this.authorUid,
    required this.imageUrl,
    required this.isPublished,
    required this.publishedAt,
    required this.viewCount,
  });

  final String id;
  final String judul;
  final String kategori;
  final String konten;
  final String authorUid;
  final String imageUrl;
  final bool isPublished;
  final DateTime? publishedAt;
  final int viewCount;

  factory BeritaDoc.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return BeritaDoc(
      id          : doc.id,
      judul       : (d['judul']     as String?) ?? '',
      kategori    : (d['kategori']  as String?) ?? '',
      konten      : (d['konten']    as String?) ?? '',
      authorUid   : (d['authorUid'] as String?) ?? '',
      imageUrl    : (d['imageUrl']  as String?) ?? '',
      isPublished : (d['isPublished'] as bool?) ?? false,
      publishedAt : (d['publishedAt'] as Timestamp?)?.toDate(),
      viewCount   : (d['viewCount']  as int?)    ?? 0,
    );
  }

  String get tanggalFormatted {
    if (publishedAt == null) return '-';
    return DateFormat('dd MMM yyyy').format(publishedAt!);
  }

  String get kategoriLabel => kategori.isNotEmpty
      ? '${kategori[0].toUpperCase()}${kategori.substring(1)}'
      : '-';
}
