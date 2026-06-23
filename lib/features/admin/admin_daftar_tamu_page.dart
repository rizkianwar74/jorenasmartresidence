import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_top_bar.dart';
import 'data/admin_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

class _TamuModel {
  _TamuModel({
    required this.id,
    required this.namaTamu,
    required this.jenisKendaraan,
    required this.nomorPlat,
    required this.kategoriKunjungan,
    required this.keterangan,
    required this.blokTujuan,
    required this.nomorRumahTujuan,
    required this.namaSatpam,
    required this.status,
    required this.waktuMasuk,
    this.waktuKeluar,
    this.createdAt,
  });

  final String    id;
  final String    namaTamu;
  final String    jenisKendaraan;
  final String    nomorPlat;
  final String    kategoriKunjungan;
  final String    keterangan;
  final String    blokTujuan;
  final String    nomorRumahTujuan;
  final String    namaSatpam;
  final String    status;
  final DateTime  waktuMasuk;
  final DateTime? waktuKeluar;
  final DateTime? createdAt;

  String get tujuanLabel => '$blokTujuan No. $nomorRumahTujuan';

  static DateTime _toDate(dynamic ts) =>
      ts is Timestamp ? ts.toDate() : DateTime.now();

  factory _TamuModel.fromFirestore(String id, Map<String, dynamic> d) {
    return _TamuModel(
      id                 : id,
      namaTamu           : d['namaTamu']           as String? ?? '-',
      jenisKendaraan     : d['jenisKendaraan']     as String? ?? '-',
      nomorPlat          : d['nomorPlat']          as String? ?? '-',
      kategoriKunjungan  : d['kategoriKunjungan']  as String? ?? '-',
      keterangan         : d['keterangan']         as String? ?? '',
      blokTujuan         : d['blokTujuan']         as String? ?? '-',
      nomorRumahTujuan   : d['nomorRumahTujuan']   as String? ?? '-',
      namaSatpam         : d['namaSatpam']         as String? ?? '-',
      status             : d['status']             as String? ?? 'MASUK',
      waktuMasuk         : _toDate(d['waktuMasuk']),
      waktuKeluar        : d['waktuKeluar'] != null ? _toDate(d['waktuKeluar']) : null,
      createdAt          : d['createdAt'] != null  ? _toDate(d['createdAt'])  : null,
    );
  }
}

