import 'package:flutter/material.dart';
import 'services/shared_prefs_service.dart';
import 'screens/home_screen.dart';
import 'screens/daily_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/book_groups_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // optional: preload prefs to catch any corrupted data safely
  try {
    await SharedPrefsService.loadUserInfo();
  } catch (e) {
    print('Error loading SharedPrefs: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bible Reading Plan',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
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
