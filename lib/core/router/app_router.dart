import 'package:flutter/material.dart';
import '../../features/home/home_page.dart';
import '../../features/layanan/layanan_page.dart';
import '../../features/komunitas/komunitas_page.dart';
import '../../features/profile/profil_page.dart';

class AppRouter {
  AppRouter._();

  static const String home      = '/';
  static const String layanan   = '/layanan';
  static const String komunitas = '/komunitas';
  static const String profil    = '/profil';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return _fade(const HomePage());
      case layanan:
        return _fade(const LayananPage());
      case komunitas:
        return _fade(const KomunitasPage());
      case profil:
        return _fade(const ProfilPage());
      default:
        return _fade(const HomePage());
    }
  }

  static PageRouteBuilder _fade(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 200),
    );
  }
}