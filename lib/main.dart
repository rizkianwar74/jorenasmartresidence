import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'core/services/sos_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await initializeDateFormatting('id_ID', null);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Notifikasi lokal hanya tersedia di Android/iOS, tidak di Web
  if (!kIsWeb) {
    await SosNotificationService.init();
  }
  runApp(const SmartResidenceApp());
}