const _pageSize = 12;

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

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

  List<_TamuModel> _allTamu = [];
  StreamSubscription<QuerySnapshot>? _sub;

  static const _filterOptions = ['Semua', 'MASUK', 'KELUAR'];

  // ── Derived ───────────────────────────────────────────────────────────────
  List<_TamuModel> get _filtered {
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

  List<_TamuModel> get _paginated {
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
            .map((d) => _TamuModel.fromFirestore(
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

  // ── Detail dialog ─────────────────────────────────────────────────────────
  void _showDetail(BuildContext context, _TamuModel t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.namaTamu,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Text(
                t.kategoriKunjungan,
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textGrey),
              ),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(height: 24),

                  // ── Info tamu ────────────────────────────────────────
                  _SectionLabel('Informasi Tamu'),
                  const SizedBox(height: 10),
                  _DetailRow(label: 'Nama Tamu',       value: t.namaTamu),
                  _DetailRow(label: 'Kategori',         value: t.kategoriKunjungan),
                  _DetailRow(label: 'Kendaraan',        value: '${t.jenisKendaraan} · ${t.nomorPlat.isEmpty ? "Tidak ada" : t.nomorPlat}'),
                  if (t.keterangan.isNotEmpty)
                    _DetailRow(label: 'Keterangan', value: t.keterangan),

                  const SizedBox(height: 16),

                  // ── Tujuan ───────────────────────────────────────────
                  _SectionLabel('Tujuan Kunjungan'),
                  const SizedBox(height: 10),
                  _DetailRow(label: 'Blok',          value: t.blokTujuan),
                  _DetailRow(label: 'Nomor Rumah',   value: t.nomorRumahTujuan),

                  const SizedBox(height: 16),

                  // ── Waktu ────────────────────────────────────────────
                  _SectionLabel('Catatan Waktu'),
                  const SizedBox(height: 10),
                  _DetailRow(
                    label: 'Waktu Masuk',
                    value: DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
                        .format(t.waktuMasuk),
                  ),
                  _DetailRow(
                    label: 'Waktu Keluar',
                    value: t.waktuKeluar != null
                        ? DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
                            .format(t.waktuKeluar!)
                        : '— Belum keluar',
                    valueColor: t.waktuKeluar == null
                        ? AppColors.textGrey
                        : null,
                  ),

                  const SizedBox(height: 16),

                  // ── Petugas ──────────────────────────────────────────
                  _SectionLabel('Petugas'),
                  const SizedBox(height: 10),
                  _DetailRow(label: 'Dicatat oleh', value: t.namaSatpam),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Tutup',
                  style: GoogleFonts.inter(color: AppColors.textGrey)),
            ),
          ],
        ),
    );
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
                            _StatCard(
                              label: 'TOTAL',
                              value: _loading ? '...' : '${_allTamu.length}',
                              color: AppColors.textDark,
                            ),
                            const SizedBox(width: 10),
                            _StatCard(
                              label: 'MASUK HARI INI',
                              value: _loading ? '...' : '$_countMasuk',
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            _StatCard(
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
                              _FilterBar(
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
                                _TamuTable(
                                  items: _paginated,
                                  onDetail: (t) => _showDetail(context, t),
                                ),

                              // Pagination
                              if (!_loading && _filtered.isNotEmpty)
                                _PaginationBar(
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

// ─────────────────────────────────────────────────────────────────────────────
// Stat card
// ─────────────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textGrey,
                  letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter bar
// ─────────────────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar(
      {required this.options, required this.selected, required this.onSelect});
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;

  Color _color(String opt) {
    if (opt == 'MASUK')  return AppColors.primary;
    if (opt == 'KELUAR') return const Color(0xFF16A34A);
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          Text('Status:',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textGrey)),
          const SizedBox(width: 12),
          Wrap(
            spacing: 8,
            children: options.map((opt) {
              final isActive = opt == selected;
              final col = _color(opt);
              return GestureDetector(
                onTap: () => onSelect(opt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color:
                        isActive ? col.withValues(alpha: 0.12) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: isActive ? col : Colors.grey.shade300),
                  ),
                  child: Text(
                    opt,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isActive ? col : const Color(0xFF374151),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Table
// ─────────────────────────────────────────────────────────────────────────────

class _TamuTable extends StatelessWidget {
  const _TamuTable({required this.items, required this.onDetail});
  final List<_TamuModel> items;
  final ValueChanged<_TamuModel> onDetail;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          color: const Color(0xFFF8FAFC),
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: const Row(
            children: [
              Expanded(flex: 3, child: _Th('Nama Tamu')),
              Expanded(flex: 2, child: _Th('Tujuan')),
              Expanded(flex: 2, child: _Th('Kategori')),
              Expanded(flex: 2, child: _Th('Kendaraan')),
              Expanded(flex: 2, child: _Th('Satpam')),
              Expanded(flex: 2, child: _Th('Waktu Masuk')),
              SizedBox(width: 80, child: _Th('Aksi')),
            ],
          ),
        ),
        // Rows
        ...items.map(
          (t) => _TamuRow(item: t, onDetail: () => onDetail(t)),
        ),
      ],
    );
  }
}

class _Th extends StatelessWidget {
  const _Th(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textGrey,
            letterSpacing: 0.4));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Row
// ─────────────────────────────────────────────────────────────────────────────

class _TamuRow extends StatelessWidget {
  const _TamuRow({required this.item, required this.onDetail});
  final _TamuModel item;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    final waktu =
        DateFormat('dd MMM, HH:mm', 'id_ID').format(item.waktuMasuk);

    return Container(
      decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade100))),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // Nama Tamu
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    item.namaTamu.isNotEmpty
                        ? item.namaTamu[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.namaTamu,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Tujuan
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                item.tujuanLabel,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Kategori
          Expanded(
            flex: 2,
            child: Text(
              item.kategoriKunjungan,
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textGrey),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Kendaraan
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.jenisKendaraan,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textDark),
                ),
                if (item.nomorPlat.isNotEmpty && item.nomorPlat != '-')
                  Text(
                    item.nomorPlat,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.textGrey),
                  ),
              ],
            ),
          ),

          // Satpam
          Expanded(
            flex: 2,
            child: Text(
              item.namaSatpam,
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textGrey),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Waktu Masuk
          Expanded(
            flex: 2,
            child: Text(
              waktu,
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textGrey),
            ),
          ),

          // Aksi
          SizedBox(
            width: 80,
            child: OutlinedButton(
              onPressed: onDetail,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                foregroundColor: AppColors.textDark,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Detail',
                  style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail dialog helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          letterSpacing: 0.5),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(
      {required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textGrey)),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: valueColor ?? AppColors.textDark,
              ),
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
    required this.totalPages,
    required this.totalItems,
    required this.pageSize,
    required this.onPageChanged,
  });
  final int currentPage, totalPages, totalItems, pageSize;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final start = totalItems == 0 ? 0 : (currentPage - 1) * pageSize + 1;
    final end   = (currentPage * pageSize).clamp(0, totalItems);

    return Container(
      decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade100))),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Text('Menampilkan $start–$end dari $totalItems tamu',
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textGrey)),
          const Spacer(),
          _PageBtn('<', currentPage > 1,
              () => onPageChanged(currentPage - 1)),
          const SizedBox(width: 4),
          ..._pages(),
          const SizedBox(width: 4),
          _PageBtn('>', currentPage < totalPages,
              () => onPageChanged(currentPage + 1)),
        ],
      ),
    );
  }

  List<Widget> _pages() {
    final w = <Widget>[];
    void add(int p) {
      w.add(_PageBtn('$p', true, () => onPageChanged(p),
          active: p == currentPage));
      w.add(const SizedBox(width: 4));
    }

    if (totalPages <= 5) {
      for (int i = 1; i <= totalPages; i++) add(i);
    } else {
      add(1); add(2); add(3);
      w.add(Text('...',
          style: GoogleFonts.inter(
              fontSize: 13, color: AppColors.textGrey)));
      w.add(const SizedBox(width: 4));
      add(totalPages);
    }
    return w;
  }
}

class _PageBtn extends StatelessWidget {
  const _PageBtn(this.label, this.enabled, this.onTap, {this.active = false});
  final String label;
  final bool enabled, active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active
                ? AppColors.primary
                : enabled
                    ? Colors.grey.shade300
                    : Colors.grey.shade200,
          ),
        ),
        child: Center(
          child: Text(label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: active ? FontWeight.bold : FontWeight.w500,
                color: active
                    ? Colors.white
                    : enabled
                        ? const Color(0xFF374151)
                        : Colors.grey.shade400,
              )),
        ),
      ),
    );
  }
}
