// Halaman Detail Pembayaran — admin klik eye icon di billing table.
// Menampilkan: summary card user, timeline periode, rincian tagihan per bulan,
// info transaksi terakhir, dan riwayat semua transaksi penghuni.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../pembayaran/data/payment_repository.dart';
import '../pembayaran/models/tagihan_model.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Page
// ═══════════════════════════════════════════════════════════════════════════════

class AdminPaymentDetailPage extends StatefulWidget {
  const AdminPaymentDetailPage({
    super.key,
    required this.userId,
    required this.namaResiden,
    required this.blok,
    required this.nomorUnit,
    this.nomorHp,
  });

  final String userId;
  final String namaResiden;
  final String blok;
  final String nomorUnit;
  final String? nomorHp;

  @override
  State<AdminPaymentDetailPage> createState() => _AdminPaymentDetailPageState();
}

class _AdminPaymentDetailPageState extends State<AdminPaymentDetailPage> {
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

  // ── Helpers ─────────────────────────────────────────────────────────────────

  List<_TxGroup> _buildGroups(List<TagihanModel> all) {
    final byOrderId = <String, List<TagihanModel>>{};
    final manual    = <TagihanModel>[];

    for (final t in all) {
      if (t.status != StatusTagihan.lunas) continue;
      if (t.orderId?.isNotEmpty == true) {
        byOrderId.putIfAbsent(t.orderId!, () => []).add(t);
      } else {
        manual.add(t);
      }
    }

    final groups = <_TxGroup>[
      for (final e in byOrderId.entries)
        _TxGroup.fromTagihan(e.value, orderId: e.key),
      for (final t in manual)
        _TxGroup.fromTagihan([t], orderId: null),
    ];
    groups.sort((a, b) => b.maxKey.compareTo(a.maxKey));
    return groups;
  }

  bool _isAdvance(TagihanModel t) {
    final now = DateTime.now();
    return t.tahun > now.year ||
        (t.tahun == now.year && t.bulanIndex > now.month);
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildTopBar(context),
          Expanded(
            child: StreamBuilder<List<TagihanModel>>(
              stream: PaymentRepository.watchUserTagihan(widget.userId),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary));
                }
                final allTagihan = List<TagihanModel>.from(snap.data ?? []);
                allTagihan.sort((a, b) =>
                    (a.tahun * 12 + a.bulanIndex)
                        .compareTo(b.tahun * 12 + b.bulanIndex));

