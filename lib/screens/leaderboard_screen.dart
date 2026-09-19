import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../models/leaderboard_entry.dart';
import '../services/supabase_service.dart';

enum _LeaderboardSort { streak, highestDay }

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  _LeaderboardSort _sort = _LeaderboardSort.streak;
  late Future<List<LeaderboardEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<List<LeaderboardEntry>> _fetch() => SupabaseService.fetchLeaderboard(
        sortBy: _sort == _LeaderboardSort.streak
            ? 'longest_streak'
            : 'highest_day_reached',
      );

  void _selectSort(_LeaderboardSort sort) {
    if (sort == _sort) return;
    setState(() {
      _sort = sort;
      _future = _fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              children: [
                Expanded(
                  child: _SortTab(
                    label: 'Longest Streak',
                    icon: Icons.local_fire_department_rounded,
                    selected: _sort == _LeaderboardSort.streak,
                    onTap: () => _selectSort(_LeaderboardSort.streak),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SortTab(
                    label: 'Highest Day',
                    icon: Icons.emoji_events_rounded,
                    selected: _sort == _LeaderboardSort.highestDay,
                    onTap: () => _selectSort(_LeaderboardSort.highestDay),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<LeaderboardEntry>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _LeaderboardMessage(
                    text: 'Could not load the leaderboard. Check your connection.',
                  );
                }
                final entries = snapshot.data ?? [];
                if (entries.isEmpty) {
                  return const _LeaderboardMessage(
                    text: "No one has joined the leaderboard yet. Opt in from "
                        'Settings to be the first!',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final entry = entries[i];
                    final statValue = _sort == _LeaderboardSort.streak
                        ? entry.longestStreak
                        : entry.highestDayReached;
                    final statLabel = _sort == _LeaderboardSort.streak
                        ? 'day streak'
                        : 'highest day';
                    return _LeaderboardTile(
                      rank: i + 1,
                      entry: entry,
                      statValue: statValue,
                      statLabel: statLabel,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardMessage extends StatelessWidget {
  final String text;
  const _LeaderboardMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppTheme.textSecondary),
        ),
      ),
    );
  }
}

class _SortTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SortTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.10)
              : Theme.of(context).colorScheme.surfaceContainerLow,
          border: Border.all(
            color: selected
                ? AppTheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 18,
                color: selected ? AppTheme.primary : AppTheme.textSecondary),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected
                    ? AppTheme.primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final int rank;
  final LeaderboardEntry entry;
  final int statValue;
  final String statLabel;

  const _LeaderboardTile({
    required this.rank,
    required this.entry,
    required this.statValue,
    required this.statLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = entry.isMe;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isMe
            ? AppTheme.primary.withValues(alpha: 0.08)
            : Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border.all(
          color: isMe
              ? AppTheme.primary.withValues(alpha: 0.4)
              : Theme.of(context).colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Text(
              '$rank',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: rank <= 3
                    ? const Color(0xFFF59E0B)
                    : AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              entry.displayName,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'You',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
          const SizedBox(width: 10),
          Text(
            '$statValue',
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: AppTheme.primary),
          ),
          const SizedBox(width: 4),
          Text(statLabel,
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
