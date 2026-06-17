// Model data tagihan.
// Data persisten di Firestore collection 'tagihan'.

enum StatusTagihan { belumBayar, lunas, jatuhTempo, pending }

/// Konversi enum <-> string Firestore.
String statusTagihanToString(StatusTagihan s) {
  switch (s) {
    case StatusTagihan.belumBayar:
      return 'belumBayar';
    case StatusTagihan.lunas:
      return 'lunas';
    case StatusTagihan.jatuhTempo:
      return 'jatuhTempo';
    case StatusTagihan.pending:
      return 'pending';
  }
}

StatusTagihan statusTagihanFromString(String? raw) {
  switch (raw) {
    case 'lunas':
      return StatusTagihan.lunas;
    case 'jatuhTempo':
      return StatusTagihan.jatuhTempo;
    case 'pending':
      return StatusTagihan.pending;
    case 'belumBayar':
    default:
      return StatusTagihan.belumBayar;
  }
}

class TagihanModel {
  const TagihanModel({
    required this.id,
    required this.bulan,
    required this.tahun,
    required this.namaResiden,
    required this.blok,
    required this.nomorUnit,
    required this.jumlah,
    required this.jatuhTempo,
    required this.status,
    this.userId,
    this.nomorHp,
    this.tanggalBayar,
    this.metodeBayar,
    this.orderId,
  });

  final String id;
  final String bulan;
  final int tahun;
  final String namaResiden;
  final String blok;
  final String nomorUnit;
  final int jumlah; // dalam rupiah
  final String jatuhTempo;
  final StatusTagihan status;
  final String? userId; // uid pemilik tagihan (Firestore)
  final String? nomorHp; // nomor HP untuk tombol Hubungi (denormalized)
  final String? tanggalBayar;
  final String? metodeBayar;
  final String? orderId; // order_id dari Midtrans

  String get unitLabel => '$blok - No. $nomorUnit';
  String get periodeLabel => '$bulan $tahun';
  String get jumlahFormatted {
    final str = jumlah.toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
      buf.write(str[i]);
    }
    return 'Rp ${buf.toString()}';
  }

  /// Buat model dari dokumen Firestore.
  factory TagihanModel.fromMap(String id, Map<String, dynamic> map) {
    return TagihanModel(
      id: id,
      userId: map['userId'] as String?,
      namaResiden: (map['namaResiden'] as String?) ?? 'Warga',
      nomorHp: map['nomorHp'] as String?,
      blok: (map['blok'] as String?) ?? '-',
      nomorUnit: (map['nomorUnit'] as String?) ?? '-',
      bulan: (map['bulan'] as String?) ?? '-',
      tahun: (map['tahun'] as num?)?.toInt() ?? 0,
      jumlah: (map['jumlah'] as num?)?.toInt() ?? 0,
      jatuhTempo: (map['jatuhTempo'] as String?) ?? '-',
      status: statusTagihanFromString(map['status'] as String?),
      tanggalBayar: map['tanggalBayar'] as String?,
      metodeBayar: map['metodeBayar'] as String?,
      orderId: map['orderId'] as String?,
    );
  }

  /// Serialisasi ke Firestore.
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'namaResiden': namaResiden,
        'nomorHp': nomorHp,
        'blok': blok,
        'nomorUnit': nomorUnit,
        'bulan': bulan,
        'tahun': tahun,
        'jumlah': jumlah,
        'jatuhTempo': jatuhTempo,
        'status': statusTagihanToString(status),
        'tanggalBayar': tanggalBayar,
        'metodeBayar': metodeBayar,
        'orderId': orderId,
      };

  TagihanModel copyWith({
    StatusTagihan? status,
    String? tanggalBayar,
    String? metodeBayar,
    String? orderId,
  }) {
    return TagihanModel(
      id: id,
      userId: userId,
      namaResiden: namaResiden,
      nomorHp: nomorHp,
      blok: blok,
      nomorUnit: nomorUnit,
      bulan: bulan,
      tahun: tahun,
      jumlah: jumlah,
      jatuhTempo: jatuhTempo,
      status: status ?? this.status,
      tanggalBayar: tanggalBayar ?? this.tanggalBayar,
      metodeBayar: metodeBayar ?? this.metodeBayar,
      orderId: orderId ?? this.orderId,
    );
  }
}

// ── Mock data (fallback bila Firestore kosong / mode demo) ──────────────────

final TagihanModel mockTagihanAktif = TagihanModel(
  id: 'tagihan-2026-06',
  bulan: 'Juni',
  tahun: 2026,
  namaResiden: 'Alex Pratama',
  blok: 'Blok A',
  nomorUnit: '42',
  nomorHp: '6281234567890',
  jumlah: 450000,
  jatuhTempo: '30 Jun 2026',
  status: StatusTagihan.belumBayar,
);

final List<TagihanModel> mockRiwayatTagihan = [
  TagihanModel(
    id: 'tagihan-2026-05',
    bulan: 'Mei',
    tahun: 2026,
    namaResiden: 'Alex Pratama',
    blok: 'Blok A',
    nomorUnit: '42',
    nomorHp: '6281234567890',
    jumlah: 450000,
    jatuhTempo: '30 Mei 2026',
    status: StatusTagihan.lunas,
    tanggalBayar: '15 Mei 2026',
    metodeBayar: 'GoPay',
  ),
  TagihanModel(
    id: 'tagihan-2026-04',
    bulan: 'April',
    tahun: 2026,
    namaResiden: 'Alex Pratama',
    blok: 'Blok A',
    nomorUnit: '42',
    nomorHp: '6281234567890',
    jumlah: 450000,
    jatuhTempo: '30 Apr 2026',
    status: StatusTagihan.lunas,
    tanggalBayar: '20 Apr 2026',
    metodeBayar: 'Transfer BCA',
  ),
  TagihanModel(
    id: 'tagihan-2026-03',
    bulan: 'Maret',
    tahun: 2026,
    namaResiden: 'Alex Pratama',
    blok: 'Blok A',
    nomorUnit: '42',
    nomorHp: '6281234567890',
    jumlah: 450000,
    jatuhTempo: '30 Mar 2026',
    status: StatusTagihan.lunas,
    tanggalBayar: '10 Mar 2026',
    metodeBayar: 'QRIS',
  ),
];
