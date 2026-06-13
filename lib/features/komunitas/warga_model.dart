class WargaModel {
  const WargaModel({
    required this.id,
    required this.name,
    required this.blok,
    required this.nomorUnit,
    this.imageUrl,
    this.role,
  });

  final String id;
  final String name;
  final String blok;
  final String nomorUnit;
  final String? imageUrl;
  final String? role; // misal: 'KETUA RT', 'BENDAHARA', null

  String get unitLabel => '$blok - No. $nomorUnit';
}

// Mock data — ganti dengan API nantinya
const List<WargaModel> mockWargaList = [
  WargaModel(
    id: '1',
    name: 'Budi Santoso',
    blok: 'Blok A',
    nomorUnit: '12',
    imageUrl: null,
    role: 'KETUA RT',
  ),
  WargaModel(
    id: '2',
    name: 'Siti Aminah',
    blok: 'Blok A',
    nomorUnit: '05',
    imageUrl: null,
  ),
  WargaModel(
    id: '3',
    name: 'Ahmad Hidayat',
    blok: 'Blok A',
    nomorUnit: '08',
    imageUrl: null,
    role: 'BENDAHARA',
  ),
  WargaModel(
    id: '4',
    name: 'Diana Lestari',
    blok: 'Blok A',
    nomorUnit: '22',
    imageUrl: null,
  ),
  WargaModel(
    id: '5',
    name: 'Hendra Wijaya',
    blok: 'Blok A',
    nomorUnit: '15',
    imageUrl: null,
  ),
  WargaModel(
    id: '6',
    name: 'Maya Sari',
    blok: 'Blok A',
    nomorUnit: '01',
    imageUrl: null,
  ),
  WargaModel(
    id: '7',
    name: 'Riko Prasetyo',
    blok: 'Blok B',
    nomorUnit: '03',
    imageUrl: null,
  ),
  WargaModel(
    id: '8',
    name: 'Nadia Putri',
    blok: 'Blok B',
    nomorUnit: '17',
    imageUrl: null,
  ),
  WargaModel(
    id: '9',
    name: 'Fajar Nugroho',
    blok: 'Blok C',
    nomorUnit: '09',
    imageUrl: null,
  ),
];