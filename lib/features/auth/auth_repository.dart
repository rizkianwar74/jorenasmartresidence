import 'package:firebase_auth/firebase_auth.dart';

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

enum UserRole { user, admin }

class AuthRepository {
  AuthRepository._();

  static AuthResult? _currentUser;
  static AuthResult? get currentUser => _currentUser;
  static bool get isLoggedIn => _currentUser != null;

  // ── Login ─────────────────────────────────────────────
  static Future<AuthResult?> login(String email, String password) async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) return null;

      _currentUser = AuthResult(
        username: user.email ?? '',
        namaLengkap: user.displayName ?? 'Pengguna',
        blok: '-',
        nomorUnit: '-',
        role: UserRole.user,
      );

      return _currentUser;
    } catch (e) {
      return null;
    }
  }

  // ── Register ──────────────────────────────────────────
  static Future<String?> register({
    required String email,
    required String password,
    required String namaLengkap,
    required String blok,
    required String nomorUnit,
    required String tanggalLahir,
  }) async {
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      await credential.user?.updateDisplayName(namaLengkap);

      return null; // sukses
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return 'Email sudah digunakan';
      } else if (e.code == 'weak-password') {
        return 'Password terlalu lemah';
      }
      return e.message;
    }
  }

  // ── Logout ────────────────────────────────────────────
  static Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    _currentUser = null;
  }
}