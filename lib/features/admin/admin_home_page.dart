import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/services/keluhan_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../pembayaran/payment_repository.dart';
import '../pembayaran/tagihan_model.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_top_bar.dart';
import 'data/admin_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Simple model untuk insiden di dashboard
// ─────────────────────────────────────────────────────────────────────────────

class _InsidenSnap {
  const _InsidenSnap({
    required this.kategori,
    required this.lokasi,
    required this.status,
    required this.waktu,
  });
  final String   kategori;
  final String   lokasi;
  final String   status;
  final DateTime waktu;

  int get severity => switch (status) {
    'BARU'      => 2,
    'DITANGANI' => 1,
    _           => 0,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

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
  List<_InsidenSnap>  _recentInsiden  = [];
  List<KeluhanItem>   _recentKeluhan  = [];
  List<TagihanModel>  _tagihanBulanIni = [];
  bool _loading = true;

  StreamSubscription? _wargaSub;
  StreamSubscription? _patroliSub;
  StreamSubscription? _tamuSub;
  StreamSubscription? _insidenSub;
  StreamSubscription? _keluhanSub;
  StreamSubscription? _tagihanSub;

  // Jumlah insiden yang belum selesai (BARU + DITANGANI)
  int get _openInsiden =>
      _recentInsiden.where((i) => i.status != 'SELESAI').length;

  // Insiden untuk ditampilkan di tabel (maks 5)
  List<_InsidenSnap> get _heatmapItems => _recentInsiden.take(5).toList();

  // ── Financial Status (bulan ini) ────────────────────────────────────────
  int get _totalTagihanBulanIni =>
      _tagihanBulanIni.fold(0, (sum, t) => sum + t.jumlah);
  int get _totalDibayarBulanIni => _tagihanBulanIni
      .where((t) => t.status == StatusTagihan.lunas)
      .fold(0, (sum, t) => sum + t.jumlah);
  int get _totalMenungguBulanIni =>
      _totalTagihanBulanIni - _totalDibayarBulanIni;

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
    // ── Total warga (role == user) ───────────────────────────────────────────
    _wargaSub = _repo.wargaStream().listen((snap) {
      if (!mounted) return;
      setState(() {
        _totalWarga = snap.docs.length;
        _loading    = false;
      });
    }, onError: (_) {
      if (mounted) setState(() => _loading = false);
    });

    // ── Patroli aktif ────────────────────────────────────────────────────────
    _patroliSub = _repo.patroliAktifStream().listen((snap) {
      if (mounted) setState(() => _patroliAktif = snap.docs.length);
    });

    // ── Tamu hari ini ────────────────────────────────────────────────────────
    _tamuSub = _repo.tamuSejakStream(_startOfToday).listen((snap) {
      if (mounted) setState(() => _tamuHariIni = snap.docs.length);
    });

    // ── Insiden terbaru (limit 10) ───────────────────────────────────────────
    _insidenSub = _repo.insidenTerbaruStream(limit: 10).listen((snap) {
      if (!mounted) return;
      setState(() {
        _recentInsiden = snap.docs.map((doc) {
          final d      = doc.data();
          final blok   = d['blok']  as String? ?? '-';
          final nomor  = d['nomor'] as String? ?? '-';
          final detail = d['detailLokasi'] as String? ?? '';
          final lokasi = detail.isNotEmpty
              ? '$blok No. $nomor · $detail'
              : '$blok No. $nomor';

          DateTime waktu;
          final ts = d['createdAt'] ?? d['waktuKejadian'];
          waktu = ts is Timestamp ? ts.toDate() : DateTime.now();

          return _InsidenSnap(
            kategori : d['kategori'] as String? ?? 'Insiden',
            lokasi   : lokasi,
            status   : d['status']   as String? ?? 'BARU',
            waktu    : waktu,
          );
        }).toList();
      });
    });

    // ── Keluhan aktif terbaru ────────────────────────────────────────────────
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

    // ── Financial status (tagihan bulan ini) ────────────────────────────────
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

  // ── Relative time ──────────────────────────────────────────────────────────
  static String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours   < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays    == 1) return 'kemarin';
    return DateFormat('dd MMM', 'id_ID').format(dt);
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
                              // ── System status bar ───────────────────
                              _SystemStatusBar(
                                onLogInsiden: () => Navigator.pushReplacementNamed(
                                    context, AppRouter.adminInsiden),
                              ),
                              const SizedBox(height: 20),

