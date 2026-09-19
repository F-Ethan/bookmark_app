/// An anonymized, aggregated view of a verse other users have highlighted.
///
/// Deliberately carries no user identity — only a verse reference, its text
/// (public domain Bible text), and how many distinct users highlighted it.
/// Backed by the `get_trending_highlights` Postgres function
/// (supabase/migrations/0003_trending_highlights.sql), which aggregates
/// across all users server-side so the client never sees individual rows.
class TrendingHighlight {
  final String book;
  final int chapter;
  final int verse;
  final String verseText;
  final String translation;
  final int highlightCount;

  const TrendingHighlight({
    required this.book,
    required this.chapter,
    required this.verse,
    required this.verseText,
    required this.translation,
    required this.highlightCount,
  });

  String get reference => '$book $chapter:$verse';

  factory TrendingHighlight.fromRpc(Map<String, dynamic> json) {
    return TrendingHighlight(
      book: json['book'] as String,
      chapter: json['chapter'] as int,
      verse: json['verse'] as int,
      verseText: json['verse_text'] as String,
      translation: (json['translation'] as String?) ?? 'kjv',
      highlightCount: (json['highlight_count'] as num).toInt(),
    );
  }
}
