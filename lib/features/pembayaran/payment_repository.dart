// Repository untuk operasi Firestore collection 'tagihan'.
// Mengikuti pola static-method seperti AuthRepository.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'tagihan_model.dart';

class PaymentRepository {
  PaymentRepository._();

  static final _db = FirebaseFirestore.instance;
  static const _collection = 'tagihan';

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

  /// Update status pembayaran setelah transaksi Midtrans.
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

  /// Set orderId Midtrans pada tagihan (sebelum buka Snap).
  static Future<void> setOrderId({
    required String tagihanId,
    required String orderId,
  }) async {
    await _db.collection(_collection).doc(tagihanId).update({
      'orderId': orderId,
    });
  }

  /// Buat dokumen tagihan baru (dipakai admin / seed).
  static Future<void> createTagihan({
    required String id,
    required String userId,
    required String namaResiden,
    required String nomorHp,
    required String blok,
    required String nomorUnit,
    required String bulan,
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

  /// Format tanggal hari ini (dd MMM yyyy) untuk tanggalBayar.
  static String _formatToday() {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final now = DateTime.now();
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }
}
