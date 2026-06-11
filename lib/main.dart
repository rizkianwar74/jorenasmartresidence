import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'core/services/sos_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Notifikasi lokal hanya tersedia di Android/iOS, tidak di Web
  if (!kIsWeb) {
    await SosNotificationService.init();
  }
  runApp(const SmartResidenceApp());
}