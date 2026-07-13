import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/admin_top_bar.dart';
import '../data/admin_repository.dart';
import 'models/tamu_model.dart';
import 'widgets/tamu_shared_widgets.dart';
import 'widgets/tamu_table.dart';
import 'widgets/tamu_detail_dialog.dart';
import 'widgets/tamu_pagination_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Halaman Daftar Tamu — daftar kunjungan tamu + statistik + pagination.
//
// Model (TamuModel) dan widget pendukung (stat card, filter, tabel, dialog
// detail, pagination) dipecah ke models/ dan widgets/ agar file ini fokus
// pada state management saja.
// ─────────────────────────────────────────────────────────────────────────────

const _pageSize = 12;

class AdminDaftarTamuPage extends StatefulWidget {
  const AdminDaftarTamuPage({super.key});

  @override
  State<AdminDaftarTamuPage> createState() => _AdminDaftarTamuPageState();
}

class _AdminDaftarTamuPageState extends State<AdminDaftarTamuPage> {
  String _filterStatus = 'Semua';
  String _searchQuery  = '';
  int    _currentPage  = 1;
  bool   _loading      = true;

  List<TamuModel> _allTamu = [];
  StreamSubscription<QuerySnapshot>? _sub;

  static const _filterOptions = ['Semua', 'MASUK', 'KELUAR'];

  // ── Derived ───────────────────────────────────────────────────────────────
  List<TamuModel> get _filtered {
    final q = _searchQuery.toLowerCase();
    return _allTamu.where((t) {
      final matchStatus = _filterStatus == 'Semua' || t.status == _filterStatus;
      final matchSearch = q.isEmpty ||
          t.namaTamu.toLowerCase().contains(q) ||
          t.blokTujuan.toLowerCase().contains(q) ||
          t.nomorRumahTujuan.contains(q) ||
          t.kategoriKunjungan.toLowerCase().contains(q) ||
          t.namaSatpam.toLowerCase().contains(q);
      return matchStatus && matchSearch;
    }).toList();
  }

  List<TamuModel> get _paginated {
    final start = (_currentPage - 1) * _pageSize;
    final end   = (start + _pageSize).clamp(0, _filtered.length);
    if (start >= _filtered.length) return [];
    return _filtered.sublist(start, end);
  }

  int get _totalPages => (_filtered.length / _pageSize).ceil().clamp(1, 9999);

  // Stat
  int get _countMasuk {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    return _allTamu
        .where((t) => t.status == 'MASUK' && (t.createdAt ?? t.waktuMasuk).isAfter(start))
        .length;
  }
  int get _countKeluar => _allTamu.where((t) => t.status == 'KELUAR').length;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    _sub = AdminRepository.instance.tamuStream().listen((snap) {
      if (!mounted) return;
      setState(() {
        _allTamu = snap.docs
            .map((d) => TamuModel.fromFirestore(
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

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          const AdminSidebar(activePage: AdminPage.daftarTamu),

          Expanded(
            child: Column(
              children: [
                const AdminTopBar(searchHint: 'Cari tamu, blok, atau satpam...'),

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
                                    'Daftar Tamu',
                                    style: GoogleFonts.inter(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Monitor kunjungan tamu yang masuk ke residence.',
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: AppColors.textGrey),
                                  ),
                                ],
                              ),
                            ),
                            TamuStatCard(
                              label: 'TOTAL',
                              value: _loading ? '...' : '${_allTamu.length}',
                              color: AppColors.textDark,
                            ),
                            const SizedBox(width: 10),
                            TamuStatCard(
                              label: 'MASUK HARI INI',
                              value: _loading ? '...' : '$_countMasuk',
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            TamuStatCard(
                              label: 'SUDAH KELUAR',
                              value: _loading ? '...' : '$_countKeluar',
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
                                  'Cari nama tamu, blok tujuan, kategori, atau satpam...',
                              hintStyle: GoogleFonts.inter(
                                  fontSize: 13, color: AppColors.textGrey),
                              prefixIcon: const Icon(Icons.search,
                                  size: 18, color: AppColors.textGrey),
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 13),
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
                              // Filter
                              TamuFilterBar(
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
                              else if (_paginated.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(48),
                                  child: Center(
                                    child: Text(
                                      'Tidak ada data tamu.',
                                      style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: AppColors.textGrey),
                                    ),
                                  ),
                                )
                              else
                                TamuTable(
                                  items: _paginated,
                                  onDetail: (t) =>
                                      showTamuDetailDialog(context, t),
                                ),

                              // Pagination
                              if (!_loading && _filtered.isNotEmpty)
                                TamuPaginationBar(
                                  currentPage : _currentPage,
                                  totalPages  : _totalPages,
                                  totalItems  : _filtered.length,
                                  pageSize    : _pageSize,
                                  onPageChanged: (p) =>
                                      setState(() => _currentPage = p),
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
