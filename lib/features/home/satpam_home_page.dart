import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/services/sos_service.dart';
import '../../core/services/sos_notification_service.dart';
import '../../core/services/bantuan_service.dart';
import '../auth/auth_repository.dart';
import '../security/data/security_repository.dart';
import '../../shared/widgets/satpam_bottom_nav.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model — Activity Feed
// ─────────────────────────────────────────────────────────────────────────────
class _FeedItem {
  const _FeedItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.sublabel,
    required this.dt,
  });
  final IconData icon;
  final Color    iconBg;
  final Color    iconColor;
  final String   label;
  final String   sublabel;
  final DateTime dt;

  String get waktu {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours   < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────
class SatpamHomePage extends StatefulWidget {
  const SatpamHomePage({super.key});

  @override
  State<SatpamHomePage> createState() => _SatpamHomePageState();
}

class _SatpamHomePageState extends State<SatpamHomePage> {
  static const double _contentMaxWidth = 600.0;

  // ── Firestore stream SOS/CALL aktif ──────────────────────────────────────
  StreamSubscription<List<SosAlert>>? _alertSub;
  List<SosAlert> _activeAlerts = [];
  final Set<String> _notifiedIds = {};

  // ── Firestore stream bantuanrequest aktif ─────────────────────────────────
  StreamSubscription<List<BantuanRequest>>? _bantuanSub;
  List<BantuanRequest> _activeBantuan = [];
  final Set<String> _notifiedBantuanIds = {};

  // ── Timer repeat notifikasi SOS PENDING ──────────────────────────────────
  Timer? _repeatTimer;

  // ── Audio player SOS (loop) ───────────────────────────────────────────────
  final AudioPlayer _audioPlayer = AudioPlayer();

  // ── Audio player bantuan (one-shot) ──────────────────────────────────────
  final AudioPlayer _bantuanPlayer = AudioPlayer();

  // ── Firestore stream patroli aktif ───────────────────────────────────────
  StreamSubscription<QuerySnapshot>? _patroliSub;
  int _activePatrols = 0;

  // ── Status bertugas ───────────────────────────────────────────────────────
  bool _isOnDuty     = false;
  bool _loadingDuty  = true;
  bool _savingDuty   = false;

  // ── Firestore stream insiden aktif ───────────────────────────────────────
  StreamSubscription<QuerySnapshot>? _insidenSub;
  int _insidenAktif = 0;

  // ── Stats tamu hari ini (dari Firestore) ─────────────────────────────────
  int _tamuHariIni = 0;
  StreamSubscription<QuerySnapshot>? _tamuSub;

  // ── Feed aktivitas terkini ────────────────────────────────────────────────
  List<QueryDocumentSnapshot> _feedSosDocs     = [];
  List<QueryDocumentSnapshot> _feedBantuanDocs = [];
  List<QueryDocumentSnapshot> _feedPatroliDocs = [];
  List<QueryDocumentSnapshot> _feedTamuDocs    = [];
  StreamSubscription<QuerySnapshot>? _feedSosSub;
  StreamSubscription<QuerySnapshot>? _feedBantuanSub;
  StreamSubscription<QuerySnapshot>? _feedPatroliSub;
  StreamSubscription<QuerySnapshot>? _feedTamuSub;

  // ── Feed items getter — gabungkan 4 koleksi, sort by dt desc, limit 10 ──
  List<_FeedItem> get _feedItems {
    DateTime _ts(dynamic v) =>
        v is Timestamp ? v.toDate() : DateTime.now();

    final items = <_FeedItem>[];

    for (final doc in _feedSosDocs) {
      final d    = doc.data() as Map<String, dynamic>;
      final type = d['type'] as String? ?? '';
      final isSos = type.toUpperCase() == 'SOS';
      items.add(_FeedItem(
        icon      : isSos ? Icons.emergency_rounded : Icons.notifications_active_outlined,
        iconBg    : isSos ? const Color(0xFFFFEBEE) : const Color(0xFFE3F0FF),
        iconColor : isSos ? const Color(0xFFD32F2F) : const Color(0xFF1173D4),
        label     : isSos ? 'SOS Darurat' : 'Panggil Satpam',
        sublabel  : 'Blok ${d['blok'] ?? '-'} – ${d['namaWarga'] ?? '-'}',
        dt        : _ts(d['createdAt']),
      ));
    }

    for (final doc in _feedBantuanDocs) {
      final d = doc.data() as Map<String, dynamic>;
      items.add(_FeedItem(
        icon      : Icons.support_agent_rounded,
        iconBg    : const Color(0xFFFFF3E0),
        iconColor : const Color(0xFFE65100),
        label     : 'Bantuan: ${d['kategori'] ?? '-'}',
        sublabel  : '${d['namaWarga'] ?? '-'} – Blok ${d['blok'] ?? '-'}',
        dt        : _ts(d['createdAt']),
      ));
    }

    for (final doc in _feedPatroliDocs) {
      final d      = doc.data() as Map<String, dynamic>;
      final status = d['status'] as String? ?? '';
      final selesai = status == 'SELESAI';
      items.add(_FeedItem(
        icon      : selesai ? Icons.check_circle_outline : Icons.shield_outlined,
        iconBg    : selesai ? const Color(0xFFE8F5E9) : const Color(0xFFE3F0FF),
        iconColor : selesai ? const Color(0xFF2E7D32) : const Color(0xFF1173D4),
        label     : selesai ? 'Patroli Selesai' : 'Patroli Dimulai',
        sublabel  : '${d['blokPatroli'] ?? '-'} – ${d['namaSatpam'] ?? '-'}',
        dt        : _ts(d['createdAt']),
      ));
    }

    for (final doc in _feedTamuDocs) {
      final d = doc.data() as Map<String, dynamic>;
      items.add(_FeedItem(
        icon      : Icons.person_add_outlined,
        iconBg    : const Color(0xFFEDE7F6),
        iconColor : const Color(0xFF512DA8),
        label     : 'Tamu: ${d['namaTamu'] ?? '-'}',
        sublabel  : 'Blok ${d['blokTujuan'] ?? '-'} – No. ${d['nomorRumahTujuan'] ?? '-'}',
        dt        : _ts(d['createdAt']),
      ));
    }

    items.sort((a, b) => b.dt.compareTo(a.dt));
    return items.take(50).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadDutyStatus();
    _startListeningSos();
    _startListeningBantuan();
    _startListeningPatroli();
    _startListeningInsiden();
    _startListeningTamu();
    _startListeningFeed();
  }

  // ── Load status isOnDuty dari Firestore ──────────────────────────────────
  Future<void> _loadDutyStatus() async {
    final uid = SecurityRepository.instance.currentSatpamUidOrNull;
    if (uid == null) { setState(() => _loadingDuty = false); return; }
    try {
      final data = await SecurityRepository.instance.fetchUser(uid);
      final onDuty = (data?['isOnDuty'] as bool?) ?? false;
      if (mounted) setState(() { _isOnDuty = onDuty; _loadingDuty = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingDuty = false);
    }
  }

  // ── Toggle status bertugas ────────────────────────────────────────────────
  Future<void> _toggleDuty(bool value) async {
    final uid = SecurityRepository.instance.currentSatpamUidOrNull;
    if (uid == null || _savingDuty) return;
    setState(() { _savingDuty = true; _isOnDuty = value; });
    try {
      await SecurityRepository.instance.setOnDuty(uid, value);
    } catch (_) {
      // Revert jika gagal
      if (mounted) setState(() => _isOnDuty = !value);
    } finally {
      if (mounted) setState(() => _savingDuty = false);
    }
  }

  void _startListeningSos() {
    _alertSub = SosService.watchActiveAlerts().listen(
      (alerts) async {
        // setState dulu agar kartu SOS muncul segera
        if (mounted) setState(() => _activeAlerts = alerts);

        // Deteksi alert baru yang belum diberi notif
        for (final alert in alerts) {
          if (!_notifiedIds.contains(alert.id)) {
            _notifiedIds.add(alert.id);
            HapticFeedback.heavyImpact();
            try {
              if (alert.type == SosType.sos) {
                await SosNotificationService.showSosNotification(alert);
              } else {
                await SosNotificationService.showCallNotification(alert);
              }
            } catch (_) {}
          }
        }

        // Kelola dering berdasarkan ada/tidaknya alert PENDING
        final hasPending = alerts.any((a) => a.status == SosStatus.pending);
        if (hasPending && _repeatTimer == null) {
          try {
            await _audioPlayer.setReleaseMode(ReleaseMode.loop);
            await _audioPlayer.setVolume(1.0);
            await _audioPlayer
                .play(AssetSource('sounds/alarm_ringtone_sos.mp3'));
          } catch (_) {}
          _repeatTimer = Timer.periodic(const Duration(seconds: 3), (_) {
            final stillPending =
                _activeAlerts.any((a) => a.status == SosStatus.pending);
            if (!stillPending) {
              _stopRinging();
              return;
            }
            HapticFeedback.heavyImpact();
          });
        } else if (!hasPending) {
          _stopRinging();
        }
      },
      onError: (e) {
        debugPrint('[SosStream] error: $e');
      },
    );
  }

  void _stopRinging() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
    _audioPlayer.stop();
  }

  // ── Stream bantuan non-SOS ─────────────────────────────────────────────────
  void _startListeningBantuan() {
    _bantuanSub = BantuanService.watchActiveRequests().listen(
      (list) async {
        // setState dulu agar kartu muncul, BARU mainkan suara
        if (mounted) setState(() => _activeBantuan = list);

        for (final req in list) {
          if (!_notifiedBantuanIds.contains(req.id)) {
            _notifiedBantuanIds.add(req.id);
            HapticFeedback.mediumImpact();
            // Bungkus audio dalam try-catch agar tidak menghentikan alur
            try {
              await _bantuanPlayer.setReleaseMode(ReleaseMode.release);
              await _bantuanPlayer.setVolume(1.0);
              await _bantuanPlayer
                  .play(AssetSource('sounds/notification.mp3'));
            } catch (_) {
              // Audio gagal tidak boleh memblokir update UI
            }
          }
        }
      },
      onError: (e) {
        // Tangkap error Firestore (misal rules belum diset)
        debugPrint('[BantuanStream] error: $e');
      },
    );
  }

  // ── Stream patroli aktif (semua satpam) ──────────────────────────────────
  void _startListeningPatroli() {
    _patroliSub = SecurityRepository.instance.patroliAktifStream().listen(
          (snap) {
            if (mounted) setState(() => _activePatrols = snap.docs.length);
          },
          onError: (e) => debugPrint('[PatroliStream] error: $e'),
        );
  }

  // ── Stream insiden aktif (status == 'BARU') ──────────────────────────────
  void _startListeningInsiden() {
    _insidenSub = SecurityRepository.instance.insidenBaruStream().listen(
          (snap) {
            if (mounted) setState(() => _insidenAktif = snap.docs.length);
          },
          onError: (e) => debugPrint('[InsidenStream] error: $e'),
        );
  }

  // ── Stream tamu hari ini dari catatantamu ────────────────────────────────
  void _startListeningTamu() {
    final now   = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end   = start.add(const Duration(days: 1));

    _tamuSub = SecurityRepository.instance.tamuRentangStream(start, end).listen(
          (snap) {
            if (mounted) setState(() => _tamuHariIni = snap.docs.length);
          },
          onError: (e) => debugPrint('[TamuStream] error: $e'),
        );
  }

  // ── Stream feed aktivitas terkini ─────────────────────────────────────────
  void _startListeningFeed() {
    final repo = SecurityRepository.instance;

    _feedSosSub = repo.sosTerbaruStream(limit: 5).listen((snap) {
      if (mounted) setState(() => _feedSosDocs = snap.docs);
    }, onError: (_) {});

    _feedBantuanSub = repo.bantuanTerbaruStream(limit: 5).listen((snap) {
      if (mounted) setState(() => _feedBantuanDocs = snap.docs);
    }, onError: (_) {});

    _feedPatroliSub = repo.patroliTerbaruStream(limit: 5).listen((snap) {
      if (mounted) setState(() => _feedPatroliDocs = snap.docs);
    }, onError: (_) {});

    _feedTamuSub = repo.tamuTerbaruStream(limit: 5).listen((snap) {
      if (mounted) setState(() => _feedTamuDocs = snap.docs);
    }, onError: (_) {});
  }

  Future<void> _onBantuanOnMyWay(BantuanRequest req) async {
    HapticFeedback.mediumImpact();
    await _bantuanPlayer.stop();
    final uid = SecurityRepository.instance.currentSatpamUidOrNull;
    await BantuanService.updateStatus(
      requestId: req.id,
      status: BantuanStatus.onMyWay,
      respondedBy: uid,
    );
  }

  Future<void> _onBantuanResolved(BantuanRequest req) async {
    HapticFeedback.mediumImpact();
    await BantuanService.updateStatus(
      requestId: req.id,
      status: BantuanStatus.resolved,
    );
  }

  @override
  void dispose() {
    _alertSub?.cancel();
    _bantuanSub?.cancel();
    _patroliSub?.cancel();
    _insidenSub?.cancel();
    _tamuSub?.cancel();
    _feedSosSub?.cancel();
    _feedBantuanSub?.cancel();
    _feedPatroliSub?.cancel();
    _feedTamuSub?.cancel();
    _stopRinging();
    _audioPlayer.dispose();
    _bantuanPlayer.dispose();
    super.dispose();
  }

  Future<void> _onMyWay(SosAlert alert) async {
    HapticFeedback.heavyImpact();
    // Stop dering langsung tanpa tunggu Firestore callback
    _stopRinging();
    final uid = SecurityRepository.instance.currentSatpamUidOrNull;
    await SosService.updateStatus(
      alertId: alert.id,
      status: SosStatus.onMyWay,
      respondedBy: uid,
    );
    // Batalkan notif setelah direspons
    if (alert.type == SosType.sos) {
      await SosNotificationService.cancelSosNotification();
    } else {
      await SosNotificationService.cancelCallNotification();
    }
  }

  Future<void> _onResolved(SosAlert alert) async {
    HapticFeedback.mediumImpact();
    await SosService.updateStatus(
      alertId: alert.id,
      status: SosStatus.resolved,
    );
  }

  @override
  Widget build(BuildContext context) {
    final namaUser =
        AuthRepository.currentUser?.namaLengkap.split(' ').first ?? 'Satpam';

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
                constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top,
                    bottom: 100,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Top Bar ─────────────────────────────────────
                      _TopBar(
                        namaUser  : namaUser,
                        photoUrl  : AuthRepository.currentUser?.photoUrl,
                        isOnDuty  : _isOnDuty,
                        isLoading : _loadingDuty,
                        isSaving  : _savingDuty,
                        onToggle  : _toggleDuty,
                      ),

                      const SizedBox(height: 16),

                      // ── SOS / CALL Alert Cards (realtime Firestore) ───
                      if (_activeAlerts.isNotEmpty) ...[
                        ..._activeAlerts.map((alert) => Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                          child: _SosAlertCard(
                            alert: alert,
                            onOnMyWay: alert.status == SosStatus.pending
                                ? () => _onMyWay(alert)
                                : null,
                            onResolved: alert.status == SosStatus.onMyWay
                                ? () => _onResolved(alert)
                                : null,
                          ),
                        )),
                        const SizedBox(height: 4),
                      ],

                      // ── Laporan Warga Card ────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: _LaporanWargaCard(
                          count: _activeBantuan.length,
                          onTap: () => Navigator.pushNamed(
                              context, AppRouter.satpamLaporan),
                        ),
                      ),

                      // ── Stats Grid ───────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _StatsGrid(
                          activePatrols: _activePatrols,
                          tamuHariIni: _tamuHariIni,
                          insidenAktif: _insidenAktif,
                          onTamuTap: () => Navigator.pushNamed(
                              context, AppRouter.satpamDaftarTamu),
                          onInsidenTap: () => Navigator.pushNamed(
                              context, AppRouter.satpamInsiden),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Quick Actions ────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _QuickActions(
                          onMulaiPatroli: () {
                            HapticFeedback.mediumImpact();
                            Navigator.pushNamed(context, AppRouter.satpamPatroli);
                          },
                          onCatatTamu: () {
                            HapticFeedback.mediumImpact();
                            Navigator.pushNamed(context, AppRouter.satpamCatatTamu);
                          },
                          onLaporInsiden: () {
                            HapticFeedback.mediumImpact();
                            Navigator.pushNamed(context, AppRouter.satpamReports);
                          },
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Recent Activity ──────────────────────────────
                      _RecentActivitySection(items: _feedItems),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),

            // ── Bottom Nav ───────────────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SatpamBottomNav(currentIndex: 0),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top Bar
