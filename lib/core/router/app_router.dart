import 'package:flutter/material.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/register_page.dart';
import '../../features/auth/auth_repository.dart';
import '../../features/home/home_page.dart';
import '../../features/layanan/layanan_page.dart';
import '../../features/komunitas/komunitas_page.dart';
import '../../features/profile/profil_page.dart';
import '../../features/pembayaran/tagihan_page.dart';
import '../../features/home/satpam_home_page.dart';
import '../../features/security/satpam_patroli_page.dart';
import '../../features/security/satpam_reports_page.dart';
import '../../features/security/satpam_catat_tamu_page.dart';


class AppRouter {
  AppRouter._();

  static const String splash    = '/';
  static const String login     = '/login';
  static const String register  = '/register';
  static const String home      = '/home';
  static const String satpamHome  = '/satpam-home';
  static const String layanan   = '/layanan';
  static const String komunitas = '/komunitas';
  static const String profil    = '/profil';
  static const String security  = '/security';
  static const String tagihan = '/tagihan';
  static const String satpamPatroli   = '/satpam/patroli';
  static const String satpamReports   = '/satpam/reports';
  static const String satpamCatatTamu = '/satpam/catat-tamu';

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
        return _fade(const HomePage());

      case satpamHome:
        return _fade(const SatpamHomePage());
      case layanan:
        return _fade(const LayananPage());
      case komunitas:
        return _fade(const KomunitasPage());
      case profil:
        return _fade(const ProfilPage());
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
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}