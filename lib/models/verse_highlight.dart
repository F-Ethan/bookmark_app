class VerseHighlight {
  final String id;
  final String book;
  final int chapter;
  final int verse;
  final String verseText;
  final String translation;
  final int readingDay;
  final DateTime createdAt;
  final bool isOwn;

  const VerseHighlight({
    required this.id,
    required this.book,
    required this.chapter,
    required this.verse,
    required this.verseText,
    required this.translation,
    required this.readingDay,
    required this.createdAt,
    this.isOwn = true,
  });

  String get reference => '$book $chapter:$verse';

  factory VerseHighlight.fromSupabase(
      Map<String, dynamic> json, String currentUserId) {
    return VerseHighlight(
      id: json['id'] as String,
      book: json['book'] as String,
      chapter: json['chapter'] as int,
      verse: json['verse'] as int,
      verseText: json['verse_text'] as String,
      translation: (json['translation'] as String?) ?? 'kjv',
      readingDay: json['reading_day'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      isOwn: json['user_id'] == currentUserId,
    );
  }

  factory VerseHighlight.fromLocal(Map<String, dynamic> json) {
    return VerseHighlight(
      id: json['id'] as String,
      book: json['book'] as String,
      chapter: json['chapter'] as int,
      verse: json['verse'] as int,
      verseText: json['verse_text'] as String,
      translation: (json['translation'] as String?) ?? 'kjv',
      readingDay: json['reading_day'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'book': book,
        'chapter': chapter,
        'verse': verse,
        'verse_text': verseText,
        'translation': translation,
        'reading_day': readingDay,
        'created_at': createdAt.toIso8601String(),
      };
}
