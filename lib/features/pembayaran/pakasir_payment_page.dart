import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/services/pakasir_service.dart';
import '../auth/data/auth_repository.dart';
import 'models/tagihan_model.dart';
import 'data/payment_repository.dart';
import 'payment_status_page.dart';

/// Halaman pembayaran via Pakasir.
///
/// Flow:
///   1. Generate orderId → simpan ke Firestore (setOrderIdForMany).
///   2. Buka URL Pakasir di browser eksternal (url_launcher).
///   3. Tampilkan layar "Menunggu Pembayaran" + listen Firestore (BUKAN
///      polling API Pakasir) untuk tahu kapan tagihan berubah status.
///   4. Status "lunas" ditulis oleh server webhook (server/pakasir-webhook/),
///      yang memverifikasi ulang pembayaran ke Pakasir sebelum menulis.
///      Begitu Firestore menunjukkan semua tagihan sudah lunas → kirim push
///      notification via OneSignal → navigasi ke [PaymentStatusPage].
///
///   Client TIDAK LAGI berwenang menandai tagihan lunas sendiri (dulu lewat
///   PaymentRepository.markManyAsLunas dipanggil langsung dari sini) — itu
///   sekarang murni tugas server, supaya klien tidak bisa memicu status
///   lunas tanpa benar-benar membayar. Lihat docs/payment_webhook_fix_prompt.md.
class PakasirPaymentPage extends StatefulWidget {
  const PakasirPaymentPage({super.key, required this.tagihanList});

  /// Semua tagihan (bisa > 1 bulan tunggakan) yang dibayar sekaligus.
  final List<TagihanModel> tagihanList;

  @override
  State<PakasirPaymentPage> createState() => _PakasirPaymentPageState();
}

class _PakasirPaymentPageState extends State<PakasirPaymentPage> {
  bool   _urlOpened    = false;
  bool   _resolved     = false;
  bool   _initializing = true;
  String? _orderId;
  StreamSubscription<List<TagihanModel>>? _tagihanSub;

