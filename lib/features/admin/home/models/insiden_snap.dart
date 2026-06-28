class InsidenSnap {
  const InsidenSnap({
    required this.kategori,
    required this.lokasi,
    required this.status,
    required this.waktu,
  });
  final String   kategori;
  final String   lokasi;
  final String   status;
  final DateTime waktu;

  int get severity => switch (status) {
    'BARU'      => 2,
    'DITANGANI' => 1,
    _           => 0,
  };
}
