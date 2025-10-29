import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/shared_prefs_service.dart'; // NEW: For resetting groups

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  final _dayController = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('name') ?? '';
    final currentDay = prefs.getInt('current_day') ?? 1;

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

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Settings saved!')));

    Navigator.pop(context); // Go back to Home
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

    if (confirmed == true && mounted) {
      await SharedPrefsService.saveGroups(
        [],
      ); // Clears custom_groups (loads defaults next time)
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
        child: SingleChildScrollView(
          // NEW: Wrap Column to enable scrolling on overflow (landscape/small screens)
          child: ConstrainedBox(
            // NEW: Ensures Column expands to full content height
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context)
                      .size
                      .height - // NEW: Responsive min-height (subtracts AppBar/SafeArea)
                  (MediaQuery.of(context).padding.top +
                      kToolbarHeight +
                      MediaQuery.of(context).padding.bottom),
            ),
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
                // NEW: Reset button with warning style
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
                const SizedBox(
                  height: 20,
                ), // NEW: Extra bottom spacer for scroll cushion
              ],
            ),
          ),
        ),
      ),
    );
  }
}
