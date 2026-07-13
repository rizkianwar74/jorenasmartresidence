part of '../satpam_home_page.dart';


// ─────────────────────────────────────────────────────────────────────────────
// Recent Activity Section — 5 teratas, expand untuk lihat semua
// ─────────────────────────────────────────────────────────────────────────────
class _RecentActivitySection extends StatefulWidget {
  const _RecentActivitySection({required this.items});
  final List<_FeedItem> items;

  @override
  State<_RecentActivitySection> createState() => _RecentActivitySectionState();
}

class _RecentActivitySectionState extends State<_RecentActivitySection> {
  static const int _pageSize = 5;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final total    = widget.items.length;
    final visible  = _expanded ? total : total.clamp(0, _pageSize);
    final shown    = widget.items.take(visible).toList();
    final remaining = total - _pageSize;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Aktivitas Terkini',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0D1B2A),
                ),
              ),
              if (total > 0)
                Text(
                  '$total aktivitas',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: const Color(0xFF94A3B8)),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Empty state ──────────────────────────────────────────────────
          if (total == 0)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.history_rounded,
                        size: 36, color: Colors.grey.shade300),
                    const SizedBox(height: 8),
                    Text(
                      'Belum ada aktivitas.',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: const Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
            )
          else
            // ── List card ────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  ...List.generate(shown.length, (i) {
                    final isLastItem = i == shown.length - 1 &&
                        (_expanded || total <= _pageSize);
                    return _AktivitasTile(
                      item: shown[i],
                      isLast: isLastItem,
                    );
                  }),

                  // ── Footer expand / collapse ─────────────────────────
                  if (total > _pageSize)
                    GestureDetector(
                      onTap: () => setState(() => _expanded = !_expanded),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                                color: Colors.grey.shade100, width: 1),
                          ),
                          borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(16)),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _expanded
                                  ? 'Sembunyikan'
                                  : 'Lihat $remaining lainnya',
                              style: GoogleFonts.inter(
                                fontSize: 13,
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
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AktivitasTile extends StatelessWidget {
  const _AktivitasTile({required this.item, required this.isLast});
  final _FeedItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: item.iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: item.iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.label,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0D1B2A),
                        )),
                    const SizedBox(height: 2),
                    Text(item.sublabel,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: const Color(0xFF94A3B8)),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(item.waktu,
                  style: GoogleFonts.inter(
                      fontSize: 11, color: const Color(0xFF94A3B8))),
            ],
          ),
        ),
        if (!isLast)
          Divider(height: 1, indent: 72, endIndent: 16,
              color: Colors.grey.shade100),
      ],
    );
  }
}
