// SharedPrefsService now only handles device-local notification preferences.
// All reading plan data and book groups are managed via Supabase.
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsService {
  static Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('enable_notifications') ?? false;
  }

  static Future<String?> getNotificationTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('notification_time');
  }

  static Future<void> setNotificationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enable_notifications', enabled);
  }

  static Future<void> setNotificationTime(String time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notification_time', time);
  }

  static Future<void> clearNotificationTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('notification_time');
  }
}
