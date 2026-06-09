import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_top_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mock data
// ─────────────────────────────────────────────────────────────────────────────

enum _ReportStatus { menunggu, diproses, selesai }

class _ReportItem {
  const _ReportItem({
    required this.id,
    required this.nama,
    required this.unit,
    required this.kategori,
    required this.subjek,
    required this.tanggal,
    required this.status,
  });
  final String id;
  final String nama;
  final String unit;
  final String kategori;
  final String subjek;
  final String tanggal;
  final _ReportStatus status;
}

const _allReports = [
  _ReportItem(
    id: '#REP-8231',
    nama: 'Budi Santoso',
    unit: 'Tower A - 12B',
    kategori: 'Infrastruktur',
    subjek: 'Kebocoran pipa air di lorong lantai 12 d...',
    tanggal: 'Today, 09:45',
    status: _ReportStatus.menunggu,
  ),
  _ReportItem(
    id: '#REP-8229',
    nama: 'Siti Aminah',
    unit: 'Tower B - 05C',
    kategori: 'Manajemen',
    subjek: 'Komplain mengenai biaya parkir tamba...',
    tanggal: 'Yesterday, 14:20',
    status: _ReportStatus.diproses,
  ),
  _ReportItem(
    id: '#REP-8215',
    nama: 'David Wilson',
    unit: 'Vila Gardenia - 02',
    kategori: 'Infrastruktur',
    subjek: 'Lampu taman area clubhouse mati seja...',
    tanggal: '24 Oct 2023',
    status: _ReportStatus.selesai,
  ),
  _ReportItem(
    id: '#REP-8210',
    nama: 'Rina Kusuma',
    unit: 'Tower A - 08A',
    kategori: 'Manajemen',
    subjek: 'Permintaan penggantian kartu akses...',
    tanggal: '23 Oct 2023',
    status: _ReportStatus.selesai,
  ),
  _ReportItem(
    id: '#REP-8208',
    nama: 'Hendra Wijaya',
    unit: 'Tower C - 03D',
    kategori: 'Infrastruktur',
    subjek: 'AC unit tidak berfungsi sejak 2 hari lalu...',
    tanggal: '22 Oct 2023',
    status: _ReportStatus.diproses,
  ),
];

