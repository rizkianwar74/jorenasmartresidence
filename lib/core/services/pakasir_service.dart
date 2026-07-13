import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Wrapper untuk Pakasir payment gateway.
///
/// Docs: https://pakasir.com/p/docs
///
/// Flow:
///   1. Buka URL [buildPaymentUrl] di browser eksternal (url_launcher).
///   2. Pembayaran diverifikasi oleh server webhook (server/pakasir-webhook/),
///      BUKAN oleh app ini — lihat docs/payment_webhook_fix_prompt.md.
///
/// Catatan: dulu class ini juga punya `getTransactionStatus()`/`isPaid()`
/// yang memanggil API transactiondetail Pakasir LANGSUNG dari client pakai
/// PAKASIR_API_KEY yang ikut ter-bundle di APK. Itu dihapus karena api_key
/// tidak boleh ada di client — klien tidak boleh punya wewenang memverifikasi
/// (dan berpotensi memalsukan) status pembayarannya sendiri. Verifikasi kini
/// sepenuhnya jadi tugas server webhook; app Flutter cukup listen Firestore
/// (lihat PaymentRepository.watchTagihanByIds) untuk tahu kapan tagihan
/// sudah ditandai lunas oleh server.
class PakasirService {
  PakasirService._();

  // PAKASIR_SLUG aman ada di client — cuma dipakai membentuk URL pembayaran,
  // bukan kredensial. PAKASIR_API_KEY SENGAJA tidak ada lagi di sini/.env.
  static String get _slug => dotenv.maybeGet('PAKASIR_SLUG') ?? '';

  static const String _payBase = 'https://app.pakasir.com/pay';

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
}
