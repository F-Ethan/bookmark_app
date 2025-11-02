import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/shared_prefs_service.dart';
import '../services/notification_service.dart'; // For notifications

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  final _dayController = TextEditingController();
  bool _loading = true;
  bool _notificationsEnabled = false; // Toggle state
  TimeOfDay? _notificationTime; // Selected time

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('name') ?? '';
    final currentDay = prefs.getInt('current_day') ?? 1;

    // Load notification prefs
    _notificationsEnabled = prefs.getBool('enable_notifications') ?? false;
    final timeString = prefs.getString('notification_time');
    if (timeString != null) {
      try {
        // Handle legacy format (e.g., "12:00 AM")
        if (timeString.contains('AM') || timeString.contains('PM')) {
          final parts = timeString.split(RegExp(r'[: ]'));
          int hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          final period = parts[2];
          if (period == 'PM' && hour != 12) hour += 12;
          if (period == 'AM' && hour == 12) hour = 0;
          _notificationTime = TimeOfDay(hour: hour, minute: minute);
        } else {
          // ISO date format (new version)
          _notificationTime = TimeOfDay.fromDateTime(
            DateTime.parse(timeString),
          );
        }
      } catch (e) {
        debugPrint('⚠️ Invalid notification_time format: $timeString ($e)');
        _notificationTime = null;
        await prefs.remove('notification_time'); // optional cleanup
      }
    }

    // NEW: Initialize notifications once (idempotent, safe to call here if not done globally)
    final notificationService = NotificationService();
    await notificationService.init();

    // Optional: Reschedule if already enabled (e.g., after app restart or time change)
    if (_notificationsEnabled && _notificationTime != null) {
      await notificationService.scheduleDailyNotification(_notificationTime!);
    }

    if (!mounted) return;

    setState(() {
      _nameController.text = name;
      _dayController.text = currentDay.toString();
      _loading = false;
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final name = _nameController.text.trim();
    final currentDay = int.tryParse(_dayController.text.trim()) ?? 1;

    await prefs.setString('name', name);
    await prefs.setInt('current_day', currentDay);

    // Save notification prefs
    await prefs.setBool('enable_notifications', _notificationsEnabled);
    if (_notificationTime != null) {
      // Store as "HH:mm" (e.g., "07:30")
      final timeString =
          '${_notificationTime!.hour.toString().padLeft(2, '0')}:${_notificationTime!.minute.toString().padLeft(2, '0')}';
      await prefs.setString('notification_time', timeString);
    } else {
      await prefs.remove('notification_time');
    }

    if (!mounted) return; // ✅ guard before using context

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Settings saved!')));

    // Optional: Reschedule notifications
    if (_notificationsEnabled && _notificationTime != null) {
      final notificationService = NotificationService();
      await notificationService.scheduleDailyNotification(_notificationTime!);
    }

    if (!mounted) return; // ✅ guard again (in case async took time)
    Navigator.pop(context);
  }

  Future<void> _toggleNotifications(bool? value) async {
    final notificationService = NotificationService();

    if (value == true) {
      final time = await showTimePicker(
        context: context,
        initialTime: _notificationTime ?? TimeOfDay.now(),
      );

      if (!mounted) return; // ✅ guard after async picker

      if (time != null) {
        setState(() {
          _notificationsEnabled = true;
          _notificationTime = time;
        });
        await notificationService.scheduleDailyNotification(time);
      }
    } else {
      setState(() {
        _notificationsEnabled = false;
        _notificationTime = null;
      });
      await notificationService.cancelDailyNotification();
    }
  }

  Future<void> _resetGroups() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Bible Groups?'),
        content: const Text(
          'This will clear all custom groups and restore the default 10 groups from Horner\'s system. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (!mounted) return; // ✅ added guard

    if (confirmed == true) {
      await SharedPrefsService.saveGroups([]);
      if (!mounted) return; // ✅ guard again

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bible groups reset to defaults!'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Your Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _dayController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Current Reading Day',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _savePrefs,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Toggle for daily reminders
            Card(
              child: SwitchListTile(
                title: const Text('Daily Reading Reminders'),
                subtitle: Text(
                  _notificationTime != null
                      ? 'Reminders at ${_notificationTime!.format(context)}'
                      : 'Enable to set a daily time',
                ),
                value: _notificationsEnabled,
                onChanged: _toggleNotifications,
                secondary: const Icon(Icons.notifications),
              ),
            ),
            const SizedBox(height: 20),
            // Reset button (unchanged)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _resetGroups,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                child: const Text(
                  'Reset Default Bible Groups',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dayController.dispose();
    super.dispose();
  }
}
