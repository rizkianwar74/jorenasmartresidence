// Repository untuk operasi Firestore collection 'tagihan'.
// Mengikuti pola static-method seperti AuthRepository.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tagihan_model.dart';

class PaymentRepository {
  PaymentRepository._();

  static final _db = FirebaseFirestore.instance;
  static const _collection = 'tagihan';

  /// Iuran bulanan default (Rp 30.000/rumah).
  static const int iuranBulanan = 30000;

  /// Stream tagihan milik satu user (untuk halaman Tagihan user).
  static Stream<List<TagihanModel>> watchUserTagihan(String userId) {
    return _db
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => TagihanModel.fromMap(d.id, d.data()))
            .toList());
  }

  /// Stream SEMUA tagihan (untuk halaman Billing admin).
  static Stream<List<TagihanModel>> watchAllTagihan() {
    return _db
        .collection(_collection)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => TagihanModel.fromMap(d.id, d.data()))
            .toList());
  }

  /// Ambil satu tagihan by id (one-shot).
  static Future<TagihanModel?> getTagihan(String id) async {
    final doc = await _db.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return TagihanModel.fromMap(doc.id, doc.data()!);
  }

  /// Update status pembayaran satu tagihan setelah transaksi Midtrans.
  static Future<void> updatePaymentStatus({
    required String tagihanId,
    required StatusTagihan status,
    String? metodeBayar,
    String? orderId,
  }) async {
    final data = <String, dynamic>{
      'status': statusTagihanToString(status),
    };
    if (status == StatusTagihan.lunas) {
      data['tanggalBayar'] = _formatToday();
    }
    if (metodeBayar != null) data['metodeBayar'] = metodeBayar;
    if (orderId != null) data['orderId'] = orderId;

    await _db.collection(_collection).doc(tagihanId).update(data);
  }

  /// Update status tagihan secara manual oleh admin (mis. pembayaran tunai).
  ///
  /// - Ke `lunas`     : catat tanggalBayar = hari ini, metodeBayar = 'Tunai (Manual)'
  /// - Ke `belumBayar`: hapus tanggalBayar, metodeBayar, orderId
  static Future<void> setStatusManual({
    required String tagihanId,
    required StatusTagihan status,
  }) async {
    final data = <String, dynamic>{
      'status': statusTagihanToString(status),
    };
    if (status == StatusTagihan.lunas) {
      data['tanggalBayar'] = _formatToday();
      data['metodeBayar']  = 'Tunai (Manual)';
    } else {
      data['tanggalBayar'] = null;
      data['metodeBayar']  = null;
      data['orderId']      = null;
    }
    await _db.collection(_collection).doc(tagihanId).update(data);
  }

  /// Tandai BANYAK tagihan sekaligus jadi lunas dalam satu batch — dipakai
  /// saat user membayar total tunggakan (beberapa bulan) lewat satu
  /// transaksi Midtrans.
  static Future<void> markManyAsLunas({
    required List<String> tagihanIds,
    String? metodeBayar,
    String? orderId,
  }) async {
    if (tagihanIds.isEmpty) return;
    final batch = _db.batch();
    final tanggalBayar = _formatToday();
    for (final id in tagihanIds) {
      final data = <String, dynamic>{
        'status': statusTagihanToString(StatusTagihan.lunas),
        'tanggalBayar': tanggalBayar,
      };
      if (metodeBayar != null) data['metodeBayar'] = metodeBayar;
      if (orderId != null) data['orderId'] = orderId;
      batch.update(_db.collection(_collection).doc(id), data);
    }
    await batch.commit();
  }

  /// Set orderId Midtrans pada satu tagihan (sebelum buka Snap).
  static Future<void> setOrderId({
    required String tagihanId,
    required String orderId,
  }) async {
    await _db.collection(_collection).doc(tagihanId).update({
      'orderId': orderId,
    });
  }

  /// Set orderId Midtrans yang SAMA ke banyak tagihan sekaligus — dipakai
  /// saat satu transaksi melunasi beberapa bulan tunggakan.
  static Future<void> setOrderIdForMany({
    required List<String> tagihanIds,
    required String orderId,
  }) async {
    if (tagihanIds.isEmpty) return;
    final batch = _db.batch();
    for (final id in tagihanIds) {
      batch.update(_db.collection(_collection).doc(id), {'orderId': orderId});
    }
    await batch.commit();
  }

  /// Buat dokumen tagihan baru (dipakai admin / seed / auto-generate bulanan).
  static Future<void> createTagihan({
    required String id,
    required String userId,
    required String namaResiden,
    required String nomorHp,
    required String blok,
    required String nomorUnit,
    required String bulan,
    required int bulanIndex,
    required int tahun,
    required int jumlah,
    required String jatuhTempo,
    StatusTagihan status = StatusTagihan.belumBayar,
  }) async {
    await _db.collection(_collection).doc(id).set({
      'userId': userId,
      'namaResiden': namaResiden,
      'nomorHp': nomorHp,
      'blok': blok,
      'nomorUnit': nomorUnit,
      'bulan': bulan,
      'bulanIndex': bulanIndex,
      'tahun': tahun,
      'jumlah': jumlah,
      'jatuhTempo': jatuhTempo,
      'status': statusTagihanToString(status),
      'tanggalBayar': null,
      'metodeBayar': null,
      'orderId': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Pastikan tagihan BULAN INI sudah ada untuk satu user — dipanggil
  /// otomatis tiap kali user login/buka app. Aman dipanggil berulang kali:
  /// kalau dokumen bulan ini sudah ada, tidak melakukan apa-apa.
  ///
  /// Tagihan bulan sebelumnya yang belum lunas TIDAK disentuh/digabung di
  /// sini — tetap berdiri sebagai dokumen terpisah (supaya admin tahu persis
  /// tunggakan itu untuk bulan apa). Akumulasi "total tunggakan" dihitung
  /// di UI lewat TagihanListX.totalUnpaid, dan dilunaskan sekaligus saat
  /// user bayar (lihat markManyAsLunas).
  static Future<void> ensureCurrentMonthTagihan({
    required String userId,
    required String namaResiden,
    required String nomorHp,
    required String blok,
    required String nomorUnit,
    int jumlah = iuranBulanan,
  }) async {
    final now = DateTime.now();
    final bulan = bulanPanjangList[now.month - 1];
    final tahun = now.year;
    final id =
        'tagihan-$tahun-${now.month.toString().padLeft(2, '0')}-$userId';

    final existing = await _db.collection(_collection).doc(id).get();
    if (existing.exists) return;

    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    final jatuhTempo = '$lastDay ${bulanSingkatList[now.month - 1]} $tahun';

    await createTagihan(
      id: id,
      userId: userId,
      namaResiden: namaResiden,
      nomorHp: nomorHp,
      blok: blok,
      nomorUnit: nomorUnit,
      bulan: bulan,
      bulanIndex: now.month,
      tahun: tahun,
      jumlah: jumlah,
      jatuhTempo: jatuhTempo,
    );
  }

  /// Migrasi satu kali: update jumlah SEMUA tagihan yang BELUM lunas
  /// (belumBayar/jatuhTempo/pending) ke nilai iuran terbaru. Tagihan yang
  /// sudah lunas (riwayat) TIDAK diubah supaya histori pembayaran tetap
  /// akurat sesuai jumlah yang benar-benar dibayar waktu itu.
  ///
  /// Dipakai sekali oleh admin lewat tombol "Update ke Iuran Terbaru" setelah
  /// tarif iuran berubah — supaya tagihan lama yang sudah terbuat duluan
  /// (dengan tarif lama) ikut ter-update, bukan cuma tagihan yang baru dibuat.
  static Future<int> migrateUnpaidJumlah({int jumlah = iuranBulanan}) async {
    final snap = await _db
        .collection(_collection)
        .where('status', whereIn: ['belumBayar', 'jatuhTempo', 'pending'])
        .get();
    if (snap.docs.isEmpty) return 0;

    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'jumlah': jumlah});
    }
    await batch.commit();
    return snap.docs.length;
  }

  /// Format tanggal hari ini (dd MMM yyyy) untuk tanggalBayar.
  static String _formatToday() {
    final now = DateTime.now();
    return '${now.day} ${bulanSingkatList[now.month - 1]} ${now.year}';
  }
}
