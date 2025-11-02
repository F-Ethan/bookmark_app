import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/shared_prefs_service.dart';
import 'screens/home_screen.dart';
import 'screens/daily_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/book_groups_screen.dart';
import 'services/notification_service.dart';

void main() async {
  // ✅ Initialize Flutter engine before using any async plugins
  WidgetsFlutterBinding.ensureInitialized();

  // Clean up invalid notification time if needed
  final prefs = await SharedPreferences.getInstance();
  final timeString = prefs.getString('notification_time');
  if (timeString != null &&
      !timeString.contains('-') &&
      !timeString.contains(':')) {
    await prefs.remove('notification_time');
  }

  // Initialize notifications
  final notificationService = NotificationService();
  await notificationService.init();

  // Load user info and determine if it's first time
  Map<String, dynamic>? userInfo;
  try {
    userInfo = await SharedPrefsService.loadUserInfo();
  } catch (e) {
    print('Error loading SharedPrefs: $e');
    userInfo = null; // Treat as first time on error
  }

  final bool isFirstTime =
      userInfo?['name'] == null || userInfo!['name'].isEmpty;

  runApp(MyApp(isFirstTime: isFirstTime));
}

class MyApp extends StatelessWidget {
  final bool isFirstTime;

  const MyApp({super.key, required this.isFirstTime});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bible Reading Plan',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      initialRoute: isFirstTime ? '/onboarding' : '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/daily': (context) => const DailyScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/bookgroups': (context) => const BookGroupsScreen(),
      },
    );
  }
}
