import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_top_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model Log Aktivitas (SOS + Bantuan)
// ─────────────────────────────────────────────────────────────────────────────

enum _LogType { sos, bantuan, patroli }

class _LogItem {
  const _LogItem({
    required this.id,
    required this.type,
    required this.judul,
    required this.sub,
    required this.status,
    required this.waktu,
    this.rawData = const {},
  });

  final String               id;
  final _LogType             type;
  final String               judul;
  final String               sub;
  final String               status;
  final DateTime             waktu;
  final Map<String, dynamic> rawData;

  List<String> get fotoUrls {
    // Coba fotoUrls (list) dulu
    final list = rawData['fotoUrls'];
    if (list is List) {
      final urls = list.whereType<String>().where((u) => u.isNotEmpty).toList();
      if (urls.isNotEmpty) return urls;
    }
    // Fallback ke fotoUrl (single string)
    final single = rawData['fotoUrl'] as String?;
    if (single != null && single.isNotEmpty) return [single];
    return [];
  }
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
    required this.id,
    required this.waktu,
    required this.petugas,
    required this.lokasi,
    required this.catatan,
    required this.selesai,
    required this.rawData,
  });

  final String               id;
  final String               waktu;
  final String               petugas;
  final String               lokasi;
  final String               catatan;
  final bool                 selesai;
  final Map<String, dynamic> rawData;

  List<String> get fotoUrls {
    final single = rawData['fotoUrl'] as String?;
    if (single != null && single.isNotEmpty) return [single];
    final list = rawData['fotoUrls'];
    if (list is List) return list.whereType<String>().where((u) => u.isNotEmpty).toList();
    return [];
  }

  List<String> get quickTags {
    final tags = rawData['quickTags'];
    if (tags is List) return tags.whereType<String>().where((t) => t.isNotEmpty).toList();
    return [];
  }

  String get jamMulai   => rawData['jamMulai']   as String? ?? '-';
  String get jamSelesai => rawData['jamSelesai'] as String? ?? '-';

  factory _PatroliItem.fromDoc(DocumentSnapshot doc) {
    final d          = doc.data() as Map<String, dynamic>;
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
      id      : doc.id,
      waktu   : waktu,
      petugas : (d['namaSatpam']  as String? ?? '').isNotEmpty ? d['namaSatpam'] as String : '-',
      lokasi  : (d['blokPatroli'] as String? ?? '').isNotEmpty ? d['blokPatroli'] as String : '-',
      catatan : keterangan,
      selesai : selesai,
      rawData : d,
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

  List<QueryDocumentSnapshot> _sosDocs     = [];
  List<QueryDocumentSnapshot> _bantuanDocs = [];
  List<_SatpamData>           _satpamList  = [];
  List<_PatroliItem>          _patroliLog  = [];
  int                         _patroliAktif = 0;
  bool _loading = true;

  static DateTime get _startOfToday {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    final start = Timestamp.fromDate(_startOfToday);

    _sosSub = _db.collection('sosalert')
        .where('createdAt', isGreaterThanOrEqualTo: start)
        .snapshots()
        .listen((snap) {
      if (mounted) setState(() { _sosDocs = snap.docs; _loading = false; });
    });

    _bantuanSub = _db.collection('bantuanrequest')
        .where('createdAt', isGreaterThanOrEqualTo: start)
        .snapshots()
        .listen((snap) {
      if (mounted) setState(() => _bantuanDocs = snap.docs);
    });

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

  List<_LogItem> get _logAktivitas {
    final items = <_LogItem>[];

    for (final doc in _sosDocs) {
      final d     = doc.data() as Map<String, dynamic>;
      final waktu = (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final status = d['status'] as String? ?? 'PENDING';
      final tipe   = d['type']   as String? ?? 'call';
      items.add(_LogItem(
        id     : doc.id,
        type   : _LogType.sos,
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
      items.add(_LogItem(
        id     : doc.id,
        type   : _LogType.bantuan,
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
  void _showLogDetail(BuildContext context, _LogItem item) {
    showDialog(
      context: context,
      builder: (_) => _LogDetailDialog(item: item),
    );
  }

  // ── Detail dialog: Patroli ───────────────────────────────────────────────
  void _showPatroliDetail(BuildContext context, _PatroliItem item) {
    showDialog(
      context: context,
      builder: (_) => _PatroliDetailDialog(item: item),
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
                                        _LogAktivitasSection(
                                          items: _logAktivitas,
                                          onTap: (item) => _showLogDetail(context, item),
                                        ),
                                        const SizedBox(height: 20),
                                        _LogPatroliSection(
                                          logs: _patroliLog,
                                          onTap: (p) => _showPatroliDetail(context, p),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    flex: 1,
                                    child: _SatpamBertugasSection(satpamList: _satpamList),
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
// Stat cards
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
          label: 'SATPAM TERDAFTAR', value: satpamAktif.toString().padLeft(2, '0'),
          sub: 'Aktif', subIcon: Icons.check_circle_outline, subColor: const Color(0xFF16A34A),
        )),
        const SizedBox(width: 14),
        Expanded(child: _StatCard(
          label: 'SOS HARI INI', value: sosHariIni.toString().padLeft(2, '0'),
          sub: 'Panggilan', subIcon: Icons.emergency_outlined,
          subColor: sosHariIni > 0 ? const Color(0xFFDC2626) : AppColors.textGrey,
          valueColor: sosHariIni > 0 ? const Color(0xFFDC2626) : AppColors.textDark,
        )),
        const SizedBox(width: 14),
        Expanded(child: _StatCard(
          label: 'BANTUAN HARI INI', value: bantuanHariIni.toString().padLeft(2, '0'),
          sub: 'Permintaan', subIcon: Icons.support_agent_outlined, subColor: AppColors.primary,
        )),
        const SizedBox(width: 14),
        Expanded(child: _StatCard(
          label: 'PATROLI AKTIF', value: patroliAktif.toString().padLeft(2, '0'),
          sub: adaPatroli ? 'Sedang Berjalan' : 'Tidak Ada',
          subIcon: adaPatroli ? Icons.shield : Icons.shield_outlined,
          subColor: adaPatroli ? const Color(0xFF0D9488) : AppColors.textGrey,
          valueColor: adaPatroli ? const Color(0xFF0D9488) : AppColors.textDark,
        )),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label, required this.value, required this.sub,
    this.subIcon, required this.subColor, this.valueColor = AppColors.textDark,
  });
  final String label, value, sub;
  final IconData? subIcon;
  final Color subColor, valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.inter(fontSize: 11,
                fontWeight: FontWeight.w600, color: AppColors.textGrey, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.inter(fontSize: 36,
                fontWeight: FontWeight.bold, color: valueColor, height: 1)),
          ]),
          Row(children: [
            if (subIcon != null) ...[Icon(subIcon, size: 15, color: subColor), const SizedBox(width: 4)],
            Text(sub, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: subColor)),
          ]),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Log Aktivitas
// ─────────────────────────────────────────────────────────────────────────────

class _LogAktivitasSection extends StatelessWidget {
  const _LogAktivitasSection({required this.items, required this.onTap});
  final List<_LogItem> items;
  final ValueChanged<_LogItem> onTap;

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.now());
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(children: [
              Text('Log Aktivitas', style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(width: 8),
              if (items.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                  child: Text('${items.length}', style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              const Spacer(),
              Text(today, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey)),
            ]),
          ),
          const SizedBox(height: 10),
          Container(
            color: const Color(0xFFF8FAFC),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: const Row(children: [
              SizedBox(width: 70, child: _ColH('WAKTU')),
              SizedBox(width: 32),
              Expanded(flex: 2, child: _ColH('KEJADIAN')),
              Expanded(flex: 2, child: _ColH('UNIT / WARGA')),
              SizedBox(width: 110, child: _ColH('STATUS')),
              SizedBox(width: 50, child: _ColH('')),
            ]),
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(28),
              child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.check_circle_outline, size: 18, color: Color(0xFF16A34A)),
                const SizedBox(width: 8),
                Text('Tidak ada aktivitas hari ini.',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey)),
              ])),
            )
          else
            ...items.map((item) => _LogRow(item: item, onTap: () => onTap(item))),
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
    fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textGrey, letterSpacing: 0.4,
  ));
}

