import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../auth/data/auth_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_helper.dart';
import 'models/tagihan_model.dart';
import 'pakasir_payment_page.dart';
import 'data/payment_repository.dart';
import 'widgets/tagihan_aktif_card.dart';
import 'widgets/tagihan_empty_states.dart';
import 'widgets/riwayat_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Halaman Tagihan Saya — kartu tagihan aktif + riwayat pembayaran.
//
// Widget-widget pendukung (stepper bulan, kartu tagihan aktif, kartu
// riwayat, empty state) dipecah ke folder widgets/ agar file ini fokus pada
// business logic (hitung tunggakan/advance, siapkan pembayaran) saja.
// ─────────────────────────────────────────────────────────────────────────────

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
  /// Bangun daftar [count] bulan advance yang BELUM lunas.
  ///
  /// [allAdvance] berisi SEMUA tagihan masa depan (termasuk yang sudah lunas)
  /// sehingga bulan yang telah dibayar di-skip dan diganti bulan berikutnya.
  List<TagihanModel> _buildAdvanceList({
    required List<TagihanModel> allAdvance,
    required TagihanModel userRef,
    required int count,
  }) {
    if (count == 0) return [];
    final result = <TagihanModel>[];
    final now    = DateTime.now();
    int key      = now.year * 100 + now.month;
    // Safety limit: maks iterasi = count + 120 bulan (10 tahun) ke depan.
    int limit    = count + 120;

    while (result.length < count && limit-- > 0) {
      // Maju satu bulan.
      int year  = key ~/ 100;
      int month = key % 100 + 1;
      if (month > 12) { month = 1; year++; }
      key = year * 100 + month;

      // Cek apakah bulan ini sudah ada di Firestore.
      TagihanModel? existing;
      for (final t in allAdvance) {
        if (t.periodeKey == key) { existing = t; break; }
      }

      // Bulan ini sudah lunas → lewati, ambil bulan berikutnya.
      if (existing != null && existing.status == StatusTagihan.lunas) continue;

      // Bulan ini ada tapi belum lunas → pakai dokumen Firestore.
      if (existing != null) {
        result.add(existing);
        continue;
      }

      // Bulan ini belum ada → buat virtual tagihan.
      final id         = 'tagihan-$year-${month.toString().padLeft(2, '0')}-${userRef.userId}';
      final lastDay    = DateTime(year, month + 1, 0).day;
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
      final toCreate = selectedTagihan
          .where((t) => !existingIds.contains(t.id))
          .toList();

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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyiapkan pembayaran: $e'),
          backgroundColor: Colors.red.shade600,
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
    final wajib              = aktif.where((t) => t.periodeKey <= currentKey).toList();
    // Semua tagihan masa depan — termasuk yang sudah lunas — agar _buildAdvanceList
    // bisa melewati bulan yang sudah dibayar dan memilih bulan berikutnya.
    final allAdvanceTagihan  = list.where((t) => t.periodeKey > currentKey).toList();

    // Jika semua wajib sudah lunas (wajib kosong), minimal 1 advance agar
    // tombol Bayar tetap aktif untuk pembayaran di muka.
    final minAdv         = wajib.isEmpty ? 1 : 0;
    final effectiveAdvCount =
        _selectedAdvanceCount.clamp(minAdv, _maxAdvanceMonths);

    // Bangun daftar advance (skip bulan yang sudah lunas, ambil bulan berikutnya).
    final fullAdvance = list.isNotEmpty
        ? _buildAdvanceList(
            allAdvance: allAdvanceTagihan,
            userRef   : list.first,
            count     : effectiveAdvCount,
          )
        : <TagihanModel>[];

    final selectedTagihan = [...wajib, ...fullAdvance];

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (aktif.isNotEmpty || list.isNotEmpty && wajib.isEmpty)
            TagihanAktifCard(
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
            const NoTagihanCard()
          else
            // Ada riwayat, tapi semua sudah lunas — tidak ada yang aktif.
            const EmptyPaidCard(),

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
                child: RiwayatCard(tagihan: t),
              ),
            ),
        ],
      ),
    );
  }
}
