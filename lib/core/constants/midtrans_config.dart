// Konfigurasi Midtrans (sandbox/production via .env).
//
// Key dibaca dari file .env (di-gitignore, tidak ikut commit).
// Template ada di .env.example.
//
// ⚠️ Server Key di client hanya untuk sandbox/skripsi. Production: pindah
// ke Cloud Functions agar key tidak bocor di APK.

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MidtransConfig {
  MidtransConfig._();

  /// Base URL Snap API untuk request token.
  static const String sandboxSnapUrl =
      'https://app.sandbox.midtrans.com/snap/v1/transactions';
  static const String productionSnapUrl =
      'https://app.midtrans.com/snap/v1/transactions';

  /// Base URL Core API untuk cek status transaksi.
  static const String sandboxStatusUrl =
      'https://api.sandbox.midtrans.com/v2';
  static const String productionStatusUrl =
      'https://api.midtrans.com/v2';

  /// true = production (uang asli), false = sandbox (test).
  static bool get isProduction {
    final raw = dotenv.maybeGet('MIDTRANS_IS_PRODUCTION') ?? 'false';
    return raw.toLowerCase() == 'true';
  }

  /// Server Key dari .env.
  static String get serverKey =>
      dotenv.maybeGet('MIDTRANS_SERVER_KEY') ?? '';

  /// Client Key dari .env.
  static String get clientKey =>
      dotenv.maybeGet('MIDTRANS_CLIENT_KEY') ?? '';

  /// URL Snap aktif sesuai mode.
  static String get snapBaseUrl =>
      isProduction ? productionSnapUrl : sandboxSnapUrl;

  /// URL status aktif sesuai mode.
  static String get statusBaseUrl =>
      isProduction ? productionStatusUrl : sandboxStatusUrl;

  /// Header Basic Auth untuk Midtrans (Server Key : <kosong>).
  static String get authHeader {
    final credentials = base64Encode(utf8.encode('${serverKey}:'));
    return 'Basic $credentials';
  }
}
