import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Enum semua halaman admin — gunakan untuk menentukan item aktif di sidebar
// ─────────────────────────────────────────────────────────────────────────────

enum AdminPage {
  dashboard,
  wargaUser,
  security,
  insiden,
  daftarTamu,
  facilities,
  billing,
  reports,
  berita,
  settings,
  support,
}

// ─────────────────────────────────────────────────────────────────────────────
// Model item navigasi
// ─────────────────────────────────────────────────────────────────────────────

class _NavItemData {
  const _NavItemData({
    required this.page,
    required this.icon,
    required this.label,
    this.route,
  });
  final AdminPage page;
  final IconData icon;
  final String label;
  final String? route;
}

const _mainNavItems = [
  _NavItemData(
    page: AdminPage.dashboard,
    icon: Icons.dashboard_outlined,
    label: 'Dashboard',
    route: AppRouter.adminHome,
  ),
  _NavItemData(
    page: AdminPage.wargaUser,
    icon: Icons.people_outline,
    label: 'Warga/User',
    route: AppRouter.adminWargaUser,
  ),
  _NavItemData(
    page: AdminPage.security,
    icon: Icons.shield_outlined,
    label: 'Security',
    route: AppRouter.adminSecurity,
  ),
  _NavItemData(
    page: AdminPage.insiden,
    icon: Icons.warning_amber_outlined,
    label: 'Insiden',
    route: AppRouter.adminInsiden,
  ),
  _NavItemData(
    page: AdminPage.daftarTamu,
    icon: Icons.badge_outlined,
    label: 'Daftar Tamu',
    route: AppRouter.adminDaftarTamu,
  ),
  _NavItemData(
    page: AdminPage.facilities,
    icon: Icons.business_outlined,
    label: 'Facilities',
    route: AppRouter.adminFacilities,
  ),
  _NavItemData(
    page: AdminPage.billing,
    icon: Icons.account_balance_wallet_outlined,
    label: 'Billing',
  ),
  _NavItemData(
    page: AdminPage.reports,
    icon: Icons.bar_chart_outlined,
    label: 'Reports',
    route: AppRouter.adminReports,
  ),
  _NavItemData(
    page: AdminPage.berita,
    icon: Icons.newspaper_outlined,
    label: 'Berita',
    route: AppRouter.adminBerita,
  ),
];

const _bottomNavItems = [
  _NavItemData(
    page: AdminPage.settings,
    icon: Icons.settings_outlined,
    label: 'Settings',
  ),
  _NavItemData(
    page: AdminPage.support,
    icon: Icons.help_outline,
    label: 'Support',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// AdminSidebar — reusable di semua halaman admin
//
// Cara pakai:
//   AdminSidebar(activePage: AdminPage.dashboard)
//   AdminSidebar(activePage: AdminPage.billing)
// ─────────────────────────────────────────────────────────────────────────────

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({super.key, required this.activePage});

  final AdminPage activePage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Logo ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Residence',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Admin Operations',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),

          // ── Main nav items ─────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: _mainNavItems
                  .map((item) => _NavTile(
                        data: item,
                        isActive: item.page == activePage,
                        onTap: () => _navigate(context, item),
                      ))
                  .toList(),
            ),
          ),

          // ── Divider ────────────────────────────────────────────────────
          Divider(height: 1, color: Colors.grey.shade200),

          // ── Bottom nav (Settings, Support) ─────────────────────────────
          ..._bottomNavItems.map(
            (item) => _NavTile(
              data: item,
              isActive: item.page == activePage,
              onTap: () => _navigate(context, item),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, _NavItemData item) {
    // Jangan navigate jika sudah di halaman yang sama
    if (item.page == activePage) return;

    if (item.route != null) {
      Navigator.pushReplacementNamed(context, item.route!);
    }
    // TODO: tambahkan route masing-masing halaman saat halaman dibuat
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NavTile — satu item di sidebar
// ─────────────────────────────────────────────────────────────────────────────

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.data,
    required this.isActive,
    required this.onTap,
  });

  final _NavItemData data;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              data.icon,
              size: 18,
              color: isActive ? AppColors.primary : AppColors.textGrey,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                data.label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive
                      ? AppColors.primary
                      : const Color(0xFF374151),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
