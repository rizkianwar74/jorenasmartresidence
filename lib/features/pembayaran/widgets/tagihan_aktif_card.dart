import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../models/tagihan_model.dart';
import 'bulan_stepper.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Kartu tagihan aktif — gradient card berisi ringkasan tagihan wajib +
// advance, stepper bulan dimuka, dan tombol Bayar.
// ─────────────────────────────────────────────────────────────────────────────

class TagihanAktifCard extends StatelessWidget {
  const TagihanAktifCard({
    super.key,
    required this.wajibList,
    required this.advanceList,
    required this.selectedAdvanceCount,
    required this.minAdvanceCount,
    required this.maxAdvanceCount,
    required this.onAdvanceCountChanged,
    this.onBayar,
    this.isLoading = false,
  });

  /// Tagihan wajib (tunggakan + bulan berjalan). Selalu ikut pembayaran.
  final List<TagihanModel> wajibList;

  /// Tagihan advance yang dipilih saat ini (sudah di-trim sesuai count).
  final List<TagihanModel> advanceList;

  /// Berapa bulan advance yang dipilih (0 = tidak tambah dimuka).
  final int selectedAdvanceCount;

  /// Minimum advance yang harus dipilih (1 jika wajib kosong).
  final int minAdvanceCount;

  /// Batas atas stepper advance.
  final int maxAdvanceCount;

  final ValueChanged<int> onAdvanceCountChanged;
  final VoidCallback? onBayar;
  final bool isLoading;

  // Gabungan yang benar-benar akan dibayar.
  List<TagihanModel> get _selected =>
      [...wajibList, ...advanceList.take(selectedAdvanceCount)];

  TagihanModel get _acuan =>
      wajibList.isNotEmpty ? wajibList.first : advanceList.first;

  int get _selectedJumlah => _selected.fold(0, (s, t) => s + t.jumlah);

  bool get _adaTunggakan => wajibList.length > 1;

  String get _periodeLabel {
    final total = _selected.length;
    if (total == 0) return '-';
    if (total == 1) return _selected.first.periodeLabel;
    if (wajibList.length > 1 && selectedAdvanceCount == 0) {
      return '${wajibList.length} Bulan Tertunggak';
    }
    if (selectedAdvanceCount > 0 && wajibList.isEmpty) {
      return '$selectedAdvanceCount Bulan Dimuka';
    }
    return '$total Bulan (${wajibList.length} wajib + $selectedAdvanceCount dimuka)';
  }

  String get _statusLabel {
    final all = [...wajibList, ...advanceList];
    if (all.every((t) => t.status == StatusTagihan.lunas)) return 'Lunas';
    if (all.any((t) => t.status == StatusTagihan.jatuhTempo)) return 'Jatuh Tempo';
    if (all.any((t) => t.status == StatusTagihan.pending)) return 'Menunggu Konfirmasi';
    if (wajibList.isEmpty && advanceList.isNotEmpty) return 'Dimuka';
    return 'Belum Dibayar';
  }

  @override
  Widget build(BuildContext context) {
    final tagihan = _acuan;
    final isLunas = [...wajibList, ...advanceList]
        .every((t) => t.status == StatusTagihan.lunas);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, const Color(0xFF0D5BAA)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20, top: -20,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            right: 40, bottom: -30,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'IURAN BULANAN',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.7),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _periodeLabel,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statusLabel,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    const Icon(Icons.person_outline,
                        color: Colors.white54, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      tagihan.namaResiden,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.85)),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.apartment,
                        color: Colors.white54, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      tagihan.unitLabel,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.85)),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Text(
                  formatRupiah(_selectedJumlah),
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: Colors.white54, size: 13),
                    const SizedBox(width: 6),
                    Text(
                      'Jatuh tempo: ${tagihan.jatuhTempo}',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.7)),
                    ),
                  ],
                ),

                // ── Info bulan wajib (jika ada tunggakan) ──────────────────
                if (_adaTunggakan) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            size: 15, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${wajibList.length} bulan tertunggak wajib dilunasi sekaligus.',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Stepper bulan dimuka ───────────────────────────────────
                const SizedBox(height: 14),
                BulanStepper(
                  label: 'Tambah bulan dimuka:',
                  count: selectedAdvanceCount,
                  min: minAdvanceCount,
                  max: maxAdvanceCount,
                  onChanged: onAdvanceCountChanged,
                ),

                const SizedBox(height: 20),

                if (isLunas)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Tagihan Anda Lunas',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: onBayar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.primary,
                              ),
                            )
                          : Text(
                              'Bayar Sekarang',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
