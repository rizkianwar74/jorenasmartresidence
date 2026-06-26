import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/keluhan_service.dart';
import '../../core/services/onesignal_service.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_top_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

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

  @override
  void initState() {
    super.initState();
    _sub = KeluhanService.watchAllKeluhan().listen(
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
                AdminTopBar(searchHint: 'Cari laporan atau nama warga...'),
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
                              _StatCardsRow(
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
                                    _TabBar(
                                      activeTab: _activeTab,
                                      tabs: _tabs,
                                      counts: {
                                        'Semua'    : _all.length,
                                        'Menunggu' : _cntMenunggu,
                                        'Diproses' : _cntDiproses,
                                      },
                                      onTabChanged: (t) => setState(() {
                                        _activeTab = t;
                                        _selected  = null;
                                      }),
                                    ),
                                    _ReportTable(
                                      reports      : _filtered,
                                      selectedId   : _selected?.id,
                                      onRowTap     : (r) => setState(() => _selected = r),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              // ── Detail ───────────────────────────────────
                              _DetailPanel(
                                report: _selected,
                                onAssigned: () =>
                                    setState(() => _selected = null),
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
// Stat cards (realtime)
// ─────────────────────────────────────────────────────────────────────────────
class _StatCardsRow extends StatelessWidget {
  const _StatCardsRow({
    required this.total,
    required this.menunggu,
    required this.diproses,
    required this.selesai,
  });
  final int total, menunggu, diproses, selesai;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(label: 'Total Laporan', value: '$total',
            sub: 'Semua keluhan masuk', subColor: AppColors.primary,
            icon: Icons.bar_chart_rounded, iconColor: AppColors.primary,
            accentColor: AppColors.primary)),
        const SizedBox(width: 14),
        Expanded(child: _StatCard(label: 'Menunggu', value: '$menunggu',
            sub: 'Butuh respon segera',
            subColor: const Color(0xFFF97316),
            icon: Icons.pending_actions_outlined,
            iconColor: const Color(0xFFF97316),
            accentColor: const Color(0xFFF97316))),
        const SizedBox(width: 14),
        Expanded(child: _StatCard(label: 'Diproses', value: '$diproses',
            sub: 'Sedang ditangani satpam',
            subColor: AppColors.primary,
            icon: Icons.supervised_user_circle_outlined,
            iconColor: AppColors.primary, accentColor: AppColors.primary)),
        const SizedBox(width: 14),
        Expanded(child: _StatCard(label: 'Selesai', value: '$selesai',
            sub: 'Sudah diselesaikan',
            subColor: const Color(0xFF16A34A),
            icon: Icons.check_circle_outline,
            iconColor: const Color(0xFF16A34A),
            accentColor: const Color(0xFF16A34A))),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label, required this.value, required this.sub,
    required this.subColor, required this.icon, required this.iconColor,
    required this.accentColor,
  });
  final String label, value, sub;
  final Color subColor, iconColor, accentColor;
  final IconData icon;

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
          Container(height: 4, decoration: BoxDecoration(
            color: accentColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          )),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
            Icon(icon, size: 20, color: iconColor),
          ]),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.bold, color: AppColors.textDark, height: 1)),
          const SizedBox(height: 6),
          Text(sub, style: GoogleFonts.inter(fontSize: 12, color: subColor, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab bar
// ─────────────────────────────────────────────────────────────────────────────
class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.activeTab,
    required this.tabs,
    required this.counts,
    required this.onTabChanged,
  });
  final String activeTab;
  final List<String> tabs;
  final Map<String, int> counts;
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
          ...tabs.map((tab) {
            final isActive = tab == activeTab;
            final cnt = counts[tab];
            return GestureDetector(
              onTap: () => onTabChanged(tab),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
                margin: const EdgeInsets.only(right: 22),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(
                    color: isActive ? AppColors.primary : Colors.transparent,
                    width: 2,
                  )),
                ),
                child: Row(
                  children: [
                    Text(tab, style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive ? AppColors.primary : AppColors.textGrey,
                    )),
                    if (cnt != null && cnt > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.primary : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('$cnt', style: GoogleFonts.inter(
                          fontSize: 10, fontWeight: FontWeight.bold,
                          color: isActive ? Colors.white : AppColors.textGrey,
                        )),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
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
    required this.selectedId,
    required this.onRowTap,
  });
  final List<KeluhanItem> reports;
  final String? selectedId;
  final ValueChanged<KeluhanItem> onRowTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          color: const Color(0xFFF8FAFC),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          child: Row(children: const [
            SizedBox(width: 6),
            Expanded(flex: 2, child: _ColH('PELAPOR & UNIT')),
            Expanded(flex: 2, child: _ColH('KATEGORI')),
            Expanded(flex: 3, child: _ColH('JUDUL')),
            Expanded(flex: 2, child: _ColH('TANGGAL')),
            Expanded(flex: 2, child: _ColH('DITUGASKAN KE')),
            SizedBox(width: 110, child: _ColH('STATUS')),
          ]),
        ),

        if (reports.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(child: Text('Tidak ada laporan.',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey))),
          )
        else
          ...reports.map((r) => _ReportRow(
            item       : r,
            isSelected : selectedId == r.id,
            onTap      : () => onRowTap(r),
          )),
      ],
    );
  }
}

