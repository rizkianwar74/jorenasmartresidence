import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../pembayaran/data/payment_repository.dart';
import '../../pembayaran/models/tagihan_model.dart';
import 'widgets/billing_shared_widgets.dart';

/// Popup menu WhatsApp + Telepon.
void showHubungiMenu(BuildContext context, TagihanModel t) {
  final rawPhone = (t.nomorHp ?? '').replaceAll(RegExp(r'[^\d]'), '');
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Hubungi ${t.namaResiden}',
              style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.chat, color: Colors.green),
            title: Text('WhatsApp', style: GoogleFonts.inter(fontSize: 14)),
            subtitle: Text(rawPhone.isEmpty ? 'Nomor tidak tersedia' : rawPhone,
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey)),
            onTap: () {
              Navigator.pop(context);
              _openWhatsApp(context, rawPhone, t);
            },
          ),
          ListTile(
            leading: const Icon(Icons.call, color: AppColors.primary),
            title: Text('Telepon', style: GoogleFonts.inter(fontSize: 14)),
            onTap: () {
              Navigator.pop(context);
              _openCall(context, rawPhone);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

Future<void> _openWhatsApp(BuildContext context, String phone, TagihanModel t) async {
  if (phone.isEmpty) {
    _toast(context, 'Nomor HP warga tidak tersedia.');
    return;
  }
  final msg = Uri.encodeComponent(
      'Halo ${t.namaResiden}, ini pengingat dari pengelola Jorena Smart Residence. '
      'Iuran periode ${t.periodeLabel} (${t.jumlahFormatted}) belum dibayar. '
      'Mohon segera melakukan pembayaran. Terima kasih.');
  final url = 'https://wa.me/$phone?text=$msg';
  await _launch(context, url);
}

Future<void> _openCall(BuildContext context, String phone) async {
  if (phone.isEmpty) {
    _toast(context, 'Nomor HP warga tidak tersedia.');
    return;
  }
  await _launch(context, 'tel:$phone');
}

Future<void> _launch(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    _toast(context, 'Tidak bisa membuka link.');
  }
}

void _toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));
}

