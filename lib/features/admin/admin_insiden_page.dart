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

class _InsidenModel {
  _InsidenModel({
    required this.id,
    required this.namaSatpam,
    required this.kategori,
    required this.blok,
    required this.nomor,
    required this.detailLokasi,
    required this.deskripsi,
    required this.waktuKejadian,
    required this.status,
    required this.createdAt,
  });

  final String    id;
  final String    namaSatpam;
  final String    kategori;
  final String    blok;
  final String    nomor;
  final String    detailLokasi;
  final String    deskripsi;
  final DateTime  waktuKejadian;
  final String    status;
  final DateTime? createdAt;

  String get lokasiLabel => '$blok No. $nomor${detailLokasi.isNotEmpty ? ' · $detailLokasi' : ''}';

  factory _InsidenModel.fromFirestore(String id, Map<String, dynamic> d) {
    DateTime toDate(dynamic ts) {
      if (ts is Timestamp) return ts.toDate();
      return DateTime.now();
    }

    return _InsidenModel(
      id           : id,
      namaSatpam   : d['namaSatpam']    as String? ?? '-',
      kategori     : d['kategori']      as String? ?? 'Insiden',
      blok         : d['blok']          as String? ?? '-',
      nomor        : d['nomor']         as String? ?? '-',
      detailLokasi : d['detailLokasi']  as String? ?? '',
      deskripsi    : d['deskripsi']     as String? ?? '',
      waktuKejadian: toDate(d['waktuKejadian']),
      status       : d['status']        as String? ?? 'BARU',
      createdAt    : d['createdAt'] != null ? toDate(d['createdAt']) : null,
    );
  }
}

// Status
const _statusOptions = ['BARU', 'DITANGANI', 'SELESAI'];

