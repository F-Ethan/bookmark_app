import 'package:shared_preferences/shared_preferences.dart';
import 'package:bookmark_new/models/book_group.dart';
import 'dart:convert';

class SharedPrefsService {
  static Future<void> saveUserInfo({
    required String name,
    required int startDay,
    required DateTime startDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', name);
    await prefs.setInt('current_day', startDay);
    await prefs.setString('start_date', startDate.toIso8601String());
  }

  static Future<Map<String, dynamic>> loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();

    // Safely read simple values
    final name = prefs.getString('name') ?? '';
    final currentDay = prefs.getInt('current_day') ?? 1;

    // Validate start_date
    String? startDateString = prefs.getString('start_date');
    DateTime? startDate;
    if (startDateString != null) {
      try {
        startDate = DateTime.parse(startDateString);
      } catch (e) {
        print('Invalid start_date in SharedPrefs: $startDateString');
        await prefs.remove('start_date');
        startDate = null;
      }
    }

    // Validate notification_time (optional, but good to add)
    String? notifTime = prefs.getString('notification_time');
    if (notifTime != null &&
        !RegExp(r'^\d{1,2}:\d{2}').hasMatch(notifTime) &&
        !notifTime.contains('-')) {
      print('Invalid notification_time format: $notifTime');
      await prefs.remove('notification_time');
      notifTime = null;
    }

    return {
      'name': name,
      'current_day': currentDay,
      'start_date': startDate?.toIso8601String(),
      'notification_time': notifTime,
    };
  }

  static Future<void> setCurrentDay(int day) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_day', day);
  }

  // Add to SharedPrefsService class

  // JSON serialization helpers (add these as static methods or in models)
  static Map<String, dynamic> _groupToJson(BibleGroup group) {
    return {
      'name': group.name,
      'books': group.books
          .map((book) => {'name': book.name, 'chapters': book.chapters})
          .toList(),
    };
  }

  static BibleGroup _groupFromJson(Map<String, dynamic> json) {
    final booksJson = json['books'] as List<dynamic>;
    final books = booksJson
        .map(
          (bJson) =>
              BibleBook(name: bJson['name'], chapters: bJson['chapters']),
        )
        .toList();
    return BibleGroup(name: json['name'], books: books);
  }

  // New methods for groups
  static Future<void> saveGroups(List<BibleGroup> groups) async {
    final prefs = await SharedPreferences.getInstance();
    final groupsJson = groups.map((g) => _groupToJson(g)).toList();
    await prefs.setString('custom_groups', jsonEncode(groupsJson));
  }

  static Future<List<BibleGroup>> loadGroups() async {
    final prefs = await SharedPreferences.getInstance();
    final groupsString = prefs.getString('custom_groups');
    if (groupsString == null) return []; // No custom, use defaults
    final groupsJson = jsonDecode(groupsString) as List<dynamic>;
    return groupsJson.map((gJson) => _groupFromJson(gJson)).toList();
  }
}