/// Bottom sheet untuk ubah status tagihan secara manual.
void showEditStatusDialog(BuildContext context, TagihanModel t) {
  final isLunas = t.status == StatusTagihan.lunas;
  bool loading   = false;

  showModalBottomSheet(
    context: context,
    isDismissible : false,
    enableDrag    : false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetCtx) => StatefulBuilder(
      builder: (sheetCtx, setSheet) {

        // ── Aksi: tandai 1 bulan lunas ────────────────────────────────────
        Future<void> bayarSatuBulan() async {
          setSheet(() => loading = true);
          try {
            await PaymentRepository.setStatusManual(
                tagihanId: t.id, status: StatusTagihan.lunas);
            if (sheetCtx.mounted) Navigator.pop(sheetCtx);
            _toast(context, '${t.namaResiden} – ${t.periodeLabel} ditandai Lunas.');
          } catch (e) {
            setSheet(() => loading = false);
            _toast(context, 'Gagal mengubah status: $e');
          }
        }

        // ── Aksi: tandai semua tunggakan lunas (dengan konfirmasi) ────────
        Future<void> bayarSemuaBulan() async {
          setSheet(() => loading = true);
          try {
            final tunggakan =
                await PaymentRepository.getWajibUnpaid(t.userId ?? '');
            setSheet(() => loading = false);

            if (tunggakan.isEmpty) {
              if (sheetCtx.mounted) Navigator.pop(sheetCtx);
              _toast(context, 'Tidak ada tunggakan untuk ${t.namaResiden}.');
              return;
            }

            final periodeList = tunggakan.map((x) => x.periodeLabel).join(' · ');
            final confirm = await showDialog<bool>(
              context: sheetCtx,
              builder: (dCtx) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: Text('Konfirmasi Pelunasan',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tandai ${tunggakan.length} bulan sebagai lunas?',
                      style: GoogleFonts.inter(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        periodeList,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.textGrey),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dCtx, false),
                    child: Text('Batal',
                        style: GoogleFonts.inter(
                            color: AppColors.textGrey)),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(dCtx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('Ya, Lunaskan',
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            );

            if (confirm != true) return;

            setSheet(() => loading = true);
            await PaymentRepository.markManyAsLunas(
              tagihanIds : tunggakan.map((x) => x.id).toList(),
              metodeBayar: 'Tunai (Manual)',
            );
            if (sheetCtx.mounted) Navigator.pop(sheetCtx);
            _toast(context, '${tunggakan.length} tagihan ${t.namaResiden} ditandai lunas.');
          } catch (e) {
            setSheet(() => loading = false);
            _toast(context, 'Gagal mengubah status: $e');
          }
        }

        // ── Aksi: tolak / batalkan pembayaran → kembali ke belumBayar ────────
        Future<void> tolakTagihan() async {
          final confirm = await showDialog<bool>(
            context: sheetCtx,
            builder: (dCtx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text('Tolak Pembayaran?',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              content: Text(
                'Status tagihan ${t.periodeLabel} milik ${t.namaResiden} '
                'akan dikembalikan menjadi Belum Bayar.',
                style: GoogleFonts.inter(fontSize: 13),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dCtx, false),
                  child: Text('Batal',
                      style: GoogleFonts.inter(color: AppColors.textGrey)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dCtx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Ya, Tolak',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          );

          if (confirm != true) return;

          setSheet(() => loading = true);
          try {
            await PaymentRepository.setStatusManual(
                tagihanId: t.id, status: StatusTagihan.belumBayar);
            if (sheetCtx.mounted) Navigator.pop(sheetCtx);
            _toast(context, 'Tagihan ${t.periodeLabel} ${t.namaResiden} dikembalikan ke Belum Bayar.');
          } catch (e) {
            setSheet(() => loading = false);
            _toast(context, 'Gagal mengubah status: $e');
          }
        }

        // ── Aksi: hapus riwayat → hapus dokumen permanen ─────────────────
        Future<void> hapusRiwayat() async {
          final confirm = await showDialog<bool>(
            context: sheetCtx,
            builder: (dCtx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text('Hapus Riwayat?',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              content: Text(
                'Dokumen tagihan ${t.periodeLabel} milik ${t.namaResiden} '
                'akan dihapus permanen dari database. Tindakan ini tidak '
                'dapat dibatalkan.',
                style: GoogleFonts.inter(fontSize: 13),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dCtx, false),
                  child: Text('Batal',
                      style: GoogleFonts.inter(color: AppColors.textGrey)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dCtx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Hapus',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          );

          if (confirm != true) return;

          setSheet(() => loading = true);
          try {
            await PaymentRepository.deleteTagihan(t.id);
            if (sheetCtx.mounted) Navigator.pop(sheetCtx);
            _toast(context, 'Riwayat tagihan ${t.periodeLabel} ${t.namaResiden} dihapus.');
          } catch (e) {
            setSheet(() => loading = false);
            _toast(context, 'Gagal menghapus riwayat: $e');
          }
        }

        // ── UI ────────────────────────────────────────────────────────────
        return PopScope(
          canPop: !loading,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: loading
                  ? const SizedBox(
                      height: 120,
                      child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary),
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ubah Status Pembayaran',
                          style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${t.namaResiden} · ${t.periodeLabel}',
                          style: GoogleFonts.inter(
                              fontSize: 13, color: AppColors.textGrey),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text('Status saat ini: ',
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.textGrey)),
                            StatusBadge(status: t.status),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (!isLunas) ...[
                          EditStatusTile(
                            icon      : Icons.payments_outlined,
                            iconColor : Colors.green.shade600,
                            bgColor   : Colors.green.shade50,
                            title     : 'Bayar Tunai 1 Bulan',
                            subtitle  : 'Tandai ${t.periodeLabel} sebagai lunas',
                            onTap     : bayarSatuBulan,
                          ),
                          const SizedBox(height: 8),
                          EditStatusTile(
                            icon      : Icons.checklist_rounded,
                            iconColor : Colors.green.shade800,
                            bgColor   : Colors.green.shade50,
                            title     : 'Bayar Tunai Beberapa Bulan',
                            subtitle  : 'Cek & lunasi semua tunggakan ${t.namaResiden}',
                            onTap     : bayarSemuaBulan,
                          ),
                          const SizedBox(height: 8),
                          EditStatusTile(
                            icon      : Icons.delete_outline_rounded,
                            iconColor : Colors.red.shade700,
                            bgColor   : Colors.red.shade50,
                            title     : 'Hapus Riwayat',
                            subtitle  : 'Hapus dokumen tagihan ini secara permanen',
                            onTap     : hapusRiwayat,
                          ),
                        ],
                        if (isLunas) ...[
                          EditStatusTile(
                            icon      : Icons.undo_rounded,
                            iconColor : Colors.orange.shade700,
                            bgColor   : Colors.orange.shade50,
                            title     : 'Tolak Tagihan',
                            subtitle  : 'Kembalikan ${t.periodeLabel} ke status Belum Bayar',
                            onTap     : tolakTagihan,
                          ),
                          const SizedBox(height: 8),
                          EditStatusTile(
                            icon      : Icons.delete_outline_rounded,
                            iconColor : Colors.red.shade700,
                            bgColor   : Colors.red.shade50,
                            title     : 'Hapus Riwayat',
                            subtitle  : 'Hapus dokumen tagihan ini secara permanen',
                            onTap     : hapusRiwayat,
                          ),
                        ],
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => Navigator.pop(sheetCtx),
                            child: Text('Batal',
                                style: GoogleFonts.inter(
                                    color: AppColors.textGrey,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    ),
  );
}

/// Dialog buat tagihan di muka.
void showBuatTagihanDialog(
  BuildContext context,
  TagihanModel t,
  List<TagihanModel> allTagihan,
) {
  final userTagihan =
      allTagihan.where((x) => x.userId == t.userId).toList();
  int baseBulan = DateTime.now().month;
  int baseTahun = DateTime.now().year;
  if (userTagihan.isNotEmpty) {
    final latest = userTagihan.reduce((a, b) =>
        (a.tahun * 12 + a.bulanIndex) > (b.tahun * 12 + b.bulanIndex)
            ? a
            : b);
    baseBulan = latest.bulanIndex;
    baseTahun = latest.tahun;
  }

  List<Map<String, int>> computeMonths(int count) {
    final result = <Map<String, int>>[];
    int b = baseBulan, y = baseTahun;
    for (int i = 0; i < count; i++) {
      b++;
      if (b > 12) { b = 1; y++; }
      result.add({'bulan': b, 'tahun': y});
    }
    return result;
  }

  int buatCount = 1;

  showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDlg) {
        final months  = computeMonths(buatCount);
        final preview = months
            .map((m) =>
                '${bulanPanjangList[m['bulan']! - 1]} ${m['tahun']}')
            .join(' · ');
        final totalBayar =
            formatRupiah(PaymentRepository.iuranBulanan * buatCount);

        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Buat Tagihan di Muka',
            style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.namaResiden,
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark)),
                          Text(t.unitLabel,
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.textGrey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Tagihan terakhir: '
                '${bulanPanjangList[baseBulan - 1]} $baseTahun',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textGrey),
              ),
              const SizedBox(height: 14),
              Text('Buat tagihan ke depan:',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textGrey)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DlgStepBtn(
                    icon: Icons.remove,
                    enabled: buatCount > 1,
                    onTap: () => setDlg(() => buatCount--),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      '$buatCount bulan',
                      style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark),
                    ),
                  ),
                  DlgStepBtn(
                    icon: Icons.add,
                    enabled: buatCount < 6,
                    onTap: () => setDlg(() => buatCount++),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Periode yang dibuat:',
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textGrey)),
                    const SizedBox(height: 4),
                    Text(preview,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textDark)),
                    const SizedBox(height: 4),
                    Text('Total: $totalBayar',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Batal',
                  style: GoogleFonts.inter(color: AppColors.textGrey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final monthsToBuat = computeMonths(buatCount);
                Navigator.pop(ctx);
                try {
                  int created = 0;
                  for (final m in monthsToBuat) {
                    final ok =
                        await PaymentRepository.createTagihanForMonth(
                      userId      : t.userId      ?? '',
                      namaResiden : t.namaResiden,
                      nomorHp     : t.nomorHp     ?? '',
                      blok        : t.blok,
                      nomorUnit   : t.nomorUnit,
                      bulanIndex  : m['bulan']!,
                      tahun       : m['tahun']!,
                    );
                    if (ok) created++;
                  }
                  if (!context.mounted) return;
                  _toast(context, created > 0
                      ? '$created tagihan berhasil dibuat untuk '
                          '${t.namaResiden}.'
                      : 'Semua tagihan tersebut sudah ada.');
                } catch (e) {
                  if (!context.mounted) return;
                  _toast(context, 'Gagal membuat tagihan: $e');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Buat $buatCount Tagihan',
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    ),
  );
}
