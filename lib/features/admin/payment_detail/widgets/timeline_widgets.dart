import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../pembayaran/models/tagihan_model.dart';
import 'payment_detail_shared_widgets.dart';

bool isAdvanceTagihan(TagihanModel t) {
  final now = DateTime.now();
  return t.tahun > now.year ||
      (t.tahun == now.year && t.bulanIndex > now.month);
}

class TimelineSection extends StatefulWidget {
  const TimelineSection({
    super.key,
    required this.allTagihan,
  });
  final List<TagihanModel> allTagihan;

  @override
  State<TimelineSection> createState() => _TimelineSectionState();
}

class _TimelineSectionState extends State<TimelineSection> {
  final _timelineCtrl = ScrollController();
  static const double _cardW = 148.0;
  static const double _cardGap = 12.0;

  @override
  void initState() {
    super.initState();
    _timelineCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _timelineCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.allTagihan.isEmpty) return const SizedBox.shrink();

    final advanceItems = widget.allTagihan
        .where((t) => t.status == StatusTagihan.lunas && isAdvanceTagihan(t))
        .toList()
      ..sort((a, b) => (a.tahun * 12 + a.bulanIndex)
          .compareTo(b.tahun * 12 + b.bulanIndex));

    String? advanceNote;
    if (advanceItems.isNotEmpty) {
      final n = advanceItems.length;
      final from = advanceItems.first.periodeLabel;
      final to   = advanceItems.last.periodeLabel;
      advanceNote = n == 1
          ? 'Penghuni ini telah membayar 1 bulan ke depan ($from).'
          : 'Penghuni ini telah membayar $n bulan ke depan ($from – $to).';
    }

    final canScrollLeft  = _timelineCtrl.hasClients && _timelineCtrl.offset > 0;
    final canScrollRight = _timelineCtrl.hasClients &&
        _timelineCtrl.offset < _timelineCtrl.position.maxScrollExtent;

    return SectionCard(
      title: 'Periode yang Dibayar',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 110,
              child: Row(
                children: [
                  // Arrow left
                  ArrowBtn(
                    icon: Icons.chevron_left,
                    enabled: canScrollLeft,
                    onTap: () => _timelineCtrl.animateTo(
                      (_timelineCtrl.offset - (_cardW + _cardGap))
                          .clamp(0, double.infinity),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Scrollable cards
                  Expanded(
                    child: ListView.separated(
                      controller: _timelineCtrl,
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.allTagihan.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: _cardGap),
                      itemBuilder: (_, i) {
                        final t    = widget.allTagihan[i];
                        final isFirst = i == 0;
                        final isLast  = i == widget.allTagihan.length - 1;
                        return TimelineCard(
                          tagihan: t,
                          isFirst: isFirst,
                          isLast: isLast,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Arrow right
                  ArrowBtn(
                    icon: Icons.chevron_right,
                    enabled: canScrollRight,
                    onTap: () => _timelineCtrl.animateTo(
                      (_timelineCtrl.offset + (_cardW + _cardGap))
                          .clamp(0, _timelineCtrl.position.maxScrollExtent),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                  ),
                ],
              ),
            ),

            // Advance note
            if (advanceNote != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 14, color: Color(0xFF16A34A)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(advanceNote,
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF16A34A),
                              fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class TimelineCard extends StatelessWidget {
  const TimelineCard({
    super.key,
    required this.tagihan,
    required this.isFirst,
    required this.isLast,
  });
  final TagihanModel tagihan;
  final bool isFirst;
  final bool isLast;

  bool get _isLunas => tagihan.status == StatusTagihan.lunas;

  (Color, Color, String) get _statusInfo {
    final isFuture = isAdvanceTagihan(tagihan);
    return switch (tagihan.status) {
      StatusTagihan.lunas      => (const Color(0xFF16A34A), const Color(0xFFDCFCE7), '(Sudah Lunas)'),
      StatusTagihan.jatuhTempo => (const Color(0xFFD97706), const Color(0xFFFEF3C7), '(Jatuh Tempo)'),
      StatusTagihan.pending    => (const Color(0xFFCA8A04), const Color(0xFFFEF9C3), '(Pending)'),
      _ => isFuture
          ? (const Color(0xFF94A3B8), const Color(0xFFF1F5F9), '(Belum Jatuh Tempo)')
          : (const Color(0xFFDC2626), const Color(0xFFFEE2E2), '(Belum Dibayar)'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (dotColor, bgColor, statusText) = _statusInfo;

    return Container(
      width: 148,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: dotColor.withValues(alpha: _isLunas ? 0.4 : 0.3),
            width: _isLunas ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Dot indicator
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    color: dotColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(tagihan.bulan,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('${tagihan.tahun}',
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.textGrey)),
          const SizedBox(height: 6),
          Text(tagihan.jumlahFormatted,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark)),
          const SizedBox(height: 4),
          Text(statusText,
              style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: dotColor)),
        ],
      ),
    );
  }
}
