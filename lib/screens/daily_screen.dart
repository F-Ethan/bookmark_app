import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/shared_prefs_service.dart';
import '../utils/chapter_utils.dart';
import '../data/bible_sections.dart';
import '../models/book_group.dart'; // For BibleGroup

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
  List<BibleGroup>? activeGroups; // Loaded custom or default groups
  final PageController _pageController = PageController(viewportFraction: 0.33);
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final map = await SharedPrefsService.loadUserInfo();
    final sdString = map['start_date'] as String?;

    // Load custom groups or fallback to defaults
    final customGroups = await SharedPrefsService.loadGroups();
    final List<BibleGroup> loadedGroups = customGroups.isNotEmpty
        ? customGroups
        : defaultBookGroups;

    setState(() {
      name = (map['name'] as String?) ?? 'Reader';
      currentDay = (map['current_day'] as int?) ?? 1;
      startDate = sdString != null ? DateTime.parse(sdString) : DateTime.now();
      activeGroups = loadedGroups;
      todaysChapters = getChaptersForDay(
        currentDay,
        loadedGroups,
      ); // Pass groups to util
    });

    // Scroll to center current day
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pageController.hasClients) {
        final int minDay = math.max(1, currentDay - 5);
        final int currentIndex = currentDay - minDay;
        _pageController.animateToPage(
          currentIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _setCurrentDay(int day) async {
    if (day < 1) return;

    await SharedPrefsService.setCurrentDay(day);

    setState(() {
      currentDay = day;
      todaysChapters = getChaptersForDay(
        currentDay,
        activeGroups ?? defaultBookGroups,
      );
    });

    // Re-center carousel
    final int minDay = math.max(1, currentDay - 5);
    final int newIndex = currentDay - minDay;
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        newIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // DEFINED: Mark as read (advance one day)
  Future<void> _markAsRead() async {
    await _setCurrentDay(currentDay + 1);
  }

  // DEFINED: Go back one day
  Future<void> _goBackOneDay() async {
    await _setCurrentDay(currentDay - 1);
  }

  // DEFINED: Go forward one day (for forward button)
  Future<void> _goForwardOneDay() async {
    await _setCurrentDay(currentDay + 1);
  }

  DateTime get lastReadDate {
    if (startDate == null) return DateTime.now();
    if (currentDay <= 1) return startDate!.subtract(const Duration(days: 1));
    return startDate!.add(Duration(days: currentDay - 2));
  }

  String get formattedLastDate =>
      DateFormat('MMM d, yyyy').format(lastReadDate);

  DateTime _getDateForDay(int day) {
    if (startDate == null) return DateTime.now();
    return startDate!.add(Duration(days: day - 1));
  }

  @override
  Widget build(BuildContext context) {
    if (name == null || startDate == null || activeGroups == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final int minDay = math.max(1, currentDay - 5);
    final int maxDay = currentDay + 5;
    final int numDays = maxDay - minDay + 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Reading'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Good morning, ${name ?? 'Reader'}!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 120,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) =>
                        setState(() => _currentPageIndex = index),
                    itemCount: numDays,
                    itemBuilder: (context, index) {
                      final int day = minDay + index;
                      final bool isCurrent = day == currentDay;
                      final DateTime dayDate = _getDateForDay(day);
                      final String formattedDate = DateFormat(
                        'MMM d, yyyy',
                      ).format(dayDate);

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: GestureDetector(
                          onTap: () => _setCurrentDay(day),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isCurrent ? Colors.blue : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Day $day',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isCurrent
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formattedDate,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isCurrent
                                        ? Colors.white70
                                        : Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(numDays, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPageIndex == index
                            ? Colors.blue
                            : Colors.grey[300],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (currentDay > 1)
                  Text(
                    'Last read: Day ${currentDay - 1} ($formattedLastDate)',
                    style: const TextStyle(fontSize: 16),
                  ),
                Text(
                  'To read today: Day $currentDay',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => ListTile(
                  leading: const Icon(Icons.book, color: Colors.blue),
                  title: Text(
                    todaysChapters[index],
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                childCount: todaysChapters.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Go back one day',
                onPressed: _goBackOneDay, // Now defined above
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _markAsRead, // Now defined above
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                  child: const Text(
                    'Mark as Read',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                tooltip: 'Go forward one day',
                onPressed: _goForwardOneDay, // Defined above
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
