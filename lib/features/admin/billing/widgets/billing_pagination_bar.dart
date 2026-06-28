import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

// ── Pagination bar ───────────────────────────────────────────────────────────
class BillingPaginationBar extends StatelessWidget {
  const BillingPaginationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.pageSize,
    required this.onPageChanged,
  });
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final start = totalItems == 0 ? 0 : ((currentPage - 1) * pageSize) + 1;
    final end = (currentPage * pageSize).clamp(0, totalItems);

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Text(
            'Showing $start to $end of $totalItems tagihan',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey),
          ),
          const Spacer(),
          _PageBtn(
            label: '<',
            enabled: currentPage > 1,
            onTap: () => onPageChanged(currentPage - 1),
          ),
          const SizedBox(width: 4),
          ..._buildPageNumbers(),
          const SizedBox(width: 4),
          _PageBtn(
            label: '>',
            enabled: currentPage < totalPages,
            onTap: () => onPageChanged(currentPage + 1),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers() {
    final pages = <Widget>[];
    void addPage(int page) {
      pages.add(_PageBtn(
        label: '$page',
        isActive: page == currentPage,
        onTap: () => onPageChanged(page),
      ));
      pages.add(const SizedBox(width: 4));
    }

    if (totalPages <= 5) {
      for (int i = 1; i <= totalPages; i++) {
        addPage(i);
      }
    } else {
      addPage(1);
      addPage(2);
      addPage(3);
      pages.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text('...',
            style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.textGrey)),
      ));
      pages.add(const SizedBox(width: 4));
      addPage(totalPages);
    }
    return pages;
  }
}

class _PageBtn extends StatelessWidget {
  const _PageBtn({
    required this.label,
    this.isActive = false,
    this.enabled = true,
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
