import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';

/// Wrapper terpusat untuk SEMUA interaksi dengan OneSignal SDK.
///
/// Mengikuti panduan integrasi OneSignal: tidak boleh ada pemanggilan
/// `OneSignal.*` langsung di luar kelas ini. Tujuannya agar mudah diuji dan
/// diubah saat versi SDK naik. Konsisten dengan pola service lain di
/// `core/services/` (mis. SosNotificationService).
class OneSignalService {
  OneSignalService._();

  static final OneSignalService instance = OneSignalService._();

  /// App ID OneSignal — ini ID publik (aman ada di client), bukan REST API Key.
  static const String appId = 'a01a15ef-73d4-452a-b47e-6273ab20238c';

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

    // Minta izin notifikasi (WAJIB di Android 13+/iOS agar push tampil &
    // device berstatus opted-in / muncul di Subscriptions OneSignal).
    final granted = await OneSignal.Notifications.requestPermission(true);
    debugPrint('[OneSignal] permission granted=$granted '
        'subId=${OneSignal.User.pushSubscription.id} '
        'optedIn=${OneSignal.User.pushSubscription.optedIn}');

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

  // ── Kirim push pembayaran berhasil ke user ────────────────────────────────
  /// Notifikasi ke pemilik tagihan (targeted by External ID = Firebase UID).
  Future<void> sendPaymentSuccess({
    required String userId,
    required String periode,
    required String jumlah,
  }) async {
    if (kIsWeb) return;
    final restKey = dotenv.maybeGet('ONESIGNAL_REST_API_KEY') ?? '';
    if (restKey.isEmpty) {
      debugPrint(
          '[OneSignal] ONESIGNAL_REST_API_KEY kosong — push payment dilewati');
      return;
    }
    try {
      final payload = {
        'app_id'   : appId,
        'headings' : {'en': '✅ Pembayaran Berhasil!', 'id': '✅ Pembayaran Berhasil!'},
        'contents' : {
          'en': 'Iuran $periode sebesar $jumlah telah dikonfirmasi.',
          'id': 'Iuran $periode sebesar $jumlah telah dikonfirmasi.',
        },
        // Targetkan device berdasarkan External ID (Firebase UID).
        'include_aliases' : {'external_id': [userId]},
        'target_channel'  : 'push',
      };
      final res = await http.post(
        Uri.parse('https://api.onesignal.com/notifications'),
        headers: {
          'Content-Type' : 'application/json; charset=UTF-8',
          'Accept'       : 'application/json',
          'Authorization': 'Key $restKey',
        },
        body: jsonEncode(payload),
      );
      if (res.statusCode != 200 && res.statusCode != 201) {
        debugPrint(
            '[OneSignal] sendPaymentSuccess gagal ${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      debugPrint('[OneSignal] sendPaymentSuccess error: $e');
    }
  }

  // ── Kirim push update patroli ke SEMUA WARGA ─────────────────────────────
  /// Broadcast ke semua device ber-tag role=warga.
  /// [mulai] true = patroli dimulai, false = patroli selesai.
  Future<void> sendPatroliUpdate({
    required bool   mulai,
    required String blok,
    required String namaSatpam,
  }) async {
    if (kIsWeb) return;
    final title = mulai
        ? '🛡️ Patroli Dimulai'
        : '✅ Patroli Selesai';
    final body  = mulai
        ? '$namaSatpam sedang melakukan patroli di $blok.'
        : '$namaSatpam telah menyelesaikan patroli di $blok.';
    await _sendToWarga(title: title, body: body);
  }

  // ── Kirim push update bantuan ke USER yang meminta ────────────────────────
  /// Targeted ke satu user berdasarkan External ID (Firebase UID).
  Future<void> sendBantuanUpdate({
    required String userId,
    required bool   onMyWay, // true = menuju lokasi, false = selesai
    required String namaSatpam,
  }) async {
    if (kIsWeb) return;
    final restKey = dotenv.maybeGet('ONESIGNAL_REST_API_KEY') ?? '';
    if (restKey.isEmpty) {
      debugPrint('[OneSignal] ONESIGNAL_REST_API_KEY kosong — push bantuan dilewati');
      return;
    }
    final title = onMyWay ? '🚶 Satpam Menuju Lokasi' : '✅ Bantuan Selesai';
    final body  = onMyWay
        ? '$namaSatpam sedang dalam perjalanan menuju lokasi Anda.'
        : '$namaSatpam telah menyelesaikan permintaan bantuan Anda.';
    try {
      final payload = {
        'app_id'          : appId,
        'headings'        : {'en': title, 'id': title},
        'contents'        : {'en': body,  'id': body},
        'include_aliases' : {'external_id': [userId]},
        'target_channel'  : 'push',
      };
      final res = await http.post(
        Uri.parse('https://api.onesignal.com/notifications'),
        headers: {
          'Content-Type' : 'application/json; charset=UTF-8',
          'Accept'       : 'application/json',
          'Authorization': 'Key $restKey',
        },
        body: jsonEncode(payload),
      );
      if (res.statusCode != 200 && res.statusCode != 201) {
        debugPrint('[OneSignal] sendBantuanUpdate gagal ${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      debugPrint('[OneSignal] sendBantuanUpdate error: $e');
    }
  }

  /// Broadcast ke semua device dengan tag role=warga.
  Future<void> _sendToWarga({
    required String title,
    required String body,
  }) async {
    final restKey = dotenv.maybeGet('ONESIGNAL_REST_API_KEY') ?? '';
    if (restKey.isEmpty) {
      debugPrint('[OneSignal] ONESIGNAL_REST_API_KEY kosong — push warga dilewati');
      return;
    }
    try {
      final payload = {
        'app_id'   : appId,
        'headings' : {'en': title, 'id': title},
        'contents' : {'en': body,  'id': body},
        'filters'  : [
          {'field': 'tag', 'key': 'role', 'relation': '=', 'value': 'user'},
        ],
      };
      final res = await http.post(
        Uri.parse('https://api.onesignal.com/notifications'),
        headers: {
          'Content-Type' : 'application/json; charset=UTF-8',
          'Accept'       : 'application/json',
          'Authorization': 'Key $restKey',
        },
        body: jsonEncode(payload),
      );
      if (res.statusCode != 200 && res.statusCode != 201) {
        debugPrint('[OneSignal] _sendToWarga gagal ${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      debugPrint('[OneSignal] _sendToWarga error: $e');
    }
  }

  // ── Kirim push update keluhan ke USER pemilik keluhan ────────────────────
  /// [statusLabel] mis. "Sedang Diproses", "Selesai", "Ditolak".
  Future<void> sendKeluhanUpdate({
    required String userId,
    required String statusLabel,
    required String judulKeluhan,
  }) async {
    if (kIsWeb) return;
    final restKey = dotenv.maybeGet('ONESIGNAL_REST_API_KEY') ?? '';
    if (restKey.isEmpty) return;
    final title = '📋 Update Keluhan';
    final body  = 'Keluhan "$judulKeluhan" kini berstatus: $statusLabel.';
    try {
      final payload = {
        'app_id'          : appId,
        'headings'        : {'en': title, 'id': title},
        'contents'        : {'en': body,  'id': body},
        'include_aliases' : {'external_id': [userId]},
        'target_channel'  : 'push',
      };
      final res = await http.post(
        Uri.parse('https://api.onesignal.com/notifications'),
        headers: {
          'Content-Type' : 'application/json; charset=UTF-8',
          'Accept'       : 'application/json',
          'Authorization': 'Key $restKey',
        },
        body: jsonEncode(payload),
      );
      if (res.statusCode != 200 && res.statusCode != 201) {
        debugPrint('[OneSignal] sendKeluhanUpdate gagal ${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      debugPrint('[OneSignal] sendKeluhanUpdate error: $e');
    }
  }

  // ── Kirim push berita baru ke SEMUA WARGA ────────────────────────────────
  Future<void> sendBeritaBaru({required String judul}) async {
    if (kIsWeb) return;
    const title = '📰 Pengumuman Baru';
    final body  = judul;
    await _sendToWarga(title: title, body: body);
  }

  // ── Kirim push SOS direspon ke USER pemilik SOS ───────────────────────────
  Future<void> sendSosUpdate({
    required String userId,
    required bool   onMyWay, // true = menuju, false = selesai
    required String namaSatpam,
  }) async {
    if (kIsWeb) return;
    final restKey = dotenv.maybeGet('ONESIGNAL_REST_API_KEY') ?? '';
    if (restKey.isEmpty) return;
    final title = onMyWay ? '🚨 Satpam Menuju Lokasi' : '✅ SOS Selesai Ditangani';
    final body  = onMyWay
        ? '$namaSatpam sedang dalam perjalanan menuju lokasi Anda.'
        : '$namaSatpam telah menyelesaikan penanganan SOS Anda.';
    try {
      final payload = {
        'app_id'          : appId,
        'headings'        : {'en': title, 'id': title},
        'contents'        : {'en': body,  'id': body},
        'include_aliases' : {'external_id': [userId]},
        'target_channel'  : 'push',
      };
      final res = await http.post(
        Uri.parse('https://api.onesignal.com/notifications'),
        headers: {
          'Content-Type' : 'application/json; charset=UTF-8',
          'Accept'       : 'application/json',
          'Authorization': 'Key $restKey',
        },
        body: jsonEncode(payload),
      );
      if (res.statusCode != 200 && res.statusCode != 201) {
        debugPrint('[OneSignal] sendSosUpdate gagal ${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      debugPrint('[OneSignal] sendSosUpdate error: $e');
    }
  }

  // ── Kirim push bantuan baru ke satpam ON DUTY ────────────────────────────
  Future<void> sendBantuanBaruToSatpam({
    required String namaWarga,
    required String blok,
    required String nomorUnit,
    required String kategori,
  }) async {
    await _notifyOnDutySatpam(
      title  : '🆘 Permintaan Bantuan Baru',
      message: '$namaWarga (Blok $blok No. $nomorUnit) meminta bantuan: $kategori.',
    );
  }

  // ── Kirim push keluhan baru ke satpam ON DUTY ─────────────────────────────
  Future<void> sendKeluhanBaruToSatpam({
    required String namaWarga,
    required String judul,
    required String kategori,
  }) async {
    await _notifyOnDutySatpam(
      title  : '📋 Keluhan Baru Masuk',
      message: '$namaWarga melaporkan keluhan [$kategori]: "$judul".',
    );
  }

  // ── Kirim push keluhan di-assign ke satpam TERTENTU ───────────────────────
  Future<void> sendKeluhanAssigned({
    required String satpamUid,
    required String namaWarga,
    required String judul,
  }) async {
    if (kIsWeb) return;
    final restKey = dotenv.maybeGet('ONESIGNAL_REST_API_KEY') ?? '';
    if (restKey.isEmpty) return;
    const title = '📌 Keluhan Ditugaskan ke Anda';
    final body  = 'Keluhan dari $namaWarga: "$judul" telah ditugaskan kepada Anda.';
    try {
      final payload = {
        'app_id'          : appId,
        'headings'        : {'en': title, 'id': title},
        'contents'        : {'en': body,  'id': body},
        'include_aliases' : {'external_id': [satpamUid]},
        'target_channel'  : 'push',
      };
      final res = await http.post(
        Uri.parse('https://api.onesignal.com/notifications'),
        headers: {
          'Content-Type' : 'application/json; charset=UTF-8',
          'Accept'       : 'application/json',
          'Authorization': 'Key $restKey',
        },
        body: jsonEncode(payload),
      );
      if (res.statusCode != 200 && res.statusCode != 201) {
        debugPrint('[OneSignal] sendKeluhanAssigned gagal ${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      debugPrint('[OneSignal] sendKeluhanAssigned error: $e');
    }
  }

  // ── Kirim push SOS/Panggilan ke satpam yang sedang BERTUGAS ───────────────
  // Target: device dengan tag role=satpam AND onDuty=true. Push tetap sampai
  // walau app satpam tertutup. REST API Key dibaca dari .env (tidak hardcode).
  Future<void> sendSosToOnDutySatpam({
    required bool isSos,
    required String namaWarga,
    required String blok,
    required String nomorUnit,
  }) async {
    final title = isSos ? '🚨 SOS DARURAT!' : '📢 Panggilan Satpam';
    final message = isSos
        ? '$namaWarga butuh bantuan darurat — Blok $blok No. $nomorUnit'
        : '$namaWarga memanggil satpam — Blok $blok No. $nomorUnit';
    await _notifyOnDutySatpam(title: title, message: message);
  }

  Future<void> _notifyOnDutySatpam({
    required String title,
    required String message,
  }) async {
    if (kIsWeb) return;
    final restKey = dotenv.maybeGet('ONESIGNAL_REST_API_KEY') ?? '';
    if (restKey.isEmpty) {
      debugPrint('[OneSignal] ONESIGNAL_REST_API_KEY kosong di .env — push dilewati');
      return;
    }
    try {
      final payload = {
        'app_id': appId,
        'headings': {'en': title},
        'contents': {'en': message},
        'priority': 10,
        // Hanya kirim ke satpam yang sedang bertugas.
        'filters': [
          {'field': 'tag', 'key': 'role', 'relation': '=', 'value': 'satpam'},
          {'operator': 'AND'},
          {'field': 'tag', 'key': 'onDuty', 'relation': '=', 'value': 'true'},
        ],
      };
      final res = await http.post(
        Uri.parse('https://api.onesignal.com/notifications'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
          'Authorization': 'Key $restKey',
        },
        body: jsonEncode(payload),
      );
      if (res.statusCode != 200 && res.statusCode != 201) {
        debugPrint('[OneSignal] kirim gagal ${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      debugPrint('[OneSignal] kirim error: $e');
    }
  }
}
