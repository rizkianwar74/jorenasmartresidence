import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'core/services/sos_notification_service.dart';
import 'core/services/onesignal_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await initializeDateFormatting('id_ID', null);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Notifikasi lokal hanya tersedia di Android/iOS, tidak di Web.
  // Dibungkus try-catch masing-masing: kalau salah satu gagal (mis. resource
  // icon tidak ditemukan, plugin error di device tertentu, dll), app tetap
  // lanjut ke runApp() — bukan stuck selamanya di splash screen karena
  // exception tak tertangani sebelum runApp() sempat dipanggil.
  if (!kIsWeb) {
    try {
      await SosNotificationService.init();
    } catch (e) {
      debugPrint('[main] SosNotificationService.init() gagal: $e');
    }
    try {
      await OneSignalService.instance.init();
    } catch (e) {
      debugPrint('[main] OneSignalService.init() gagal: $e');
    }
  }
  runApp(const SmartResidenceApp());
}