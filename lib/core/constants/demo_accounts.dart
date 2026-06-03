/// Akun demo untuk keperluan testing UI.
/// Ganti dengan autentikasi API yang sesungguhnya saat production.

enum UserRole { admin, user, satpam }

class DemoAccount {
  const DemoAccount({
    required this.id,
    required this.username,
    required this.password,
    required this.namaLengkap,
    required this.blok,
    required this.nomorUnit,
    required this.role,
  });

  final String id;
  final String username;
  final String password;
  final String namaLengkap;
  final String blok;
  final String nomorUnit;
  final UserRole role;

  String get roleLabel => switch (role) {
        UserRole.admin   => 'Administrator',
        UserRole.user    => 'Pemilik Unit',
        UserRole.satpam  => 'Satpam',
      };
}

class DemoAccounts {
  DemoAccounts._();

  static const List<DemoAccount> all = [
    // ── Admin ───────────────────────────────
    DemoAccount(
      id: 'admin1',
      username: 'admin',
      password: 'admin123',
      namaLengkap: 'Admin Residence',
      blok: '-',
      nomorUnit: '-',
      role: UserRole.admin,
    ),

    // ── User / Pemilik Unit ──────────────────
    DemoAccount(
      id: 'user1',
      username: 'user1',
      password: '123',
      namaLengkap: 'Alex Pratama',
      blok: 'Blok A',
      nomorUnit: '42',
      role: UserRole.user,
    ),
    DemoAccount(
      id: 'user2',
      username: 'budi',
      password: '123456',
      namaLengkap: 'Budi Santoso',
      blok: 'Blok A',
      nomorUnit: '12',
      role: UserRole.user,
    ),

    // ── Satpam ──────────────────────────────
    DemoAccount(
      id: 'satpam1',
      username: 'satpam',
      password: 'satpam123',
      namaLengkap: 'Rudi Hartono',
      blok: '-',
      nomorUnit: '-',
      role: UserRole.satpam,
    ),
  ];

  /// Cari akun berdasarkan username & password.
  /// Return null jika tidak ditemukan.
  static DemoAccount? find(String username, String password) {
    try {
      return all.firstWhere(
        (a) => a.username == username.trim() && a.password == password,
      );
    } catch (_) {
      return null;
    }
  }
}