class _LogRow extends StatelessWidget {
  const _LogRow({required this.item, required this.onTap});
  final _LogItem item;
  final VoidCallback onTap;

  (Color, IconData) get _typeStyle => switch (item.type) {
    _LogType.sos     => (const Color(0xFFDC2626), Icons.emergency_outlined),
    _LogType.bantuan => (AppColors.primary,       Icons.support_agent_outlined),
    _LogType.patroli => (const Color(0xFF0D9488), Icons.shield_outlined),
  };

  Color get _statusColor {
    final s = item.status;
    if (s == 'Selesai')        return const Color(0xFF16A34A);
    if (s == 'Menuju Lokasi')  return AppColors.primary;
    if (s == 'Menunggu')       return const Color(0xFFF97316);
    return AppColors.textGrey;
  }

  @override
  Widget build(BuildContext context) {
    final (typeColor, typeIcon) = _typeStyle;
    final waktu = DateFormat('HH:mm').format(item.waktu);
    final hasFoto = item.fotoUrls.isNotEmpty;

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey.shade100))),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(children: [
          SizedBox(width: 70, child: Text(waktu, style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark))),
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: typeColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(typeIcon, size: 15, color: typeColor),
          ),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: Text(item.judul, style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark))),
          Expanded(flex: 2, child: Text(item.sub, style: GoogleFonts.inter(
              fontSize: 12, color: AppColors.textGrey), overflow: TextOverflow.ellipsis)),
          SizedBox(width: 110, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 6, height: 6,
                  decoration: BoxDecoration(color: _statusColor, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Flexible(child: Text(item.status, style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor),
                  overflow: TextOverflow.ellipsis)),
            ]),
          )),
          // Tombol detail
          SizedBox(
            width: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (hasFoto)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(Icons.photo_outlined,
                        size: 14, color: AppColors.primary.withOpacity(0.7)),
                  ),
                Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Log Patroli
