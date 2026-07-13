import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import 'patroli_shared_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// State: ACTIVE — patroli sedang berjalan. Form laporan selesai patroli.
// ─────────────────────────────────────────────────────────────────────────────

class PatroliActiveView extends StatelessWidget {
  const PatroliActiveView({
    super.key,
    required this.activeJamMulai,
    required this.activeBlok,
    required this.keteranganController,
    required this.fotos,
    required this.maxFotos,
    required this.quickTags,
    required this.selectedTags,
    required this.saving,
    required this.onPickFoto,
    required this.onRemoveFoto,
    required this.onToggleTag,
    required this.onSelesai,
  });

  final String activeJamMulai;
  final String activeBlok;
  final TextEditingController keteranganController;
  final List<Uint8List> fotos;
  final int maxFotos;
  final List<String> quickTags;
  final Set<String> selectedTags;
  final bool saving;
  final VoidCallback onPickFoto;
  final void Function(int index) onRemoveFoto;
  final void Function(String tag) onToggleTag;
  final VoidCallback onSelesai;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner patroli aktif
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              Container(
                width: 10, height: 10,
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Patroli Sedang Berjalan', style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.bold,
                    color: Colors.white,
                  )),
                  const SizedBox(height: 2),
                  Text('Mulai pukul $activeJamMulai  ·  $activeBlok',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: Colors.white70)),
                ],
              )),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('AKTIF', style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.bold,
                  color: Colors.white, letterSpacing: 0.5,
                )),
              ),
            ]),
          ),

          const SizedBox(height: 20),

          Text('Laporan Patroli', style: GoogleFonts.inter(
            fontSize: 22, fontWeight: FontWeight.bold,
            color: const Color(0xFF0D1B2A),
          )),
          const SizedBox(height: 4),
          Text('Isi keterangan dan temuan selama patroli berlangsung.',
              style: GoogleFonts.inter(
                  fontSize: 13, color: const Color(0xFF94A3B8))),

          const SizedBox(height: 20),

          // Card keterangan + foto
          PatroliSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header + tombol foto
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const PatroliCardHeader(
                        icon: Icons.menu, label: 'KETERANGAN PATROLI'),
                    GestureDetector(
                      onTap: fotos.length >= maxFotos ? null : onPickFoto,
                      child: Row(children: [
                        Icon(Icons.camera_alt_outlined, size: 16,
                            color: fotos.length >= maxFotos
                                ? Colors.grey
                                : AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          fotos.length >= maxFotos
                              ? 'Maks $maxFotos foto'
                              : 'Foto (${fotos.length}/$maxFotos)',
                          style: GoogleFonts.inter(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: fotos.length >= maxFotos
                                ? Colors.grey
                                : AppColors.primary,
                          ),
                        ),
                      ]),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Text area
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: keteranganController,
                    maxLines: 5,
                    style: GoogleFonts.inter(
                        fontSize: 14, color: const Color(0xFF0D1B2A)),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(14),
                      hintText:
                          'Tuliskan temuan atau rutinitas patroli... '
                          '(Contoh: Tidak ada aktivitas mencurigakan, '
                          'lampu lorong menyala normal)',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 13, color: const Color(0xFFB0BEC5),
                        height: 1.5,
                      ),
                    ),
                  ),
                ),

                // Preview foto
                if (fotos.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: fotos.length +
                          (fotos.length < maxFotos ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        if (i == fotos.length) {
                          return GestureDetector(
                            onTap: onPickFoto,
                            child: Container(
                              width: 90, height: 90,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F6F9),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: Colors.grey.shade300),
                              ),
                              child: Icon(Icons.add_photo_alternate_outlined,
                                  size: 28, color: AppColors.primary),
                            ),
                          );
                        }
                        return Stack(children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(fotos[i],
                                width: 90, height: 90, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 4, right: 4,
                            child: GestureDetector(
                              onTap: () => onRemoveFoto(i),
                              child: Container(
                                width: 22, height: 22,
                                decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.close,
                                    size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ]);
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // Quick tags
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: quickTags.map((tag) {
                    final selected = selectedTags.contains(tag);
                    return GestureDetector(
                      onTap: () => onToggleTag(tag),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(tag, style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : const Color(0xFF0D1B2A),
                        )),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Tombol selesai
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: saving ? null : onSelesai,
              icon: saving
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_outline,
                      color: Colors.white, size: 22),
              label: Text(
                saving ? 'Menyimpan...' : 'SELESAI PATROLI',
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Center(
            child: Text(
              'Waktu selesai akan dicatat otomatis saat tombol ditekan.',
              style: GoogleFonts.inter(
                  fontSize: 11, color: const Color(0xFF94A3B8)),
            ),
          ),
        ],
      ),
    );
  }
}
