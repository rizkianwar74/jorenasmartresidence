import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/data/keluhan_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Kartu riwayat keluhan
// ─────────────────────────────────────────────────────────────────────────────
class KeluhanRiwayatCard extends StatelessWidget {
  const KeluhanRiwayatCard({super.key, required this.item, this.onDetailTap});

  final KeluhanItem item;
  final VoidCallback? onDetailTap;

  Color get _statusColor => switch (item.status) {
        StatusKeluhan.diproses => const Color(0xFFFF9500),
        StatusKeluhan.selesai  => const Color(0xFF34C759),
        StatusKeluhan.ditolak  => Colors.red,
        StatusKeluhan.menunggu => AppColors.textGrey,
      };

  Color get _statusBg => switch (item.status) {
        StatusKeluhan.diproses => const Color(0xFFFFF3E0),
        StatusKeluhan.selesai  => const Color(0xFFE8F5E9),
        StatusKeluhan.ditolak  => const Color(0xFFFFEBEE),
        StatusKeluhan.menunggu => const Color(0xFFF5F5F5),
      };

  String get _statusLabel => item.statusLabel.toUpperCase();

  @override
  Widget build(BuildContext context) {
    final tgl = DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
        .format(item.createdAt);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
          // Baris atas: kategori chip + badge status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.kategori,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textGrey,
                  letterSpacing: 0.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _statusLabel,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _statusColor,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Judul
          Text(
            item.judul,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),

          const SizedBox(height: 4),

          // Deskripsi singkat
          Text(
            item.deskripsi,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.textGrey),
          ),

          // Admin note (jika ada)
          if (item.adminNote != null && item.adminNote!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded,
                      size: 13, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.adminNote!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

          const SizedBox(height: 12),

          Divider(color: Colors.grey.shade100, height: 1),
          const SizedBox(height: 10),

          // Baris bawah: tanggal + lihat detail
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 13, color: AppColors.textGrey),
                  const SizedBox(width: 6),
                  Text(
                    tgl,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textGrey),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onDetailTap,
                child: Text(
                  'LIHAT DETAIL',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
