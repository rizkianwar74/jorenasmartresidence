import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/services/keluhan_service.dart';
import '../../shared/widgets/satpam_bottom_nav.dart';
import '../auth/auth_repository.dart';

class SatpamReportsPage extends StatefulWidget {
  const SatpamReportsPage({super.key});

  @override
  State<SatpamReportsPage> createState() => _SatpamReportsPageState();
}

class _SatpamReportsPageState extends State<SatpamReportsPage>
    with SingleTickerProviderStateMixin {
  static const double _contentMaxWidth = 600.0;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        body: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: _contentMaxWidth),
                child: Column(
                  children: [
                    // ── Top Bar ──────────────────────────────────────────
                    _TopBar(),

                    // ── Tab Bar ──────────────────────────────────────────
                    Container(
                      color: Colors.white,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: const Color(0xFF94A3B8),
                        indicatorColor: AppColors.primary,
                        indicatorWeight: 2.5,
                        labelStyle: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        unselectedLabelStyle: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        tabs: const [
                          Tab(text: 'Keluhan Warga'),
                          Tab(text: 'Lapor Insiden'),
                        ],
                      ),
                    ),

                    // ── Tab Views ─────────────────────────────────────────
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _KeluhanTab(),
                          _LaporInsidenTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom Nav ────────────────────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SatpamBottomNav(currentIndex: 2),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 — Keluhan Warga (Firestore realtime)
// ─────────────────────────────────────────────────────────────────────────────
class _KeluhanTab extends StatefulWidget {
  @override
  State<_KeluhanTab> createState() => _KeluhanTabState();
}

class _KeluhanTabState extends State<_KeluhanTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  StreamSubscription<List<KeluhanItem>>? _sub;
  List<KeluhanItem> _items = [];
  bool _loading = true;

  // Filter status: null = semua
  StatusKeluhan? _filterStatus;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _sub = KeluhanService.watchAssignedKeluhan(uid).listen(
      (list) {
        if (mounted) setState(() { _items = list; _loading = false; });
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
    if (_filterStatus == null) return _items;
    return _items.where((i) => i.status == _filterStatus).toList();
  }

  Future<void> _updateStatus(
      KeluhanItem item, StatusKeluhan newStatus) async {
    // Jika ditolak, minta alasan dulu
    String? note;
    if (newStatus == StatusKeluhan.ditolak) {
      note = await _showNoteDialog('Alasan Penolakan');
      if (note == null) return; // user cancel
    } else if (newStatus == StatusKeluhan.selesai) {
      note = await _showNoteDialog('Catatan Penyelesaian (opsional)',
          required: false);
    }

    await KeluhanService.updateStatus(
      keluhanId : item.id,
      status    : newStatus,
      adminNote : note,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Status diperbarui menjadi ${_labelOf(newStatus)}',
            style: GoogleFonts.inter(fontSize: 13),
          ),
          backgroundColor: _colorOf(newStatus),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        ),
      );
    }
  }

  Future<String?> _showNoteDialog(String title,
      {bool required = true}) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        title: Text(title,
            style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: required
                ? 'Masukkan alasan...'
                : 'Kosongkan jika tidak ada catatan',
            hintStyle: GoogleFonts.inter(
                fontSize: 13, color: AppColors.textGrey),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text('Batal',
                style: GoogleFonts.inter(color: AppColors.textGrey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (required && ctrl.text.trim().isEmpty) return;
              Navigator.pop(context,
                  ctrl.text.trim().isEmpty ? null : ctrl.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Simpan',
                style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
    ctrl.dispose();
    return result;
  }

  String _labelOf(StatusKeluhan s) {
    switch (s) {
      case StatusKeluhan.diproses: return 'Diproses';
      case StatusKeluhan.selesai:  return 'Selesai';
      case StatusKeluhan.ditolak:  return 'Ditolak';
      default:                     return 'Menunggu';
    }
  }

  Color _colorOf(StatusKeluhan s) {
    switch (s) {
      case StatusKeluhan.diproses: return const Color(0xFFFF9500);
      case StatusKeluhan.selesai:  return const Color(0xFF2E7D32);
      case StatusKeluhan.ditolak:  return Colors.red;
      default:                     return AppColors.textGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        // ── Filter chips ───────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'Semua',
                  active: _filterStatus == null,
                  onTap: () =>
                      setState(() => _filterStatus = null),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Menunggu',
                  active: _filterStatus == StatusKeluhan.menunggu,
                  color: AppColors.textGrey,
                  onTap: () => setState(
                      () => _filterStatus = StatusKeluhan.menunggu),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Diproses',
                  active: _filterStatus == StatusKeluhan.diproses,
                  color: const Color(0xFFFF9500),
                  onTap: () => setState(
                      () => _filterStatus = StatusKeluhan.diproses),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Selesai',
                  active: _filterStatus == StatusKeluhan.selesai,
                  color: const Color(0xFF2E7D32),
                  onTap: () => setState(
                      () => _filterStatus = StatusKeluhan.selesai),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Ditolak',
                  active: _filterStatus == StatusKeluhan.ditolak,
                  color: Colors.red,
                  onTap: () => setState(
                      () => _filterStatus = StatusKeluhan.ditolak),
                ),
              ],
            ),
          ),
        ),

        // ── List ────────────────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(strokeWidth: 2))
              : _filtered.isEmpty
                  ? _EmptyKeluhan()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                      itemBuilder: (_, i) => _KeluhanCard(
                        item: _filtered[i],
                        onUpdateStatus: _updateStatus,
                        isSatpamView: true,
                      ),
                    ),
        ),
      ],
    );
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
    this.color,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? c.withOpacity(0.1) : const Color(0xFFF4F6F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? c : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight:
                active ? FontWeight.bold : FontWeight.w500,
            color: active ? c : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

// ── Empty state keluhan ────────────────────────────────────────────────────────
class _EmptyKeluhan extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined,
              size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          Text(
            'Tidak ada keluhan',
            style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textGrey),
          ),
          const SizedBox(height: 4),
          Text(
            'Belum ada keluhan yang ditugaskan ke Anda',
            style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }
}

