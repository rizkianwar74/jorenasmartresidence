import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, debugPrint;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';

/// Wrapper terpusat untuk SEMUA interaksi dengan OneSignal.
///
/// Mengikuti panduan integrasi OneSignal: tidak boleh ada pemanggilan
/// `OneSignal.*` langsung di luar kelas ini. Tujuannya agar mudah diuji dan
/// diubah saat versi SDK naik. Konsisten dengan pola service lain di
/// `core/services/` (mis. SosNotificationService).
///
/// ── Perubahan arsitektur pengiriman notifikasi ──────────────────────────────
/// Dulu kelas ini memanggil REST API OneSignal LANGSUNG dari app, memakai
/// ONESIGNAL_REST_API_KEY yang dibaca dari .env. Karena .env didaftarkan
/// sebagai asset di pubspec.yaml, key tersebut ikut terkemas ke dalam APK dan
/// dapat dibaca siapa pun yang memiliki file aplikasi — persis kelas masalah
/// yang sama dengan PAKASIR_API_KEY sebelumnya.
///
/// Sekarang semua pengiriman notifikasi lewat server tepercaya di Vercel
/// (server/api/send-notification.ts). App hanya mengirim JENIS kejadian dan ID
/// DOKUMEN Firestore-nya; server yang membaca dokumen itu, memeriksa wewenang
/// pemanggil lewat Firebase ID Token, lalu menyusun sendiri isi pesan dan
/// daftar penerimanya. App tidak lagi memegang satu pun kredensial rahasia.
class OneSignalService {
  OneSignalService._();

  static final OneSignalService instance = OneSignalService._();

  /// App ID OneSignal — ID publik, aman ada di client. Bukan REST API Key.
  static const String appId = 'a01a15ef-73d4-452a-b47e-6273ab20238c';

  /// Endpoint notifikasi pada server tepercaya (Vercel).
  ///
  /// Bukan rahasia: URL ini toh terlihat di lalu lintas jaringan. Yang menjaga
  /// endpoint bukan kerahasiaan alamatnya, melainkan verifikasi Firebase ID
  /// Token dan pemeriksaan peran di sisi server.
  ///
  /// Perbarui bila nama project Vercel berubah.
  static const String notificationEndpoint =
      'https://jorenaapp.vercel.app/api/send-notification';

  /// Dipasang ke MaterialApp.navigatorKey agar dialog bisa ditampilkan dari
  /// luar widget tree (mis. dari observer push subscription).
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  bool _initialized = false;

  /// Inisialisasi SDK — panggil sekali di main(), setelah Firebase siap.
  Future<void> init() async {
    if (kIsWeb || _initialized) return;
    _initialized = true;

    // Log verbose hanya di debug build — silent di produksi.
    OneSignal.Debug.setLogLevel(
        kDebugMode ? OSLogLevel.verbose : OSLogLevel.none);
    OneSignal.initialize(appId);

    _setupPushSubscriptionObserver();

    // Minta izin notifikasi secara TIDAK MEMBLOKIR (fire-and-forget).
    // Sebelumnya: await requestPermission(true) — bisa hang di beberapa device
    // Android karena dialog izin tidak muncul atau sistem lambat merespons,
    // menyebabkan main() tidak pernah selesai → app stuck di splash.
    OneSignal.Notifications.requestPermission(true).then((granted) {
      debugPrint('[OneSignal] permission granted=$granted '
          'subId=${OneSignal.User.pushSubscription.id} '
          'optedIn=${OneSignal.User.pushSubscription.optedIn}');
    }).catchError((e) {
      debugPrint('[OneSignal] requestPermission error: $e');
    });

    // Registrasi FCM bersifat asinkron — cek ulang setelah beberapa detik.
    // token KOSONG = FCM masih gagal; token ADA = device siap menerima push.
    Future.delayed(const Duration(seconds: 8), () {
      final sub = OneSignal.User.pushSubscription;
      final tokenStatus = sub.token == null
          ? 'null'
          : (sub.token!.isEmpty ? 'KOSONG' : 'ADA(${sub.token!.length} char)');
      debugPrint('[OneSignal] (cek ulang 8s) subId=${sub.id} '
          'optedIn=${sub.optedIn} fcmToken=$tokenStatus');
    });
  }

  // ── Identitas pengguna ──────────────────────────────────────────────────
  /// Tautkan device ke ID pengguna app (mis. uid Firebase) agar bisa
  /// ditargetkan lewat External ID.
  Future<void> login(String externalId) async {
    if (kIsWeb) return;
    OneSignal.login(externalId);
  }

  Future<void> logout() async {
    if (kIsWeb) return;
    OneSignal.logout();
  }

  // ── Tag (mis. role=satpam, onDuty=true) untuk penargetan notifikasi ──────
  Future<void> setTag(String key, String value) async {
    if (kIsWeb) return;
    OneSignal.User.addTags({key: value});
  }