class _ColH extends StatelessWidget {
  const _ColH(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text, style: GoogleFonts.inter(
    fontSize: 10, fontWeight: FontWeight.w700,
    color: AppColors.textGrey, letterSpacing: 0.4,
  ));
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.item, required this.isSelected, required this.onTap});
  final KeluhanItem item;
  final bool isSelected;
  final VoidCallback onTap;

  Color get _strip => switch (item.status) {
    StatusKeluhan.menunggu => const Color(0xFFF97316),
    StatusKeluhan.diproses => AppColors.primary,
    StatusKeluhan.selesai  => const Color(0xFF16A34A),
    StatusKeluhan.ditolak  => Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    final tgl = DateFormat('dd MMM yy', 'id_ID').format(item.createdAt);
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.04) : Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade100)),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: _strip),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(children: [
                    // Pelapor
                    Expanded(flex: 2, child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(item.namaWarga, style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                        Text('Blok ${item.blok} – ${item.nomorUnit}',
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textGrey)),
                      ],
                    )),
                    // Kategori
                    Expanded(flex: 2, child: _KategoriBadge(item.kategori)),
                    // Judul
                    Expanded(flex: 3, child: Text(item.judul,
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey, height: 1.4),
                        overflow: TextOverflow.ellipsis, maxLines: 2)),
                    // Tanggal
                    Expanded(flex: 2, child: Text(tgl,
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey))),
                    // Ditugaskan ke
                    Expanded(flex: 2, child: item.assignedName != null
                        ? Row(children: [
                            Icon(Icons.person_pin_outlined, size: 13, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Flexible(child: Text(item.assignedName!,
                                style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary,
                                    fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis)),
                          ])
                        : Text('—', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey))),
                    // Status
                    SizedBox(width: 110, child: _StatusBadgeRow(item.status)),
                  ]),
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
    final isInfra = label.contains('Infrastruktur');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isInfra ? const Color(0xFFEFF6FF) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isInfra ? 'Infrastruktur' : 'Manajemen',
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500,
            color: isInfra ? AppColors.primary : const Color(0xFF15803D)),
      ),
    );
  }
}

class _StatusBadgeRow extends StatelessWidget {
  const _StatusBadgeRow(this.status);
  final StatusKeluhan status;

  (Color dot, Color bg, Color fg, String label) get _style => switch (status) {
    StatusKeluhan.menunggu => (const Color(0xFFF97316), const Color(0xFFFFF7ED), const Color(0xFFF97316), 'Menunggu'),
    StatusKeluhan.diproses => (AppColors.primary,       const Color(0xFFEFF6FF), AppColors.primary,       'Diproses'),
    StatusKeluhan.selesai  => (const Color(0xFF16A34A), const Color(0xFFF0FDF4), const Color(0xFF16A34A), 'Selesai'),
    StatusKeluhan.ditolak  => (Colors.red,              const Color(0xFFFFEBEE), Colors.red,              'Ditolak'),
  };