                final groups  = _buildGroups(allTagihan);
                final latestG = groups.isNotEmpty ? groups.first : null;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCard(allTagihan, latestG),
                      const SizedBox(height: 20),
                      _buildTimeline(allTagihan),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildDetailTable(allTagihan),
                          ),
                          const SizedBox(width: 20),
                          SizedBox(
                            width: 300,
                            child: _buildInfoCard(latestG, allTagihan),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildHistoryTable(groups),
                      const SizedBox(height: 40),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Top bar ──────────────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new, size: 13),
            label: Text('Kembali',
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Detail Pembayaran',
                    style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text('Pembayaran',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.textGrey)),
                    const _Chevron(),
                    Text('Billing',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.textGrey)),
                    const _Chevron(),
                    Text('Detail Pembayaran',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Summary card (gradient header) ──────────────────────────────────────────

  Widget _buildSummaryCard(List<TagihanModel> allTagihan, _TxGroup? latestG) {
    final initials = widget.namaResiden.isNotEmpty
        ? widget.namaResiden.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join()
        : '?';

    final totalDibayar = allTagihan
        .where((t) => t.status == StatusTagihan.lunas)
        .fold(0, (s, t) => s + t.jumlah);
    final totalBulanLunas =
        allTagihan.where((t) => t.status == StatusTagihan.lunas).length;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + name + badge
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                child: Text(initials,
                    style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(widget.namaResiden,
                              style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4)),
                          ),
                          child: Text('Penghuni Aktif',
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.blok} – No. ${widget.nomorUnit}'
                      '${widget.nomorHp != null ? "  •  ${widget.nomorHp}" : ""}',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          // Stat pills
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              _StatPill(
                  label: 'TOTAL DIBAYAR',
                  value: formatRupiah(totalDibayar)),
              _StatPill(
                  label: 'TOTAL BULAN',
                  value: '$totalBulanLunas Bulan'),
              if (latestG != null) ...[
                _StatPill(
                    label: 'METODE',
                    value: latestG.metode.isNotEmpty ? latestG.metode : '-'),
                if (latestG.orderId != null)
                  _StatPill(
                      label: 'ORDER ID',
                      value: latestG.orderId!,
                      mono: true),
                _StatPill(
                    label: 'TANGGAL BAYAR',
                    value: latestG.tanggalBayar),
                const _StatPill(
                    label: 'STATUS PEMBAYARAN',
                    value: '✓ Lunas',
                    valueColor: Color(0xFF86EFAC)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── Timeline horizontal ──────────────────────────────────────────────────────

  Widget _buildTimeline(List<TagihanModel> allTagihan) {
    if (allTagihan.isEmpty) return const SizedBox.shrink();

    final advanceItems = allTagihan
        .where((t) => t.status == StatusTagihan.lunas && _isAdvance(t))
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

    return _SectionCard(
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
                  _ArrowBtn(
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
                      itemCount: allTagihan.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: _cardGap),
                      itemBuilder: (_, i) {
                        final t    = allTagihan[i];
                        final isFirst = i == 0;
                        final isLast  = i == allTagihan.length - 1;
                        return _TimelineCard(
                          tagihan: t,
                          isFirst: isFirst,
                          isLast: isLast,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Arrow right
                  _ArrowBtn(
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

  // ── Rincian tagihan per bulan ────────────────────────────────────────────────

  Widget _buildDetailTable(List<TagihanModel> allTagihan) {
    return _SectionCard(
      title: 'Rincian Tagihan per Bulan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            color: const Color(0xFFF8FAFC),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Expanded(flex: 2, child: _TblHeader('PERIODE')),
                const Expanded(flex: 2, child: _TblHeader('TAGIHAN')),
                const Expanded(flex: 2, child: _TblHeader('JATUH TEMPO')),
                const Expanded(flex: 2, child: _TblHeader('STATUS')),
                const Expanded(flex: 2, child: _TblHeader('KETERANGAN')),
              ],
            ),
          ),
          // Rows
          ...allTagihan.map((t) => _DetailRow(tagihan: t)),

          // Info banner advance
          if (allTagihan.any(_isAdvance)) ...[
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF9C3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFDE047)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline,
                        size: 14, color: Color(0xFFCA8A04)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pembayaran lebih awal akan otomatis digunakan '
                        'saat tagihan bulan berjalan jatuh tempo.',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF854D0E)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Info pembayaran card ─────────────────────────────────────────────────────

  // Helper: ikon & warna berdasarkan metode
  static (IconData, Color) _metodeIcon(String metode) {
    final lower = metode.toLowerCase();
    if (lower.contains('qris')) return (Icons.qr_code, const Color(0xFF1D4ED8));
    if (lower.contains('tunai')) return (Icons.payments_outlined, Colors.green);
    return (Icons.payment, AppColors.textGrey);
  }

  Widget _buildInfoCard(_TxGroup? latestG, List<TagihanModel> allTagihan) {
    String? catatan;
    if (latestG != null) {
      final advance = latestG.tagihan.where(_isAdvance).toList()
        ..sort((a, b) => (a.tahun * 12 + a.bulanIndex)
            .compareTo(b.tahun * 12 + b.bulanIndex));
      if (advance.isNotEmpty) {
        final n    = advance.length;
        final from = advance.first.periodeLabel;
        final to   = advance.last.periodeLabel;
        catatan = n == 1
            ? 'Pembayaran 1 bulan ke depan ($from)'
            : 'Pembayaran untuk $n bulan ke depan ($from – $to)';
      }
    }

    return _SectionCard(
      title: 'Informasi Pembayaran',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: latestG == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text('Belum ada transaksi',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.textGrey)),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(
                    label: 'Metode Pembayaran',
                    value: latestG.metode.isNotEmpty ? latestG.metode : '-',
                    icon: _metodeIcon(latestG.metode).$1,
                    iconColor: _metodeIcon(latestG.metode).$2,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    label: 'Order ID',
                    value: latestG.orderId ?? '-',
                    mono: true,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    label: 'Tanggal Pembayaran',
                    value: latestG.tanggalBayar,
                    icon: Icons.calendar_today_outlined,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    label: 'Total Dibayar',
                    value: formatRupiah(latestG.totalJumlah),
                    valueColor: AppColors.primary,
                    bold: true,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    label: 'Jumlah Bulan',
                    value: '${latestG.tagihan.length} Bulan',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text('Status',
                            style: GoogleFonts.inter(
                                fontSize: 12, color: AppColors.textGrey)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Lunas',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700)),
                      ),
                    ],
                  ),
                  if (catatan != null) ...[
                    const SizedBox(height: 12),
                    _InfoRow(
                        label: 'Catatan',
                        value: catatan,
                        valueColor: AppColors.textGrey),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Fitur unduh bukti pembayaran segera hadir.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.download_outlined, size: 16),
                      label: Text('Unduh Bukti Pembayaran',
                          style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Riwayat pembayaran ───────────────────────────────────────────────────────

  Widget _buildHistoryTable(List<_TxGroup> groups) {
    return _SectionCard(
      title: 'Riwayat Pembayaran Penghuni',
      child: Column(
        children: [
          // Header
          Container(
            color: const Color(0xFFF8FAFC),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Expanded(flex: 2, child: _TblHeader('TANGGAL')),
                const Expanded(flex: 3, child: _TblHeader('ORDER ID')),
                const Expanded(flex: 2, child: _TblHeader('JUMLAH')),
                const Expanded(flex: 3, child: _TblHeader('BULAN DIBAYAR')),
                const Expanded(flex: 2, child: _TblHeader('METODE')),
                const Expanded(flex: 2, child: _TblHeader('STATUS')),
                const SizedBox(width: 40, child: _TblHeader('AKSI')),
              ],
            ),
          ),
          if (groups.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text('Belum ada riwayat pembayaran.',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.textGrey)),
              ),
            )
          else
            ...groups.map((g) => _HistoryRow(group: g)),
        ],
      ),
    );
  }

}

// ═══════════════════════════════════════════════════════════════════════════════
// Data helper
// ═══════════════════════════════════════════════════════════════════════════════

class _TxGroup {
  _TxGroup._({
    required this.orderId,
    required this.tagihan,
    required this.totalJumlah,
    required this.metode,
    required this.tanggalBayar,
  });

  factory _TxGroup.fromTagihan(List<TagihanModel> raw, {String? orderId}) {
    final sorted = List<TagihanModel>.from(raw)
      ..sort((a, b) => (a.tahun * 12 + a.bulanIndex)
          .compareTo(b.tahun * 12 + b.bulanIndex));
    return _TxGroup._(
      orderId     : orderId,
      tagihan     : sorted,
      totalJumlah : sorted.fold(0, (s, t) => s + t.jumlah),
      metode      : sorted.first.metodeBayar ?? '-',
      tanggalBayar: sorted.first.tanggalBayar ?? '-',
    );
  }

  final String?            orderId;
  final List<TagihanModel> tagihan;
  final int                totalJumlah;
  final String             metode;
  final String             tanggalBayar;

  int get maxKey => tagihan.fold(
      0,
      (s, t) =>
          s > (t.tahun * 12 + t.bulanIndex) ? s : (t.tahun * 12 + t.bulanIndex));

  String get periodeRange {
    if (tagihan.isEmpty) return '-';
    if (tagihan.length == 1) return tagihan.first.periodeLabel;
    return '${tagihan.first.periodeLabel} – ${tagihan.last.periodeLabel}'
        ' (${tagihan.length} bulan)';
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Section card wrapper
// ═══════════════════════════════════════════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Text(title,
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          child,
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Stat pill (summary card)
// ═══════════════════════════════════════════════════════════════════════════════

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    this.mono = false,
    this.valueColor,
  });
  final String label;
  final String value;
  final bool   mono;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withValues(alpha: 0.7),
                  letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(
            value,
            style: mono
                ? GoogleFonts.sourceCodePro(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? Colors.white)
                : GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? Colors.white),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Info row (info card)
// ═══════════════════════════════════════════════════════════════════════════════

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
    this.valueColor,
    this.mono  = false,
    this.bold  = false,
  });
  final String   label;
  final String   value;
  final IconData? icon;
  final Color?   iconColor;
  final Color?   valueColor;
  final bool     mono;
  final bool     bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(label,
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textGrey)),
        ),
        Expanded(
          flex: 3,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: iconColor ?? AppColors.textGrey),
                const SizedBox(width: 5),
              ],
              Expanded(
                child: Text(
                  value,
                  style: mono
                      ? GoogleFonts.sourceCodePro(
                          fontSize: 11,
                          color: valueColor ?? AppColors.textDark)
                      : GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: bold
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: valueColor ?? AppColors.textDark),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Timeline card
// ═══════════════════════════════════════════════════════════════════════════════

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({
    required this.tagihan,
    required this.isFirst,
    required this.isLast,
  });
  final TagihanModel tagihan;
  final bool isFirst;
  final bool isLast;

  bool get _isLunas => tagihan.status == StatusTagihan.lunas;

  (Color, Color, String) get _statusInfo {
    final now = DateTime.now();
    final isFuture = tagihan.tahun > now.year ||
        (tagihan.tahun == now.year && tagihan.bulanIndex > now.month);
    return switch (tagihan.status) {
      StatusTagihan.lunas     => (const Color(0xFF16A34A), const Color(0xFFDCFCE7), '(Sudah Lunas)'),
      StatusTagihan.jatuhTempo => (const Color(0xFFD97706), const Color(0xFFFEF3C7), '(Jatuh Tempo)'),
      StatusTagihan.pending   => (const Color(0xFFCA8A04), const Color(0xFFFEF9C3), '(Pending)'),
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

// ═══════════════════════════════════════════════════════════════════════════════
// Detail table row
// ═══════════════════════════════════════════════════════════════════════════════

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.tagihan});
  final TagihanModel tagihan;

  bool get _isLunas => tagihan.status == StatusTagihan.lunas;
  bool get _isPakasirPaid =>
      _isLunas && (tagihan.orderId?.isNotEmpty == true);

  String get _keterangan {
    if (!_isLunas) return '-';
    return _isPakasirPaid ? 'Dibayar lebih awal' : 'Lunas Manual';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          // Periode
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(
                  _isLunas
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  size: 13,
                  color: _isLunas
                      ? Colors.green.shade500
                      : Colors.grey.shade400,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(tagihan.periodeLabel,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textDark),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          // Tagihan
          Expanded(
            flex: 2,
            child: Text(tagihan.jumlahFormatted,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark)),
          ),
          // Jatuh tempo
          Expanded(
            flex: 2,
            child: Text(tagihan.jatuhTempo,
                style: GoogleFonts.inter(
                    fontSize: 11, color: AppColors.textGrey)),
          ),
          // Status badge
          Expanded(
            flex: 2,
            child: _DetailStatusBadge(status: tagihan.status),
          ),
          // Keterangan
          Expanded(
            flex: 2,
            child: Text(
              _keterangan,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: _isPakasirPaid
                    ? const Color(0xFF1D4ED8)
                    : AppColors.textGrey,
                fontStyle: _isPakasirPaid
                    ? FontStyle.normal
                    : FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// History table row
// ═══════════════════════════════════════════════════════════════════════════════

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.group});
  final _TxGroup group;

  @override
  Widget build(BuildContext context) {
    final isPakasir = group.metode.toLowerCase().contains('pakasir');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          // Tanggal
          Expanded(
            flex: 2,
            child: Text(group.tanggalBayar,
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textDark)),
          ),
          // Order ID
          Expanded(
            flex: 3,
            child: Text(
              group.orderId ?? '-',
              style: GoogleFonts.sourceCodePro(
                  fontSize: 11,
                  color: group.orderId != null
                      ? AppColors.primary
                      : AppColors.textGrey),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Jumlah
          Expanded(
            flex: 2,
            child: Text(formatRupiah(group.totalJumlah),
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark)),
          ),
          // Bulan dibayar
          Expanded(
            flex: 3,
            child: Text(group.periodeRange,
                style: GoogleFonts.inter(
                    fontSize: 11, color: AppColors.textGrey)),
          ),
          // Metode
          Expanded(
            flex: 2,
            child: _HistMetodeBadge(metode: group.metode),
          ),
          // Status
          Expanded(
            flex: 2,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text('Lunas',
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700)),
            ),
          ),
          // Aksi
          SizedBox(
            width: 40,
            child: Center(
              child: Tooltip(
                message: 'Lihat detail',
                child: InkWell(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fitur ini segera hadir.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  ),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.remove_red_eye_outlined,
                        size: 14, color: AppColors.textGrey),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Small helper widgets
// ═══════════════════════════════════════════════════════════════════════════════

class _Chevron extends StatelessWidget {
  const _Chevron();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Icon(Icons.chevron_right,
            size: 13, color: Colors.grey.shade400),
      );
}

class _TblHeader extends StatelessWidget {
  const _TblHeader(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppColors.textGrey,
          letterSpacing: 0.4));
}

class _ArrowBtn extends StatelessWidget {
  const _ArrowBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });
  final IconData icon;
  final bool     enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(6),
          boxShadow: enabled
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 6)]
              : null,
        ),
        child: Icon(icon,
            size: 18,
            color: enabled ? Colors.white : Colors.grey.shade400),
      ),
    );
  }
}

