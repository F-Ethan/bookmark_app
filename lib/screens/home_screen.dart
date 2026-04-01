import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/supabase_error.dart';
import '../models/reading_plan.dart';
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
          : Scaffold(body: Center(child: Text('Error: $e'))),
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

class _HighlightsSection extends ConsumerWidget {
  const _HighlightsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final highlightsAsync = ref.watch(verseHighlightsProvider);

    return highlightsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (highlights) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.favorite_rounded,
                    color: Color(0xFFEF4444), size: 16),
                const SizedBox(width: 8),
                Text(
                  "Today's Highlights",
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.3,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            highlights.isEmpty
                ? _EmptyHighlights()
                : SizedBox(
                    height: 148,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      itemCount: highlights.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, i) =>
                          _HighlightCard(highlight: highlights[i]),
                    ),
                  ),
          ],
        );
      },
    );
  }
}

class _EmptyHighlights extends StatelessWidget {
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
  final VerseHighlight highlight;

  const _HighlightCard({required this.highlight});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight.isOwn
            ? AppTheme.primary.withValues(alpha: 0.06)
            : Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border.all(
          color: highlight.isOwn
              ? AppTheme.primary.withValues(alpha: 0.25)
              : Theme.of(context).colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              highlight.verseText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.5,
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
                  highlight.reference,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              if (highlight.isOwn)
                GestureDetector(
                  onTap: () => ref
                      .read(verseHighlightsProvider.notifier)
                      .toggle(
                        book: highlight.book,
                        chapter: highlight.chapter,
                        verse: highlight.verse,
                        verseText: highlight.verseText,
                      ),
                  child: const Icon(Icons.favorite_rounded,
                      size: 14, color: Color(0xFFEF4444)),
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
