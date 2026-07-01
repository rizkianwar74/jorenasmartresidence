import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/data/sos_repository.dart';
import 'data/security_repository.dart';
import 'bantuan/bantuan_satpam_page.dart';
import 'sos_status_page.dart';
import 'widgets/sos_button.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

// ── Model satpam bertugas ─────────────────────────────────────────────────────
class _SatpamInfo {
  final String namaLengkap;
  final String nomorHp;
  _SatpamInfo({required this.namaLengkap, required this.nomorHp});
}

// ── Model unified aktivitas keamanan ─────────────────────────────────────────
class _AktivitasFeed {
  final IconData icon;
  final Color    iconColor;
  final Color    iconBg;
  final String   title;
  final String   subtitle;
  final String?  badgeLabel;   // null = tidak ada badge
  final Color?   badgeColor;
  final DateTime sortKey;

  const _AktivitasFeed({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.sortKey,
    this.badgeLabel,
    this.badgeColor,
  });
}

class _SecurityPageState extends State<SecurityPage> {
  bool _isLoading = false;

  // ── Satpam bertugas ───────────────────────────────────────────────────────
  List<_SatpamInfo>? _satpamList;
  bool _satpamLoading = true;
  StreamSubscription<QuerySnapshot>? _satpamSub;

  // ── Aktivitas gabungan ────────────────────────────────────────────────────
  List<_AktivitasFeed> _patroliItems  = [];
  List<_AktivitasFeed> _bantuanItems  = [];
  List<_AktivitasFeed> _insidenItems  = [];
  List<_AktivitasFeed> _tamuItems     = [];
  bool _aktivitasLoading = true;

  StreamSubscription<QuerySnapshot>? _patroliSub;
  StreamSubscription<QuerySnapshot>? _bantuanSub;
  StreamSubscription<QuerySnapshot>? _insidenSubA;
  StreamSubscription<QuerySnapshot>? _tamuSubA;

  List<_AktivitasFeed> get _mergedAktivitas {
    final all = [
      ..._patroliItems,
      ..._bantuanItems,
      ..._insidenItems,
      ..._tamuItems,
    ]..sort((a, b) => b.sortKey.compareTo(a.sortKey));
    return all.take(5).toList();
  }

  static const double _contentMaxWidth = 600.0;

  @override
  void initState() {
    super.initState();
    _loadSatpam();
    _startPatroliStream();
    _startBantuanStream();
    _startInsidenStream();
    _startTamuStream();
  }

  void _loadSatpam() {
    _satpamSub = SecurityRepository.instance.satpamOnDutyStream().listen(
          (snap) {
            final list = snap.docs.map((d) {
              final data = d.data();
              return _SatpamInfo(
                namaLengkap: (data['namaLengkap'] as String?)?.trim() ?? 'Satpam',
                nomorHp    : (data['nomorHp']     as String?)?.trim() ?? '-',
              );
            }).toList();
            if (mounted) setState(() { _satpamList = list; _satpamLoading = false; });
          },
          onError: (e) {
            debugPrint('[SatpamStream] error: $e');
            if (mounted) setState(() { _satpamList = []; _satpamLoading = false; });
          },
        );
  }

