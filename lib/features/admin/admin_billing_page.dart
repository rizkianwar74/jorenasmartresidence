// Halaman Billing Admin.
// Tampilkan list tagihan semua warga dari Firestore (real-time) +
// tombol Hubungi (WhatsApp / Telepon) untuk yang belum bayar.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import 'data/admin_repository.dart';
import '../pembayaran/data/payment_repository.dart';
import '../pembayaran/models/tagihan_model.dart';
import '../../tool/seed_tagihan.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_top_bar.dart';
import 'admin_payment_detail_page.dart';

class AdminBillingPage extends StatefulWidget {
  const AdminBillingPage({super.key});

  @override
  State<AdminBillingPage> createState() => _AdminBillingPageState();
}

class _AdminBillingPageState extends State<AdminBillingPage> {
  String _filter = 'Semua'; // Semua | Lunas | Belum Bayar | Jatuh Tempo
  int? _filterBulan; // 1-12, null = semua bulan
  int? _filterTahun; // null = semua tahun

  // UID satpam — diambil sekali saat halaman dibuka; dipakai untuk
  // menyaring tagihan agar hanya warga (role: user) yang tampil di billing.
  Set<String> _satpamUids = {};

  // Snapshot tagihan terakhir dari stream — dipakai oleh dialog Buat Tagihan
  // untuk mendeteksi tagihan terakhir milik user yang dipilih.
  List<TagihanModel> _allTagihan = [];

  @override
  void initState() {
    super.initState();
    SeedTagihan.autoSeedIfNeeded();
    _loadSatpamUids();
  }

