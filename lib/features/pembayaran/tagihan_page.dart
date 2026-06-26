import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../auth/auth_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_helper.dart';
import 'models/tagihan_model.dart';
import 'pakasir_payment_page.dart';
import 'data/payment_repository.dart';

class TagihanPage extends StatefulWidget {
  const TagihanPage({super.key});

  @override
  State<TagihanPage> createState() => _TagihanPageState();
}

class _TagihanPageState extends State<TagihanPage> {
  static const double _contentMaxWidth = 600.0;

  // Jumlah bulan ADVANCE (dimuka) yang dipilih user.
  // Wajib (tunggakan + bulan berjalan) selalu ikut — tidak bisa di-skip.
  int _selectedAdvanceCount = 0;

  // Loading state saat membuat tagihan baru ke Firestore sebelum bayar.
  bool _isPreparingPayment = false;

  // Batas praktis stepper advance (60 bulan = 5 tahun).
  static const int _maxAdvanceMonths = 60;

  // ── Generate advance list ──────────────────────────────────────────────────
  // Mengembalikan [count] bulan advance mulai dari bulan setelah bulan berjalan.
  // Bulan yang sudah ada di [existingAdvance] dipakai apa adanya;
  // sisanya dibuat sebagai TagihanModel virtual (belum ada di Firestore).
  List<TagihanModel> _buildAdvanceList({
    required List<TagihanModel> existingAdvance,
    required TagihanModel userRef,
    required int count,
  }) {
    if (count == 0) return [];
    final result = <TagihanModel>[];
    final now    = DateTime.now();
    int key      = now.year * 100 + now.month;

    for (int i = 0; i < count; i++) {
      // Maju satu bulan.
      int year  = key ~/ 100;
      int month = key % 100 + 1;
      if (month > 12) { month = 1; year++; }
      key = year * 100 + month;

      // Pakai dokumen Firestore yang sudah ada kalau tersedia.
      TagihanModel? existing;
      for (final t in existingAdvance) {
        if (t.periodeKey == key) { existing = t; break; }
      }
      if (existing != null) {
        result.add(existing);
        continue;
      }

      // Buat virtual tagihan untuk bulan ini.
      final id       = 'tagihan-$year-${month.toString().padLeft(2, '0')}-${userRef.userId}';
      final lastDay  = DateTime(year, month + 1, 0).day;
      final jatuhTempo = '$lastDay ${bulanSingkatList[month - 1]} $year';
      result.add(TagihanModel(
        id         : id,
        bulan      : bulanPanjangList[month - 1],
        bulanIndex : month,
        tahun      : year,
        namaResiden: userRef.namaResiden,
        blok       : userRef.blok,
        nomorUnit  : userRef.nomorUnit,
        jumlah     : PaymentRepository.iuranBulanan,
        jatuhTempo : jatuhTempo,
        status     : StatusTagihan.belumBayar,
        userId     : userRef.userId,
        nomorHp    : userRef.nomorHp,
      ));
    }
    return result;
  }

