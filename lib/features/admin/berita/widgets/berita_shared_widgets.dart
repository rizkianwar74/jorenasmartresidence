import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Stat card — dipakai di header AdminBeritaPage (Total/Diterbitkan/Draf)
// ─────────────────────────────────────────────────────────────────────────────

class BeritaStatCard extends StatelessWidget {
  const BeritaStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 26, color: iconColor),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textGrey,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(value,
                  style: GoogleFonts.inter(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      height: 1)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Label header kolom tabel
// ─────────────────────────────────────────────────────────────────────────────

class BeritaColHeader extends StatelessWidget {
  const BeritaColHeader(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textGrey,
            letterSpacing: 0.5));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status badge (Published/Draft)
// ─────────────────────────────────────────────────────────────────────────────

class BeritaStatusBadge extends StatelessWidget {
  const BeritaStatusBadge(this.isPublished, {super.key});
  final bool isPublished;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isPublished
                ? const Color(0xFF16A34A)
                : Colors.grey.shade400,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        // Flexible (bukan cuma Text biasa) — supaya teks "PUBLISHED"/"DRAFT"
        // bisa menyusut/elipsis kalau kolom Status menyempit di lebar
        // tablet, alih-alih bikin Row ini overflow ke kanan.
        Flexible(
          child: Text(
            isPublished ? 'PUBLISHED' : 'DRAFT',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isPublished
                  ? const Color(0xFF16A34A)
                  : Colors.grey.shade500,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tombol ikon aksi (edit/hapus) di baris tabel
// ─────────────────────────────────────────────────────────────────────────────

class BeritaAksiButton extends StatelessWidget {
  const BeritaAksiButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
