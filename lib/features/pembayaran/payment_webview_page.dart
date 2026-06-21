import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/data/midtrans_service.dart';
import '../auth/auth_repository.dart';
import 'tagihan_model.dart';
import 'payment_repository.dart';
import 'payment_status_page.dart';

class PaymentWebViewPage extends StatefulWidget {
  const PaymentWebViewPage({super.key, required this.tagihanList});

  /// Semua tagihan (bisa lebih dari 1 bulan tunggakan) yang dibayar
  /// SEKALIGUS dalam satu transaksi Midtrans.
  final List<TagihanModel> tagihanList;

  @override
  State<PaymentWebViewPage> createState() => _PaymentWebViewPageState();
}

class _PaymentWebViewPageState extends State<PaymentWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _resolved = false;
  String _loadingMessage = 'Menghubungkan ke Midtrans...';
  String? _snapUrl;
  String? _orderId;
  Timer? _pollTimer;

  TagihanModel get _tertua => widget.tagihanList.first;
  TagihanModel get _terbaru => widget.tagihanList.last;
  List<String> get _ids => widget.tagihanList.map((t) => t.id).toList();
  int get _totalJumlah =>
      widget.tagihanList.fold(0, (sum, t) => sum + t.jumlah);
  String get _periodeLabel => widget.tagihanList.length > 1
      ? '${widget.tagihanList.length} Bulan Tertunggak'
      : _tertua.periodeLabel;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _isLoading = true),
        onPageFinished: (_) => setState(() => _isLoading = false),
        onNavigationRequest: (req) {
          final url = req.url;
          if (url.contains('transaction_status=capture') ||
              url.contains('transaction_status=settlement')) {
            _handleResult(PaymentResult.success);
            return NavigationDecision.prevent;
          }
          if (url.contains('transaction_status=deny') ||
              url.contains('transaction_status=cancel') ||
              url.contains('transaction_status=expire')) {
            _handleResult(PaymentResult.failed);
            return NavigationDecision.prevent;
          }
          if (url.contains('transaction_status=pending')) {
            _handleResult(PaymentResult.pending);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ));
    _initPayment();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _initPayment() async {
    final orderId = 'IUR-${DateTime.now().millisecondsSinceEpoch}';
    _orderId = orderId;

    try {
      await PaymentRepository.setOrderIdForMany(
        tagihanIds: _ids,
        orderId: orderId,
      );
    } catch (_) {
      // Tidak fatal — lanjutkan request Snap walau gagal set orderId.
    }

    final url = await MidtransService.getSnapRedirectUrl(
      orderId: orderId,
      amount: _totalJumlah,
      nama: _tertua.namaResiden,
      phone: _tertua.nomorHp,
      email: AuthRepository.currentUser?.email,
    );

    if (!mounted) return;

    if (url == null) {
      setState(() {
        _loadingMessage =
            'Gagal terhubung ke Midtrans. Periksa Server Key di midtrans_config.dart.';
      });
      return;
    }

    setState(() => _snapUrl = url);
    _controller.loadRequest(Uri.parse(url));

    // Banyak metode bayar Midtrans (GoPay, QRIS, transfer VA) TIDAK pernah
    // me-redirect webview ini ke URL finish — user menyelesaikan pembayaran
    // di app/HP lain. Tanpa redirect, onNavigationRequest di atas tidak akan
    // pernah terpicu, sehingga status tidak pernah ter-update otomatis.
    // Untuk menutup gap itu, polling status transaksi secara berkala ke
    // Midtrans selama halaman ini masih terbuka.
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (_resolved) {
        _pollTimer?.cancel();
        return;
      }
      try {
        final status = await MidtransService.verifyStatus(orderId);
        if (MidtransService.isPaid(status)) {
          await _handleResult(PaymentResult.success);
        } else if (status == 'deny' ||
            status == 'cancel' ||
            status == 'expire') {
          await _handleResult(PaymentResult.failed);
        }
        // status == 'pending' (atau null/belum ada transaksi) -> terus polling.
      } catch (_) {
        // Abaikan kegagalan satu kali polling, coba lagi di tick berikutnya.
      }
    });
  }

  Future<void> _handleResult(PaymentResult resultFromUrl) async {
    if (_resolved) return;
    _resolved = true;
    _pollTimer?.cancel();

    var result = resultFromUrl;

    try {
      final orderId = _orderId;
      if (orderId != null) {
        final status = await MidtransService.verifyStatus(orderId);
        if (MidtransService.isPaid(status)) {
          result = PaymentResult.success;
        } else if (status == 'pending') {
          result = PaymentResult.pending;
        } else if (status != null) {
          result = PaymentResult.failed;
        }
      }

      if (result == PaymentResult.success) {
        // Lunaskan SEMUA bulan tunggakan sekaligus dalam satu batch.
        await PaymentRepository.markManyAsLunas(
          tagihanIds: _ids,
          metodeBayar: 'Midtrans',
          orderId: _orderId,
        );
      }
    } catch (_) {
      // Biarkan navigasi ke status page walau update Firestore gagal.
    }

    if (!mounted) return;

    // Gabungkan semua tagihan yang dibayar jadi satu model representatif
    // (jumlah dijumlah, periode digabung) untuk ditampilkan di status page.
    final combined = TagihanModel(
      id: _tertua.id,
      bulan: widget.tagihanList.length > 1 ? _periodeLabel : _tertua.bulan,
      bulanIndex: _tertua.bulanIndex,
      tahun: _terbaru.tahun,
      namaResiden: _tertua.namaResiden,
      blok: _tertua.blok,
      nomorUnit: _tertua.nomorUnit,
      jumlah: _totalJumlah,
      jatuhTempo: _tertua.jatuhTempo,
      status: result == PaymentResult.success
          ? StatusTagihan.lunas
          : result == PaymentResult.pending
              ? StatusTagihan.pending
              : StatusTagihan.belumBayar,
      userId: _tertua.userId,
      nomorHp: _tertua.nomorHp,
    );

    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => PaymentStatusPage(tagihan: combined, result: result),
    ));
  }

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

  @override
  Widget build(BuildContext context) {
    final hasUrl = _snapUrl != null;

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
            Text('Pembayaran',
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
            Text(_periodeLabel,
                style:
                    GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey)),
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
                Text('Aman',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: Colors.green.shade600)),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (hasUrl) WebViewWidget(controller: _controller),
          if (!hasUrl || _isLoading)
            Container(
              color: Colors.white,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                          color: AppColors.primary, strokeWidth: 2.5),
                      const SizedBox(height: 16),
                      Text(_loadingMessage,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                              fontSize: 14, color: AppColors.textGrey)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
