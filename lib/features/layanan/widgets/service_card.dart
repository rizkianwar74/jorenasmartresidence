import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class ServiceCard extends StatelessWidget {
  const ServiceCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.bgIconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color bgIconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: bgIconColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textGrey,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}