                              // ── Stat cards ─────────────────────────
                              _StatCardsRow(
                                totalWarga   : _totalWarga,
                                patroliAktif : _patroliAktif,
                                openInsiden  : _openInsiden,
                                tamuHariIni  : _tamuHariIni,
                              ),
                              const SizedBox(height: 20),

                              // ── Heatmap + Financial ─────────────────
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: _SecurityHeatmap(
                                      items: _heatmapItems,
                                      onLihatSemua: () =>
                                          Navigator.pushReplacementNamed(
                                              context, AppRouter.adminInsiden),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    flex: 1,
                                    child: _FinancialStatus(
                                      totalTagihan: _totalTagihanBulanIni,
                                      totalDibayar: _totalDibayarBulanIni,
                                      totalMenunggu: _totalMenungguBulanIni,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // ── Resident Requests ───────────────────
                              _ResidentRequests(
                                items: _recentKeluhan,
                                relativeTime: _relativeTime,
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

// ─────────────────────────────────────────────────────────────────────────────
// System Status Bar
// ─────────────────────────────────────────────────────────────────────────────

class _SystemStatusBar extends StatelessWidget {
  const _SystemStatusBar({required this.onLogInsiden});
  final VoidCallback onLogInsiden;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
                color: Color(0xFF22C55E), shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sistem Operasional: Aktif',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark)),
              Text('Semua modul berfungsi normal.',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textGrey)),
            ],
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () => _showAlarmDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('TRIGGER ALARM',
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: onLogInsiden,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textDark,
              side: BorderSide(color: Colors.grey.shade300),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Log Insiden Manual',
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  void _showAlarmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
          const SizedBox(width: 8),
          Text('Aktifkan Alarm Darurat?',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        content: Text(
          'Tindakan ini akan mengirim notifikasi darurat ke seluruh penghuni dan satpam.',
          style: GoogleFonts.inter(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal',
                style: GoogleFonts.inter(color: AppColors.textGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Aktifkan',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat Cards Row (Firestore-driven)
// ─────────────────────────────────────────────────────────────────────────────

class _StatCardsRow extends StatelessWidget {
  const _StatCardsRow({
    required this.totalWarga,
    required this.patroliAktif,
    required this.openInsiden,
    required this.tamuHariIni,
  });
  final int totalWarga, patroliAktif, openInsiden, tamuHariIni;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label      : 'TOTAL WARGA',
            value      : '$totalWarga',
            sub        : 'Penghuni terdaftar',
            subColor   : const Color(0xFF64748B),
            icon       : Icons.people_alt_outlined,
            iconColor  : AppColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            label      : 'PATROLI AKTIF',
            value      : '$patroliAktif',
            sub        : patroliAktif > 0 ? 'Sedang berjalan' : 'Tidak ada',
            subColor   : patroliAktif > 0
                ? const Color(0xFF0D9488)
                : const Color(0xFF64748B),
            valueColor : patroliAktif > 0
                ? const Color(0xFF0D9488)
                : AppColors.textDark,
            icon       : Icons.verified_user_outlined,
            iconColor  : patroliAktif > 0
                ? const Color(0xFF0D9488)
                : AppColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            label      : 'INSIDEN TERBUKA',
            value      : '$openInsiden',
            sub        : openInsiden > 0 ? 'Butuh tindakan' : 'Semua aman',
            subColor   : openInsiden > 0
                ? const Color(0xFFDC2626)
                : const Color(0xFF16A34A),
            valueColor : openInsiden > 0
                ? const Color(0xFFDC2626)
                : AppColors.textDark,
            icon       : Icons.emergency_outlined,
            iconColor  : openInsiden > 0
                ? const Color(0xFFDC2626)
                : const Color(0xFF16A34A),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            label      : 'TAMU HARI INI',
            value      : '$tamuHariIni',
            sub        : 'Kunjungan tercatat',
            subColor   : const Color(0xFF64748B),
            icon       : Icons.badge_outlined,
            iconColor  : AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.subColor,
    required this.icon,
    required this.iconColor,
    this.valueColor = AppColors.textDark,
  });
  final String   label, value, sub;
  final Color    subColor, valueColor, iconColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textGrey,
                      letterSpacing: 0.5)),
              Icon(icon, size: 20, color: iconColor),
            ],
          ),
          const SizedBox(height: 12),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                  height: 1)),
          const SizedBox(height: 6),
          Text(sub,
              style: GoogleFonts.inter(fontSize: 12, color: subColor)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Security & Incidents Heatmap (Firestore-driven)
// ─────────────────────────────────────────────────────────────────────────────

class _SecurityHeatmap extends StatelessWidget {
  const _SecurityHeatmap({
    required this.items,
    required this.onLihatSemua,
  });
  final List<_InsidenSnap> items;
  final VoidCallback        onLihatSemua;

  Color _severityColor(int sev) => switch (sev) {
    2 => const Color(0xFFDC2626),
    1 => const Color(0xFFF59E0B),
    _ => const Color(0xFF22C55E),
  };

  Widget _statusBadge(String status) {
    final (bg, fg) = switch (status) {
      'BARU'      => (const Color(0xFFFFE4E6), const Color(0xFFDC2626)),
      'DITANGANI' => (const Color(0xFFFEF3C7), const Color(0xFFD97706)),
      'SELESAI'   => (const Color(0xFFDCFCE7), const Color(0xFF16A34A)),
      _           => (Colors.grey.shade100, AppColors.textGrey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status,
          style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Security & Incidents',
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark)),
                GestureDetector(
                  onTap: onLihatSemua,
                  child: Text('Lihat Semua',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: const Color(0xFFF8FAFC),
            child: Row(children: [
              const SizedBox(width: 8),
              Expanded(flex: 3,
                  child: _Th('TIPE KEJADIAN')),
              Expanded(flex: 3,
                  child: _Th('LOKASI')),
              SizedBox(width: 110, child: _Th('STATUS')),
              SizedBox(width: 80,  child: _Th('WAKTU')),
            ]),
          ),

          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(28),
              child: Center(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.check_circle_outline,
                      size: 18, color: Color(0xFF16A34A)),
                  const SizedBox(width: 8),
                  Text('Tidak ada insiden.',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.textGrey)),
                ]),
              ),
            )
          else
            ...items.map((item) => Container(
              decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade100))),
              child: IntrinsicHeight(
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Container(
                    width: 4,
                    color: _severityColor(item.severity),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(children: [
                        Expanded(flex: 3,
                            child: Text(item.kategori,
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textDark))),
                        Expanded(flex: 3,
                            child: Text(item.lokasi,
                                style: GoogleFonts.inter(
                                    fontSize: 13, color: const Color(0xFF374151)),
                                overflow: TextOverflow.ellipsis)),
                        SizedBox(width: 110, child: _statusBadge(item.status)),
                        SizedBox(
                          width: 80,
                          child: Text(
                            _AdminHomePageState._relativeTime(item.waktu),
                            style: GoogleFonts.inter(
                                fontSize: 12, color: AppColors.textGrey),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ]),
              ),
            )),

          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _Th extends StatelessWidget {
  const _Th(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textGrey,
          letterSpacing: 0.5));
}

