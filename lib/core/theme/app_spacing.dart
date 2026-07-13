import 'package:flutter/material.dart';

/// Design tokens untuk spacing — berdasarkan frekuensi pemakaian di codebase.
///
/// Frekuensi (dari scan): 8px=192x, 16px=171x, 12px=155x,
/// 20px=128x, 10px=127x, 14px=124x, 6px=107x, 4px=107x, 24px=92x
///
/// Cara pakai:
/// ```dart
/// const SizedBox(height: AppSpacing.md)        // 16px
/// Padding(padding: EdgeInsets.all(AppSpacing.md))
/// Padding(padding: AppSpacing.pagePadding)      // horizontal 20
/// ```
class AppSpacing {
  AppSpacing._();

  // ── Nilai dasar ───────────────────────────────────────────────────────────
  static const double xxs = 4;
  static const double xs  = 6;
  static const double sm  = 8;
  static const double md  = 12;
  static const double lg  = 16;
  static const double xl  = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;

  // ── SizedBox helper ───────────────────────────────────────────────────────
  static const Widget gapXxs  = SizedBox(height: xxs);
  static const Widget gapXs   = SizedBox(height: xs);
  static const Widget gapSm   = SizedBox(height: sm);
  static const Widget gapMd   = SizedBox(height: md);
  static const Widget gapLg   = SizedBox(height: lg);
  static const Widget gapXl   = SizedBox(height: xl);
  static const Widget gapXxl  = SizedBox(height: xxl);
  static const Widget gapXxxl = SizedBox(height: xxxl);

  static const Widget hGapXs  = SizedBox(width: xs);
  static const Widget hGapSm  = SizedBox(width: sm);
  static const Widget hGapMd  = SizedBox(width: md);
  static const Widget hGapLg  = SizedBox(width: lg);
  static const Widget hGapXl  = SizedBox(width: xl);

  // ── EdgeInsets helper ─────────────────────────────────────────────────────
  /// Padding horizontal standar halaman mobile (kiri/kanan 20px)
  static const EdgeInsets pagePadding =
      EdgeInsets.symmetric(horizontal: xl);

  /// Padding horizontal + atas standar halaman
  static const EdgeInsets pageInsets =
      EdgeInsets.fromLTRB(xl, lg, xl, 0);

  /// Padding dalam card
  static const EdgeInsets cardPadding =
      EdgeInsets.all(lg);

  /// Padding kecil dalam chip / badge
  static const EdgeInsets chipPadding =
      EdgeInsets.symmetric(horizontal: md, vertical: xxs);
}
