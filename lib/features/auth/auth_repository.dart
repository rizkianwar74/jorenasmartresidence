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
    required this.email,
    required this.nomorHp,
    required this.tanggalLahir,
    this.photoUrl,
  });

  final String username;
  final String namaLengkap;
  final String blok;
  final String nomorUnit;
  final UserRole role;
  final String email;
  final String nomorHp;
  final String tanggalLahir;
  final String? photoUrl;

  // clearPhoto: true → paksa photoUrl jadi null
  AuthResult copyWith({
    String? username,
    String? email,
    String? nomorHp,
    String? tanggalLahir,
    String? blok,
    String? nomorUnit,
    String? photoUrl,
    bool clearPhoto = false,
  }) => AuthResult(
        username     : username     ?? this.username,
        namaLengkap  : namaLengkap,
        blok         : blok         ?? this.blok,
        nomorUnit    : nomorUnit    ?? this.nomorUnit,
        role         : role,
        email        : email        ?? this.email,
        nomorHp      : nomorHp      ?? this.nomorHp,
        tanggalLahir : tanggalLahir ?? this.tanggalLahir,
        photoUrl     : clearPhoto ? null : (photoUrl ?? this.photoUrl),
      );
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

  // ── Logout — bersihkan in-memory session ──────────────────────────────────
  static void clearUser() => _currentUser = null;

  // ── Update field profil (in-memory + Firestore) ──────────────────────────
  static Future<void> updateProfile(String field, String value) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({field: value.trim()});
    _currentUser = _currentUser?.copyWith(
      username    : field == 'username'     ? value.trim() : null,
      email       : field == 'email'        ? value.trim() : null,
      nomorHp     : field == 'nomorHp'      ? value.trim() : null,
      tanggalLahir: field == 'tanggalLahir' ? value.trim() : null,
      blok        : field == 'blok'         ? value.trim() : null,
      nomorUnit   : field == 'nomorUnit'    ? value.trim() : null,
    );
  }

  // ── Update blok + nomorUnit sekaligus ────────────────────────────────────
  static Future<void> updateAlamat(String blok, String nomorUnit) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'blok': blok.trim(), 'nomorUnit': nomorUnit.trim()});
    _currentUser = _currentUser?.copyWith(
      blok     : blok.trim(),
      nomorUnit: nomorUnit.trim(),
    );
  }

  // ── Update foto profil (in-memory + Firestore) ────────────────────────────
  static Future<void> updatePhotoUrl(String url) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'photoUrl': url});
    _currentUser = _currentUser?.copyWith(photoUrl: url);
  }

  // ── Hapus foto profil (set null di Firestore + in-memory) ────────────────
  static Future<void> removePhotoUrl() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'photoUrl': FieldValue.delete()});
    _currentUser = _currentUser?.copyWith(clearPhoto: true);
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  static Future<AuthResult?> login(String email, String password) async {
    try {
      // 1. Login ke Firebase Auth dengan email asli
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
              email: email.trim().toLowerCase(), password: password);

      final user = credential.user;
      if (user == null) return null;

      // 2. Baca data tambahan dari Firestore collection 'users'
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      // 3. Ambil field dari Firestore
      final data = doc.data();
      final role = _parseRole(data?['role'] as String?);
      final namaLengkap = (data?['namaLengkap'] as String?)?.isNotEmpty == true
          ? data!['namaLengkap'] as String
          : (user.displayName ?? 'Pengguna');
      final blok         = data?['blok']          as String? ?? '-';
      final nomorUnit    = data?['nomorUnit']      as String? ?? '-';
      final username     = data?['username']       as String? ?? '';
      final emailDb      = data?['email']          as String? ?? '';
      final nomorHp      = data?['nomorHp']        as String? ?? '-';
      final tanggalLahir = data?['tanggalLahir']   as String? ?? '-';

      final photoUrl = (data?['photoUrl'] as String?)?.isNotEmpty == true
          ? data!['photoUrl'] as String
          : user.photoURL;

      _currentUser = AuthResult(
        username     : username,
        namaLengkap  : namaLengkap,
        blok         : blok,
        nomorUnit    : nomorUnit,
        role         : role,
        email        : emailDb,
        nomorHp      : nomorHp,
        tanggalLahir : tanggalLahir,
        photoUrl     : photoUrl,
      );

      return _currentUser;
    } catch (e) {
      return null;
    }
  }

  // ── Register ──────────────────────────────────────────────────────────────
  static Future<String?> register({
    required String username,
    required String email,
    required String nomorHp,
    required String password,
    required String namaLengkap,
    required String blok,
    required String nomorUnit,
    required String tanggalLahir,
  }) async {
    try {
      final cleanUsername = username.trim().toLowerCase();

      // 1. Buat akun di Firebase Auth dengan email asli
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: email.trim().toLowerCase(), password: password);

      final uid = credential.user?.uid;
      if (uid == null) return 'Gagal membuat akun';

      // 4. Update displayName di Auth
      await credential.user?.updateDisplayName(namaLengkap);

      // 5. Simpan data lengkap ke Firestore — role default 'user'
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'username': cleanUsername,
        'email': email.trim().toLowerCase(),
        'nomorHp': nomorHp.trim(),
        'namaLengkap': namaLengkap,
        'blok': blok,
        'nomorUnit': nomorUnit,
        'tanggalLahir': tanggalLahir,
        'role': 'user', // default semua registrasi baru = user biasa
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null; // null = sukses
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') return 'Username sudah digunakan';
      if (e.code == 'weak-password') return 'Password terlalu lemah';
      return e.message;
    } catch (e) {
      return 'Terjadi kesalahan. Coba lagi.';
    }
  }

  // ── Reset Password ────────────────────────────────────────────────────────
  // Langsung kirim via Firebase Auth — tidak perlu cek Firestore dulu
  static Future<String?> resetPassword(String email) async {
    try {
      final cleanEmail = email.trim().toLowerCase();

      // Langkah 1: cek apakah email terdaftar di Firestore
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: cleanEmail)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        return 'Email tidak terdaftar. Periksa kembali alamat email Anda.';
      }

      // Langkah 2: kirim link reset
      await FirebaseAuth.instance.sendPasswordResetEmail(email: cleanEmail);
      return null; // null = sukses
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-email') return 'Format email tidak valid';
      return e.message ?? 'Terjadi kesalahan. Coba lagi.';
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