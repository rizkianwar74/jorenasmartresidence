// Helper seed data tagihan ke Firestore.
//
// Dua entry point utama:
//   SeedTagihan.run()                — seed manual (tombol admin)
//   SeedTagihan.autoSeedIfNeeded()   — dipanggil saat admin buka billing page;
//                                      cek Firestore apakah bulan ini sudah
//                                      di-seed, kalau belum jalankan otomatis.
//
// Membuat 1 tagihan aktif untuk setiap user (role: user/satpam)
// di collection 'tagihan', periode bulan berjalan.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/pembayaran/data/payment_repository.dart';

class SeedTagihan {
  SeedTagihan._();

  /// Jalankan seed. Aman di-call berulang — skip user yang sudah punya
  /// tagihan periode ini.
  static Future<int> run({
    int jumlah = PaymentRepository.iuranBulanan,
    String jatuhTempo = '30 bulan ini',
  }) async {
    final db = FirebaseFirestore.instance;

    // Ambil semua user.
    final usersSnap = await db.collection('users').get();
    if (usersSnap.docs.isEmpty) {
      // ignore: avoid_print
      print('[Seed] Tidak ada user di Firestore.');
      return 0;
    }

    final now = DateTime.now();
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    const monthsShort = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final bulan = months[now.month - 1];
    final tahun = now.year;
    final jatuhTempoStr = '30 ${monthsShort[now.month - 1]} $tahun';

    int created = 0;
    for (final doc in usersSnap.docs) {
      final data = doc.data();
      final role = data['role'] as String? ?? 'user';

      // Hanya warga (role: user) yang ditagih iuran.
      if (role != 'user') continue;

      final uid = doc.id;
      final nama = (data['namaLengkap'] as String?)?.isNotEmpty == true
          ? data['namaLengkap'] as String
          : (data['username'] as String? ?? 'Warga');
      final blok = (data['blok'] as String?) ?? 'Blok A';
      final nomorUnit = (data['nomorUnit'] as String?) ?? '01';
      final nomorHp = (data['nomorHp'] as String?) ?? '6281234567890';

      final tagihanId = 'tagihan-$tahun-${now.month.toString().padLeft(2, '0')}-$uid';

      // Skip bila sudah ada.
      final existing = await db.collection('tagihan').doc(tagihanId).get();
      if (existing.exists) continue;

      await PaymentRepository.createTagihan(
        id: tagihanId,
        userId: uid,
        namaResiden: nama,
        nomorHp: nomorHp,
        blok: blok,
        nomorUnit: nomorUnit,
        bulan: bulan,
        bulanIndex: now.month,
        tahun: tahun,
        jumlah: jumlah,
        jatuhTempo: jatuhTempoStr,
      );
      created++;
    }

    // ignore: avoid_print
    print('[Seed] Selesai. $created tagihan dibuat.');
    return created;
  }

  /// Auto-seed bulanan tanpa interaksi admin.
  ///
  /// Dipanggil tiap kali admin membuka halaman Billing. Logika:
  /// - Baca doc `config/tagihan_seed` di Firestore.
  /// - Kalau `lastSeededYear` == tahun ini DAN `lastSeededMonth` == bulan ini
  ///   → sudah di-seed bulan ini, tidak lakukan apa-apa.
  /// - Kalau belum → panggil run() → update `config/tagihan_seed`.
  ///
  /// Dengan cara ini seed hanya jalan sekali per bulan (saat admin pertama
  /// kali buka billing), tanpa perlu Cloud Functions.
  static Future<void> autoSeedIfNeeded() async {
    final db = FirebaseFirestore.instance;
    final now = DateTime.now();

    final configRef = db.collection('config').doc('tagihan_seed');
    final configSnap = await configRef.get();

    if (configSnap.exists) {
      final data = configSnap.data()!;
      final lastYear  = data['lastSeededYear']  as int? ?? 0;
      final lastMonth = data['lastSeededMonth'] as int? ?? 0;
      if (lastYear == now.year && lastMonth == now.month) return; // sudah
    }

    // Belum di-seed bulan ini — jalankan
    await run();
    await configRef.set({
      'lastSeededYear' : now.year,
      'lastSeededMonth': now.month,
      'lastSeededAt'   : FieldValue.serverTimestamp(),
    });
  }

  /// Hapus SEMUA tagihan (dev reset).
  static Future<int> clearAll() async {
    final db = FirebaseFirestore.instance;
    final snap = await db.collection('tagihan').get();
    int n = 0;
    for (final doc in snap.docs) {
      await doc.reference.delete();
      n++;
    }
    // ignore: avoid_print
    print('[Seed] $n tagihan dihapus.');
    return n;
  }
}