  Future<void> _loadSatpamUids() async {
    final uids = await AdminRepository.instance.fetchSatpamUids();
    if (!mounted) return;
    setState(() => _satpamUids = uids);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          const AdminSidebar(activePage: AdminPage.billing),
          Expanded(
            child: Column(
              children: [
                const AdminTopBar(
                  searchHint: 'Cari nama warga atau unit...',
                ),
                Expanded(
                  child: StreamBuilder<List<TagihanModel>>(
                    stream: PaymentRepository.watchAllTagihan(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary));
                      }
                      if (snap.hasError) {
                        return _CenterMessage(
                            icon: Icons.error_outline,
                            text: 'Gagal memuat: ${snap.error}');
                      }
                      // Tampilkan hanya tagihan warga (role: user).
                      final all = (snap.data ?? const <TagihanModel>[])
                          .where((t) => !_satpamUids.contains(t.userId))
                          .toList();
                      // Simpan snapshot untuk dipakai dialog Buat Tagihan.
                      _allTagihan = all;
                      return _BillingContent(
                        all: all,
                        filter: _filter,
                        filterBulan: _filterBulan,
                        filterTahun: _filterTahun,
                        onFilter: (f) => setState(() => _filter = f),
                        onFilterBulan: (b) => setState(() => _filterBulan = b),
                        onFilterTahun: (t) => setState(() => _filterTahun = t),
                        onHubungi: _showHubungiMenu,
                        onEditStatus: _showEditStatusDialog,
                        onDetail: _showDetailPage,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Popup menu WhatsApp + Telepon.
  void _showHubungiMenu(TagihanModel t) {
    final rawPhone = (t.nomorHp ?? '').replaceAll(RegExp(r'[^\d]'), '');
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Hubungi ${t.namaResiden}',
                style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.chat, color: Colors.green),
              title: Text('WhatsApp', style: GoogleFonts.inter(fontSize: 14)),
              subtitle: Text(rawPhone.isEmpty ? 'Nomor tidak tersedia' : rawPhone,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey)),
              onTap: () {
                Navigator.pop(context);
                _openWhatsApp(rawPhone, t);
              },
            ),
            ListTile(
              leading: const Icon(Icons.call, color: AppColors.primary),
              title: Text('Telepon', style: GoogleFonts.inter(fontSize: 14)),
              onTap: () {
                Navigator.pop(context);
                _openCall(rawPhone);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _openWhatsApp(String phone, TagihanModel t) async {
    if (phone.isEmpty) {
      _toast('Nomor HP warga tidak tersedia.');
      return;
    }
    final msg = Uri.encodeComponent(
        'Halo ${t.namaResiden}, ini pengingat dari pengelola Jorena Smart Residence. '
        'Iuran periode ${t.periodeLabel} (${t.jumlahFormatted}) belum dibayar. '
        'Mohon segera melakukan pembayaran. Terima kasih.');
    final url = 'https://wa.me/$phone?text=$msg';
    await _launch(url);
  }

  Future<void> _openCall(String phone) async {
    if (phone.isEmpty) {
      _toast('Nomor HP warga tidak tersedia.');
      return;
    }
    await _launch('tel:$phone');
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _toast('Tidak bisa membuka link.');
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Bottom sheet untuk ubah status tagihan secara manual.
  void _showEditStatusDialog(TagihanModel t) {
    final isLunas = t.status == StatusTagihan.lunas;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ubah Status Pembayaran',
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.bold,
                    color: AppColors.textDark),
              ),
              const SizedBox(height: 4),
              Text(
                '${t.namaResiden} · ${t.periodeLabel}',
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textGrey),
              ),
              const SizedBox(height: 6),
              // Status saat ini
              Row(
                children: [
                  Text('Status saat ini: ',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textGrey)),
                  _StatusBadge(status: t.status),
                ],
              ),
              const SizedBox(height: 20),
              // Pilihan aksi
              if (!isLunas) ...[
                _EditStatusTile(
                  icon: Icons.person_outline,
                  iconColor: Colors.green.shade600,
                  bgColor: Colors.green.shade50,
                  title: 'Bayar Tunai 1 Bulan',
                  subtitle: 'Tandai ${t.periodeLabel} sebagai lunas',
                  onTap: () async {
                    Navigator.pop(context);
                    await _applyStatusManual(t, StatusTagihan.lunas);
                  },
                ),
                const SizedBox(height: 8),
                _EditStatusTile(
                  icon: Icons.checklist_rounded,
                  iconColor: Colors.green.shade800,
                  bgColor: Colors.green.shade50,
                  title: 'Bayar Tunai Beberapa Bulan',
                  subtitle: 'Tandai semua tunggakan ${t.namaResiden} sebagai lunas',
                  onTap: () async {
                    Navigator.pop(context);
                    await _applySemuaTunggakanLunas(t);
                  },
                ),
              ],
              if (isLunas)
                _EditStatusTile(
                  icon: Icons.undo_rounded,
                  iconColor: Colors.red.shade600,
                  bgColor: Colors.red.shade50,
                  title: 'Tandai Belum Bayar',
                  subtitle: 'Batalkan status lunas (hapus catatan bayar)',
                  onTap: () async {
                    Navigator.pop(context);
                    await _applyStatusManual(t, StatusTagihan.belumBayar);
                  },
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Batal',
                      style: GoogleFonts.inter(
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _applyStatusManual(
      TagihanModel t, StatusTagihan newStatus) async {
    try {
      await PaymentRepository.setStatusManual(
          tagihanId: t.id, status: newStatus);
      if (!mounted) return;
      final label =
          newStatus == StatusTagihan.lunas ? 'Lunas' : 'Belum Bayar';
      _toast('${t.namaResiden} ditandai $label.');
    } catch (e) {
      if (!mounted) return;
      _toast('Gagal mengubah status: $e');
    }
  }

  /// Tandai SEMUA tagihan belum bayar milik user ini sebagai lunas sekaligus.
  Future<void> _applySemuaTunggakanLunas(TagihanModel t) async {
    final now = DateTime.now();
    final currentKey = now.year * 100 + now.month;

    // Kumpulkan semua tagihan wajib (periodeKey ≤ sekarang) yang belum lunas.
    final tunggakan = _allTagihan
        .where((x) =>
            x.userId == t.userId &&
            x.periodeKey <= currentKey &&
            x.status != StatusTagihan.lunas)
        .toList();

    if (tunggakan.isEmpty) {
      _toast('Tidak ada tunggakan untuk ${t.namaResiden}.');
      return;
    }

    try {
      await PaymentRepository.markManyAsLunas(
        tagihanIds : tunggakan.map((x) => x.id).toList(),
        metodeBayar: 'Tunai (Manual)',
      );
      if (!mounted) return;
      _toast('${tunggakan.length} tagihan ${t.namaResiden} ditandai lunas.');
    } catch (e) {
      if (!mounted) return;
      _toast('Gagal mengubah status: $e');
    }
  }

  /// Navigasi ke halaman detail pembayaran penghuni.
  void _showDetailPage(TagihanModel t) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AdminPaymentDetailPage(
        userId      : t.userId ?? '',
        namaResiden : t.namaResiden,
        blok        : t.blok,
        nomorUnit   : t.nomorUnit,
        nomorHp     : t.nomorHp,
      ),
    ));
  }

  /// Dialog buat tagihan di muka — admin pilih BERAPA BULAN ke depan,
  /// sistem auto-detect dari tagihan terakhir user (lunas atau tidak).
  void _showBuatTagihanDialog(TagihanModel t) {
    // Cari tagihan terbaru milik user ini (bulanIndex + tahun tertinggi).
    final userTagihan =
        _allTagihan.where((x) => x.userId == t.userId).toList();
    int baseBulan = DateTime.now().month;
    int baseTahun = DateTime.now().year;
    if (userTagihan.isNotEmpty) {
      final latest = userTagihan.reduce((a, b) =>
          (a.tahun * 12 + a.bulanIndex) > (b.tahun * 12 + b.bulanIndex)
              ? a
              : b);
      baseBulan = latest.bulanIndex;
      baseTahun = latest.tahun;
    }

    // Helper: hitung N bulan setelah base.
    List<Map<String, int>> computeMonths(int count) {
      final result = <Map<String, int>>[];
      int b = baseBulan, y = baseTahun;
      for (int i = 0; i < count; i++) {
        b++;
        if (b > 12) { b = 1; y++; }
        result.add({'bulan': b, 'tahun': y});
      }
      return result;
    }

    int buatCount = 1;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          final months  = computeMonths(buatCount);
          final preview = months
              .map((m) =>
                  '${bulanPanjangList[m['bulan']! - 1]} ${m['tahun']}')
              .join(' · ');
          final totalBayar =
              formatRupiah(PaymentRepository.iuranBulanan * buatCount);

          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Buat Tagihan di Muka',
              style: GoogleFonts.inter(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info warga
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.namaResiden,
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark)),
                            Text(t.unitLabel,
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.textGrey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Tagihan terakhir
                Text(
                  'Tagihan terakhir: '
                  '${bulanPanjangList[baseBulan - 1]} $baseTahun',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textGrey),
                ),
                const SizedBox(height: 14),

                // Stepper berapa bulan ke depan
                Text('Buat tagihan ke depan:',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textGrey)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _DlgStepBtn(
                      icon: Icons.remove,
                      enabled: buatCount > 1,
                      onTap: () => setDlg(() => buatCount--),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        '$buatCount bulan',
                        style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark),
                      ),
                    ),
                    _DlgStepBtn(
                      icon: Icons.add,
                      enabled: buatCount < 6,
                      onTap: () => setDlg(() => buatCount++),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Preview bulan yang akan dibuat
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Periode yang dibuat:',
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textGrey)),
                      const SizedBox(height: 4),
                      Text(preview,
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textDark)),
                      const SizedBox(height: 4),
                      Text('Total: $totalBayar',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary)),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Batal',
                    style: GoogleFonts.inter(color: AppColors.textGrey)),
              ),
              ElevatedButton(
                onPressed: () async {
                  final monthsToBuat = computeMonths(buatCount);
                  Navigator.pop(ctx);
                  try {
                    int created = 0;
                    for (final m in monthsToBuat) {
                      final ok =
                          await PaymentRepository.createTagihanForMonth(
                        userId      : t.userId      ?? '',
                        namaResiden : t.namaResiden,
                        nomorHp     : t.nomorHp     ?? '',
                        blok        : t.blok,
                        nomorUnit   : t.nomorUnit,
                        bulanIndex  : m['bulan']!,
                        tahun       : m['tahun']!,
                      );
                      if (ok) created++;
                    }
                    if (!mounted) return;
                    _toast(created > 0
                        ? '$created tagihan berhasil dibuat untuk '
                            '${t.namaResiden}.'
                        : 'Semua tagihan tersebut sudah ada.');
                  } catch (e) {
                    if (!mounted) return;
                    _toast('Gagal membuat tagihan: $e');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Buat $buatCount Tagihan',
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Konten utama ─────────────────────────────────────────────────────────────
class _BillingContent extends StatefulWidget {
  const _BillingContent({
    required this.all,
    required this.filter,
    required this.filterBulan,
    required this.filterTahun,
    required this.onFilter,
    required this.onFilterBulan,
    required this.onFilterTahun,
    required this.onHubungi,
    required this.onEditStatus,
    required this.onDetail,
  });

  final List<TagihanModel> all;
  final String filter;
  final int? filterBulan; // 1-12, null = semua bulan
  final int? filterTahun; // null = semua tahun
  final ValueChanged<String> onFilter;
  final ValueChanged<int?> onFilterBulan;
  final ValueChanged<int?> onFilterTahun;
  final ValueChanged<TagihanModel> onHubungi;
  final ValueChanged<TagihanModel> onEditStatus;
  final ValueChanged<TagihanModel> onDetail;

  @override
  State<_BillingContent> createState() => _BillingContentState();
}

class _BillingContentState extends State<_BillingContent> {
  int _currentPage = 1;
  static const int _pageSize = 8;

  // 'warga' = satu baris per penghuni; 'tagihan' = satu baris per dokumen tagihan.
  String _viewMode = 'warga';

  // Reset ke page 1 tiap filter / data / view mode berubah.
  @override
  void didUpdateWidget(covariant _BillingContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter != widget.filter ||
        oldWidget.filterBulan != widget.filterBulan ||
        oldWidget.filterTahun != widget.filterTahun) {
      _currentPage = 1;
    }
  }

  // ── Resident summary (view mode: warga) ─────────────────────────────────────

  /// Kelompokkan semua tagihan per userId → satu _ResidentSummary per warga.
  /// Diurutkan: jatuh tempo → belum bayar → lunas; lalu nama A–Z.
  List<_ResidentSummary> get _residentSummaries {
    final Map<String, List<TagihanModel>> grouped = {};
    for (final t in widget.all) {
      final uid = t.userId ?? '';
      if (uid.isEmpty) continue;
      grouped.putIfAbsent(uid, () => []).add(t);
    }
    final summaries =
        grouped.values.map(_ResidentSummary.new).toList();
    const order = {
      StatusTagihan.jatuhTempo: 0,
      StatusTagihan.belumBayar: 1,
      StatusTagihan.pending   : 1,
      StatusTagihan.lunas     : 2,
    };
    summaries.sort((a, b) {
      final diff =
          (order[a.overallStatus] ?? 1) - (order[b.overallStatus] ?? 1);
      return diff != 0 ? diff : a.namaResiden.compareTo(b.namaResiden);
    });
    return summaries;
  }

  List<_ResidentSummary> get _filteredResidents {
    final all = _residentSummaries;
    return switch (widget.filter) {
      'Lunas'       => all.where((r) => r.overallStatus == StatusTagihan.lunas).toList(),
      'Belum Bayar' => all.where((r) => r.overallStatus == StatusTagihan.belumBayar).toList(),
      'Jatuh Tempo' => all.where((r) => r.overallStatus == StatusTagihan.jatuhTempo).toList(),
      _             => all,
    };
  }

  int get _totalResidentPages =>
      (_filteredResidents.length / _pageSize).ceil().clamp(1, 9999);

  List<_ResidentSummary> get _paginatedResidents {
    final page  = _currentPage.clamp(1, _totalResidentPages);
    final start = (page - 1) * _pageSize;
    final end   = (start + _pageSize).clamp(0, _filteredResidents.length);
    return _filteredResidents.sublist(start, end);
  }

  // Tagihan setelah difilter periode (bulan & tahun) saja — dasar untuk
  // stat cards (Total/Lunas/Belum Bayar) DAN untuk filter status di tabel.
  List<TagihanModel> get _periodeFiltered {
    Iterable<TagihanModel> result = widget.all;
    if (widget.filterBulan != null) {
      result = result.where((t) => t.bulanIndex == widget.filterBulan);
    }
    if (widget.filterTahun != null) {
      result = result.where((t) => t.tahun == widget.filterTahun);
    }
    return result.toList();
  }

  // Tagihan setelah filter periode + filter status — dipakai untuk tabel.
  List<TagihanModel> get _filtered {
    List<TagihanModel> result;
    switch (widget.filter) {
      case 'Lunas':
        result = _periodeFiltered
            .where((t) => t.status == StatusTagihan.lunas)
            .toList();
        break;
      case 'Belum Bayar':
        result = _periodeFiltered
            .where((t) => t.status == StatusTagihan.belumBayar)
            .toList();
        break;
      case 'Jatuh Tempo':
        result = _periodeFiltered
            .where((t) => t.status == StatusTagihan.jatuhTempo)
            .toList();
        break;
      default:
        result = _periodeFiltered.toList();
    }
    // Urutkan dari periode terbaru ke terlama.
    result.sort((a, b) => b.periodeKey.compareTo(a.periodeKey));
    return result;
  }

  int get _totalPages =>
      (_filtered.length / _pageSize).ceil().clamp(1, 9999);

  List<TagihanModel> get _paginated {
    final page = _currentPage.clamp(1, _totalPages);
    final start = (page - 1) * _pageSize;
    final end = (start + _pageSize).clamp(0, _filtered.length);
    return _filtered.sublist(start, end);
  }

  // Tahun-tahun yang benar-benar ada di data — opsi dropdown Tahun.
  List<int> get _availableYears {
    final years = widget.all.map((t) => t.tahun).toSet().toList();
    years.sort();
    if (years.isEmpty) years.add(DateTime.now().year);
    return years;
  }

  // Hitung WARGA UNIK (bukan jumlah tagihan) agar warga dengan banyak bulan
  // tunggakan tidak dihitung berkali-kali.
  int get _lunas => _periodeFiltered
      .where((t) => t.status == StatusTagihan.lunas)
      .map((t) => t.userId)
      .whereType<String>()
      .toSet()
      .length;
  int get _belum => _periodeFiltered
      .where((t) =>
          t.status == StatusTagihan.belumBayar ||
          t.status == StatusTagihan.jatuhTempo)
      .map((t) => t.userId)
      .whereType<String>()
      .toSet()
      .length;

  // ── Nominal rupiah untuk summary boxes ──────────────────────────────────────
  int get _totalRupiah =>
      _periodeFiltered.fold(0, (s, t) => s + t.jumlah);
  int get _lunasRupiah => _periodeFiltered
      .where((t) => t.status == StatusTagihan.lunas)
      .fold(0, (s, t) => s + t.jumlah);
  int get _belumRupiah => _totalRupiah - _lunasRupiah;
  double get _persenLunas =>
      _totalRupiah == 0 ? 0 : _lunasRupiah / _totalRupiah;

  /// Untuk setiap userId → periodeLabel tagihan lunas terbaru (tahun*12+bulan
  /// tertinggi). Dipakai untuk sub-teks "Lunas s/d …" di kolom PERIODE.
  Map<String, String> get _latestLunasPerUser {
    final scoreMap = <String, int>{};
    final labelMap = <String, String>{};
    for (final t in widget.all) {
      if (t.status != StatusTagihan.lunas) continue;
      final uid = t.userId;
      if (uid == null || uid.isEmpty) continue;
      final score = t.tahun * 12 + t.bulanIndex;
      if (!scoreMap.containsKey(uid) || score > scoreMap[uid]!) {
        scoreMap[uid] = score;
        labelMap[uid] = t.periodeLabel;
      }
    }
    return labelMap;
  }

  void _onFilter(String f) {
    setState(() => _currentPage = 1);
    widget.onFilter(f);
  }

  void _onFilterBulan(int? b) {
    setState(() => _currentPage = 1);
    widget.onFilterBulan(b);
  }

  void _onFilterTahun(int? t) {
    setState(() => _currentPage = 1);
    widget.onFilterTahun(t);
  }

  void _onPageChanged(int p) => setState(() => _currentPage = p);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      // Clamp (no bouncy stretch) biar scroll billing terasa solid seperti
      // halaman warga yang kontennya tinggi.
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Billing Iuran Warga',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pantau pembayaran iuran warga. Hubungi yang belum bayar.',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey),
          ),
          const SizedBox(height: 20),

          // ── Summary boxes ──────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _SummaryBox(
                  label     : 'TOTAL TAGIHAN',
                  rupiah    : _totalRupiah,
                  count     : _periodeFiltered.length,
                  countLabel: 'tagihan',
                  icon      : Icons.receipt_long_outlined,
                  accentColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _SummaryBox(
                  label     : 'SUDAH LUNAS',
                  rupiah    : _lunasRupiah,
                  count     : _lunas,
                  countLabel: 'warga',
                  icon      : Icons.check_circle_outline,
                  accentColor: const Color(0xFF16A34A),
                  persen    : _persenLunas,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _SummaryBox(
                  label     : 'BELUM DIBAYAR',
                  rupiah    : _belumRupiah,
                  count     : _belum,
                  countLabel: 'warga',
                  icon      : Icons.schedule_outlined,
                  accentColor: const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FilterBar(
                  selected      : widget.filter,
                  onSelect      : _onFilter,
                  filterBulan   : widget.filterBulan,
                  filterTahun   : widget.filterTahun,
                  availableYears: _availableYears,
                  onFilterBulan : _onFilterBulan,
                  onFilterTahun : _onFilterTahun,
                  viewMode      : _viewMode,
                  onViewMode    : (m) => setState(() {
                    _viewMode    = m;
                    _currentPage = 1;
                  }),
                ),
                Builder(builder: (_) {
                  final isEmpty = _viewMode == 'warga'
                      ? _filteredResidents.isEmpty
                      : _filtered.isEmpty;
                  if (isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 48, horizontal: 16),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                size: 48, color: AppColors.textGrey),
                            const SizedBox(height: 12),
                            Text(
                              widget.all.isEmpty
                                  ? 'Belum ada data tagihan.'
                                  : 'Tidak ada data untuk filter ini.',
                              style: GoogleFonts.inter(
                                  fontSize: 13, color: AppColors.textGrey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      if (_viewMode == 'warga')
                        _ResidentTable(
                          items    : _paginatedResidents,
                          onHubungi: widget.onHubungi,
                          onDetail : widget.onDetail,
                        )
                      else
                        _TagihanTable(
                          items             : _paginated,
                          onHubungi         : widget.onHubungi,
                          onEditStatus      : widget.onEditStatus,
                          onDetail          : widget.onDetail,
                          latestLunasPerUser: _latestLunasPerUser,
                        ),
                      _PaginationBar(
                        currentPage: _currentPage.clamp(
                            1,
                            _viewMode == 'warga'
                                ? _totalResidentPages
                                : _totalPages),
                        totalPages: _viewMode == 'warga'
                            ? _totalResidentPages
                            : _totalPages,
                        totalItems: _viewMode == 'warga'
                            ? _filteredResidents.length
                            : _filtered.length,
                        pageSize  : _pageSize,
                        onPageChanged: _onPageChanged,
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter chips (status) + filter periode (Bulan & Tahun) — satu baris ─────
class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selected,
    required this.onSelect,
    required this.filterBulan,
    required this.filterTahun,
    required this.availableYears,
    required this.onFilterBulan,
    required this.onFilterTahun,
    required this.viewMode,
    required this.onViewMode,
  });

  final String selected;
  final ValueChanged<String> onSelect;
  final int? filterBulan;
  final int? filterTahun;
  final List<int> availableYears;
  final ValueChanged<int?> onFilterBulan;
  final ValueChanged<int?> onFilterTahun;
  final String viewMode;
  final ValueChanged<String> onViewMode;

  static const _options = ['Semua', 'Lunas', 'Belum Bayar', 'Jatuh Tempo'];

  bool get _periodeActive => filterBulan != null || filterTahun != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          // ── View mode toggle (Per Warga / Per Tagihan) ──────────────────
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ToggleBtn(
                  icon  : Icons.people_outline,
                  label : 'Per Warga',
                  active: viewMode == 'warga',
                  onTap : () => onViewMode('warga'),
                ),
                _ToggleBtn(
                  icon  : Icons.receipt_long_outlined,
                  label : 'Per Tagihan',
                  active: viewMode == 'tagihan',
                  onTap : () => onViewMode('tagihan'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // ── Status chips ────────────────────────────────────────────────
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _options.map((o) {
                final active = o == selected;
                return InkWell(
                  onTap: () => onSelect(o),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: active
                              ? AppColors.primary
                              : Colors.grey.shade300),
                    ),
                    child: Text(
                      o,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: active ? Colors.white : AppColors.textGrey,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Filter periode — hanya tampil di mode Per Tagihan ───────────
          if (viewMode == 'tagihan') ...[
            const SizedBox(width: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _PeriodeDropdown(
                  value       : filterBulan,
                  hint        : 'Semua Bulan',
                  options     : List<int>.generate(12, (i) => i + 1),
                  labelBuilder: (m) => bulanPanjangList[m - 1],
                  onChanged   : onFilterBulan,
                ),
                _PeriodeDropdown(
                  value       : filterTahun,
                  hint        : 'Semua Tahun',
                  options     : availableYears,
                  labelBuilder: (y) => '$y',
                  onChanged   : onFilterTahun,
                ),
                if (_periodeActive)
                  TextButton.icon(
                    onPressed: () {
                      onFilterBulan(null);
                      onFilterTahun(null);
                    },
                    icon : const Icon(Icons.close, size: 14),
                    label: Text('Reset',
                        style: GoogleFonts.inter(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding    : const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 30),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// Toggle button kecil di dalam _FilterBar
class _ToggleBtn extends StatelessWidget {
  const _ToggleBtn({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });
  final IconData icon;
  final String   label;
  final bool     active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: active
              ? [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 1))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14,
                color: active ? AppColors.primary : AppColors.textGrey),
            const SizedBox(width: 5),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active ? AppColors.primary : AppColors.textGrey)),
          ],
        ),
      ),
    );
  }
}

class _PeriodeDropdown extends StatelessWidget {
  const _PeriodeDropdown({
    required this.value,
    required this.hint,
    required this.options,
    required this.labelBuilder,
    required this.onChanged,
  });

  final int? value;
  final String hint;
  final List<int> options;
  final String Function(int) labelBuilder;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: value,
          hint: Text(hint,
              style:
                  GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey)),
          icon: Icon(Icons.keyboard_arrow_down,
              size: 16, color: AppColors.textGrey),
          isDense: true,
          style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textDark,
              fontWeight: FontWeight.w600),
          items: [
            DropdownMenuItem<int?>(
              value: null,
              child: Text(hint,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textGrey)),
            ),
            ...options.map((o) => DropdownMenuItem<int?>(
                  value: o,
                  child: Text(labelBuilder(o),
                      style: GoogleFonts.inter(fontSize: 12)),
                )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ── Tabel tagihan ────────────────────────────────────────────────────────────
class _TagihanTable extends StatelessWidget {
  const _TagihanTable({
    required this.items,
    required this.onHubungi,
    required this.onEditStatus,
    required this.onDetail,
    required this.latestLunasPerUser,
  });
  final List<TagihanModel> items;
  final ValueChanged<TagihanModel> onHubungi;
  final ValueChanged<TagihanModel> onEditStatus;
  final ValueChanged<TagihanModel> onDetail;
  final Map<String, String> latestLunasPerUser;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header row
        Container(
          color: const Color(0xFFF8FAFC),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: const [
              Expanded(flex: 3, child: _HeaderText('WARGA')),
              Expanded(flex: 2, child: _HeaderText('PERIODE')),
              Expanded(flex: 2, child: _HeaderText('JUMLAH')),
              Expanded(flex: 2, child: _HeaderText('STATUS')),
              Expanded(flex: 2, child: _HeaderText('METODE')),
              Expanded(flex: 2, child: _HeaderText('AKSI')),
              SizedBox(width: 80, child: _HeaderText('EDIT')),
            ],
          ),
        ),
        ...items.map((t) => _TagihanRow(
              item: t,
              onHubungi: onHubungi,
              onEditStatus: onEditStatus,
              onDetail: onDetail,
              latestLunasPeriode: latestLunasPerUser[t.userId],
            )),
      ],
    );
  }
}

