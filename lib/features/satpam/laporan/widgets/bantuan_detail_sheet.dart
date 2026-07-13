import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/data/bantuan_repository.dart';
import 'bantuan_foto_image.dart';
import 'bantuan_foto_viewer.dart';
import 'laporan_shared_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Detail laporan bantuan (bottom sheet) — jam, isi, keterangan, gambar (jika ada)
// ─────────────────────────────────────────────────────────────────────────────

class BantuanDetailSheet extends StatelessWidget {
  const BantuanDetailSheet({super.key, required this.request});
  final BantuanRequest request;

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
      case BantuanStatus.resolved:
        return 'Selesai';
      case BantuanStatus.cancelled:
        return 'Dibatalkan';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tglLengkap =
        DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(request.createdAt);
    final jam = DateFormat('HH:mm', 'id_ID').format(request.createdAt);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: 12,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 28,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Status
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                _statusLabel.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _statusColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Judul (kategori)
            Text(
              request.kategori,
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),

            // ── Jam / waktu lapor ────────────────────────────────────────
            Row(
              children: [
                Icon(Icons.schedule_rounded,
                    size: 14, color: AppColors.textGrey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '$tglLengkap • $jam',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textGrey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Keterangan (pelapor) ─────────────────────────────────────
            const BantuanDetailLabel('KETERANGAN PELAPOR'),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person_outline_rounded,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${request.namaWarga} • Blok ${request.blok} – Unit ${request.nomorUnit}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Isi laporan ──────────────────────────────────────────────
            const BantuanDetailLabel('ISI LAPORAN'),
            const SizedBox(height: 8),
            Text(
              request.catatan.isNotEmpty
                  ? request.catatan
                  : 'Tidak ada catatan tambahan dari warga.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: request.catatan.isNotEmpty
                    ? const Color(0xFF475569)
                    : AppColors.textGrey,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),

            // ── Gambar (jika ada) ────────────────────────────────────────
            BantuanDetailLabel(request.fotoUrls.isEmpty
                ? 'GAMBAR (TIDAK ADA)'
                : 'GAMBAR (${request.fotoUrls.length})'),
            const SizedBox(height: 8),
            if (request.fotoUrls.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Icon(Icons.image_not_supported_outlined,
                        size: 28, color: Colors.grey.shade400),
                    const SizedBox(height: 6),
                    Text(
                      'Tidak ada gambar dilampirkan',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textGrey),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 92,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: request.fotoUrls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BantuanFotoViewer(
                          urls: request.fotoUrls,
                          initialIndex: i,
                        ),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: BantuanFotoImage(
                        url: request.fotoUrls[i],
                        width: 92,
                        height: 92,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
