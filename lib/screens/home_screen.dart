import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../models/reading_plan.dart';
import '../providers/reading_plan_provider.dart';

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
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (plan) {
        if (plan == null) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Bible Reading Plan')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            children: [
              // Greeting
              Text(
                'Welcome back, ${plan.name}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
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
              const SizedBox(height: 32),
              _NavTile(
                icon: Icons.menu_book_rounded,
                title: "Today's Reading",
                subtitle: 'Day ${plan.currentDay}',
                onTap: () => context.go('/daily'),
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