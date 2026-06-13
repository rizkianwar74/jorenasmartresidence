import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_top_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model Log Aktivitas (gabungan SOS + Bantuan + Patroli)
// ─────────────────────────────────────────────────────────────────────────────

enum _LogType { sos, bantuan, patroli }

class _LogItem {
  const _LogItem({
    required this.type,
    required this.judul,
    required this.sub,
    required this.status,
    required this.waktu,
  });
  final _LogType type;
  final String judul;
  final String sub;
  final String status;
  final DateTime waktu;
}

// ─────────────────────────────────────────────────────────────────────────────
// Model Satpam
// ─────────────────────────────────────────────────────────────────────────────

class _SatpamData {
  const _SatpamData({required this.uid, required this.nama, this.lokasi = '-'});
  final String uid;
  final String nama;
  final String lokasi;
}

// ─────────────────────────────────────────────────────────────────────────────
// Model Log Patroli
// ─────────────────────────────────────────────────────────────────────────────

class _PatroliItem {
  const _PatroliItem({
    required this.waktu,
    required this.petugas,
    required this.lokasi,
    required this.catatan,
    required this.selesai,
  });
  final String waktu;
  final String petugas;
  final String lokasi;
  final String catatan;
  final bool selesai;

  factory _PatroliItem.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final jamMulai   = d['jamMulai']   as String? ?? '';
    final jamSelesai = d['jamSelesai'] as String? ?? '';
    final status     = d['status']     as String? ?? '';
    final selesai    = status == 'SELESAI' || jamSelesai.isNotEmpty;

    String waktu = jamMulai.isNotEmpty ? jamMulai : '--:--';
    if (jamSelesai.isNotEmpty) waktu = '$jamMulai – $jamSelesai';

    final keteranganRaw = d['keterangan'] as String? ?? '';
    final keterangan = keteranganRaw.isNotEmpty
        ? keteranganRaw
        : (() {
            final tags = d['quickTags'];
            if (tags is List) {
              final filled = tags.whereType<String>().where((t) => t.isNotEmpty).join(', ');
              return filled.isNotEmpty ? filled : '-';
            }
            return '-';
          })();