// ─────────────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.namaUser,
    this.photoUrl,
    required this.isOnDuty,
    required this.isLoading,
    required this.isSaving,
    required this.onToggle,
  });

  final String             namaUser;
  final String?            photoUrl;
  final bool               isOnDuty;
  final bool               isLoading;
  final bool               isSaving;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    const activeColor   = Color(0xFF16A34A);
    const inactiveColor = Color(0xFF94A3B8);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                ? NetworkImage(photoUrl!)
                : null,
            child: (photoUrl == null || photoUrl!.isEmpty)
                ? Text(
                    namaUser.isNotEmpty ? namaUser[0].toUpperCase() : '?',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          // Nama
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selamat bertugas,',
                style: GoogleFonts.inter(
                    fontSize: 12, color: const Color(0xFF94A3B8)),
              ),
              Text(
                namaUser,
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0D1B2A),
                ),
              ),
            ],
          ),
          const Spacer(),
          // Status bertugas — kompak di kanan
          if (isLoading)
            const SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isOnDuty
                    ? activeColor.withValues(alpha: 0.1)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isOnDuty
                      ? activeColor.withValues(alpha: 0.35)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dot
                  Container(
                    width: 7, height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOnDuty ? activeColor : inactiveColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isOnDuty ? 'Bertugas' : 'Off Duty',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isOnDuty ? activeColor : inactiveColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    height: 24,
                    child: Transform.scale(
                      scale: 0.75,
                      child: Switch(
                        value            : isOnDuty,
                        onChanged        : isSaving ? null : onToggle,
                        activeColor      : activeColor,
                        activeTrackColor : activeColor.withValues(alpha: 0.3),
                        inactiveThumbColor : inactiveColor,
                        inactiveTrackColor : inactiveColor.withValues(alpha: 0.2),
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
// SOS / CALL Alert Card — realtime dari Firestore
// ─────────────────────────────────────────────────────────────────────────────
class _SosAlertCard extends StatelessWidget {
  const _SosAlertCard({
    required this.alert,
    this.onOnMyWay,
    this.onResolved,
  });
  final SosAlert alert;
  final VoidCallback? onOnMyWay;
  final VoidCallback? onResolved;

  bool get _isSos => alert.type == SosType.sos;

  List<Color> get _gradientColors => _isSos
      ? const [Color(0xFFD32F2F), Color(0xFFB71C1C)]
      : const [Color(0xFF1565C0), Color(0xFF0D47A1)];

  Color get _shadowColor =>
      _isSos ? Colors.red : const Color(0xFF1565C0);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _gradientColors,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _shadowColor.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: badge + status ──────────────────────────────────────
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.circle, size: 7, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(
                      _isSos ? 'SOS DARURAT' : 'PANGGIL SATPAM',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  alert.status == SosStatus.pending
                      ? 'PENDING'
                      : 'ON MY WAY',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Lokasi warga ────────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.location_on,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.namaWarga,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Blok ${alert.blok} – Unit ${alert.nomorUnit}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Tombol aksi sesuai status ───────────────────────────────────
          if (onOnMyWay != null)
            _ActionButton(
              label: 'ON MY WAY',
              icon: Icons.directions_walk_rounded,
              color: _isSos ? const Color(0xFFD32F2F) : const Color(0xFF1565C0),
              onTap: onOnMyWay!,
            ),

          if (onResolved != null)
            _ActionButton(
              label: 'SELESAI / RESOLVED',
              icon: Icons.check_circle_outline_rounded,
              color: const Color(0xFF2E7D32),
              onTap: onResolved!,
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
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
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bantuan Request Card — warna oranye, beda dari SOS merah/biru
// ─────────────────────────────────────────────────────────────────────────────
class _BantuanRequestCard extends StatelessWidget {
  const _BantuanRequestCard({
    required this.request,
    this.onOnMyWay,
    this.onResolved,
  });
  final BantuanRequest request;
  final VoidCallback? onOnMyWay;
  final VoidCallback? onResolved;

  static const _gradientColors = [Color(0xFFE65100), Color(0xFFBF360C)];
  static const _shadowColor = Color(0xFFE65100);

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
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _gradientColors,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _shadowColor.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: badge tipe + status ────────────────────────────────
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_kategoriIcon, size: 12, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(
                      'BANTUAN WARGA',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  request.status == BantuanStatus.pending
                      ? 'PENDING'
                      : 'ON MY WAY',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Info warga + kategori ──────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_kategoriIcon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.kategori,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${request.namaWarga}  •  Blok ${request.blok} – Unit ${request.nomorUnit}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Catatan (jika ada) ─────────────────────────────────────────
          if (request.catatan.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes_rounded,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.8)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      request.catatan,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // ── Tombol aksi ────────────────────────────────────────────────
          if (onOnMyWay != null)
            _ActionButton(
              label: 'ON MY WAY',
              icon: Icons.directions_walk_rounded,
              color: const Color(0xFFE65100),
              onTap: onOnMyWay!,
            ),

          if (onResolved != null)
            _ActionButton(
              label: 'SELESAI / RESOLVED',
              icon: Icons.check_circle_outline_rounded,
              color: const Color(0xFF2E7D32),
              onTap: onResolved!,
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Laporan Warga Card — single card dengan badge count, tap → SatpamLaporanPage
// ─────────────────────────────────────────────────────────────────────────────
class _LaporanWargaCard extends StatelessWidget {
  const _LaporanWargaCard({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE65100), Color(0xFFBF360C)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE65100).withValues(alpha: 0.3),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Laporan Warga',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    count > 0
                        ? '$count laporan menunggu tindakan'
                        : 'Tidak ada laporan aktif',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            // Badge count
            if (count > 0)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFE65100),
                  ),
                ),
              ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats Grid: 2x2
// ─────────────────────────────────────────────────────────────────────────────
class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.activePatrols,
    required this.tamuHariIni,
    required this.insidenAktif,
    required this.onTamuTap,
    required this.onInsidenTap,
  });
  final int activePatrols;
  final int tamuHariIni;
  final int insidenAktif;
  final VoidCallback onTamuTap;
  final VoidCallback onInsidenTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Row 1: Patroli + Tamu
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.route_outlined,
                iconColor: AppColors.primary,
                iconBg: const Color(0xFFE3F0FF),
                label: 'PATROLI AKTIF',
                value: '$activePatrols',
                valueLabel: 'Online',
                valueColor: AppColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _StatCard(
                icon: Icons.people_outline,
                iconColor: const Color(0xFF512DA8),
                iconBg: const Color(0xFFEDE7F6),
                label: 'TAMU HARI INI',
                value: '$tamuHariIni',
                valueLabel: 'Orang',
                valueColor: const Color(0xFF0D1B2A),
                onTap: onTamuTap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Row 2: Insiden full-width
        _StatCard(
          icon: Icons.warning_amber_rounded,
          iconColor: const Color(0xFFD32F2F),
          iconBg: const Color(0xFFFFEBEE),
          label: 'INSIDEN AKTIF',
          value: '$insidenAktif',
          valueLabel: 'Kasus',
          valueColor: insidenAktif > 0
              ? const Color(0xFFD32F2F)
              : const Color(0xFF2E7D32),
          onTap: onInsidenTap,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    required this.valueLabel,
    required this.valueColor,
    this.onTap,
  });
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;
  final String valueLabel;
  final Color valueColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF94A3B8),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: valueColor,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      valueLabel,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(Icons.chevron_right_rounded,
                size: 16, color: Color(0xFFB0BEC5)),
        ],
      ),
    );

    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, child: card);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Actions
