import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/data/bantuan_repository.dart';
import '../../shared/widgets/bottom_nav_bar.dart';
import '../../core/router/app_router.dart';
import '../auth/data/auth_repository.dart';
import '../berita/models/berita_doc.dart';
import '../berita/data/berita_repository.dart';
import 'data/home_repository.dart';
import '../berita/berita_detail_page.dart';
import '../berita/berita_list_page.dart';
import '../pembayaran/data/payment_repository.dart';
import '../pembayaran/models/tagihan_model.dart';
import 'widgets/home_header.dart';
import 'widgets/quick_action_card.dart';
import 'widgets/news_carousel.dart';
import 'widgets/unit_status_card.dart';
import 'models/feed_item.dart';
import 'widgets/active_bantuan_card.dart';
import 'widgets/home_activity_section.dart';
import '../security/bantuan/bantuan_status_page.dart';

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
    _ensureTagihanBulanIni();
  }

  /// Auto-generate tagihan bulan ini + isi gap bulan yang terlewat.
  Future<void> _ensureTagihanBulanIni() async {
    final uid  = AuthRepository.currentUid;
    final user = AuthRepository.currentUser;
    if (uid == null || user == null) return;
    try {
      await PaymentRepository.ensureAllMissingTagihan(
        userId     : uid,
        namaResiden: user.namaLengkap,
        nomorHp    : user.nomorHp,
        blok       : user.blok,
        nomorUnit  : user.nomorUnit,
      );
    } catch (e) {
      debugPrint('[HomeTagihan] gagal ensure tagihan: $e');
    }
  }

  void _startListeningBantuan() {
    final uid = AuthRepository.currentUid;
    if (uid == null) return;
    _bantuanSub?.cancel();
    _bantuanSub = BantuanRepository.watchMyActiveRequest(uid).listen(
      (req) {
        if (mounted) setState(() => _activeBantuan = req);
      },
      onError: (e) => debugPrint('[HomeBantuanStream] error: $e'),
      onDone: () {
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

    _feedKeluhanSub = repo
        .keluhanByUidStream(uid)
        .listen((s) => setState(() => _feedKeluhanDocs = s.docs));

    _feedBantuanSub = repo
        .bantuanByUidStream(uid)
        .listen((s) => setState(() => _feedBantuanDocs = s.docs));

    if (user != null) {
      _feedTamuSub = repo
          .tamuByUnitStream(user.blok, user.nomorUnit)
          .listen((s) => setState(() => _feedTamuDocs = s.docs));
    }

    _feedInsidenSub = repo
        .insidenTerbaruStream(limit: 5)
        .listen((s) => setState(() => _feedInsidenDocs = s.docs));

    _feedPatroliSub = repo
        .patroliSelesaiStream(limit: 5)
        .listen((s) => setState(() => _feedPatroliDocs = s.docs));
  }

  List<FeedItem> get _feedItems {
    final items = <FeedItem>[];

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
      items.add(FeedItem(
        icon: Icons.report_problem_outlined,
        iconBg: iconColor.withValues(alpha: 0.12),
        iconColor: iconColor,
        label: 'Keluhan: ${d['judul'] ?? d['kategori'] ?? '-'}',
        sublabel: 'Status: $status',
        dt: toDate(d['createdAt']),
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
      items.add(FeedItem(
        icon: Icons.support_agent_rounded,
        iconBg: iconColor.withValues(alpha: 0.12),
        iconColor: iconColor,
        label: 'Bantuan: ${d['kategori'] ?? '-'}',
        sublabel: 'Status: $statusLabel',
        dt: toDate(d['createdAt']),
        badgeLabel: statusLabel,
        badgeColor: iconColor,
      ));
    }

    // Tamu masuk ke unit
    for (final doc in _feedTamuDocs) {
      final d = doc.data() as Map<String, dynamic>;
      final status = d['status'] as String? ?? 'MASUK';
      items.add(FeedItem(
        icon: Icons.person_outline_rounded,
        iconBg: const Color(0xFFEDE9FE),
        iconColor: const Color(0xFF7C3AED),
        label: 'Tamu: ${d['namaTamu'] ?? '-'}',
        sublabel: 'Tujuan: ${d['tujuan'] ?? '-'}',
        dt: toDate(d['createdAt']),
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
      items.add(FeedItem(
        icon: Icons.warning_amber_rounded,
        iconBg: iconColor.withValues(alpha: 0.12),
        iconColor: iconColor,
        label: 'Insiden: ${d['kategori'] ?? '-'}',
        sublabel: 'Blok ${d['blok'] ?? '-'} No. ${d['nomor'] ?? '-'}',
        dt: toDate(d['createdAt'] ?? d['waktuKejadian']),
        badgeLabel: status,
        badgeColor: iconColor,
      ));
    }

    // Patroli selesai
    for (final doc in _feedPatroliDocs) {
      final d = doc.data() as Map<String, dynamic>;
      final petugas = d['namaSatpam'] as String? ?? d['petugas'] as String? ?? '-';
      items.add(FeedItem(
        icon: Icons.shield_outlined,
        iconBg: Colors.green.shade50,
        iconColor: Colors.green.shade700,
        label: 'Patroli Selesai',
        sublabel: 'Petugas: $petugas · ${d['lokasi'] ?? ''}',
        dt: toDate(d['createdAt']),
      ));
    }

    items.sort((a, b) => b.dt.compareTo(a.dt));
    return items;
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

  void _openBantuanStatus(String requestId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BantuanStatusPage(requestId: requestId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthRepository.currentUser;
    final uid = AuthRepository.currentUid;
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
              child: StreamBuilder<List<TagihanModel>>(
                stream: uid == null
                    ? Stream.value(const <TagihanModel>[])
                    : PaymentRepository.watchUserTagihan(uid),
                builder: (context, tagihanSnap) {
                  final list = tagihanSnap.data ?? const <TagihanModel>[];
                  final unpaid = list.unpaidSorted;
                  final adaUnpaid = unpaid.isNotEmpty;
                  final sudahLunas = list.isNotEmpty && !adaUnpaid;
                  final jumlahFmt = adaUnpaid
                      ? formatRupiah(list.totalUnpaid)
                      : formatRupiah(PaymentRepository.iuranBulanan);

                  return SingleChildScrollView(
                     padding: const EdgeInsets.only(bottom: 120),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         SizedBox(height: MediaQuery.of(context).padding.top),

                         HomeHeader(
                           userName: namaDepan,
                           greeting: _buildGreeting(),
                         ),

                         if (_activeBantuan != null)
                           Padding(
                             padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                             child: GestureDetector(
                               onTap: () =>
                                   _openBantuanStatus(_activeBantuan!.id),
                               child: ActiveBantuanCard(
                                 request: _activeBantuan!,
                               ),
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
                                   jumlahTagihan: jumlahFmt,
                                   sudahLunas: sudahLunas,
                                   onBayarTap: () => Navigator.pushNamed(
                                       context, AppRouter.tagihan),
                                 ),
                               ),
                               const SizedBox(width: 16),
                               Expanded(
                                 child: QuickActionCard(
                                   icon: Icons.security, // panggil satpam
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
                         HomeActivitySection(items: _feedItems),
                         const SizedBox(height: 16),
                       ],
                     ),
                  );
                },
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
