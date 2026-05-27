import 'package:flutter/material.dart';

/// Breakpoints standar
/// mobile  : < 600px
/// tablet  : 600px - 1024px
/// desktop : > 1024px

enum DeviceType { mobile, tablet, desktop }

class Responsive {
  Responsive._();

  static DeviceType of(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return DeviceType.mobile;
    if (width < 1024) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  static bool isMobile(BuildContext context) =>
      of(context) == DeviceType.mobile;

  static bool isTablet(BuildContext context) =>
      of(context) == DeviceType.tablet;

  static bool isDesktop(BuildContext context) =>
      of(context) == DeviceType.desktop;

  /// Pilih nilai berdasarkan device
  /// Contoh: Responsive.value(context, mobile: 1, tablet: 2, desktop: 3)
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    switch (of(context)) {
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.mobile:
        return mobile;
    }
  }
}