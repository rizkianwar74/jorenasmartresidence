import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class ReportsTabBar extends StatelessWidget {
  const ReportsTabBar({
    super.key,
    required this.activeTab,
    required this.tabs,
    required this.counts,
    required this.onTabChanged,
  });
  final String activeTab;
  final List<String> tabs;
  final Map<String, int> counts;
  final ValueChanged<String> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          ...tabs.map((tab) {
            final isActive = tab == activeTab;
            final cnt = counts[tab];
            return GestureDetector(
              onTap: () => onTabChanged(tab),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
                margin: const EdgeInsets.only(right: 22),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(
                    color: isActive ? AppColors.primary : Colors.transparent,
                    width: 2,
                  )),
                ),
                child: Row(
                  children: [
                    Text(tab, style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive ? AppColors.primary : AppColors.textGrey,
                    )),
                    if (cnt != null && cnt > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.primary : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('$cnt', style: GoogleFonts.inter(
                          fontSize: 10, fontWeight: FontWeight.bold,
                          color: isActive ? Colors.white : AppColors.textGrey,
                        )),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
