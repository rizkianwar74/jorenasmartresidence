import '../../core/constants/demo_accounts.dart';

/// Model untuk akun yang didaftarkan via form registrasi
class RegisteredAccount {
  const RegisteredAccount({
    required this.username,
    required this.password,
    required this.namaLengkap,
    required this.blok,
    required this.nomorUnit,
    required this.tanggalLahir,
    this.role = UserRole.user,
  });

  final String username;
  final String password;
  final String namaLengkap;
  final String blok;
  final String nomorUnit;
  final String tanggalLahir;
  final UserRole role;
}

/// Hasil login — bisa dari demo account atau registered account
class AuthResult {
  const AuthResult({
    required this.username,
    required this.namaLengkap,
    required this.blok,
    required this.nomorUnit,
    required this.role,
  });

  final String username;
  final String namaLengkap;
  final String blok;
  final String nomorUnit;
  final UserRole role;
}

class AuthRepository {
  AuthRepository._();

  /// Akun yang didaftarkan selama sesi berjalan (in-memory)
  static final List<RegisteredAccount> _registeredAccounts = [];

  /// Akun yang sedang login
  static AuthResult? _currentUser;
  static AuthResult? get currentUser => _currentUser;
  static bool get isLoggedIn => _currentUser != null;

  // ── Register ────────────────────────────────────────

  /// Return null jika berhasil, return pesan error jika gagal
  static String? register({
    required String username,
    required String password,
    required String namaLengkap,
    required String blok,
    required String nomorUnit,
    required String tanggalLahir,
  }) {
    // Cek apakah username sudah ada di demo accounts
    final existsInDemo = DemoAccounts.all.any(
      (a) => a.username.toLowerCase() == username.toLowerCase(),
    );

    // Cek apakah username sudah ada di registered accounts
    final existsInRegistered = _registeredAccounts.any(
      (a) => a.username.toLowerCase() == username.toLowerCase(),
    );

    if (existsInDemo || existsInRegistered) {
      return 'Username "$username" sudah digunakan';
    }

    _registeredAccounts.add(
      RegisteredAccount(
        username: username.trim(),
        password: password,
        namaLengkap: namaLengkap.trim(),
        blok: blok.trim(),
        nomorUnit: nomorUnit.trim(),
        tanggalLahir: tanggalLahir,
      ),
    );

    return null; // sukses
  }

  // ── Login ────────────────────────────────────────────

  /// Return AuthResult jika berhasil, null jika gagal
  static AuthResult? login(String username, String password) {
    // 1. Cek di demo accounts
    final demo = DemoAccounts.find(username, password);
    if (demo != null) {
      _currentUser = AuthResult(
        username: demo.username,
        namaLengkap: demo.namaLengkap,
        blok: demo.blok,
        nomorUnit: demo.nomorUnit,
        role: demo.role,
      );
      return _currentUser;
    }

    // 2. Cek di registered accounts
    try {
      final registered = _registeredAccounts.firstWhere(
        (a) =>
            a.username.toLowerCase() == username.trim().toLowerCase() &&
            a.password == password,
      );
      _currentUser = AuthResult(
        username: registered.username,
        namaLengkap: registered.namaLengkap,
        blok: registered.blok,
        nomorUnit: registered.nomorUnit,
        role: registered.role,
      );
      return _currentUser;
    } catch (_) {
      return null;
    }
  }

  // ── Logout ───────────────────────────────────────────

  static void logout() => _currentUser = null;
}