import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Warna status insiden — dipakai bersama oleh tabel, baris, filter, dan
// dialog detail supaya konsisten.
// ─────────────────────────────────────────────────────────────────────────────

Color insidenStatusColor(String status) {
  switch (status) {
    case 'BARU':       return const Color(0xFFDC2626);
    case 'DITANGANI':  return const Color(0xFFD97706);
    case 'SELESAI':    return const Color(0xFF16A34A);
    default:           return AppColors.textGrey;
  }
}

Color insidenStatusBg(String status) {
  switch (status) {
    case 'BARU':       return const Color(0xFFFEF2F2);
    case 'DITANGANI':  return const Color(0xFFFFFBEB);
    case 'SELESAI':    return const Color(0xFFF0FDF4);
    default:           return Colors.grey.shade100;
  }
}
