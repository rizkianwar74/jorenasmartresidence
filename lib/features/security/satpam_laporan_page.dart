import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/bantuan_service.dart';
import 'data/security_repository.dart';

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
    _sub = BantuanService.watchSatpamInbox(uid, includeShared: onDuty).listen(
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
    final uid = SecurityRepository.instance.currentSatpamUidOrNull;
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

  // ── Tap kartu → buka detail (jam, isi, keterangan, gambar jika ada) ──────
  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BantuanDetailSheet(request: request),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _statusColor.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
              color: _statusColor.withValues(alpha: 0.07),
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
                        color: _statusColor.withValues(alpha: 0.1),
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

// ─────────────────────────────────────────────────────────────────────────────
// Detail laporan bantuan (bottom sheet) — jam, isi, keterangan, gambar (jika ada)
// ─────────────────────────────────────────────────────────────────────────────
class _BantuanDetailSheet extends StatelessWidget {
  const _BantuanDetailSheet({required this.request});
  final BantuanRequest request;

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
      case BantuanStatus.resolved:
        return 'Selesai';
      case BantuanStatus.cancelled:
        return 'Dibatalkan';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tglLengkap =
        DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(request.createdAt);
    final jam = DateFormat('HH:mm', 'id_ID').format(request.createdAt);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: 12,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 28,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Status
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                _statusLabel.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _statusColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Judul (kategori)
            Text(
              request.kategori,
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),

            // ── Jam / waktu lapor ────────────────────────────────────────
            Row(
              children: [
                Icon(Icons.schedule_rounded,
                    size: 14, color: AppColors.textGrey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '$tglLengkap • $jam',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textGrey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Keterangan (pelapor) ─────────────────────────────────────
            const _BantuanDetailLabel('KETERANGAN PELAPOR'),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person_outline_rounded,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${request.namaWarga} • Blok ${request.blok} – Unit ${request.nomorUnit}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Isi laporan ──────────────────────────────────────────────
            const _BantuanDetailLabel('ISI LAPORAN'),
            const SizedBox(height: 8),
            Text(
              request.catatan.isNotEmpty
                  ? request.catatan
                  : 'Tidak ada catatan tambahan dari warga.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: request.catatan.isNotEmpty
                    ? const Color(0xFF475569)
                    : AppColors.textGrey,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),

            // ── Gambar (jika ada) ────────────────────────────────────────
            _BantuanDetailLabel(request.fotoUrls.isEmpty
                ? 'GAMBAR (TIDAK ADA)'
                : 'GAMBAR (${request.fotoUrls.length})'),
            const SizedBox(height: 8),
            if (request.fotoUrls.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Icon(Icons.image_not_supported_outlined,
                        size: 28, color: Colors.grey.shade400),
                    const SizedBox(height: 6),
                    Text(
                      'Tidak ada gambar dilampirkan',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textGrey),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 92,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: request.fotoUrls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _BantuanFotoViewer(
                          urls: request.fotoUrls,
                          initialIndex: i,
                        ),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _BantuanFotoImage(
                        url: request.fotoUrls[i],
                        width: 92,
                        height: 92,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Viewer foto fullscreen (swipe antar foto kalau lebih dari satu) ────────
class _BantuanFotoViewer extends StatefulWidget {
  const _BantuanFotoViewer({required this.urls, required this.initialIndex});
  final List<String> urls;
  final int initialIndex;

  @override
  State<_BantuanFotoViewer> createState() => _BantuanFotoViewerState();
}

class _BantuanFotoViewerState extends State<_BantuanFotoViewer> {
  late final PageController _pageController;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_index + 1} / ${widget.urls.length}',
          style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.urls.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (_, i) => InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Center(
            child: _BantuanFotoImage(
              url: widget.urls[i],
              fit: BoxFit.contain,
              dark: true,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Gambar foto bantuan — aware base64 (data URI) maupun URL http biasa.
// Disamakan dengan pola ProfileAvatar: base64 dipakai untuk foto baru (lihat
// BantuanService.sendRequest), tapi tetap dukung URL http kalau ada data
// lama yang sempat tersimpan lewat Firebase Storage sebelumnya.
class _BantuanFotoImage extends StatelessWidget {
  const _BantuanFotoImage({
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
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return _loading();
      },
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  Widget _loading() => Container(
        width: width,
        height: height,
        color: dark ? Colors.black : const Color(0xFFF5F5F5),
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
        color: dark ? Colors.black : const Color(0xFFF5F5F5),
        child: Icon(Icons.broken_image_outlined,
            color: dark ? Colors.white54 : Colors.grey.shade400,
            size: dark ? 48 : 24),
      );
}

// ── Label kecil untuk tiap section di detail sheet ──────────────────────────
class _BantuanDetailLabel extends StatelessWidget {
  const _BantuanDetailLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: AppColors.textGrey,
        letterSpacing: 0.6,
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
