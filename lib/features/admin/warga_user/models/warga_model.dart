class AdminWargaModel {
  AdminWargaModel({
    required this.uid,
    required this.namaLengkap,
    required this.email,
    required this.blok,
    required this.nomorUnit,
    required this.nomorHp,
    this.komunitasRole,
  });

  final String uid;
  final String namaLengkap;
  final String email;
  final String blok;
  final String nomorUnit;
  final String nomorHp;
  final String? komunitasRole;

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
    );
  }
}

const List<String> jabatanOptions = [
  '',
  'KETUA RT',
  'WAKIL KETUA RT',
  'KETUA STM',
  'WAKIL KETUA STM',
];
