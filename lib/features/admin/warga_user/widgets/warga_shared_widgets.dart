import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class DialogLabel extends StatelessWidget {
  const DialogLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textGrey),
    );
  }
}

InputDecoration wargaInputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: AppColors.primary),
    ),
  );
}

class MiniStatCard extends StatelessWidget {
  const MiniStatCard({
    super.key,
    required this.label,
    required this.value,
    this.valueColor = AppColors.textDark,
  });
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textGrey,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class ThWidget extends StatelessWidget {
  const ThWidget(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textGrey,
        letterSpacing: 0.4,
      ),
    );
  }
}

class PageBtn extends StatelessWidget {
  const PageBtn({
    super.key,
    required this.label,
    this.isActive = false,
    this.enabled  = true,
    required this.onTap,
  });
  final String label;
  final bool isActive;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? AppColors.primary
                : enabled
                    ? Colors.grey.shade300
                    : Colors.grey.shade200,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive
                  ? Colors.white
                  : enabled
                      ? const Color(0xFF374151)
                      : Colors.grey.shade400,
            ),
          ),
        ),
      ),
    );
  }
}
