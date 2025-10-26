import 'package:shared_preferences/shared_preferences.dart';

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
    return {
      'name': prefs.getString('name'),
      'current_day': prefs.getInt('current_day') ?? 1,
      'start_date': prefs.getString('start_date'),
    };
  }

  static Future<void> setCurrentDay(int day) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_day', day);
  }
}