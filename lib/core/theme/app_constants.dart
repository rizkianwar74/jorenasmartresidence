/// Konstanta global aplikasi Smart Residence.
///
/// Dipusatkan di sini agar tidak ada magic number yang tersebar.

class AppConstants {
  AppConstants._();

  // ── Identitas App ─────────────────────────────────────────────────────────
  static const String appName    = 'Smart Residence';
  static const String appVersion = '1.0.0';
  static const String residenceName = 'Jorena Smart Residence';

  // ── Layout — lebar konten ─────────────────────────────────────────────────
  /// Lebar maksimum konten halaman mobile (home, komunitas, layanan, dll.)
  /// Membatasi konten agar tetap terbaca di layar tablet/desktop.
  static const double contentMaxWidth = 600.0;

  /// Lebar maksimum form / dialog (auth, layanan, patroli, dll.)
  static const double formMaxWidth = 480.0;

  // ── Animasi ───────────────────────────────────────────────────────────────
  static const Duration fastAnimation   = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation   = Duration(milliseconds: 500);
}