  // ── Buat tagihan yang belum ada + navigasi ke pembayaran ──────────────────
  Future<void> _prepareAndPay({
    required List<TagihanModel> selectedTagihan,
    required List<TagihanModel> allExisting,
  }) async {
    setState(() => _isPreparingPayment = true);
    try {
      final existingIds = allExisting.map((t) => t.id).toSet();
      final toCreate = selectedTagihan.where((t) => !existingIds.contains(t.id));

      for (final t in toCreate) {
        await PaymentRepository.createTagihanForMonth(
          userId      : t.userId ?? '',
          namaResiden : t.namaResiden,
          nomorHp     : t.nomorHp ?? '',
          blok        : t.blok,
          nomorUnit   : t.nomorUnit,
          bulanIndex  : t.bulanIndex,
          tahun       : t.tahun,
        );
      }

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PakasirPaymentPage(tagihanList: selectedTagihan),
        ),
      );
    } finally {
      if (mounted) setState(() => _isPreparingPayment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hPad = Responsive.value<double>(context, mobile: 24, tablet: 32);
    final uid = AuthRepository.currentUid;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F7F8),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          color: AppColors.textDark,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tagihan Saya',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        centerTitle: true,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
          child: uid == null
              ? _buildContent(context, hPad, const [])
              : StreamBuilder<List<TagihanModel>>(
                  stream: PaymentRepository.watchUserTagihan(uid),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary));
                    }
                    final list = snap.data ?? const <TagihanModel>[];
                    return _buildContent(context, hPad, list);
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, double hPad, List<TagihanModel> list) {
    final aktif = list.unpaidSorted;
    final riwayat = list.where((t) => t.status == StatusTagihan.lunas).toList();

    // Pisahkan tagihan aktif menjadi dua kelompok:
    //   wajib   = tunggakan + bulan berjalan  → selalu ikut pembayaran
    //   advance = bulan-bulan dimuka (> hari ini) → opsional, dikontrol stepper
    final now        = DateTime.now();
    final currentKey = now.year * 100 + now.month;
    final wajib           = aktif.where((t) => t.periodeKey <= currentKey).toList();
    final advanceExisting = aktif.where((t) => t.periodeKey >  currentKey).toList();

    // Jika semua wajib sudah lunas (wajib kosong) tapi advance ada,
    // pastikan minimal 1 advance dipilih supaya tombol Bayar tetap aktif.
    final minAdv         = wajib.isEmpty ? 1 : 0;
    final effectiveAdvCount =
        _selectedAdvanceCount.clamp(minAdv, _maxAdvanceMonths);

    // Bangun daftar advance (Firestore yang sudah ada + virtual untuk bulan baru).
    final fullAdvance = list.isNotEmpty
        ? _buildAdvanceList(
            existingAdvance: advanceExisting,
            userRef        : list.first,
            count          : effectiveAdvCount,
          )
        : advanceExisting.take(effectiveAdvCount).toList();

    final selectedTagihan = [...wajib, ...fullAdvance];

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (aktif.isNotEmpty || list.isNotEmpty && wajib.isEmpty)
            _TagihanAktifCard(
              wajibList           : wajib,
              advanceList         : fullAdvance,
              selectedAdvanceCount: effectiveAdvCount,
              minAdvanceCount     : minAdv,
              maxAdvanceCount     : _maxAdvanceMonths,
              onAdvanceCountChanged: (c) =>
                  setState(() => _selectedAdvanceCount = c),
              onBayar: (_isPreparingPayment || selectedTagihan.isEmpty)
                  ? null
                  : () => _prepareAndPay(
                        selectedTagihan: selectedTagihan,
                        allExisting    : list,
                      ),
              isLoading: _isPreparingPayment,
            )
          else if (list.isEmpty)
            // Belum ada dokumen tagihan sama sekali untuk akun ini.
            const _NoTagihanCard()
          else
            // Ada riwayat, tapi semua sudah lunas — tidak ada yang aktif.
            const _EmptyPaidCard(),

          const SizedBox(height: 28),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Riwayat Pembayaran',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                '${riwayat.length} transaksi',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textGrey),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (riwayat.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Belum ada riwayat pembayaran.',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.textGrey),
                ),
              ),
            )
          else
            ...riwayat.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RiwayatCard(tagihan: t),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Stepper pilih jumlah bulan dimuka ────────────────────────────────────────
class _BulanStepper extends StatelessWidget {
  const _BulanStepper({
    required this.count,
    required this.min,
    required this.max,
    required this.onChanged,
    this.label = 'Pilih jumlah bulan:',
  });