const _tabs = ['Semua Laporan', 'Manajemen', 'Infrastruktur'];

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  String _activeTab = 'Semua Laporan';
  _ReportItem? _selectedReport;
  int _currentPage = 1;

  List<_ReportItem> get _filtered {
    if (_activeTab == 'Semua Laporan') return _allReports;
    return _allReports.where((r) => r.kategori == _activeTab).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // ── Sidebar ────────────────────────────────────────────────────
          const AdminSidebar(activePage: AdminPage.reports),

          // ── Main content ───────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                AdminTopBar(
                  searchHint: 'Cari laporan atau nama warga...',
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Page header ──────────────────────────────────
                        Text(
                          'Laporan & Keluhan Warga',
                          style: GoogleFonts.inter(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pusat komando manajemen operasional dan keamanan kawasan.',
                          style: GoogleFonts.inter(
                              fontSize: 13, color: AppColors.textGrey),
                        ),

                        const SizedBox(height: 24),

                        // ── Stat cards ───────────────────────────────────
                        _StatCardsRow(),

                        const SizedBox(height: 24),

                        // ── Table card ───────────────────────────────────
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              // Tab bar + filter
                              _TabBar(
                                activeTab: _activeTab,
                                onTabChanged: (t) => setState(() {
                                  _activeTab = t;
                                  _currentPage = 1;
                                  _selectedReport = null;
                                }),
                              ),

                              // Table
                              _ReportTable(
                                reports: _filtered,
                                selectedReport: _selectedReport,
                                onRowTap: (r) => setState(
                                    () => _selectedReport = r),
                              ),

                              // Pagination
                              _PaginationBar(
                                currentPage: _currentPage,
                                totalItems: 1284,
                                onPageChanged: (p) =>
                                    setState(() => _currentPage = p),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Bottom: detail + statistik ───────────────────
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: _DetailPanel(report: _selectedReport),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 3,
                              child: const _StatistikPanel(),
                            ),
                          ],
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

// ─────────────────────────────────────────────────────────────────────────────
// Stat cards
// ─────────────────────────────────────────────────────────────────────────────

class _StatCardsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _StatCard(
            label: 'Total Laporan',
            value: '1,284',
            sub: '↑ 12% dari bulan lalu',
            subColor: Color(0xFF16A34A),
            icon: Icons.bar_chart_rounded,
            iconColor: AppColors.primary,
            accentColor: AppColors.primary,
          ),
        ),
        SizedBox(width: 14),
        Expanded(
          child: _StatCard(
            label: 'Menunggu',
            value: '42',
            sub: 'Butuh respon segera',
            subColor: Color(0xFFF97316),
            icon: Icons.pending_actions_outlined,
            iconColor: Color(0xFFF97316),
            accentColor: Color(0xFFF97316),
          ),
        ),
        SizedBox(width: 14),
        Expanded(
          child: _StatCard(
            label: 'Diproses',
            value: '18',
            sub: 'Sedang ditangani tim',
            subColor: AppColors.primary,
            icon: Icons.supervised_user_circle_outlined,
            iconColor: AppColors.primary,
            accentColor: AppColors.primary,
          ),
        ),
        SizedBox(width: 14),
        Expanded(
          child: _StatCard(
            label: 'Selesai',
            value: '1,224',
            sub: 'Tingkat resolusi 95%',
            subColor: Color(0xFF16A34A),
            icon: Icons.check_circle_outline,
            iconColor: Color(0xFF16A34A),
            accentColor: Color(0xFF16A34A),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.subColor,
    required this.icon,
    required this.iconColor,
    required this.accentColor,
  });
  final String label;
  final String value;
  final String sub;
  final Color subColor;
  final IconData icon;
  final Color iconColor;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Accent bar top
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icon, size: 20, color: iconColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sub,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: subColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab bar
// ─────────────────────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  const _TabBar({required this.activeTab, required this.onTabChanged});
  final String activeTab;
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
          ..._tabs.map((tab) {
            final isActive = tab == activeTab;
            return GestureDetector(
              onTap: () => onTabChanged(tab),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 4, vertical: 14),
                margin: const EdgeInsets.only(right: 24),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive
                          ? AppColors.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  tab,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive
                        ? AppColors.primary
                        : AppColors.textGrey,
                  ),
                ),
              ),
            );
          }).toList(),

          const Spacer(),

          // Filter button
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.filter_list_outlined,
                      size: 16, color: AppColors.textGrey),
                  const SizedBox(width: 6),
                  Text(
                    'Filter',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textGrey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Report table
// ─────────────────────────────────────────────────────────────────────────────

class _ReportTable extends StatelessWidget {
  const _ReportTable({
    required this.reports,
    required this.selectedReport,
    required this.onRowTap,
  });
  final List<_ReportItem> reports;
  final _ReportItem? selectedReport;
  final ValueChanged<_ReportItem> onRowTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          color: const Color(0xFFF8FAFC),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          child: Row(
            children: const [
              SizedBox(width: 6), // space for left strip
              SizedBox(width: 100, child: _ColH('ID LAPORAN')),
              Expanded(flex: 2, child: _ColH('NAMA WARGA\n& UNIT')),
              Expanded(flex: 2, child: _ColH('KATEGORI')),
              Expanded(flex: 3, child: _ColH('SUBJEK/DESKRIPSI')),
              Expanded(flex: 2, child: _ColH('TANGGAL\nMASUK')),
              SizedBox(width: 110, child: _ColH('STATUS')),
            ],
          ),
        ),

        // Rows
        if (reports.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                'Tidak ada laporan.',
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textGrey),
              ),
            ),
          )
        else
          ...reports
              .map((r) => _ReportRow(
                    item: r,
                    isSelected: selectedReport?.id == r.id,
                    onTap: () => onRowTap(r),
                  ))
              .toList(),
      ],
    );
  }
}

