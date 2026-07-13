import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/data/keluhan_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet detail keluhan
// ─────────────────────────────────────────────────────────────────────────────
class RiwayatDetailSheet extends StatelessWidget {
  const RiwayatDetailSheet({super.key, required this.item});
  final KeluhanItem item;

  @override
  Widget build(BuildContext context) {
    final tgl = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID')
        .format(item.createdAt);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header: judul + status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.judul,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _StatusBadge(status: item.status),
              ],
            ),

            const SizedBox(height: 6),
            Text(
              item.kategori,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textGrey),
            ),

            const SizedBox(height: 16),
            Divider(color: Colors.grey.shade100),
            const SizedBox(height: 16),

            // Info warga
            _DetailRow(
              icon: Icons.person_outline_rounded,
              label: 'Pelapor',
              value:
                  '${item.namaWarga} • Blok ${item.blok} – Unit ${item.nomorUnit}',
            ),
            const SizedBox(height: 10),
            _DetailRow(
              icon: Icons.calendar_today_outlined,
              label: 'Tanggal',
              value: tgl,
            ),

            const SizedBox(height: 16),

            // Deskripsi
            Text(
              'DESKRIPSI',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textGrey,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.deskripsi,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textDark,
                height: 1.6,
              ),
            ),

            // Foto (jika ada)
            if (item.fotoUrls.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'FOTO BUKTI',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textGrey,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: item.fotoUrls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _RiwayatFotoImage(url: item.fotoUrls[i]),
                  ),
                ),
              ),
            ],

            // Catatan admin (jika ada)
            if (item.adminNote != null && item.adminNote!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'CATATAN ADMIN',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textGrey,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.15)),
                ),
                child: Text(
                  item.adminNote!,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.primary,
                    height: 1.5,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final StatusKeluhan status;

  Color get _color => switch (status) {
        StatusKeluhan.diproses => const Color(0xFFFF9500),
        StatusKeluhan.selesai  => const Color(0xFF34C759),
        StatusKeluhan.ditolak  => Colors.red,
        StatusKeluhan.menunggu => AppColors.textGrey,
      };

  Color get _bg => switch (status) {
        StatusKeluhan.diproses => const Color(0xFFFFF3E0),
        StatusKeluhan.selesai  => const Color(0xFFE8F5E9),
        StatusKeluhan.ditolak  => const Color(0xFFFFEBEE),
        StatusKeluhan.menunggu => const Color(0xFFF5F5F5),
      };

  String get _label => switch (status) {
        StatusKeluhan.diproses => 'DIPROSES',
        StatusKeluhan.selesai  => 'SELESAI',
        StatusKeluhan.ditolak  => 'DITOLAK',
        StatusKeluhan.menunggu => 'MENUNGGU',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: _color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textGrey),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textGrey),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Gambar foto bukti keluhan — aware base64 (data URI) maupun URL http.
// KeluhanRepository.sendKeluhan kini menyimpan base64, sama seperti foto
// profil/bantuan/patroli — Image.network saja tidak bisa decode itu.
class _RiwayatFotoImage extends StatelessWidget {
  const _RiwayatFotoImage({required this.url});
  final String url;

  bool get _isBase64 => url.startsWith('data:image');

  @override
  Widget build(BuildContext context) {
    if (_isBase64) {
      try {
        return Image.memory(
          base64Decode(url.split(',').last),
          width: 90,
          height: 90,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
        );
      } catch (_) {
        return _placeholder();
      }
    }
    return Image.network(
      url,
      width: 90,
      height: 90,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() => Container(
        width: 90,
        height: 90,
        color: Colors.grey.shade200,
        child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
      );
}
