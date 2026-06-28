import '../../../pembayaran/models/tagihan_model.dart';

/// Data class: ringkasan satu warga untuk tampilan billing per-warga.
class ResidentSummary {
  ResidentSummary(List<TagihanModel> tagihan) {
    assert(tagihan.isNotEmpty);
    final now        = DateTime.now();
    final currentKey = now.year * 100 + now.month;
    final ref        = tagihan.first;

    userId      = ref.userId ?? '';
    namaResiden = ref.namaResiden;
    blok        = ref.blok;
    nomorUnit   = ref.nomorUnit;
    nomorHp     = ref.nomorHp;
    anyTagihan  = ref;

    // Tunggakan = tagihan bulan ini dan sebelumnya yang belum lunas.
    final wajibUnpaid = tagihan
        .where((t) =>
            t.periodeKey <= currentKey && t.status != StatusTagihan.lunas)
        .toList();
    tunggakanCount = wajibUnpaid.length;
    totalUtang     = wajibUnpaid.fold(0, (s, t) => s + t.jumlah);

    // Periode lunas terakhir.
    final lunasList = tagihan
        .where((t) => t.status == StatusTagihan.lunas)
        .toList()
      ..sort((a, b) => b.periodeKey.compareTo(a.periodeKey));
    lunasSampai = lunasList.isNotEmpty ? lunasList.first.periodeLabel : null;

    // Status keseluruhan.
    if (wajibUnpaid.any((t) => t.status == StatusTagihan.jatuhTempo)) {
      overallStatus = StatusTagihan.jatuhTempo;
    } else if (wajibUnpaid.isNotEmpty) {
      overallStatus = StatusTagihan.belumBayar;
    } else {
      overallStatus = StatusTagihan.lunas;
    }
  }

  late final String        userId;
  late final String        namaResiden;
  late final String        blok;
  late final String        nomorUnit;
  late final String?       nomorHp;
  late final int           tunggakanCount;
  late final int           totalUtang;
  late final String?       lunasSampai;
  late final StatusTagihan overallStatus;
  late final TagihanModel  anyTagihan;

  String get unitLabel => '$blok-$nomorUnit';
}
