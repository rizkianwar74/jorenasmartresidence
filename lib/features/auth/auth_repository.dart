// lib/features/auth/auth_repository.dart
// Update: login sekarang baca role dari Firestore collection 'users/{uid}'

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ── Model hasil login ────────────────────────────────────────────────────────
class AuthResult {
  const AuthResult({
    required this.username,
    required this.namaLengkap,
    required this.blok,
    required this.nomorUnit,
    required this.role,
    this.photoUrl,
  });

  final String username;
  final String namaLengkap;
  final String blok;
  final String nomorUnit;
  final UserRole role;
  final String? photoUrl;
}

// ── Tiga role yang tersedia ──────────────────────────────────────────────────
enum UserRole { user, admin, satpam }

// ── Helper: konversi string Firestore → enum ─────────────────────────────────
UserRole _parseRole(String? raw) {
  switch (raw) {
    case 'admin':
      return UserRole.admin;
    case 'satpam':
      return UserRole.satpam;
    default:
      return UserRole.user;
  }
}

// ── Repository ───────────────────────────────────────────────────────────────
class AuthRepository {
  AuthRepository._();

  static AuthResult? _currentUser;
  static AuthResult? get currentUser => _currentUser;
  static bool get isLoggedIn => _currentUser != null;

  // ── Login ─────────────────────────────────────────────────────────────────
  static Future<AuthResult?> login(String email, String password) async {
    try {
      // 1. Login ke Firebase Auth
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final user = credential.user;
      if (user == null) return null;

      // 2. Baca data tambahan dari Firestore collection 'users'
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      // 3. Ambil field dari Firestore (fallback ke nilai default jika belum ada)
      final data = doc.data();
      final role = _parseRole(data?['role'] as String?);
      final namaLengkap = (data?['namaLengkap'] as String?)?.isNotEmpty == true
          ? data!['namaLengkap'] as String
          : (user.displayName ?? 'Pengguna');
      final blok = data?['blok'] as String? ?? '-';
      final nomorUnit = data?['nomorUnit'] as String? ?? '-';

      // 4. Simpan ke state in-memory
      final photoUrl = (data?['photoUrl'] as String?)?.isNotEmpty == true
          ? data!['photoUrl'] as String
          : user.photoURL;

      _currentUser = AuthResult(
        username: user.email ?? '',
        namaLengkap: namaLengkap,
        blok: blok,
        nomorUnit: nomorUnit,
        role: role,
        photoUrl: photoUrl,
      );

      return _currentUser;
    } catch (e) {
      return null;
    }
  }

  // ── Register ──────────────────────────────────────────────────────────────
  static Future<String?> register({
    required String email,
    required String password,
    required String namaLengkap,
    required String blok,
    required String nomorUnit,
    required String tanggalLahir,
  }) async {
    try {
      // 1. Buat akun di Firebase Auth
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = credential.user?.uid;
      if (uid == null) return 'Gagal membuat akun';

      // 2. Update displayName di Auth
      await credential.user?.updateDisplayName(namaLengkap);

      // 3. Simpan data lengkap ke Firestore — role default 'user'
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'namaLengkap': namaLengkap,
        'email': email,
        'blok': blok,
        'nomorUnit': nomorUnit,
        'tanggalLahir': tanggalLahir,
        'role': 'user', // default semua registrasi baru = user biasa
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null; // null = sukses
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') return 'Email sudah digunakan';
      if (e.code == 'weak-password') return 'Password terlalu lemah';
      return e.message;
    } catch (e) {
      return 'Terjadi kesalahan. Coba lagi.';
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  static Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    _currentUser = null;
  }
}