import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Top bar halaman patroli
// ─────────────────────────────────────────────────────────────────────────────

class PatroliTopBar extends StatelessWidget {
  const PatroliTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 20, right: 20, bottom: 12,
      ),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: Color(0xFF0D1B2A)),
        ),
        const SizedBox(width: 12),
        Icon(Icons.security, color: AppColors.primary, size: 22),
        const SizedBox(width: 8),
        Text('SECURITY OPS', style: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.bold,
          color: AppColors.primary, letterSpacing: 0.5,
        )),
        const Spacer(),
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200)),
          child: const Icon(Icons.person_outline,
              size: 20, color: Color(0xFF0D1B2A)),
        ),
      ]),
    );
  }
}
