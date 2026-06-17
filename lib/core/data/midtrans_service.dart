// Service untuk komunikasi langsung dengan Midtrans Snap API (Sandbox).
//
// ⚠️ Mode sandbox. Server Key ditanam di client hanya untuk skripsi/demo.
// Production: pindahkan ke Cloud Functions.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/midtrans_config.dart';

class MidtransService {
  MidtransService._();

  /// Request Snap redirect URL. Return null bila gagal.
  ///
  /// [orderId] wajib unik per transaksi (midtrans menolak duplikat).
  /// [amount] gross amount dalam Rupiah.
  /// [nama], [email], [phone] opsional untuk data customer.
  static Future<String?> getSnapRedirectUrl({
    required String orderId,
    required int amount,
    String? nama,
    String? email,
    String? phone,
  }) async {
    final body = <String, dynamic>{
      'transaction_details': {
        'order_id': orderId,
        'gross_amount': amount,
      },
      'credit_card': {'secure': true},
    };

    // Data customer (opsional, memperbaiki tampilan Snap).
    if (nama != null || email != null || phone != null) {
      body['customer_details'] = {
        if (nama != null) 'first_name': nama,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
      };
    }

    try {
      final url = MidtransConfig.snapBaseUrl;
      final keyPreview = MidtransConfig.serverKey.length > 12
          ? '${MidtransConfig.serverKey.substring(0, 12)}...'
          : MidtransConfig.serverKey;
      // ignore: avoid_print
      print('[Midtrans] POST $url');
      // ignore: avoid_print
      print('[Midtrans] serverKey loaded: $keyPreview');
      // ignore: avoid_print
      print('[Midtrans] body: ${jsonEncode(body)}');

      final res = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': MidtransConfig.authHeader,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      // ignore: avoid_print
      print('[Midtrans] response ${res.statusCode}: ${res.body}');

      if (res.statusCode == 201 || res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return data['redirect_url'] as String?;
      }
      // Gagal — log untuk debugging.
      // ignore: avoid_print
      print('[Midtrans] getSnapUrl failed ${res.statusCode}: ${res.body}');
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('[Midtrans] getSnapUrl error: $e');
      return null;
    }
  }

  /// Cek status transaksi dari Midtrans. Return transaction_status string.
  /// Nilai mungkin: settlement, capture, pending, deny, cancel, expire, refund.
  ///
  /// Return null bila gagal request.
  static Future<String?> verifyStatus(String orderId) async {
    final url = '${MidtransConfig.statusBaseUrl}/$orderId/status';
    try {
      final res = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': MidtransConfig.authHeader,
          'Accept': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return data['transaction_status'] as String?;
      }
      // ignore: avoid_print
      print('[Midtrans] verifyStatus failed ${res.statusCode}: ${res.body}');
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('[Midtrans] verifyStatus error: $e');
      return null;
    }
  }

  /// Map transaction_status Midtrans -> status lunas/belum/pending.
  /// 'settlement' | 'capture' -> true (lunas)
  /// selainnya -> false
  static bool isPaid(String? status) {
    return status == 'settlement' || status == 'capture';
  }
}
