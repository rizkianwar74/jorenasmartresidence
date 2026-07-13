import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

/// Widget "belum ada data" yang konsisten di seluruh app.
///
/// ```dart
/// EmptyStateWidget(
///   icon: Icons.article_outlined,
///   message: 'Tidak ada berita ditemukan',
///   subtitle: 'Coba ubah kata kunci pencarian',   // opsional
/// )
/// ```
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.message,
    this.subtitle,
    this.iconSize = 48,
    this.iconColor,
  });

  final IconData icon;
  final String message;
  final String? subtitle;
  final double iconSize;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: iconSize,
            color: iconColor ?? Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF94A3B8),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
