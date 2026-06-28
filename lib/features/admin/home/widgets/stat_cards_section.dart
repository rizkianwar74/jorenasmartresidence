import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class StatCardsRow extends StatelessWidget {
  const StatCardsRow({
    super.key,
    required this.totalWarga,
    required this.patroliAktif,
    required this.openInsiden,
    required this.tamuHariIni,
  });
  final int totalWarga, patroliAktif, openInsiden, tamuHariIni;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            label      : 'TOTAL WARGA',
            value      : '$totalWarga',
            sub        : 'Penghuni terdaftar',
            subColor   : const Color(0xFF64748B),
            icon       : Icons.people_alt_outlined,
            iconColor  : AppColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            label      : 'PATROLI AKTIF',
            value      : '$patroliAktif',
            sub        : patroliAktif > 0 ? 'Sedang berjalan' : 'Tidak ada',
            subColor   : patroliAktif > 0
                ? const Color(0xFF0D9488)
                : const Color(0xFF64748B),
            valueColor : patroliAktif > 0
                ? const Color(0xFF0D9488)
                : AppColors.textDark,
            icon       : Icons.verified_user_outlined,
            iconColor  : patroliAktif > 0
                ? const Color(0xFF0D9488)
                : AppColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            label      : 'INSIDEN TERBUKA',
            value      : '$openInsiden',
            sub        : openInsiden > 0 ? 'Butuh tindakan' : 'Semua aman',
            subColor   : openInsiden > 0
                ? const Color(0xFFDC2626)
                : const Color(0xFF16A34A),
            valueColor : openInsiden > 0
                ? const Color(0xFFDC2626)
                : AppColors.textDark,
            icon       : Icons.emergency_outlined,
            iconColor  : openInsiden > 0
                ? const Color(0xFFDC2626)
                : const Color(0xFF16A34A),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            label      : 'TAMU HARI INI',
            value      : '$tamuHariIni',
            sub        : 'Kunjungan tercatat',
            subColor   : const Color(0xFF64748B),
            icon       : Icons.badge_outlined,
            iconColor  : AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.sub,
    required this.subColor,
    required this.icon,
    required this.iconColor,
    this.valueColor = AppColors.textDark,
  });
  final String   label, value, sub;
  final Color    subColor, valueColor, iconColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textGrey,
                      letterSpacing: 0.5)),
              Icon(icon, size: 20, color: iconColor),
            ],
          ),
          const SizedBox(height: 12),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                  height: 1)),
          const SizedBox(height: 6),
          Text(sub,
              style: GoogleFonts.inter(fontSize: 12, color: subColor)),
        ],
      ),
    );
  }
}