// ── Kartu keluhan ─────────────────────────────────────────────────────────────
class _KeluhanCard extends StatelessWidget {
  const _KeluhanCard({
    required this.item,
    required this.onUpdateStatus,
    this.isSatpamView = false,
  });
  final KeluhanItem item;
  final Future<void> Function(KeluhanItem, StatusKeluhan) onUpdateStatus;
  final bool isSatpamView;

  Color get _statusColor => switch (item.status) {
        StatusKeluhan.diproses => const Color(0xFFFF9500),
        StatusKeluhan.selesai  => const Color(0xFF2E7D32),
        StatusKeluhan.ditolak  => Colors.red,
        StatusKeluhan.menunggu => AppColors.textGrey,
      };

  Color get _statusBg => switch (item.status) {
        StatusKeluhan.diproses => const Color(0xFFFFF3E0),
        StatusKeluhan.selesai  => const Color(0xFFE8F5E9),
        StatusKeluhan.ditolak  => const Color(0xFFFFEBEE),
        StatusKeluhan.menunggu => const Color(0xFFF5F5F5),
      };

  @override
  Widget build(BuildContext context) {
    final tgl = DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
        .format(item.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: _statusColor.withOpacity(0.15), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusBg,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    item.statusLabel.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _statusColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  item.kategori,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  tgl,
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppColors.textGrey),
                ),
              ],
            ),
          ),

          // ── Body ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Judul
                Text(
                  item.judul,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0D1B2A),
                  ),
                ),
                const SizedBox(height: 4),

                // Info warga
                Row(
                  children: [
                    Icon(Icons.person_outline_rounded,
                        size: 13, color: AppColors.textGrey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${item.namaWarga}  •  Blok ${item.blok} – Unit ${item.nomorUnit}',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.textGrey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Deskripsi
                Text(
                  item.deskripsi,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF475569),
                    height: 1.5,
                  ),
                ),

                // Admin note
                if (item.adminNote != null &&
                    item.adminNote!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                            size: 12, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.adminNote!,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.primary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Tombol aksi ─────────────────────────────────────
                if (item.status == StatusKeluhan.menunggu ||
                    item.status == StatusKeluhan.diproses) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (item.status == StatusKeluhan.menunggu)
                        Expanded(
                          child: _ActionBtn(
                            label: 'Proses',
                            icon: Icons.play_circle_outline_rounded,
                            color: const Color(0xFFFF9500),
                            onTap: () => onUpdateStatus(
                                item, StatusKeluhan.diproses),
                          ),
                        ),
                      if (item.status == StatusKeluhan.menunggu)
                        const SizedBox(width: 8),
                      if (item.status == StatusKeluhan.diproses)
                        Expanded(
                          child: _ActionBtn(
                            label: 'Selesai',
                            icon: Icons.check_circle_outline_rounded,
                            color: const Color(0xFF2E7D32),
                            onTap: () => onUpdateStatus(
                                item, StatusKeluhan.selesai),
                          ),
                        ),
                      if (item.status == StatusKeluhan.diproses)
                        const SizedBox(width: 8),
                      if (!isSatpamView && item.status != StatusKeluhan.ditolak)
                        Expanded(
                          child: _ActionBtn(
                            label: 'Tolak',
                            icon: Icons.cancel_outlined,
                            color: Colors.red,
                            onTap: () => onUpdateStatus(
                                item, StatusKeluhan.ditolak),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 — Lapor Insiden (form satpam)
// ─────────────────────────────────────────────────────────────────────────────
class _LaporInsidenTab extends StatefulWidget {
  @override
  State<_LaporInsidenTab> createState() => _LaporInsidenTabState();
}

class _LaporInsidenTabState extends State<_LaporInsidenTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String? _selectedKategori;
  final _blokController         = TextEditingController();
  final _nomorController        = TextEditingController();
  final _detailLokasiController = TextEditingController();
  final _deskripsiController    = TextEditingController();
  DateTime _waktuKejadian       = DateTime.now();
  bool _saving                  = false;

  static const _kategoriList = [
    (label: 'Kebakaran',  icon: Icons.local_fire_department_outlined),
    (label: 'Vandalisme', icon: Icons.format_paint_outlined),
    (label: 'Medis',      icon: Icons.medical_services_outlined),
    (label: 'Pencurian',  icon: Icons.person_search_outlined),
    (label: 'Lainnya',    icon: Icons.more_time_outlined),
  ];

  @override
  void dispose() {
    _blokController.dispose();
    _nomorController.dispose();
    _detailLokasiController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  String _formatWaktu(DateTime dt) {
    final d  = '${dt.month.toString().padLeft(2,'0')}/${dt.day.toString().padLeft(2,'0')}/${dt.year}';
    final h  = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m  = dt.minute.toString().padLeft(2, '0');
    final pm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$d  ${h.toString().padLeft(2,'0')}:$m $pm';
  }

  Future<void> _pickWaktu() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _waktuKejadian,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_waktuKejadian),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (time == null) return;
    setState(() {
      _waktuKejadian = DateTime(
          date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    // ── Validasi ─────────────────────────────────────────────────────────────
    if (_selectedKategori == null) {
      _showSnack('Pilih kategori insiden terlebih dahulu.', isError: true);
      return;
    }
    if (_blokController.text.trim().isEmpty) {
      _showSnack('Isi blok lokasi kejadian.', isError: true);
      return;
    }
    if (_deskripsiController.text.trim().isEmpty) {
      _showSnack('Isi deskripsi detail kejadian.', isError: true);
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _saving = true);

    try {
      final user      = FirebaseAuth.instance.currentUser;
      final appUser   = AuthRepository.currentUser;
      final satpamUid = user?.uid ?? '';
      final namaSatpam = appUser?.namaLengkap.isNotEmpty == true
          ? appUser!.namaLengkap
          : (user?.displayName ?? 'Satpam');

      await FirebaseFirestore.instance.collection('insiden').add({
        'satpamUid'   : satpamUid,
        'namaSatpam'  : namaSatpam,
        'kategori'    : _selectedKategori,
        'blok'        : _blokController.text.trim(),
        'nomor'       : _nomorController.text.trim(),
        'detailLokasi': _detailLokasiController.text.trim(),
        'deskripsi'   : _deskripsiController.text.trim(),
        'waktuKejadian': Timestamp.fromDate(_waktuKejadian),
        'status'      : 'BARU',
        'createdAt'   : FieldValue.serverTimestamp(),
        'updatedAt'   : FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // Reset form
      setState(() {
        _selectedKategori = null;
        _waktuKejadian    = DateTime.now();
        _saving           = false;
      });
      _blokController.clear();
      _nomorController.clear();
      _detailLokasiController.clear();
      _deskripsiController.clear();

      _showSnack('Laporan insiden berhasil dikirim ke Command Center.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showSnack('Gagal mengirim laporan: $e', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(fontSize: 13)),
      backgroundColor: isError ? Colors.red.shade600 : const Color(0xFF1173D4),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
    ));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero Banner ──────────────────────────────────────────────
          _HeroBanner(),
          const SizedBox(height: 20),

          // ── Form ─────────────────────────────────────────────────────
          _FormCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Kategori Insiden
                _SectionLabel(label: 'KATEGORI INSIDEN'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _kategoriList.map((k) {
                    final isSelected = _selectedKategori == k.label;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedKategori = k.label),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.08)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.grey.shade300,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(k.icon,
                                size: 16,
                                color: isSelected
                                    ? AppColors.primary
                                    : const Color(0xFF64748B)),
                            const SizedBox(width: 6),
                            Text(
                              k.label,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? AppColors.primary
                                    : const Color(0xFF0D1B2A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 22),
                Divider(color: Colors.grey.shade100),
                const SizedBox(height: 18),

                // 2. Lokasi Kejadian
                _SectionLabel(label: 'LOKASI KEJADIAN'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _InputField(
                        controller: _blokController,
                        icon: Icons.grid_view_outlined,
                        hint: 'Blok',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InputField(
                        controller: _nomorController,
                        icon: Icons.tag,
                        hint: 'Nomor',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _InputField(
                  controller: _detailLokasiController,
                  icon: Icons.location_on_outlined,
                  hint: 'Detail Lokasi (Contoh: Lobby Selatan, Lantai 1)',
                ),

                const SizedBox(height: 22),
                Divider(color: Colors.grey.shade100),
                const SizedBox(height: 18),

                // 3. Waktu Kejadian
                _SectionLabel(label: 'WAKTU KEJADIAN'),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickWaktu,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time_outlined,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _formatWaktu(_waktuKejadian),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFF0D1B2A),
                            ),
                          ),
                        ),
                        Icon(Icons.calendar_today_outlined,
                            size: 16,
                            color: Colors.grey.shade400),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 22),
                Divider(color: Colors.grey.shade100),
                const SizedBox(height: 18),

                // 4. Deskripsi Detail
                _SectionLabel(label: 'DESKRIPSI DETAIL'),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: _deskripsiController,
                    maxLines: 5,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF0D1B2A),
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(14),
                      hintText:
                          'Jelaskan kronologi kejadian secara detail...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFFB0BEC5),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Submit button ───────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _submit,
                    icon: _saving
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_outlined,
                            color: Colors.white, size: 18),
                    label: Text(
                      _saving ? 'Mengirim...' : 'SUBMIT LAPORAN SEKARANG',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1173D4),
                      disabledBackgroundColor:
                          const Color(0xFF1173D4).withOpacity(0.6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Laporan akan langsung diteruskan ke Pusat Komando.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF94A3B8),
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
// Shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 20,
        right: 20,
        bottom: 12,
      ),
      child: Row(
        children: [
          Icon(Icons.security, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            'Laporan & Keluhan',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const Spacer(),
          Icon(Icons.notifications_outlined,
              size: 22, color: const Color(0xFF0D1B2A)),
          const SizedBox(width: 14),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Icon(Icons.person_outline,
                size: 18, color: Color(0xFF0D1B2A)),
          ),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D2137), Color(0xFF1173D4)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Opacity(
              opacity: 0.15,
              child: Icon(Icons.grid_on, size: 130, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Pelaporan Real-Time',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
       
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Pastikan data yang diinput akurat dan objektif.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
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

class _FormCard extends StatelessWidget {
  const _FormCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF94A3B8),
        letterSpacing: 0.8,
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.icon,
    required this.hint,
    this.keyboardType,
  });
  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(
            fontSize: 14, color: const Color(0xFF0D1B2A)),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          prefixIcon:
              Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 38, minHeight: 38),
          hintText: hint,
          hintStyle: GoogleFonts.inter(
              fontSize: 13, color: const Color(0xFFB0BEC5)),
        ),
      ),
    );
  }
}
