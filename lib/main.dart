import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
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

/// Crash/error reporting DSN, empty by default. Pass via
/// --dart-define=SENTRY_DSN=... (or dart_defines/dev.json) once a Sentry
/// project exists; until then this is a no-op and Sentry.init is skipped
/// entirely, so nothing is sent anywhere.
const _sentryDsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');

Future<void> main() async {
  if (_sentryDsn.isEmpty) {
    await _runApp();
    return;
  }
  await SentryFlutter.init(
    (options) {
      options.dsn = _sentryDsn;
      options.tracesSampleRate = 0.2;
    },
    appRunner: _runApp,
  );
}

Future<void> _runApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    publishableKey: AppConstants.supabaseAnonKey,
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
  try {
    await BibleService.instance.initialize(translation);
  } catch (e) {
    runApp(_FatalErrorApp(error: e));
    return;
  }

  runApp(ProviderScope(
    overrides: [
      guestModeProvider.overrideWith((ref) => isGuest),
      translationProvider.overrideWith(() => TranslationNotifier(initial: translation)),
      appearanceProvider.overrideWith(() => AppearanceNotifier(initial: appearance)),
    ],
    child: const MyApp(),
  ));
}

/// Shown only if the bundled Bible text itself fails to parse — a
/// corrupted install we can't recover from by falling back to anything.
class _FatalErrorApp extends StatelessWidget {
  final Object error;
  const _FatalErrorApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 40, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Bookmark couldn\'t load its Bible text and can\'t start. '
                    'Please reinstall the app.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
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
