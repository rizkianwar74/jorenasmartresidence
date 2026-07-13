import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/satpam_insiden_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Kartu item insiden di daftar
// ─────────────────────────────────────────────────────────────────────────────
class SatpamInsidenCard extends StatelessWidget {
  const SatpamInsidenCard({super.key, required this.item, required this.onTap});
  final SatpamInsidenItem item;
  final VoidCallback      onTap;

  static const _statusColor = {
    'BARU'      : Color(0xFFD32F2F),
    'DITANGANI' : Color(0xFFE65100),
    'SELESAI'   : Color(0xFF2E7D32),
  };
  static const _statusBg = {
    'BARU'      : Color(0xFFFFEBEE),
    'DITANGANI' : Color(0xFFFFF3E0),
    'SELESAI'   : Color(0xFFE8F5E9),
  };
  static const _statusIcon = {
    'BARU'      : Icons.warning_amber_rounded,
    'DITANGANI' : Icons.directions_run_rounded,
    'SELESAI'   : Icons.check_circle_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final sc = _statusColor[item.status] ?? AppColors.primary;
    final sb = _statusBg[item.status]    ?? const Color(0xFFE3F0FF);
    final si = _statusIcon[item.status]  ?? Icons.info_outline;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  // Icon kategori
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: sb,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(si, color: sc, size: 22),
                  ),
                  const SizedBox(width: 12),
                  // Kategori + lokasi
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.kategori,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 12,
                                color: AppColors.textGrey),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                item.lokasiLabel,
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.textGrey),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: sb,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.status,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: sc,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Divider ─────────────────────────────────────────────────
            Divider(height: 1, indent: 16, color: Colors.grey.shade100),

            // ── Footer: satpam + waktu ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined,
                      size: 13, color: AppColors.textGrey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.namaSatpam,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textGrey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    DateFormat('dd MMM, HH:mm', 'id_ID')
                        .format(item.waktuKejadian),
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.textGrey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
