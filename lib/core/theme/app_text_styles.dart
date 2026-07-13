import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Design tokens untuk tipografi — semua pakai GoogleFonts.inter.
///
/// Penamaan: `AppTextStyles.<ukuran><Variant>`
/// Contoh: `AppTextStyles.h1`, `AppTextStyles.body`, `AppTextStyles.caption`
///
/// Cara pakai:
/// ```dart
/// Text('Judul', style: AppTextStyles.h1)
/// Text('Konten', style: AppTextStyles.body.copyWith(color: Colors.red))
/// ```
class AppTextStyles {
  AppTextStyles._();

  // ── Heading ───────────────────────────────────────────────────────────────

  /// 32 px bold — judul halaman (Layanan, Komunitas, Profil)
  static TextStyle get h1 => GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      );

  /// 22 px bold — judul section utama
  static TextStyle get h2 => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      );

  /// 18 px semiBold — judul card / dialog
  static TextStyle get h3 => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      );

  /// 16 px semiBold — sub-header, label seksi
  static TextStyle get h4 => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      );

  // ── Body ──────────────────────────────────────────────────────────────────

  /// 15 px regular — body utama
  static TextStyle get body => GoogleFonts.inter(
        fontSize: 15,
        color: AppColors.textDark,
      );

  /// 15 px semiBold — body tebal
  static TextStyle get bodyBold => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      );

  /// 14 px regular — body sekunder (paling umum di form & list)
  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 14,
        color: AppColors.textDark,
      );

  /// 14 px bold — label form, judul item list
  static TextStyle get bodySmallBold => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      );

  // ── Caption ───────────────────────────────────────────────────────────────

  /// 13 px regular — teks deskripsi, metadata (PALING SERING dipakai: 62x)
  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 13,
        color: AppColors.textDark,
      );

  /// 13 px regular grey — keterangan sekunder / placeholder
  static TextStyle get captionGrey => GoogleFonts.inter(
        fontSize: 13,
        color: AppColors.textGrey,
      );

  /// 13 px bold — label badge, status chip
  static TextStyle get captionBold => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      );

  /// 12 px regular grey — timestamp, sub-label (34x di codebase)
  static TextStyle get small => GoogleFonts.inter(
        fontSize: 12,
        color: AppColors.textGrey,
      );

  /// 12 px semiBold — badge kecil, tag
  static TextStyle get smallBold => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      );

  /// 11 px regular grey — versi app, label sangat kecil
  static TextStyle get tiny => GoogleFonts.inter(
        fontSize: 11,
        color: AppColors.textGrey,
      );
}
