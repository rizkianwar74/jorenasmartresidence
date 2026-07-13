import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/data/bantuan_repository.dart';
import 'bantuan_detail_sheet.dart';
import 'laporan_shared_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Kartu satu laporan bantuan warga
// ─────────────────────────────────────────────────────────────────────────────

class LaporanCard extends StatelessWidget {
  const LaporanCard({
    super.key,
    required this.request,
    this.onMyWay,
    this.onResolved,
  });

  final BantuanRequest request;
  final VoidCallback? onMyWay;
  final VoidCallback? onResolved;

  Color get _statusColor {
    switch (request.status) {
      case BantuanStatus.pending:
        return const Color(0xFFE65100);
      case BantuanStatus.onMyWay:
        return const Color(0xFF1565C0);
      default:
        return const Color(0xFF2E7D32);
    }
  }

  String get _statusLabel {
    switch (request.status) {
      case BantuanStatus.pending:
        return 'Menunggu';
      case BantuanStatus.onMyWay:
        return 'Menuju Lokasi';
      default:
        return 'Selesai';
    }
  }

  IconData get _statusIcon {
    switch (request.status) {
      case BantuanStatus.pending:
        return Icons.access_time_rounded;
      case BantuanStatus.onMyWay:
        return Icons.directions_walk_rounded;
      default:
        return Icons.check_circle_outline_rounded;
    }
  }

  IconData get _kategoriIcon {
    switch (request.kategori) {
      case 'Pendampingan':
        return Icons.directions_walk_rounded;
      case 'Kendaraan':
        return Icons.directions_car_outlined;
      case 'Orang Mencurigakan':
        return Icons.remove_red_eye_outlined;
      case 'Gangguan Lingkungan':
        return Icons.volume_up_outlined;
      default:
        return Icons.support_agent_rounded;
    }
  }

  // ── Tap kartu → buka detail (jam, isi, keterangan, gambar jika ada) ──────
  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BantuanDetailSheet(request: request),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _statusColor.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header status ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.07),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Icon(_statusIcon, size: 14, color: _statusColor),
                const SizedBox(width: 6),
                Text(
                  _statusLabel.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _statusColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Text(
                  _timeAgo(request.createdAt),
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppColors.textGrey),
                ),
              ],
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_kategoriIcon,
                          color: _statusColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.kategori,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${request.namaWarga}  •  Blok ${request.blok} – Unit ${request.nomorUnit}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (request.catatan.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F7F8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.notes_rounded,
                            size: 14, color: AppColors.textGrey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            request.catatan,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textGrey,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Tombol aksi ──────────────────────────────────────────
                if (onMyWay != null || onResolved != null) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (onMyWay != null)
                        Expanded(
                          child: LaporanActionBtn(
                            label: 'On My Way',
                            icon: Icons.directions_walk_rounded,
                            color: const Color(0xFF1565C0),
                            onTap: onMyWay!,
                          ),
                        ),
                      if (onResolved != null)
                        Expanded(
                          child: LaporanActionBtn(
                            label: 'Selesai',
                            icon: Icons.check_circle_outline_rounded,
                            color: const Color(0xFF2E7D32),
                            onTap: onResolved!,
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

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }
}
