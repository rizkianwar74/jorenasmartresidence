import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/bottom_nav_bar.dart';
import 'widgets/service_card.dart';
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
      icon: Icons.qr_code_2_outlined,
      iconColor: AppColors.primary,
      bgIconColor: Color(0xFFE8F0FD),
      title: 'Izin Tamu',
      subtitle: 'AKSES KEAMANAN',
    ),
    _ServiceData(
      icon: Icons.warning_rounded,
      iconColor: Colors.red,
      bgIconColor: Color(0xFFFFEBEE),
      title: 'Darurat',
      subtitle: 'PUSAT BANTUAN 24/7',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.0,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: _services
                            .map(
                              (s) => ServiceCard(
                                icon: s.icon,
                                iconColor: s.iconColor,
                                bgIconColor: s.bgIconColor,
                                title: s.title,
                                subtitle: s.subtitle,
                                onTap: () {
                                  // TODO: navigasi ke halaman masing-masing layanan
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    ServiceHelpBanner(
                      onTap: () {
                        // TODO: hubungi building management
                      },
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