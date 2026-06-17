import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/bantuan_service.dart';
import '../../shared/widgets/bottom_nav_bar.dart';
import '../../core/router/app_router.dart';
import '../auth/auth_repository.dart';
import '../admin/models/berita_doc.dart';
import '../berita/data/berita_repository.dart';
import 'data/home_repository.dart';
import '../berita/berita_detail_page.dart';
import '../berita/berita_list_page.dart';
import '../pembayaran/payment_repository.dart';
import '../pembayaran/tagihan_model.dart';
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

  StreamSubscription<BantuanRequest?>? _bantuanSub;
  BantuanRequest? _activeBantuan;

  // Berita dari Firestore
  List<BeritaDoc> _beritaList = [];
  bool _beritaLoading = true;

  // ── Feed aktivitas terkini ────────────────────────────────────────────────
  List<QueryDocumentSnapshot> _feedKeluhanDocs  = [];
  List<QueryDocumentSnapshot> _feedBantuanDocs  = [];
  List<QueryDocumentSnapshot> _feedTamuDocs     = [];
  List<QueryDocumentSnapshot> _feedInsidenDocs  = [];
  List<QueryDocumentSnapshot> _feedPatroliDocs  = [];

  StreamSubscription<QuerySnapshot>? _feedKeluhanSub;
  StreamSubscription<QuerySnapshot>? _feedBantuanSub;
  StreamSubscription<QuerySnapshot>? _feedTamuSub;
  StreamSubscription<QuerySnapshot>? _feedInsidenSub;
  StreamSubscription<QuerySnapshot>? _feedPatroliSub;

  @override
  void initState() {
    super.initState();
    _startListeningBantuan();
    _loadBerita();
    _startListeningFeed();
  }

  void _startListeningBantuan() {
    final uid = AuthRepository.currentUid;
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
      // Ambil 3 berita published teratas via repository
      final published = await BeritaRepository.instance.fetchPublished();
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

  void _startListeningFeed() {
    final uid  = AuthRepository.currentUid;
    final user = AuthRepository.currentUser;
    if (uid == null) return;

    final repo = HomeRepository.instance;

    // 1. Keluhan milik user (sort client-side, no composite index needed)
    _feedKeluhanSub = repo
        .keluhanByUidStream(uid)
        .listen((s) => setState(() => _feedKeluhanDocs = s.docs));

    // 2. Bantuan request milik user
    _feedBantuanSub = repo
        .bantuanByUidStream(uid)
        .listen((s) => setState(() => _feedBantuanDocs = s.docs));

    // 3. Tamu yang masuk ke unit user
    if (user != null) {
      _feedTamuSub = repo
          .tamuByUnitStream(user.blok, user.nomorUnit)
          .listen((s) => setState(() => _feedTamuDocs = s.docs));
    }

    // 4. Insiden terbaru di lingkungan (info umum)
    _feedInsidenSub = repo
        .insidenTerbaruStream(limit: 5)
        .listen((s) => setState(() => _feedInsidenDocs = s.docs));

    // 5. Patroli selesai terbaru (info keamanan)
    _feedPatroliSub = repo
        .patroliSelesaiStream(limit: 5)
        .listen((s) => setState(() => _feedPatroliDocs = s.docs));
  }

  List<_FeedItem> get _feedItems {
    final items = <_FeedItem>[];

    DateTime toDate(dynamic ts) {
      if (ts is Timestamp) return ts.toDate();
      return DateTime.now();
    }

    // Keluhan
    for (final doc in _feedKeluhanDocs) {
      final d = doc.data() as Map<String, dynamic>;
      final status = d['status'] as String? ?? 'MENUNGGU';
      Color iconColor;
      switch (status) {
        case 'SELESAI': iconColor = Colors.green.shade600; break;
        case 'DITOLAK': iconColor = Colors.red.shade600;   break;
        case 'DIPROSES': iconColor = Colors.blue.shade600; break;
        default: iconColor = Colors.orange.shade600;
      }
      items.add(_FeedItem(
        icon     : Icons.report_problem_outlined,
        iconBg   : iconColor.withValues(alpha: 0.12),
        iconColor: iconColor,
        label    : 'Keluhan: ${d['judul'] ?? d['kategori'] ?? '-'}',
        sublabel : 'Status: $status',
        dt       : toDate(d['createdAt']),
        badgeLabel: status,
        badgeColor: iconColor,
      ));
    }

    // Bantuan request
    for (final doc in _feedBantuanDocs) {
      final d = doc.data() as Map<String, dynamic>;
      final status = d['status'] as String? ?? 'PENDING';
      Color iconColor;
      switch (status) {
        case 'RESOLVED':  iconColor = Colors.green.shade600; break;
        case 'ON_MY_WAY': iconColor = Colors.blue.shade600;  break;
        case 'CANCELLED': iconColor = Colors.grey.shade500;  break;
        default:          iconColor = Colors.red.shade600;
      }
      final statusLabel = status == 'ON_MY_WAY'  ? 'Menuju Lokasi'
                        : status == 'RESOLVED'   ? 'Selesai'
                        : status == 'CANCELLED'  ? 'Dibatalkan'
                        : 'Menunggu';
      items.add(_FeedItem(
        icon     : Icons.support_agent_rounded,
        iconBg   : iconColor.withValues(alpha: 0.12),
        iconColor: iconColor,
        label    : 'Bantuan: ${d['kategori'] ?? '-'}',
        sublabel : 'Status: $statusLabel',
        dt       : toDate(d['createdAt']),
        badgeLabel: statusLabel,
        badgeColor: iconColor,
      ));
    }

    // Tamu masuk ke unit
    for (final doc in _feedTamuDocs) {
      final d = doc.data() as Map<String, dynamic>;
      final status = d['status'] as String? ?? 'MASUK';
      items.add(_FeedItem(
        icon     : Icons.person_outline_rounded,
        iconBg   : const Color(0xFFEDE9FE),
        iconColor: const Color(0xFF7C3AED),
        label    : 'Tamu: ${d['namaTamu'] ?? '-'}',
        sublabel : 'Tujuan: ${d['tujuan'] ?? '-'}',
        dt       : toDate(d['createdAt']),
        badgeLabel: status,
        badgeColor: status == 'KELUAR'
            ? Colors.grey.shade500
            : const Color(0xFF7C3AED),
      ));
    }

    // Insiden
    for (final doc in _feedInsidenDocs) {
      final d = doc.data() as Map<String, dynamic>;
      final status = d['status'] as String? ?? 'BARU';
      Color iconColor;
      switch (status) {
        case 'SELESAI':   iconColor = Colors.green.shade600;  break;
        case 'DITANGANI': iconColor = Colors.orange.shade600; break;
        default:          iconColor = Colors.red.shade600;
      }
      items.add(_FeedItem(
        icon     : Icons.warning_amber_rounded,
        iconBg   : iconColor.withValues(alpha: 0.12),
        iconColor: iconColor,
        label    : 'Insiden: ${d['kategori'] ?? '-'}',
        sublabel : 'Blok ${d['blok'] ?? '-'} No. ${d['nomor'] ?? '-'}',
        dt       : toDate(d['createdAt'] ?? d['waktuKejadian']),
        badgeLabel: status,
        badgeColor: iconColor,
      ));
    }

    // Patroli selesai
    for (final doc in _feedPatroliDocs) {
      final d = doc.data() as Map<String, dynamic>;
      final petugas = d['namaSatpam'] as String? ?? d['petugas'] as String? ?? '-';
      items.add(_FeedItem(
        icon     : Icons.shield_outlined,
        iconBg   : Colors.green.shade50,
        iconColor: Colors.green.shade700,
        label    : 'Patroli Selesai',
        sublabel : 'Petugas: $petugas · ${d['lokasi'] ?? ''}',
        dt       : toDate(d['createdAt']),
      ));
    }

    items.sort((a, b) => b.dt.compareTo(a.dt));
    return items.toList();
  }

  @override
  void dispose() {
    _bantuanSub?.cancel();
    _feedKeluhanSub?.cancel();
    _feedBantuanSub?.cancel();
    _feedTamuSub?.cancel();
    _feedInsidenSub?.cancel();
    _feedPatroliSub?.cancel();
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
    final uid = FirebaseAuth.instance.currentUser?.uid;
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
                child: StreamBuilder<List<TagihanModel>>(
                  stream: uid == null
                      ? Stream.value(const <TagihanModel>[])
                      : PaymentRepository.watchUserTagihan(uid!),
                  builder: (context, snap) {
                    final list = snap.data ?? const <TagihanModel>[];
                    final adaUnpaid =
                        list.any((t) => t.status != StatusTagihan.lunas);
                    // Sudah lunas = punya tagihan dan semua lunas.
                    final sudahLunas = list.isNotEmpty && !adaUnpaid;
                    final aktif = list.isEmpty
                        ? null
                        : (adaUnpaid
                            ? list.firstWhere(
                                (t) => t.status != StatusTagihan.lunas)
                            : list.first);
                    final jumlahFmt =
                        aktif?.jumlahFormatted ?? 'Rp 450.000';

                    return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: MediaQuery.of(context).padding.top),

                    HomeHeader(
                      userName: namaDepan,
                      greeting: _buildGreeting(),
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
                          // Kartu tagihan — data dari Firestore
                          Expanded(
                            child: TagihanCard(
                              namaPenghuni: namaLengkap,
                              jumlahTagihan: jumlahFmt,
                              sudahLunas: sudahLunas,
                              onBayarTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRouter.tagihan,
                                );
                              },
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
                      paymentStatus: sudahLunas
                          ? PaymentStatus.paid
                          : PaymentStatus.unpaid,
                    ),

                    const SizedBox(height: 8),
                    _HomeActivitySection(items: _feedItems),
                    const SizedBox(height: 16),
                  ],
                    );
                  },
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
        border: Border.all(color: _statusColor.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _statusColor.withValues(alpha: 0.08),
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
              color: _statusColor.withValues(alpha: 0.07),
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
                    color: _statusColor.withValues(alpha: 0.1),
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
          color: widget.color.withValues(alpha: 0.4 + 0.6 * _ctrl.value),
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
          final lineIndex = i ~/ 2;
          final filled = lineIndex < activeIndex;
          return Expanded(
            child: Container(
              height: 2,
              color: filled ? AppColors.primary : Colors.grey.shade200,
            ),
          );
        }
        final stepIndex = i ~/ 2;
        final isDone   = stepIndex < activeIndex;
        final isActive = stepIndex == activeIndex;
        final color    = isDone || isActive
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
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? AppColors.textDark : AppColors.textGrey,
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feed item model
// ─────────────────────────────────────────────────────────────────────────────

