import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/keluhan_repository.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/admin_top_bar.dart';
import 'widgets/reports_shared_widgets.dart';
import 'widgets/reports_tab_bar.dart';
import 'widgets/report_table.dart';
import 'widgets/report_pagination_bar.dart';
import 'widgets/detail_panel.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  StreamSubscription<List<KeluhanItem>>? _sub;
  List<KeluhanItem> _all = [];
  bool _loading = true;

  String _activeTab   = 'Semua';
  KeluhanItem? _selected;

  static const _tabs = ['Semua', 'Menunggu', 'Diproses', 'Selesai', 'Ditolak'];

  static const _perPage = 10;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _sub = KeluhanRepository.watchAllKeluhan().listen(
      (list) {
        if (mounted) setState(() { _all = list; _loading = false; });
      },
      onError: (_) { if (mounted) setState(() => _loading = false); },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  List<KeluhanItem> get _filtered {
    switch (_activeTab) {
      case 'Menunggu': return _all.where((i) => i.status == StatusKeluhan.menunggu).toList();
      case 'Diproses': return _all.where((i) => i.status == StatusKeluhan.diproses).toList();
      case 'Selesai':  return _all.where((i) => i.status == StatusKeluhan.selesai).toList();
      case 'Ditolak':  return _all.where((i) => i.status == StatusKeluhan.ditolak).toList();
      default:         return _all;
    }
  }

  // ── Stat counts ──────────────────────────────────────────────────────────
  int get _cntMenunggu => _all.where((i) => i.status == StatusKeluhan.menunggu).length;
  int get _cntDiproses => _all.where((i) => i.status == StatusKeluhan.diproses).length;
  int get _cntSelesai  => _all.where((i) => i.status == StatusKeluhan.selesai).length;

  // ── Pagination ───────────────────────────────────────────────────────────
  int get _totalPages => (_filtered.length / _perPage).ceil().clamp(1, 9999);

  List<KeluhanItem> get _pageItems {
    final page  = _currentPage.clamp(1, _totalPages);
    final start = (page - 1) * _perPage;
    final end   = (start + _perPage).clamp(0, _filtered.length);
    return _filtered.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          const AdminSidebar(activePage: AdminPage.reports),
          Expanded(
            child: Column(
              children: [
                const AdminTopBar(searchHint: 'Cari laporan atau nama warga...'),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Header ──────────────────────────────────
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
                                'Kelola dan tugaskan keluhan warga kepada satpam yang bertugas.',
                                style: GoogleFonts.inter(
                                    fontSize: 13, color: AppColors.textGrey),
                              ),

                              const SizedBox(height: 24),

                              // ── Stat cards ───────────────────────────────
                              StatCardsRow(
                                total    : _all.length,
                                menunggu : _cntMenunggu,
                                diproses : _cntDiproses,
                                selesai  : _cntSelesai,
                              ),

                              const SizedBox(height: 24),

                              // ── Table card ───────────────────────────────
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  children: [
                                    ReportsTabBar(
                                      activeTab: _activeTab,
                                      tabs: _tabs,
                                      counts: {
                                        'Semua'    : _all.length,
                                        'Menunggu' : _cntMenunggu,
                                        'Diproses' : _cntDiproses,
                                      },
                                      onTabChanged: (t) => setState(() {
                                        _activeTab    = t;
                                        _selected     = null;
                                        _currentPage  = 1;
                                      }),
                                    ),
                                    ReportTable(
                                      reports      : _pageItems,
                                      selectedId   : _selected?.id,
                                      onRowTap     : (r) async {
                                        setState(() => _selected = r);
                                        await showReportDetailDialog(
                                          context,
                                          initialReport: r,
                                        );
                                        if (mounted) {
                                          setState(() => _selected = null);
                                        }
                                      },
                                    ),
                                    ReportPaginationBar(
                                      currentPage  : _currentPage.clamp(1, _totalPages),
                                      totalItems   : _filtered.length,
                                      perPage      : _perPage,
                                      onPageChanged: (p) => setState(() => _currentPage = p),
                                    ),
                                  ],
                                ),
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
