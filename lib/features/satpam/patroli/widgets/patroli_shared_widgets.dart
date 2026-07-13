import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Widget kecil yang dipakai bersama oleh idle view & active view
// ─────────────────────────────────────────────────────────────────────────────

class PatroliSectionCard extends StatelessWidget {
  const PatroliSectionCard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }
}

class PatroliCardHeader extends StatelessWidget {
  const PatroliCardHeader({super.key, required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: AppColors.primary),
      const SizedBox(width: 8),
      Text(label, style: GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w700,
        color: const Color(0xFF94A3B8), letterSpacing: 0.5,
      )),
    ]);
  }
}
