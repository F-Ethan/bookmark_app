import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/leaderboard_entry.dart';
import '../models/reading_plan.dart';
import '../models/book_group.dart';
import '../models/supporter.dart';

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

  static Future<void> updateReadingStats(
    String planId, {
    required int currentStreak,
    required int longestStreak,
    required int highestDayReached,
    required DateTime lastActiveDate,
  }) async {
    await _client.from('reading_plans').update({
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'highest_day_reached': highestDayReached,
      'last_active_date':
          lastActiveDate.toIso8601String().split('T').first, // date only
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', planId);
  }

  static Future<void> updateLeaderboardOptIn(
    String planId, {
    required bool optIn,
    required String? displayName,
  }) async {
    await _client.from('reading_plans').update({
      'leaderboard_opt_in': optIn,
      'leaderboard_display_name': displayName,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', planId);
  }

  // ── Leaderboard (anonymized to display name + stats only — see
  // supabase/migrations/0004_reading_stats.sql) ──────────────────────────────

  static Future<List<LeaderboardEntry>> fetchLeaderboard({
    required String sortBy, // 'longest_streak' | 'highest_day_reached'
    int limit = 50,
  }) async {
    final data = await _client.rpc('get_leaderboard', params: {
      'p_sort_by': sortBy,
      'p_limit': limit,
    });
    return (data as List)
        .map((j) => LeaderboardEntry.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  // ── Supporters ────────────────────────────────────────────────────────────

  static Future<List<Supporter>> fetchSupporters() async {
    final data = await _client
        .from('supporters')
        .select()
        .eq('active', true)
        .order('sort_order');
    return (data as List)
        .map((j) => Supporter.fromJson(j as Map<String, dynamic>))
        .toList();
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

  // ── Chapter progress ─────────────────────────────────────────────────────────

  static Future<Set<int>> fetchChapterProgress(int day) async {
    final data = await _client
        .from('chapter_progress')
        .select('chapter_index')
        .eq('user_id', _userId)
        .eq('day', day);
    return (data as List)
        .map((row) => row['chapter_index'] as int)
        .toSet();
  }

  static Future<void> setChapterRead(
      int day, int chapterIndex, bool read) async {
    if (read) {
      await _client.from('chapter_progress').upsert(
        {
          'user_id': _userId,
          'day': day,
          'chapter_index': chapterIndex,
        },
        onConflict: 'user_id,day,chapter_index',
      );
    } else {
      await _client
          .from('chapter_progress')
          .delete()
          .eq('user_id', _userId)
          .eq('day', day)
          .eq('chapter_index', chapterIndex);
    }
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