// ─────────────────────────────────────────────────────────────────────────────
// Page
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

  List<_InsidenModel> _allInsiden = [];
  StreamSubscription<QuerySnapshot>? _sub;

  static const _filterOptions = ['Semua', 'BARU', 'DITANGANI', 'SELESAI'];

  // ── Derived ───────────────────────────────────────────────────────────────
  List<_InsidenModel> get _filtered {
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
            .map((d) => _InsidenModel.fromFirestore(
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

  // ── Detail dialog ─────────────────────────────────────────────────────────
  void _showDetail(BuildContext context, _InsidenModel insiden) {
    String currentStatus = insiden.status;
    bool   saving        = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _statusBg(insiden.status),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.warning_amber_rounded,
                    color: _statusColor(insiden.status), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insiden.kategori,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      'Laporan Insiden',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textGrey),
                    ),
                  ],
                ),
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

                  // Info rows
                  _DetailRow(label: 'Dilaporkan oleh', value: insiden.namaSatpam),
                  const SizedBox(height: 10),
                  _DetailRow(label: 'Lokasi', value: insiden.lokasiLabel),
                  const SizedBox(height: 10),
                  _DetailRow(
                    label: 'Waktu Kejadian',
                    value: DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
                        .format(insiden.waktuKejadian),
                  ),
                  const SizedBox(height: 10),
                  _DetailRow(
                    label: 'Dilaporkan',
                    value: insiden.createdAt != null
                        ? DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
                            .format(insiden.createdAt!)
                        : '-',
                  ),
                  const SizedBox(height: 16),

                  // Deskripsi
                  Text(
                    'Deskripsi',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textGrey),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      insiden.deskripsi.isNotEmpty
                          ? insiden.deskripsi
                          : '-',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textDark,
                          height: 1.5),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Update status
                  Text(
                    'Update Status',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textGrey),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _statusOptions.map((s) {
                      final isActive = s == currentStatus;
                      return GestureDetector(
                        onTap: saving ? null : () => setS(() => currentStatus = s),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isActive
                                ? _statusColor(s).withValues(alpha: 0.12)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isActive
                                  ? _statusColor(s)
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            s,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: isActive
                                  ? FontWeight.bold
                                  : FontWeight.w400,
                              color: isActive
                                  ? _statusColor(s)
                                  : AppColors.textGrey,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: Text('Tutup',
                  style: GoogleFonts.inter(color: AppColors.textGrey)),
            ),
            ElevatedButton(
              onPressed: (saving || currentStatus == insiden.status)
                  ? null
                  : () async {
                      setS(() => saving = true);
                      try {
                        await _updateStatus(insiden.id, currentStatus);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Status diperbarui ke $currentStatus')),
                          );
                        }
                      } catch (_) {
                        setS(() => saving = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Gagal memperbarui status')),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text('Simpan',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
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
                            _StatCard(
                              label: 'TOTAL',
                              value: _loading ? '...' : '${_allInsiden.length}',
                              color: AppColors.textDark,
                            ),
                            const SizedBox(width: 10),
                            _StatCard(
                              label: 'BARU',
                              value: _loading ? '...' : '$_countBaru',
                              color: const Color(0xFFDC2626),
                            ),
                            const SizedBox(width: 10),
                            _StatCard(
                              label: 'DITANGANI',
                              value: _loading ? '...' : '$_countDitangani',
                              color: const Color(0xFFD97706),
                            ),
                            const SizedBox(width: 10),
                            _StatCard(
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
                            onChanged: (v) =>
                                setState(() => _searchQuery = v),
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
                              _FilterBar(
                                options: _filterOptions,
                                selected: _filterStatus,
                                onSelect: (s) =>
                                    setState(() => _filterStatus = s),
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
                              else
                                _InsidenTable(
                                  items: _filtered,
                                  onDetail: (i) =>
                                      _showDetail(context, i),
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
// Status helpers
// ─────────────────────────────────────────────────────────────────────────────

Color _statusColor(String status) {
  switch (status) {
    case 'BARU':       return const Color(0xFFDC2626);
    case 'DITANGANI':  return const Color(0xFFD97706);
    case 'SELESAI':    return const Color(0xFF16A34A);
    default:           return AppColors.textGrey;
  }
}

Color _statusBg(String status) {
  switch (status) {
    case 'BARU':       return const Color(0xFFFEF2F2);
    case 'DITANGANI':  return const Color(0xFFFFFBEB);
    case 'SELESAI':    return const Color(0xFFF0FDF4);
    default:           return Colors.grey.shade100;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat card
// ─────────────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color  color;

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
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textGrey,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter bar
// ─────────────────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.options,
    required this.selected,
    required this.onSelect,
  });
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          Text(
            'Status:',
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textGrey),
          ),
          const SizedBox(width: 12),
          Wrap(
            spacing: 8,
            children: options.map((opt) {
              final isActive = opt == selected;
              final color = opt == 'Semua'
                  ? AppColors.primary
                  : _statusColor(opt);
              return GestureDetector(
                onTap: () => onSelect(opt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isActive ? color.withValues(alpha: 0.12) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive ? color : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    opt,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isActive ? color : const Color(0xFF374151),
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

class _InsidenTable extends StatelessWidget {
  const _InsidenTable({required this.items, required this.onDetail});
  final List<_InsidenModel> items;
  final ValueChanged<_InsidenModel> onDetail;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          color: const Color(0xFFF8FAFC),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Expanded(flex: 3, child: _th('Kategori')),
              Expanded(flex: 3, child: _th('Lokasi')),
              Expanded(flex: 2, child: _th('Satpam')),
              Expanded(flex: 2, child: _th('Waktu Kejadian')),
              Expanded(flex: 2, child: _th('Status')),
              const SizedBox(width: 80, child: _ThText('Aksi')),
            ],
          ),
        ),
        // Rows
        ...items.map((i) => _InsidenRow(item: i, onDetail: () => onDetail(i))),
      ],
    );
  }

  Widget _th(String t) => _ThText(t);
}

class _ThText extends StatelessWidget {
  const _ThText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textGrey,
          letterSpacing: 0.4),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Row
// ─────────────────────────────────────────────────────────────────────────────

class _InsidenRow extends StatelessWidget {
  const _InsidenRow({required this.item, required this.onDetail});
  final _InsidenModel item;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('dd MMM, HH:mm', 'id_ID')
        .format(item.waktuKejadian);

    return Container(
      decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade100))),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // Kategori
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _statusBg(item.status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.warning_amber_rounded,
                      color: _statusColor(item.status), size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.kategori,
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

          // Lokasi
          Expanded(
            flex: 3,
            child: Text(
              item.lokasiLabel,
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textDark),
              overflow: TextOverflow.ellipsis,
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

          // Waktu
          Expanded(
            flex: 2,
            child: Text(
              timeStr,
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textGrey),
            ),
          ),

          // Status badge
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _statusBg(item.status),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                item.status,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _statusColor(item.status),
                ),
              ),
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
// Detail row helper
// ─────────────────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.textGrey),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark),
          ),
        ),
      ],
    );
  }
}