class _ColH extends StatelessWidget {
  const _ColH(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppColors.textGrey,
        letterSpacing: 0.4,
        height: 1.4,
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });
  final _ReportItem item;
  final bool isSelected;
  final VoidCallback onTap;

  Color get _stripColor {
    switch (item.status) {
      case _ReportStatus.menunggu:
        return const Color(0xFFF97316);
      case _ReportStatus.diproses:
        return AppColors.primary;
      case _ReportStatus.selesai:
        return const Color(0xFF16A34A);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.04)
              : Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade100)),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left color strip
              Container(width: 4, color: _stripColor),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      // ID
                      SizedBox(
                        width: 86,
                        child: Text(
                          item.id,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),

                      // Nama & unit
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.nama,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            Text(
                              item.unit,
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.textGrey),
                            ),
                          ],
                        ),
                      ),

                      // Kategori badge
                      Expanded(
                        flex: 2,
                        child: _KategoriBadge(item.kategori),
                      ),

                      // Subjek
                      Expanded(
                        flex: 3,
                        child: Text(
                          item.subjek,
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textGrey,
                              height: 1.4),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),

                      // Tanggal
                      Expanded(
                        flex: 2,
                        child: Text(
                          item.tanggal,
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textGrey),
                        ),
                      ),

                      // Status badge
                      SizedBox(
                        width: 110,
                        child: _StatusBadge(item.status),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KategoriBadge extends StatelessWidget {
  const _KategoriBadge(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final isInfra = label == 'Infrastruktur';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isInfra
            ? const Color(0xFFEFF6FF)
            : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isInfra
              ? AppColors.primary
              : const Color(0xFF15803D),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status);
  final _ReportStatus status;

  @override
  Widget build(BuildContext context) {
    late Color dotColor;
    late Color bg;
    late Color fg;
    late String label;

    switch (status) {
      case _ReportStatus.menunggu:
        dotColor = const Color(0xFFF97316);
        bg = const Color(0xFFFFF7ED);
        fg = const Color(0xFFF97316);
        label = 'Menunggu';
        break;
      case _ReportStatus.diproses:
        dotColor = AppColors.primary;
        bg = const Color(0xFFEFF6FF);
        fg = AppColors.primary;
        label = 'Diproses';
        break;
      case _ReportStatus.selesai:
        dotColor = const Color(0xFF16A34A);
        bg = const Color(0xFFF0FDF4);
        fg = const Color(0xFF16A34A);
        label = 'Selesai';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration:
                BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pagination
// ─────────────────────────────────────────────────────────────────────────────

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.currentPage,
    required this.totalItems,
    required this.onPageChanged,
  });
  final int currentPage;
  final int totalItems;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final totalPages = (totalItems / 10).ceil();
    final start = (currentPage - 1) * 10 + 1;
    final end = (currentPage * 10).clamp(0, totalItems);

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Text(
            'Menampilkan $start-$end dari $totalItems laporan',
            style:
                GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey),
          ),
          const Spacer(),
          _PBtn(
            label: '<',
            enabled: currentPage > 1,
            onTap: () => onPageChanged(currentPage - 1),
          ),
          const SizedBox(width: 4),
          _PBtn(label: '1', isActive: currentPage == 1, onTap: () => onPageChanged(1)),
          const SizedBox(width: 4),
          _PBtn(label: '2', isActive: currentPage == 2, onTap: () => onPageChanged(2)),
          const SizedBox(width: 4),
          _PBtn(label: '3', isActive: currentPage == 3, onTap: () => onPageChanged(3)),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('...', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey)),
          ),
          const SizedBox(width: 4),
          _PBtn(
            label: '$totalPages',
            isActive: currentPage == totalPages,
            onTap: () => onPageChanged(totalPages),
          ),
          const SizedBox(width: 4),
          _PBtn(
            label: '>',
            enabled: currentPage < totalPages,
            onTap: () => onPageChanged(currentPage + 1),
          ),
        ],
      ),
    );
  }
}

class _PBtn extends StatelessWidget {
  const _PBtn({
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

// ─────────────────────────────────────────────────────────────────────────────
// Detail panel (empty / selected)
// ─────────────────────────────────────────────────────────────────────────────

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({required this.report});
  final _ReportItem? report;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 260),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: report == null ? _emptyState() : _detailState(),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.description_outlined,
              size: 36,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Pilih Laporan Untuk Detail',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Klik salah satu baris di atas untuk melihat detail\nkronologi, bukti foto, dan tanggapan admin.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textGrey,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailState() {
    final r = report!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                r.id,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              _StatusBadge(r.status),
            ],
          ),
          const SizedBox(height: 12),
          _detailRow('Pelapor', '${r.nama} — ${r.unit}'),
          _detailRow('Kategori', r.kategori),
          _detailRow('Tanggal Masuk', r.tanggal),
          const SizedBox(height: 8),
          Text(
            'Deskripsi',
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textGrey),
          ),
          const SizedBox(height: 4),
          Text(
            r.subjek,
            style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.textDark, height: 1.5),
          ),
          const SizedBox(height: 16),
          // Action buttons
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.reply, size: 16, color: Colors.white),
                label: Text(
                  'Tanggapi',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () {},
                icon: Icon(Icons.swap_horiz, size: 16, color: AppColors.textGrey),
                label: Text(
                  'Update Status',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textGrey),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textGrey),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.textDark),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Statistik Operasional panel
// ─────────────────────────────────────────────────────────────────────────────

class _StatistikPanel extends StatelessWidget {
  const _StatistikPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistik Operasional',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Rangkuman kinerja tim pemeliharaan minggu ini.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
              height: 1.4,
            ),
          ),

          const SizedBox(height: 24),

          _StatBar(label: 'Kecepatan Respon', value: 0.88, pct: '88%'),
          const SizedBox(height: 14),
          _StatBar(label: 'Kepuasan Warga', value: 0.92, pct: '92%'),
          const SizedBox(height: 14),
          _StatBar(label: 'SLA Tercapai', value: 0.75, pct: '75%'),

          const SizedBox(height: 24),

          // Quote box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '"Tim Infrastruktur sedang melakukan perawatan rutin lift Tower A hari ini pukul 13:00 WIB."',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBar extends StatelessWidget {
  const _StatBar({
    required this.label,
    required this.value,
    required this.pct,
  });
  final String label;
  final double value;
  final String pct;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.85)),
            ),
            Text(
              pct,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor:
                const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