class _TagihanRow extends StatelessWidget {
  const _TagihanRow({
    required this.item,
    required this.onHubungi,
    required this.onEditStatus,
    required this.onDetail,
    required this.latestLunasPeriode,
  });
  final TagihanModel item;
  final ValueChanged<TagihanModel> onHubungi;
  final ValueChanged<TagihanModel> onEditStatus;
  final ValueChanged<TagihanModel> onDetail;
  /// Periode lunas terakhir milik user ini (null = belum pernah lunas).
  final String? latestLunasPeriode;

  bool get _unpaid =>
      item.status == StatusTagihan.belumBayar ||
      item.status == StatusTagihan.jatuhTempo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          // Warga
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    (item.namaResiden.isNotEmpty
                            ? item.namaResiden[0]
                            : '?')
                        .toUpperCase(),
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.namaResiden,
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark)),
                      Text(item.unitLabel,
                          style: GoogleFonts.inter(
                              fontSize: 11, color: AppColors.textGrey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Periode — baris 1: periode tagihan ini; baris 2: lunas s/d
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item.periodeLabel,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textDark)),
                const SizedBox(height: 2),
                Text(
                  latestLunasPeriode != null
                      ? 'Lunas s/d $latestLunasPeriode'
                      : 'Belum ada lunas',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: latestLunasPeriode != null
                        ? Colors.green.shade600
                        : AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          // Jumlah
          Expanded(
            flex: 2,
            child: Text(item.jumlahFormatted,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark)),
          ),
          // Status
          Expanded(flex: 2, child: _StatusBadge(status: item.status)),
          // Metode bayar
          Expanded(flex: 2, child: _MetodeBadge(metode: item.metodeBayar)),
          // Kolom AKSI — tombol Hubungi (hanya untuk yang belum bayar)
          Expanded(
            flex: 2,
            child: _unpaid
                ? OutlinedButton.icon(
                    onPressed: () => onHubungi(item),
                    icon: const Icon(Icons.phone_in_talk, size: 14),
                    label: Text('Hubungi',
                        style: GoogleFonts.inter(
                            fontSize: 11, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primaryLight),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      minimumSize: const Size(0, 30),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          // Kolom EDIT — eye (detail) + pensil (edit)
          SizedBox(
            width: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Tooltip(
                  message: 'Lihat detail pembayaran',
                  child: InkWell(
                    onTap: () => onDetail(item),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Icon(Icons.remove_red_eye_outlined,
                          size: 15, color: Colors.blue.shade600),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Tooltip(
                  message: 'Ubah status pembayaran',
                  child: InkWell(
                    onTap: () => onEditStatus(item),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Icon(Icons.edit_outlined,
                          size: 15, color: AppColors.textGrey),
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

// ── Status badge ─────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final StatusTagihan status;

  String get _label => switch (status) {
        StatusTagihan.belumBayar => 'Belum Bayar',
        StatusTagihan.jatuhTempo => 'Jatuh Tempo',
        StatusTagihan.lunas => 'Lunas',
        StatusTagihan.pending => 'Pending',
      };

  (Color, Color) get _colors => switch (status) {
        StatusTagihan.lunas =>
          (Colors.green.shade50, Colors.green.shade700),
        StatusTagihan.belumBayar =>
          (Colors.red.shade50, Colors.red.shade700),
        StatusTagihan.jatuhTempo =>
          (Colors.orange.shade50, Colors.orange.shade700),
        StatusTagihan.pending =>
          (Colors.amber.shade50, Colors.amber.shade800),
      };

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _label,
        style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}

// ── Tombol stepper di dalam dialog (lingkaran abu) ───────────────────────────
class _DlgStepBtn extends StatelessWidget {
  const _DlgStepBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });
  final IconData  icon;
  final bool      enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary : Colors.grey.shade200,
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            size: 18,
            color: enabled ? Colors.white : Colors.grey.shade400),
      ),
    );
  }
}

// ── Metode bayar badge ────────────────────────────────────────────────────────
class _MetodeBadge extends StatelessWidget {
  const _MetodeBadge({required this.metode});
  final String? metode;

  @override
  Widget build(BuildContext context) {
    if (metode == null || metode!.isEmpty) {
      return Text('-',
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey));
    }

    final lower    = metode!.toLowerCase();
    final isQris   = lower.contains('qris');
    final isTunai  = lower.contains('tunai');

    final (Color bg, Color fg, IconData icon, String label) = isQris
        ? (const Color(0xFFEFF6FF), const Color(0xFF1D4ED8), Icons.qr_code, 'QRIS')
        : isTunai
            ? (Colors.green.shade50, Colors.green.shade700, Icons.payments_outlined, 'Tunai')
            : (Colors.grey.shade100, AppColors.textGrey, Icons.help_outline, metode!);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.bold, color: fg),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Komponen kecil ───────────────────────────────────────────────────────────
class _HeaderText extends StatelessWidget {
  const _HeaderText(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textGrey,
            letterSpacing: 0.5),
      );
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(
      {required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textGrey,
                  letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color ?? AppColors.textDark)),
        ],
      ),
    );
  }
}

