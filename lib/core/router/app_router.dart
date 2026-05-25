import 'package:flutter/material.dart';
import '../../features/home/homepage.dart';
import '../../features/layanan/layanan_page.dart';
import '../../features/profile/profil_page.dart';

class AppRouter {
  AppRouter._();

  static const String home    = '/';
  static const String layanan = '/layanan';
  static const String profil  = '/profil';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return _fade(const HomePage());
      case layanan:
        return _fade(const LayananPage());
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