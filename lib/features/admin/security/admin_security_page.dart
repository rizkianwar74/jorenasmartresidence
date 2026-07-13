import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/admin_top_bar.dart';
import '../data/admin_repository.dart';
import 'models/security_models.dart';
import 'widgets/security_shared_widgets.dart';
import 'widgets/security_dialogs.dart';
import 'widgets/satpam_bertugas_section.dart';
import 'widgets/log_aktivitas_section.dart';
import 'widgets/log_patroli_section.dart';

class AdminSecurityPage extends StatefulWidget {
  const AdminSecurityPage({super.key});

  @override
  State<AdminSecurityPage> createState() => _AdminSecurityPageState();
}

class _AdminSecurityPageState extends State<AdminSecurityPage> {
  final _repo = AdminRepository.instance;

  StreamSubscription<QuerySnapshot>? _sosSub;
  StreamSubscription<QuerySnapshot>? _bantuanSub;
  StreamSubscription<QuerySnapshot>? _satpamSub;
  StreamSubscription<QuerySnapshot>? _patroliSub;
  StreamSubscription<QuerySnapshot>? _patroliAktifSub;

  List<QueryDocumentSnapshot> _sosDocs     = [];
  List<QueryDocumentSnapshot> _bantuanDocs = [];
  List<SatpamData>            _satpamList  = [];
  List<PatroliItem>          _patroliLog  = [];
  int                         _patroliAktif = 0;
  bool _loading = true;

  static DateTime get _startOfToday {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  // Filter tambahan di sisi client — jaga-jaga kalau ada dokumen lama yang
  // lolos dari query Firestore (mis. createdAt tidak konsisten/kosong pada
  // sebagian data lama). Query `sejakStream` di atas tetap dipakai untuk
  // membatasi data yang di-fetch, tapi keputusan "termasuk hari ini atau
  // tidak" akhirnya divalidasi ulang di sini berdasarkan tanggal asli.
  bool _isToday(dynamic rawCreatedAt) {
    if (rawCreatedAt is! Timestamp) return false;
    final d = rawCreatedAt.toDate();
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  @override
  void initState() {
    super.initState();
    final start = _startOfToday;

    _sosSub = _repo.sosSejakStream(start).listen((snap) {
      if (mounted) {
        setState(() {
          _sosDocs = snap.docs
              .where((d) => _isToday(d.data()['createdAt']))
              .toList();
          _loading = false;
        });
      }
    });

    _bantuanSub = _repo.bantuanSejakStream(start).listen((snap) {
      if (mounted) {
        setState(() {
          _bantuanDocs = snap.docs
              .where((d) => _isToday(d.data()['createdAt']))
              .toList();
        });
      }
    });

    _satpamSub = _repo.satpamStream().listen((snap) {
      if (!mounted) return;
      setState(() {
        _satpamList = snap.docs.map((doc) {
          final d = doc.data();
          final nama = (d['namaLengkap'] as String?)?.isNotEmpty == true
              ? d['namaLengkap'] as String
              : (d['username'] as String? ?? 'Satpam');
          return SatpamData(uid: doc.id, nama: nama,
              lokasi: d['lokasi'] as String? ?? '-',
              isOnDuty: d['isOnDuty'] as bool? ?? false);
        }).toList();
      });
    });

    _patroliSub = _repo.patroliSejakStream(start).listen((snap) {
      if (!mounted) return;
      setState(() {
        _patroliLog = snap.docs.map(PatroliItem.fromDoc).toList()
          ..sort((a, b) => b.waktu.compareTo(a.waktu));
      });
    });

    _patroliAktifSub = _repo.patroliAktifStream().listen((snap) {
      if (mounted) setState(() => _patroliAktif = snap.docs.length);
    });
  }

  @override
  void dispose() {
    _sosSub?.cancel();
    _bantuanSub?.cancel();
    _satpamSub?.cancel();
    _patroliSub?.cancel();
    _patroliAktifSub?.cancel();
    super.dispose();
  }

  List<LogItem> get _logAktivitas {
    final items = <LogItem>[];

    for (final doc in _sosDocs) {
      final d     = doc.data() as Map<String, dynamic>;
      final waktu = (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final status = d['status'] as String? ?? 'PENDING';
      final tipe   = d['type']   as String? ?? 'call';
      items.add(LogItem(
        id     : doc.id,
        type   : LogType.sos,
        judul  : tipe == 'sos' ? 'SOS Darurat' : 'Panggil Satpam',
        sub    : 'Blok ${d['blok'] ?? '-'} – ${d['namaWarga'] ?? '-'}',
        status : _labelStatus(status),
        waktu  : waktu,
        rawData: d,
      ));
    }

    for (final doc in _bantuanDocs) {
      final d     = doc.data() as Map<String, dynamic>;
      final waktu = (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final status = d['status'] as String? ?? 'PENDING';
      items.add(LogItem(
        id     : doc.id,
        type   : LogType.bantuan,
        judul  : d['kategori'] as String? ?? 'Bantuan',
        sub    : 'Blok ${d['blok'] ?? '-'} – ${d['namaWarga'] ?? '-'}',
        status : _labelStatus(status),
        waktu  : waktu,
        rawData: d,
      ));
    }

    items.sort((a, b) => b.waktu.compareTo(a.waktu));
    return items;
  }

  String _labelStatus(String s) {
    switch (s.toUpperCase()) {
      case 'PENDING':    return 'Menunggu';
      case 'ON_MY_WAY':  return 'Menuju Lokasi';
      case 'RESOLVED':   return 'Selesai';
      case 'CANCELLED':  return 'Dibatalkan';
      default:           return s;
    }
  }

  int get _totalSosHariIni     => _sosDocs.length;
  int get _totalBantuanHariIni => _bantuanDocs.length;

  // ── Detail dialog: Log Aktivitas ─────────────────────────────────────────
  void _showLogDetail(BuildContext context, LogItem item) {
    showDialog(
      context: context,
      builder: (_) => LogDetailDialog(item: item),
    );
  }

  // ── Detail dialog: Patroli ───────────────────────────────────────────────
  void _showPatroliDetail(BuildContext context, PatroliItem item) {
    showDialog(
      context: context,
      builder: (_) => PatroliDetailDialog(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          const AdminSidebar(activePage: AdminPage.security),
          Expanded(
            child: Column(
              children: [
                const AdminTopBar(searchHint: 'Search security, incidents...'),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              StatCardsRow(
                                satpamAktif    : _satpamList.length,
                                sosHariIni     : _totalSosHariIni,
                                bantuanHariIni : _totalBantuanHariIni,
                                patroliAktif   : _patroliAktif,
                              ),
                              const SizedBox(height: 20),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      children: [
                                        LogAktivitasSection(
                                          items: _logAktivitas,
                                          onTap: (item) => _showLogDetail(context, item),
                                        ),
                                        const SizedBox(height: 20),
                                        LogPatroliSection(
                                          logs: _patroliLog,
                                          onTap: (p) => _showPatroliDetail(context, p),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    flex: 1,
                                    child: SatpamBertugasSection(satpamList: _satpamList),
                                  ),
                                ],
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
