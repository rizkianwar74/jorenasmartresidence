import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/data/keluhan_repository.dart';

class ReportFotoImage extends StatelessWidget {
  const ReportFotoImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.dark = false,
  });
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool dark;

  bool get _isBase64 => url.startsWith('data:image');

  @override
  Widget build(BuildContext context) {
    if (_isBase64) {
      try {
        final bytes = base64Decode(url.split(',').last);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => _placeholder(),
        );
      } catch (_) {
        return _placeholder();
      }
    }
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return _loading();
      },
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  Widget _loading() => Container(
        width: width,
        height: height,
        color: dark ? Colors.grey.shade800 : Colors.grey.shade100,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: dark ? Colors.white : null,
            ),
          ),
        ),
      );

  Widget _placeholder() => Container(
        width: width,
        height: height,
        color: dark ? Colors.grey.shade800 : Colors.grey.shade100,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image_outlined,
                size: dark ? 48 : 28,
                color: dark ? Colors.white54 : Colors.grey.shade400),
            if (!dark) ...[
              const SizedBox(height: 4),
              Text('Gagal memuat',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textGrey)),
            ],
          ],
        ),
      );
}

class KategoriBadge extends StatelessWidget {
  const KategoriBadge(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    final isInfra = label.contains('Infrastruktur');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isInfra ? const Color(0xFFEFF6FF) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isInfra ? 'Infrastruktur' : 'Manajemen',
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500,
            color: isInfra ? AppColors.primary : const Color(0xFF15803D)),
      ),
    );
  }
}

class StatusBadgeRow extends StatelessWidget {
  const StatusBadgeRow(this.status, {super.key});
  final StatusKeluhan status;

  (Color dot, Color bg, Color fg, String label) get _style => switch (status) {
    StatusKeluhan.menunggu => (const Color(0xFFF97316), const Color(0xFFFFF7ED), const Color(0xFFF97316), 'Menunggu'),
    StatusKeluhan.diproses => (AppColors.primary,       const Color(0xFFEFF6FF), AppColors.primary,       'Diproses'),
    StatusKeluhan.selesai  => (const Color(0xFF16A34A), const Color(0xFFF0FDF4), const Color(0xFF16A34A), 'Selesai'),
    StatusKeluhan.ditolak  => (Colors.red,              const Color(0xFFFFEBEE), Colors.red,              'Ditolak'),
  };

  @override
  Widget build(BuildContext context) {
    final (dot, bg, fg, label) = _style;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 7, height: 7,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
      ]),
    );
  }
}

class ColH extends StatelessWidget {
  const ColH(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Text(text, style: GoogleFonts.inter(
    fontSize: 10, fontWeight: FontWeight.w700,
    color: AppColors.textGrey, letterSpacing: 0.4,
  ));
}

class StatCardsRow extends StatelessWidget {
  const StatCardsRow({
    super.key,
    required this.total,
    required this.menunggu,
    required this.diproses,
    required this.selesai,
  });
  final int total, menunggu, diproses, selesai;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: StatCard(label: 'Total Laporan', value: '$total',
            sub: 'Semua keluhan masuk', subColor: AppColors.primary,
            icon: Icons.bar_chart_rounded, iconColor: AppColors.primary,
            accentColor: AppColors.primary)),
        const SizedBox(width: 14),
        Expanded(child: StatCard(label: 'Menunggu', value: '$menunggu',
            sub: 'Butuh respon segera',
            subColor: const Color(0xFFF97316),
            icon: Icons.pending_actions_outlined,
            iconColor: const Color(0xFFF97316),
            accentColor: const Color(0xFFF97316))),
        const SizedBox(width: 14),
        Expanded(child: StatCard(label: 'Diproses', value: '$diproses',
            sub: 'Sedang ditangani satpam',
            subColor: AppColors.primary,
            icon: Icons.supervised_user_circle_outlined,
            iconColor: AppColors.primary, accentColor: AppColors.primary)),
        const SizedBox(width: 14),
        Expanded(child: StatCard(label: 'Selesai', value: '$selesai',
            sub: 'Sudah diselesaikan',
            subColor: const Color(0xFF16A34A),
            icon: Icons.check_circle_outline,
            iconColor: const Color(0xFF16A34A),
            accentColor: const Color(0xFF16A34A))),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.sub,
    required this.subColor,
    required this.icon,
    required this.iconColor,
    required this.accentColor,
  });
  final String label, value, sub;
  final Color subColor, iconColor, accentColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 4, decoration: BoxDecoration(
            color: accentColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          )),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
            Icon(icon, size: 20, color: iconColor),
          ]),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.bold, color: AppColors.textDark, height: 1)),
          const SizedBox(height: 6),
          Text(sub, style: GoogleFonts.inter(fontSize: 12, color: subColor, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