    return _PatroliItem(
      waktu   : waktu,
      petugas : (d['namaSatpam']  as String? ?? '').isNotEmpty ? d['namaSatpam'] as String : '-',
      lokasi  : (d['blokPatroli'] as String? ?? '').isNotEmpty ? d['blokPatroli'] as String : '-',
      catatan : keterangan,
      selesai : selesai,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class AdminSecurityPage extends StatefulWidget {
  const AdminSecurityPage({super.key});

  @override
  State<AdminSecurityPage> createState() => _AdminSecurityPageState();
}

class _AdminSecurityPageState extends State<AdminSecurityPage> {
  final _db = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot>? _sosSub;
  StreamSubscription<QuerySnapshot>? _bantuanSub;
  StreamSubscription<QuerySnapshot>? _satpamSub;
  StreamSubscription<QuerySnapshot>? _patroliSub;
  StreamSubscription<QuerySnapshot>? _patroliAktifSub;

  List<QueryDocumentSnapshot> _sosDocs        = [];
  List<QueryDocumentSnapshot> _bantuanDocs    = [];
  List<_SatpamData>           _satpamList     = [];
  List<_PatroliItem>          _patroliLog     = [];
  int                         _patroliAktif   = 0;
  bool _loading = true;

  // Awal hari ini (00:00:00)
  static DateTime get _startOfToday {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();

    final start = Timestamp.fromDate(_startOfToday);

    // Stream SOS hari ini
    _sosSub = _db.collection('sosalert')
        .where('createdAt', isGreaterThanOrEqualTo: start)
        .snapshots()
        .listen((snap) {
      if (mounted) setState(() { _sosDocs = snap.docs; _loading = false; });
    });

    // Stream Bantuan hari ini
    _bantuanSub = _db.collection('bantuanrequest')
        .where('createdAt', isGreaterThanOrEqualTo: start)
        .snapshots()
        .listen((snap) {
      if (mounted) setState(() => _bantuanDocs = snap.docs);
    });

    // Stream Satpam (semua, bukan hanya hari ini)
    _satpamSub = _db.collection('users')
        .where('role', isEqualTo: 'satpam')
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      setState(() {
        _satpamList = snap.docs.map((doc) {
          final d = doc.data() as Map<String, dynamic>;
          final nama = (d['namaLengkap'] as String?)?.isNotEmpty == true
              ? d['namaLengkap'] as String
              : (d['username'] as String? ?? 'Satpam');
          return _SatpamData(uid: doc.id, nama: nama,
              lokasi: d['lokasi'] as String? ?? '-');
        }).toList();
      });
    });

    // Stream Patroli hari ini (untuk log)
    _patroliSub = _db.collection('patroli')
        .where('createdAt', isGreaterThanOrEqualTo: start)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      setState(() {
        _patroliLog = snap.docs.map(_PatroliItem.fromDoc).toList()
          ..sort((a, b) => b.waktu.compareTo(a.waktu));
      });
    });

    // Stream Patroli AKTIF (realtime)
    _patroliAktifSub = _db.collection('patroli')
        .where('status', isEqualTo: 'AKTIF')
        .snapshots()
        .listen((snap) {
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

  // ── Gabungkan semua aktivitas hari ini jadi log ───────────────────────────
  List<_LogItem> get _logAktivitas {
    final items = <_LogItem>[];

    for (final doc in _sosDocs) {
      final d      = doc.data() as Map<String, dynamic>;
      final waktu  = (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final status = d['status'] as String? ?? 'PENDING';
      final tipe   = d['type']   as String? ?? 'call';
      items.add(_LogItem(
        type   : _LogType.sos,
        judul  : tipe == 'sos' ? 'SOS Darurat' : 'Panggil Satpam',
        sub    : 'Blok ${d['blok'] ?? '-'} – ${d['namaWarga'] ?? '-'}',
        status : _labelStatus(status),
        waktu  : waktu,
      ));
    }

    for (final doc in _bantuanDocs) {
      final d      = doc.data() as Map<String, dynamic>;
      final waktu  = (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final status = d['status'] as String? ?? 'PENDING';
      items.add(_LogItem(
        type   : _LogType.bantuan,
        judul  : d['kategori'] as String? ?? 'Bantuan',
        sub    : 'Blok ${d['blok'] ?? '-'} – ${d['namaWarga'] ?? '-'}',
        status : _labelStatus(status),
        waktu  : waktu,
      ));
    }

    // sort terbaru di atas
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

  // ── Stat counts hari ini ──────────────────────────────────────────────────
  int get _totalSosHariIni     => _sosDocs.length;
  int get _totalBantuanHariIni => _bantuanDocs.length;

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
                              // ── Stat cards ───────────────────────────────
                              _StatCardsRow(
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
                                        // ── Log Aktivitas Hari Ini ────────
                                        _LogAktivitasSection(
                                            items: _logAktivitas),
                                        const SizedBox(height: 20),
                                        // ── Log Patroli ───────────────────
                                        _LogPatroliSection(logs: _patroliLog),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    flex: 1,
                                    child: _SatpamBertugasSection(
                                        satpamList: _satpamList),
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

// ─────────────────────────────────────────────────────────────────────────────
// Stat cards — counter hari ini
// ─────────────────────────────────────────────────────────────────────────────

class _StatCardsRow extends StatelessWidget {
  const _StatCardsRow({
    required this.satpamAktif,
    required this.sosHariIni,
    required this.bantuanHariIni,
    required this.patroliAktif,
  });
  final int satpamAktif, sosHariIni, bantuanHariIni, patroliAktif;

  @override
  Widget build(BuildContext context) {
    final adaPatroli = patroliAktif > 0;
    return Row(
      children: [
        Expanded(child: _StatCard(
          label    : 'SATPAM TERDAFTAR',
          value    : satpamAktif.toString().padLeft(2, '0'),
          sub      : 'Aktif',
          subIcon  : Icons.check_circle_outline,
          subColor : const Color(0xFF16A34A),
        )),
        const SizedBox(width: 14),
        Expanded(child: _StatCard(
          label      : 'SOS HARI INI',
          value      : sosHariIni.toString().padLeft(2, '0'),
          sub        : 'Panggilan',
          subIcon    : Icons.emergency_outlined,
          subColor   : sosHariIni > 0 ? const Color(0xFFDC2626) : AppColors.textGrey,
          valueColor : sosHariIni > 0 ? const Color(0xFFDC2626) : AppColors.textDark,
        )),
        const SizedBox(width: 14),
        Expanded(child: _StatCard(
          label    : 'BANTUAN HARI INI',
          value    : bantuanHariIni.toString().padLeft(2, '0'),
          sub      : 'Permintaan',
          subIcon  : Icons.support_agent_outlined,
          subColor : AppColors.primary,
        )),
        const SizedBox(width: 14),
        Expanded(child: _StatCard(
          label      : 'PATROLI AKTIF',
          value      : patroliAktif.toString().padLeft(2, '0'),
          sub        : adaPatroli ? 'Sedang Berjalan' : 'Tidak Ada',
          subIcon    : adaPatroli ? Icons.shield : Icons.shield_outlined,
          subColor   : adaPatroli ? const Color(0xFF0D9488) : AppColors.textGrey,
          valueColor : adaPatroli ? const Color(0xFF0D9488) : AppColors.textDark,
        )),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    this.subIcon,
    required this.subColor,
    this.valueColor = AppColors.textDark,
  });
  final String label, value, sub;
  final IconData? subIcon;
  final Color subColor, valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.inter(fontSize: 11,
                fontWeight: FontWeight.w600, color: AppColors.textGrey, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.inter(fontSize: 36,
                fontWeight: FontWeight.bold, color: valueColor, height: 1)),
          ]),
          Row(children: [
            if (subIcon != null) ...[
              Icon(subIcon, size: 15, color: subColor),
              const SizedBox(width: 4),
            ],
            Text(sub, style: GoogleFonts.inter(fontSize: 13,
                fontWeight: FontWeight.w500, color: subColor)),
          ]),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Log Aktivitas Hari Ini
// ─────────────────────────────────────────────────────────────────────────────

class _LogAktivitasSection extends StatelessWidget {
  const _LogAktivitasSection({required this.items});
  final List<_LogItem> items;

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.now());

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(children: [
              Text('Log Aktivitas', style: GoogleFonts.inter(
                fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark,
              )),
              const SizedBox(width: 8),
              if (items.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary, borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${items.length}', style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white,
                  )),
                ),
              const Spacer(),
              Text(today, style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.textGrey,
              )),
            ]),
          ),

          const SizedBox(height: 10),

          // Table header
          Container(
            color: const Color(0xFFF8FAFC),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(children: const [
              SizedBox(width: 70, child: _ColH('WAKTU')),
              SizedBox(width: 32),
              Expanded(flex: 2, child: _ColH('KEJADIAN')),
              Expanded(flex: 2, child: _ColH('UNIT / WARGA')),
              SizedBox(width: 110, child: _ColH('STATUS')),
            ]),
          ),

          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(28),
              child: Center(child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline, size: 18, color: const Color(0xFF16A34A)),
                  const SizedBox(width: 8),
                  Text('Tidak ada aktivitas hari ini.',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey)),
                ],
              )),
            )
          else
            ...items.map((item) => _LogRow(item: item)),

          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _ColH extends StatelessWidget {
  const _ColH(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text, style: GoogleFonts.inter(
    fontSize: 10, fontWeight: FontWeight.w700,
    color: AppColors.textGrey, letterSpacing: 0.4,
  ));
}

