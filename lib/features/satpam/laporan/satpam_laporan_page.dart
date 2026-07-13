import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/bantuan_repository.dart';
import '../../../core/services/onesignal_service.dart';
import '../../security/data/security_repository.dart';
import 'widgets/laporan_shared_widgets.dart';
import 'widgets/laporan_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Halaman Laporan Warga (satpam) — inbox permintaan bantuan warga.
//
// Widget-widget pendukung (kartu laporan, detail sheet, viewer foto, empty
// state) dipecah ke folder widgets/ agar file ini fokus pada state
// management (inbox stream, aksi On My Way / Selesai) saja.
// ─────────────────────────────────────────────────────────────────────────────

class SatpamLaporanPage extends StatefulWidget {
  const SatpamLaporanPage({super.key});

  @override
  State<SatpamLaporanPage> createState() => _SatpamLaporanPageState();
}

class _SatpamLaporanPageState extends State<SatpamLaporanPage> {
  StreamSubscription<List<BantuanRequest>>? _sub;
  List<BantuanRequest> _requests = [];
  bool _loading = true;

  // Filter: 'aktif' | 'semua'
  String _filter = 'aktif';

  @override
  void initState() {
    super.initState();
    _initInbox();
  }

  // Bantuan warga hanya masuk ke satpam yang sedang BERTUGAS (kolam bersama).
  Future<void> _initInbox() async {
    final repo = SecurityRepository.instance;
    final uid = repo.currentSatpamUid;
    bool onDuty = false;
    try {
      final data = await repo.fetchUser(uid);
      onDuty = (data?['isOnDuty'] as bool?) ?? false;
    } catch (_) {}
    if (!mounted) return;
    _sub = BantuanRepository.watchSatpamInbox(uid, includeShared: onDuty).listen(
      (list) {
        if (mounted) setState(() { _requests = list; _loading = false; });
      },
      onError: (_) { if (mounted) setState(() => _loading = false); },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  List<BantuanRequest> get _filtered {
    if (_filter == 'aktif') return _requests;
    // 'semua' — stream sudah hanya PENDING/ON_MY_WAY, cukup tampilkan semua
    return _requests;
  }

  Future<void> _onMyWay(BantuanRequest req) async {
    HapticFeedback.mediumImpact();
    final repo = SecurityRepository.instance;
    final uid  = repo.currentSatpamUidOrNull;
    await BantuanRepository.updateStatus(
      requestId: req.id,
      status: BantuanStatus.onMyWay,
      respondedBy: uid,
    );
    // Notifikasi ke user yang meminta bantuan (fire-and-forget).
    OneSignalService.instance.sendBantuanUpdate(
      userId     : req.uid,
      onMyWay    : true,
      namaSatpam : repo.satpamDisplayName,
    );
  }

  Future<void> _onResolved(BantuanRequest req) async {
    HapticFeedback.mediumImpact();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('Selesaikan Laporan?',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text('Tandai laporan ini sebagai selesai?',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal',
                style: GoogleFonts.inter(color: AppColors.textGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              elevation: 0,
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Selesai',
                style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await BantuanRepository.updateStatus(
        requestId: req.id,
        status: BantuanStatus.resolved,
      );
      // Notifikasi ke user yang meminta bantuan (fire-and-forget).
      OneSignalService.instance.sendBantuanUpdate(
        userId     : req.uid,
        onMyWay    : false,
        namaSatpam : SecurityRepository.instance.satpamDisplayName,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6F9),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          color: AppColors.textDark,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Laporan Warga',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        centerTitle: true,
        actions: [
          // Badge jumlah aktif
          if (_requests.isNotEmpty)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE65100),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_requests.length} aktif',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: _loading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : _requests.isEmpty
                  ? const LaporanEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => LaporanCard(
                        request: _filtered[i],
                        onMyWay: _filtered[i].status == BantuanStatus.pending
                            ? () => _onMyWay(_filtered[i])
                            : null,
                        onResolved:
                            _filtered[i].status == BantuanStatus.onMyWay
                                ? () => _onResolved(_filtered[i])
                                : null,
                      ),
                    ),
        ),
      ),
    );
  }
}
