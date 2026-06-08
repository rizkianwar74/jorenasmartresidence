import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';

class SatpamReportsPage extends StatelessWidget {
  const SatpamReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        body: Stack(
          children: [
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFEBEE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.inbox_outlined,
                        size: 48,
                        color: Color(0xFFD32F2F),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Halaman Laporan',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0D1B2A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Fitur ini sedang dalam pengembangan.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 32),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Kembali',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _SatpamBottomNavShared(currentIndex: 2),
            ),
          ],
        ),
      ),
    );
  }
}

class _SatpamBottomNavShared extends StatelessWidget {
  const _SatpamBottomNavShared({required this.currentIndex});
  final int currentIndex;

  static const _items = [
    (icon: Icons.home_filled,    label: 'Home',    route: AppRouter.satpamHome),
    (icon: Icons.route_outlined, label: 'Patroli', route: AppRouter.satpamPatroli),
    (icon: Icons.inbox_outlined, label: 'Laporan', route: AppRouter.satpamReports),
    (icon: Icons.person_outline, label: 'Profil',  route: AppRouter.profil),
  ];

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;
    final route = _items[index].route;
    if (route.isEmpty) return;
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (i) {
              final isActive = i == currentIndex;
              final color = isActive ? AppColors.primary : const Color(0xFFB0BEC5);
              return GestureDetector(
                onTap: () => _onTap(context, i),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_items[i].icon, color: color, size: 24),
                    const SizedBox(height: 4),
                    Text(
                      _items[i].label,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight:
                            isActive ? FontWeight.bold : FontWeight.w500,
                        color: color,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}