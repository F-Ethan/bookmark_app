import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme/app_theme.dart';
import '../providers/appearance_provider.dart';
import '../providers/guest_mode_provider.dart';
import '../providers/reading_plan_provider.dart';
import '../providers/book_groups_provider.dart';
import '../services/local_data_service.dart';
import '../services/notification_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameController = TextEditingController();
  final _dayController = TextEditingController();
  bool _notificationsEnabled = false;
  TimeOfDay? _notificationTime;
  bool _prefsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationPrefs();
  }

  Future<void> _loadNotificationPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool('enable_notifications') ?? false;

    final timeString = prefs.getString('notification_time');
    if (timeString != null) {
      try {
        if (timeString.contains('AM') || timeString.contains('PM')) {
          final parts = timeString.split(RegExp(r'[: ]'));
          int hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          final period = parts[2];
          if (period == 'PM' && hour != 12) hour += 12;
          if (period == 'AM' && hour == 12) hour = 0;
          _notificationTime = TimeOfDay(hour: hour, minute: minute);
        } else {
          final parts = timeString.split(':');
          _notificationTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
      } catch (_) {
        _notificationTime = null;
      }
    }

    if (!mounted) return;
    setState(() => _prefsLoaded = true);
  }

  Future<void> _saveSettings() async {
    final plan = ref.read(readingPlanProvider).valueOrNull;
    if (plan == null) return;

    final name = _nameController.text.trim();
    final day = int.tryParse(_dayController.text.trim()) ?? plan.currentDay;

    await ref
        .read(readingPlanProvider.notifier)
        .updateProfile(name: name, currentDay: day);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enable_notifications', _notificationsEnabled);
    if (_notificationTime != null) {
      final timeString =
          '${_notificationTime!.hour.toString().padLeft(2, '0')}:${_notificationTime!.minute.toString().padLeft(2, '0')}';
      await prefs.setString('notification_time', timeString);
    } else {
      await prefs.remove('notification_time');
    }

    if (_notificationsEnabled && _notificationTime != null) {
      await NotificationService()
          .scheduleDailyNotification(_notificationTime!);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Settings saved!')));
    Navigator.pop(context);
  }

  Future<void> _toggleNotifications(bool? value) async {
    final notificationService = NotificationService();
    if (value == true) {
      final time = await showTimePicker(
        context: context,
        initialTime: _notificationTime ?? TimeOfDay.now(),
      );
      if (!mounted) return;
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

  Future<void> _startOver() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Over?'),
        content: const Text(
          'This will delete your reading progress and reset your book groups to the defaults. You\'ll be taken back through setup. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Start Over',
                style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirmed == true) {
      await ref.read(bookGroupsProvider.notifier).resetToDefaults();
      await ref.read(readingPlanProvider.notifier).deletePlan();
      if (!mounted) return;
      context.go('/onboarding');
    }
  }

  Future<void> _signOut() async {
    final isGuest = ref.read(guestModeProvider);
    if (isGuest) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Leave guest mode?'),
          content: const Text(
            'Your local reading progress will be lost. Create a free account first if you want to keep it.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Leave',
                  style: TextStyle(color: AppTheme.danger)),
            ),
          ],
        ),
      );
      if (confirmed == true && mounted) {
        await LocalDataService.clearAll();
        await exitGuestMode(ref.read(guestModeProvider.notifier));
      }
    } else {
      await Supabase.instance.client.auth.signOut();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final planAsync = ref.watch(readingPlanProvider);

    return planAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (plan) {
        if (plan == null || !_prefsLoaded) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        if (_nameController.text.isEmpty) {
          _nameController.text = plan.name;
        }
        if (_dayController.text.isEmpty) {
          _dayController.text = plan.currentDay.toString();
        }

        final isGuest = ref.watch(guestModeProvider);
        final email =
            Supabase.instance.client.auth.currentUser?.email ?? '';

        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            children: [
              // Guest mode banner
              if (isGuest) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                    border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Color(0xFFF59E0B), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Using without an account',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Your progress is saved on this device only. Create a free account to back it up.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: () => context.go('/sign-up'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFFF59E0B),
                                ),
                                child: const Text('Create a free account'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Account row (signed-in users)
              if (!isGuest && email.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    border: Border.all(
                        color:
                            Theme.of(context).colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color:
                              AppTheme.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.person_rounded,
                            color: AppTheme.primary, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          email,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Profile fields
              Text(
                'Profile',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.5,
                    ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Your Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _dayController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Current Reading Day'),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saveSettings,
                child: const Text('Save Changes'),
              ),
              const SizedBox(height: 32),

              // Notifications
              Text(
                'Notifications',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.5,
                    ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  border: Border.all(
                      color:
                          Theme.of(context).colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SwitchListTile(
                  title: const Text('Daily Reading Reminders'),
                  subtitle: Text(
                    _notificationTime != null
                        ? 'At ${_notificationTime!.format(context)}'
                        : 'Enable to set a time',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                  value: _notificationsEnabled,
                  onChanged: _toggleNotifications,
                  activeColor: AppTheme.primary,
                  secondary: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.notifications_rounded,
                        color: AppTheme.primary, size: 18),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Appearance
              _SettingsSectionLabel('Appearance'),
              const SizedBox(height: 12),
              _OptionRow(
                label: 'Theme',
                options: themeModeOptions,
                selected: ref.watch(appearanceProvider).themeModeKey,
                onSelected: (k) =>
                    ref.read(appearanceProvider.notifier).setThemeMode(k),
              ),
              const SizedBox(height: 32),

              // Reader
              _SettingsSectionLabel('Reader'),
              const SizedBox(height: 12),
              _OptionRow(
                label: 'Font',
                options: fontOptions,
                selected: ref.watch(appearanceProvider).fontKey,
                onSelected: (k) =>
                    ref.read(appearanceProvider.notifier).setFont(k),
              ),
              const SizedBox(height: 16),
              _OptionRow(
                label: 'Text Size',
                options: const {
                  'small': 'S',
                  'medium': 'M',
                  'large': 'L',
                  'xlarge': 'XL'
                },
                selected: ref.watch(appearanceProvider).fontSizeKey,
                onSelected: (k) =>
                    ref.read(appearanceProvider.notifier).setFontSize(k),
              ),
              const SizedBox(height: 16),
              _OptionRow(
                label: 'Spacing',
                options: const {
                  'compact': 'Compact',
                  'normal': 'Normal',
                  'relaxed': 'Relaxed'
                },
                selected: ref.watch(appearanceProvider).spacingKey,
                onSelected: (k) =>
                    ref.read(appearanceProvider.notifier).setSpacing(k),
              ),
              const SizedBox(height: 16),
              _JustifyToggle(),
              const SizedBox(height: 32),

              // Danger zone
              Text(
                'Danger Zone',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.5,
                    ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _startOver,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.danger,
                  side: const BorderSide(color: AppTheme.danger),
                ),
                child: const Text('Start Over'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _signOut,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.danger,
                  side: const BorderSide(color: AppTheme.danger),
                ),
                child: Text(isGuest ? 'Leave Guest Mode' : 'Sign Out'),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Shared settings widgets ────────────────────────────────────────────────────

class _SettingsSectionLabel extends StatelessWidget {
  final String text;
  const _SettingsSectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
            letterSpacing: 0.5,
          ),
    );
  }
}

/// A labelled row of pill buttons (single-select).
class _OptionRow extends StatelessWidget {
  final String label;
  final Map<String, String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  const _OptionRow({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.entries.map((e) {
            final isSelected = e.key == selected;
            return GestureDetector(
              onTap: () => onSelected(e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primary
                      : Theme.of(context).colorScheme.surfaceContainerLow,
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primary
                        : Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  e.value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Justify text toggle row.
class _JustifyToggle extends ConsumerWidget {
  const _JustifyToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final justify = ref.watch(appearanceProvider).justifyText;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: SwitchListTile(
        title: const Text('Justify Text'),
        subtitle: const Text(
          'Align text to both edges for a book-like appearance',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        value: justify,
        activeColor: AppTheme.primary,
        onChanged: (v) =>
            ref.read(appearanceProvider.notifier).setJustifyText(v),
      ),
    );
  }
}