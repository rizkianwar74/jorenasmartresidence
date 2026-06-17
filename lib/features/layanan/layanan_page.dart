import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_helper.dart';
import '../../shared/widgets/bottom_nav_bar.dart';
import 'widgets/service_card.dart';
import 'lapor_keluhan/lapor_keluhan_page.dart';
import 'kantin/kantin_page.dart';
import 'fasilitas/fasilitas_page.dart';
import 'pusat_bantuan/pusat_bantuan_page.dart';
import 'widgets/service_help_banner.dart';

class LayananPage extends StatelessWidget {
  const LayananPage({super.key});

  static const double _contentMaxWidth = 600.0;

  static const _services = [
    _ServiceData(
      icon: Icons.handyman_outlined,
      iconColor: AppColors.primary,
      bgIconColor: Color(0xFFE8F0FD),
      title: 'Lapor Keluhan',
      subtitle: 'MAINTENANCE & PERBAIKAN',
    ),
    _ServiceData(
      icon: Icons.calendar_month_outlined,
      iconColor: AppColors.primary,
      bgIconColor: Color(0xFFE8F0FD),
      title: 'Booking Fasilitas',
      subtitle: 'AREA & RUANG PUBLIK',
    ),
    _ServiceData(
      icon: Icons.diamond_outlined,
      iconColor: Colors.red,
      bgIconColor: Color(0xFFFFEBEE),
      title: 'Darurat',
      subtitle: 'PUSAT BANTUAN 24/7',
    ),
    _ServiceData(
      icon: Icons.restaurant_outlined,
      iconColor: AppColors.primary,
      bgIconColor: Color(0xFFE8F0FD),
      title: 'Kantin',
      subtitle: 'PESAN MAKANAN & MINUMAN',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Jumlah kolom grid: 2 di mobile, 4 di tablet/desktop
    final crossAxisCount = Responsive.value<int>(
      context,
      mobile: 2,
      tablet: 4,
      desktop: 4,
    );

    // Rasio kartu: lebih tinggi di mobile agar subtitle tidak overflow
    final aspectRatio = Responsive.value<double>(
      context,
      mobile: 0.85,
      tablet: 0.90,
      desktop: 0.90,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: MediaQuery.of(context).padding.top + 16),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Layanan',
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: GridView.count(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: aspectRatio,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: _services
                            .map(
                              (s) {
                                VoidCallback? handler;
                                if (s.title == 'Lapor Keluhan') {
                                  handler = () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LaporKeluhanPage(),
                                    ),
                                  );
                                } else if (s.title == 'Booking Fasilitas') {
                                  handler = () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const FasilitasPage(),
                                    ),
                                  );
                                } else if (s.title == 'Darurat') {
                                  handler = () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const PusatBantuanPage(),
                                    ),
                                  );
                                } else if (s.title == 'Kantin') {
                                  handler = () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const KantinPage(),
                                    ),
                                  );
                                }
                                return ServiceCard(
                                  icon: s.icon,
                                  iconColor: s.iconColor,
                                  bgIconColor: s.bgIconColor,
                                  title: s.title,
                                  subtitle: s.subtitle,
                                  onTap: handler,
                                );
                              },
                            )
                            .toList(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    ServiceHelpBanner(
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomNavBar(
              currentIndex: 1,
              contentMaxWidth: _contentMaxWidth,
            ),
          ),

          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 130,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceData {
  const _ServiceData({
    required this.icon,
    required this.iconColor,
    required this.bgIconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final Color bgIconColor;
  final String title;
  final String subtitle;
}