import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/admin_top_bar.dart';
import '../data/admin_repository.dart';
import 'models/insiden_model.dart';
import 'widgets/insiden_shared_widgets.dart';
import 'widgets/insiden_table.dart';
import 'widgets/insiden_detail_dialog.dart';
import 'widgets/insiden_pagination_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Halaman Laporan Insiden — daftar + statistik + dialog detail/update status.
//
// Model (InsidenModel) dan widget pendukung (stat card, filter, tabel,
// dialog detail, helper warna status) dipecah ke models/ dan widgets/ agar
// file ini fokus pada state management saja.
// ─────────────────────────────────────────────────────────────────────────────

class AdminInsidenPage extends StatefulWidget {
  const AdminInsidenPage({super.key});

  @override
  State<AdminInsidenPage> createState() => _AdminInsidenPageState();
}

class _AdminInsidenPageState extends State<AdminInsidenPage> {
  String _filterStatus = 'Semua';
  String _searchQuery  = '';
  bool   _loading      = true;

  List<InsidenModel> _allInsiden = [];
  StreamSubscription<QuerySnapshot>? _sub;

  static const _filterOptions = ['Semua', 'BARU', 'DITANGANI', 'SELESAI'];

  // ── Pagination ───────────────────────────────────────────────────────────
  static const _perPage = 10;
  int _currentPage = 1;

  // ── Derived ───────────────────────────────────────────────────────────────
  List<InsidenModel> get _filtered {
    final q = _searchQuery.toLowerCase();
    return _allInsiden.where((i) {
      final matchStatus = _filterStatus == 'Semua' || i.status == _filterStatus;
      final matchSearch = q.isEmpty ||
          i.namaSatpam.toLowerCase().contains(q) ||
          i.kategori.toLowerCase().contains(q) ||
          i.blok.toLowerCase().contains(q) ||
          i.deskripsi.toLowerCase().contains(q);
      return matchStatus && matchSearch;
    }).toList();
  }

  int get _totalPages => (_filtered.length / _perPage).ceil().clamp(1, 9999);

  List<InsidenModel> get _pageItems {
    final page  = _currentPage.clamp(1, _totalPages);
    final start = (page - 1) * _perPage;
    final end   = (start + _perPage).clamp(0, _filtered.length);
    return _filtered.sublist(start, end);
  }

  int get _countBaru      => _allInsiden.where((i) => i.status == 'BARU').length;
  int get _countDitangani => _allInsiden.where((i) => i.status == 'DITANGANI').length;
  int get _countSelesai   => _allInsiden.where((i) => i.status == 'SELESAI').length;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    _sub = AdminRepository.instance.insidenStream().listen((snap) {
      if (!mounted) return;
      setState(() {
        _allInsiden = snap.docs
            .map((d) => InsidenModel.fromFirestore(
                  d.id,
                  d.data(),
                ))
            .toList();
        _loading = false;
      });
    }, onError: (_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // ── Update status ─────────────────────────────────────────────────────────
  Future<void> _updateStatus(String id, String newStatus) async {
    await AdminRepository.instance.updateInsidenStatus(id, newStatus);
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          const AdminSidebar(activePage: AdminPage.insiden),

          Expanded(
            child: Column(
              children: [
                const AdminTopBar(searchHint: 'Search insiden, lokasi, satpam...'),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Header + stat cards ──────────────────────────
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Laporan Insiden',
                                    style: GoogleFonts.inter(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Monitor dan tangani laporan insiden dari satpam.',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppColors.textGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            InsidenStatCard(
                              label: 'TOTAL',
                              value: _loading ? '...' : '${_allInsiden.length}',
                              color: AppColors.textDark,
                            ),
                            const SizedBox(width: 10),
                            InsidenStatCard(
                              label: 'BARU',
                              value: _loading ? '...' : '$_countBaru',
                              color: const Color(0xFFDC2626),
                            ),
                            const SizedBox(width: 10),
                            InsidenStatCard(
                              label: 'DITANGANI',
                              value: _loading ? '...' : '$_countDitangani',
                              color: const Color(0xFFD97706),
                            ),
                            const SizedBox(width: 10),
                            InsidenStatCard(
                              label: 'SELESAI',
                              value: _loading ? '...' : '$_countSelesai',
                              color: const Color(0xFF16A34A),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // ── Search ───────────────────────────────────────
                        Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: TextField(
                            onChanged: (v) => setState(() {
                              _searchQuery = v;
                              _currentPage = 1;
                            }),
                            style: GoogleFonts.inter(
                                fontSize: 13, color: AppColors.textDark),
                            decoration: InputDecoration(
                              hintText:
                                  'Cari kategori, satpam, lokasi, atau deskripsi...',
                              hintStyle: GoogleFonts.inter(
                                  fontSize: 13, color: AppColors.textGrey),
                              prefixIcon: const Icon(Icons.search,
                                  size: 18, color: AppColors.textGrey),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 13),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Table card ───────────────────────────────────
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Filter chips
                              InsidenFilterBar(
                                options: _filterOptions,
                                selected: _filterStatus,
                                onSelect: (s) => setState(() {
                                  _filterStatus = s;
                                  _currentPage  = 1;
                                }),
                              ),

                              // Content
                              if (_loading)
                                const Padding(
                                  padding: EdgeInsets.all(48),
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                )
                              else if (_filtered.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(48),
                                  child: Center(
                                    child: Text(
                                      'Tidak ada laporan insiden.',
                                      style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: AppColors.textGrey),
                                    ),
                                  ),
                                )
                              else ...[
                                InsidenTable(
                                  items: _pageItems,
                                  onDetail: (i) => showInsidenDetailDialog(
                                    context,
                                    i,
                                    onUpdateStatus: _updateStatus,
                                  ),
                                ),
                                InsidenPaginationBar(
                                  currentPage: _currentPage.clamp(1, _totalPages),
                                  totalItems: _filtered.length,
                                  perPage: _perPage,
                                  onPageChanged: (p) =>
                                      setState(() => _currentPage = p),
                                ),
                              ],
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