class _FeedItem {
  const _FeedItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.sublabel,
    required this.dt,
    this.badgeLabel,
    this.badgeColor,
  });

  final IconData icon;
  final Color    iconBg;
  final Color    iconColor;
  final String   label;
  final String   sublabel;
  final DateTime dt;
  final String?  badgeLabel;
  final Color?   badgeColor;

  String get waktu {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours   < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Aktivitas Terkini Section
// ─────────────────────────────────────────────────────────────────────────────

class _HomeActivitySection extends StatefulWidget {
  const _HomeActivitySection({required this.items});
  final List<_FeedItem> items;

  @override
  State<_HomeActivitySection> createState() => _HomeActivitySectionState();
}

class _HomeActivitySectionState extends State<_HomeActivitySection> {
  static const int _pageSize = 5;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final all      = widget.items;
    final shown    = _expanded ? all : all.take(_pageSize).toList();
    final hasMore  = all.length > _pageSize;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Aktivitas Terkini',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              if (hasMore)
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Text(
                    _expanded ? 'Sembunyikan' : 'Lihat Semua',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Empty state ───────────────────────────────────────────────────
          if (all.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.history_rounded,
                        size: 36, color: Colors.grey.shade300),
                    const SizedBox(height: 8),
                    Text(
                      'Belum ada aktivitas',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.textGrey),
                    ),
                  ],
                ),
              ),
            )

          // ── List ──────────────────────────────────────────────────────────
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: List.generate(
                  shown.length,
                  (i) => _ActivityTile(
                    item  : shown[i],
                    isLast: i == shown.length - 1 && !hasMore,
                  ),
                )..addAll(
                  // Footer "lihat semua / sembunyikan" di dalam card
                  hasMore
                      ? [
                          InkWell(
                            onTap: () =>
                                setState(() => _expanded = !_expanded),
                            borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(14)),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _expanded
                                        ? 'Sembunyikan'
                                        : 'Lihat ${all.length - _pageSize} lainnya',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    _expanded
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ]
                      : const <Widget>[],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Activity Tile — satu baris item pada kartu "Aktivitas Terkini"
// (Direkonstruksi setelah file ter-truncate; sesuaikan gaya bila perlu.)
// ─────────────────────────────────────────────────────────────────────────────
class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.item, required this.isLast});

  final _FeedItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: item.iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, size: 20, color: item.iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.label,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    if (item.badgeLabel != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: (item.badgeColor ?? AppColors.primary)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item.badgeLabel!,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: item.badgeColor ?? AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.sublabel,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item.waktu,
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }
}
