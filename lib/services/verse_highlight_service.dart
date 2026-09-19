import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/trending_highlight.dart';
import '../models/verse_highlight.dart';

const _kLocalKey = 'guest_verse_highlights';

class VerseHighlightService {
  // ── Supabase ─────────────────────────────────────────────────────────────────

  static Future<List<VerseHighlight>> fetchForDay(int day) async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return [];
    final data = await client
        .from('verse_highlights')
        .select()
        .eq('reading_day', day)
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((j) => VerseHighlight.fromSupabase(j, userId))
        .toList();
  }

  static Future<VerseHighlight> add({
    required String book,
    required int chapter,
    required int verse,
    required String verseText,
    required String translation,
    required int readingDay,
  }) async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser!.id;
    final result = await client
        .from('verse_highlights')
        .insert({
          'user_id': userId,
          'book': book,
          'chapter': chapter,
          'verse': verse,
          'verse_text': verseText,
          'translation': translation,
          'reading_day': readingDay,
        })
        .select()
        .single();
    return VerseHighlight.fromSupabase(result, userId);
  }

  static Future<void> remove(String id) async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser!.id;
    // Scope by user_id client-side as defense in depth — the real boundary
    // must be a Supabase RLS policy (see supabase/migrations/) since a
    // malicious client could otherwise omit this filter entirely.
    await client
        .from('verse_highlights')
        .delete()
        .eq('id', id)
        .eq('user_id', userId);
  }

  /// Anonymized counts of how many distinct users highlighted each verse
  /// within [chapters] (the caller's current day's reading). Never exposes
  /// which user highlighted anything — see 0003_trending_highlights.sql.
  static Future<List<TrendingHighlight>> fetchTrending(
    List<(String book, int chapter)> chapters, {
    int limit = 5,
  }) async {
    final client = Supabase.instance.client;
    if (client.auth.currentUser == null || chapters.isEmpty) return [];
    final payload = chapters
        .map((c) => {'book': c.$1, 'chapter': c.$2})
        .toList();
    final data = await client.rpc('get_trending_highlights', params: {
      'p_chapters': payload,
      'p_limit': limit,
    });
    return (data as List)
        .map((j) => TrendingHighlight.fromRpc(j as Map<String, dynamic>))
        .toList();
  }

  // ── Local (guest mode) ────────────────────────────────────────────────────────

  static Future<List<VerseHighlight>> fetchLocalForDay(int day) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kLocalKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((j) => VerseHighlight.fromLocal(j as Map<String, dynamic>))
        .where((h) => h.readingDay == day)
        .toList();
  }

  static Future<VerseHighlight> addLocal({
    required String book,
    required int chapter,
    required int verse,
    required String verseText,
    required String translation,
    required int readingDay,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kLocalKey);
    final list =
        raw != null ? jsonDecode(raw) as List : <dynamic>[];

    final highlight = VerseHighlight(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      book: book,
      chapter: chapter,
      verse: verse,
      verseText: verseText,
      translation: translation,
      readingDay: readingDay,
      createdAt: DateTime.now(),
    );

    list.add(highlight.toJson());
    await prefs.setString(_kLocalKey, jsonEncode(list));
    return highlight;
  }

  static Future<void> removeLocal(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kLocalKey);
    if (raw == null) return;
    final list = (jsonDecode(raw) as List)
        .where((j) => (j as Map)['id'] != id)
        .toList();
    await prefs.setString(_kLocalKey, jsonEncode(list));
  }
}