// ── Summary box (Total Tagihan / Sudah Lunas / Belum Dibayar) ─────────────────
class _SummaryBox extends StatelessWidget {
  const _SummaryBox({
    required this.label,
    required this.rupiah,
    required this.count,
    required this.countLabel,
    required this.icon,
    required this.accentColor,
    this.persen,
  });

  final String   label;
  final int      rupiah;
  final int      count;
  final String   countLabel;
  final IconData icon;
  final Color    accentColor;
  /// Jika tidak null, tampilkan progress bar (dipakai di "Sudah Lunas").
  final double?  persen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label + ikon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textGrey,
                      letterSpacing: 0.5)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: accentColor),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Nominal
          Text(
            rupiah > 0 ? formatRupiah(rupiah) : 'Rp 0',
            style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
                height: 1),
          ),
          const SizedBox(height: 6),

          // Count + persen (jika ada)
          Row(
            children: [
              Text(
                '$count $countLabel',
                style: GoogleFonts.inter(
                    fontSize: 12, color: accentColor, fontWeight: FontWeight.w600),
              ),
              if (persen != null) ...[
                const SizedBox(width: 6),
                Text(
                  '· ${(persen! * 100).round()}%',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textGrey),
                ),
              ],
            ],
          ),

          // Progress bar opsional
          if (persen != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: persen,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Data class: ringkasan satu warga ─────────────────────────────────────────
class _ResidentSummary {
  _ResidentSummary(List<TagihanModel> tagihan) {
    assert(tagihan.isNotEmpty);
    final now        = DateTime.now();
    final currentKey = now.year * 100 + now.month;
    final ref        = tagihan.first;

    userId      = ref.userId ?? '';
    namaResiden = ref.namaResiden;
    blok        = ref.blok;
    nomorUnit   = ref.nomorUnit;
    nomorHp     = ref.nomorHp;
    anyTagihan  = ref;

    // Tunggakan = tagihan bulan ini dan sebelumnya yang belum lunas.
    final wajibUnpaid = tagihan
        .where((t) =>
            t.periodeKey <= currentKey && t.status != StatusTagihan.lunas)
        .toList();
    tunggakanCount = wajibUnpaid.length;
    totalUtang     = wajibUnpaid.fold(0, (s, t) => s + t.jumlah);

    // Periode lunas terakhir.
    final lunasList = tagihan
        .where((t) => t.status == StatusTagihan.lunas)
        .toList()
      ..sort((a, b) => b.periodeKey.compareTo(a.periodeKey));
    lunasSampai = lunasList.isNotEmpty ? lunasList.first.periodeLabel : null;

    // Status keseluruhan.
    if (wajibUnpaid.any((t) => t.status == StatusTagihan.jatuhTempo)) {
      overallStatus = StatusTagihan.jatuhTempo;
    } else if (wajibUnpaid.isNotEmpty) {
      overallStatus = StatusTagihan.belumBayar;
    } else {
      overallStatus = StatusTagihan.lunas;
    }
  }

  late final String        userId;
  late final String        namaResiden;
  late final String        blok;
  late final String        nomorUnit;
  late final String?       nomorHp;
  late final int           tunggakanCount;
  late final int           totalUtang;
  late final String?       lunasSampai;
  late final StatusTagihan overallStatus;
  late final TagihanModel  anyTagihan;

  String get unitLabel => '$blok-$nomorUnit';
}

// ── Tabel per warga ───────────────────────────────────────────────────────────
class _ResidentTable extends StatelessWidget {
  const _ResidentTable({
    required this.items,
    required this.onHubungi,
    required this.onDetail,
  });
  final List<_ResidentSummary>          items;
  final ValueChanged<TagihanModel>      onHubungi;
  final ValueChanged<TagihanModel>      onDetail;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          color: const Color(0xFFF8FAFC),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: const Row(
            children: [
              Expanded(flex: 3, child: _HeaderText('WARGA')),
              Expanded(flex: 2, child: _HeaderText('TUNGGAKAN')),
              Expanded(flex: 2, child: _HeaderText('TOTAL UTANG')),
              Expanded(flex: 2, child: _HeaderText('LUNAS S/D')),
              Expanded(flex: 2, child: _HeaderText('STATUS')),
              Expanded(flex: 2, child: _HeaderText('AKSI')),
              SizedBox(width: 56, child: _HeaderText('DETAIL')),
            ],
          ),
        ),
        ...items.map((r) => _ResidentRow(
              item     : r,
              onHubungi: onHubungi,
              onDetail : onDetail,
            )),
      ],
    );
  }
}

