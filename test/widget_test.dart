// This is a basic Flutter widget test for the Bookmark app.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For mocking prefs

import 'package:bookmark/main.dart';
import 'package:bookmark/screens/home_screen.dart'; // Adjust import if needed
import 'package:bookmark/screens/onboarding_screen.dart'; // Adjust import if needed

void main() {
  // Mock SharedPreferences for consistent testing (avoids real device storage)
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'name': '', // Empty = first time (triggers onboarding)
      'current_day': 1,
      'start_date': '',
    });
  });

  group('App Launch Tests', () {
    testWidgets('On first launch, shows OnboardingScreen', (
      WidgetTester tester,
    ) async {
      // Ensure mock prefs indicate first time (name is empty)
      SharedPreferences.setMockInitialValues({
        'name': '',
        'current_day': 1,
        'start_date': '',
      });

      // Build app and trigger a frame.
      await tester.pumpWidget(const MyApp(isFirstTime: true));

      // Verify it routes to onboarding (adjust selector to match your OnboardingScreen, e.g., a title or button)
      expect(find.byType(OnboardingScreen), findsOneWidget);
      // Or check for specific text/button in onboarding, e.g.:
      // expect(find.text('Enter your name'), findsOneWidget); // Uncomment and customize

      // Verify app title in debug mode
      expect(find.text('Bible Reading Plan'), findsOneWidget);
    });

    testWidgets('On subsequent launches, shows HomeScreen', (
      WidgetTester tester,
    ) async {
      // Mock prefs with data (not first time)
      SharedPreferences.setMockInitialValues({
        'name': 'Test User',
        'current_day': 5,
        'start_date': '2025-10-26T00:00:00.000Z',
      });

      // Build app and trigger a frame.
      await tester.pumpWidget(const MyApp(isFirstTime: false));

      // Verify it routes to home
      expect(find.byType(HomeScreen), findsOneWidget);
      // Or check for specific text in home, e.g.:
      // expect(find.text('Welcome, Test User'), findsOneWidget); // Uncomment and customize

      // Verify app title
      expect(find.text('Bible Reading Plan'), findsOneWidget);
    });

    testWidgets('App loads without crashing', (WidgetTester tester) async {
      // Use default mock (first time)
      await tester.pumpWidget(const MyApp(isFirstTime: true));

      // Pump another frame to simulate interactions
      await tester.pump();

      // Basic check: No errors, and MaterialApp is present
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
