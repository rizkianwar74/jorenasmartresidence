import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../pembayaran/models/tagihan_model.dart';

// ── Summary box (Total Tagihan / Sudah Lunas / Belum Dibayar) ─────────────────
class SummaryBox extends StatelessWidget {
  const SummaryBox({
    super.key,
    required this.label,
    required this.rupiah,
    required this.count,
    required this.countLabel,
    required this.icon,
    required this.accentColor,
    this.persen,
  });

  final String   label;
  final int      rupiah;
  final int      count;
  final String   countLabel;
  final IconData icon;
  final Color    accentColor;
  /// Jika tidak null, tampilkan progress bar (dipakai di "Sudah Lunas").
  final double?  persen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label + ikon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textGrey,
                      letterSpacing: 0.5)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: accentColor),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Nominal
          Text(
            rupiah > 0 ? formatRupiah(rupiah) : 'Rp 0',
            style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
                height: 1),
          ),
          const SizedBox(height: 6),

          // Count + persen (jika ada)
          Row(
            children: [
              Text(
                '$count $countLabel',
                style: GoogleFonts.inter(
                    fontSize: 12, color: accentColor, fontWeight: FontWeight.w600),
              ),
              if (persen != null) ...[
                const SizedBox(width: 6),
                Text(
                  '· ${(persen! * 100).round()}%',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textGrey),
                ),
              ],
            ],
          ),

          // Progress bar opsional
          if (persen != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: persen,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
