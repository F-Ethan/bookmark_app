import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reading_plan.dart';
import '../models/book_group.dart';

class SupabaseService {
  static SupabaseClient get _client => Supabase.instance.client;
  static String get _userId => _client.auth.currentUser!.id;

  // ── Reading Plan ──────────────────────────────────────────────────────────

  static Future<ReadingPlan?> fetchReadingPlan() async {
    final data = await _client
        .from('reading_plans')
        .select()
        .eq('user_id', _userId)
        .maybeSingle();

    if (data == null) return null;
    return ReadingPlan.fromJson(data);
  }

  static Future<ReadingPlan> createReadingPlan({
    required String name,
    required int startDay,
    required DateTime startDate,
  }) async {
    final data = await _client
        .from('reading_plans')
        .insert({
          'user_id': _userId,
          'name': name,
          'current_day': startDay,
          'start_date': startDate.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    return ReadingPlan.fromJson(data);
  }

  static Future<void> updateCurrentDay(String planId, int day) async {
    await _client
        .from('reading_plans')
        .update({
          'current_day': day,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', planId);
  }

  static Future<void> updateProfile(
    String planId, {
    required String name,
    required int currentDay,
  }) async {
    await _client
        .from('reading_plans')
        .update({
          'name': name,
          'current_day': currentDay,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', planId);
  }

  static Future<void> deleteReadingPlan() async {
    await _client.from('reading_plans').delete().eq('user_id', _userId);
  }

  static Future<void> deleteAccount() async {
    await _client.rpc('delete_user');
  }

  // ── Book Groups ───────────────────────────────────────────────────────────

  static Future<List<BibleGroup>> fetchBookGroups() async {
    final data = await _client
        .from('book_groups')
        .select()
        .eq('user_id', _userId)
        .order('position');

    return (data as List).map((row) {
      final booksJson = row['books'] as List<dynamic>;
      final books = booksJson
          .map((b) => BibleBook(
                name: b['name'] as String,
                chapters: b['chapters'] as int?,
                singleChapter: b['singleChapter'] as int?,
              ))
          .toList();
      return BibleGroup(name: row['name'] as String, books: books);
    }).toList();
  }

  static Future<void> saveBookGroups(List<BibleGroup> groups) async {
    // Delete existing rows then re-insert (simplest correct approach)
    await _client.from('book_groups').delete().eq('user_id', _userId);

    if (groups.isEmpty) return;

    await _client.from('book_groups').insert(
      groups.asMap().entries.map((entry) {
        final i = entry.key;
        final g = entry.value;
        return {
          'user_id': _userId,
          'name': g.name,
          'books': g.books.map((b) => b.toJson()).toList(),
          'position': i,
          'updated_at': DateTime.now().toIso8601String(),
        };
      }).toList(),
    );
  }
}
