import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../data/bible_sections.dart';
import '../models/book_group.dart';
import '../providers/book_groups_provider.dart';

class BookGroupsScreen extends ConsumerWidget {
  const BookGroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(bookGroupsProvider);

    return groupsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (groups) => _BookGroupsBody(groups: groups),
    );
  }
}

class _BookGroupsBody extends ConsumerWidget {
  final List<BibleGroup> groups;

  const _BookGroupsBody({required this.groups});

  Future<void> _addGroup(WidgetRef ref) async {
    await ref
        .read(bookGroupsProvider.notifier)
        .addGroup(BibleGroup(name: 'New Group', books: []));
  }

  Future<void> _removeGroup(
      BuildContext context, WidgetRef ref, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group?'),
        content: Text(
          'This will remove "${groups[index].name}" and cannot be undone. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(bookGroupsProvider.notifier).removeGroup(index);
    }
  }

  void _editGroup(BuildContext context, WidgetRef ref, int index) {
    final group = groups[index];
    final selectedBooks = <String>{
      for (final book in group.books) book.name,
    };
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
                      final isSelected =
                          selectedBooks.contains(book.name);
                      return CheckboxListTile(
                        title: Text(book.name),
                        value: isSelected,
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
                ref.read(bookGroupsProvider.notifier).updateGroup(
                      index,
                      BibleGroup(
                        name: nameController.text,
                        books: updatedBooks,
                      ),
                    );
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
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Groups'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Add Group',
              onPressed: () => _addGroup(ref),
            ),
          ),
        ],
      ),
      body: groups.isEmpty
          ? Center(
              child: Text(
                'No groups yet. Tap + to add one.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppTheme.textSecondary),
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              buildDefaultDragHandles: false,
              onReorder: (oldIndex, newIndex) => ref
                  .read(bookGroupsProvider.notifier)
                  .reorderGroups(oldIndex, newIndex),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                final bookNames = group.books.isEmpty
                    ? 'No books yet'
                    : group.books.map((b) => b.name).join(', ');

                return Padding(
                  key: ValueKey(group.name + index.toString()),
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => _editGroup(context, ref, index),
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
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.primary
                                  .withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.library_books_rounded,
                              color: AppTheme.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  group.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                          fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  bookNames,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                          color: AppTheme.textSecondary),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: AppTheme.danger, size: 20),
                            tooltip: 'Delete group',
                            onPressed: () =>
                                _removeGroup(context, ref, index),
                          ),
                          ReorderableDragStartListener(
                            index: index,
                            child: const Icon(
                              Icons.drag_handle_rounded,
                              color: AppTheme.textSecondary,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}