  @override
  Widget build(BuildContext context) {
    final (dot, bg, fg, label) = _style;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 7, height: 7,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail panel
// ─────────────────────────────────────────────────────────────────────────────
class _DetailPanel extends StatefulWidget {
  const _DetailPanel({required this.report, required this.onAssigned});
  final KeluhanItem? report;
  final VoidCallback onAssigned;

  @override
  State<_DetailPanel> createState() => _DetailPanelState();
}

class _DetailPanelState extends State<_DetailPanel> {
  bool _assigning = false;

  Future<void> _showAssignDialog(KeluhanItem item) async {
    List<SatpamInfo> satpamList;
    try {
      satpamList = await KeluhanService.getSatpamList();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Gagal memuat daftar satpam: $e',
            style: GoogleFonts.inter(fontSize: 13)),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }
    if (!mounted) return;

    if (satpamList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Tidak ada satpam terdaftar. Pastikan akun satpam di Firestore memiliki field role = "satpam".',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }

    SatpamInfo? chosen;
    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text('Tugaskan ke Satpam',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pilih satpam yang akan menangani laporan ini:',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey)),
                const SizedBox(height: 12),
                ...satpamList.map((s) => RadioListTile<SatpamInfo>(
                  value: s,
                  groupValue: chosen,
                  onChanged: (v) => setSt(() => chosen = v),
                  title: Text(s.nama,
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)),
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Batal',
                  style: GoogleFonts.inter(color: AppColors.textGrey)),
            ),
            ElevatedButton(
              onPressed: chosen == null ? null : () => Navigator.pop(ctx, chosen),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Tugaskan',
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    ).then((result) async {
      if (result is SatpamInfo) {
        setState(() => _assigning = true);
        await KeluhanService.assignKeluhan(
          keluhanId  : item.id,
          satpamUid  : result.uid,
          satpamNama : result.nama,
        );
        // Notifikasi ke satpam yang ditugaskan (fire-and-forget).
        OneSignalService.instance.sendKeluhanAssigned(
          satpamUid : result.uid,
          namaWarga : item.namaWarga,
          judul     : item.judul,
        );
        if (mounted) {
          setState(() => _assigning = false);
          widget.onAssigned();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Laporan ditugaskan ke ${result.nama}',
                style: GoogleFonts.inter(fontSize: 13)),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ));
        }
      }
    });
  }

  Future<void> _updateStatus(KeluhanItem item, StatusKeluhan s) async {
    await KeluhanService.updateStatus(keluhanId: item.id, status: s);
    if (mounted) widget.onAssigned();
    // Notifikasi ke warga pemilik keluhan (fire-and-forget).
    OneSignalService.instance.sendKeluhanUpdate(
      userId       : item.uid,
      statusLabel  : _statusLabelFor(s),
      judulKeluhan : item.judul,
    );
  }

  String _statusLabelFor(StatusKeluhan s) {
    switch (s) {
      case StatusKeluhan.diproses: return 'Sedang Diproses';
      case StatusKeluhan.selesai:  return 'Selesai';
      case StatusKeluhan.ditolak:  return 'Ditolak';
      default:                     return 'Menunggu';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 260),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: widget.report == null ? _emptyState() : _detailState(widget.report!),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
          child: Icon(Icons.description_outlined, size: 36, color: Colors.grey.shade400),
        ),
        const SizedBox(height: 20),
        Text('Pilih Laporan Untuk Detail',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark)),
        const SizedBox(height: 8),
        Text('Klik salah satu baris untuk melihat detail\ndan menugaskan kepada satpam.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey, height: 1.5)),
      ]),
    );
  }

  Widget _detailState(KeluhanItem r) {
    final tgl = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(r.createdAt);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Kiri: info + action buttons ─────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(children: [
                  Expanded(child: Text(r.judul,
                      style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textDark))),
                  const SizedBox(width: 12),
                  _StatusBadgeRow(r.status),
                ]),
                const SizedBox(height: 12),

                // Info
                _Row('Pelapor', '${r.namaWarga} — Blok ${r.blok} – Unit ${r.nomorUnit}'),
                _Row('Kategori', r.kategori),
                _Row('Tanggal', tgl),
                if (r.assignedName != null)
                  _Row('Ditugaskan ke', r.assignedName!, valueColor: AppColors.primary),

                const SizedBox(height: 10),
                Divider(color: Colors.grey.shade100),
                const SizedBox(height: 10),

                // Deskripsi
                Text('Deskripsi', style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textGrey)),
                const SizedBox(height: 6),
                Text(r.deskripsi, style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textDark, height: 1.6)),

                // Admin note
                if (r.adminNote != null && r.adminNote!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                    ),
                    child: Text(r.adminNote!,
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.primary, height: 1.5)),
                  ),
                ],

                const SizedBox(height: 20),

                // Action buttons
                if (_assigning)
                  const CircularProgressIndicator(strokeWidth: 2)
                else
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      if (r.status == StatusKeluhan.menunggu ||
                          r.status == StatusKeluhan.diproses)
                        ElevatedButton.icon(
                          onPressed: () => _showAssignDialog(r),
                          icon: const Icon(Icons.person_add_outlined, size: 16, color: Colors.white),
                          label: Text(
                            r.assignedName == null ? 'Tugaskan Satpam' : 'Ganti Satpam',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary, elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      if (r.status == StatusKeluhan.diproses)
                        ElevatedButton.icon(
                          onPressed: () => _updateStatus(r, StatusKeluhan.selesai),
                          icon: const Icon(Icons.check_circle_outline, size: 16, color: Colors.white),
                          label: Text('Selesai',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32), elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      if (r.status == StatusKeluhan.menunggu)
                        OutlinedButton.icon(
                          onPressed: () => _updateStatus(r, StatusKeluhan.ditolak),
                          icon: Icon(Icons.cancel_outlined, size: 16, color: Colors.red.shade400),
                          label: Text('Tolak',
                              style: GoogleFonts.inter(fontSize: 12, color: Colors.red.shade400)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.red.shade200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),

          // ── Kanan: foto ──────────────────────────────────────────────
          const SizedBox(width: 24),
          SizedBox(
            width: 260,
            child: _FotoPanel(fotoUrls: r.fotoUrls),
          ),
        ],
      ),
    );
  }

  Widget _Row(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(children: [
        SizedBox(width: 120, child: Text(label,
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textGrey))),
        Expanded(child: Text(value,
            style: GoogleFonts.inter(fontSize: 13,
                color: valueColor ?? AppColors.textDark,
                fontWeight: valueColor != null ? FontWeight.w600 : FontWeight.normal))),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Panel foto (kanan detail)
// ─────────────────────────────────────────────────────────────────────────────

class _FotoPanel extends StatelessWidget {
  const _FotoPanel({required this.fotoUrls});
  final List<String> fotoUrls;

  void _openFullscreen(BuildContext context, String url, int index, List<String> all) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _FotoFullscreen(urls: all, initialIndex: index),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.photo_library_outlined, size: 14, color: AppColors.textGrey),
          const SizedBox(width: 6),
          Text(
            'Foto Lampiran (${fotoUrls.length})',
            style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textGrey),
          ),
        ]),
        const SizedBox(height: 10),

        if (fotoUrls.isEmpty)
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.image_not_supported_outlined,
                      size: 28, color: Colors.grey.shade400),
                  const SizedBox(height: 6),
                  Text('Tidak ada foto',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textGrey)),
                ],
              ),
            ),
          )
        else
          ...fotoUrls.asMap().entries.map((entry) {
            final i   = entry.key;
            final url = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => _openFullscreen(context, url, i, fotoUrls),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      _ReportFotoImage(
                        url: url,
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover,
                      ),
                      // Overlay: zoom icon
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.zoom_in,
                              size: 16, color: Colors.white),
                        ),
                      ),
                      // Label nomor jika lebih dari 1
                      if (fotoUrls.length > 1)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${i + 1} / ${fotoUrls.length}',
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fullscreen viewer
// ─────────────────────────────────────────────────────────────────────────────

