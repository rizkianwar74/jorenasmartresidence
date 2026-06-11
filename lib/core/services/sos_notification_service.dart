import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'sos_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Channel ID constants
// ─────────────────────────────────────────────────────────────────────────────

const _kSosChannelId   = 'SOS_CHANNEL';
const _kCallChannelId  = 'CALL_CHANNEL';

const _kSosNotifId  = 1001;
const _kCallNotifId = 1002;

// ─────────────────────────────────────────────────────────────────────────────
// SosNotificationService
// ─────────────────────────────────────────────────────────────────────────────

class SosNotificationService {
  SosNotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // ── Inisialisasi — panggil sekali di main() ───────────────────────────────
  static Future<void> init() async {
    if (kIsWeb || _initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(initSettings);

    // Pola getar SOS: [delay, getar, jeda, getar, jeda, getar] dalam ms
    final sosVibration = Int64List.fromList([0, 500, 300, 500, 300, 500]);

    // Buat channel SOS: alarm + getar terus, prioritas MAX
    final sosChannel = AndroidNotificationChannel(
      _kSosChannelId,
      'SOS Darurat',
      description: 'Notifikasi darurat dari warga — membutuhkan respon segera',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      vibrationPattern: sosVibration,
      enableLights: true,
      ledColor: const Color(0xFFFF0000),
    );

    // Buat channel CALL: suara notif biasa, tanpa getar
    const callChannel = AndroidNotificationChannel(
      _kCallChannelId,
      'Panggil Satpam',
      description: 'Permintaan bantuan dari warga',
      importance: Importance.high,
      playSound: true,
      enableVibration: false,
    );

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(sosChannel);
    await androidPlugin?.createNotificationChannel(callChannel);

    // Minta permission notifikasi (Android 13+)
    await androidPlugin?.requestNotificationsPermission();

    _initialized = true;
  }

  // ── Tampilkan notifikasi SOS — alarm + getar terus ────────────────────────
  static Future<void> showSosNotification(SosAlert alert) async {
    if (kIsWeb) return;
    final vibration = Int64List.fromList([0, 500, 300, 500, 300, 500]);
    final androidDetails = AndroidNotificationDetails(
      _kSosChannelId,
      'SOS Darurat',
      channelDescription: 'Notifikasi darurat dari warga',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      vibrationPattern: vibration,
      // Full screen intent: muncul meski HP terkunci
      fullScreenIntent: true,
      ongoing: true, // tidak bisa di-dismiss sebelum ditangani
      autoCancel: false,
      color: const Color(0xFFD32F2F),
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(
        'Warga membutuhkan bantuan segera di Blok ${alert.blok} Unit ${alert.nomorUnit}',
        summaryText: 'Tap untuk merespons',
      ),
    );

    await _plugin.show(
      _kSosNotifId,
      '🚨 SOS DARURAT! ${alert.namaWarga}',
      'Blok ${alert.blok} – Unit ${alert.nomorUnit} | Tap untuk merespons',
      NotificationDetails(android: androidDetails),
    );
  }

  // ── Tampilkan notifikasi CALL — suara sekali, tanpa getar ─────────────────
  static Future<void> showCallNotification(SosAlert alert) async {
    if (kIsWeb) return;
    final androidDetails = AndroidNotificationDetails(
      _kCallChannelId,
      'Panggil Satpam',
      channelDescription: 'Permintaan bantuan dari warga',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: false,
      autoCancel: true,
      color: const Color(0xFF1E3A8A),
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(
        'Warga meminta bantuan di Blok ${alert.blok} Unit ${alert.nomorUnit}',
        summaryText: 'Tap untuk merespons',
      ),
    );

    await _plugin.show(
      _kCallNotifId,
      '📢 Panggilan dari ${alert.namaWarga}',
      'Blok ${alert.blok} – Unit ${alert.nomorUnit}',
      NotificationDetails(android: androidDetails),
    );
  }

  // ── Batalkan notifikasi SOS (setelah direspons) ───────────────────────────
  static Future<void> cancelSosNotification() async {
    if (kIsWeb) return;
    await _plugin.cancel(_kSosNotifId);
  }

  // ── Batalkan notifikasi CALL ──────────────────────────────────────────────
  static Future<void> cancelCallNotification() async {
    if (kIsWeb) return;
    await _plugin.cancel(_kCallNotifId);
  }

  // ── Batalkan semua notifikasi ─────────────────────────────────────────────
  static Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }
}
