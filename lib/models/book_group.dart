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
