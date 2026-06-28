import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../pembayaran/models/tagihan_model.dart';

// ── Status badge ─────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});
  final StatusTagihan status;

  String get _label => switch (status) {
        StatusTagihan.belumBayar => 'Belum Bayar',
        StatusTagihan.jatuhTempo => 'Jatuh Tempo',
        StatusTagihan.lunas => 'Lunas',
        StatusTagihan.pending => 'Pending',
      };

  (Color, Color) get _colors => switch (status) {
        StatusTagihan.lunas =>
          (Colors.green.shade50, Colors.green.shade700),
        StatusTagihan.belumBayar =>
          (Colors.red.shade50, Colors.red.shade700),
        StatusTagihan.jatuhTempo =>
          (Colors.orange.shade50, Colors.orange.shade700),
        StatusTagihan.pending =>
          (Colors.amber.shade50, Colors.amber.shade800),
      };

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _label,
        style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}

// ── Tombol stepper di dalam dialog (lingkaran abu) ───────────────────────────
class DlgStepBtn extends StatelessWidget {
  const DlgStepBtn({
    super.key,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });
  final IconData  icon;
  final bool      enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary : Colors.grey.shade200,
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            size: 18,
            color: enabled ? Colors.white : Colors.grey.shade400),
      ),
    );
  }
}

// ── Metode bayar badge ────────────────────────────────────────────────────────
class MetodeBadge extends StatelessWidget {
  const MetodeBadge({super.key, required this.metode});
  final String? metode;

  @override
  Widget build(BuildContext context) {
    if (metode == null || metode!.isEmpty) {
      return Text('-',
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey));
    }

    final lower    = metode!.toLowerCase();
    final isQris   = lower.contains('qris');
    final isTunai  = lower.contains('tunai');

    final (Color bg, Color fg, IconData icon, String label) = isQris
        ? (const Color(0xFFEFF6FF), const Color(0xFF1D4ED8), Icons.qr_code, 'QRIS')
        : isTunai
            ? (Colors.green.shade50, Colors.green.shade700, Icons.payments_outlined, 'Tunai')
            : (Colors.grey.shade100, AppColors.textGrey, Icons.help_outline, metode!);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.bold, color: fg),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Komponen kecil ───────────────────────────────────────────────────────────
class HeaderText extends StatelessWidget {
  const HeaderText(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textGrey,
            letterSpacing: 0.5),
      );
}

class CenterMessage extends StatelessWidget {
  const CenterMessage({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.textGrey),
          const SizedBox(height: 12),
          Text(text,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textGrey)),
        ],
      ),
    );
  }
}

// ── Tile opsi edit status (dipakai di bottom sheet) ──────────────────────────
class EditStatusTile extends StatelessWidget {
  const EditStatusTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: iconColor.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: iconColor)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textGrey)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: iconColor),
          ],
        ),
      ),
    );
  }
}
