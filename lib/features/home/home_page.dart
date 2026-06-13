import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/bantuan_service.dart';
import '../../shared/widgets/bottom_nav_bar.dart';
import '../../core/router/app_router.dart';
import '../auth/auth_repository.dart';
import '../admin/admin_berita_page.dart' show BeritaDoc;
import '../berita/berita_detail_page.dart';
import '../berita/berita_list_page.dart';
import 'widgets/home_header.dart';
import 'widgets/quick_action_card.dart';
import 'widgets/news_carousel.dart';
import 'widgets/unit_status_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const double _contentMaxWidth = 600.0;
  static const bool _sudahLunas = false;

  StreamSubscription<BantuanRequest?>? _bantuanSub;
  BantuanRequest? _activeBantuan;

  // Berita dari Firestore
  List<BeritaDoc> _beritaList = [];
  bool _beritaLoading = true;

  @override
  void initState() {
    super.initState();
    _startListeningBantuan();
    _loadBerita();
  }

  void _startListeningBantuan() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _bantuanSub?.cancel();
    _bantuanSub = BantuanService.watchMyActiveRequest(uid).listen(
      (req) {
        if (mounted) setState(() => _activeBantuan = req);
      },
      onError: (e) => debugPrint('[HomeBantuanStream] error: $e'),
      onDone: () {
        // Stream selesai (tidak ada request aktif) — restart nanti
        // jika user kirim request baru, stream akan aktif lagi
        if (mounted && _activeBantuan == null) {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) _startListeningBantuan();
          });
        }
      },
    );
  }

  Future<void> _loadBerita() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('beritaacara')
          .get();

      final all = snap.docs.map(BeritaDoc.fromDoc).toList();
      // Filter published, sort by publishedAt client-side, ambil 3 teratas
      final published = all.where((b) => b.isPublished).toList()
        ..sort((a, b) {
          if (a.publishedAt == null && b.publishedAt == null) return 0;
          if (a.publishedAt == null) return 1;
          if (b.publishedAt == null) return -1;
          return b.publishedAt!.compareTo(a.publishedAt!);
        });
      final top3 = published.take(3).toList();

      if (mounted) {
        setState(() {
          _beritaList = top3;
          _beritaLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[HomeBerita] error: $e');
      if (mounted) setState(() => _beritaLoading = false);
    }
  }

  @override
  void dispose() {
    _bantuanSub?.cancel();
    super.dispose();
  }

  String _buildGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  Future<void> _cancelBantuan(String requestId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('Batalkan Laporan?',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text(
          'Apakah Anda yakin ingin membatalkan laporan ini?',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text('Tidak', style: GoogleFonts.inter(color: AppColors.textGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Ya, Batalkan',
                style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await BantuanService.cancelRequest(requestId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthRepository.currentUser;
    final namaDepan = user?.namaLengkap.split(' ').first ?? 'Pengguna';
    final namaLengkap = user?.namaLengkap ?? 'Pengguna';
    final blok = user?.blok ?? '-';
    final nomorUnit = user?.nomorUnit ?? '-';

    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: MediaQuery.of(context).padding.top),

                    HomeHeader(
                      userName: namaDepan,
                      greeting: _buildGreeting(),
                      notificationCount: 3,
                      onNotificationTap: () {},
                    ),

                    // ── Kartu status bantuan aktif ─────────────────────────
                    if (_activeBantuan != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                        child: _ActiveBantuanCard(
                          request: _activeBantuan!,
                          onCancel: () =>
                              _cancelBantuan(_activeBantuan!.id),
                        ),
                      ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: TagihanCard(
                              namaPenghuni: namaLengkap,
                              jumlahTagihan: 'Rp 450.000',
                              sudahLunas: _sudahLunas,
                              onBayarTap: () =>
                                  Navigator.pushNamed(context, AppRouter.tagihan),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: QuickActionCard(
                              icon: Icons.security,
                              iconColor: Colors.red,
                              bgIconColor: Colors.red.shade50,
                              title: 'Panggil Satpam',
                              subtitle: 'RESPON CEPAT',
                              onTap: () => Navigator.pushNamed(
                                  context, AppRouter.security),
                            ),
                          ),
                        ],
                      ),
                    ),

                    _beritaLoading
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                                child: CircularProgressIndicator(
                                    strokeWidth: 2)),
                          )
                        : _beritaList.isEmpty
                            ? const SizedBox.shrink()
                            : NewsCarousel(
                                items: _beritaList
                                    .map((b) => NewsItem(
                                          imageUrl: b.imageUrl,
                                          category: b.kategori,
                                          title: b.judul,
                                          date: b.tanggalFormatted,
                                        ))
                                    .toList(),
                                onSeeAllTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const BeritaListPage()),
                                  );
                                },
                                onNewsTap: (item) {
                                  final index = _beritaList.indexWhere(
                                      (b) => b.judul == item.title);
                                  if (index != -1) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => BeritaDetailPage(
                                                berita: _beritaList[index]),
                                      ),
                                    );
                                  }
                                },
                              ),

                    UnitStatusCard(
                      blockName: blok,
                      unitNumber: nomorUnit,
                      paymentStatus: PaymentStatus.paid,
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomNavBar(
              currentIndex: 0,
              contentMaxWidth: _contentMaxWidth,
            ),
          ),

          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 130,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Kartu status bantuan aktif — muncul di home saat ada request PENDING/ON_MY_WAY