  final int    count;
  final int    min;
  final int    max;
  final String label;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.8)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // Tombol kurang
          _StepBtn(
            icon: Icons.remove,
            enabled: count > min,
            onTap: () => onChanged(count - 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              '$count bln',
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
          // Tombol tambah
          _StepBtn(
            icon: Icons.add,
            enabled: count < max,
            onTap: () => onChanged(count + 1),
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: enabled
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled
              ? Colors.white
              : Colors.white.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

// ── Kartu saat memang belum ada tagihan sama sekali ──────────────────────────
class _NoTagihanCard extends StatelessWidget {
  const _NoTagihanCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.receipt_long_outlined,
                color: Colors.grey.shade500, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tidak Ada Tagihan',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Belum ada data tagihan untuk akun Anda.',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textGrey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Kartu saat semua tagihan sudah lunas ─────────────────────────────────────
class _EmptyPaidCard extends StatelessWidget {
  const _EmptyPaidCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle, color: Colors.green, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Semua Tagihan Lunas',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tidak ada iuran yang perlu dibayar saat ini.',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Kartu tagihan aktif ───────────────────────────────────────────────────────
class _TagihanAktifCard extends StatelessWidget {
  const _TagihanAktifCard({
    required this.wajibList,
    required this.advanceList,
    required this.selectedAdvanceCount,
    required this.minAdvanceCount,
    required this.maxAdvanceCount,
    required this.onAdvanceCountChanged,
    this.onBayar,
    this.isLoading = false,
  });

  /// Tagihan wajib (tunggakan + bulan berjalan). Selalu ikut pembayaran.
  final List<TagihanModel> wajibList;

  /// Tagihan advance yang dipilih saat ini (sudah di-trim sesuai count).
  final List<TagihanModel> advanceList;

  /// Berapa bulan advance yang dipilih (0 = tidak tambah dimuka).
  final int selectedAdvanceCount;

  /// Minimum advance yang harus dipilih (1 jika wajib kosong).
  final int minAdvanceCount;

  /// Batas atas stepper advance.
  final int maxAdvanceCount;

  final ValueChanged<int> onAdvanceCountChanged;
  final VoidCallback? onBayar;
  final bool isLoading;

  // Gabungan yang benar-benar akan dibayar.
  List<TagihanModel> get _selected =>
      [...wajibList, ...advanceList.take(selectedAdvanceCount)];

  TagihanModel get _acuan =>
      wajibList.isNotEmpty ? wajibList.first : advanceList.first;

  int get _selectedJumlah => _selected.fold(0, (s, t) => s + t.jumlah);

  bool get _adaTunggakan => wajibList.length > 1;

  String get _periodeLabel {
    final total = _selected.length;
    if (total == 0) return '-';
    if (total == 1) return _selected.first.periodeLabel;
    if (wajibList.length > 1 && selectedAdvanceCount == 0) {
      return '${wajibList.length} Bulan Tertunggak';
    }
    if (selectedAdvanceCount > 0 && wajibList.isEmpty) {
      return '$selectedAdvanceCount Bulan Dimuka';
    }
    return '$total Bulan (${wajibList.length} wajib + $selectedAdvanceCount dimuka)';
  }

  String get _statusLabel {
    final all = [...wajibList, ...advanceList];
    if (all.every((t) => t.status == StatusTagihan.lunas)) return 'Lunas';
    if (all.any((t) => t.status == StatusTagihan.jatuhTempo)) return 'Jatuh Tempo';
    if (all.any((t) => t.status == StatusTagihan.pending)) return 'Menunggu Konfirmasi';
    if (wajibList.isEmpty && advanceList.isNotEmpty) return 'Dimuka';
    return 'Belum Dibayar';
  }

  @override
  Widget build(BuildContext context) {
    final tagihan = _acuan;
    final isLunas = [...wajibList, ...advanceList]
        .every((t) => t.status == StatusTagihan.lunas);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, const Color(0xFF0D5BAA)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20, top: -20,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            right: 40, bottom: -30,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'IURAN BULANAN',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.7),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _periodeLabel,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statusLabel,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    const Icon(Icons.person_outline,
                        color: Colors.white54, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      tagihan.namaResiden,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.85)),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.apartment,
                        color: Colors.white54, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      tagihan.unitLabel,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.85)),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Text(
                  formatRupiah(_selectedJumlah),
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: Colors.white54, size: 13),
                    const SizedBox(width: 6),
                    Text(
                      'Jatuh tempo: ${tagihan.jatuhTempo}',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.7)),
                    ),
                  ],
                ),

                // ── Info bulan wajib (jika ada tunggakan) ──────────────────
                if (_adaTunggakan) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            size: 15, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${wajibList.length} bulan tertunggak wajib dilunasi sekaligus.',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Stepper bulan dimuka ───────────────────────────────────
                const SizedBox(height: 14),
                _BulanStepper(
                  label: 'Tambah bulan dimuka:',
                  count: selectedAdvanceCount,
                  min: minAdvanceCount,
                  max: maxAdvanceCount,
                  onChanged: onAdvanceCountChanged,
                ),

                const SizedBox(height: 20),

                if (isLunas)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Tagihan Anda Lunas',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: onBayar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.primary,
                              ),
                            )
                          : Text(
                              'Bayar Sekarang',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
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

// ── Kartu riwayat ─────────────────────────────────────────────────────────────
class _RiwayatCard extends StatelessWidget {
  const _RiwayatCard({required this.tagihan});
  final TagihanModel tagihan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle_outline,
                color: Colors.green.shade600, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Iuran ${tagihan.periodeLabel}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      tagihan.tanggalBayar ?? '-',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textGrey),
                    ),
                    if (tagihan.metodeBayar != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 3, height: 3,
                        decoration: const BoxDecoration(
                          color: AppColors.textGrey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tagihan.metodeBayar!,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.textGrey),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                tagihan.jumlahFormatted,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Lunas',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
