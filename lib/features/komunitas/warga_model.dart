class WargaModel {
  const WargaModel({
    required this.id,
    required this.name,
    required this.blok,
    required this.nomorUnit,
    required this.imageUrl,
    this.role,
  });

  final String id;
  final String name;
  final String blok;
  final String nomorUnit;
  final String imageUrl;
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
    imageUrl: 'https://i.pravatar.cc/150?img=3',
    role: 'KETUA RT',
  ),
  WargaModel(
    id: '2',
    name: 'Siti Aminah',
    blok: 'Blok A',
    nomorUnit: '05',
    imageUrl: 'https://i.pravatar.cc/150?img=5',
  ),
  WargaModel(
    id: '3',
    name: 'Ahmad Hidayat',
    blok: 'Blok A',
    nomorUnit: '08',
    imageUrl: 'https://i.pravatar.cc/150?img=7',
    role: 'BENDAHARA',
  ),
  WargaModel(
    id: '4',
    name: 'Diana Lestari',
    blok: 'Blok A',
    nomorUnit: '22',
    imageUrl: 'https://i.pravatar.cc/150?img=9',
  ),
  WargaModel(
    id: '5',
    name: 'Hendra Wijaya',
    blok: 'Blok A',
    nomorUnit: '15',
    imageUrl: 'https://i.pravatar.cc/150?img=11',
  ),
  WargaModel(
    id: '6',
    name: 'Maya Sari',
    blok: 'Blok A',
    nomorUnit: '01',
    imageUrl: 'https://i.pravatar.cc/150?img=13',
  ),
  WargaModel(
    id: '7',
    name: 'Riko Prasetyo',
    blok: 'Blok B',
    nomorUnit: '03',
    imageUrl: 'https://i.pravatar.cc/150?img=15',
  ),
  WargaModel(
    id: '8',
    name: 'Nadia Putri',
    blok: 'Blok B',
    nomorUnit: '17',
    imageUrl: 'https://i.pravatar.cc/150?img=16',
  ),
  WargaModel(
    id: '9',
    name: 'Fajar Nugroho',
    blok: 'Blok C',
    nomorUnit: '09',
    imageUrl: 'https://i.pravatar.cc/150?img=18',
  ),
];