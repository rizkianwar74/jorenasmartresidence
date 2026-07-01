import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/keluhan_repository.dart';
import '../helpers/status_keluhan_helpers.dart';
import 'keluhan_detail_sheet.dart';

class KeluhanCard extends StatelessWidget {
  const KeluhanCard({
    super.key,
    required this.item,
    required this.onUpdateStatus,
    this.isSatpamView = false,
  });
  final KeluhanItem item;
  final Future<void> Function(KeluhanItem, StatusKeluhan) onUpdateStatus;
  final bool isSatpamView;

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => KeluhanDetailSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tgl = DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
        .format(item.createdAt);

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: item.status.color.withValues(alpha: 0.15), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: item.status.color.withValues(alpha: 0.06),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(13)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: item.status.bgColor,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      item.statusLabel.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: item.status.color,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.kategori,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textGrey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    tgl,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.textGrey),
                  ),
                ],
              ),
            ),

            // ── Body ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul
                  Text(
                    item.judul,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0D1B2A),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Info warga
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded,
                          size: 13, color: AppColors.textGrey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${item.namaWarga}  •  Blok ${item.blok} – Unit ${item.nomorUnit}',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.textGrey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Deskripsi
                  Text(
                    item.deskripsi,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF475569),
                      height: 1.5,
                    ),
                  ),

                  // Admin note
                  if (item.adminNote != null &&
                      item.adminNote!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded,
                              size: 12, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.adminNote!,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.primary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ── Tombol aksi ─────────────────────────────────────
                  if (item.status == StatusKeluhan.menunggu ||
                      item.status == StatusKeluhan.diproses) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (item.status == StatusKeluhan.menunggu)
                          Expanded(
                            child: ActionBtn(
                              label: 'Proses',
                              icon: Icons.play_circle_outline_rounded,
                              color: const Color(0xFFFF9500),
                              onTap: () => onUpdateStatus(
                                  item, StatusKeluhan.diproses),
                            ),
                          ),
                        if (item.status == StatusKeluhan.menunggu)
                          const SizedBox(width: 8),
                        if (item.status == StatusKeluhan.diproses)
                          Expanded(
                            child: ActionBtn(
                              label: 'Selesai',
                              icon: Icons.check_circle_outline_rounded,
                              color: const Color(0xFF2E7D32),
                              onTap: () => onUpdateStatus(
                                  item, StatusKeluhan.selesai),
                            ),
                          ),
                        if (item.status == StatusKeluhan.diproses)
                          const SizedBox(width: 8),
                        if (!isSatpamView && item.status != StatusKeluhan.ditolak)
                          Expanded(
                            child: ActionBtn(
                              label: 'Tolak',
                              icon: Icons.cancel_outlined,
                              color: Colors.red,
                              onTap: () => onUpdateStatus(
                                  item, StatusKeluhan.ditolak),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ActionBtn extends StatelessWidget {
  const ActionBtn({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
