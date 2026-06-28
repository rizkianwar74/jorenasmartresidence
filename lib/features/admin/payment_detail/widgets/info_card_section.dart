import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../pembayaran/models/tagihan_model.dart';
import '../models/tx_group.dart';
import 'payment_detail_shared_widgets.dart';
import 'timeline_widgets.dart';

class InfoCardSection extends StatelessWidget {
  const InfoCardSection({
    super.key,
    required this.latestG,
    required this.allTagihan,
  });
  final TxGroup? latestG;
  final List<TagihanModel> allTagihan;

  // Helper: ikon & warna berdasarkan metode
  static (IconData, Color) _metodeIcon(String metode) {
    final lower = metode.toLowerCase();
    if (lower.contains('qris')) return (Icons.qr_code, const Color(0xFF1D4ED8));
    if (lower.contains('tunai')) return (Icons.payments_outlined, Colors.green);
    return (Icons.payment, AppColors.textGrey);
  }

  @override
  Widget build(BuildContext context) {
    String? catatan;
    final lg = latestG;
    if (lg != null) {
      final advance = lg.tagihan.where(isAdvanceTagihan).toList()
        ..sort((a, b) => (a.tahun * 12 + a.bulanIndex)
            .compareTo(b.tahun * 12 + b.bulanIndex));
      if (advance.isNotEmpty) {
        final n    = advance.length;
        final from = advance.first.periodeLabel;
        final to   = advance.last.periodeLabel;
        catatan = n == 1
            ? 'Pembayaran 1 bulan ke depan ($from)'
            : 'Pembayaran untuk $n bulan ke depan ($from – $to)';
      }
    }

    return SectionCard(
      title: 'Informasi Pembayaran',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: lg == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text('Belum ada transaksi',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.textGrey)),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InfoRow(
                    label: 'Metode Pembayaran',
                    value: lg.metode.isNotEmpty ? lg.metode : '-',
                    icon: _metodeIcon(lg.metode).$1,
                    iconColor: _metodeIcon(lg.metode).$2,
                  ),
                  const SizedBox(height: 12),
                  InfoRow(
                    label: 'Order ID',
                    value: lg.orderId ?? '-',
                    mono: true,
                  ),
                  const SizedBox(height: 12),
                  InfoRow(
                    label: 'Tanggal Pembayaran',
                    value: lg.tanggalBayar,
                    icon: Icons.calendar_today_outlined,
                  ),
                  const SizedBox(height: 12),
                  InfoRow(
                    label: 'Total Dibayar',
                    value: formatRupiah(lg.totalJumlah),
                    valueColor: AppColors.primary,
                    bold: true,
                  ),
                  const SizedBox(height: 12),
                  InfoRow(
                    label: 'Jumlah Bulan',
                    value: '${lg.tagihan.length} Bulan',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text('Status',
                            style: GoogleFonts.inter(
                                fontSize: 12, color: AppColors.textGrey)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Lunas',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700)),
                      ),
                    ],
                  ),
                  if (catatan != null) ...[
                    const SizedBox(height: 12),
                    InfoRow(
                        label: 'Catatan',
                        value: catatan,
                        valueColor: AppColors.textGrey),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Fitur unduh bukti pembayaran segera hadir.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.download_outlined, size: 16),
                      label: Text('Unduh Bukti Pembayaran',
                          style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
