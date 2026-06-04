import 'package:flutter/material.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/register_page.dart';
import '../../features/home/home_page.dart';
import '../../features/layanan/layanan_page.dart';
import '../../features/komunitas/komunitas_page.dart';
import '../../features/profile/profil_page.dart';
import '../../features/security/security_page.dart';

class AppRouter {
  AppRouter._();

  static const String splash    = '/';
  static const String login     = '/login';
  static const String register  = '/register';
  static const String home      = '/home';
  static const String layanan   = '/layanan';
  static const String komunitas = '/komunitas';
  static const String profil    = '/profil';
  static const String security  = '/security';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _fade(const SplashScreen());
      case login:
        return _fade(const LoginPage());
      case register:
        return _slide(const RegisterPage());
      case home:
        return _fade(const HomePage());
      case layanan:
        return _fade(const LayananPage());
      case komunitas:
        return _fade(const KomunitasPage());
      case profil:
        return _fade(const ProfilPage());
      case security:
        return _slide(const SecurityPage());
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