  // ── Helper: Timestamp → DateTime ─────────────────────────────────────────
  static DateTime _toDateTime(dynamic ts) {
    if (ts is Timestamp) return ts.toDate();
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  void _checkAktivitasLoaded() {
    // Tandai loading selesai setelah semua stream pertama kali datang
    if (_aktivitasLoading && mounted) setState(() => _aktivitasLoading = false);
  }

  // ── Stream: patroli ───────────────────────────────────────────────────────
  void _startPatroliStream() {
    _patroliSub = SecurityRepository.instance
        .patroliTerbaruStream(limit: 10)
        .listen((snap) {
      _patroliItems = snap.docs.map((doc) {
        final d          = doc.data();
        final status     = d['status'] as String? ?? '';
        final blok       = d['blokPatroli'] as String? ?? '-';
        final nama       = d['namaSatpam']  as String? ?? 'Satpam';
        final jamMulai   = d['jamMulai']    as String? ?? '';
        final jamSelesai = d['jamSelesai']  as String? ?? '';
        final isAktif    = status == 'AKTIF';
        return _AktivitasFeed(
          icon      : isAktif ? Icons.shield_outlined : Icons.security,
          iconColor : isAktif ? Colors.orange.shade700 : const Color(0xFF1A4080),
          iconBg    : isAktif ? Colors.orange.shade50  : const Color(0xFFE3F0FF),
          title     : isAktif ? 'Patroli Berlangsung · $blok' : 'Patroli Selesai · $blok',
          subtitle  : isAktif
              ? 'Mulai $jamMulai · $nama'
              : (jamSelesai.isNotEmpty ? 'Selesai $jamSelesai · $nama' : nama),
          badgeLabel: isAktif ? 'AKTIF' : null,
          badgeColor: Colors.orange.shade700,
          sortKey   : _toDateTime(d['createdAt']),
        );
      }).toList();
      _checkAktivitasLoaded();
      if (mounted) setState(() {});
    }, onError: (e) {
      debugPrint('[PatroliStream] $e');
      _checkAktivitasLoaded();
    });
  }

  // ── Stream: bantuanrequest ────────────────────────────────────────────────
  void _startBantuanStream() {
    _bantuanSub = SecurityRepository.instance
        .bantuanTerbaruStream(limit: 10)
        .listen((snap) {
      _bantuanItems = snap.docs.map((doc) {
        final d       = doc.data();
        final status  = d['status']    as String? ?? '';
        final kategori= d['kategori']  as String? ?? 'Bantuan';
        final nama    = d['namaWarga'] as String? ?? '-';
        final blok    = d['blok']      as String? ?? '-';
        final unit    = d['nomorUnit'] as String? ?? '-';
        final isPending = status == 'PENDING' || status == 'ON_MY_WAY';
        return _AktivitasFeed(
          icon      : Icons.support_agent_outlined,
          iconColor : isPending ? Colors.deepOrange : Colors.teal.shade700,
          iconBg    : isPending ? const Color(0xFFFFF3E0) : Colors.teal.shade50,
          title     : 'Bantuan: $kategori',
          subtitle  : '$nama · Blok $blok No. $unit',
          badgeLabel: isPending ? status : null,
          badgeColor: Colors.deepOrange,
          sortKey   : _toDateTime(d['createdAt']),
        );
      }).toList();
      if (mounted) setState(() {});
    }, onError: (e) => debugPrint('[BantuanStream] $e'));
  }

  // ── Stream: insiden ───────────────────────────────────────────────────────
  void _startInsidenStream() {
    _insidenSubA = SecurityRepository.instance
        .insidenTerbaruStream(limit: 10)
        .listen((snap) {
      _insidenItems = snap.docs.map((doc) {
        final d       = doc.data();
        final status  = d['status']     as String? ?? '';
        final kategori= d['kategori']   as String? ?? 'Insiden';
        final blok    = d['blok']       as String? ?? '-';
        final nomor   = d['nomor']      as String? ?? '-';
        final nama    = d['namaSatpam'] as String? ?? 'Satpam';
        final isBaru  = status == 'BARU';
        return _AktivitasFeed(
          icon      : Icons.warning_amber_rounded,
          iconColor : isBaru ? Colors.red.shade700 : Colors.grey.shade600,
          iconBg    : isBaru ? Colors.red.shade50   : Colors.grey.shade100,
          title     : 'Insiden: $kategori',
          subtitle  : 'Blok $blok No. $nomor · $nama',
          badgeLabel: isBaru ? 'BARU' : null,
          badgeColor: Colors.red.shade700,
          sortKey   : _toDateTime(d['createdAt']),
        );
      }).toList();
      if (mounted) setState(() {});
    }, onError: (e) => debugPrint('[InsidenStream] $e'));
  }

  // ── Stream: catatantamu ───────────────────────────────────────────────────
  void _startTamuStream() {
    _tamuSubA = SecurityRepository.instance
        .tamuTerbaruStream(limit: 10)
        .listen((snap) {
      _tamuItems = snap.docs.map((doc) {
        final d        = doc.data();
        final nama     = d['namaTamu']           as String? ?? 'Tamu';
        final kategori = d['kategoriKunjungan']   as String? ?? '-';
        final blok     = d['blokTujuan']          as String? ?? '-';
        final nomor    = d['nomorRumahTujuan']    as String? ?? '-';
        final satpam   = d['namaSatpam']          as String? ?? 'Satpam';
        return _AktivitasFeed(
          icon      : Icons.person_add_outlined,
          iconColor : const Color(0xFF512DA8),
          iconBg    : const Color(0xFFEDE7F6),
          title     : 'Tamu Masuk: $nama',
          subtitle  : '$kategori · Blok $blok No. $nomor · Dicatat $satpam',
          sortKey   : _toDateTime(d['createdAt']),
        );
      }).toList();
      if (mounted) setState(() {});
    }, onError: (e) => debugPrint('[TamuStream] $e'));
  }

  @override
  void dispose() {
    _satpamSub?.cancel();
    _patroliSub?.cancel();
    _bantuanSub?.cancel();
    _insidenSubA?.cancel();
    _tamuSubA?.cancel();
    super.dispose();
  }

  Future<void> _onSosActivated() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    // Cek satpam bertugas & kirim SOS sekaligus (paralel) supaya pengecekan
    // ini tidak menambah delay pada alert darurat yang sudah ditahan 3 detik.
    final results = await Future.wait([
      SosRepository.hasSatpamOnDuty(),
      SosRepository.sendSos(),
    ]);
    final hasOnDuty = results[0] as bool;
    final alert = results[1] as SosAlert?;

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (alert != null) {
      if (!hasOnDuty) {
        await _showNoSatpamOnDutyWarning(
          'Permintaan SOS Anda tetap tersimpan dan akan segera diproses '
          'begitu ada satpam yang online.',
        );
        if (!mounted) return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SosStatusPage(
            alertId: alert.id,
            type: SosType.sos,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim SOS. Coba lagi.',
              style: GoogleFonts.inter(fontSize: 13)),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // ── Warning: tidak ada satpam yang sedang bertugas ───────────────────────
  Future<void> _showNoSatpamOnDutyWarning(String message) {
    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Tidak Ada Satpam Bertugas',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Text(message,
            style: GoogleFonts.inter(fontSize: 14, height: 1.4)),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Mengerti',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: MediaQuery.of(context).padding.top),

                  // ── App Bar ──────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              size: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Keamanan',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── SOS Section ──────────────────────────────────────
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Butuh Bantuan Segera?',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tahan tombol SOS selama 3 detik\nuntuk memanggil satpam.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textGrey,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // SOS Button (hold 3 detik)
                        SosButton(
                          onActivated: _isLoading ? null : _onSosActivated,
                        ),

                        const SizedBox(height: 24),

                        // Tombol Minta Bantuan (non-emergency)
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BantuanSatpamPage(),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.support_agent_outlined,
                                    size: 18, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'Minta Bantuan',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Satpam Bertugas ──────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Text(
                          'Satpam Bertugas',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (!_satpamLoading && (_satpamList?.isNotEmpty ?? false))
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_satpamList!.length} orang',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (_satpamLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else if (_satpamList == null || _satpamList!.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          'Tidak ada data satpam',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 140,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _satpamList!.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 12),
                        itemBuilder: (context, i) {
                          final s = _satpamList![i];
                          return _SatpamCard(satpam: s);
                        },
                      ),
                    ),

                  const SizedBox(height: 28),

                  // ── Aktivitas Keamanan (realtime dari Firestore) ─────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Aktivitas Keamanan',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (_aktivitasLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  else if (_mergedAktivitas.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          'Belum ada aktivitas keamanan',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textGrey),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: _mergedAktivitas
                          .map((item) => _AktivitasItem(feed: item))
                          .toList(),
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Item aktivitas keamanan ───────────────────────────────────────────────────
class _AktivitasItem extends StatelessWidget {
  const _AktivitasItem({required this.feed});
  final _AktivitasFeed feed;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon box
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: feed.iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(feed.icon, color: feed.iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          // Teks
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feed.title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                if (feed.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    feed.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.textGrey, height: 1.4),
                  ),
                ],
              ],
            ),
          ),
          // Badge (opsional)
          if (feed.badgeLabel != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: feed.badgeColor!.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: feed.badgeColor!.withValues(alpha: 0.3)),
              ),
              child: Text(
                feed.badgeLabel!,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: feed.badgeColor,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Card satpam bertugas ──────────────────────────────────────────────────────
class _SatpamCard extends StatelessWidget {
  const _SatpamCard({required this.satpam});
  final _SatpamInfo satpam;

  String get _initials {
    final parts = satpam.namaLengkap.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52, height: 52,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle, color: Color(0xFF1A4080)),
            child: Text(_initials,
                style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ),
          const SizedBox(height: 8),
          Text(satpam.namaLengkap,
              maxLines: 2, overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: AppColors.textDark, height: 1.3)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 5, height: 5,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green.shade600)),
                const SizedBox(width: 3),
                Text('Bertugas',
                    style: GoogleFonts.inter(
                        fontSize: 9, fontWeight: FontWeight.w600,
                        color: Colors.green.shade700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

