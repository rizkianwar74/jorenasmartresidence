import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

enum PaymentStatus { paid, unpaid, overdue }

class UnitStatusCard extends StatelessWidget {
  const UnitStatusCard({
    super.key,
    required this.blockName,
    required this.unitNumber,
    required this.paymentStatus,
  });

  final String blockName;
  final String unitNumber;
  final PaymentStatus paymentStatus;

  String get _statusLabel => switch (paymentStatus) {
        PaymentStatus.paid => 'Terbayar',
        PaymentStatus.unpaid => 'Belum Bayar',
        PaymentStatus.overdue => 'Jatuh Tempo',
      };

  Color get _statusColor => switch (paymentStatus) {
        PaymentStatus.paid => Colors.green.shade600,
        PaymentStatus.unpaid => Colors.orange.shade600,
        PaymentStatus.overdue => Colors.red.shade600,
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade50),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.apartment, color: AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status Unit',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '$blockName - No. $unitNumber',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textDark,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Iuran Bulan Ini',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _statusLabel,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: _statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}