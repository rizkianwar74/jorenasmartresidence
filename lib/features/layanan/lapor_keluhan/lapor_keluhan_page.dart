import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_helper.dart';
import 'keluhan_form_page.dart';
import 'riwayat_keluhan_page.dart';

class KeluhanCategory {
  const KeluhanCategory({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

const _categories = [
  KeluhanCategory(
    icon: Icons.manage_accounts_outlined,
    title: 'Keluhan Manajemen',
    description: 'Masalah terkait layanan, staf, atau administrasi.',
  ),
  KeluhanCategory(
    icon: Icons.handyman_outlined,
    title: 'Keluhan Infrastruktur',
    description:
        'Masalah terkait fasilitas fisik, jalan, lampu, atau utilitas.',
  ),
];

class LaporKeluhanPage extends StatelessWidget {
  const LaporKeluhanPage({super.key});

  static const double _contentMaxWidth = 600.0;

  @override
  Widget build(BuildContext context) {
    final hPad = Responsive.value<double>(context, mobile: 24, tablet: 32);
    final statusBarH = MediaQuery.of(context).padding.top;
    final appBarH = kToolbarHeight;
    final bannerH = Responsive.value<double>(
      context,
      mobile: 180,
      tablet: 220,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      // Biarkan body meluas ke belakang AppBar
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Lapor Keluhan',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        titleSpacing: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Banner ──────────────────────────────────────────────
                // Tingginya = statusBar + AppBar + sisa area banner
                // sehingga pas menutupi area AppBar tanpa gap
                Container(
                  width: double.infinity,
                  height: statusBarH + appBarH + bannerH,
                  color: AppColors.primary,
                  child: Stack(
                    children: [
                      // Dekorasi lingkaran
                      Positioned(
                        right: -30,
                        top: -20,
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.07),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 60,
                        bottom: -50,
                        child: Container(
                          width: 170,
                          height: 170,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.07),
                          ),
                        ),
                      ),
                      Positioned(
                        right: -10,
                        top: statusBarH + 20,
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                      // Teks di pojok kiri bawah banner
                      Positioned(
                        left: hPad,
                        bottom: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Ada masalah?',
                              style: GoogleFonts.inter(
                                fontSize: Responsive.value<double>(
                                  context,
                                  mobile: 24,
                                  tablet: 28,
                                ),
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'KAMI SIAP MEMBANTU ANDA',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.8),
                                letterSpacing: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Konten bawah ────────────────────────────────────────
                Container(
                  color: const Color(0xFFF6F7F8),
                  padding: EdgeInsets.fromLTRB(hPad, 28, hPad, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pilih Kategori Keluhan',
                        style: GoogleFonts.inter(
                          fontSize: Responsive.value<double>(
                            context,
                            mobile: 20,
                            tablet: 24,
                          ),
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Silakan pilih jenis kendala yang sedang Anda alami.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textGrey,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Kartu kategori
                      ..._categories.map(
                        (cat) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _CategoryCard(
                            category: cat,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => KeluhanFormPage(category: cat),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Riwayat laporan
                      _RiwayatCard(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RiwayatKeluhanPage(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Kartu kategori ────────────────────────────────────────────────────────────
class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, this.onTap});
  final KeluhanCategory category;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(category.icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category.description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textGrey,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: AppColors.textGrey, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Riwayat laporan ───────────────────────────────────────────────────────────
class _RiwayatCard extends StatelessWidget {
  const _RiwayatCard({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history_rounded,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Riwayat Laporan',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Lihat status keluhan Anda sebelumnya',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textGrey),
                  ),
                ],
              ),
            ),
            Text(
              'LIHAT',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}