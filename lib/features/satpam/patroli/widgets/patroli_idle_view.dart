import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import 'patroli_shared_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// State: IDLE — belum ada patroli aktif. Form untuk mulai patroli baru.
// ─────────────────────────────────────────────────────────────────────────────

class PatroliIdleView extends StatelessWidget {
  const PatroliIdleView({
    super.key,
    required this.blokMulaiController,
    required this.saving,
    required this.onMulai,
  });

  final TextEditingController blokMulaiController;
  final bool saving;
  final VoidCallback onMulai;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                    color: Colors.grey.shade400, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text('Tidak Ada Patroli Aktif', style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              )),
            ]),
          ),

          const SizedBox(height: 20),

          Text('Mulai Patroli Baru', style: GoogleFonts.inter(
            fontSize: 26, fontWeight: FontWeight.bold,
            color: const Color(0xFF0D1B2A),
          )),
          const SizedBox(height: 4),
          Text('Tentukan area patroli, lalu tekan mulai.', style: GoogleFonts.inter(
            fontSize: 13, color: const Color(0xFF94A3B8),
          )),

          const SizedBox(height: 28),

          // Ilustrasi
          Center(
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.shield_outlined, size: 56, color: AppColors.primary),
            ),
          ),

          const SizedBox(height: 28),

          // Card: input blok
          PatroliSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PatroliCardHeader(
                    icon: Icons.grid_view_outlined, label: 'AREA / BLOK PATROLI'),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: blokMulaiController,
                    style: GoogleFonts.inter(
                        fontSize: 14, color: const Color(0xFF0D1B2A)),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      hintText: 'Contoh: Blok A, B, C',
                      hintStyle: GoogleFonts.inter(
                          fontSize: 13, color: const Color(0xFFB0BEC5)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Waktu mulai akan dicatat otomatis saat tombol ditekan.',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: const Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Tombol mulai
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: saving ? null : onMulai,
              icon: saving
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 22),
              label: Text(
                saving ? 'Memulai...' : 'MULAI PATROLI',
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
