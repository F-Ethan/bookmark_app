import '../models/book_group.dart';

class BibleBook {
  final String name;
  final int? chapters; // optional: for full books
  final int? singleChapter; // optional: for single-chapter selections

  BibleBook({required this.name, this.chapters, this.singleChapter});

  // For saving/loading to JSON later
  Map<String, dynamic> toJson() => {
    'name': name,
    'chapters': chapters,
    'singleChapter': singleChapter,
  };

  factory BibleBook.fromJson(Map<String, dynamic> json) {
    return BibleBook(
      name: json['name'],
      chapters: json['chapters'],
      singleChapter: json['singleChapter'],
    );
  }
}

class BibleGroup {
  String name;
  List<BibleBook> books;

  BibleGroup({required this.name, required this.books});

  Map<String, dynamic> toJson() => {
    'name': name,
    'books': books.map((b) => b.toJson()).toList(),
  };

  factory BibleGroup.fromJson(Map<String, dynamic> json) {
    return BibleGroup(
      name: json['name'],
      books: (json['books'] as List).map((b) => BibleBook.fromJson(b)).toList(),
    );
  }
}

final List<BibleGroup> defaultBookGroups = [
  BibleGroup(
    name: 'Genesis - Deuteronomy',
    books: [
      BibleBook(name: 'Genesis', chapters: 50),
      BibleBook(name: 'Exodus', chapters: 40),
      BibleBook(name: 'Leviticus', chapters: 27),
      BibleBook(name: 'Numbers', chapters: 36),
      BibleBook(name: 'Deuteronomy', chapters: 34),
    ],
  ),
  BibleGroup(
    name: 'Joshua - Esther',
    books: [
      BibleBook(name: 'Joshua', chapters: 24),
      BibleBook(name: 'Judges', chapters: 21),
      BibleBook(name: 'Ruth', chapters: 4),
      BibleBook(name: '1 Samuel', chapters: 31),
      BibleBook(name: '2 Samuel', chapters: 24),
      BibleBook(name: '1 Kings', chapters: 22),
      BibleBook(name: '2 Kings', chapters: 25),
      BibleBook(name: '1 Chronicles', chapters: 29),
      BibleBook(name: '2 Chronicles', chapters: 36),
      BibleBook(name: 'Ezra', chapters: 10),
      BibleBook(name: 'Nehemiah', chapters: 13),
      BibleBook(name: 'Esther', chapters: 10),
    ],
  ),
  BibleGroup(
    name: 'Job, Ecclesiastes, Song of Solomon',
    books: [
      BibleBook(name: 'Job', chapters: 42),
      BibleBook(name: 'Ecclesiastes', chapters: 12),
      BibleBook(name: 'Song of Solomon', chapters: 8),
    ],
  ),
  BibleGroup(
    name: 'Psalms',
    books: [BibleBook(name: 'Psalms', chapters: 150)],
  ),
  BibleGroup(
    name: 'Proverbs',
    books: [BibleBook(name: 'Proverbs', chapters: 31)],
  ),
  BibleGroup(
    name: 'Isaiah - Malachi',
    books: [
      BibleBook(name: 'Isaiah', chapters: 66),
      BibleBook(name: 'Jeremiah', chapters: 52),
      BibleBook(name: 'Lamentations', chapters: 5),
      BibleBook(name: 'Ezekiel', chapters: 48),
      BibleBook(name: 'Daniel', chapters: 12),
      BibleBook(name: 'Hosea', chapters: 14),
      BibleBook(name: 'Joel', chapters: 3),
      BibleBook(name: 'Amos', chapters: 9),
      BibleBook(name: 'Obadiah', chapters: 1),
      BibleBook(name: 'Jonah', chapters: 4),
      BibleBook(name: 'Micah', chapters: 7),
      BibleBook(name: 'Nahum', chapters: 3),
      BibleBook(name: 'Habakkuk', chapters: 3),
      BibleBook(name: 'Zephaniah', chapters: 3),
      BibleBook(name: 'Haggai', chapters: 2),
      BibleBook(name: 'Zechariah', chapters: 14),
      BibleBook(name: 'Malachi', chapters: 4),
    ],
  ),
  BibleGroup(
    name: 'Matthew - John',
    books: [
      BibleBook(name: 'Matthew', chapters: 28),
      BibleBook(name: 'Mark', chapters: 16),
      BibleBook(name: 'Luke', chapters: 24),
      BibleBook(name: 'John', chapters: 21),
    ],
  ),
  BibleGroup(
    name: 'Acts',
    books: [BibleBook(name: 'Acts', chapters: 28)],
  ),
  BibleGroup(
    name: 'Romans - Colossians, Hebrews',
    books: [
      BibleBook(name: 'Romans', chapters: 16),
      BibleBook(name: '1 Corinthians', chapters: 16),
      BibleBook(name: '2 Corinthians', chapters: 13),
      BibleBook(name: 'Galatians', chapters: 6),
      BibleBook(name: 'Ephesians', chapters: 6),
      BibleBook(name: 'Philippians', chapters: 4),
      BibleBook(name: 'Colossians', chapters: 4),
      BibleBook(name: 'Hebrews', chapters: 13),
    ],
  ),
  BibleGroup(
    name: '1 Thessalonians - Revelation',
    books: [
      BibleBook(name: '1 Thessalonians', chapters: 5),
      BibleBook(name: '2 Thessalonians', chapters: 3),
      BibleBook(name: '1 Timothy', chapters: 6),
      BibleBook(name: '2 Timothy', chapters: 4),
      BibleBook(name: 'Titus', chapters: 3),
      BibleBook(name: 'Philemon', chapters: 1),
      BibleBook(name: 'James', chapters: 5),
      BibleBook(name: '1 Peter', chapters: 5),
      BibleBook(name: '2 Peter', chapters: 3),
      BibleBook(name: '1 John', chapters: 5),
      BibleBook(name: '2 John', chapters: 1),
      BibleBook(name: '3 John', chapters: 1),
      BibleBook(name: 'Jude', chapters: 1),
      BibleBook(name: 'Revelation', chapters: 22),
    ],
  ),
];