  TagihanModel  get _terlama      => widget.tagihanList.first;
  TagihanModel  get _terbaru     => widget.tagihanList.last;
  List<String>  get _ids         => widget.tagihanList.map((t) => t.id).toList();
  int           get _totalJumlah =>
      widget.tagihanList.fold(0, (sum, t) => sum + t.jumlah);
  String        get _periodeLabel => widget.tagihanList.length > 1
      ? '${widget.tagihanList.length} Bulan Tertunggak'
      : _terlama.periodeLabel;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _initPayment();
  }

  @override
  void dispose() {
    _tagihanSub?.cancel();
    super.dispose();
  }

  // ── Init ───────────────────────────────────────────────────────────────────
  Future<void> _initPayment() async {
    final orderId = 'IUR-${DateTime.now().millisecondsSinceEpoch}';
    _orderId = orderId;

    // Simpan orderId ke Firestore — tidak fatal kalau gagal. orderId inilah
    // yang dipakai server webhook untuk mencari tagihan mana yang harus
    // ditandai lunas begitu Pakasir mengonfirmasi pembayaran.
    try {
      await PaymentRepository.setOrderIdForMany(
        tagihanIds: _ids,
        orderId:    orderId,
      );
    } catch (_) {}

    if (!mounted) return;
    setState(() => _initializing = false);

    // Buka halaman pembayaran Pakasir di browser.
    await _openPaymentUrl();

    // Dengarkan Firestore — bukan polling ke Pakasir. Server webhook yang
    // akan menulis status lunas setelah verifikasi.
    _listenForPaymentConfirmation();
  }

  // ── Buka URL ───────────────────────────────────────────────────────────────
  Future<void> _openPaymentUrl() async {
    if (_orderId == null) return;
    final uri = Uri.parse(
      PakasirService.buildPaymentUrl(orderId: _orderId!, amount: _totalJumlah),
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (mounted) setState(() => _urlOpened = true);
      }
    } catch (_) {}
  }

  // ── Tunggu konfirmasi via Firestore ────────────────────────────────────────
  // Server webhook (server/api/pakasir-webhook.ts) yang menulis status ini setelah
  // memverifikasi ulang pembayaran ke Pakasir. Begitu SEMUA tagihan yang
  // sedang dibayar berstatus lunas, anggap pembayaran selesai.
  void _listenForPaymentConfirmation() {
    final uid = AuthRepository.currentUid;
    if (uid == null) {
      debugPrint('[PakasirPaymentPage] uid null, tidak bisa listen tagihan.');
      return;
    }
    _tagihanSub = PaymentRepository
        .watchTagihanByIds(_ids, userId: uid)
        .listen((list) {
      if (_resolved) return;
      // Pastikan SEMUA tagihan yang dibayar sudah kembali (bukan snapshot
      // parsial) dan semuanya sudah lunas sebelum dianggap selesai.
      final semuaLunas = list.length == _ids.length &&
          list.every((t) => t.status == StatusTagihan.lunas);
      if (semuaLunas) _handleSuccess();
    });
  }

  // ── Bayar Berhasil ─────────────────────────────────────────────────────────
  Future<void> _handleSuccess() async {
    if (_resolved) return;
    _resolved = true;
    _tagihanSub?.cancel();

    // Notifikasi "pembayaran berhasil" TIDAK dikirim dari sini lagi.
    // Pemicunya kini server webhook Pakasir, tepat setelah tagihan ditandai
    // lunas (server/api/pakasir-webhook.ts). Dengan begitu notifikasi tetap
    // sampai meskipun warga sudah menutup aplikasi sebelum halaman ini sempat
    // menerima pembaruan dari Firestore.

    if (!mounted) return;

    // Buat model representatif untuk status page.
    final combined = TagihanModel(
      id          : _terlama.id,
      bulan       : widget.tagihanList.length > 1 ? _periodeLabel : _terlama.bulan,
      bulanIndex  : _terlama.bulanIndex,
      tahun       : _terbaru.tahun,
      namaResiden : _terlama.namaResiden,
      blok        : _terlama.blok,
      nomorUnit   : _terlama.nomorUnit,
      jumlah      : _totalJumlah,
      jatuhTempo  : _terlama.jatuhTempo,
      status      : StatusTagihan.lunas,
      userId      : _terlama.userId,
      nomorHp     : _terlama.nomorHp,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentStatusPage(
          tagihan: combined,
          result:  PaymentResult.success,
        ),
      ),
    );
  }

  // ── Konfirmasi tutup ───────────────────────────────────────────────────────
  void _confirmClose() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Batalkan Pembayaran?',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text('Transaksi belum selesai. Yakin ingin keluar?',
            style: GoogleFonts.inter(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Lanjutkan',
                style: GoogleFonts.inter(color: AppColors.primary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('Keluar',
                style: GoogleFonts.inter(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ── UI ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, size: 22),
          color: AppColors.textDark,
          onPressed: _confirmClose,
        ),
        title: Column(
          children: [
            Text(
              'Pembayaran',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            Text(
              _periodeLabel,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Icon(Icons.lock_outline, size: 14, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  'Aman',
                  style:
                      GoogleFonts.inter(fontSize: 12, color: Colors.green.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _initializing
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            // ── Kartu ringkasan tagihan ───────────────────────────────────
            _SummaryCard(
              periodeLabel: _periodeLabel,
              totalJumlah:  _totalJumlah,
              namaResiden:  _terlama.namaResiden,
              unitLabel:    _terlama.unitLabel,
            ),

            const SizedBox(height: 36),

            // ── Animasi menunggu ──────────────────────────────────────────
            const _PulsingPaymentIcon(),

            const SizedBox(height: 16),

            // QRIS badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.qr_code, size: 14, color: Color(0xFF1D4ED8)),
                  const SizedBox(width: 5),
                  Text('QRIS',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1D4ED8))),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Text(
              _urlOpened
                  ? 'Scan QR Code untuk Membayar'
                  : 'Membuka Halaman QRIS...',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Buka browser lalu scan QR Code yang muncul.\n'
              'Halaman ini otomatis update setelah berhasil.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textGrey,
                  height: 1.5),
            ),

            const Spacer(),

            // ── Tombol buka ulang ─────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _openPaymentUrl,
                icon: const Icon(Icons.open_in_browser, size: 18),
                label: Text(
                  'Buka Ulang Halaman QRIS',
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            const SizedBox(height: 12),

            TextButton(
              onPressed: _confirmClose,
              child: Text(
                'Batalkan Pembayaran',
                style: GoogleFonts.inter(
                    fontSize: 13, color: Colors.red.shade400),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Kartu ringkasan ───────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.periodeLabel,
    required this.totalJumlah,
    required this.namaResiden,
    required this.unitLabel,
  });

  final String periodeLabel;
  final int    totalJumlah;
  final String namaResiden;
  final String unitLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF0D5BAA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Pembayaran',
            style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            formatRupiah(totalJumlah),
            style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
          const SizedBox(height: 14),
          _SummaryRow(icon: Icons.calendar_today, label: periodeLabel),
          const SizedBox(height: 4),
          _SummaryRow(icon: Icons.person_outline,  label: namaResiden),
          const SizedBox(height: 4),
          _SummaryRow(icon: Icons.apartment,        label: unitLabel),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.icon, required this.label});
  final IconData icon;
  final String   label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 6),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.85))),
      ],
    );
  }
}

// ── Animasi ikon payment berdenyut ────────────────────────────────────────────
class _PulsingPaymentIcon extends StatefulWidget {
  const _PulsingPaymentIcon();

  @override
  State<_PulsingPaymentIcon> createState() => _PulsingPaymentIconState();
}

class _PulsingPaymentIconState extends State<_PulsingPaymentIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;
  late Animation<double>   _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _scale   = Tween(begin: 0.85, end: 1.15).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _opacity = Tween(begin: 0.45, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.scale(
        scale: _scale.value,
        child: Opacity(
          opacity: _opacity.value,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.qr_code_2,
                color: AppColors.primary, size: 34),
          ),
        ),
      ),
    );
  }
}
