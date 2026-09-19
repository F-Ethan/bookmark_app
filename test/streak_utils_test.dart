import 'package:flutter_test/flutter_test.dart';
import 'package:bookmark_new/utils/streak_utils.dart';

void main() {
  group('computeStreakUpdate', () {
    test('no prior activity starts the streak at 1', () {
      final (current, longest) = computeStreakUpdate(
        today: DateTime(2026, 1, 5),
        lastActiveDate: null,
        currentStreak: 0,
        longestStreak: 0,
      );
      expect(current, 1);
      expect(longest, 1);
    });

    test('marking read again the same day does not double count', () {
      final (current, longest) = computeStreakUpdate(
        today: DateTime(2026, 1, 5, 21), // later the same day, with a time component
        lastActiveDate: DateTime(2026, 1, 5, 8),
        currentStreak: 4,
        longestStreak: 4,
      );
      expect(current, 4);
      expect(longest, 4);
    });

    test('the very next calendar day extends the streak', () {
      final (current, longest) = computeStreakUpdate(
        today: DateTime(2026, 1, 6),
        lastActiveDate: DateTime(2026, 1, 5),
        currentStreak: 4,
        longestStreak: 4,
      );
      expect(current, 5);
      expect(longest, 5);
    });

    test('a gap of more than one day resets the streak to 1', () {
      final (current, longest) = computeStreakUpdate(
        today: DateTime(2026, 1, 10),
        lastActiveDate: DateTime(2026, 1, 5),
        currentStreak: 4,
        longestStreak: 4,
      );
      expect(current, 1);
      expect(longest, 4); // longest is preserved across a reset
    });

    test('longest streak only grows, never shrinks with the current streak', () {
      final (current, longest) = computeStreakUpdate(
        today: DateTime(2026, 2, 1),
        lastActiveDate: DateTime(2026, 1, 5),
        currentStreak: 20,
        longestStreak: 20,
      );
      expect(current, 1);
      expect(longest, 20);
    });
  });
}
