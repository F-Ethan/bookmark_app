import 'dart:math' as math;

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
  final PageController _pageController = PageController(
    viewportFraction: 0.33,
  ); // 25% of screen per block (~100-120px on most devices)
  int _currentPageIndex = 0; // Track for dots indicator

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
    setState(() {
      name = (map['name'] as String?) ?? 'Reader';
      currentDay = (map['current_day'] as int?) ?? 1;
      startDate = sdString != null ? DateTime.parse(sdString) : DateTime.now();
      todaysChapters = getChaptersForDay(currentDay);
    });

    // Scroll to center the current day after a frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pageController.hasClients) {
        final int minDay = math.max(1, currentDay - 5);
        final int currentIndex = currentDay - minDay; // Offset from minDay
        _pageController.animateToPage(
          currentIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _setCurrentDay(int day) async {
    if (day < 1) return; // Can't go before day 1

    await SharedPrefsService.setCurrentDay(day);

    setState(() {
      currentDay = day;
      todaysChapters = getChaptersForDay(currentDay);
    });

    // Scroll to center the new current day
    final int minDay = math.max(1, currentDay - 5);
    final int newIndex = currentDay - minDay; // Use currentDay now
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        newIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _markAsRead() async {
    await _setCurrentDay(currentDay + 1);
  }

  Future<void> _goBackOneDay() async {
    await _setCurrentDay(currentDay - 1);
  }

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

  // Helper to get date for a specific day
  DateTime _getDateForDay(int day) {
    if (startDate == null) return DateTime.now();
    return startDate!.add(Duration(days: day - 1));
  }

  @override
  Widget build(BuildContext context) {
    if (name == null || startDate == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Calculate range for carousel: up to 5 days back/forward from current
    final int minDay = math.max(
      1,
      currentDay - 5,
    ); // Use math.max for int typing
    final int maxDay = currentDay + 5;
    final int numDays = maxDay - minDay + 1;

    return Scaffold(
      appBar: AppBar(
        // Sticky top header—no changes
        title: Text(
          'Daily Reading',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // This returns to HomeScreen
          },
        ),
      ),
      body: CustomScrollView(
        // NEW: Replaces Column + Expanded(ListView) for unified scrolling
        slivers: [
          // NEW: Spacer sliver for top padding (replaces greeting spacing)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              20,
            ), // Matches your original padding
            sliver: SliverToBoxAdapter(
              child: Text(
                'Good morning, $name!', // Greeting—now scrolls if very long, but sticky-ish
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          // NEW: Carousel as a sliver—scrolls with content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 120, // Fixed height for carousel
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPageIndex = index;
                      });
                    },
                    itemCount: numDays,
                    itemBuilder: (context, index) {
                      final int day = minDay + index;
                      final bool isCurrent = day == currentDay;
                      final DateTime dayDate = _getDateForDay(day);
                      final String formattedDate = DateFormat(
                        'MMM d, yyyy',
                      ).format(dayDate);

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal:
                              8.0, // Reduced padding for tighter fit with viewportFraction
                        ), // Space around blocks for centering
                        child: GestureDetector(
                          onTap: () =>
                              _setCurrentDay(day), // Tap to set current day
                          child: Container(
                            // Remove fixed width—PageView with viewportFraction handles sizing
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
                // Dots indicator for scrollable hint
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
          // NEW: "Last read" and "To read today" as slivers—scroll with content
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
                const SizedBox(height: 10), // Spacer before chapters
              ]),
            ),
          ),
          // NEW: Chapters as SliverList—efficient for long lists
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return ListTile(
                  leading: const Icon(Icons.book, color: Colors.blue),
                  title: Text(
                    todaysChapters[index],
                    style: const TextStyle(fontSize: 16),
                  ),
                );
              }, childCount: todaysChapters.length),
            ),
          ),
          // NEW: Bottom spacer to prevent chapters from hitting bottom buttons
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
      // NEW: Sticky bottom buttons—replaces the old Row in body
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
        ), // Optional subtle shadow for elevation
        child: SafeArea(
          // Ensures it doesn't overlap system UI (e.g., gesture bar)
          child: Row(
            children: [
              // Go back one day button (arrow) - Now optional since carousel handles it
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
              // Forward one day button
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                tooltip: 'Go forward one day',
                onPressed: _goForwardOneDay, // Fixed: Calls forward logic
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
