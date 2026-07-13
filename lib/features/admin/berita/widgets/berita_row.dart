import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../berita/models/berita_doc.dart';
import '../../data/admin_repository.dart';
import '../admin_berita_form_page.dart';
import 'berita_shared_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Satu baris pada tabel "Daftar Berita Community"
// ─────────────────────────────────────────────────────────────────────────────

class BeritaRow extends StatefulWidget {
  const BeritaRow({
    super.key,
    required this.item,
    required this.onDeleted,
    this.isCompact = false,
  });
  final BeritaDoc item;
  final VoidCallback onDeleted;

  /// true di lebar tablet sempit — sembunyikan kolom Tanggal & beri kolom
  /// Status flex lebih besar (lihat header row di AdminBeritaPage).
  final bool isCompact;

  @override
  State<BeritaRow> createState() => _BeritaRowState();
}

class _BeritaRowState extends State<BeritaRow> {
  bool _hovered = false;

  Color _kategoriColor(String k) {
    switch (k.toLowerCase()) {
      case 'keamanan':   return const Color(0xFF1D4ED8);
      case 'lingkungan': return const Color(0xFF15803D);
      case 'fasilitas':  return const Color(0xFF0369A1);
      case 'agenda':     return const Color(0xFF6B21A8);
      default:           return const Color(0xFF64748B);
    }
  }

  Color _kategoriBg(String k) {
    switch (k.toLowerCase()) {
      case 'keamanan':   return const Color(0xFFEFF6FF);
      case 'lingkungan': return const Color(0xFFF0FDF4);
      case 'fasilitas':  return const Color(0xFFE0F2FE);
      case 'agenda':     return const Color(0xFFF5F3FF);
      default:           return const Color(0xFFF1F5F9);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Hapus Berita?',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${widget.item.judul}"?',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal',
                style: GoogleFonts.inter(color: AppColors.textGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade500,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child:
                Text('Hapus', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AdminRepository.instance.deleteBerita(widget.item.id);
      widget.onDeleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: Container(
        decoration: BoxDecoration(
          color: _hovered
              ? AppColors.primary.withValues(alpha: 0.03)
              : Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade100)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            // Judul + thumbnail
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: _buildThumbnail(item),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.judul,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textDark,
                          height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Kategori badge
            Expanded(
              flex: 2,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kategoriBg(item.kategori),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.kategoriLabel.toUpperCase(),
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _kategoriColor(item.kategori),
                        letterSpacing: 0.3),
                  ),
                ),
              ),
            ),

            // Tanggal — disembunyikan di lebar tablet sempit
            if (!widget.isCompact)
              Expanded(
                flex: 2,
                child: Text(item.tanggalFormatted,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textGrey)),
              ),

            // Status — diberi flex lebih besar saat compact supaya tidak
            // overflow (lihat juga BeritaStatusBadge yang sudah dibuat fleksibel).
            Expanded(
              flex: widget.isCompact ? 3 : 2,
              child: BeritaStatusBadge(item.isPublished),
            ),

            // Aksi
            SizedBox(
              width: 70,
              child: Row(
                children: [
                  BeritaAksiButton(
                    icon: Icons.edit_outlined,
                    color: AppColors.primary,
                    onTap: () => showBeritaFormDialog(
                      context,
                      editDoc: widget.item,
                    ),
                  ),
                  const SizedBox(width: 6),
                  BeritaAksiButton(
                    icon: Icons.delete_outline,
                    color: Colors.red.shade400,
                    onTap: _delete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(BeritaDoc item) {
    if (item.imageUrl.isEmpty) return _thumbPlaceholder(item.kategori);

    // Base64 data URL — simpan langsung di Firestore
    if (item.imageUrl.startsWith('data:')) {
      try {
        final base64Str = item.imageUrl.split(',').last;
        final bytes = base64Decode(base64Str);
        return Image.memory(bytes,
            width: 46, height: 36, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _thumbPlaceholder(item.kategori));
      } catch (_) {
        return _thumbPlaceholder(item.kategori);
      }
    }

    // URL biasa (http/https)
    return Image.network(
      item.imageUrl,
      width: 46,
      height: 36,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _thumbPlaceholder(item.kategori),
    );
  }

  Widget _thumbPlaceholder(String kategori) {
    return Container(
      width: 46,
      height: 36,
      color: _kategoriColor(kategori).withValues(alpha: 0.15),
      child: Icon(Icons.article_outlined,
          size: 18, color: _kategoriColor(kategori)),
    );
  }
}