// ─────────────────────────────────────────────────────────────────────────────
// Financial Status (live — dari koleksi Firestore 'tagihan', bulan berjalan)
// ─────────────────────────────────────────────────────────────────────────────

class _FinancialStatus extends StatelessWidget {
  const _FinancialStatus({
    required this.totalTagihan,
    required this.totalDibayar,
    required this.totalMenunggu,
  });

  final int totalTagihan;
  final int totalDibayar;
  final int totalMenunggu;

  double get _persenTertagih =>
      totalTagihan == 0 ? 0 : totalDibayar / totalTagihan;

  @override
  Widget build(BuildContext context) {
    final adaTagihan = totalTagihan > 0;
    final persenLabel = '${(_persenTertagih * 100).round()}% Tertagih';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FINANCIAL STATUS (BULAN INI)',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textGrey,
                  letterSpacing: 0.5)),

          const SizedBox(height: 16),

          if (!adaTagihan)
            Text('Belum ada tagihan bulan ini.',
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textGrey))
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(formatRupiah(totalTagihan),
                        style: GoogleFonts.inter(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                            height: 1)),
                    const SizedBox(height: 4),
                    Text(persenLabel,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF16A34A))),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CustomPaint(
                      painter: _DonutChartPainter(progress: _persenTertagih)),
                ),
              ],
            ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sudah Dibayar',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textGrey)),
              Text(formatRupiah(totalDibayar),
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _persenTertagih,
              backgroundColor: Colors.grey.shade200,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 6,
            ),
          ),

          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Menunggu Pembayaran',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textGrey)),
              Text(formatRupiah(totalMenunggu),
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFDC2626))),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  const _DonutChartPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center      = Offset(size.width / 2, size.height / 2);
    final radius      = size.width / 2;
    const strokeWidth = 8.0;

    final bgPaint = Paint()
      ..color       = Colors.grey.shade200
      ..style       = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap   = StrokeCap.round;
    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    final fgPaint = Paint()
      ..color       = AppColors.primary
      ..style       = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap   = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_DonutChartPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Resident Requests — Keluhan Aktif (Firestore-driven)
