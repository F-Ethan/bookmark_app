import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/shared_prefs_service.dart';
import 'daily_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  int _startDay = 1;
  DateTime _startDate =
      DateTime.now(); // Fixed to current date—no changes needed

  Future<void> _saveAndNavigate() async {
    await SharedPrefsService.saveUserInfo(
      name: _nameController.text,
      startDay: _startDay,
      startDate: _startDate, // Will always be today
    );
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const DailyScreen()),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome to Bible Reading')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Let\'s get started!', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Your Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  _startDay = int.tryParse(value) ?? 1;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Starting Day (e.g., 1)',
              ),
            ),
            const SizedBox(height: 10),
            // Static display for the fixed start date (no picker)
            Text(
              'Start Date: ${DateFormat('MMM d, yyyy').format(_startDate)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _nameController.text.isNotEmpty && _startDay > 0
                  ? _saveAndNavigate
                  : null,
              child: const Text('Start Reading'),
            ),
          ],
        ),
      ),
    );
  }
}
