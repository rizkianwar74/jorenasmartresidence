import 'package:flutter/material.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/register_page.dart';
import '../../features/auth/auth_repository.dart';
import '../../features/home/home_page.dart';
import '../../features/home/satpam_home_page.dart';
import '../../features/layanan/layanan_page.dart';
import '../../features/komunitas/komunitas_page.dart';
import '../../features/profile/profil_page.dart';
import '../../features/security/security_page.dart';
import '../../features/security/bantuan/bantuan_satpam_page.dart';
import '../../features/security/satpam_patroli_page.dart';
import '../../features/security/satpam_reports_page.dart';
import '../../features/security/satpam_catat_tamu_page.dart';
import '../../features/pembayaran/tagihan_page.dart';
import '../../features/admin/admin_home_page.dart';
import '../../features/admin/warga_user_page.dart';
import '../../features/admin/admin_security_page.dart';
import '../../features/admin/admin_facilities_page.dart';
import '../../features/admin/admin_reports_page.dart';
import '../../features/admin/admin_berita_page.dart';

class AppRouter {
  AppRouter._();

  // ── Route names ───────────────────────────────────────────────────
  static const String splash        = '/';
  static const String login         = '/login';
  static const String register      = '/register';
  static const String home          = '/home';
  static const String satpamHome    = '/satpam-home';
  static const String layanan       = '/layanan';
  static const String komunitas     = '/komunitas';
  static const String profil        = '/profil';
  static const String security      = '/security';
  static const String bantuanSatpam = '/bantuan-satpam';
  static const String tagihan       = '/tagihan';
  static const String satpamPatroli   = '/satpam/patroli';
  static const String satpamReports   = '/satpam/reports';
  static const String satpamCatatTamu = '/satpam/catat-tamu';
  static const String adminHome       = '/admin-home';
  static const String adminWargaUser  = '/admin/warga-user';
  static const String adminSecurity    = '/admin/security';
  static const String adminFacilities  = '/admin/facilities';
  static const String adminReports     = '/admin/reports';
  static const String adminBerita      = '/admin/berita';

  // ── Route generator ───────────────────────────────────────────────
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _fade(const SplashScreen());
      case login:
        return _fade(const LoginPage());
      case register:
        return _slide(const RegisterPage());
      case home:
        final role = AuthRepository.currentUser?.role;
        if (role == UserRole.satpam) {
          return _fade(const SatpamHomePage());
        }
        if (role == UserRole.admin) {
          return _fade(const AdminHomePage());
        }
        return _fade(const HomePage());
      case adminHome:
        return _fade(const AdminHomePage());
      case adminWargaUser:
        return _fade(const WargaUserPage());
      case adminSecurity:
        return _fade(const AdminSecurityPage());
      case adminFacilities:
        return _fade(const AdminFacilitiesPage());
      case adminReports:
        return _fade(const AdminReportsPage());
      case adminBerita:
        return _fade(const AdminBeritaPage());
      case satpamHome:
        return _fade(const SatpamHomePage());
      case layanan:
        return _fade(const LayananPage());
      case komunitas:
        return _fade(const KomunitasPage());
      case profil:
        return _fade(const ProfilPage());
      case security:
        return _slide(const SecurityPage());
      case bantuanSatpam:
        return _slide(const BantuanSatpamPage());
      case tagihan:
        return _slide(const TagihanPage());
      case satpamPatroli:
        return _slide(const SatpamPatroliPage());
      case satpamReports:
        return _slide(const SatpamReportsPage());
      case satpamCatatTamu:
        return _slide(const SatpamCatatTamuPage());
      default:
        return _fade(const SplashScreen());
    }
  }

  // ── Transitions ───────────────────────────────────────────────────
  static PageRouteBuilder _fade(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 200),
    );
  }

  static PageRouteBuilder _slide(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final tween = Tween(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(
            position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
