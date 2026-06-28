import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/keluhan_service.dart'; // contains StatusKeluhan enum

extension StatusKeluhanExtension on StatusKeluhan {
  String get label => switch (this) {
        StatusKeluhan.diproses => 'Diproses',
        StatusKeluhan.selesai  => 'Selesai',
        StatusKeluhan.ditolak  => 'Ditolak',
        StatusKeluhan.menunggu => 'Menunggu',
      };

  Color get color => switch (this) {
        StatusKeluhan.diproses => const Color(0xFFFF9500),
        StatusKeluhan.selesai  => const Color(0xFF2E7D32),
        StatusKeluhan.ditolak  => Colors.red,
        StatusKeluhan.menunggu => AppColors.textGrey,
      };

  Color get bgColor => switch (this) {
        StatusKeluhan.diproses => const Color(0xFFFFF3E0),
        StatusKeluhan.selesai  => const Color(0xFFE8F5E9),
        StatusKeluhan.ditolak  => const Color(0xFFFFEBEE),
        StatusKeluhan.menunggu => const Color(0xFFF5F5F5),
      };
}

String formatWaktuKejadian(DateTime dt) {
  final d  = '${dt.month.toString().padLeft(2,'0')}/${dt.day.toString().padLeft(2,'0')}/${dt.year}';
  final h  = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
  final m  = dt.minute.toString().padLeft(2, '0');
  final pm = dt.hour >= 12 ? 'PM' : 'AM';
  return '$d  ${h.toString().padLeft(2,'0')}:$m $pm';
}
