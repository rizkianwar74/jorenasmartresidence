import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model satu catatan tamu di halaman Daftar Tamu (admin)
// ─────────────────────────────────────────────────────────────────────────────

class TamuModel {
  TamuModel({
    required this.id,
    required this.namaTamu,
    required this.jenisKendaraan,
    required this.nomorPlat,
    required this.kategoriKunjungan,
    required this.keterangan,
    required this.blokTujuan,
    required this.nomorRumahTujuan,
    required this.namaSatpam,
    required this.status,
    required this.waktuMasuk,
    this.waktuKeluar,
    this.createdAt,
  });

  final String    id;
  final String    namaTamu;
  final String    jenisKendaraan;
  final String    nomorPlat;
  final String    kategoriKunjungan;
  final String    keterangan;
  final String    blokTujuan;
  final String    nomorRumahTujuan;
  final String    namaSatpam;
  final String    status;
  final DateTime  waktuMasuk;
  final DateTime? waktuKeluar;
  final DateTime? createdAt;

  String get tujuanLabel => '$blokTujuan No. $nomorRumahTujuan';

  static DateTime _toDate(dynamic ts) =>
      ts is Timestamp ? ts.toDate() : DateTime.now();

  factory TamuModel.fromFirestore(String id, Map<String, dynamic> d) {
    return TamuModel(
      id                 : id,
      namaTamu           : d['namaTamu']           as String? ?? '-',
      jenisKendaraan     : d['jenisKendaraan']     as String? ?? '-',
      nomorPlat          : d['nomorPlat']          as String? ?? '-',
      kategoriKunjungan  : d['kategoriKunjungan']  as String? ?? '-',
      keterangan         : d['keterangan']         as String? ?? '',
      blokTujuan         : d['blokTujuan']         as String? ?? '-',
      nomorRumahTujuan   : d['nomorRumahTujuan']   as String? ?? '-',
      namaSatpam         : d['namaSatpam']         as String? ?? '-',
      status             : d['status']             as String? ?? 'MASUK',
      waktuMasuk         : _toDate(d['waktuMasuk']),
      waktuKeluar        : d['waktuKeluar'] != null ? _toDate(d['waktuKeluar']) : null,
      createdAt          : d['createdAt'] != null  ? _toDate(d['createdAt'])  : null,
    );
  }
}
