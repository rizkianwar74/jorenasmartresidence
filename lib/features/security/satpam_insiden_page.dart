import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import 'data/security_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────
class _InsidenItem {
  _InsidenItem({
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

  final String   id;
  final String   namaSatpam;
  final String   kategori;
  final String   blok;
  final String   nomor;
  final String   detailLokasi;
  final String   deskripsi;
  final DateTime waktuKejadian;
  final String   status;
  final DateTime createdAt;

  String get lokasiLabel =>
      '$blok No. $nomor${detailLokasi.isNotEmpty ? ' · $detailLokasi' : ''}';

  factory _InsidenItem.fromDoc(QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    DateTime toDate(dynamic ts) =>
        ts is Timestamp ? ts.toDate() : DateTime.now();
    return _InsidenItem(
      id           : doc.id,
      namaSatpam   : d['namaSatpam']   as String? ?? '-',
      kategori     : d['kategori']     as String? ?? 'Insiden',
      blok         : d['blok']         as String? ?? '-',
      nomor        : d['nomor']        as String? ?? '-',
      detailLokasi : d['detailLokasi'] as String? ?? '',
      deskripsi    : d['deskripsi']    as String? ?? '',
      waktuKejadian: toDate(d['waktuKejadian']),
      status       : d['status']       as String? ?? 'BARU',
      createdAt    : toDate(d['createdAt']),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────
class SatpamInsidenPage extends StatefulWidget {
  const SatpamInsidenPage({super.key});

  @override
  State<SatpamInsidenPage> createState() => _SatpamInsidenPageState();
}

class _SatpamInsidenPageState extends State<SatpamInsidenPage> {
  StreamSubscription<QuerySnapshot>? _sub;
  List<_InsidenItem> _all  = [];
  bool _loading            = true;
  String _filterStatus     = 'Semua';

  static const _statusOptions = ['Semua', 'BARU', 'DITANGANI', 'SELESAI'];

  List<_InsidenItem> get _filtered => _filterStatus == 'Semua'
      ? _all
      : _all.where((i) => i.status == _filterStatus).toList();

  @override
  void initState() {
    super.initState();
    _sub = SecurityRepository.instance.insidenStream().listen(
      (snap) {
        if (!mounted) return;
        setState(() {
          _all = snap.docs.map(_InsidenItem.fromDoc).toList();
          _loading = false;
        });
      },
      onError: (_) {
        if (mounted) setState(() => _loading = false);
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // ── Update status dengan bottom sheet konfirmasi ──────────────────────────
  Future<void> _updateStatus(_InsidenItem item, String newStatus) async {
    HapticFeedback.mediumImpact();
    try {
      await SecurityRepository.instance.updateInsidenStatus(item.id, newStatus);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal update: $e')),
      );
    }
  }

  void _showDetail(_InsidenItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InsidenDetailSheet(
        item: item,
        onUpdateStatus: _updateStatus,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        body: SafeArea(
          child: Column(
            children: [
              // ── Top Bar ───────────────────────────────────────────────────
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 20, color: Color(0xFF0D1B2A)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Daftar Insiden',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    // Badge total
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_filtered.length}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFD32F2F),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Filter chips ─────────────────────────────────────────────
              Container(
                color: Colors.white,
                padding:
                    const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _statusOptions.map((s) {
                      final active = _filterStatus == s;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _filterStatus = s),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.primary
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              s == 'Semua'
                                  ? 'Semua (${_all.length})'
                                  : _chipLabel(s),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: active
                                    ? Colors.white
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // ── List ─────────────────────────────────────────────────────
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : _filtered.isEmpty
                        ? _EmptyState(filterStatus: _filterStatus)
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) => _InsidenCard(
                              item: _filtered[i],
                              onTap: () => _showDetail(_filtered[i]),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _chipLabel(String status) {
    final count =
        _all.where((i) => i.status == status).length;
    return '$status ($count)';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card item
// ─────────────────────────────────────────────────────────────────────────────
class _InsidenCard extends StatelessWidget {
  const _InsidenCard({required this.item, required this.onTap});
  final _InsidenItem  item;
  final VoidCallback  onTap;

  static const _statusColor = {
    'BARU'      : Color(0xFFD32F2F),
    'DITANGANI' : Color(0xFFE65100),
    'SELESAI'   : Color(0xFF2E7D32),
  };
  static const _statusBg = {
    'BARU'      : Color(0xFFFFEBEE),
    'DITANGANI' : Color(0xFFFFF3E0),
    'SELESAI'   : Color(0xFFE8F5E9),
  };
  static const _statusIcon = {
    'BARU'      : Icons.warning_amber_rounded,
    'DITANGANI' : Icons.directions_run_rounded,
    'SELESAI'   : Icons.check_circle_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final sc = _statusColor[item.status] ?? AppColors.primary;
    final sb = _statusBg[item.status]    ?? const Color(0xFFE3F0FF);
    final si = _statusIcon[item.status]  ?? Icons.info_outline;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  // Icon kategori
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: sb,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(si, color: sc, size: 22),
                  ),
                  const SizedBox(width: 12),
                  // Kategori + lokasi
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.kategori,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 12,
                                color: AppColors.textGrey),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                item.lokasiLabel,
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.textGrey),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: sb,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.status,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: sc,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Divider ─────────────────────────────────────────────────
            Divider(height: 1, indent: 16, color: Colors.grey.shade100),

            // ── Footer: satpam + waktu ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined,
                      size: 13, color: AppColors.textGrey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.namaSatpam,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textGrey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    DateFormat('dd MMM, HH:mm', 'id_ID')
                        .format(item.waktuKejadian),
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.textGrey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail bottom sheet
// ─────────────────────────────────────────────────────────────────────────────
class _InsidenDetailSheet extends StatelessWidget {
  const _InsidenDetailSheet({
    required this.item,
    required this.onUpdateStatus,
  });
  final _InsidenItem  item;
  final Future<void> Function(_InsidenItem, String) onUpdateStatus;

  static const _statusFlow = {
    'BARU'      : 'DITANGANI',
    'DITANGANI' : 'SELESAI',
  };

  static const _statusColor = {
    'BARU'      : Color(0xFFD32F2F),
    'DITANGANI' : Color(0xFFE65100),
    'SELESAI'   : Color(0xFF2E7D32),
  };
  static const _statusBg = {
    'BARU'      : Color(0xFFFFEBEE),
    'DITANGANI' : Color(0xFFFFF3E0),
    'SELESAI'   : Color(0xFFE8F5E9),
  };

  @override
  Widget build(BuildContext context) {
    final nextStatus = _statusFlow[item.status];
    final sc  = _statusColor[item.status] ?? AppColors.primary;
    final sb  = _statusBg[item.status]    ?? const Color(0xFFE3F0FF);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Header ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.kategori,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: sb,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.status,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: sc,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Info rows ───────────────────────────────────────────────
            _InfoSection(children: [
              _InfoRow(
                icon  : Icons.location_on_outlined,
                label : 'Lokasi',
                value : item.lokasiLabel,
              ),
              _InfoRow(
                icon  : Icons.shield_outlined,
                label : 'Dilaporkan oleh',
                value : item.namaSatpam,
              ),
              _InfoRow(
                icon  : Icons.access_time_rounded,
                label : 'Waktu kejadian',
                value : DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
                    .format(item.waktuKejadian),
              ),
              _InfoRow(
                icon  : Icons.upload_file_outlined,
                label : 'Dilaporkan pada',
                value : DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
                    .format(item.createdAt),
              ),
            ]),

            // ── Deskripsi ───────────────────────────────────────────────
            if (item.deskripsi.isNotEmpty) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Deskripsi',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.deskripsi,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textDark,
                        height: 1.6),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ── Tombol update status ─────────────────────────────────────
            if (nextStatus != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: Icon(
                      nextStatus == 'DITANGANI'
                          ? Icons.directions_run_rounded
                          : Icons.check_circle_rounded,
                      size: 18,
                    ),
                    label: Text(
                      nextStatus == 'DITANGANI'
                          ? 'Tandai Sedang Ditangani'
                          : 'Tandai Selesai',
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: nextStatus == 'DITANGANI'
                          ? const Color(0xFFE65100)
                          : const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      await onUpdateStatus(item, nextStatus);
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable widgets
// ─────────────────────────────────────────────────────────────────────────────
class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: List.generate(children.length, (i) => Column(
            children: [
              children[i],
              if (i < children.length - 1)
                Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: Colors.grey.shade200),
            ],
          )),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String   label;
  final String   value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textGrey),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.textGrey),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filterStatus});
  final String filterStatus;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            filterStatus == 'Semua'
                ? 'Belum ada insiden'
                : 'Tidak ada insiden $filterStatus',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Data akan muncul otomatis saat ada insiden baru',
            style: GoogleFonts.inter(
                fontSize: 12, color: const Color(0xFFB0BEC5)),
          ),
        ],
      ),
    );
  }
}
