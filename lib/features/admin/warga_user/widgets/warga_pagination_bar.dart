import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import 'warga_shared_widgets.dart';

class WargaPaginationBar extends StatelessWidget {
  const WargaPaginationBar({
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
    final end   = (currentPage * pageSize).clamp(0, totalItems);

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Text(
            'Menampilkan $start–$end dari $totalItems warga',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey),
          ),
          const Spacer(),
          PageBtn(
            label: '<',
            enabled: currentPage > 1,
            onTap: () => onPageChanged(currentPage - 1),
          ),
          const SizedBox(width: 4),
          ..._buildPageNumbers(),
          const SizedBox(width: 4),
          PageBtn(
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
      pages.add(PageBtn(
        label   : '$page',
        isActive: page == currentPage,
        onTap   : () => onPageChanged(page),
      ));
      pages.add(const SizedBox(width: 4));
    }

    if (totalPages <= 5) {
      for (int i = 1; i <= totalPages; i++) addPage(i);
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