// ─────────────────────────────────────────────────────────────────────────────

class _ActiveBantuanCard extends StatelessWidget {
  const _ActiveBantuanCard({
    required this.request,
    required this.onCancel,
  });

  final BantuanRequest request;
  final VoidCallback onCancel;

  Color get _statusColor {
    switch (request.status) {
      case BantuanStatus.onMyWay:
        return const Color(0xFF0284C7); // biru
      default:
        return AppColors.primary;
    }
  }

  IconData get _statusIcon {
    switch (request.status) {
      case BantuanStatus.onMyWay:
        return Icons.directions_walk_rounded;
      default:
        return Icons.access_time_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _statusColor.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _statusColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header kartu ─────────────────────────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.07),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Icon(_statusIcon, size: 16, color: _statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    request.statusLabel,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _statusColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                // Tombol batal hanya saat PENDING
                if (request.status == BantuanStatus.pending)
                  GestureDetector(
                    onTap: onCancel,
                    child: Text(
                      'Batalkan',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.support_agent_rounded,
                      color: _statusColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.kategori,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Blok ${request.blok} – Unit ${request.nomorUnit}',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.textGrey),
                      ),
                      if (request.catatan.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          request.catatan,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.textGrey),
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Indikator pulse (hanya PENDING) ──────────────────────
                if (request.status == BantuanStatus.pending)
                  _PulseDot(color: _statusColor),
              ],
            ),
          ),

          // ── Progress bar steps ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: _MiniTimeline(status: request.status),
          ),
        ],
      ),
    );
  }
}

// ── Dot animasi pulse ─────────────────────────────────────────────────────────

class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color});
  final Color color;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              widget.color.withOpacity(0.4 + 0.6 * _ctrl.value),
        ),
      ),
    );
  }
}

// ── Timeline mini (3 langkah horizontal) ──────────────────────────────────────

class _MiniTimeline extends StatelessWidget {
  const _MiniTimeline({required this.status});
  final BantuanStatus status;

  @override
  Widget build(BuildContext context) {
    final steps = ['Terkirim', 'Menuju Lokasi', 'Selesai'];
    final activeIndex = status == BantuanStatus.onMyWay ? 1 : 0;

    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Garis penghubung
          final lineIndex = i ~/ 2;
          final filled = lineIndex < activeIndex;
          return Expanded(
            child: Container(
              height: 2,
              color: filled
                  ? AppColors.primary
                  : Colors.grey.shade200,
            ),
          );
        }
        final stepIndex = i ~/ 2;
        final isDone = stepIndex < activeIndex;
        final isActive = stepIndex == activeIndex;
        final color = isDone || isActive
            ? AppColors.primary
            : Colors.grey.shade300;

        return Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone || isActive ? color : Colors.grey.shade100,
                border: Border.all(color: color, width: 1.5),
              ),
              child: isDone
                  ? const Icon(Icons.check_rounded,
                      size: 12, color: Colors.white)
                  : isActive
                      ? Center(
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                            ),
                          ),
                        )
                      : null,
            ),
            const SizedBox(height: 4),
            Text(
              steps[stepIndex],
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive
                    ? AppColors.textDark
                    : AppColors.textGrey,
              ),
            ),
          ],
        );
      }),
    );
  }
}
