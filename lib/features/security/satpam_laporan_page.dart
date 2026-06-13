import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/bantuan_service.dart';

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
    _sub = BantuanService.watchActiveRequests().listen(
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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    await BantuanService.updateStatus(
      requestId: req.id,
      status: BantuanStatus.onMyWay,
      respondedBy: uid,
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
      await BantuanService.updateStatus(
        requestId: req.id,
        status: BantuanStatus.resolved,
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
                  ? _EmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _LaporanCard(
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

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline_rounded,
              size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Tidak ada laporan aktif',
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textGrey)),
          const SizedBox(height: 6),
          Text('Semua laporan warga sudah ditangani',
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textGrey)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Kartu satu laporan
// ─────────────────────────────────────────────────────────────────────────────
class _LaporanCard extends StatelessWidget {
  const _LaporanCard({
    required this.request,
    this.onMyWay,
    this.onResolved,
  });

  final BantuanRequest request;
  final VoidCallback? onMyWay;
  final VoidCallback? onResolved;

  Color get _statusColor {
    switch (request.status) {
      case BantuanStatus.pending:
        return const Color(0xFFE65100);
      case BantuanStatus.onMyWay:
        return const Color(0xFF1565C0);
      default:
        return const Color(0xFF2E7D32);
    }
  }

  String get _statusLabel {
    switch (request.status) {
      case BantuanStatus.pending:
        return 'Menunggu';
      case BantuanStatus.onMyWay:
        return 'Menuju Lokasi';
      default:
        return 'Selesai';
    }
  }

  IconData get _statusIcon {
    switch (request.status) {
      case BantuanStatus.pending:
        return Icons.access_time_rounded;
      case BantuanStatus.onMyWay:
        return Icons.directions_walk_rounded;
      default:
        return Icons.check_circle_outline_rounded;
    }
  }

  IconData get _kategoriIcon {
    switch (request.kategori) {
      case 'Pendampingan':
        return Icons.directions_walk_rounded;
      case 'Kendaraan':
        return Icons.directions_car_outlined;
      case 'Orang Mencurigakan':
        return Icons.remove_red_eye_outlined;
      case 'Gangguan Lingkungan':
        return Icons.volume_up_outlined;
      default:
        return Icons.support_agent_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _statusColor.withOpacity(0.2), width: 1.5),
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
          // ── Header status ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.07),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Icon(_statusIcon, size: 14, color: _statusColor),
                const SizedBox(width: 6),
                Text(
                  _statusLabel.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _statusColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Text(
                  _timeAgo(request.createdAt),
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppColors.textGrey),
                ),
              ],
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_kategoriIcon,
                          color: _statusColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.kategori,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${request.namaWarga}  •  Blok ${request.blok} – Unit ${request.nomorUnit}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (request.catatan.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F7F8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.notes_rounded,
                            size: 14, color: AppColors.textGrey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            request.catatan,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textGrey,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Tombol aksi ──────────────────────────────────────────
                if (onMyWay != null || onResolved != null) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (onMyWay != null)
                        Expanded(
                          child: _ActionBtn(
                            label: 'On My Way',
                            icon: Icons.directions_walk_rounded,
                            color: const Color(0xFF1565C0),
                            onTap: onMyWay!,
                          ),
                        ),
                      if (onResolved != null)
                        Expanded(
                          child: _ActionBtn(
                            label: 'Selesai',
                            icon: Icons.check_circle_outline_rounded,
                            color: const Color(0xFF2E7D32),
                            onTap: onResolved!,
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

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
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
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
