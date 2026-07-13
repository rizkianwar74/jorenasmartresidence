import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Footer pagination di bawah tabel insiden
// ─────────────────────────────────────────────────────────────────────────────

class InsidenPaginationBar extends StatelessWidget {
  const InsidenPaginationBar({
    super.key,
    required this.currentPage,
    required this.totalItems,
    required this.perPage,
    required this.onPageChanged,
  });
  final int currentPage;
  final int totalItems;
  final int perPage;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final totalPages = (totalItems / perPage).ceil().clamp(1, 9999);
    final start      = (currentPage - 1) * perPage + 1;
    final end        = (currentPage * perPage).clamp(0, totalItems);

    return Container(
      decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade100))),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Text(
            totalItems == 0
                ? 'Tidak ada insiden'
                : 'Menampilkan $start–$end dari $totalItems insiden',
            style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.textGrey),
          ),
          const Spacer(),
          _PageBtn(
            icon: Icons.chevron_left,
            enabled: currentPage > 1,
            onTap: () => onPageChanged(currentPage - 1),
          ),
          const SizedBox(width: 8),
          Text('$currentPage / $totalPages',
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textDark)),
          const SizedBox(width: 8),
          _PageBtn(
            icon: Icons.chevron_right,
            enabled: currentPage < totalPages,
            onTap: () => onPageChanged(currentPage + 1),
          ),
        ],
      ),
    );
  }
}

class _PageBtn extends StatelessWidget {
  const _PageBtn(
      {required this.icon, required this.enabled, required this.onTap});
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.grey.shade100,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon,
            size: 18,
            color: enabled ? AppColors.textDark : Colors.grey.shade400),
      ),
    );
  }
}
