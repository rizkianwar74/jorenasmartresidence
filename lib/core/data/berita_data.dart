// Dummy database berita komunitas
// Ganti dengan API call saat production

enum KategoriBerita { keamanan, fasilitas, kegiatan, kehilangan, pengumuman }

class BeritaModel {
  const BeritaModel({
    required this.id,
    required this.judul,
    required this.isi,
    required this.ringkasan,
    required this.imageUrl,
    required this.kategori,
    required this.tanggal,
    required this.penulis,
  });

  final String id;
  final String judul;
  final String isi;           // konten lengkap artikel
  final String ringkasan;     // preview singkat di kartu
  final String imageUrl;
  final KategoriBerita kategori;
  final String tanggal;
  final String penulis;

  String get kategoriLabel => switch (kategori) {
        KategoriBerita.keamanan    => 'Keamanan',
        KategoriBerita.fasilitas   => 'Fasilitas',
        KategoriBerita.kegiatan    => 'Kegiatan',
        KategoriBerita.kehilangan  => 'Kehilangan',
        KategoriBerita.pengumuman  => 'Pengumuman',
      };
}

const List<BeritaModel> dummyBeritaList = [
  // ── Keamanan ──────────────────────────────────────────────────────────────
  BeritaModel(
    id: 'berita-001',
    judul: 'Penangkapan Pelaku Pencurian di Blok C',
    ringkasan:
        'Satpam kompleks berhasil menangkap seorang pelaku pencurian motor di area parkir Blok C pada Selasa malam.',
    isi:
        'Pada Selasa malam, 10 Oktober 2023, sekitar pukul 22.30 WIB, tim keamanan kompleks berhasil '
        'menggagalkan aksi pencurian kendaraan bermotor di area parkir Blok C. Pelaku berinisial RA (28) '
        'berhasil diamankan setelah sempat berusaha melarikan diri.\n\n'
        'Kejadian bermula saat petugas CCTV mendeteksi aktivitas mencurigakan di area parkir. '
        'Satpam yang berjaga segera bergerak dan berhasil mengamankan pelaku beserta barang bukti berupa '
        'kunci T dan kawat yang biasa digunakan untuk membobol kunci motor.\n\n'
        'Pelaku kemudian diserahkan kepada pihak kepolisian Polsek setempat untuk diproses lebih lanjut. '
        'Manajemen kompleks menghimbau seluruh warga untuk tetap waspada dan segera melaporkan '
        'aktivitas mencurigakan kepada petugas keamanan.',
    imageUrl: 'https://picsum.photos/id/1074/800/400',
    kategori: KategoriBerita.keamanan,
    tanggal: '10 Okt 2023',
    penulis: 'Tim Keamanan',
  ),
  BeritaModel(
    id: 'berita-002',
    judul: 'Protokol Keamanan Baru Mulai Berlaku November',
    ringkasan:
        'Manajemen menerapkan sistem RFID terbaru untuk akses gerbang utama mulai 1 November 2023.',
    isi:
        'Dalam upaya meningkatkan keamanan lingkungan hunian, manajemen kompleks akan menerapkan '
        'sistem akses gerbang berbasis RFID (Radio Frequency Identification) terbaru mulai '
        '1 November 2023.\n\n'
        'Setiap penghuni wajib melakukan registrasi ulang kartu akses di kantor manajemen lantai GF '
        'paling lambat 31 Oktober 2023. Kartu akses lama akan dinonaktifkan secara otomatis '
        'setelah tanggal tersebut.\n\n'
        'Untuk tamu, tersedia fitur izin tamu digital melalui aplikasi Smart Residence. '
        'Penghuni dapat memberikan akses sementara kepada tamu tanpa perlu datang ke pos keamanan.\n\n'
        'Informasi lebih lanjut dapat diperoleh di kantor manajemen setiap hari kerja pukul 08.00–17.00.',
    imageUrl: 'https://picsum.photos/id/250/800/400',
    kategori: KategoriBerita.keamanan,
    tanggal: '15 Okt 2023',
    penulis: 'Manajemen',
  ),

  // ── Fasilitas ─────────────────────────────────────────────────────────────
  BeritaModel(
    id: 'berita-003',
    judul: 'Renovasi Clubhouse Selesai, Siap Digunakan',
    ringkasan:
        'Proses renovasi clubhouse telah selesai. Warga dapat kembali menikmati fasilitas kolam renang, gym, dan ruang serbaguna.',
    isi:
        'Kabar baik bagi seluruh warga! Proses renovasi clubhouse yang berlangsung selama 3 bulan '
        'akhirnya telah selesai dan siap digunakan kembali mulai 20 Oktober 2023.\n\n'
        'Fasilitas yang telah diperbarui antara lain:\n'
        '• Kolam renang dengan sistem filtrasi terbaru\n'
        '• Ruang gym dengan peralatan fitness terkini\n'
        '• Ruang serbaguna berkapasitas 100 orang\n'
        '• Kafe dan area santai outdoor\n'
        '• Toilet dan ruang ganti yang lebih luas\n\n'
        'Jam operasional clubhouse adalah Senin–Jumat pukul 06.00–22.00, '
        'dan Sabtu–Minggu pukul 06.00–23.00. Untuk booking ruang serbaguna, '
        'warga dapat menggunakan fitur Booking Fasilitas di aplikasi Smart Residence.',
    imageUrl: 'https://picsum.photos/id/1040/800/400',
    kategori: KategoriBerita.fasilitas,
    tanggal: '18 Okt 2023',
    penulis: 'Manajemen',
  ),
  BeritaModel(
    id: 'berita-004',
    judul: 'Perawatan Lift Blok A & B Jadwal 25 Oktober',
    ringkasan:
        'Lift di Blok A dan B akan menjalani perawatan rutin pada 25 Oktober 2023 pukul 08.00–12.00.',
    isi:
        'Diberitahukan kepada seluruh warga Blok A dan Blok B bahwa akan dilaksanakan '
        'perawatan rutin lift pada:\n\n'
        'Tanggal : 25 Oktober 2023\n'
        'Pukul   : 08.00 – 12.00 WIB\n'
        'Lokasi  : Blok A (Lift 1 & 2) dan Blok B (Lift 1)\n\n'
        'Selama proses perawatan berlangsung, lift tidak dapat digunakan. '
        'Warga diharapkan menggunakan tangga darurat yang tersedia di setiap blok.\n\n'
        'Perawatan ini dilakukan untuk memastikan keselamatan dan kenyamanan seluruh penghuni. '
        'Mohon maaf atas ketidaknyamanan yang ditimbulkan.',
    imageUrl: 'https://picsum.photos/id/1048/800/400',
    kategori: KategoriBerita.fasilitas,
    tanggal: '20 Okt 2023',
    penulis: 'Manajemen Teknis',
  ),

  // ── Kegiatan ──────────────────────────────────────────────────────────────
  BeritaModel(
    id: 'berita-005',
    judul: 'Sesi Yoga Pagi Setiap Sabtu di Taman Utama',
    ringkasan:
        'Komunitas warga mengadakan sesi yoga pagi gratis setiap Sabtu pukul 06.30 di taman utama.',
    isi:
        'Komunitas warga Jorena Residence dengan bangga mengumumkan program Yoga Pagi Bersama '
        'yang akan diadakan secara rutin setiap Sabtu pagi.\n\n'
        'Detail kegiatan:\n'
        '• Waktu  : Setiap Sabtu, pukul 06.30–07.30 WIB\n'
        '• Lokasi : Taman Utama dekat Gerbang B\n'
        '• Biaya  : Gratis untuk semua warga\n'
        '• Instruktur: Kak Dinda (bersertifikasi internasional)\n\n'
        'Peserta diharapkan membawa matras sendiri dan mengenakan pakaian olahraga yang nyaman. '
        'Untuk informasi lebih lanjut, hubungi panitia di grup WhatsApp komunitas warga.',
    imageUrl: 'https://picsum.photos/id/200/800/400',
    kategori: KategoriBerita.kegiatan,
    tanggal: '14 Okt 2023',
    penulis: 'Komunitas Warga',
  ),
  BeritaModel(
    id: 'berita-006',
    judul: 'Lomba 17 Agustus: Pendaftaran Dibuka',
    ringkasan:
        'Panitia HUT RI ke-79 membuka pendaftaran untuk berbagai lomba. Hadiah total jutaan rupiah.',
    isi:
        'Dalam rangka memperingati HUT Kemerdekaan RI ke-79, panitia kompleks membuka '
        'pendaftaran lomba untuk seluruh warga dan keluarga.\n\n'
        'Daftar lomba:\n'
        '• Lomba makan kerupuk (semua usia)\n'
        '• Balap karung (anak-anak & dewasa)\n'
        '• Tarik tambang (per blok)\n'
        '• Voli antar blok\n'
        '• Memasak ibu-ibu\n\n'
        'Total hadiah: Rp 5.000.000,-\n\n'
        'Pendaftaran: 1–10 Agustus 2024 di kantor manajemen atau via aplikasi.\n'
        'Pelaksanaan: 17 Agustus 2024 pukul 07.00 WIB di lapangan utama.',
    imageUrl: 'https://picsum.photos/id/447/800/400',
    kategori: KategoriBerita.kegiatan,
    tanggal: '01 Agt 2024',
    penulis: 'Panitia HUT RI',
  ),

  // ── Kehilangan ────────────────────────────────────────────────────────────
  BeritaModel(
    id: 'berita-007',
    judul: 'Kucing Pak Owi Hilang, Mohon Bantuannya',
    ringkasan:
        'Kucing ras Persia bernama Mochi milik Pak Owi (Blok A-15) hilang sejak Kamis malam.',
    isi:
        'Kepada warga yang terhormat,\n\n'
        'Bapak Owi Susanto dari Blok A No. 15 melaporkan bahwa kucing peliharaannya '
        'bernama Mochi hilang sejak Kamis, 12 Oktober 2023 malam.\n\n'
        'Ciri-ciri kucing:\n'
        '• Ras   : Persia\n'
        '• Warna : Putih dengan bercak oranye\n'
        '• Mata  : Biru\n'
        '• Berat : ±4 kg\n'
        '• Memakai kalung merah dengan lonceng\n\n'
        'Bagi yang menemukan atau melihat keberadaan Mochi, mohon segera '
        'hubungi Pak Owi di nomor 0812-XXXX-XXXX atau langsung ke unit Blok A-15.\n\n'
        'Akan diberikan hadiah bagi yang berhasil menemukan. Terima kasih.',
    imageUrl: 'https://picsum.photos/id/1062/800/400',
    kategori: KategoriBerita.kehilangan,
    tanggal: '14 Okt 2023',
    penulis: 'Owi Susanto',
  ),

  // ── Pengumuman ────────────────────────────────────────────────────────────
  BeritaModel(
    id: 'berita-008',
    judul: 'Kenaikan Iuran Bulanan Mulai Januari 2024',
    ringkasan:
        'Manajemen mengumumkan penyesuaian iuran bulanan sebesar 10% mulai Januari 2024 untuk peningkatan layanan.',
    isi:
        'Kepada Yth. Seluruh Warga Jorena Residence,\n\n'
        'Dengan hormat, manajemen kompleks menyampaikan informasi penyesuaian '
        'iuran bulanan yang akan berlaku mulai 1 Januari 2024.\n\n'
        'Besaran penyesuaian: 10% dari iuran saat ini\n\n'
        'Iuran baru per kategori:\n'
        '• Tipe Studio  : Rp 350.000/bulan\n'
        '• Tipe 1BR     : Rp 450.000/bulan\n'
        '• Tipe 2BR     : Rp 600.000/bulan\n'
        '• Tipe 3BR     : Rp 750.000/bulan\n\n'
        'Penyesuaian ini digunakan untuk peningkatan kualitas keamanan 24 jam, '
        'pemeliharaan fasilitas, dan peningkatan layanan kebersihan.\n\n'
        'Informasi lebih lanjut dapat ditanyakan ke kantor manajemen. Terima kasih atas pengertiannya.',
    imageUrl: 'https://picsum.photos/id/453/800/400',
    kategori: KategoriBerita.pengumuman,
    tanggal: '01 Nov 2023',
    penulis: 'Manajemen',
  ),
];

/// Filter berita berdasarkan kategori
List<BeritaModel> getBeritaByKategori(KategoriBerita kategori) =>
    dummyBeritaList.where((b) => b.kategori == kategori).toList();

/// Ambil N berita terbaru untuk ditampilkan di carousel homepage
List<BeritaModel> getBeritaTerbaru({int limit = 3}) =>
    dummyBeritaList.take(limit).toList();