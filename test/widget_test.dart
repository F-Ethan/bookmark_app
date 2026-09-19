// Widget smoke tests. These deliberately stay in guest mode and avoid any
// screen that touches Supabase.instance directly during build, so they run
// without a real Supabase.initialize() call (which needs platform channels
// the test environment doesn't provide).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bookmark_new/providers/guest_mode_provider.dart';
import 'package:bookmark_new/screens/auth/sign_in_screen.dart';
import 'package:bookmark_new/screens/home_screen.dart';

void main() {
  testWidgets('HomeScreen renders the guest-mode plan name and day',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'guest_plan_name': 'Test User',
      'guest_plan_current_day': 5,
      'guest_plan_start_date': DateTime(2025, 1, 1).toIso8601String(),
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [guestModeProvider.overrideWith((ref) => true)],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome back, Test User'), findsOneWidget);
    expect(find.text('Day 5 of your reading plan'), findsOneWidget);
  });

  testWidgets('SignInScreen renders without a signed-in session',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: SignInScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Sign in to continue'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Sign In'), findsOneWidget);
  });
}
