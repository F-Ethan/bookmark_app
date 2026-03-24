import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/guest_mode_provider.dart';
import '../../screens/auth/sign_in_screen.dart';
import '../../screens/auth/sign_up_screen.dart';
import '../../screens/onboarding_screen.dart';
import '../../screens/home_screen.dart';
import '../../screens/daily_screen.dart';
import '../../screens/book_groups_screen.dart';
import '../../screens/settings_screen.dart';
import '../../screens/reader_screen.dart' show ReaderScreen, ReaderArgs;

class _AppStateNotifier extends ChangeNotifier {
  _AppStateNotifier() {
    _subscription = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AppStateNotifier();
  ref.onDispose(notifier.dispose);

  // Refresh router whenever guest mode toggles
  ref.listen<bool>(guestModeProvider, (_, __) => notifier.notifyListeners());

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final user = Supabase.instance.client.auth.currentUser;
      final isLoggedIn = user != null;
      final isGuest = ref.read(guestModeProvider);
      final isAuthenticated = isLoggedIn || isGuest;
      final loc = state.matchedLocation;
      final isAuthRoute = loc == '/sign-in' || loc == '/sign-up';

      if (!isAuthenticated && !isAuthRoute) return '/sign-in';
      if (isAuthenticated && isAuthRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/sign-up',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'daily',
            builder: (context, state) => const DailyScreen(),
          ),
          GoRoute(
            path: 'bookgroups',
            builder: (context, state) => const BookGroupsScreen(),
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: 'reader',
            builder: (context, state) {
              final args = state.extra;
              if (args is! ReaderArgs) return const DailyScreen();
              return ReaderScreen(args: args);
            },
          ),
        ],
      ),
    ],
  );
});