class _LogRow extends StatelessWidget {
  const _LogRow({required this.item});
  final _LogItem item;

  (Color, IconData) get _typeStyle => switch (item.type) {
    _LogType.sos     => (const Color(0xFFDC2626), Icons.emergency_outlined),
    _LogType.bantuan => (AppColors.primary,       Icons.support_agent_outlined),
    _LogType.patroli => (const Color(0xFF0D9488), Icons.shield_outlined),
  };

  Color get _statusColor {
    final s = item.status;
    if (s == 'Selesai') return const Color(0xFF16A34A);
    if (s == 'Menuju Lokasi') return AppColors.primary;
    if (s == 'Menunggu') return const Color(0xFFF97316);
    return AppColors.textGrey;
  }

  @override
  Widget build(BuildContext context) {
    final (typeColor, typeIcon) = _typeStyle;
    final waktu = DateFormat('HH:mm').format(item.waktu);

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(children: [
        // Waktu
        SizedBox(width: 70, child: Text(waktu, style: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark,
        ))),

        // Icon type
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: typeColor.withOpacity(0.1), shape: BoxShape.circle,
          ),
          child: Icon(typeIcon, size: 15, color: typeColor),
        ),
        const SizedBox(width: 8),

        // Judul
        Expanded(flex: 2, child: Text(item.judul, style: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark,
        ))),

        // Sub (unit / warga)
        Expanded(flex: 2, child: Text(item.sub, style: GoogleFonts.inter(
          fontSize: 12, color: AppColors.textGrey,
        ), overflow: TextOverflow.ellipsis)),

        // Status badge
        SizedBox(
          width: 110,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 6, height: 6,
                  decoration: BoxDecoration(color: _statusColor, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Flexible(child: Text(item.status, style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor,
              ), overflow: TextOverflow.ellipsis)),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Log Patroli
// ─────────────────────────────────────────────────────────────────────────────

class _LogPatroliSection extends StatelessWidget {
  const _LogPatroliSection({required this.logs});
  final List<_PatroliItem> logs;

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
            child: Row(children: [
              Text('Log Patroli Hari Ini', style: GoogleFonts.inter(
                fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark,
              )),
              if (logs.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${logs.length}', style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white,
                  )),
                ),
              ],
            ]),
          ),
          const SizedBox(height: 12),
          Container(
            color: const Color(0xFFF8FAFC),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(children: const [
              SizedBox(width: 90, child: _ColH('WAKTU')),
              Expanded(flex: 2, child: _ColH('PETUGAS')),
              Expanded(flex: 2, child: _ColH('BLOK / AREA')),
              Expanded(flex: 3, child: _ColH('KETERANGAN')),
              SizedBox(width: 90, child: _ColH('STATUS')),
            ]),
          ),
          if (logs.isEmpty)
            Padding(
              padding: const EdgeInsets.all(28),
              child: Center(child: Text('Belum ada log patroli hari ini.',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey))),
            )
          else
            ...logs.map((log) => _PatroliRow(log: log)),
        ],
      ),
    );
  }
}

