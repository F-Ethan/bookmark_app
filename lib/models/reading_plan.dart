class ReadingPlan {
  final String id;
  final String userId;
  final String name;
  final int currentDay;
  final DateTime startDate;

  // Reading-streak stats (see lib/utils/streak_utils.dart). Default to zero/
  // null for rows created before these columns existed (or for a guest plan
  // that hasn't completed a day yet).
  final int currentStreak;
  final int longestStreak;
  final int highestDayReached;
  final DateTime? lastActiveDate;

  // Leaderboard participation — deliberately separate from [name], which may
  // be the user's real name and is never shown publicly. Signed-in users
  // only; always false/null for a guest plan.
  final bool leaderboardOptIn;
  final String? leaderboardDisplayName;

  const ReadingPlan({
    required this.id,
    required this.userId,
    required this.name,
    required this.currentDay,
    required this.startDate,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.highestDayReached = 0,
    this.lastActiveDate,
    this.leaderboardOptIn = false,
    this.leaderboardDisplayName,
  });

  factory ReadingPlan.fromJson(Map<String, dynamic> json) {
    return ReadingPlan(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      currentDay: json['current_day'] as int,
      startDate: DateTime.parse(json['start_date'] as String),
      currentStreak: (json['current_streak'] as int?) ?? 0,
      longestStreak: (json['longest_streak'] as int?) ?? 0,
      highestDayReached: (json['highest_day_reached'] as int?) ?? 0,
      lastActiveDate: json['last_active_date'] != null
          ? DateTime.parse(json['last_active_date'] as String)
          : null,
      leaderboardOptIn: (json['leaderboard_opt_in'] as bool?) ?? false,
      leaderboardDisplayName: json['leaderboard_display_name'] as String?,
    );
  }

  ReadingPlan copyWith({
    String? id,
    String? userId,
    String? name,
    int? currentDay,
    DateTime? startDate,
    int? currentStreak,
    int? longestStreak,
    int? highestDayReached,
    DateTime? lastActiveDate,
    bool? leaderboardOptIn,
    String? leaderboardDisplayName,
  }) {
    return ReadingPlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      currentDay: currentDay ?? this.currentDay,
      startDate: startDate ?? this.startDate,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      highestDayReached: highestDayReached ?? this.highestDayReached,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      leaderboardOptIn: leaderboardOptIn ?? this.leaderboardOptIn,
      leaderboardDisplayName:
          leaderboardDisplayName ?? this.leaderboardDisplayName,
    );
  }
}
