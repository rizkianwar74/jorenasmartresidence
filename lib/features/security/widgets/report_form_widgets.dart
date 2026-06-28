import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FormCard extends StatelessWidget {
  const FormCard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF94A3B8),
        letterSpacing: 0.8,
      ),
    );
  }
}

class ReportInputField extends StatelessWidget {
  const ReportInputField({
    super.key,
    required this.controller,
    required this.icon,
    required this.hint,
    this.keyboardType,
  });
  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(
            fontSize: 14, color: const Color(0xFF0D1B2A)),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          prefixIcon:
              Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 38, minHeight: 38),
          hintText: hint,
          hintStyle: GoogleFonts.inter(
              fontSize: 13, color: const Color(0xFFB0BEC5)),
        ),
      ),
    );
  }
}
