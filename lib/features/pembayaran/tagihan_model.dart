// Model data tagihan
// Ganti dengan data dari Firestore saat production

enum StatusTagihan { belumBayar, lunas, jatuhTempo, pending }

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
  final int jumlah;           // dalam rupiah
  final String jatuhTempo;
  final StatusTagihan status;
  final String? tanggalBayar;
  final String? metodeBayar;
  final String? orderId;      // order_id dari Midtrans

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
}

// ── Mock data ────────────────────────────────────────────────────────────────
// Ganti dengan stream dari Firestore collection /pembayaran

final TagihanModel mockTagihanAktif = TagihanModel(
  id: 'tagihan-2024-11',
  bulan: 'November',
  tahun: 2024,
  namaResiden: 'Alex Pratama',
  blok: 'Blok A',
  nomorUnit: '42',
  jumlah: 450000,
  jatuhTempo: '30 Nov 2024',
  status: StatusTagihan.belumBayar,
);

final List<TagihanModel> mockRiwayatTagihan = [
  TagihanModel(
    id: 'tagihan-2024-10',
    bulan: 'Oktober',
    tahun: 2024,
    namaResiden: 'Alex Pratama',
    blok: 'Blok A',
    nomorUnit: '42',
    jumlah: 450000,
    jatuhTempo: '30 Okt 2024',
    status: StatusTagihan.lunas,
    tanggalBayar: '15 Okt 2024',
    metodeBayar: 'GoPay',
  ),
  TagihanModel(
    id: 'tagihan-2024-09',
    bulan: 'September',
    tahun: 2024,
    namaResiden: 'Alex Pratama',
    blok: 'Blok A',
    nomorUnit: '42',
    jumlah: 450000,
    jatuhTempo: '30 Sep 2024',
    status: StatusTagihan.lunas,
    tanggalBayar: '20 Sep 2024',
    metodeBayar: 'Transfer BCA',
  ),
  TagihanModel(
    id: 'tagihan-2024-08',
    bulan: 'Agustus',
    tahun: 2024,
    namaResiden: 'Alex Pratama',
    blok: 'Blok A',
    nomorUnit: '42',
    jumlah: 450000,
    jatuhTempo: '30 Agt 2024',
    status: StatusTagihan.lunas,
    tanggalBayar: '10 Agt 2024',
    metodeBayar: 'QRIS',
  ),
  TagihanModel(
    id: 'tagihan-2024-07',
    bulan: 'Juli',
    tahun: 2024,
    namaResiden: 'Alex Pratama',
    blok: 'Blok A',
    nomorUnit: '42',
    jumlah: 400000,
    jatuhTempo: '30 Jul 2024',
    status: StatusTagihan.lunas,
    tanggalBayar: '05 Jul 2024',
    metodeBayar: 'GoPay',
  ),
];