class _ResidentRow extends StatelessWidget {
  const _ResidentRow({
    required this.item,
    required this.onHubungi,
    required this.onDetail,
  });
  final _ResidentSummary           item;
  final ValueChanged<TagihanModel> onHubungi;
  final ValueChanged<TagihanModel> onDetail;

  bool get _hasTunggakan => item.tunggakanCount > 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          // Warga
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    (item.namaResiden.isNotEmpty
                            ? item.namaResiden[0]
                            : '?')
                        .toUpperCase(),
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.namaResiden,
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark)),
                      Text(item.unitLabel,
                          style: GoogleFonts.inter(
                              fontSize: 11, color: AppColors.textGrey)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tunggakan
          Expanded(
            flex: 2,
            child: _hasTunggakan
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: item.overallStatus == StatusTagihan.jatuhTempo
                          ? Colors.orange.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${item.tunggakanCount} bulan',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: item.overallStatus ==
                                  StatusTagihan.jatuhTempo
                              ? Colors.orange.shade700
                              : Colors.red.shade700),
                    ),
                  )
                : Text('–',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.textGrey)),
          ),

          // Total utang
          Expanded(
            flex: 2,
            child: Text(
              _hasTunggakan ? formatRupiah(item.totalUtang) : '–',
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight:
                      _hasTunggakan ? FontWeight.w600 : FontWeight.normal,
                  color: _hasTunggakan
                      ? AppColors.textDark
                      : AppColors.textGrey),
            ),
          ),

          // Lunas s/d
          Expanded(
            flex: 2,
            child: Text(
              item.lunasSampai ?? 'Belum ada',
              style: GoogleFonts.inter(
                  fontSize: 12,
                  color: item.lunasSampai != null
                      ? Colors.green.shade600
                      : AppColors.textGrey),
            ),
          ),

          // Status
          Expanded(flex: 2, child: _StatusBadge(status: item.overallStatus)),

          // Aksi — Hubungi jika ada tunggakan
          Expanded(
            flex: 2,
            child: _hasTunggakan
                ? OutlinedButton.icon(
                    onPressed: () => onHubungi(item.anyTagihan),
                    icon : const Icon(Icons.phone_in_talk, size: 14),
                    label: Text('Hubungi',
                        style: GoogleFonts.inter(
                            fontSize: 11, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primaryLight),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      minimumSize: const Size(0, 30),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Detail — eye icon → AdminPaymentDetailPage
          SizedBox(
            width: 56,
            child: Center(
              child: Tooltip(
                message: 'Lihat detail pembayaran',
                child: InkWell(
                  onTap: () => onDetail(item.anyTagihan),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Icon(Icons.remove_red_eye_outlined,
                        size: 15, color: Colors.blue.shade600),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CenterMessage extends StatelessWidget {
  const _CenterMessage({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.textGrey),
          const SizedBox(height: 12),
          Text(text,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textGrey)),
        ],
      ),
    );
  }
}

// ── Tile opsi edit status (dipakai di bottom sheet) ──────────────────────────
class _EditStatusTile extends StatelessWidget {
  const _EditStatusTile({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: iconColor.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: iconColor)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textGrey)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: iconColor),
          ],
        ),
      ),
    );
  }
}

