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

  // Slug proyek Pakasir. Aman sebagai konstanta di client — nilainya cuma
  // dipakai membentuk URL halaman pembayaran dan tetap terlihat di URL yang
  // dibuka pengguna, jadi memang bukan rahasia. Berbeda dengan PAKASIR_API_KEY
  // yang hanya hidup di server.
  //
  // Sebelumnya dibaca lewat flutter_dotenv. Paket itu sudah dilepas karena
  // setelah kedua kunci rahasia pindah ke server, tidak ada lagi nilai rahasia
  // yang perlu dibaca dari .env — sedangkan .env sebagai asset justru ikut
  // terkemas ke dalam APK.
  //
  // GANTI dengan slug proyek Pakasir kamu.
  static const String _slug = 'jorenaapp';

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
