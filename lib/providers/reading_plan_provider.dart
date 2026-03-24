import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reading_plan.dart';
import '../services/supabase_service.dart';
import '../services/local_data_service.dart';
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
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(currentDay: day));
    if (ref.read(guestModeProvider)) {
      await LocalDataService.updateCurrentDay(day);
    } else {
      await SupabaseService.updateCurrentDay(current.id, day);
    }
  }

  Future<void> updateProfile({
    required String name,
    required int currentDay,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(name: name, currentDay: currentDay));
    if (ref.read(guestModeProvider)) {
      await LocalDataService.updateProfile(name: name, currentDay: currentDay);
    } else {
      await SupabaseService.updateProfile(current.id,
          name: name, currentDay: currentDay);
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
