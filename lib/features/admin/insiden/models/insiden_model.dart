import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model satu laporan insiden (admin)
// ─────────────────────────────────────────────────────────────────────────────

class InsidenModel {
  InsidenModel({
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

  final String    id;
  final String    namaSatpam;
  final String    kategori;
  final String    blok;
  final String    nomor;
  final String    detailLokasi;
  final String    deskripsi;
  final DateTime  waktuKejadian;
  final String    status;
  final DateTime? createdAt;

  String get lokasiLabel => '$blok No. $nomor${detailLokasi.isNotEmpty ? ' · $detailLokasi' : ''}';

  factory InsidenModel.fromFirestore(String id, Map<String, dynamic> d) {
    DateTime toDate(dynamic ts) {
      if (ts is Timestamp) return ts.toDate();
      return DateTime.now();
    }

    return InsidenModel(
      id           : id,
      namaSatpam   : d['namaSatpam']    as String? ?? '-',
      kategori     : d['kategori']      as String? ?? 'Insiden',
      blok         : d['blok']          as String? ?? '-',
      nomor        : d['nomor']         as String? ?? '-',
      detailLokasi : d['detailLokasi']  as String? ?? '',
      deskripsi    : d['deskripsi']     as String? ?? '',
      waktuKejadian: toDate(d['waktuKejadian']),
      status       : d['status']        as String? ?? 'BARU',
      createdAt    : d['createdAt'] != null ? toDate(d['createdAt']) : null,
    );
  }
}

/// Opsi status yang bisa dipilih admin di dialog detail.
const insidenStatusOptions = ['BARU', 'DITANGANI', 'SELESAI'];