// ── Pagination bar (mirip warga_user_page) ───────────────────────────────────
class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.pageSize,
    required this.onPageChanged,
  });
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final start = totalItems == 0 ? 0 : ((currentPage - 1) * pageSize) + 1;
    final end = (currentPage * pageSize).clamp(0, totalItems);

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Text(
            'Showing $start to $end of $totalItems tagihan',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey),
          ),
          const Spacer(),
          _PageBtn(
            label: '<',
            enabled: currentPage > 1,
            onTap: () => onPageChanged(currentPage - 1),
          ),
          const SizedBox(width: 4),
          ..._buildPageNumbers(),
          const SizedBox(width: 4),
          _PageBtn(
            label: '>',
            enabled: currentPage < totalPages,
            onTap: () => onPageChanged(currentPage + 1),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers() {
    final pages = <Widget>[];
    void addPage(int page) {
      pages.add(_PageBtn(
        label: '$page',
        isActive: page == currentPage,
        onTap: () => onPageChanged(page),
      ));
      pages.add(const SizedBox(width: 4));
    }

    if (totalPages <= 5) {
      for (int i = 1; i <= totalPages; i++) addPage(i);
    } else {
      addPage(1);
      addPage(2);
      addPage(3);
      pages.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text('...',
            style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.textGrey)),
      ));
      pages.add(const SizedBox(width: 4));
      addPage(totalPages);
    }
    return pages;
  }
}

class _PageBtn extends StatelessWidget {
  const _PageBtn({
    required this.label,
    this.isActive = false,
    this.enabled = true,
    required this.onTap,
  });
  final String label;
  final bool isActive;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? AppColors.primary
                : enabled
                    ? Colors.grey.shade300
                    : Colors.grey.shade200,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive
                  ? Colors.white
                  : enabled
                      ? const Color(0xFF374151)
                      : Colors.grey.shade400,
            ),
          ),
        ),
      ),
    );
  }
}
