import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:rxdart/rxdart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // NEW: For TimeOfDay

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  final String? payload = response.payload;
  if (payload != null) {
    // Handle payload here (e.g., save to shared prefs, trigger analytics)
    debugPrint('Background notification tapped with payload: $payload');
    // Note: Can't directly add to streams here—use a method channel or shared storage
  }
}

class NotificationService {
  static final NotificationService _notificationService =
      NotificationService._internal();
  factory NotificationService() => _notificationService;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final BehaviorSubject<String?> onNotificationClick =
      BehaviorSubject<String?>();

  Future<void> init() async {
    tz.initializeTimeZones(); // For timezone scheduling

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings
    initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission:
          false, // CHANGED: Defer to manual request to avoid double-prompting
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final String? payload = response.payload;
        if (payload != null) {
          debugPrint(
            'Notification tapped with payload: $payload',
          ); // Optional: for debugging
          onNotificationClick.add(payload);
        }
      },
      // Optional: For background/terminated app handling
      onDidReceiveBackgroundNotificationResponse:
          notificationTapBackground, // Define this as a top-level function
    );

    // iOS permission request (now the only prompt, since init settings are false)
    final iosImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    if (iosImplementation != null) {
      final bool? granted = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      if (granted != true) {
        print('iOS notification permission denied');
      }
    }
  }

  Future<void> scheduleDailyNotification(TimeOfDay timeOfDay) async {
    await flutterLocalNotificationsPlugin.cancel(0); // Cancel any existing

    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0, // ID
      'Daily Bible Reading Reminder',
      'Time to read your daily chapters from Horner\'s system!',
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily Reminders',
          channelDescription: 'Reminders for daily Bible reading',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(sound: 'default'),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDailyNotification() async {
    await flutterLocalNotificationsPlugin.cancel(0);
  }
}
