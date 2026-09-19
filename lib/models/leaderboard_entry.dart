/// A single opted-in leaderboard row. Backed by the `get_leaderboard`
/// Postgres function (supabase/migrations/0004_reading_stats.sql), which
/// only ever returns what a user explicitly opted in to share — a chosen
/// display name and two counts. Never a user id, real name, or email.
class LeaderboardEntry {
  final String displayName;
  final int currentStreak;
  final int longestStreak;
  final int highestDayReached;
  final bool isMe;

  const LeaderboardEntry({
    required this.displayName,
    required this.currentStreak,
    required this.longestStreak,
    required this.highestDayReached,
    required this.isMe,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      displayName: json['display_name'] as String,
      currentStreak: (json['current_streak'] as num).toInt(),
      longestStreak: (json['longest_streak'] as num).toInt(),
      highestDayReached: (json['highest_day_reached'] as num).toInt(),
      isMe: json['is_me'] as bool? ?? false,
    );
  }
}
