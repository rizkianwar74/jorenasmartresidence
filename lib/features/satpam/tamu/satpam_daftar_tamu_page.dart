import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/satpam_bottom_nav.dart';
import '../../security/data/security_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

class _TamuItem {
  const _TamuItem({
    required this.id,
    required this.namaTamu,
    required this.kategoriKunjungan,
    required this.jenisKendaraan,
    required this.nomorPlat,
    required this.blokTujuan,
    required this.nomorRumahTujuan,
    required this.keterangan,
    required this.namaSatpam,
    required this.status,
    required this.waktuMasuk,
    this.waktuKeluar,
  });

  final String    id;
  final String    namaTamu;
  final String    kategoriKunjungan;
  final String    jenisKendaraan;
  final String    nomorPlat;
  final String    blokTujuan;
  final String    nomorRumahTujuan;
  final String    keterangan;
  final String    namaSatpam;
  final String    status;
  final DateTime  waktuMasuk;
  final DateTime? waktuKeluar;

  bool get isMasuk => status == 'MASUK';

  String get tujuanLabel => '$blokTujuan No. $nomorRumahTujuan';

  static DateTime _ts(dynamic v) =>
      v is Timestamp ? v.toDate() : DateTime.now();

  factory _TamuItem.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return _TamuItem(
      id                : doc.id,
      namaTamu          : d['namaTamu']          as String? ?? '-',
      kategoriKunjungan : d['kategoriKunjungan'] as String? ?? '-',
      jenisKendaraan    : d['jenisKendaraan']    as String? ?? '-',
      nomorPlat         : d['nomorPlat']         as String? ?? '',
      blokTujuan        : d['blokTujuan']        as String? ?? '-',
      nomorRumahTujuan  : d['nomorRumahTujuan']  as String? ?? '-',
      keterangan        : d['keterangan']        as String? ?? '',
      namaSatpam        : d['namaSatpam']        as String? ?? '-',
      status            : d['status']            as String? ?? 'MASUK',
      waktuMasuk        : _ts(d['waktuMasuk']),
      waktuKeluar       : d['waktuKeluar'] != null ? _ts(d['waktuKeluar']) : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class SatpamDaftarTamuPage extends StatefulWidget {
  const SatpamDaftarTamuPage({super.key});

  @override
  State<SatpamDaftarTamuPage> createState() => _SatpamDaftarTamuPageState();
}

class _SatpamDaftarTamuPageState extends State<SatpamDaftarTamuPage> {
  static const double _maxWidth = 600.0;

  List<_TamuItem> _items  = [];
  bool            _loading = true;
  String          _filter  = 'Semua'; // Semua | MASUK | KELUAR

  StreamSubscription<QuerySnapshot>? _sub;

  static DateTime get _startOfToday {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  @override
  void initState() {
    super.initState();
    final start = _startOfToday;
    final end   = _startOfToday.add(const Duration(days: 1));

    _sub = SecurityRepository.instance
        .tamuRentangStream(start, end)
        .listen((snap) {
      if (!mounted) return;
      setState(() {
        _items   = snap.docs.map(_TamuItem.fromDoc).toList();
        _loading = false;
      });
    }, onError: (_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  List<_TamuItem> get _filtered => _filter == 'Semua'
      ? _items
      : _items.where((t) => t.status == _filter).toList();

  int get _countMasuk  => _items.where((t) => t.isMasuk).length;
  int get _countKeluar => _items.where((t) => !t.isMasuk).length;

  // ── Tandai Keluar ──────────────────────────────────────────────────────────
  Future<void> _tandaiKeluar(String id) async {
    await SecurityRepository.instance.tandaiTamuKeluar(id);
  }

  // ── Detail bottom sheet ────────────────────────────────────────────────────
  void _showDetail(_TamuItem t) {
    bool marking = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Text(
                          t.namaTamu.isNotEmpty
                              ? t.namaTamu[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.namaTamu,
                                style: GoogleFonts.inter(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0D1B2A))),
                            const SizedBox(height: 2),
                            Text(t.kategoriKunjungan,
                                style: GoogleFonts.inter(
                                    fontSize: 13, color: AppColors.textGrey)),
                          ],
                        ),
                      ),
                      // Badge status
                      _StatusBadge(isMasuk: t.isMasuk),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                Divider(height: 1, color: Colors.grey.shade100),
                const SizedBox(height: 16),

                // Info rows
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _DetailRow('Tujuan',       t.tujuanLabel),
                      _DetailRow('Kendaraan',
                          t.nomorPlat.isNotEmpty
                              ? '${t.jenisKendaraan} · ${t.nomorPlat}'
                              : t.jenisKendaraan),
                      _DetailRow('Waktu Masuk',
                          DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(t.waktuMasuk)),
                      _DetailRow('Waktu Keluar',
                          t.waktuKeluar != null
                              ? DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(t.waktuKeluar!)
                              : '— Belum keluar'),
                      _DetailRow('Dicatat oleh', t.namaSatpam),
                      if (t.keterangan.isNotEmpty)
                        _DetailRow('Keterangan', t.keterangan),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Tombol Tandai Keluar
                if (t.isMasuk)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: marking
                            ? null
                            : () async {
                                setS(() => marking = true);
                                try {
                                  await _tandaiKeluar(t.id);
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${t.namaTamu} sudah dicatat keluar'),
                                        backgroundColor: const Color(0xFF16A34A),
                                      ),
                                    );
                                  }
                                } catch (_) {
                                  setS(() => marking = false);
                                }
                              },
                        icon: marking
                            ? const SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.logout_rounded,
                                size: 18, color: Colors.white),
                        label: Text(
                          marking ? 'Menyimpan...' : 'Tandai Keluar',
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.now());

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
                constraints: const BoxConstraints(maxWidth: _maxWidth),
                child: Column(
                  children: [
                    // ── App Bar ─────────────────────────────────────────
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(4, 8, 20, 0),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                  size: 20, color: Color(0xFF0D1B2A)),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Daftar Tamu Hari Ini',
                                      style: GoogleFonts.inter(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF0D1B2A))),
                                  Text(today,
                                      style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppColors.textGrey)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Summary chips ────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          _SummaryChip(
                            label: 'Total',
                            count: _items.length,
                            color: AppColors.primary,
                            isActive: _filter == 'Semua',
                            onTap: () => setState(() => _filter = 'Semua'),
                          ),
                          const SizedBox(width: 10),
                          _SummaryChip(
                            label: 'Masuk',
                            count: _countMasuk,
                            color: AppColors.primary,
                            isActive: _filter == 'MASUK',
                            onTap: () => setState(() => _filter = 'MASUK'),
                          ),
                          const SizedBox(width: 10),
                          _SummaryChip(
                            label: 'Keluar',
                            count: _countKeluar,
                            color: const Color(0xFF16A34A),
                            isActive: _filter == 'KELUAR',
                            onTap: () => setState(() => _filter = 'KELUAR'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── List ─────────────────────────────────────────────
                    Expanded(
                      child: _loading
                          ? const Center(
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : _filtered.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.people_outline,
                                          size: 48, color: Colors.grey.shade400),
                                      const SizedBox(height: 12),
                                      Text(
                                        _filter == 'Semua'
                                            ? 'Belum ada tamu hari ini'
                                            : 'Tidak ada tamu dengan status $_filter',
                                        style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: AppColors.textGrey),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                      20, 0, 20, 100),
                                  itemCount: _filtered.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (_, i) =>
                                      _TamuTile(
                                        item: _filtered[i],
                                        onTap: () =>
                                            _showDetail(_filtered[i]),
                                      ),
                                ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom Nav ──────────────────────────────────────────────
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: SatpamBottomNav(currentIndex: 0),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary chip (filter)
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.count,
    required this.color,
    required this.isActive,
    required this.onTap,
  });
  final String label;
  final int    count;
  final Color  color;
  final bool   isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isActive ? color : Colors.grey.shade300),
          boxShadow: isActive
              ? [BoxShadow(color: color.withValues(alpha: 0.25),
                  blurRadius: 8, offset: const Offset(0, 3))]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : AppColors.textGrey)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withValues(alpha: 0.3)
                    : color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$count',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.white : color)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tamu tile (list item)
