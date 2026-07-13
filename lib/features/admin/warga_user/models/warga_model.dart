class AdminWargaModel {
  AdminWargaModel({
    required this.uid,
    required this.namaLengkap,
    required this.email,
    required this.blok,
    required this.nomorUnit,
    required this.nomorHp,
    this.komunitasRole,
    this.role = 'user',
  });

  final String uid;
  final String namaLengkap;
  final String email;
  final String blok;
  final String nomorUnit;
  final String nomorHp;
  final String? komunitasRole;
  /// Role sistem: 'user' | 'satpam' | 'admin'
  final String role;

  String get unitLabel => '$blok - No. $nomorUnit';

  String get initials {
    final parts = namaLengkap.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return namaLengkap.isNotEmpty ? namaLengkap[0].toUpperCase() : '?';
  }

  factory AdminWargaModel.fromFirestore(
      String uid, Map<String, dynamic> data) {
    return AdminWargaModel(
      uid           : uid,
      namaLengkap   : data['namaLengkap']   as String? ?? '-',
      email         : data['email']          as String? ?? '-',
      blok          : data['blok']           as String? ?? '-',
      nomorUnit     : data['nomorUnit']      as String? ?? '-',
      nomorHp       : data['nomorHp']        as String? ?? '-',
      komunitasRole : data['komunitasRole']  as String?,
      role          : data['role']           as String? ?? 'user',
    );
  }
}

/// Nilai sentinel untuk chip filter "SATPAM" di WargaFilterBar.
///
/// Sengaja BUKAN string kosong (''): satpam bisa saja punya blok/nomorUnit
/// asli juga (mis. ditugaskan tinggal di salah satu unit), jadi filter
/// "SATPAM" harus murni berdasarkan `role == 'satpam'`, terpisah total dari
/// filter blok — supaya satpam yang punya blok tetap ikut ke-filter saat
/// chip "SATPAM" dipilih, bukan cuma yang bloknya kosong.
const String kSatpamFilterValue = '__satpam_filter__';

const List<String> jabatanOptions = [
  '',
  'KETUA RT',
  'WAKIL KETUA RT',
  'KETUA STM',
  'WAKIL KETUA STM',
];

/// Opsi role sistem yang bisa di-set admin dari dalam app.
/// Role 'admin' tidak termasuk — hanya bisa diset via Firebase Console.
const List<String> roleOptions = ['user', 'satpam'];
