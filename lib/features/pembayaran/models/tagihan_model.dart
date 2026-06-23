// Model data tagihan + mapping ke/dari Firestore collection 'tagihan'.
//
// Aturan bisnis: iuran bulanan = Rp 30.000/rumah. Tiap bulan dibuat 1
// dokumen tagihan per user (lihat PaymentRepository.ensureCurrentMonthTagihan).
// Kalau bulan sebelumnya belum dibayar, dokumennya TETAP terpisah per bulan
// (supaya admin tahu persis tagihan untuk bulan apa) — tapi di UI user,
// semua yang belum lunas dijumlah jadi satu "total tunggakan" yang harus
// dibayar sekali jalan (lihat TagihanListX di bawah).

enum StatusTagihan { belumBayar, lunas, jatuhTempo, pending }

const List<String> bulanPanjangList = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
];

const List<String> bulanSingkatList = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
];

/// Konversi nama bulan ("Juni") -> index 1-12. Fallback 1 kalau tidak match
/// (dokumen lama yang belum punya bulanIndex tersimpan).
int bulanToIndex(String bulan) {
  final i = bulanPanjangList.indexOf(bulan);
  return i == -1 ? 1 : i + 1;
}

/// Format angka rupiah dengan titik pemisah ribuan, mis. 30000 -> "Rp 30.000".
String formatRupiah(int value) {
  final str = value.toString();
  final buf = StringBuffer();
  for (int i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
    buf.write(str[i]);
  }
  return 'Rp ${buf.toString()}';
}

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

StatusTagihan statusTagihanFromString(String? s) {
  switch (s) {
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
    int? bulanIndex,
    this.userId,
    this.nomorHp,
    this.tanggalBayar,
    this.metodeBayar,
    this.orderId,
  }) : bulanIndex = bulanIndex ?? 0;

  final String id;
  final String bulan;
  final int bulanIndex; // 1-12, dipakai untuk urutan kronologis tunggakan
  final int tahun;
  final String namaResiden;
  final String blok;
  final String nomorUnit;
  final int jumlah; // dalam rupiah
  final String jatuhTempo;
  final StatusTagihan status;
  final String? userId;
  final String? nomorHp;
  final String? tanggalBayar;
  final String? metodeBayar;
  final String? orderId; // order_id dari Midtrans

  /// Key kronologis (tahun*100 + bulanIndex) untuk sorting periode lama -> baru.
  int get periodeKey => tahun * 100 + (bulanIndex == 0 ? bulanToIndex(bulan) : bulanIndex);

  String get unitLabel => '$blok - No. $nomorUnit';
  String get periodeLabel => '$bulan $tahun';
  String get jumlahFormatted => formatRupiah(jumlah);

  factory TagihanModel.fromMap(String id, Map<String, dynamic> data) {
    final bulan = data['bulan'] as String? ?? '-';
    return TagihanModel(
      id: id,
      bulan: bulan,
      bulanIndex: data['bulanIndex'] as int? ?? bulanToIndex(bulan),
      tahun: data['tahun'] as int? ?? DateTime.now().year,
      namaResiden: data['namaResiden'] as String? ?? '-',
      blok: data['blok'] as String? ?? '-',
      nomorUnit: data['nomorUnit'] as String? ?? '-',
      jumlah: data['jumlah'] as int? ?? 0,
      jatuhTempo: data['jatuhTempo'] as String? ?? '-',
      status: statusTagihanFromString(data['status'] as String?),
      userId: data['userId'] as String?,
      nomorHp: data['nomorHp'] as String?,
      tanggalBayar: data['tanggalBayar'] as String?,
      metodeBayar: data['metodeBayar'] as String?,
      orderId: data['orderId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'namaResiden': namaResiden,
      'nomorHp': nomorHp,
      'blok': blok,
      'nomorUnit': nomorUnit,
      'bulan': bulan,
      'bulanIndex': bulanIndex == 0 ? bulanToIndex(bulan) : bulanIndex,
      'tahun': tahun,
      'jumlah': jumlah,
      'jatuhTempo': jatuhTempo,
      'status': statusTagihanToString(status),
      'tanggalBayar': tanggalBayar,
      'metodeBayar': metodeBayar,
      'orderId': orderId,
    };
  }

  TagihanModel copyWith({
    StatusTagihan? status,
    String? tanggalBayar,
    String? metodeBayar,
    String? orderId,
  }) {
    return TagihanModel(
      id: id,
      bulan: bulan,
      bulanIndex: bulanIndex,
      tahun: tahun,
      namaResiden: namaResiden,
      blok: blok,
      nomorUnit: nomorUnit,
      jumlah: jumlah,
      jatuhTempo: jatuhTempo,
      status: status ?? this.status,
      userId: userId,
      nomorHp: nomorHp,
      tanggalBayar: tanggalBayar ?? this.tanggalBayar,
      metodeBayar: metodeBayar ?? this.metodeBayar,
      orderId: orderId ?? this.orderId,
    );
  }
}

// ── Helper untuk daftar tagihan (dipakai di home/tagihan page) ──────────────
extension TagihanListX on List<TagihanModel> {
  /// Semua tagihan yang belum lunas, diurutkan dari bulan paling lama.
  List<TagihanModel> get unpaidSorted {
    final u = where((t) => t.status != StatusTagihan.lunas).toList();
    u.sort((a, b) => a.periodeKey.compareTo(b.periodeKey));
    return u;
  }

  /// Total rupiah dari semua tagihan yang belum lunas (akumulasi tunggakan).
  int get totalUnpaid =>
      unpaidSorted.fold(0, (sum, t) => sum + t.jumlah);
}
