import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/shared_prefs_service.dart';
import '../utils/chapter_utils.dart';

class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key});

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  String? name;
  int currentDay = 1;
  DateTime? startDate;
  List<String> todaysChapters = [];

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final map = await SharedPrefsService.loadUserInfo();
    final sdString = map['start_date'] as String?;
    setState(() {
      name = (map['name'] as String?) ?? 'Reader';
      currentDay = (map['current_day'] as int?) ?? 1;
      startDate = sdString != null ? DateTime.parse(sdString) : DateTime.now();
      todaysChapters = getChaptersForDay(currentDay);
    });
  }

  Future<void> _markAsRead() async {
    await SharedPrefsService.setCurrentDay(currentDay + 1);
    setState(() {
      currentDay++;
      todaysChapters = getChaptersForDay(currentDay);
    });
  }

  Future<void> _goBackOneDay() async {
    if (currentDay <= 1) return; // can't go before day 1

    await SharedPrefsService.setCurrentDay(currentDay - 1);

    setState(() {
      currentDay--;
      todaysChapters = getChaptersForDay(currentDay);
    });
  }

  DateTime get lastReadDate {
    if (startDate == null) return DateTime.now();
    if (currentDay <= 1) return startDate!.subtract(const Duration(days: 1));
    return startDate!.add(Duration(days: currentDay - 2));
  }

  String get formattedLastDate =>
      DateFormat('MMM d, yyyy').format(lastReadDate);

  @override
  Widget build(BuildContext context) {
    if (name == null || startDate == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Reading'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // This returns to HomeScreen
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good morning, $name!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (currentDay > 1)
              Text(
                'Last read: Day ${currentDay - 1} ($formattedLastDate)',
                style: const TextStyle(fontSize: 16),
              ),
            const SizedBox(height: 10),
            Text(
              'To read today: Day $currentDay',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: todaysChapters.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(Icons.book, color: Colors.blue),
                    title: Text(
                      todaysChapters[index],
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                },
              ),
            ),
            Row(
              children: [
                // Go back one day button (arrow)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Go back one day',
                  onPressed: _goBackOneDay,
                ),
                const SizedBox(width: 8),

                // Expanded so the "Mark as Read" button fills the rest of the row
                Expanded(
                  child: ElevatedButton(
                    onPressed: _markAsRead,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Text(
                      'Mark as Read',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
