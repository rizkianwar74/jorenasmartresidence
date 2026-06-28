import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../pembayaran/models/tagihan_model.dart';
import 'payment_detail_shared_widgets.dart';
import 'timeline_widgets.dart';

class DetailTableSection extends StatelessWidget {
  const DetailTableSection({super.key, required this.allTagihan});
  final List<TagihanModel> allTagihan;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Rincian Tagihan per Bulan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            color: const Color(0xFFF8FAFC),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: const [
                Expanded(flex: 2, child: TblHeader('PERIODE')),
                Expanded(flex: 2, child: TblHeader('TAGIHAN')),
                Expanded(flex: 2, child: TblHeader('JATUH TEMPO')),
                Expanded(flex: 2, child: TblHeader('STATUS')),
                Expanded(flex: 2, child: TblHeader('KETERANGAN')),
              ],
            ),
          ),
          // Rows
          ...allTagihan.map((t) => DetailRow(tagihan: t)),

          // Info banner advance
          if (allTagihan.any(isAdvanceTagihan)) ...[
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF9C3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFDE047)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline,
                        size: 14, color: Color(0xFFCA8A04)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pembayaran lebih awal akan otomatis digunakan '
                        'saat tagihan bulan berjalan jatuh tempo.',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF854D0E)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  const DetailRow({super.key, required this.tagihan});
  final TagihanModel tagihan;

  bool get _isLunas => tagihan.status == StatusTagihan.lunas;
  bool get _isPakasirPaid =>
      _isLunas && (tagihan.orderId?.isNotEmpty == true);

  String get _keterangan {
    if (!_isLunas) return '-';
    return _isPakasirPaid ? 'Dibayar lebih awal' : 'Lunas Manual';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          // Periode
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(
                  _isLunas
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  size: 13,
                  color: _isLunas
                      ? Colors.green.shade500
                      : Colors.grey.shade400,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(tagihan.periodeLabel,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textDark),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          // Tagihan
          Expanded(
            flex: 2,
            child: Text(tagihan.jumlahFormatted,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark)),
          ),
          // Jatuh tempo
          Expanded(
            flex: 2,
            child: Text(tagihan.jatuhTempo,
                style: GoogleFonts.inter(
                    fontSize: 11, color: AppColors.textGrey)),
          ),
          // Status badge
          Expanded(
            flex: 2,
            child: DetailStatusBadge(status: tagihan.status),
          ),
          // Keterangan
          Expanded(
            flex: 2,
            child: Text(
              _keterangan,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: _isPakasirPaid
                    ? const Color(0xFF1D4ED8)
                    : AppColors.textGrey,
                fontStyle: _isPakasirPaid
                    ? FontStyle.normal
                    : FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