  Future<void> setTags(Map<String, String> tags) async {
    if (kIsWeb) return;
    OneSignal.User.addTags(tags);
  }

  Future<void> removeTag(String key) async {
    if (kIsWeb) return;
    OneSignal.User.removeTag(key);
  }

  // ── Izin notifikasi (Android 13+ / iOS) ──────────────────────────────────
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    return OneSignal.Notifications.requestPermission(true);
  }

  // ── Observer push subscription ────────────────────────────────────────────
  void _setupPushSubscriptionObserver() {
    OneSignal.User.pushSubscription.addObserver((state) {
      debugPrint('[OneSignal] pushSubscription berubah: '
          'previous=${state.previous.id} current=${state.current.id}');
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PENGIRIMAN NOTIFIKASI
  //
  // Semua method di bawah ini hanya meneruskan JENIS kejadian + ID DOKUMEN ke
  // server. Tidak ada judul, isi pesan, maupun daftar penerima yang disusun di
  // sini — semuanya jadi wewenang server.
  // ═══════════════════════════════════════════════════════════════════════════

  /// Kirim permintaan notifikasi ke server tepercaya.
  ///
  /// Sengaja tidak melempar exception: notifikasi bersifat pelengkap, sedangkan
  /// data utamanya sudah tersimpan di Firestore. Kegagalan cukup dicatat di log
  /// agar tidak pernah mengganggu alur yang sedang dijalankan pengguna.
  Future<void> _post(String type, String docId) async {
    if (kIsWeb) return;

    if (notificationEndpoint.contains('GANTI-DENGAN')) {
      debugPrint('[OneSignal] notificationEndpoint belum dikonfigurasi — '
          'push dilewati (type=$type)');
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('[OneSignal] belum login — push dilewati (type=$type)');
        return;
      }

      // ID Token membuktikan identitas pemanggil ke server. Server yang
      // memutuskan apakah pemanggil berwenang memicu jenis notifikasi ini,
      // berdasarkan peran yang dibaca dari Firestore (bukan dari app).
      final idToken = await user.getIdToken();

      final res = await http.post(
        Uri.parse(notificationEndpoint),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({'type': type, 'docId': docId}),
      );

      if (res.statusCode != 200) {
        debugPrint('[OneSignal] $type gagal ${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      debugPrint('[OneSignal] $type error: $e');
    }
  }

  // ── Warga → satpam yang sedang bertugas ───────────────────────────────────
  /// Panggilan SOS atau panggilan satpam biasa. Server membedakan keduanya
  /// dari field `type` pada dokumen `sosalert`.
  Future<void> sendSosBaru({required String docId}) =>
      _post('sos_baru', docId);

  /// Permintaan bantuan non-darurat baru (`bantuanrequest`).
  Future<void> sendBantuanBaru({required String docId}) =>
      _post('bantuan_baru', docId);

  /// Pengaduan baru masuk (`keluhan`).
  Future<void> sendKeluhanBaru({required String docId}) =>
      _post('keluhan_baru', docId);

  // ── Petugas → warga pemilik laporan ───────────────────────────────────────
  /// Perubahan status penanganan SOS. Server membaca status terkini dokumen
  /// untuk menentukan bunyi pesannya (menuju lokasi / selesai).
  Future<void> sendSosUpdate({required String docId}) =>
      _post('sos_update', docId);

  /// Perubahan status permintaan bantuan.
  Future<void> sendBantuanUpdate({required String docId}) =>
      _post('bantuan_update', docId);

  /// Perubahan status pengaduan.
  Future<void> sendKeluhanUpdate({required String docId}) =>
      _post('keluhan_update', docId);

  // ── Admin → satpam tertentu ───────────────────────────────────────────────
  /// Pengaduan ditugaskan ke satpam. Sasarannya dibaca server dari field
  /// `assignedTo` pada dokumen, bukan dikirim dari app.
  Future<void> sendKeluhanAssigned({required String docId}) =>
      _post('keluhan_assigned', docId);

  // ── Siaran ke seluruh warga ───────────────────────────────────────────────
  /// Berita/pengumuman baru dipublikasikan. Server melewati dokumen yang masih
  /// berstatus draft.
  Future<void> sendBeritaBaru({required String docId}) =>
      _post('berita_baru', docId);

  /// Patroli dimulai atau selesai. Server membedakannya dari status dokumen.
  Future<void> sendPatroliUpdate({required String docId}) =>
      _post('patroli_update', docId);

  // ── Catatan: notifikasi pembayaran ────────────────────────────────────────
  // sendPaymentSuccess() DIHAPUS dari sini. Notifikasi "pembayaran berhasil"
  // kini dipicu langsung oleh server webhook Pakasir setelah tagihan ditandai
  // lunas (server/api/pakasir-webhook.ts). Sebelumnya dipicu app setelah
  // pembayaran selesai — akibatnya warga tidak menerima notifikasi bila
  // menutup aplikasi lebih dulu, padahal tagihannya sudah lunas.
}