// ─────────────────────────────────────────────────────────────────────────────

class _LogPatroliSection extends StatelessWidget {
  const _LogPatroliSection({required this.logs, required this.onTap});
  final List<_PatroliItem> logs;
  final ValueChanged<_PatroliItem> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(children: [
              Text('Log Patroli Hari Ini', style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              if (logs.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488), borderRadius: BorderRadius.circular(10)),
                  child: Text('${logs.length}', style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ]),
          ),
          const SizedBox(height: 12),
          Container(
            color: const Color(0xFFF8FAFC),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: const Row(children: [
              SizedBox(width: 90, child: _ColH('WAKTU')),
              Expanded(flex: 2, child: _ColH('PETUGAS')),
              Expanded(flex: 2, child: _ColH('BLOK / AREA')),
              Expanded(flex: 3, child: _ColH('KETERANGAN')),
              SizedBox(width: 90, child: _ColH('STATUS')),
              SizedBox(width: 40, child: _ColH('')),
            ]),
          ),
          if (logs.isEmpty)
            Padding(
              padding: const EdgeInsets.all(28),
              child: Center(child: Text('Belum ada log patroli hari ini.',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey))),
            )
          else
            ...logs.map((log) => _PatroliRow(log: log, onTap: () => onTap(log))),
        ],
      ),
    );
  }
}

