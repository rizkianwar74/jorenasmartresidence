import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class UnitInfoCard extends StatelessWidget {
  const UnitInfoCard({
    super.key,
    required this.blockName,
    required this.unitNumber,
  });

  final String blockName;
  final String unitNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(child: _UnitInfoCell(label: 'BLOK', value: blockName)),
            VerticalDivider(
              color: Colors.grey.shade200,
              thickness: 1,
              width: 1,
            ),
            Expanded(child: _UnitInfoCell(label: 'NOMOR', value: unitNumber)),
          ],
        ),
      ),
    );
  }
}

class _UnitInfoCell extends StatelessWidget {
  const _UnitInfoCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }
}