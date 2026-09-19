import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reading_plan.dart';
import '../services/supabase_service.dart';
import '../services/local_data_service.dart';
import '../utils/streak_utils.dart';
import 'auth_provider.dart';
import 'guest_mode_provider.dart';

class ReadingPlanNotifier extends AsyncNotifier<ReadingPlan?> {
  @override
  Future<ReadingPlan?> build() async {
    final isGuest = ref.watch(guestModeProvider);
    if (isGuest) return LocalDataService.fetchReadingPlan();
    final user = ref.watch(currentUserProvider);
    if (user == null) return null;
    return SupabaseService.fetchReadingPlan();
  }

  Future<void> create({
    required String name,
    required int startDay,
  }) async {
    final startDate = DateTime.now().subtract(Duration(days: startDay - 1));
    final isGuest = ref.read(guestModeProvider);
    final plan = isGuest
        ? await LocalDataService.createReadingPlan(
            name: name, startDay: startDay, startDate: startDate)
        : await SupabaseService.createReadingPlan(
            name: name, startDay: startDay, startDate: startDate);
    state = AsyncData(plan);
  }

  Future<void> setCurrentDay(int day) async {
    final previous = state.valueOrNull;
    if (previous == null) return;
    state = AsyncData(previous.copyWith(currentDay: day));
    try {
      if (ref.read(guestModeProvider)) {
        await LocalDataService.updateCurrentDay(day);
      } else {
        await SupabaseService.updateCurrentDay(previous.id, day);
      }
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> updateProfile({
    required String name,
    required int currentDay,
  }) async {
    final previous = state.valueOrNull;
    if (previous == null) return;
    state = AsyncData(previous.copyWith(name: name, currentDay: currentDay));
    try {
      if (ref.read(guestModeProvider)) {
        await LocalDataService.updateProfile(
            name: name, currentDay: currentDay);
      } else {
        await SupabaseService.updateProfile(previous.id,
            name: name, currentDay: currentDay);
      }
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  /// Called when [completedDay] is genuinely marked as read (as opposed to
  /// [setCurrentDay] alone, which is also used by Settings' manual day-number
  /// edit and must not affect streak/highest-day stats). Advances the day,
  /// updates streak/highest-day stats, and returns the new current streak so
  /// the caller can check it against review-prompt milestones.
  Future<int> recordDayCompleted(int completedDay) async {
    final previous = state.valueOrNull;
    if (previous == null) return 0;

    await setCurrentDay(completedDay + 1);

    final today = DateTime.now();
    final (newStreak, newLongest) = computeStreakUpdate(
      today: today,
      lastActiveDate: previous.lastActiveDate,
      currentStreak: previous.currentStreak,
      longestStreak: previous.longestStreak,
    );
    final newHighestDay = completedDay > previous.highestDayReached
        ? completedDay
        : previous.highestDayReached;

    final afterDayAdvance = state.valueOrNull ?? previous;
    state = AsyncData(afterDayAdvance.copyWith(
      currentStreak: newStreak,
      longestStreak: newLongest,
      highestDayReached: newHighestDay,
      lastActiveDate: today,
    ));
    try {
      if (ref.read(guestModeProvider)) {
        await LocalDataService.updateReadingStats(
          currentStreak: newStreak,
          longestStreak: newLongest,
          highestDayReached: newHighestDay,
          lastActiveDate: today,
        );
      } else {
        await SupabaseService.updateReadingStats(
          previous.id,
          currentStreak: newStreak,
          longestStreak: newLongest,
          highestDayReached: newHighestDay,
          lastActiveDate: today,
        );
      }
    } catch (_) {
      // The day number already advanced successfully above (and rolls back
      // independently if that write fails) — a real day was completed, so we
      // don't undo it just because this secondary stats write failed. Only
      // the stats themselves revert; they'll catch up next time a day is
      // marked read.
      state = AsyncData(afterDayAdvance.copyWith(
        currentStreak: previous.currentStreak,
        longestStreak: previous.longestStreak,
        highestDayReached: previous.highestDayReached,
        lastActiveDate: previous.lastActiveDate,
      ));
      rethrow;
    }
    return newStreak;
  }

  Future<void> updateLeaderboardOptIn({
    required bool optIn,
    required String? displayName,
  }) async {
    final previous = state.valueOrNull;
    if (previous == null) return;
    state = AsyncData(previous.copyWith(
      leaderboardOptIn: optIn,
      leaderboardDisplayName: displayName,
    ));
    if (ref.read(guestModeProvider)) return; // leaderboard is signed-in only
    try {
      await SupabaseService.updateLeaderboardOptIn(previous.id,
          optIn: optIn, displayName: displayName);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> deletePlan() async {
    if (ref.read(guestModeProvider)) {
      await LocalDataService.deleteReadingPlan();
    } else {
      await SupabaseService.deleteReadingPlan();
    }
    state = const AsyncData(null);
  }
}

final readingPlanProvider =
    AsyncNotifierProvider<ReadingPlanNotifier, ReadingPlan?>(
  ReadingPlanNotifier.new,
);
