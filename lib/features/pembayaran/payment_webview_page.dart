import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/data/midtrans_service.dart';
import '../../core/theme/app_colors.dart';
import 'payment_repository.dart';
import 'tagihan_model.dart';
import 'payment_status_page.dart';

class PaymentWebViewPage extends StatefulWidget {
  const PaymentWebViewPage({super.key, required this.tagihan});
  final TagihanModel tagihan;

  @override
  State<PaymentWebViewPage> createState() => _PaymentWebViewPageState();
}

class _PaymentWebViewPageState extends State<PaymentWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _resolved = false; // true bila status final sudah diproses
  String _loadingMessage = 'Menyiapkan pembayaran...';
  String? _snapUrl;

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
          // Deteksi redirect finish Midtrans (status ada di query param).
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

    // Request Snap URL dari Midtrans.
    _initPayment();
  }

  /// Generate order_id unik + minta redirect URL Snap.
  Future<void> _initPayment() async {
    // Order id unik & PENDEK (Midtrans max 50 char).
    // Format: IUR-{timestamp-millis} → cukup unik untuk demo.
    final orderId = 'IUR-${DateTime.now().millisecondsSinceEpoch}';

    // Simpan orderId ke Firestore untuk referensi admin.
    try {
      await PaymentRepository.setOrderId(
        tagihanId: widget.tagihan.id,
        orderId: orderId,
      );
    } catch (_) {/* abaikan bila tagihan belum ada doc */}

    final url = await MidtransService.getSnapRedirectUrl(
      orderId: orderId,
      amount: widget.tagihan.jumlah,
      nama: widget.tagihan.namaResiden,
      phone: widget.tagihan.nomorHp,
    );

    if (!mounted) return;

    if (url == null) {
      setState(() => _loadingMessage =
          'Gagal terhubung ke Midtrans. Periksa Server Key di midtrans_config.dart.');
      return;
    }

    setState(() {
      _snapUrl = url;
      _loadingMessage = 'Memuat halaman pembayaran...';
    });
    _controller.loadRequest(Uri.parse(url));
  }

  /// Proses hasil pembayaran: verifikasi ke Midtrans, update Firestore, pindah halaman.
  Future<void> _handleResult(PaymentResult resultFromUrl) async {
    if (_resolved) return;
    _resolved = true;

    setState(() => _isLoading = true);

    // Ambil orderId terbaru dari Firestore (yang disimpan _initPayment).
    final latest = await PaymentRepository.getTagihan(widget.tagihan.id);
    final orderId = latest?.orderId;

    // Verifikasi ke Midtrans untuk pastikan status (lebih reliable dari URL).
    if (orderId != null) {
      final status = await MidtransService.verifyStatus(orderId);
      if (status != null) {
        if (MidtransService.isPaid(status)) {
          resultFromUrl = PaymentResult.success;
          await PaymentRepository.updatePaymentStatus(
            tagihanId: widget.tagihan.id,
            status: StatusTagihan.lunas,
            orderId: orderId,
          );
        } else if (status == 'pending') {
          resultFromUrl = PaymentResult.pending;
          await PaymentRepository.updatePaymentStatus(
            tagihanId: widget.tagihan.id,
            status: StatusTagihan.pending,
            orderId: orderId,
          );
        } else {
          resultFromUrl = PaymentResult.failed;
        }
      } else {
        // Verifikasi gagal — pakai hasil dari URL.
        if (resultFromUrl == PaymentResult.success) {
          await PaymentRepository.updatePaymentStatus(
            tagihanId: widget.tagihan.id,
            status: StatusTagihan.lunas,
            orderId: orderId,
          );
        }
      }
    }

    if (!mounted) return;
    _toStatus(resultFromUrl);
  }

  void _toStatus(PaymentResult result) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentStatusPage(
            tagihan: widget.tagihan, result: result),
      ),
    );
  }

  void _confirmClose() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            child:
                Text('Keluar', style: GoogleFonts.inter(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // _snapUrl dipakai untuk memastikan controller sudah load.
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
            Text(widget.tagihan.periodeLabel,
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
          // Tampilkan WebView hanya bila URL sudah didapat.
          if (hasUrl) WebViewWidget(controller: _controller),
          if (_isLoading || !hasUrl)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 2.5),
                    const SizedBox(height: 16),
                    Text(_loadingMessage,
                        style: GoogleFonts.inter(
                            fontSize: 14, color: AppColors.textGrey)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
