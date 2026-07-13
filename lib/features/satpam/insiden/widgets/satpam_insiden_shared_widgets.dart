import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Empty state — daftar insiden kosong
// ─────────────────────────────────────────────────────────────────────────────
class SatpamInsidenEmptyState extends StatelessWidget {
  const SatpamInsidenEmptyState({super.key, required this.filterStatus});
  final String filterStatus;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            filterStatus == 'Semua'
                ? 'Belum ada insiden'
                : 'Tidak ada insiden $filterStatus',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Data akan muncul otomatis saat ada insiden baru',
            style: GoogleFonts.inter(
                fontSize: 12, color: const Color(0xFFB0BEC5)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Kartu info baris (dipakai di detail sheet)
// ─────────────────────────────────────────────────────────────────────────────
class SatpamInfoSection extends StatelessWidget {
  const SatpamInfoSection({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: List.generate(children.length, (i) => Column(
            children: [
              children[i],
              if (i < children.length - 1)
                Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: Colors.grey.shade200),
            ],
          )),
        ),
      ),
    );
  }
}

class SatpamInfoRow extends StatelessWidget {
  const SatpamInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String   label;
  final String   value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textGrey),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.textGrey),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
