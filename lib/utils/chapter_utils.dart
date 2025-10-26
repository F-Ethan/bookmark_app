import '../data/bible_sections.dart';

/// Function to get the chapter for a given group
String? _getChapterForGroup(int day, BibleGroup group) {
  final books = group.books;

  // total number of chapters across all books in the group
  final totalChapters = books.fold<int>(0, (sum, b) => sum + (b.chapters ?? 0));
  if (totalChapters == 0) return null;

  // find which book/chapter corresponds to this day
  final effectiveDay = ((day - 1) % totalChapters) + 1;
  int cumulative = 0;

  for (final book in books) {
    final bookChapters = book.chapters ?? 0;
    if (effectiveDay <= cumulative + bookChapters) {
      final chapterNum = effectiveDay - cumulative;
      return '${book.name} $chapterNum';
    }
    cumulative += bookChapters;
  }

  return null;
}

/// Get all chapters for a given day (one per group)
List<String> getChaptersForDay(int day) {
  final List<String> chapters = [];

  for (final group in defaultBookGroups) {
    final chapter = _getChapterForGroup(day, group);
    if (chapter != null) {
      chapters.add(chapter);
    }
  }

  return chapters;
}



// import '../data/bible_sections.dart';

// String? getChapterForSection(int day, int sectionId) {
//   final section = bibleSections[sectionId];
//   if (section == null) return null;

//   final books = section['books'] as Map<String, int>;
//   final totalChapters = books.values.fold<int>(0, (sum, ch) => sum + ch);
//   if (totalChapters == 0) return null;

//   final effectiveDay = ((day - 1) % totalChapters) + 1;
//   int cumulative = 0;

//   for (final book in books.keys) {
//     final chaptersInBook = books[book]!;
//     if (effectiveDay <= cumulative + chaptersInBook) {
//       final chapterNum = effectiveDay - cumulative;
//       return '$book $chapterNum';
//     }
//     cumulative += chaptersInBook;
  
//   return null;
// }

// List<String> getChaptersForDay(int day) {
//   final List<String> chapters = [];
//   for (int i = 1; i <= bibleSections.length; i++) {
//     final chapter = getChapterForSection(day, i);
//     if (chapter != null) chapters.add(chapter);
//   }
//   return chapters;
// }