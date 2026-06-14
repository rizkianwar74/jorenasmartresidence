class WargaModel {
  const WargaModel({
    required this.id,
    required this.namaLengkap,
    required this.blok,
    required this.nomorUnit,
    required this.nomorHp,
    required this.email,
    this.photoUrl,
    this.komunitasRole,
  });

  final String id;
  final String namaLengkap;
  final String blok;
  final String nomorUnit;
  final String nomorHp;
  final String email;
  final String? photoUrl;
  final String? komunitasRole; // e.g. 'KETUA RT', 'BENDAHARA'

  String get unitLabel => '$blok - No. $nomorUnit';

  /// Format nomor WA: 08xx → 628xx
  String get waNumber {
    final n = nomorHp.replaceAll(RegExp(r'[^0-9]'), '');
    if (n.startsWith('0')) return '62${n.substring(1)}';
    if (n.startsWith('62')) return n;
    return '62$n';
  }

  factory WargaModel.fromFirestore(String id, Map<String, dynamic> data) {
    return WargaModel(
      id            : id,
      namaLengkap   : data['namaLengkap']   as String? ?? '-',
      blok          : data['blok']           as String? ?? '-',
      nomorUnit     : data['nomorUnit']      as String? ?? '-',
      nomorHp       : data['nomorHp']        as String? ?? '-',
      email         : data['email']          as String? ?? '-',
      photoUrl      : data['photoUrl']       as String?,
      komunitasRole : data['komunitasRole']  as String?,
    );
  }
}
