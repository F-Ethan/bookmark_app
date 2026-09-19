import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reading_plan.dart';
import '../models/book_group.dart';
import '../data/bible_sections.dart';

/// Local SharedPreferences storage used in guest (no-account) mode.
class LocalDataService {
  static const _nameKey = 'guest_plan_name';
  static const _dayKey = 'guest_plan_current_day';
  static const _dateKey = 'guest_plan_start_date';
  static const _groupsKey = 'guest_book_groups';
  static const _currentStreakKey = 'guest_current_streak';
  static const _longestStreakKey = 'guest_longest_streak';
  static const _highestDayKey = 'guest_highest_day';
  static const _lastActiveDateKey = 'guest_last_active_date';

  // ── Reading Plan ────────────────────────────────────────────────────────────

  static Future<ReadingPlan?> fetchReadingPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_nameKey);
    if (name == null) return null;
    final day = prefs.getInt(_dayKey) ?? 1;
    final dateStr =
        prefs.getString(_dateKey) ?? DateTime.now().toIso8601String();
    final lastActiveStr = prefs.getString(_lastActiveDateKey);
    return ReadingPlan(
      id: 'local',
      userId: 'local',
      name: name,
      currentDay: day,
      startDate: DateTime.parse(dateStr),
      currentStreak: prefs.getInt(_currentStreakKey) ?? 0,
      longestStreak: prefs.getInt(_longestStreakKey) ?? 0,
      highestDayReached: prefs.getInt(_highestDayKey) ?? 0,
      lastActiveDate:
          lastActiveStr != null ? DateTime.parse(lastActiveStr) : null,
    );
  }

  static Future<ReadingPlan> createReadingPlan({
    required String name,
    required int startDay,
    required DateTime startDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
    await prefs.setInt(_dayKey, startDay);
    await prefs.setString(_dateKey, startDate.toIso8601String());
    return ReadingPlan(
      id: 'local',
      userId: 'local',
      name: name,
      currentDay: startDay,
      startDate: startDate,
    );
  }

  static Future<void> updateCurrentDay(int day) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dayKey, day);
  }

  static Future<void> updateProfile({
    required String name,
    required int currentDay,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
    await prefs.setInt(_dayKey, currentDay);
  }

  static Future<void> deleteReadingPlan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_nameKey);
    await prefs.remove(_dayKey);
    await prefs.remove(_dateKey);
    await prefs.remove(_currentStreakKey);
    await prefs.remove(_longestStreakKey);
    await prefs.remove(_highestDayKey);
    await prefs.remove(_lastActiveDateKey);
  }

  static Future<void> updateReadingStats({
    required int currentStreak,
    required int longestStreak,
    required int highestDayReached,
    required DateTime lastActiveDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_currentStreakKey, currentStreak);
    await prefs.setInt(_longestStreakKey, longestStreak);
    await prefs.setInt(_highestDayKey, highestDayReached);
    await prefs.setString(
        _lastActiveDateKey, lastActiveDate.toIso8601String());
  }

  // ── Book Groups ─────────────────────────────────────────────────────────────

  static Future<List<BibleGroup>> fetchBookGroups() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_groupsKey);
    if (json == null) return List.from(defaultBookGroups);
    final list = jsonDecode(json) as List<dynamic>;
    return list.map((g) => BibleGroup.fromJson(g as Map<String, dynamic>)).toList();
  }

  static Future<void> saveBookGroups(List<BibleGroup> groups) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _groupsKey,
      jsonEncode(groups.map((g) => g.toJson()).toList()),
    );
  }

  // ── Chapter progress ───────────────────────────────────────────────────────

  static String _chapterProgressKey(int day) => 'chapter_read_day_$day';

  static Future<Set<int>> fetchChapterProgress(int day) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_chapterProgressKey(day)) ?? [];
    return list.map(int.parse).toSet();
  }

  static Future<void> saveChapterProgress(int day, Set<int> indices) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _chapterProgressKey(day),
      indices.map((i) => i.toString()).toList(),
    );
  }

  // ── Clear All ───────────────────────────────────────────────────────────────

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_nameKey);
    await prefs.remove(_dayKey);
    await prefs.remove(_dateKey);
    await prefs.remove(_groupsKey);
    await prefs.remove(_currentStreakKey);
    await prefs.remove(_longestStreakKey);
    await prefs.remove(_highestDayKey);
    await prefs.remove(_lastActiveDateKey);
  }
}
