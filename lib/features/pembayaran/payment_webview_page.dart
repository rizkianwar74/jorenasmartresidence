import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/theme/app_colors.dart';
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

  // TODO: Ganti dengan snap_token dari Cloud Functions
  // final result = await FirebaseFunctions.instance
  //     .httpsCallable('createTransaction')
  //     .call({'order_id': widget.tagihan.id, 'amount': widget.tagihan.jumlah});
  // final snapUrl = 'https://app.sandbox.midtrans.com/snap/v2/vtweb/${result.data['snap_token']}';
  static const String _dummySnapUrl =
      'https://app.sandbox.midtrans.com/snap/v2/vtweb/SNAP_TOKEN_PLACEHOLDER';

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
            _toStatus(PaymentResult.success);
            return NavigationDecision.prevent;
          }
          if (url.contains('transaction_status=deny') ||
              url.contains('transaction_status=cancel') ||
              url.contains('transaction_status=expire')) {
            _toStatus(PaymentResult.failed);
            return NavigationDecision.prevent;
          }
          if (url.contains('transaction_status=pending')) {
            _toStatus(PaymentResult.pending);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(_dummySnapUrl));
  }

  void _toStatus(PaymentResult result) {
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) =>
          PaymentStatusPage(tagihan: widget.tagihan, result: result),
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
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 2.5),
                    const SizedBox(height: 16),
                    Text('Memuat halaman pembayaran...',
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