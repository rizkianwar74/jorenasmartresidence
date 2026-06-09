import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_top_bar.dart';

class AdminFacilitiesPage extends StatelessWidget {
  const AdminFacilitiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F7),
      body: Row(
        children: [
          // ── Sidebar ──────────────────────────────────────────────────
          const AdminSidebar(activePage: AdminPage.facilities),

          // ── Main content ─────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // Top bar
                const AdminTopBar(
                  searchHint: 'Search facilities or documents...',
                ),

                // Body — centered under construction
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Illustration card ───────────────────────────
                        Container(
                          width: 380,
                          padding: const EdgeInsets.symmetric(
                              vertical: 48, horizontal: 40),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Building + gear illustration
                              SizedBox(
                                width: 140,
                                height: 140,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(
                                      Icons.apartment_rounded,
                                      size: 110,
                                      color: const Color(0xFF1E3A8A)
                                          .withOpacity(0.85),
                                    ),
                                    Positioned(
                                      bottom: 8,
                                      right: 6,
                                      child: Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xFF1E3A8A)
                                                .withOpacity(0.2),
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.settings_outlined,
                                          size: 22,
                                          color: Color(0xFF1E3A8A),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // UNDER CONSTRUCTION
                              Text(
                                'UNDER CONSTRUCTION',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E3A8A),
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'New features coming soon!',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.textGrey,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ── Description ─────────────────────────────────
                        Text(
                          'Fasilitas Sedang Dibangun',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),

                        const SizedBox(height: 16),

                        SizedBox(
                          width: 440,
                          child: Text(
                            'Modul manajemen fasilitas hunian sedang dalam tahap '
                            'pengembangan akhir. Tim kami sedang menyiapkan sistem '
                            'reservasi dan monitoring terbaik untuk operasional hunian Anda.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textGrey,
                              height: 1.6,
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ── Kembali ke Dashboard button ──────────────────
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pushReplacementNamed(
                              context, AppRouter.adminHome),
                          icon: const Icon(Icons.arrow_back,
                              size: 18, color: Colors.white),
                          label: Text(
                            'Kembali Ke Dashboard',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
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
