import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

import 'services/auth_service.dart';
import 'services/audio_recorder_service.dart';
import 'services/s3_upload_service.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'services/call_detector_service.dart';
import 'services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request necessary permissions
  await _requestPermissions();

  // Initialize services
  await NotificationService().initialize();
  await BackgroundService.initialize();

  // Initialize shared preferences
  await SharedPreferences.getInstance();

  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => AudioRecorderService()),
        ChangeNotifierProvider(create: (_) => CallDetectionService()),
        Provider(create: (_) => S3Service()),
        Provider(create: (_) => ApiService()),
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> _requestPermissions() async {
  final statuses = await [
    Permission.microphone,
    Permission.phone,
    Permission.storage,
    Permission.notification,
    Permission.systemAlertWindow,
    Permission.ignoreBatteryOptimizations,
  ].request();

  // Optional: Check for denied permissions
  statuses.forEach((perm, status) {
    if (!status.isGranted) {
      print('Permission denied: $perm');
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Call Recorder Pro',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