// ─────────────────────────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onMulaiPatroli,
    required this.onCatatTamu,
    required this.onLaporInsiden,
  });
  final VoidCallback onMulaiPatroli;
  final VoidCallback onCatatTamu;
  final VoidCallback onLaporInsiden;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aksi Cepat',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0D1B2A),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Mulai Patroli — primary, lebih besar
            Expanded(
              flex: 5,
              child: _QuickActionPrimary(
                icon: Icons.shield_outlined,
                label: 'Mulai\nPatroli',
                colors: const [Color(0xFF1E6FD9), Color(0xFF1173D4)],
                shadowColor: AppColors.primary,
                onTap: onMulaiPatroli,
              ),
            ),
            const SizedBox(width: 12),
            // Kolom kanan: 2 tombol kecil
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  _QuickActionSecondary(
                    icon: Icons.person_add_outlined,
                    label: 'Catat Tamu',
                    iconBg: const Color(0xFFEDE7F6),
                    iconColor: const Color(0xFF512DA8),
                    onTap: onCatatTamu,
                  ),
                  const SizedBox(height: 10),
                  _QuickActionSecondary(
                    icon: Icons.report_problem_outlined,
                    label: 'Lapor Insiden',
                    iconBg: const Color(0xFFFFEBEE),
                    iconColor: const Color(0xFFD32F2F),
                    onTap: onLaporInsiden,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionPrimary extends StatelessWidget {
  const _QuickActionPrimary({
    required this.icon,
    required this.label,
    required this.colors,
    required this.shadowColor,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final List<Color> colors;
  final Color shadowColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withValues(alpha: 0.3),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Lingkaran dekoratif
            Positioned(
              right: -16,
              top: -16,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: -20,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            // Konten
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    child: Icon(icon, color: Colors.white, size: 26),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                      height: 1.3,
                    ),
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

class _QuickActionSecondary extends StatelessWidget {
  const _QuickActionSecondary({
    required this.icon,
    required this.label,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0D1B2A),
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: Color(0xFFB0BEC5),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recent Activity Section — 5 teratas, expand untuk lihat semua
// ─────────────────────────────────────────────────────────────────────────────
class _RecentActivitySection extends StatefulWidget {
  const _RecentActivitySection({required this.items});
  final List<_FeedItem> items;

  @override
  State<_RecentActivitySection> createState() => _RecentActivitySectionState();
}

class _RecentActivitySectionState extends State<_RecentActivitySection> {
  static const int _pageSize = 5;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final total    = widget.items.length;
    final visible  = _expanded ? total : total.clamp(0, _pageSize);
    final shown    = widget.items.take(visible).toList();
    final remaining = total - _pageSize;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Aktivitas Terkini',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0D1B2A),
                ),
              ),
              if (total > 0)
                Text(
                  '$total aktivitas',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: const Color(0xFF94A3B8)),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Empty state ──────────────────────────────────────────────────
          if (total == 0)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.history_rounded,
                        size: 36, color: Colors.grey.shade300),
                    const SizedBox(height: 8),
                    Text(
                      'Belum ada aktivitas.',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: const Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
            )
          else
            // ── List card ────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  ...List.generate(shown.length, (i) {
                    final isLastItem = i == shown.length - 1 &&
                        (_expanded || total <= _pageSize);
                    return _AktivitasTile(
                      item: shown[i],
                      isLast: isLastItem,
                    );
                  }),

                  // ── Footer expand / collapse ─────────────────────────
                  if (total > _pageSize)
                    GestureDetector(
                      onTap: () => setState(() => _expanded = !_expanded),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                                color: Colors.grey.shade100, width: 1),
                          ),
                          borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(16)),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _expanded
                                  ? 'Sembunyikan'
                                  : 'Lihat $remaining lainnya',
                              style: GoogleFonts.inter(
                                fontSize: 13,
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
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AktivitasTile extends StatelessWidget {
  const _AktivitasTile({required this.item, required this.isLast});
  final _FeedItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: item.iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: item.iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.label,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0D1B2A),
                        )),
                    const SizedBox(height: 2),
                    Text(item.sublabel,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: const Color(0xFF94A3B8)),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(item.waktu,
                  style: GoogleFonts.inter(
                      fontSize: 11, color: const Color(0xFF94A3B8))),
            ],
          ),
        ),
        if (!isLast)
          Divider(height: 1, indent: 72, endIndent: 16,
              color: Colors.grey.shade100),
      ],
    );
  }
}

