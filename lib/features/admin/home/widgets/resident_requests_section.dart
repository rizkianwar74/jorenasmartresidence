import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/data/keluhan_repository.dart';

class ResidentRequests extends StatelessWidget {
  const ResidentRequests({
    super.key,
    required this.items,
    required this.onLihatSemua,
  });
  final List<KeluhanItem> items;
  final VoidCallback       onLihatSemua;

  static String relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours   < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays    == 1) return 'kemarin';
    return DateFormat('dd MMM', 'id_ID').format(dt);
  }

  IconData _icon(String kategori) {
    final k = kategori.toLowerCase();
    if (k.contains('rusak') || k.contains('pipa') || k.contains('perbaikan')) {
      return Icons.build_outlined;
    }
    if (k.contains('listrik'))  return Icons.bolt_outlined;
    if (k.contains('sampah'))   return Icons.delete_outline;
    if (k.contains('parkir'))   return Icons.local_parking_outlined;
    if (k.contains('keamanan')) return Icons.security_outlined;
    if (k.contains('fasilitas')) return Icons.apartment_outlined;
    return Icons.report_outlined;
  }

  (Color bg, Color fg, String label) _statusStyle(StatusKeluhan s) => switch (s) {
    StatusKeluhan.menunggu => (
      const Color(0xFFFFF7ED), const Color(0xFFD97706), 'Menunggu'),
    StatusKeluhan.diproses => (
      const Color(0xFFEFF6FF), AppColors.primary, 'Diproses'),
    _ => (Colors.grey.shade100, AppColors.textGrey, 'Lainnya'),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Row(children: [
              Text('Laporan Warga',
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark)),
              const SizedBox(width: 12),
              if (items.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${items.length} Laporan Aktif',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                ),
              const Spacer(),
              GestureDetector(
                onTap: onLihatSemua,
                child: Text('Lihat Semua',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary)),
              ),
            ]),
          ),

          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Row(children: [
                const Icon(Icons.check_circle_outline,
                    size: 18, color: Color(0xFF16A34A)),
                const SizedBox(width: 8),
                Text('Tidak ada laporan aktif saat ini.',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.textGrey)),
              ]),
            )
          else
            ...items.map((k) {
              final (statusBg, statusFg, statusLabel) =
                  _statusStyle(k.status);
              return Container(
                decoration: BoxDecoration(
                    border: Border(
                        top: BorderSide(color: Colors.grey.shade100))),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                child: Row(children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_icon(k.kategori),
                        size: 20, color: AppColors.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          k.judul.isNotEmpty ? k.judul : k.kategori,
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${k.namaWarga} · Blok ${k.blok} – ${k.nomorUnit} · ${relativeTime(k.createdAt)}',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.textGrey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(statusLabel,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusFg)),
                  ),
                ]),
              );
            }),

          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
