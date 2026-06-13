import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';

/// Bottom navigation bar bersama untuk semua halaman satpam.
/// Gunakan ini di setiap halaman satpam — jangan buat navbar lokal lagi.
///
/// Index:
///   0 = Home       (satpamHome)
///   1 = Patroli    (satpamPatroli)
///   2 = Laporan    (satpamReports)
///   3 = Profil     (profil)
class SatpamBottomNav extends StatelessWidget {
  const SatpamBottomNav({super.key, required this.currentIndex});

  final int currentIndex;

  static const _items = [
    (icon: Icons.home_filled,        label: 'Home',    route: AppRouter.satpamHome),
    (icon: Icons.shield_outlined,    label: 'Patroli', route: AppRouter.satpamPatroli),
    (icon: Icons.inbox_outlined,     label: 'Laporan', route: AppRouter.satpamReports),
    (icon: Icons.person_outline,     label: 'Profil',  route: AppRouter.profil),
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
              return GestureDetector(
                onTap: () => _onTap(context, i),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary.withOpacity(0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        _items[i].icon,
                        color: isActive
                            ? AppColors.primary
                            : const Color(0xFFB0BEC5),
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _items[i].label,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight:
                            isActive ? FontWeight.bold : FontWeight.w500,
                        color: isActive
                            ? AppColors.primary
                            : const Color(0xFFB0BEC5),
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
