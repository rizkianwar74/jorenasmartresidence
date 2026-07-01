import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/keluhan_repository.dart';
import '../../../core/services/onesignal_service.dart';
import '../data/security_repository.dart';
import '../helpers/status_keluhan_helpers.dart';
import 'report_filter_chip.dart';
import 'keluhan_card.dart';

class KeluhanTab extends StatefulWidget {
  const KeluhanTab({super.key});

  @override
  State<KeluhanTab> createState() => _KeluhanTabState();
}

class _KeluhanTabState extends State<KeluhanTab>
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
    _initInbox();
  }

  // Keluhan baru hanya masuk ke satpam yang sedang BERTUGAS (kolam bersama).
  // Cek status bertugas dulu, lalu langganan inbox sesuai status itu.
  Future<void> _initInbox() async {
    final repo = SecurityRepository.instance;
    final uid = repo.currentSatpamUid;
    bool onDuty = false;
    try {
      final data = await repo.fetchUser(uid);
      onDuty = (data?['isOnDuty'] as bool?) ?? false;
    } catch (_) {}
    if (!mounted) return;
    _sub = KeluhanRepository.watchSatpamInbox(uid, includeShared: onDuty).listen(
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

    // Saat satpam menangani, keluhan diklaim jadi miliknya (keluar dari
    // kolam bersama satpam lain).
    final repo = SecurityRepository.instance;
    await KeluhanRepository.updateStatus(
      keluhanId   : item.id,
      status      : newStatus,
      adminNote   : note,
      assignToUid : repo.currentSatpamUid,
      assignToName: repo.satpamDisplayName,
    );
    // Notifikasi ke warga pemilik keluhan (fire-and-forget).
    OneSignalService.instance.sendKeluhanUpdate(
      userId       : item.uid,
      statusLabel  : newStatus.label,
      judulKeluhan : item.judul,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Status diperbarui menjadi ${newStatus.label}',
            style: GoogleFonts.inter(fontSize: 13),
          ),
          backgroundColor: newStatus.color,
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
      builder: (dialogCtx) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogCtx, null),
            child: Text('Batal',
                style: GoogleFonts.inter(color: AppColors.textGrey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (required && ctrl.text.trim().isEmpty) return;
              Navigator.pop(dialogCtx,
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
                ReportFilterChip(
                  label: 'Semua',
                  active: _filterStatus == null,
                  onTap: () =>
                      setState(() => _filterStatus = null),
                ),
                const SizedBox(width: 8),
                ReportFilterChip(
                  label: 'Menunggu',
                  active: _filterStatus == StatusKeluhan.menunggu,
                  color: AppColors.textGrey,
                  onTap: () => setState(
                      () => _filterStatus = StatusKeluhan.menunggu),
                ),
                const SizedBox(width: 8),
                ReportFilterChip(
                  label: 'Diproses',
                  active: _filterStatus == StatusKeluhan.diproses,
                  color: const Color(0xFFFF9500),
                  onTap: () => setState(
                      () => _filterStatus = StatusKeluhan.diproses),
                ),
                const SizedBox(width: 8),
                ReportFilterChip(
                  label: 'Selesai',
                  active: _filterStatus == StatusKeluhan.selesai,
                  color: const Color(0xFF2E7D32),
                  onTap: () => setState(
                      () => _filterStatus = StatusKeluhan.selesai),
                ),
                const SizedBox(width: 8),
                ReportFilterChip(
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
                  ? const EmptyKeluhan()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                      itemBuilder: (_, i) => KeluhanCard(
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
