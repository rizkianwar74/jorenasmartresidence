import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/keluhan_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../pembayaran/data/payment_repository.dart';
import '../../pembayaran/models/tagihan_model.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/admin_top_bar.dart';
import '../data/admin_repository.dart';
import 'models/insiden_snap.dart';
import 'widgets/stat_cards_section.dart';
import 'widgets/security_heatmap_section.dart';
import 'widgets/financial_status_section.dart';
import 'widgets/resident_requests_section.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final _repo = AdminRepository.instance;

  int  _totalWarga    = 0;
  int  _patroliAktif  = 0;
  int  _tamuHariIni   = 0;
  List<InsidenSnap>  _recentInsiden  = [];
  List<KeluhanItem>   _recentKeluhan  = [];
  List<TagihanModel>  _tagihanBulanIni = [];
  bool _loading = true;

  StreamSubscription? _wargaSub;
  StreamSubscription? _patroliSub;
  StreamSubscription? _tamuSub;
  StreamSubscription? _insidenSub;
  StreamSubscription? _keluhanSub;
  StreamSubscription? _tagihanSub;

  int get _openInsiden =>
      _recentInsiden.where((i) => i.status != 'SELESAI').length;

  List<InsidenSnap> get _heatmapItems => _recentInsiden.take(5).toList();

  // ── Financial Status (bulan ini) ────────────────────────────────────────
  int get _totalTagihanBulanIni =>
      _tagihanBulanIni.fold(0, (sum, t) => sum + t.jumlah);
  int get _totalDibayarBulanIni => _tagihanBulanIni
      .where((t) => t.status == StatusTagihan.lunas)
      .fold(0, (sum, t) => sum + t.jumlah);
  int get _totalMenungguBulanIni =>
      _totalTagihanBulanIni - _totalDibayarBulanIni;

  int get _dibayarQris => _tagihanBulanIni
      .where((t) =>
          t.status == StatusTagihan.lunas &&
          (t.metodeBayar?.toLowerCase().contains('qris') ?? false))
      .fold(0, (sum, t) => sum + t.jumlah);

  int get _dibayarTunai => _tagihanBulanIni
      .where((t) =>
          t.status == StatusTagihan.lunas &&
          (t.metodeBayar?.toLowerCase().contains('tunai') ?? false))
      .fold(0, (sum, t) => sum + t.jumlah);

  int get _countQris => _tagihanBulanIni
      .where((t) =>
          t.status == StatusTagihan.lunas &&
          (t.metodeBayar?.toLowerCase().contains('qris') ?? false))
      .length;
  int get _countTunai => _tagihanBulanIni
      .where((t) =>
          t.status == StatusTagihan.lunas &&
          (t.metodeBayar?.toLowerCase().contains('tunai') ?? false))
      .length;

  static DateTime get _startOfToday {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  @override
  void initState() {
    super.initState();
    _startStreams();
  }

  void _startStreams() {
    _wargaSub = _repo.wargaStream().listen((snap) {
      if (!mounted) return;
      setState(() {
        _totalWarga = snap.docs.length;
        _loading    = false;
      });
    }, onError: (_) {
      if (mounted) setState(() => _loading = false);
    });

    _patroliSub = _repo.patroliAktifStream().listen((snap) {
      if (mounted) setState(() => _patroliAktif = snap.docs.length);
    });

    _tamuSub = _repo.tamuSejakStream(_startOfToday).listen((snap) {
      if (mounted) setState(() => _tamuHariIni = snap.docs.length);
    });

    _insidenSub = _repo.insidenTerbaruStream(limit: 10).listen((snap) {
      if (!mounted) return;
      setState(() {
        _recentInsiden = snap.docs.map((doc) {
          final d      = doc.data() as Map<String, dynamic>;
          final blok   = d['blok']  as String? ?? '-';
          final nomor  = d['nomor'] as String? ?? '-';
          final detail = d['detailLokasi'] as String? ?? '';
          final lokasi = detail.isNotEmpty
              ? '$blok No. $nomor · $detail'
              : '$blok No. $nomor';

          DateTime waktu;
          final ts = d['createdAt'] ?? d['waktuKejadian'];
          waktu = ts is Timestamp ? ts.toDate() : DateTime.now();

          return InsidenSnap(
            kategori : d['kategori'] as String? ?? 'Insiden',
            lokasi   : lokasi,
            status   : d['status']   as String? ?? 'BARU',
            waktu    : waktu,
          );
        }).toList();
      });
    });

    _keluhanSub = _repo.keluhanTerbaruStream(limit: 20).listen((snap) {
      if (!mounted) return;
      setState(() {
        _recentKeluhan = snap.docs
            .map((d) => KeluhanItem.fromDoc(d))
            .where((k) => k.status != StatusKeluhan.selesai
                       && k.status != StatusKeluhan.ditolak)
            .take(5)
            .toList();
      });
    });

    final now = DateTime.now();
    _tagihanSub = PaymentRepository.watchAllTagihan().listen((list) {
      if (!mounted) return;
      setState(() {
        _tagihanBulanIni = list
            .where((t) => t.tahun == now.year && t.bulanIndex == now.month)
            .toList();
      });
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _wargaSub?.cancel();
    _patroliSub?.cancel();
    _tamuSub?.cancel();
    _insidenSub?.cancel();
    _keluhanSub?.cancel();
    _tagihanSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          const AdminSidebar(activePage: AdminPage.dashboard),

          Expanded(
            child: Column(
              children: [
                const AdminTopBar(
                    searchHint: 'Search residents, units, or incidents...'),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : SingleChildScrollView(
                          padding:
                              const EdgeInsets.fromLTRB(24, 20, 24, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              StatCardsRow(
                                totalWarga   : _totalWarga,
                                patroliAktif : _patroliAktif,
                                openInsiden  : _openInsiden,
                                tamuHariIni  : _tamuHariIni,
                              ),
                              const SizedBox(height: 20),

                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: SecurityHeatmap(
                                      items: _heatmapItems,
                                      onLihatSemua: () =>
                                          Navigator.pushReplacementNamed(
                                              context, AppRouter.adminInsiden),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    flex: 1,
                                    child: FinancialStatus(
                                      totalTagihan  : _totalTagihanBulanIni,
                                      totalDibayar  : _totalDibayarBulanIni,
                                      totalMenunggu : _totalMenungguBulanIni,
                                      dibayarQris   : _dibayarQris,
                                      dibayarTunai  : _dibayarTunai,
                                      countQris     : _countQris,
                                      countTunai    : _countTunai,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              ResidentRequests(
                                items: _recentKeluhan,
                                onLihatSemua: () =>
                                    Navigator.pushReplacementNamed(
                                        context, AppRouter.adminReports),
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
