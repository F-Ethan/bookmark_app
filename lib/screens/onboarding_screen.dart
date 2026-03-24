import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../data/bible_sections.dart';
import '../models/book_group.dart';
import '../providers/book_groups_provider.dart';
import '../providers/reading_plan_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();
  late List<BibleGroup> _groups;
  int _currentPage = 0;
  int _startDay = 1;
  bool _loading = false;
  String? _error;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _groups = List.from(defaultBookGroups);
  }

  static const int _totalPages = 3;

  void _nextPage() {
    if (_currentPage == 0 && _nameController.text.trim().isEmpty) {
      setState(() => _nameError = 'Please enter your name to continue.');
      return;
    }
    setState(() {
      _nameError = null;
      _currentPage++;
    });
  }

  void _prevPage() => setState(() => _currentPage--);

  Future<void> _finish() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(readingPlanProvider.notifier).create(
            name: _nameController.text.trim(),
            startDay: _startDay,
          );
      await ref.read(bookGroupsProvider.notifier).setGroups(_groups);
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not save. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: List.generate(_totalPages, (i) {
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 4,
                      margin: EdgeInsets.only(
                          right: i < _totalPages - 1 ? 6 : 0),
                      decoration: BoxDecoration(
                        color: i <= _currentPage
                            ? AppTheme.primary
                            : Theme.of(context).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: switch (_currentPage) {
                0 => _WelcomePage(
                    nameController: _nameController,
                    nameError: _nameError,
                    onNext: _nextPage,
                  ),
                1 => _BookGroupsPage(
                    groups: _groups,
                    onGroupsChanged: (updated) =>
                        setState(() => _groups = updated),
                    onNext: _nextPage,
                    onBack: _prevPage,
                  ),
                _ => _StartDayPage(
                    startDay: _startDay,
                    onDayChanged: (d) => setState(() => _startDay = d),
                    onBack: _prevPage,
                    onFinish: _finish,
                    loading: _loading,
                    error: _error,
                  ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Page 1: Welcome ──────────────────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  final TextEditingController nameController;
  final String? nameError;
  final VoidCallback onNext;

  const _WelcomePage({
    required this.nameController,
    required this.onNext,
    this.nameError,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: AppTheme.primary,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Welcome to Bookmark',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: AppTheme.textPrimary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            "Bookmark helps you stay consistent with your Bible reading. "
            "It's built around Horner's Bible Reading System — read one "
            "chapter from each of 10 groups every day, cycling through "
            "the whole Bible at different paces.",
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: AppTheme.textSecondary, height: 1.55),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              border: Border.all(
                  color: nameError != null
                      ? AppTheme.danger
                      : Theme.of(context).colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Before we begin',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.5,
                      ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration:
                      const InputDecoration(labelText: "What's your name?"),
                ),
                if (nameError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    nameError!,
                    style: const TextStyle(
                        color: AppTheme.danger, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: onNext,
            child: const Text('Get Started'),
          ),
        ],
      ),
    );
  }
}

// ─── Page 2: Book Groups ──────────────────────────────────────────────────────

class _BookGroupsPage extends StatelessWidget {
  final List<BibleGroup> groups;
  final ValueChanged<List<BibleGroup>> onGroupsChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _BookGroupsPage({
    required this.groups,
    required this.onGroupsChanged,
    required this.onNext,
    required this.onBack,
  });

  void _editGroup(BuildContext context, int index) {
    final group = groups[index];
    final selectedBooks = <String>{for (final b in group.books) b.name};
    final nameController = TextEditingController(text: group.name);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Group'),
          content: SizedBox(
            width: double.maxFinite,
            height: 460,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration:
                      const InputDecoration(labelText: 'Group Name'),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select Books',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: allBibleBooks.length,
                    itemBuilder: (context, bookIndex) {
                      final book = allBibleBooks[bookIndex];
                      return CheckboxListTile(
                        title: Text(book.name),
                        value: selectedBooks.contains(book.name),
                        activeColor: AppTheme.primary,
                        onChanged: (value) => setDialogState(() {
                          if (value == true) {
                            selectedBooks.add(book.name);
                          } else {
                            selectedBooks.remove(book.name);
                          }
                        }),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final updatedBooks = allBibleBooks
                    .where((b) => selectedBooks.contains(b.name))
                    .toList();
                final updated = List<BibleGroup>.from(groups);
                updated[index] = BibleGroup(
                  name: nameController.text.trim().isEmpty
                      ? group.name
                      : nameController.text.trim(),
                  books: updatedBooks,
                );
                onGroupsChanged(updated);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    ).then((_) => nameController.dispose());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Reading Groups',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: AppTheme.textPrimary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                "Tap any group to customize which books it includes. "
                "Drag the handle to reorder. You can always adjust these later from the app.",
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppTheme.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            buildDefaultDragHandles: false,
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex--;
              final updated = List<BibleGroup>.from(groups);
              final item = updated.removeAt(oldIndex);
              updated.insert(newIndex, item);
              onGroupsChanged(updated);
            },
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              final bookNames = group.books.isEmpty
                  ? 'No books selected'
                  : group.books.map((b) => b.name).join(', ');
              return Padding(
                key: ValueKey(group.name + index.toString()),
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => _editGroup(context, index),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                bookNames,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppTheme.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.edit_rounded,
                            size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 8),
                        ReorderableDragStartListener(
                          index: index,
                          child: const Icon(
                            Icons.drag_handle_rounded,
                            color: AppTheme.textSecondary,
                            size: 20,
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
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Row(
            children: [
              OutlinedButton(
                onPressed: onBack,
                child: const Text('Back'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: onNext,
                  child: const Text('Looks Good'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Page 3: Start Day ────────────────────────────────────────────────────────

class _StartDayPage extends StatelessWidget {
  final int startDay;
  final ValueChanged<int> onDayChanged;
  final VoidCallback onBack;
  final VoidCallback onFinish;
  final bool loading;
  final String? error;

  const _StartDayPage({
    required this.startDay,
    required this.onDayChanged,
    required this.onBack,
    required this.onFinish,
    required this.loading,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.today_rounded,
                color: AppTheme.primary,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Where are you starting?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: AppTheme.textPrimary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            "Starting at day 1 is perfect for new readers. "
            "If you've been reading for a while, set today's day number "
            "so your plan picks up right where you left off.",
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: AppTheme.textSecondary, height: 1.55),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  'Starting Day',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.5,
                      ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StepButton(
                      icon: Icons.remove_rounded,
                      onPressed: startDay > 1
                          ? () => onDayChanged(startDay - 1)
                          : null,
                    ),
                    const SizedBox(width: 32),
                    Text(
                      '$startDay',
                      style: Theme.of(context)
                          .textTheme
                          .displaySmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                    ),
                    const SizedBox(width: 32),
                    _StepButton(
                      icon: Icons.add_rounded,
                      onPressed: () => onDayChanged(startDay + 1),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  startDay == 1
                      ? 'Starting fresh — great choice!'
                      : 'Today will be counted as day $startDay',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppTheme.danger.withValues(alpha: 0.3)),
              ),
              child: Text(error!,
                  style: const TextStyle(
                      color: AppTheme.danger, fontSize: 14)),
            ),
          ],
          const SizedBox(height: 32),
          Row(
            children: [
              OutlinedButton(
                onPressed: loading ? null : onBack,
                child: const Text('Back'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: loading ? null : onFinish,
                  child: loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Start Reading'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _StepButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: onPressed != null
              ? AppTheme.primary.withValues(alpha: 0.10)
              : Theme.of(context)
                  .colorScheme
                  .outlineVariant
                  .withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: onPressed != null ? AppTheme.primary : AppTheme.textSecondary,
          size: 22,
        ),
      ),
    );
  }
}