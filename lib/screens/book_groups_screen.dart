import 'package:flutter/material.dart';
import '../data/bible_sections.dart';

class BookGroupsScreen extends StatefulWidget {
  const BookGroupsScreen({super.key});

  @override
  State<BookGroupsScreen> createState() => _BookGroupsScreenState();
}

class _BookGroupsScreenState extends State<BookGroupsScreen> {
  List<BibleGroup> groups = List.from(defaultBookGroups);

  void _addGroup() {
    setState(() {
      groups.add(BibleGroup(name: 'New Group', books: []));
    });
  }

  void _removeGroup(int index) {
    setState(() {
      groups.removeAt(index);
    });
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
              onTap: () {
                // we'll later add editing for each group
              },
            ),
          );
        },
      ),
    );
  }
}
