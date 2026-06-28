import 'package:cloud_firestore/cloud_firestore.dart';

class InsidenFormData {
  const InsidenFormData({
    required this.satpamUid,
    required this.namaSatpam,
    required this.kategori,
    required this.blok,
    required this.nomor,
    required this.detailLokasi,
    required this.deskripsi,
    required this.waktuKejadian,
  });

  final String satpamUid;
  final String namaSatpam;
  final String kategori;
  final String blok;
  final String nomor;
  final String detailLokasi;
  final String deskripsi;
  final DateTime waktuKejadian;

  Map<String, dynamic> toMap() {
    return {
      'satpamUid': satpamUid,
      'namaSatpam': namaSatpam,
      'kategori': kategori,
      'blok': blok,
      'nomor': nomor,
      'detailLokasi': detailLokasi,
      'deskripsi': deskripsi,
      'waktuKejadian': Timestamp.fromDate(waktuKejadian),
      'status': 'BARU',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
