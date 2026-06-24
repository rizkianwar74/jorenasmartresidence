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

// UI dipecah ke beberapa file 'part' agar file ini tak terlalu besar,
// namun tetap satu library sehingga widget privat bisa saling akses.
part 'widgets/satpam_home_cards.dart';
part 'widgets/satpam_home_sections.dart';
part 'widgets/satpam_home_activity.dart';

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
  // Snapshot mentah terakhir dari stream bantuan, dipakai untuk diproses
  // ulang saat status bertugas berubah (stream tak emit ulang sendiri).
  List<BantuanRequest> _latestBantuan = [];
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
      if (mounted) {
        setState(() { _isOnDuty = onDuty; _loadingDuty = false; });
        // Baru tahu kita sedang bertugas — proses ulang alert yang sudah
        // masuk lebih dulu (stream Firestore tidak emit ulang dengan
        // sendirinya hanya karena status duty lokal berubah).
        if (onDuty) await _processSosAlerts(_activeAlerts);
        await _processBantuan(_latestBantuan);
      }
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
      if (value) {
        // Baru ON duty — proses ulang alert aktif yang sudah ada supaya
        // tidak terlewat notifikasinya.
        await _processSosAlerts(_activeAlerts);
      } else {
        // Baru OFF duty — langsung hentikan dering kalau sedang berbunyi.
        _stopRinging();
        await _bantuanPlayer.stop();
      }
      // Sinkronkan kartu/suara bantuan dengan status terbaru.
      await _processBantuan(_latestBantuan);
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
        await _processSosAlerts(alerts);
      },
      onError: (e) {
        debugPrint('[SosStream] error: $e');
      },
    );
  }

  // ── Proses notifikasi & dering SOS — HANYA untuk satpam yang sedang
  // bertugas (isOnDuty == true). Satpam yang OFF DUTY tidak akan menerima
  // notifikasi popup maupun suara alarm sama sekali, walaupun stream
  // Firestore-nya tetap mengalir untuk semua device yang membuka halaman ini.
  Future<void> _processSosAlerts(List<SosAlert> alerts) async {
    if (!_isOnDuty) {
      // Pastikan dering berhenti kalau status berubah jadi off duty
      // sementara masih ada alert pending.
      _stopRinging();
      return;
    }

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
        if (!_isOnDuty) {
          _stopRinging();
          return;
        }
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
  }

  void _stopRinging() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
    _audioPlayer.stop();
  }

  // ── Stream bantuan non-SOS ─────────────────────────────────────────────────
  void _startListeningBantuan() {
    _bantuanSub = BantuanService.watchActiveRequests().listen(
      (list) => _processBantuan(list),
      onError: (e) {
        // Tangkap error Firestore (misal rules belum diset)
        debugPrint('[BantuanStream] error: $e');
      },
    );
  }

  // ── Proses kartu & suara bantuan — HANYA untuk satpam yang sedang bertugas.
  // Satpam OFF DUTY tidak melihat kartu maupun mendengar suara bantuan,
  // walaupun stream Firestore-nya tetap mengalir.
  Future<void> _processBantuan(List<BantuanRequest> list) async {
    _latestBantuan = list;

    if (!_isOnDuty) {
      // Off duty — kosongkan kartu bantuan kalau sebelumnya tampil.
      if (mounted && _activeBantuan.isNotEmpty) {
        setState(() => _activeBantuan = []);
      }
      return;
    }

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
