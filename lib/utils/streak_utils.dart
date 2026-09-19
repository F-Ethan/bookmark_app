DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Computes the updated (currentStreak, longestStreak) when a day is marked
/// read on [today], given the streak state as of [lastActiveDate].
///
/// - Marking read again on the same calendar day as [lastActiveDate] is a
///   no-op (catching up several days in one sitting shouldn't inflate the
///   streak).
/// - Exactly one calendar day later extends the streak.
/// - Any bigger gap (or no prior activity) resets it to 1.
(int currentStreak, int longestStreak) computeStreakUpdate({
  required DateTime today,
  required DateTime? lastActiveDate,
  required int currentStreak,
  required int longestStreak,
}) {
  final todayDate = _dateOnly(today);
  int newStreak;
  if (lastActiveDate == null) {
    newStreak = 1;
  } else {
    final gap = todayDate.difference(_dateOnly(lastActiveDate)).inDays;
    if (gap <= 0) {
      // Same day (or a clock-skew negative gap) — don't double count.
      newStreak = currentStreak == 0 ? 1 : currentStreak;
    } else if (gap == 1) {
      newStreak = currentStreak + 1;
    } else {
      newStreak = 1;
    }
  }
  final newLongest = newStreak > longestStreak ? newStreak : longestStreak;
  return (newStreak, newLongest);
}
