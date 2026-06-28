import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class DRow extends StatelessWidget {
  const DRow(this.label, this.value, {super.key});
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 110, child: Text(label,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey))),
        Expanded(child: Text(value, style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark))),
      ]),
    );
  }
}

class AdminFotoImage extends StatelessWidget {
  const AdminFotoImage({
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
      loadingBuilder: (_, child, prog) => prog == null ? child : _loading(),
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
        child: Icon(Icons.broken_image_outlined,
            size: dark ? 48 : 28,
            color: dark ? Colors.white54 : Colors.grey.shade400),
      );
}

class StatCardsRow extends StatelessWidget {
  const StatCardsRow({
    super.key,
    required this.satpamAktif,
    required this.sosHariIni,
    required this.bantuanHariIni,
    required this.patroliAktif,
  });
  final int satpamAktif, sosHariIni, bantuanHariIni, patroliAktif;

  @override
  Widget build(BuildContext context) {
    final adaPatroli = patroliAktif > 0;
    return Row(
      children: [
        Expanded(child: StatCard(
          label: 'SATPAM TERDAFTAR', value: satpamAktif.toString().padLeft(2, '0'),
          sub: 'Aktif', subIcon: Icons.check_circle_outline, subColor: const Color(0xFF16A34A),
        )),
        const SizedBox(width: 14),
        Expanded(child: StatCard(
          label: 'SOS HARI INI', value: sosHariIni.toString().padLeft(2, '0'),
          sub: 'Panggilan', subIcon: Icons.emergency_outlined,
          subColor: sosHariIni > 0 ? const Color(0xFFDC2626) : AppColors.textGrey,
          valueColor: sosHariIni > 0 ? const Color(0xFFDC2626) : AppColors.textDark,
        )),
        const SizedBox(width: 14),
        Expanded(child: StatCard(
          label: 'BANTUAN HARI INI', value: bantuanHariIni.toString().padLeft(2, '0'),
          sub: 'Permintaan', subIcon: Icons.support_agent_outlined, subColor: AppColors.primary,
        )),
        const SizedBox(width: 14),
        Expanded(child: StatCard(
          label: 'PATROLI AKTIF', value: patroliAktif.toString().padLeft(2, '0'),
          sub: adaPatroli ? 'Sedang Berjalan' : 'Tidak Ada',
          subIcon: adaPatroli ? Icons.shield : Icons.shield_outlined,
          subColor: adaPatroli ? const Color(0xFF0D9488) : AppColors.textGrey,
          valueColor: adaPatroli ? const Color(0xFF0D9488) : AppColors.textDark,
        )),
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
    this.subIcon,
    required this.subColor,
    this.valueColor = AppColors.textDark,
  });
  final String label, value, sub;
  final IconData? subIcon;
  final Color subColor, valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.inter(fontSize: 11,
                fontWeight: FontWeight.w600, color: AppColors.textGrey, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.inter(fontSize: 36,
                fontWeight: FontWeight.bold, color: valueColor, height: 1)),
          ]),
          Row(children: [
            if (subIcon != null) ...[Icon(subIcon, size: 15, color: subColor), const SizedBox(width: 4)],
            Text(sub, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: subColor)),
          ]),
        ],
      ),
    );
  }
}
