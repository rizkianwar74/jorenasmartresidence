import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MidtransConfig {
  MidtransConfig._();

  static const String sandboxSnapUrl =
      'https://app.sandbox.midtrans.com/snap/v1/transactions';
  static const String productionSnapUrl =
      'https://app.midtrans.com/snap/v1/transactions';
  static const String sandboxStatusUrl = 'https://api.sandbox.midtrans.com/v2';
  static const String productionStatusUrl = 'https://api.midtrans.com/v2';

  static bool get isProduction {
    final raw = dotenv.maybeGet('MIDTRANS_IS_PRODUCTION') ?? 'false';
    return raw.toLowerCase() == 'true';
  }

  static String get serverKey => dotenv.maybeGet('MIDTRANS_SERVER_KEY') ?? '';
  static String get clientKey => dotenv.maybeGet('MIDTRANS_CLIENT_KEY') ?? '';

  static String get snapBaseUrl => isProduction ? productionSnapUrl : sandboxSnapUrl;
  static String get statusBaseUrl => isProduction ? productionStatusUrl : sandboxStatusUrl;

  static String get authHeader {
    final credentials = base64Encode(utf8.encode('$serverKey:'));
    return 'Basic $credentials';
  }
}
