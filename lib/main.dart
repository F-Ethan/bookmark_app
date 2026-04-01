import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/router/router.dart';
import 'core/theme/app_theme.dart';
import 'providers/appearance_provider.dart';
import 'providers/guest_mode_provider.dart';
import 'providers/translation_provider.dart';
import 'services/bible_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // Clean up any invalid notification_time format left from older builds
  final prefs = await SharedPreferences.getInstance();
  final timeString = prefs.getString('notification_time');
  if (timeString != null &&
      !timeString.contains('-') &&
      !timeString.contains(':')) {
    await prefs.remove('notification_time');
  }

  final notificationService = NotificationService();
  await notificationService.init();

  final isGuest = prefs.getBool('guest_mode') ?? false;
  final translation = prefs.getString(kTranslationKey) ?? kDefaultTranslation;
  final appearance = await loadAppearanceSettings();

  // Copy KJV from bundle if needed, then load into memory
  await BibleService.instance.initialize(translation);

  runApp(ProviderScope(
    overrides: [
      guestModeProvider.overrideWith((ref) => isGuest),
      translationProvider.overrideWith(() => TranslationNotifier(initial: translation)),
      appearanceProvider.overrideWith(() => AppearanceNotifier(initial: appearance)),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(appearanceProvider.select((a) => a.themeMode));
    return MaterialApp.router(
      title: 'Bookmark: Horner Bible Reading',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
