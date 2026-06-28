import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class WargaFilterBar extends StatelessWidget {
  const WargaFilterBar({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelect,
  });
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          Text(
            'Filter:',
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textGrey),
          ),
          const SizedBox(width: 12),
          Wrap(
            spacing: 8,
            children: options.map((blok) {
              final isActive = blok == selected;
              return GestureDetector(
                onTap: () => onSelect(blok),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive
                          ? AppColors.primary
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    blok,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isActive
                          ? Colors.white
                          : const Color(0xFF374151),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
