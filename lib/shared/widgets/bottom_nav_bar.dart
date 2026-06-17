import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.currentIndex,
    this.contentMaxWidth = 600.0,
  });

  final int currentIndex;
  final double contentMaxWidth;

  static const _items = [
    (icon: Icons.home_filled,  label: 'Beranda',   route: AppRouter.home),
    (icon: Icons.grid_view,    label: 'Layanan',   route: AppRouter.layanan),
    (icon: Icons.groups,       label: 'Komunitas', route: AppRouter.komunitas),
    (icon: Icons.person,       label: 'Profil',    route: AppRouter.profil),
  ];

  // Route yang dibuka dengan push (bisa di-back)
  static const _pushRoutes = {AppRouter.profil};

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;

    final route = _items[index].route;
    if (route.isEmpty) return;

    if (_pushRoutes.contains(route)) {
      Navigator.pushNamed(context, route);
    } else {
      Navigator.pushReplacementNamed(context, route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            border: Border(
              top: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentMaxWidth),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(
                  _items.length,
                  (i) => GestureDetector(
                    onTap: () => _onTap(context, i),
                    child: _NavItem(
                      icon: _items[i].icon,
                      label: _items[i].label,
                      isActive: currentIndex == i,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
  });

  final IconData icon;
  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : AppColors.textGrey;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: color,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}