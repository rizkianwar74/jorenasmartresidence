import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Wrapper untuk Pakasir payment gateway.
///
/// Docs: https://pakasir.com/p/docs
///
/// Flow:
///   1. Buka URL [buildPaymentUrl] di browser eksternal (url_launcher).
///   2. Poll [getTransactionStatus] setiap beberapa detik.
///   3. Kalau [isPaid] → tandai tagihan lunas di Firestore.
class PakasirService {
  PakasirService._();

  static String get _slug   => dotenv.maybeGet('PAKASIR_SLUG')    ?? '';
  static String get _apiKey => dotenv.maybeGet('PAKASIR_API_KEY') ?? '';

  static const String _payBase = 'https://app.pakasir.com/pay';
  static const String _apiBase = 'https://app.pakasir.com/api';

  // ── URL pembayaran ──────────────────────────────────────────────────────────
  /// Buat URL halaman pembayaran yang dibuka di browser eksternal.
  /// Format: https://app.pakasir.com/pay/{slug}/{amount}?order_id={id}&qris_only=1
  ///
  /// Parameter `qris_only=1` memaksa halaman Pakasir hanya menampilkan QRIS —
  /// user langsung melihat QR code dan tidak bisa ganti ke metode lain.
  static String buildPaymentUrl({
    required String orderId,
    required int    amount,
  }) =>
      '$_payBase/$_slug/$amount?order_id=$orderId&qris_only=1';

  // ── Cek status transaksi ───────────────────────────────────────────────────
  /// Ambil status transaksi via Pakasir Transaction Detail API.
  ///
  /// Return: `'completed'`, `'pending'`, atau `null` (belum ada / error).
  static Future<String?> getTransactionStatus({
    required String orderId,
    required int    amount,
  }) async {
    if (_slug.isEmpty || _apiKey.isEmpty) {
      debugPrint(
          '[Pakasir] PAKASIR_SLUG / PAKASIR_API_KEY belum diisi di .env');
      return null;
    }
    try {
      final uri = Uri.parse('$_apiBase/transactiondetail').replace(
        queryParameters: {
          'project'  : _slug,
          'amount'   : amount.toString(),
          'order_id' : orderId,
          'api_key'  : _apiKey,
        },
      );
      final res = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final tx   = data['transaction'] as Map<String, dynamic>?;
        return tx?['status'] as String?;
      }
      debugPrint('[Pakasir] getStatus ${res.statusCode}: ${res.body}');
      return null;
    } catch (e) {
      debugPrint('[Pakasir] getStatus error: $e');
      return null;
    }
  }

  // ── Helper status ─────────────────────────────────────────────────────────
  static bool isPaid(String? status) => status == 'completed';
}
