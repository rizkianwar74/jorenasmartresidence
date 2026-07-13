import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/onesignal_service.dart';

class SmartResidenceApp extends StatelessWidget {
  const SmartResidenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: OneSignalService.navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Smart Residence',
      theme: AppTheme.light,
      initialRoute: AppRouter.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}