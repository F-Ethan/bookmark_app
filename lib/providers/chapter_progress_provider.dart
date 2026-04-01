import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'reading_plan_provider.dart';

class ChapterProgressNotifier extends AsyncNotifier<Set<int>> {
  @override
  Future<Set<int>> build() async {
    final plan = await ref.watch(readingPlanProvider.future);
    if (plan == null) return {};
    return _load(plan.currentDay);
  }

  static Future<Set<int>> _load(int day) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('chapter_read_day_$day') ?? [];
    return list.map(int.parse).toSet();
  }

  Future<void> toggle(int chapterIndex) async {
    final plan = ref.read(readingPlanProvider).valueOrNull;
    if (plan == null) return;
    final current = state.valueOrNull ?? {};
    final updated = Set<int>.from(current);
    if (updated.contains(chapterIndex)) {
      updated.remove(chapterIndex);
    } else {
      updated.add(chapterIndex);
    }
    state = AsyncData(updated);
    await _save(plan.currentDay, updated);
  }

  Future<void> markRead(int chapterIndex) async {
    final plan = ref.read(readingPlanProvider).valueOrNull;
    if (plan == null) return;
    final current = state.valueOrNull ?? {};
    if (current.contains(chapterIndex)) return;
    final updated = {...current, chapterIndex};
    state = AsyncData(updated);
    await _save(plan.currentDay, updated);
  }

  static Future<void> _save(int day, Set<int> indices) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'chapter_read_day_$day',
      indices.map((i) => i.toString()).toList(),
    );
  }

  bool isRead(int chapterIndex) =>
      state.valueOrNull?.contains(chapterIndex) ?? false;
}

final chapterProgressProvider =
    AsyncNotifierProvider<ChapterProgressNotifier, Set<int>>(
  ChapterProgressNotifier.new,
);
