import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/keluhan_repository.dart';
import '../helpers/status_keluhan_helpers.dart';
import 'keluhan_foto_viewer.dart';

class KeluhanDetailSheet extends StatelessWidget {
  const KeluhanDetailSheet({super.key, required this.item});
  final KeluhanItem item;

  void _openFoto(BuildContext context, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            FullscreenFotoViewer(urls: item.fotoUrls, initialIndex: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tglLengkap =
        DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(item.createdAt);
    final jam = DateFormat('HH:mm', 'id_ID').format(item.createdAt);

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

            // Status + kategori
            Row(
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
                Expanded(
                  child: Text(
                    item.kategori,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textGrey,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Judul
            Text(
              item.judul,
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0D1B2A),
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
            const DetailLabel('KETERANGAN PELAPOR'),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person_outline_rounded,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${item.namaWarga} • Blok ${item.blok} – Unit ${item.nomorUnit}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF0D1B2A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Isi laporan ──────────────────────────────────────────────
            const DetailLabel('ISI LAPORAN'),
            const SizedBox(height: 8),
            Text(
              item.deskripsi.isNotEmpty ? item.deskripsi : '-',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF475569),
                height: 1.6,
              ),
            ),

            // Catatan admin/satpam (kalau ada)
            if (item.adminNote != null && item.adminNote!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const DetailLabel('CATATAN'),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded,
                        size: 14, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.adminNote!,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.primary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ── Foto bukti (jika ada) ────────────────────────────────────
            DetailLabel(item.fotoUrls.isEmpty
                ? 'FOTO BUKTI (TIDAK ADA)'
                : 'FOTO BUKTI (${item.fotoUrls.length})'),
            const SizedBox(height: 8),
            if (item.fotoUrls.isEmpty)
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
                      'Warga tidak melampirkan foto',
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
                  itemCount: item.fotoUrls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => _openFoto(context, i),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: KeluhanFotoImage(
                        url: item.fotoUrls[i],
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

class DetailLabel extends StatelessWidget {
  const DetailLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: AppColors.textGrey,
        letterSpacing: 0.6,
      ),
    );
  }
}