class _PatroliRow extends StatelessWidget {
  const _PatroliRow({required this.log, required this.onTap});
  final _PatroliItem log;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasFoto = log.fotoUrls.isNotEmpty;
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade100))),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(children: [
          SizedBox(width: 90, child: Text(log.waktu, style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark))),
          Expanded(flex: 2, child: Text(log.petugas, style: GoogleFonts.inter(
              fontSize: 13, color: AppColors.textDark))),
          Expanded(flex: 2, child: Text(log.lokasi, style: GoogleFonts.inter(
              fontSize: 13, color: AppColors.textDark))),
          Expanded(flex: 3, child: Text(log.catatan, style: GoogleFonts.inter(
              fontSize: 13, color: AppColors.textDark), overflow: TextOverflow.ellipsis)),
          SizedBox(width: 90, child: log.selesai
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                  child: Text('Selesai', style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textGrey)))
              : Row(children: [
                  Container(width: 8, height: 8,
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('Berjalan', style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                ])),
          // Arrow + foto indicator
          SizedBox(
            width: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (hasFoto)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(Icons.photo_outlined,
                        size: 14, color: const Color(0xFF0D9488).withOpacity(0.8)),
                  ),
                Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail Dialog: Log Aktivitas (SOS / Bantuan)
// ─────────────────────────────────────────────────────────────────────────────

class _LogDetailDialog extends StatelessWidget {
  const _LogDetailDialog({required this.item});
  final _LogItem item;

  (Color, IconData, String) get _typeTheme => switch (item.type) {
    _LogType.sos     => (const Color(0xFFDC2626), Icons.emergency_outlined,  'SOS / Darurat'),
    _LogType.bantuan => (AppColors.primary,       Icons.support_agent_outlined, 'Bantuan Satpam'),
    _LogType.patroli => (const Color(0xFF0D9488), Icons.shield_outlined,     'Patroli'),
  };

  @override
  Widget build(BuildContext context) {
    final d             = item.rawData;
    final (col, icon, typeLabel) = _typeTheme;
    final waktuFmt      = DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(item.waktu);
    final fotos         = item.fotoUrls;

    // Ambil field sesuai tipe
    final namaWarga = d['namaWarga']   as String? ?? '-';
    final blok      = d['blok']        as String? ?? '-';
    final unit      = d['nomorUnit']   as String? ?? '-';
    final kategori  = d['kategori']    as String? ?? '-';
    final catatan   = d['catatan']     as String?
                      ?? d['keterangan'] as String? ?? '';
    final satpam    = d['namaSatpam']  as String? ?? '-';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 80, vertical: 40),
      child: SizedBox(
        width: 700,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Kiri: info ──────────────────────────────────────────
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: col.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10)),
                        child: Icon(icon, color: col, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.judul, style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold, fontSize: 16,
                              color: AppColors.textDark)),
                          Text(typeLabel, style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.textGrey)),
                        ],
                      )),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.close, color: Colors.grey.shade400, size: 20),
                      ),
                    ]),

                    const Divider(height: 28),

                    _DRow('Warga',   namaWarga),
                    _DRow('Blok',    '$blok – Unit $unit'),
                    if (kategori != '-') _DRow('Kategori', kategori),
                    _DRow('Waktu',   waktuFmt),
                    _DRow('Status',  item.status),
                    if (satpam != '-') _DRow('Satpam',  satpam),

                    if (catatan.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text('Catatan', style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: AppColors.textGrey)),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(catatan, style: GoogleFonts.inter(
                            fontSize: 13, height: 1.5, color: AppColors.textDark)),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Kanan: foto ─────────────────────────────────────────
              const SizedBox(width: 24),
              SizedBox(width: 220, child: _FotoColumn(fotos: fotos)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail Dialog: Patroli
// ─────────────────────────────────────────────────────────────────────────────

class _PatroliDetailDialog extends StatelessWidget {
  const _PatroliDetailDialog({required this.item});
  final _PatroliItem item;

  @override
  Widget build(BuildContext context) {
    final fotos = item.fotoUrls;
    final d     = item.rawData;

    // Waktu kejadian dari createdAt atau jamMulai
    final createdAt = d['createdAt'] as Timestamp?;
    final tglFmt = createdAt != null
        ? DateFormat('dd MMM yyyy', 'id_ID').format(createdAt.toDate())
        : '-';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 80, vertical: 40),
      child: SizedBox(
        width: 700,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Kiri: info ──────────────────────────────────────────
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.shield_outlined,
                            color: Color(0xFF0D9488), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Detail Patroli', style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold, fontSize: 16,
                              color: AppColors.textDark)),
                          Text('Log Patroli Harian', style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.textGrey)),
                        ],
                      )),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.close, color: Colors.grey.shade400, size: 20),
                      ),
                    ]),

                    const Divider(height: 28),

                    _DRow('Petugas',      item.petugas),
                    _DRow('Blok / Area',  item.lokasi),
                    _DRow('Tanggal',      tglFmt),
                    _DRow('Jam Mulai',    item.jamMulai.isNotEmpty ? item.jamMulai : '-'),
                    _DRow('Jam Selesai',  item.jamSelesai.isNotEmpty ? item.jamSelesai : '— Belum selesai'),
                    _DRow('Status',       item.selesai ? 'Selesai' : 'Sedang Berjalan'),

                    if (item.quickTags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text('Kondisi Ditemukan', style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: AppColors.textGrey)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: item.quickTags.map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D9488).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: const Color(0xFF0D9488).withOpacity(0.3)),
                          ),
                          child: Text(tag, style: GoogleFonts.inter(
                              fontSize: 12, color: const Color(0xFF0D9488),
                              fontWeight: FontWeight.w500)),
                        )).toList(),
                      ),
                    ],

                    if (item.catatan.isNotEmpty && item.catatan != '-') ...[
                      const SizedBox(height: 12),
                      Text('Keterangan', style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: AppColors.textGrey)),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(item.catatan, style: GoogleFonts.inter(
                            fontSize: 13, height: 1.5, color: AppColors.textDark)),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Kanan: foto ─────────────────────────────────────────
              const SizedBox(width: 24),
              SizedBox(width: 220, child: _FotoColumn(fotos: fotos)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Foto column (kanan dialog)
// ─────────────────────────────────────────────────────────────────────────────

class _FotoColumn extends StatefulWidget {
  const _FotoColumn({required this.fotos});
  final List<String> fotos;

  @override
  State<_FotoColumn> createState() => _FotoColumnState();
}

class _FotoColumnState extends State<_FotoColumn> {
  int _selected = 0;

  void _open(BuildContext ctx, int index) {
    showDialog(
      context: ctx,
      barrierColor: Colors.black87,
      builder: (_) => _FullscreenViewer(urls: widget.fotos, initial: index),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fotos = widget.fotos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.photo_library_outlined, size: 14, color: AppColors.textGrey),
          const SizedBox(width: 6),
          Text('Foto Bukti (${fotos.length})', style: GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textGrey)),
        ]),
        const SizedBox(height: 10),

        if (fotos.isEmpty)
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.image_not_supported_outlined,
                    size: 28, color: Colors.grey.shade400),
                const SizedBox(height: 6),
                Text('Tidak ada foto', style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textGrey)),
              ],
            )),
          )
        else ...[
          // Main preview
          GestureDetector(
            onTap: () => _open(context, _selected),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(children: [
                Image.network(
                  fotos[_selected],
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, prog) => prog == null ? child : Container(
                    width: double.infinity, height: 160,
                    color: Colors.grey.shade100,
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorBuilder: (_, __, ___) => Container(
                    width: double.infinity, height: 160,
                    color: Colors.grey.shade100,
                    child: Icon(Icons.broken_image_outlined,
                        size: 32, color: Colors.grey.shade400),
                  ),
                ),
                Positioned(bottom: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                    child: const Icon(Icons.zoom_in, size: 14, color: Colors.white),
                  )),
                if (fotos.length > 1)
                  Positioned(top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                      child: Text('${_selected + 1}/${fotos.length}',
                          style: GoogleFonts.inter(fontSize: 10,
                              color: Colors.white, fontWeight: FontWeight.w600)),
                    )),
              ]),
            ),
          ),

          // Thumbnails jika > 1
          if (fotos.length > 1) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: fotos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => setState(() => _selected = i),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Stack(children: [
                      Image.network(fotos[i], width: 52, height: 52, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(width: 52, height: 52,
                              color: Colors.grey.shade200,
                              child: Icon(Icons.broken_image_outlined, size: 20,
                                  color: Colors.grey.shade400))),
                      if (_selected == i)
                        Container(width: 52, height: 52,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.primary, width: 2),
                              borderRadius: BorderRadius.circular(6))),
                    ]),
                  ),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fullscreen viewer
