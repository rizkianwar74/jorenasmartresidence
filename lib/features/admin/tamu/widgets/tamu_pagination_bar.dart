import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Pagination daftar tamu
// ─────────────────────────────────────────────────────────────────────────────

class TamuPaginationBar extends StatelessWidget {
  const TamuPaginationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.pageSize,
    required this.onPageChanged,
  });
  final int currentPage, totalPages, totalItems, pageSize;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final start = totalItems == 0 ? 0 : (currentPage - 1) * pageSize + 1;
    final end   = (currentPage * pageSize).clamp(0, totalItems);

    return Container(
      decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade100))),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Text('Menampilkan $start–$end dari $totalItems tamu',
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textGrey)),
          const Spacer(),
          _PageBtn('<', currentPage > 1,
              () => onPageChanged(currentPage - 1)),
          const SizedBox(width: 4),
          ..._pages(),
          const SizedBox(width: 4),
          _PageBtn('>', currentPage < totalPages,
              () => onPageChanged(currentPage + 1)),
        ],
      ),
    );
  }

  List<Widget> _pages() {
    final w = <Widget>[];
    void add(int p) {
      w.add(_PageBtn('$p', true, () => onPageChanged(p),
          active: p == currentPage));
      w.add(const SizedBox(width: 4));
    }

    if (totalPages <= 5) {
      for (int i = 1; i <= totalPages; i++) add(i);
    } else {
      add(1); add(2); add(3);
      w.add(Text('...',
          style: GoogleFonts.inter(
              fontSize: 13, color: AppColors.textGrey)));
      w.add(const SizedBox(width: 4));
      add(totalPages);
    }
    return w;
  }
}

class _PageBtn extends StatelessWidget {
  const _PageBtn(this.label, this.enabled, this.onTap, {this.active = false});
  final String label;
  final bool enabled, active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active
                ? AppColors.primary
                : enabled
                    ? Colors.grey.shade300
                    : Colors.grey.shade200,
          ),
        ),
        child: Center(
          child: Text(label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: active ? FontWeight.bold : FontWeight.w500,
                color: active
                    ? Colors.white
                    : enabled
                        ? const Color(0xFF374151)
                        : Colors.grey.shade400,
              )),
        ),
      ),
    );
  }
}
