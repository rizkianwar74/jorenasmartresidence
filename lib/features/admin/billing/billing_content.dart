import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../pembayaran/models/tagihan_model.dart';
import 'models/resident_summary.dart';
import 'widgets/billing_filter_bar.dart';
import 'widgets/billing_tagihan_table.dart';
import 'widgets/billing_resident_table.dart';
import 'widgets/billing_pagination_bar.dart';
import 'widgets/billing_summary_box.dart';

class BillingContent extends StatefulWidget {
  const BillingContent({
    super.key,
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
  final int? filterBulan;
  final int? filterTahun;
  final ValueChanged<String> onFilter;
  final ValueChanged<int?> onFilterBulan;
  final ValueChanged<int?> onFilterTahun;
  final ValueChanged<TagihanModel> onHubungi;
  final ValueChanged<TagihanModel> onEditStatus;
  final ValueChanged<TagihanModel> onDetail;

  @override
  State<BillingContent> createState() => _BillingContentState();
}

class _BillingContentState extends State<BillingContent> {
  int _currentPage = 1;
  static const int _pageSize = 8;

  String _viewMode = 'warga';

  @override
  void didUpdateWidget(covariant BillingContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter != widget.filter ||
        oldWidget.filterBulan != widget.filterBulan ||
        oldWidget.filterTahun != widget.filterTahun) {
      _currentPage = 1;
    }
  }

  List<ResidentSummary> get _residentSummaries {
    final Map<String, List<TagihanModel>> grouped = {};
    for (final t in widget.all) {
      final uid = t.userId ?? '';
      if (uid.isEmpty) continue;
      grouped.putIfAbsent(uid, () => []).add(t);
    }
    final summaries =
        grouped.values.map(ResidentSummary.new).toList();
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

  List<ResidentSummary> get _filteredResidents {
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

  List<ResidentSummary> get _paginatedResidents {
    final page  = _currentPage.clamp(1, _totalResidentPages);
    final start = (page - 1) * _pageSize;
    final end   = (start + _pageSize).clamp(0, _filteredResidents.length);
    return _filteredResidents.sublist(start, end);
  }

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

  List<int> get _availableYears {
    final years = widget.all.map((t) => t.tahun).toSet().toList();
    years.sort();
    if (years.isEmpty) years.add(DateTime.now().year);
    return years;
  }

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

  int get _totalRupiah =>
      _periodeFiltered.fold(0, (s, t) => s + t.jumlah);
  int get _lunasRupiah => _periodeFiltered
      .where((t) => t.status == StatusTagihan.lunas)
      .fold(0, (s, t) => s + t.jumlah);
  int get _belumRupiah => _totalRupiah - _lunasRupiah;
  double get _persenLunas =>
      _totalRupiah == 0 ? 0 : _lunasRupiah / _totalRupiah;

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
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(24),
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
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: SummaryBox(
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
                child: SummaryBox(
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
                child: SummaryBox(
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
                BillingFilterBar(
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
                        BillingResidentTable(
                          items    : _paginatedResidents,
                          onHubungi: widget.onHubungi,
                          onDetail : widget.onDetail,
                        )
                      else
                        BillingTagihanTable(
                          items             : _paginated,
                          onHubungi         : widget.onHubungi,
                          onEditStatus      : widget.onEditStatus,
                          onDetail          : widget.onDetail,
                          latestLunasPerUser: _latestLunasPerUser,
                        ),
                      BillingPaginationBar(
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
