import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../pembayaran/models/tagihan_model.dart';

class Chevron extends StatelessWidget {
  const Chevron({super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Icon(Icons.chevron_right,
            size: 13, color: Colors.grey.shade400),
      );
}

class TblHeader extends StatelessWidget {
  const TblHeader(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppColors.textGrey,
          letterSpacing: 0.4));
}

class ArrowBtn extends StatelessWidget {
  const ArrowBtn({
    super.key,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });
  final IconData icon;
  final bool     enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(6),
          boxShadow: enabled
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 6)]
              : null,
        ),
        child: Icon(icon,
            size: 18,
            color: enabled ? Colors.white : Colors.grey.shade400),
      ),
    );
  }
}

class DetailStatusBadge extends StatelessWidget {
  const DetailStatusBadge({super.key, required this.status});
  final StatusTagihan status;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, String label) = switch (status) {
      StatusTagihan.lunas      => (Colors.green.shade50, Colors.green.shade700, 'Lunas'),
      StatusTagihan.belumBayar => (Colors.red.shade50,   Colors.red.shade700,   'Belum Bayar'),
      StatusTagihan.jatuhTempo => (Colors.orange.shade50,Colors.orange.shade700,'Jatuh Tempo'),
      StatusTagihan.pending    => (Colors.amber.shade50, Colors.amber.shade800, 'Pending'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(5)),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
    );
  }
}

class HistMetodeBadge extends StatelessWidget {
  const HistMetodeBadge({super.key, required this.metode});
  final String metode;

  @override
  Widget build(BuildContext context) {
    final lower   = metode.toLowerCase();
    final isQris  = lower.contains('qris');
    final isTunai = lower.contains('tunai');

    final (Color bg, Color fg, IconData icon, String label) = isQris
        ? (const Color(0xFFEFF6FF), const Color(0xFF1D4ED8), Icons.qr_code, 'QRIS')
        : isTunai
            ? (Colors.green.shade50, Colors.green.shade700, Icons.payments_outlined, 'Tunai')
            : (Colors.grey.shade100, AppColors.textGrey, Icons.payment, metode);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(5)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: fg),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
        ],
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Text(title,
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          child,
        ],
      ),
    );
  }
}

class StatPill extends StatelessWidget {
  const StatPill({
    super.key,
    required this.label,
    required this.value,
    this.mono = false,
    this.valueColor,
  });
  final String label;
  final String value;
  final bool   mono;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withValues(alpha: 0.7),
                  letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(
            value,
            style: mono
                ? GoogleFonts.sourceCodePro(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? Colors.white)
                : GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? Colors.white),
          ),
        ],
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
    this.valueColor,
    this.mono  = false,
    this.bold  = false,
  });
  final String   label;
  final String   value;
  final IconData? icon;
  final Color?   iconColor;
  final Color?   valueColor;
  final bool     mono;
  final bool     bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(label,
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textGrey)),
        ),
        Expanded(
          flex: 3,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: iconColor ?? AppColors.textGrey),
                const SizedBox(width: 5),
              ],
              Expanded(
                child: Text(
                  value,
                  style: mono
                      ? GoogleFonts.sourceCodePro(
                          fontSize: 11,
                          color: valueColor ?? AppColors.textDark)
                      : GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: bold
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: valueColor ?? AppColors.textDark),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
