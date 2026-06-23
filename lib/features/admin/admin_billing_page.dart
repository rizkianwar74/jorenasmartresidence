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
                AdminTopBar(
                  searchHint: 'Cari nama warga atau unit...',
                  actionButton: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              title: Text('Update Tagihan ke Iuran Terbaru?',
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold)),
                              content: Text(
                                'Semua tagihan yang BELUM lunas akan diupdate '
                                'jumlahnya jadi ${formatRupiah(PaymentRepository.iuranBulanan)}. '
                                'Riwayat tagihan yang sudah lunas tidak akan diubah.',
                                style: GoogleFonts.inter(fontSize: 13),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text('Batal',
                                      style: GoogleFonts.inter(
                                          color: AppColors.textGrey)),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8)),
                                  ),
                                  child: Text('Update',
                                      style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          );
                          if (confirm != true) return;

                          final n =
                              await PaymentRepository.migrateUnpaidJumlah();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(n > 0
                                    ? '$n tagihan diupdate ke iuran terbaru.'
                                    : 'Tidak ada tagihan yang perlu diupdate.')),
                          );
                        },
                        icon: const Icon(Icons.sync, size: 16),
                        label: Text('Update ke Iuran Terbaru',
                            style: GoogleFonts.inter(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primaryLight),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      AdminAddButton(
                        label: 'Seed Data',
                        onPressed: () async {
                          final n = await SeedTagihan.run();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(n > 0
                                    ? '$n tagihan dibuat.'
                                    : 'Tidak ada tagihan baru.')),
                          );
                        },
                      ),
                    ],
                  ),
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
                      // Tagihan satpam yang mungkin sudah ada di Firestore
                      // disaring di sini agar tidak muncul di billing admin.
                      final all = (snap.data ?? const <TagihanModel>[])
                          .where((t) => !_satpamUids.contains(t.userId))
                          .toList();
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
              if (!isLunas)
                _EditStatusTile(
                  icon: Icons.check_circle_outline,
                  iconColor: Colors.green.shade600,
                  bgColor: Colors.green.shade50,
                  title: 'Tandai Lunas',
                  subtitle: 'Catat sebagai pembayaran tunai hari ini',
                  onTap: () async {
                    Navigator.pop(context);
                    await _applyStatusManual(t, StatusTagihan.lunas);
                  },
                ),
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

  @override
  State<_BillingContent> createState() => _BillingContentState();
}

class _BillingContentState extends State<_BillingContent> {
  int _currentPage = 1;
  static const int _pageSize = 8;

  // Reset ke page 1 tiap filter / data berubah.
  @override
  void didUpdateWidget(covariant _BillingContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter != widget.filter ||
        oldWidget.filterBulan != widget.filterBulan ||
        oldWidget.filterTahun != widget.filterTahun) {
      _currentPage = 1;
    }
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
    switch (widget.filter) {
      case 'Lunas':
        return _periodeFiltered
            .where((t) => t.status == StatusTagihan.lunas)
            .toList();
      case 'Belum Bayar':
        return _periodeFiltered
            .where((t) => t.status == StatusTagihan.belumBayar)
            .toList();
      case 'Jatuh Tempo':
        return _periodeFiltered
            .where((t) => t.status == StatusTagihan.jatuhTempo)
            .toList();
      default:
        return _periodeFiltered;
    }
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

  int get _lunas =>
      _periodeFiltered.where((t) => t.status == StatusTagihan.lunas).length;
  int get _belum => _periodeFiltered
      .where((t) =>
          t.status == StatusTagihan.belumBayar ||
          t.status == StatusTagihan.jatuhTempo)
      .length;

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
          // Header + stat cards
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.textGrey),
                    ),
                  ],
                ),
              ),
              _MiniStat(
                  label: 'TOTAL TAGIHAN', value: '${_periodeFiltered.length}'),
              const SizedBox(width: 12),
              _MiniStat(
                  label: 'LUNAS', value: '$_lunas', color: Colors.green),
              const SizedBox(width: 12),
              _MiniStat(
                  label: 'BELUM BAYAR', value: '$_belum', color: Colors.red),
            ],
          ),
          const SizedBox(height: 24),

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
                  selected: widget.filter,
                  onSelect: _onFilter,
                  filterBulan: widget.filterBulan,
                  filterTahun: widget.filterTahun,
                  availableYears: _availableYears,
                  onFilterBulan: _onFilterBulan,
                  onFilterTahun: _onFilterTahun,
                ),
                if (_filtered.isEmpty)
                  Padding(
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
                                ? 'Belum ada tagihan. Tekan "Seed Data" untuk membuat.'
                                : 'Tidak ada tagihan untuk filter ini.',
                            style: GoogleFonts.inter(
                                fontSize: 13, color: AppColors.textGrey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  _TagihanTable(
                      items: _paginated,
                      onHubungi: widget.onHubungi,
                      onEditStatus: widget.onEditStatus),
                  _PaginationBar(
                    currentPage: _currentPage.clamp(1, _totalPages),
                    totalPages: _totalPages,
                    totalItems: _filtered.length,
                    pageSize: _pageSize,
                    onPageChanged: _onPageChanged,
                  ),
                ],
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
  });

  final String selected;
  final ValueChanged<String> onSelect;
  final int? filterBulan;
  final int? filterTahun;
  final List<int> availableYears;
  final ValueChanged<int?> onFilterBulan;
  final ValueChanged<int?> onFilterTahun;

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
        border:
            Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          // Status chips — Semua / Lunas / Belum Bayar / Jatuh Tempo
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
          const SizedBox(width: 12),
          // Filter periode — Bulan & Tahun, sejajar di sebelah kanan
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _PeriodeDropdown(
                value: filterBulan,
                hint: 'Semua Bulan',
                options: List<int>.generate(12, (i) => i + 1),
                labelBuilder: (m) => bulanPanjangList[m - 1],
                onChanged: onFilterBulan,
              ),
              _PeriodeDropdown(
                value: filterTahun,
                hint: 'Semua Tahun',
                options: availableYears,
                labelBuilder: (y) => '$y',
                onChanged: onFilterTahun,
              ),
              if (_periodeActive)
                TextButton.icon(
                  onPressed: () {
                    onFilterBulan(null);
                    onFilterTahun(null);
                  },
                  icon: const Icon(Icons.close, size: 14),
                  label: Text('Reset',
                      style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 30),
                  ),
                ),
            ],
          ),
        ],
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
  });
  final List<TagihanModel> items;
  final ValueChanged<TagihanModel> onHubungi;
  final ValueChanged<TagihanModel> onEditStatus;

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
              Expanded(flex: 2, child: _HeaderText('AKSI')),
              SizedBox(width: 56, child: _HeaderText('EDIT')),
            ],
          ),
        ),
        ...items.map((t) => _TagihanRow(
            item: t, onHubungi: onHubungi, onEditStatus: onEditStatus)),
      ],
    );
  }
}

class _TagihanRow extends StatelessWidget {
  const _TagihanRow({
    required this.item,
    required this.onHubungi,
    required this.onEditStatus,
  });
  final TagihanModel item;
  final ValueChanged<TagihanModel> onHubungi;
  final ValueChanged<TagihanModel> onEditStatus;

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
          // Periode
          Expanded(
            flex: 2,
            child: Text(item.periodeLabel,
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textDark)),
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
          // Kolom EDIT — ikon pensil, selalu tampil, lebar tetap sejajar header
          SizedBox(
            width: 56,
            child: Center(
              child: Tooltip(
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