class _PatroliRow extends StatelessWidget {
  const _PatroliRow({required this.log});
  final _PatroliItem log;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade100))),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(children: [
        SizedBox(width: 90, child: Text(log.waktu, style: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark,
        ))),
        Expanded(flex: 2, child: Text(log.petugas, style: GoogleFonts.inter(
            fontSize: 13, color: AppColors.textDark))),
        Expanded(flex: 2, child: Text(log.lokasi, style: GoogleFonts.inter(
            fontSize: 13, color: AppColors.textDark))),
        Expanded(flex: 3, child: Text(log.catatan, style: GoogleFonts.inter(
            fontSize: 13, color: AppColors.textDark),
            overflow: TextOverflow.ellipsis)),
        SizedBox(width: 90, child: log.selesai
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Selesai', style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textGrey,
                )),
              )
            : Row(children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text('Berjalan', style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary,
                )),
              ])),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Satpam Bertugas
// ─────────────────────────────────────────────────────────────────────────────

class _SatpamBertugasSection extends StatelessWidget {
  const _SatpamBertugasSection({required this.satpamList});
  final List<_SatpamData> satpamList;

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'S';
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
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            child: Row(children: [
              Text('Satpam Terdaftar', style: GoogleFonts.inter(
                fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark,
              )),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary, borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${satpamList.length} Aktif', style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white,
                )),
              ),
            ]),
          ),
          if (satpamList.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
              child: Text('Belum ada satpam terdaftar.',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey)),
            )
          else
            ...satpamList.map((s) => Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade100)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withOpacity(0.12),
                  child: Text(_initials(s.nama), style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary,
                  )),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.nama, style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark,
                    )),
                    if (s.lokasi != '-')
                      Text(s.lokasi, style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.textGrey,
                      )),
                  ],
                )),
                Container(width: 8, height: 8, decoration: const BoxDecoration(
                  color: Color(0xFF16A34A), shape: BoxShape.circle,
                )),
              ]),
            )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