class _DetailStatusBadge extends StatelessWidget {
  const _DetailStatusBadge({required this.status});
  final StatusTagihan status;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, String label) = switch (status) {
      StatusTagihan.lunas      => (Colors.green.shade50, Colors.green.shade700, 'Lunas'),
      StatusTagihan.belumBayar => (Colors.red.shade50,   Colors.red.shade700,   'Belum Bayar'),
      StatusTagihan.jatuhTempo => (Colors.orange.shade50,Colors.orange.shade700,'Jatuh Tempo'),
      StatusTagihan.pending    => (Colors.amber.shade50, Colors.amber.shade800, 'Pending'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(5)),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
    );
  }
}

class _HistMetodeBadge extends StatelessWidget {
  const _HistMetodeBadge({required this.metode});
  final String metode;

  @override
  Widget build(BuildContext context) {
    final lower   = metode.toLowerCase();
    final isQris  = lower.contains('qris');
    final isTunai = lower.contains('tunai');

    final (Color bg, Color fg, IconData icon, String label) = isQris
        ? (const Color(0xFFEFF6FF), const Color(0xFF1D4ED8), Icons.qr_code, 'QRIS')
        : isTunai
            ? (Colors.green.shade50, Colors.green.shade700, Icons.payments_outlined, 'Tunai')
            : (Colors.grey.shade100, AppColors.textGrey, Icons.payment, metode);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(5)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: fg),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
        ],
      ),
    );
  }
}
