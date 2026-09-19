import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_data_service.dart';
import '../services/supabase_service.dart';
import 'guest_mode_provider.dart';
import 'reading_plan_provider.dart';

class ChapterProgressNotifier extends AsyncNotifier<Set<int>> {
  @override
  Future<Set<int>> build() async {
    final plan = await ref.watch(readingPlanProvider.future);
    if (plan == null) return {};
    final isGuest = ref.watch(guestModeProvider);
    return isGuest
        ? LocalDataService.fetchChapterProgress(plan.currentDay)
        : SupabaseService.fetchChapterProgress(plan.currentDay);
  }

  Future<void> _setRead(int day, int chapterIndex, bool read) async {
    if (ref.read(guestModeProvider)) {
      final updated = Set<int>.from(state.valueOrNull ?? {});
      read ? updated.add(chapterIndex) : updated.remove(chapterIndex);
      await LocalDataService.saveChapterProgress(day, updated);
    } else {
      await SupabaseService.setChapterRead(day, chapterIndex, read);
    }
  }

  Future<void> toggle(int chapterIndex) async {
    final plan = ref.read(readingPlanProvider).valueOrNull;
    if (plan == null) return;
    final previous = state.valueOrNull ?? {};
    final nowRead = !previous.contains(chapterIndex);
    final updated = Set<int>.from(previous);
    nowRead ? updated.add(chapterIndex) : updated.remove(chapterIndex);
    state = AsyncData(updated);
    try {
      await _setRead(plan.currentDay, chapterIndex, nowRead);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> markRead(int chapterIndex) async {
    final plan = ref.read(readingPlanProvider).valueOrNull;
    if (plan == null) return;
    final previous = state.valueOrNull ?? {};
    if (previous.contains(chapterIndex)) return;
    final updated = {...previous, chapterIndex};
    state = AsyncData(updated);
    try {
      await _setRead(plan.currentDay, chapterIndex, true);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  bool isRead(int chapterIndex) =>
      state.valueOrNull?.contains(chapterIndex) ?? false;
}

final chapterProgressProvider =
    AsyncNotifierProvider<ChapterProgressNotifier, Set<int>>(
  ChapterProgressNotifier.new,
);