class _FotoFullscreen extends StatefulWidget {
  const _FotoFullscreen({required this.urls, required this.initialIndex});
  final List<String> urls;
  final int initialIndex;

  @override
  State<_FotoFullscreen> createState() => _FotoFullscreenState();
}

class _FotoFullscreenState extends State<_FotoFullscreen> {
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Close + counter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.urls.length > 1)
                Text(
                  '${_current + 1} / ${widget.urls.length}',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                )
              else
                const SizedBox(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _ReportFotoImage(
              url: widget.urls[_current],
              fit: BoxFit.contain,
              dark: true,
            ),
          ),

          // Prev / Next
          if (widget.urls.length > 1) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _NavBtn(
                  icon: Icons.arrow_back_ios_new,
                  enabled: _current > 0,
                  onTap: () => setState(() => _current--),
                ),
                const SizedBox(width: 16),
                _NavBtn(
                  icon: Icons.arrow_forward_ios,
                  enabled: _current < widget.urls.length - 1,
                  onTap: () => setState(() => _current++),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  const _NavBtn({required this.icon, required this.enabled, required this.onTap});
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: enabled ? Colors.white24 : Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            color: enabled ? Colors.white : Colors.white38, size: 18),
      ),
    );
  }
}

// ── Gambar foto keluhan — aware base64 (data URI) maupun URL http biasa.
// KeluhanService.sendKeluhan kini menyimpan base64, sama seperti foto
// profil/bantuan/patroli — Image.network saja tidak bisa decode itu.
class _ReportFotoImage extends StatelessWidget {
  const _ReportFotoImage({
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.dark = false,
  });
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool dark;

  bool get _isBase64 => url.startsWith('data:image');

  @override
  Widget build(BuildContext context) {
    if (_isBase64) {
      try {
        final bytes = base64Decode(url.split(',').last);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => _placeholder(),
        );
      } catch (_) {
        return _placeholder();
      }
    }
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return _loading();
      },
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  Widget _loading() => Container(
        width: width,
        height: height,
        color: dark ? Colors.grey.shade800 : Colors.grey.shade100,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: dark ? Colors.white : null,
            ),
          ),
        ),
      );

  Widget _placeholder() => Container(
        width: width,
        height: height,
        color: dark ? Colors.grey.shade800 : Colors.grey.shade100,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image_outlined,
                size: dark ? 48 : 28,
                color: dark ? Colors.white54 : Colors.grey.shade400),
            if (!dark) ...[
              const SizedBox(height: 4),
              Text('Gagal memuat',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textGrey)),
            ],
          ],
        ),
      );
}

