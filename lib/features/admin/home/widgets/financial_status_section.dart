import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../pembayaran/models/tagihan_model.dart';

class FinancialStatus extends StatelessWidget {
  const FinancialStatus({
    super.key,
    required this.totalTagihan,
    required this.totalDibayar,
    required this.totalMenunggu,
    required this.dibayarQris,
    required this.dibayarTunai,
    required this.countQris,
    required this.countTunai,
  });

  final int totalTagihan;
  final int totalDibayar;
  final int totalMenunggu;
  final int dibayarQris;
  final int dibayarTunai;
  final int countQris;
  final int countTunai;

  double get _persenTertagih =>
      totalTagihan == 0 ? 0 : totalDibayar / totalTagihan;

  double get _persenQris =>
      totalDibayar == 0 ? 0 : dibayarQris / totalDibayar;

  @override
  Widget build(BuildContext context) {
    final adaTagihan  = totalTagihan > 0;
    final adaDibayar  = totalDibayar > 0;
    final persenLabel = '${(_persenTertagih * 100).round()}% Tertagih';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FINANCIAL STATUS (BULAN INI)',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textGrey,
                  letterSpacing: 0.5)),

          const SizedBox(height: 16),

          if (!adaTagihan)
            Text('Belum ada tagihan bulan ini.',
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textGrey))
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(formatRupiah(totalTagihan),
                        style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                            height: 1)),
                    const SizedBox(height: 4),
                    Text(persenLabel,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF16A34A))),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CustomPaint(
                      painter: DonutChartPainter(progress: _persenTertagih)),
                ),
              ],
            ),

          const SizedBox(height: 16),

          // Progress bar tertagih
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sudah Dibayar',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textGrey)),
              Text(formatRupiah(totalDibayar),
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _persenTertagih,
              backgroundColor: Colors.grey.shade200,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 6,
            ),
          ),

          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Menunggu Pembayaran',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textGrey)),
              Text(formatRupiah(totalMenunggu),
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFDC2626))),
            ],
          ),

          if (adaDibayar) ...[
            const SizedBox(height: 18),
            Divider(height: 1, color: Colors.grey.shade100),
            const SizedBox(height: 14),

            Text('Metode Pembayaran',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textGrey,
                    letterSpacing: 0.4)),
            const SizedBox(height: 10),

            // QRIS row
            MetodeRow(
              icon      : Icons.qr_code,
              label     : 'QRIS (Pakasir)',
              amount    : dibayarQris,
              count     : countQris,
              iconColor : const Color(0xFF1D4ED8),
              bg        : const Color(0xFFEFF6FF),
              barColor  : const Color(0xFF3B82F6),
              barValue  : _persenQris,
            ),
            const SizedBox(height: 8),

            // Tunai row
            MetodeRow(
              icon      : Icons.payments_outlined,
              label     : 'Tunai (Manual)',
              amount    : dibayarTunai,
              count     : countTunai,
              iconColor : const Color(0xFF16A34A),
              bg        : const Color(0xFFF0FDF4),
              barColor  : const Color(0xFF22C55E),
              barValue  : totalDibayar == 0
                  ? 0
                  : dibayarTunai / totalDibayar,
            ),
          ],
        ],
      ),
    );
  }
}

class MetodeRow extends StatelessWidget {
  const MetodeRow({
    super.key,
    required this.icon,
    required this.label,
    required this.amount,
    required this.count,
    required this.iconColor,
    required this.bg,
    required this.barColor,
    required this.barValue,
  });

  final IconData icon;
  final String   label;
  final int      amount;
  final int      count;
  final Color    iconColor;
  final Color    bg;
  final Color    barColor;
  final double   barValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
              child: Icon(icon, size: 12, color: iconColor),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppColors.textGrey)),
            ),
            Text(
              amount > 0 ? formatRupiah(amount) : '-',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: amount > 0 ? AppColors.textDark : AppColors.textGrey),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: barValue,
                  backgroundColor: Colors.grey.shade100,
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  minHeight: 4,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$count txn',
              style: GoogleFonts.inter(
                  fontSize: 10, color: AppColors.textGrey),
            ),
          ],
        ),
      ],
    );
  }
}

class DonutChartPainter extends CustomPainter {
  const DonutChartPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center      = Offset(size.width / 2, size.height / 2);
    final radius      = size.width / 2;
    const strokeWidth = 8.0;

    final bgPaint = Paint()
      ..color       = Colors.grey.shade200
      ..style       = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap   = StrokeCap.round;
    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    final fgPaint = Paint()
      ..color       = AppColors.primary
      ..style       = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap   = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(DonutChartPainter old) => old.progress != progress;
}
