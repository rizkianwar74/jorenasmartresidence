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
          'Authorization': 'Basic $restKey',
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
          // REST API Key klasik memakai skema 'Basic'. Jika kamu memakai key
          // gaya baru OneSignal, ganti 'Basic' menjadi 'Key'.
          'Authorization': 'Basic $restKey',
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
