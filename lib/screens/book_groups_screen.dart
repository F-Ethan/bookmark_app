import 'package:flutter/material.dart';
import '../data/bible_sections.dart';
import '../services/shared_prefs_service.dart'; // NEW: For persistence
import '../models/book_group.dart';

class BookGroupsScreen extends StatefulWidget {
  const BookGroupsScreen({super.key});

  @override
  State<BookGroupsScreen> createState() => _BookGroupsScreenState();
}

class _BookGroupsScreenState extends State<BookGroupsScreen> {
  List<BibleGroup> groups = [];

  @override
  void initState() {
    super.initState();
    _loadGroups(); // NEW: Load custom or defaults
  }

  Future<void> _loadGroups() async {
    final customGroups = await SharedPrefsService.loadGroups();
    setState(() {
      groups = customGroups.isNotEmpty
          ? customGroups
          : List.from(defaultBookGroups);
    });
  }

  Future<void> _saveGroups() async {
    await SharedPrefsService.saveGroups(groups);
  }

  void _addGroup() {
    setState(() {
      groups.add(BibleGroup(name: 'New Group', books: []));
    });
    _saveGroups(); // NEW: Persist immediately
  }

  Future<void> _removeGroup(int index) async {
    // NEW: Confirmation dialog
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
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        groups.removeAt(index);
      });
      await _saveGroups(); // Persist
    }
  }

  void _editGroup(int index) {
    final group = groups[index];
    final selectedBooks = <String>{}; // Track selected names
    for (final book in group.books) {
      selectedBooks.add(book.name);
    }

    final TextEditingController nameController = TextEditingController(
      text: group.name,
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Group'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400, // Increased for better scroll
              child: SingleChildScrollView(
                // NEW: Ensures dialog scrolls if many books
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Group Name',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        // Update name in real-time
                        setState(() {
                          groups[index] = BibleGroup(
                            name: value,
                            books: group.books,
                          );
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Select Books:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 300,
                      child: ListView.builder(
                        itemCount: allBibleBooks.length,
                        itemBuilder: (context, bookIndex) {
                          final book = allBibleBooks[bookIndex];
                          final isSelected = selectedBooks.contains(book.name);
                          return CheckboxListTile(
                            title: Text(book.name),
                            value: isSelected,
                            onChanged: (bool? value) {
                              setDialogState(() {
                                if (value == true) {
                                  selectedBooks.add(book.name);
                                } else {
                                  selectedBooks.remove(book.name);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Revert name on cancel
                  setState(() {
                    groups[index] = BibleGroup(
                      name: nameController.text,
                      books: group.books,
                    );
                  });
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Save: Filter allBibleBooks by selected names
                  final updatedBooks = allBibleBooks
                      .where((book) => selectedBooks.contains(book.name))
                      .toList();
                  setState(() {
                    groups[index] = BibleGroup(
                      name: nameController.text,
                      books: updatedBooks,
                    );
                  });
                  _saveGroups(); // NEW: Persist
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    ).then((_) => nameController.dispose()); // Clean up
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addGroup,
            tooltip: 'Add Group',
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: Text(group.name),
              subtitle: Text(
                group.books.isEmpty
                    ? 'No books yet'
                    : group.books.map((b) => b.name).join(', '),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _removeGroup(index),
              ),
              onTap: () => _editGroup(index), // Tap to edit
            ),
          );
        },
      ),
    );
  }
}
