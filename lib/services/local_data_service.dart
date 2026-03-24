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

  // ── Reading Plan ────────────────────────────────────────────────────────────

  static Future<ReadingPlan?> fetchReadingPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_nameKey);
    if (name == null) return null;
    final day = prefs.getInt(_dayKey) ?? 1;
    final dateStr =
        prefs.getString(_dateKey) ?? DateTime.now().toIso8601String();
    return ReadingPlan(
      id: 'local',
      userId: 'local',
      name: name,
      currentDay: day,
      startDate: DateTime.parse(dateStr),
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

  // ── Clear All ───────────────────────────────────────────────────────────────

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_nameKey);
    await prefs.remove(_dayKey);
    await prefs.remove(_dateKey);
    await prefs.remove(_groupsKey);
  }
}
