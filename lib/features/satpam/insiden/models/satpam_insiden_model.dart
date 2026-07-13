import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model insiden — versi khusus halaman satpam (read-only + update status).
// ─────────────────────────────────────────────────────────────────────────────
class SatpamInsidenItem {
  SatpamInsidenItem({
    required this.id,
    required this.namaSatpam,
    required this.kategori,
    required this.blok,
    required this.nomor,
    required this.detailLokasi,
    required this.deskripsi,
    required this.waktuKejadian,
    required this.status,
    required this.createdAt,
  });

  final String   id;
  final String   namaSatpam;
  final String   kategori;
  final String   blok;
  final String   nomor;
  final String   detailLokasi;
  final String   deskripsi;
  final DateTime waktuKejadian;
  final String   status;
  final DateTime createdAt;

  String get lokasiLabel =>
      '$blok No. $nomor${detailLokasi.isNotEmpty ? ' · $detailLokasi' : ''}';

  factory SatpamInsidenItem.fromDoc(QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    DateTime toDate(dynamic ts) =>
        ts is Timestamp ? ts.toDate() : DateTime.now();
    return SatpamInsidenItem(
      id           : doc.id,
      namaSatpam   : d['namaSatpam']   as String? ?? '-',
      kategori     : d['kategori']     as String? ?? 'Insiden',
      blok         : d['blok']         as String? ?? '-',
      nomor        : d['nomor']        as String? ?? '-',
      detailLokasi : d['detailLokasi'] as String? ?? '',
      deskripsi    : d['deskripsi']    as String? ?? '',
      waktuKejadian: toDate(d['waktuKejadian']),
      status       : d['status']       as String? ?? 'BARU',
      createdAt    : toDate(d['createdAt']),
    );
  }
}

const satpamInsidenStatusOptions = ['Semua', 'BARU', 'DITANGANI', 'SELESAI'];