// final Map<int, Map<String, dynamic>> bibleSections = {
//   1: {
//     "name": "Genesis - Deuteronomy",
//     "books": {
//       "Genesis": 50,
//       "Exodus": 40,
//       "Leviticus": 27,
//       "Numbers": 36,
//       "Deuteronomy": 34,
//     },
//   },
//   2: {
//     "name": "Joshua - Esther",
//     "books": {
//       "Joshua": 24,
//       "Judges": 21,
//       "Ruth": 4,
//       "1 Samuel": 31,
//       "2 Samuel": 24,
//       "1 Kings": 22,
//       "2 Kings": 25,
//       "1 Chronicles": 29,
//       "2 Chronicles": 36,
//       "Ezra": 10,
//       "Nehemiah": 13,
//       "Esther": 10,
//     },
//   },
//   3: {
//     "name": "Job, Ecclesiastes, Song of Solomon",
//     "books": {
//       "Job": 42,
//       "Ecclesiastes": 12,
//       "Song of Solomon": 8,
//     },
//   },
//   4: {
    // "name": "Psalms",
    // "books": {
    //   "Psalms": 150,
    // },
//   },
//   5: {
  //   "name": "Proverbs",
  //   "books": {
  //     "Proverbs": 31,
  //   },
  // },
//   6: {
    // "name": "Isaiah - Malachi",
    // "books": {
    //   "Isaiah": 66,
    //   "Jeremiah": 52,
    //   "Lamentations": 5,
    //   "Ezekiel": 48,
    //   "Daniel": 12,
    //   "Hosea": 14,
    //   "Joel": 3,
    //   "Amos": 9,
    //   "Obadiah": 1,
    //   "Jonah": 4,
    //   "Micah": 7,
    //   "Nahum": 3,
    //   "Habakkuk": 3,
    //   "Zephaniah": 3,
    //   "Haggai": 2,
    //   "Zechariah": 14,
    //   "Malachi": 4,
    // },
//   },
//   7: {
//     "name": "Matthew - John",
//     "books": {
//       "Matthew": 28,
//       "Mark": 16,
//       "Luke": 24,
//       "John": 21,
//     },
//   },
//   8: {
//     "name": "Acts",
//     "books": {
//       "Acts": 28,
//     },
//   },
  // 9: {
  //   "name": "Romans - Colossians, Hebrews",
  //   "books": {
  //     "Romans": 16,
  //     "1 Corinthians": 16,
  //     "2 Corinthians": 13,
  //     "Galatians": 6,
  //     "Ephesians": 6,
  //     "Philippians": 4,
  //     "Colossians": 4,
  //     "Hebrews": 13,
  //   },
//   },
//   10: {
//     "name": "1 Thessalonians - Revelation",
//     "books": {
//       "1 Thessalonians": 5,
//       "2 Thessalonians": 3,
//       "1 Timothy": 6,
//       "2 Timothy": 4,
//       "Titus": 3,
//       "Philemon": 1,
//       "James": 5,
//       "1 Peter": 5,
//       "2 Peter": 3,
//       "1 John": 5,
//       "2 John": 1,
//       "3 John": 1,
//       "Jude": 1,
//       "Revelation": 22,
//     },
//   },
// };