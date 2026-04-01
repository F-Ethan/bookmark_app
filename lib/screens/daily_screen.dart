import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/supabase_error.dart';
import '../data/bible_sections.dart';
import '../providers/reading_plan_provider.dart';
import '../providers/book_groups_provider.dart';
import '../providers/chapter_progress_provider.dart';
import '../providers/verse_highlights_provider.dart';
import '../services/bible_service.dart';
import '../utils/chapter_utils.dart';
import 'reader_screen.dart' show ReaderArgs;

class DailyScreen extends ConsumerStatefulWidget {
  const DailyScreen({super.key});

  @override
  ConsumerState<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends ConsumerState<DailyScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.33);
  int _currentPageIndex = 0;
  int? _viewedDay; // null = show currentDay

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToDay(int day, {required int currentDay}) {
    if (day < 1) return;
    final minDay = math.max(1, currentDay - 5);
    final maxDay = currentDay + 5;
    if (day < minDay || day > maxDay) return;
    setState(() => _viewedDay = day == currentDay ? null : day);
    final newIndex = day - minDay;
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        newIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _markAsRead({required int displayDay, required int currentDay}) async {
    if (displayDay < currentDay) return; // already read
    await ref.read(readingPlanProvider.notifier).setCurrentDay(displayDay + 1);
    setState(() => _viewedDay = null); // snap back to new currentDay
  }

  DateTime _getDateForDay(int day, DateTime startDate) =>
      startDate.add(Duration(days: day - 1));

  @override
  Widget build(BuildContext context) {
    final planAsync = ref.watch(readingPlanProvider);
    final groupsAsync = ref.watch(bookGroupsProvider);

    return planAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => isSupabasePaused(e)
          ? const SupabasePausedScreen()
          : Scaffold(body: Center(child: Text('Error: $e'))),
      data: (plan) {
        if (plan == null) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final groups = groupsAsync.valueOrNull ?? defaultBookGroups;
        final currentDay = plan.currentDay;
        final startDate = plan.startDate;
        final int displayDay = _viewedDay ?? currentDay;
        final todaysChapters = getChaptersForDay(displayDay, groups);

        final int minDay = math.max(1, currentDay - 5);
        final int maxDay = currentDay + 5;
        final int numDays = maxDay - minDay + 1;

        // Only auto-scroll to currentDay when not manually navigating
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _pageController.hasClients && _viewedDay == null) {
            final targetIndex = currentDay - minDay;
            if (_pageController.page?.round() != targetIndex) {
              _pageController.jumpToPage(targetIndex);
            }
          }
        });

        final int lastReadDay = currentDay - 1;
        final String? lastReadDate = lastReadDay >= 1
            ? DateFormat('MMM d, yyyy')
                .format(_getDateForDay(lastReadDay, startDate))
            : null;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Daily Reading'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.go('/'),
            ),
          ),
          body: CustomScrollView(
            slivers: [
              // Greeting
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Good morning, ${plan.name}!',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Day carousel
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    SizedBox(
                      height: 88,
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (i) =>
                            setState(() => _currentPageIndex = i),
                        itemCount: numDays,
                        itemBuilder: (context, index) {
                          final int day = minDay + index;
                          final bool isCurrent = day == displayDay;
                          final bool isRead = day < currentDay;
                          final String formattedDate =
                              DateFormat('MMM d').format(
                            _getDateForDay(day, startDate),
                          );

                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 6.0),
                            child: GestureDetector(
                              onTap: () => _navigateToDay(day, currentDay: currentDay),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? AppTheme.primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerLow,
                                  border: Border.all(
                                    color: isCurrent
                                        ? AppTheme.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .outlineVariant,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Day $day',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: isCurrent
                                            ? Colors.white
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (isRead)
                                      Icon(
                                        Icons.check_circle_rounded,
                                        size: 20,
                                        color: isCurrent
                                            ? Colors.white
                                            : const Color(0xFF22C55E),
                                      )
                                    else
                                      Text(
                                        formattedDate,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isCurrent
                                              ? Colors.white70
                                              : AppTheme.textSecondary,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Page dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(numDays, (i) {
                        final isActive = _currentPageIndex == i;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: isActive ? 16 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppTheme.primary
                                : Theme.of(context)
                                    .colorScheme
                                    .outlineVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              // Last read / today labels
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (lastReadDate != null) ...[
                      Text(
                        'Last read: Day $lastReadDay • $lastReadDate',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      displayDay == currentDay
                          ? 'Today — Day $currentDay'
                          : displayDay < currentDay
                              ? 'Day $displayDay — Already Read'
                              : 'Day $displayDay',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                  ]),
                ),
              ),

              // Chapter list
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerLow,
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary
                                      .withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.book_rounded,
                                  color: AppTheme.primary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  todaysChapters[index],
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.w500),
                                ),
                              ),
                              const SizedBox(width: 4),
                              _VerseBookmarkButton(
                                chapterRef: todaysChapters[index],
                                readingDay: currentDay,
                              ),
                              // Chapter read checkmark
                              _ChapterCheckButton(
                                chapterIndex: index,
                                isCurrentDay: displayDay == currentDay,
                                isPastDay: displayDay < currentDay,
                              ),
                              TextButton(
                                onPressed: () => context.push(
                                  '/reader',
                                  extra: ReaderArgs(
                                    dayChapters: todaysChapters,
                                    initialIndex: index,
                                    readingDay: displayDay,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('Read'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: todaysChapters.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),

          // Bottom action bar
          bottomNavigationBar: Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  _CircleIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Previous day',
                    onPressed: () => _navigateToDay(displayDay - 1, currentDay: currentDay),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: displayDay < currentDay
                          ? null
                          : () => _markAsRead(displayDay: displayDay, currentDay: currentDay),
                      child: Text(displayDay < currentDay ? 'Already Read' : 'Mark as Read'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _CircleIconButton(
                    icon: Icons.arrow_forward_rounded,
                    tooltip: 'Next day',
                    onPressed: () => _navigateToDay(displayDay + 1, currentDay: currentDay),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Verse bookmark button + picker ─────────────────────────────────────────────

class _VerseBookmarkButton extends ConsumerWidget {
  final String chapterRef;
  final int readingDay;

  const _VerseBookmarkButton({
    required this.chapterRef,
    required this.readingDay,
  });

  (String, int) get _parsed {
    final parts = chapterRef.trim().split(' ');
    final chapter = int.tryParse(parts.last) ?? 1;
    final book = parts.sublist(0, parts.length - 1).join(' ');
    return (book, chapter);
  }

  void _showPicker(BuildContext context, WidgetRef ref) {
    final (book, chapter) = _parsed;
    final verses = BibleService.instance.getChapter(book, chapter);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Icon(Icons.favorite_rounded,
                      color: Color(0xFFEF4444), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Save a verse from $chapterRef',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),
            Expanded(
              child: verses.isEmpty
                  ? const Center(child: Text('Open the reader to load verses'))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: verses.length,
                      itemBuilder: (context, i) {
                        final verseNum = i + 1;
                        final highlighted = ref
                            .read(verseHighlightsProvider.notifier)
                            .isHighlighted(book, chapter, verseNum);
                        return ListTile(
                          leading: Text(
                            '$verseNum',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: highlighted
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF4F46E5),
                            ),
                          ),
                          title: Text(
                            BibleService.cleanText(verses[i]),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                          trailing: highlighted
                              ? const Icon(Icons.favorite_rounded,
                                  color: Color(0xFFEF4444), size: 18)
                              : null,
                          onTap: () async {
                            Navigator.pop(context);
                            await ref
                                .read(verseHighlightsProvider.notifier)
                                .toggle(
                                  book: book,
                                  chapter: chapter,
                                  verse: verseNum,
                                  verseText: BibleService.cleanText(verses[i]),
                                );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.favorite_border_rounded, size: 18),
      color: const Color(0xFFEF4444),
      tooltip: 'Save a verse',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      onPressed: () => _showPicker(context, ref),
    );
  }
}

class _ChapterCheckButton extends ConsumerWidget {
  final int chapterIndex;
  final bool isCurrentDay;
  final bool isPastDay;

  const _ChapterCheckButton({
    required this.chapterIndex,
    required this.isCurrentDay,
    required this.isPastDay,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Past days are implicitly fully read
    final checked = isPastDay ||
        (ref.watch(chapterProgressProvider).valueOrNull?.contains(chapterIndex) ?? false);

    return IconButton(
      icon: Icon(
        checked ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
        size: 22,
        color: checked
            ? const Color(0xFF22C55E)
            : Theme.of(context).colorScheme.outlineVariant,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      tooltip: checked ? 'Mark unread' : 'Mark as read',
      onPressed: isCurrentDay
          ? () => ref.read(chapterProgressProvider.notifier).toggle(chapterIndex)
          : null,
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _CircleIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Icon(icon,
              color: Theme.of(context).colorScheme.onSurface, size: 20),
        ),
      ),
    );
  }
}