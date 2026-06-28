import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../models/feed_item.dart';

class HomeActivitySection extends StatefulWidget {
  const HomeActivitySection({super.key, required this.items});
  final List<FeedItem> items;

  @override
  State<HomeActivitySection> createState() => _HomeActivitySectionState();
}

class _HomeActivitySectionState extends State<HomeActivitySection> {
  static const int _pageSize = 5;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final all      = widget.items;
    final shown    = _expanded ? all : all.take(_pageSize).toList();
    final hasMore  = all.length > _pageSize;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Aktivitas Terkini',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              if (hasMore)
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Text(
                    _expanded ? 'Sembunyikan' : 'Lihat Semua',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Empty state ───────────────────────────────────────────────────
          if (all.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.history_rounded,
                        size: 36, color: Colors.grey.shade300),
                    const SizedBox(height: 8),
                    Text(
                      'Belum ada aktivitas',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.textGrey),
                    ),
                  ],
                ),
              ),
            )

          // ── List ──────────────────────────────────────────────────────────
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: List.generate(
                  shown.length,
                  (i) => ActivityTile(
                    item  : shown[i],
                    isLast: i == shown.length - 1 && !hasMore,
                  ),
                )..addAll(
                  // Footer "lihat semua / sembunyikan" di dalam card
                  hasMore
                      ? [
                          InkWell(
                            onTap: () =>
                                setState(() => _expanded = !_expanded),
                            borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(14)),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _expanded
                                        ? 'Sembunyikan'
                                        : 'Lihat ${all.length - _pageSize} lainnya',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    _expanded
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ]
                      : const <Widget>[],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ActivityTile extends StatelessWidget {
  const ActivityTile({super.key, required this.item, required this.isLast});

  final FeedItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: item.iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, size: 20, color: item.iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.label,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    if (item.badgeLabel != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: (item.badgeColor ?? AppColors.primary)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item.badgeLabel!,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: item.badgeColor ?? AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.sublabel,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item.waktu,
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }
}
