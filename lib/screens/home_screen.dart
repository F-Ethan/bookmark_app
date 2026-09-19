import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/supabase_error.dart';
import '../models/reading_plan.dart';
import '../models/trending_highlight.dart';
import '../models/verse_highlight.dart';
import '../providers/reading_plan_provider.dart';
import '../providers/verse_highlights_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(readingPlanProvider);

    ref.listen<AsyncValue<ReadingPlan?>>(readingPlanProvider, (_, next) {
      if (next is AsyncData && next.value == null) {
        context.go('/onboarding');
      }
    });

    return planAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => isSupabasePaused(e)
          ? const SupabasePausedScreen()
          : ErrorRetryView(
              error: e,
              onRetry: () => ref.invalidate(readingPlanProvider),
            ),
      data: (plan) {
        if (plan == null) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Bookmark')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            children: [
              // Greeting
              Text(
                'Welcome back, ${plan.name}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Day ${plan.currentDay} of your reading plan',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 28),

              // Today's highlights carousel
              const _HighlightsSection(),
              const SizedBox(height: 28),

              _NavTile(
                icon: Icons.menu_book_rounded,
                title: "Today's Reading",
                subtitle: 'Day ${plan.currentDay}',
                onTap: () => context.go('/daily'),
              ),
              const SizedBox(height: 12),
              _NavTile(
                icon: Icons.auto_stories_rounded,
                title: 'Bible',
                subtitle: 'Free read any book and chapter',
                iconColor: const Color(0xFF7C3AED),
                onTap: () => context.push('/bible'),
              ),
              const SizedBox(height: 12),
              _NavTile(
                icon: Icons.library_books_rounded,
                title: 'Book Groups',
                subtitle: 'Customise your reading groups',
                iconColor: const Color(0xFF0D9488),
                onTap: () => context.go('/bookgroups'),
              ),
              const SizedBox(height: 12),
              _NavTile(
                icon: Icons.emoji_events_rounded,
                title: 'Leaderboard',
                subtitle: 'Streaks from readers who opted in',
                iconColor: const Color(0xFFF59E0B),
                onTap: () => context.push('/leaderboard'),
              ),
              const SizedBox(height: 12),
              _NavTile(
                icon: Icons.settings_rounded,
                title: 'Settings',
                subtitle: 'Notifications, name, reading day',
                iconColor: AppTheme.textSecondary,
                onTap: () => context.go('/settings'),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Highlights section ─────────────────────────────────────────────────────────

/// A single highlight-carousel slide — either the user's own saved verse, or
/// an anonymized "N people also highlighted this" trending verse.
class _HighlightItem {
  final String book;
  final int chapter;
  final int verse;
  final String verseText;
  final VerseHighlight? own;
  final int? trendingCount;

  const _HighlightItem._({
    required this.book,
    required this.chapter,
    required this.verse,
    required this.verseText,
    this.own,
    this.trendingCount,
  });

  factory _HighlightItem.own(VerseHighlight h) => _HighlightItem._(
        book: h.book,
        chapter: h.chapter,
        verse: h.verse,
        verseText: h.verseText,
        own: h,
      );

  factory _HighlightItem.trending(TrendingHighlight t) => _HighlightItem._(
        book: t.book,
        chapter: t.chapter,
        verse: t.verse,
        verseText: t.verseText,
        trendingCount: t.highlightCount,
      );

  bool get isOwn => own != null;
  String get reference => '$book $chapter:$verse';
}

class _HighlightsSection extends ConsumerStatefulWidget {
  const _HighlightsSection();

  @override
  ConsumerState<_HighlightsSection> createState() => _HighlightsSectionState();
}

class _HighlightsSectionState extends ConsumerState<_HighlightsSection> {
  final _pageController = PageController(viewportFraction: 0.88);
  Timer? _autoplayTimer;
  int _pageCount = 0;
  int _currentPage = 0;

  static const _autoplayInterval = Duration(seconds: 7);

  void _syncAutoplay(int pageCount) {
    if (pageCount == _pageCount) return;
    _pageCount = pageCount;
    _autoplayTimer?.cancel();
    if (pageCount <= 1) return;
    _autoplayTimer = Timer.periodic(_autoplayInterval, (_) {
      if (!_pageController.hasClients || _pageCount <= 1) return;
      final next = ((_pageController.page ?? 0).round() + 1) % _pageCount;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void _pauseAutoplay() => _autoplayTimer?.cancel();

  void _resumeAutoplay() {
    final count = _pageCount;
    _pageCount = -1; // force _syncAutoplay to actually restart the timer
    _syncAutoplay(count);
  }

  @override
  void dispose() {
    _autoplayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ownAsync = ref.watch(verseHighlightsProvider);
    final trending = ref.watch(trendingHighlightsProvider).valueOrNull ?? [];

    return ownAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (own) {
        final ownRefs = own.map((h) => '${h.book} ${h.chapter}:${h.verse}').toSet();
        final items = <_HighlightItem>[
          ...own.map(_HighlightItem.own),
          ...trending
              .where((t) => !ownRefs.contains('${t.book} ${t.chapter}:${t.verse}'))
              .map(_HighlightItem.trending),
        ];

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _syncAutoplay(items.length);
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.favorite_rounded,
                    color: Color(0xFFEF4444), size: 16),
                const SizedBox(width: 8),
                Text(
                  'Highlights',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.3,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const _EmptyHighlights()
            else ...[
              SizedBox(
                height: 172,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is UserScrollNotification &&
                        notification.direction != ScrollDirection.idle) {
                      _pauseAutoplay();
                    } else if (notification is ScrollEndNotification) {
                      _resumeAutoplay();
                    }
                    return false;
                  },
                  child: PageView.builder(
                    controller: _pageController,
                    clipBehavior: Clip.none,
                    itemCount: items.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: _HighlightCard(item: items[i]),
                    ),
                  ),
                ),
              ),
              if (items.length > 1) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(items.length, (i) {
                    final isActive = i == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isActive ? 16 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppTheme.primary
                            : Theme.of(context).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ],
            ],
          ],
        );
      },
    );
  }
}

class _EmptyHighlights extends StatelessWidget {
  const _EmptyHighlights();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
            style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.favorite_border_rounded,
              color: AppTheme.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tap the ♥ on any verse while reading to save it here.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightCard extends ConsumerWidget {
  final _HighlightItem item;

  const _HighlightCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = item.isOwn
        ? [
            AppTheme.primary.withValues(alpha: isDark ? 0.32 : 0.14),
            AppTheme.primary.withValues(alpha: isDark ? 0.12 : 0.04),
          ]
        : [
            const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.28 : 0.12),
            const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.10 : 0.03),
          ];
    final accent = item.isOwn ? AppTheme.primary : const Color(0xFFF59E0B);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -6,
            top: -10,
            child: Icon(Icons.format_quote_rounded,
                size: 44, color: accent.withValues(alpha: 0.16)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.verseText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.45,
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                  overflow: TextOverflow.fade,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.reference,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (item.isOwn)
                    GestureDetector(
                      onTap: () => ref.read(verseHighlightsProvider.notifier).toggle(
                            book: item.own!.book,
                            chapter: item.own!.chapter,
                            verse: item.own!.verse,
                            verseText: item.own!.verseText,
                          ),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.favorite_rounded,
                            size: 14, color: Color(0xFFEF4444)),
                      ),
                    )
                  else
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_fire_department_rounded,
                              size: 12, color: accent),
                          const SizedBox(width: 3),
                          Text(
                            '${item.trendingCount}',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: accent,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Nav tile ───────────────────────────────────────────────────────────────────

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  const _NavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppTheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}
