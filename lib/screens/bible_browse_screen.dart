import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../data/bible_sections.dart';
import '../providers/book_groups_provider.dart';
import '../providers/chapter_progress_provider.dart';
import '../providers/reading_plan_provider.dart';
import '../utils/chapter_utils.dart';
import 'reader_screen.dart' show ReaderArgs;

// ── Args passed via go_router extra ───────────────────────────────────────────

class BibleBrowseArgs {
  final String? initialBook;
  final int? initialChapter;

  const BibleBrowseArgs({this.initialBook, this.initialChapter});
}

// ── Screen ─────────────────────────────────────────────────────────────────────

class BibleBrowseScreen extends ConsumerStatefulWidget {
  final BibleBrowseArgs? args;

  const BibleBrowseScreen({super.key, this.args});

  @override
  ConsumerState<BibleBrowseScreen> createState() => _BibleBrowseScreenState();
}

class _BibleBrowseScreenState extends ConsumerState<BibleBrowseScreen> {
  late String _selectedBook;
  late int _selectedChapter;

  @override
  void initState() {
    super.initState();
    _selectedBook = widget.args?.initialBook ?? 'Genesis';
    _selectedChapter = widget.args?.initialChapter ?? 1;
    // Clamp chapter to valid range for the initial book
    _selectedChapter = _selectedChapter.clamp(1, _chaptersFor(_selectedBook));
  }

  int _chaptersFor(String bookName) {
    try {
      return allBibleBooks
          .firstWhere((b) => b.name == bookName)
          .chapters ?? 1;
    } catch (_) {
      return 1;
    }
  }

  void _onBookChanged(String? book) {
    if (book == null) return;
    final maxCh = _chaptersFor(book);
    setState(() {
      _selectedBook = book;
      _selectedChapter = _selectedChapter.clamp(1, maxCh);
    });
  }

  void _readChapter() {
    context.push(
      '/reader',
      extra: ReaderArgs(
        dayChapters: ['$_selectedBook $_selectedChapter'],
        initialIndex: 0,
        readingDay: -1, // free-read — no day tracking
      ),
    );
  }

  void _jumpToNextUnread() {
    final plan = ref.read(readingPlanProvider).valueOrNull;
    final groups =
        ref.read(bookGroupsProvider).valueOrNull ?? defaultBookGroups;
    if (plan == null) return;

    final chapters = getChaptersForDay(plan.currentDay, groups);
    final progress = ref.read(chapterProgressProvider).valueOrNull ?? {};

    // Find first chapter not yet checked off
    int? nextIndex;
    for (int i = 0; i < chapters.length; i++) {
      if (!progress.contains(i)) {
        nextIndex = i;
        break;
      }
    }

    if (nextIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("All of today's chapters are complete!"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    context.push(
      '/reader',
      extra: ReaderArgs(
        dayChapters: chapters,
        initialIndex: nextIndex,
        readingDay: plan.currentDay,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxChapters = _chaptersFor(_selectedBook);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bible'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        children: [
          // ── Next Unread shortcut ───────────────────────────────────────────
          _NextUnreadCard(onTap: _jumpToNextUnread),
          const SizedBox(height: 32),

          // ── Browse section ─────────────────────────────────────────────────
          Text(
            'Browse',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
          ),
          const SizedBox(height: 16),

          // Book picker
          _SelectorLabel('Book'),
          const SizedBox(height: 8),
          _BookDropdown(
            selected: _selectedBook,
            onChanged: _onBookChanged,
          ),
          const SizedBox(height: 16),

          // Chapter picker
          _SelectorLabel('Chapter'),
          const SizedBox(height: 8),
          _ChapterDropdown(
            selected: _selectedChapter,
            max: maxChapters,
            onChanged: (ch) {
              if (ch != null) setState(() => _selectedChapter = ch);
            },
          ),
          const SizedBox(height: 28),

          FilledButton.icon(
            onPressed: _readChapter,
            icon: const Icon(Icons.auto_stories_rounded),
            label: Text('Read $_selectedBook $_selectedChapter'),
          ),
        ],
      ),
    );
  }
}

// ── Next unread card ───────────────────────────────────────────────────────────

class _NextUnreadCard extends ConsumerWidget {
  final VoidCallback onTap;

  const _NextUnreadCard({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(readingPlanProvider).valueOrNull;
    final groups =
        ref.watch(bookGroupsProvider).valueOrNull ?? defaultBookGroups;
    final progress = ref.watch(chapterProgressProvider).valueOrNull ?? {};

    if (plan == null) return const SizedBox.shrink();

    final chapters = getChaptersForDay(plan.currentDay, groups);
    final totalRead = progress.where((i) => i < chapters.length).length;
    final allDone = totalRead >= chapters.length;

    String subtitle;
    if (allDone) {
      subtitle = "All of today's chapters complete!";
    } else {
      // Find next unread
      final nextIndex = List.generate(chapters.length, (i) => i)
          .firstWhere((i) => !progress.contains(i), orElse: () => 0);
      subtitle = 'Up next: ${chapters[nextIndex]}';
    }

    return GestureDetector(
      onTap: allDone ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: allDone
              ? const Color(0xFF22C55E).withValues(alpha: 0.08)
              : AppTheme.primary.withValues(alpha: 0.06),
          border: Border.all(
            color: allDone
                ? const Color(0xFF22C55E).withValues(alpha: 0.3)
                : AppTheme.primary.withValues(alpha: 0.25),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: allDone
                    ? const Color(0xFF22C55E).withValues(alpha: 0.12)
                    : AppTheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                allDone
                    ? Icons.check_circle_rounded
                    : Icons.play_circle_rounded,
                color: allDone ? const Color(0xFF22C55E) : AppTheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    allDone
                        ? "Today's Reading Complete"
                        : 'Continue Today — Day ${plan.currentDay}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: allDone
                              ? const Color(0xFF22C55E)
                              : AppTheme.primary,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 6),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: chapters.isEmpty
                          ? 0
                          : totalRead / chapters.length,
                      backgroundColor:
                          Theme.of(context).colorScheme.outlineVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        allDone
                            ? const Color(0xFF22C55E)
                            : AppTheme.primary,
                      ),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalRead / ${chapters.length} chapters',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            if (!allDone) ...[
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: AppTheme.textSecondary),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _SelectorLabel extends StatelessWidget {
  final String text;
  const _SelectorLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
    );
  }
}

class _BookDropdown extends StatelessWidget {
  final String selected;
  final ValueChanged<String?> onChanged;

  const _BookDropdown({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: selected,
      isExpanded: true,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: allBibleBooks
          .map((b) => DropdownMenuItem(value: b.name, child: Text(b.name)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _ChapterDropdown extends StatelessWidget {
  final int selected;
  final int max;
  final ValueChanged<int?> onChanged;

  const _ChapterDropdown({
    required this.selected,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = selected.clamp(1, max);
    return DropdownButtonFormField<int>(
      initialValue: clamped,
      isExpanded: true,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: List.generate(
        max,
        (i) => DropdownMenuItem(
          value: i + 1,
          child: Text('Chapter ${i + 1}'),
        ),
      ),
      onChanged: onChanged,
    );
  }
}