// ─────────────────────────────────────────────────────────────────────────────

class _ResidentRequests extends StatelessWidget {
  const _ResidentRequests({
    required this.items,
    required this.relativeTime,
    required this.onLihatSemua,
  });
  final List<KeluhanItem>              items;
  final String Function(DateTime)      relativeTime;
  final VoidCallback                   onLihatSemua;

  IconData _icon(String kategori) {
    final k = kategori.toLowerCase();
    if (k.contains('rusak') || k.contains('pipa') || k.contains('perbaikan'))
      return Icons.build_outlined;
    if (k.contains('listrik'))  return Icons.bolt_outlined;
    if (k.contains('sampah'))   return Icons.delete_outline;
    if (k.contains('parkir'))   return Icons.local_parking_outlined;
    if (k.contains('keamanan')) return Icons.security_outlined;
    if (k.contains('fasilitas')) return Icons.apartment_outlined;
    return Icons.report_outlined;
  }

  (Color bg, Color fg, String label) _statusStyle(StatusKeluhan s) => switch (s) {
    StatusKeluhan.menunggu => (
      const Color(0xFFFFF7ED), const Color(0xFFD97706), 'Menunggu'),
    StatusKeluhan.diproses => (
      const Color(0xFFEFF6FF), AppColors.primary, 'Diproses'),
    _ => (Colors.grey.shade100, AppColors.textGrey, 'Lainnya'),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Row(children: [
              Text('Laporan Warga',
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark)),
              const SizedBox(width: 12),
              if (items.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${items.length} Laporan Aktif',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                ),
              const Spacer(),
              GestureDetector(
                onTap: onLihatSemua,
                child: Text('Lihat Semua',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary)),
              ),
            ]),
          ),

          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Row(children: [
                const Icon(Icons.check_circle_outline,
                    size: 18, color: Color(0xFF16A34A)),
                const SizedBox(width: 8),
                Text('Tidak ada laporan aktif saat ini.',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.textGrey)),
              ]),
            )
          else
            ...items.map((k) {
              final (statusBg, statusFg, statusLabel) =
                  _statusStyle(k.status);
              return Container(
                decoration: BoxDecoration(
                    border: Border(
                        top: BorderSide(color: Colors.grey.shade100))),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                child: Row(children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_icon(k.kategori),
                        size: 20, color: AppColors.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          k.judul.isNotEmpty ? k.judul : k.kategori,
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${k.namaWarga} · Blok ${k.blok} – ${k.nomorUnit} · ${relativeTime(k.createdAt)}',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.textGrey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(statusLabel,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusFg)),
                  ),
                ]),
              );
            }),

          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
