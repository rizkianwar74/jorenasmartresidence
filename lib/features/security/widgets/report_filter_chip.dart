import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class ReportFilterChip extends StatelessWidget {
  const ReportFilterChip({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
    this.color,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? c.withValues(alpha: 0.1) : const Color(0xFFF4F6F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? c : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight:
                active ? FontWeight.bold : FontWeight.w500,
            color: active ? c : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

class EmptyKeluhan extends StatelessWidget {
  const EmptyKeluhan({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined,
              size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          Text(
            'Tidak ada keluhan',
            style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textGrey),
          ),
          const SizedBox(height: 4),
          Text(
            'Belum ada keluhan yang ditugaskan ke Anda',
            style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }
}