// ─────────────────────────────────────────────────────────────────────────────

class _TamuTile extends StatelessWidget {
  const _TamuTile({required this.item, required this.onTap});
  final _TamuItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final waktuFmt = DateFormat('HH:mm', 'id_ID').format(item.waktuMasuk);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
            // Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                item.namaTamu.isNotEmpty
                    ? item.namaTamu[0].toUpperCase()
                    : '?',
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.namaTamu,
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0D1B2A))),
                  const SizedBox(height: 3),
                  Row(children: [
                    Icon(Icons.location_on_outlined,
                        size: 12, color: AppColors.textGrey),
                    const SizedBox(width: 3),
                    Text(item.tujuanLabel,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.textGrey)),
                    const SizedBox(width: 8),
                    Container(
                      width: 3, height: 3,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade400, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(item.kategoriKunjungan,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.textGrey)),
                  ]),
                ],
              ),
            ),

            // Waktu + status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(waktuFmt,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0D1B2A))),
                const SizedBox(height: 5),
                _StatusBadge(isMasuk: item.isMasuk),
              ],
            ),

            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: Color(0xFFB0BEC5)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status badge
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isMasuk});
  final bool isMasuk;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isMasuk
            ? AppColors.primary.withValues(alpha: 0.1)
            : const Color(0xFF16A34A).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMasuk ? Icons.login_rounded : Icons.logout_rounded,
            size: 10,
            color: isMasuk ? AppColors.primary : const Color(0xFF16A34A),
          ),
          const SizedBox(width: 4),
          Text(
            isMasuk ? 'MASUK' : 'KELUAR',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isMasuk ? AppColors.primary : const Color(0xFF16A34A),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail row helper
// ─────────────────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textGrey)),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF0D1B2A))),
          ),
        ],
      ),
    );
  }
}