// ─────────────────────────────────────────────────────────────────────────────

class _FullscreenViewer extends StatefulWidget {
  const _FullscreenViewer({required this.urls, required this.initial});
  final List<String> urls;
  final int initial;

  @override
  State<_FullscreenViewer> createState() => _FullscreenViewerState();
}

class _FullscreenViewerState extends State<_FullscreenViewer> {
  late int _current;

  @override
  void initState() { super.initState(); _current = widget.initial; }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            if (widget.urls.length > 1)
              Text('${_current + 1} / ${widget.urls.length}',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13))
            else const SizedBox(),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              widget.urls[_current],
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                height: 200, color: Colors.grey.shade800,
                child: const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48),
              ),
            ),
          ),
          if (widget.urls.length > 1) ...[
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _NavBtn(Icons.arrow_back_ios_new, _current > 0,
                  () => setState(() => _current--)),
              const SizedBox(width: 16),
              _NavBtn(Icons.arrow_forward_ios, _current < widget.urls.length - 1,
                  () => setState(() => _current++)),
            ]),
          ],
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  const _NavBtn(this.icon, this.enabled, this.onTap);
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: enabled ? Colors.white24 : Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: enabled ? Colors.white : Colors.white38, size: 18),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail row helper
// ─────────────────────────────────────────────────────────────────────────────

class _DRow extends StatelessWidget {
  const _DRow(this.label, this.value);
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 110, child: Text(label,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey))),
        Expanded(child: Text(value, style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark))),
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
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            child: Row(children: [
              Text('Satpam Terdaftar', style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                    color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                child: Text('${satpamList.length} Aktif', style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
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
                  border: Border(top: BorderSide(color: Colors.grey.shade100))),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withOpacity(0.12),
                  child: Text(_initials(s.nama), style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.nama, style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                    if (s.lokasi != '-')
                      Text(s.lokasi, style: GoogleFonts.inter(
                          fontSize: 11, color: AppColors.textGrey)),
                  ],
                )),
                Container(width: 8, height: 8,
                    decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle)),
              ]),
            )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
