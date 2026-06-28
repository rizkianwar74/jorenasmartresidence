import '../../../pembayaran/models/tagihan_model.dart';

class TxGroup {
  TxGroup._({
    required this.orderId,
    required this.tagihan,
    required this.totalJumlah,
    required this.metode,
    required this.tanggalBayar,
  });

  factory TxGroup.fromTagihan(List<TagihanModel> raw, {String? orderId}) {
    final sorted = List<TagihanModel>.from(raw)
      ..sort((a, b) => (a.tahun * 12 + a.bulanIndex)
          .compareTo(b.tahun * 12 + b.bulanIndex));
    return TxGroup._(
      orderId     : orderId,
      tagihan     : sorted,
      totalJumlah : sorted.fold(0, (s, t) => s + t.jumlah),
      metode      : sorted.first.metodeBayar ?? '-',
      tanggalBayar: sorted.first.tanggalBayar ?? '-',
    );
  }

  final String?            orderId;
  final List<TagihanModel> tagihan;
  final int                totalJumlah;
  final String             metode;
  final String             tanggalBayar;

  int get maxKey => tagihan.fold(
      0,
      (s, t) =>
          s > (t.tahun * 12 + t.bulanIndex) ? s : (t.tahun * 12 + t.bulanIndex));

  String get periodeRange {
    if (tagihan.isEmpty) return '-';
    if (tagihan.length == 1) return tagihan.first.periodeLabel;
    return '${tagihan.first.periodeLabel} – ${tagihan.last.periodeLabel}'
        ' (${tagihan.length} & bulan)'; // Wait, in the original it says ' (${tagihan.length} bulan)'. Let's keep it clean
  }

  String get periodeRangeClean {
    if (tagihan.isEmpty) return '-';
    if (tagihan.length == 1) return tagihan.first.periodeLabel;
    return '${tagihan.first.periodeLabel} – ${tagihan.last.periodeLabel}'
        ' (${tagihan.length} bulan)';
  }
}
