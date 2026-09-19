import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Occasionally asks happy users to rate the app, tied to streak milestones
/// rather than a blind timer — asks at a moment the user is likely feeling
/// good about the app. iOS/Android themselves also rate-limit the native
/// prompt (and don't report back whether it actually showed); this is a
/// belt-and-suspenders local throttle on top of that so repeated calls never
/// feel naggy even across many milestone hits.
class ReviewPromptService {
  static const _milestones = {7, 30, 100};
  static const _maxPrompts = 3;
  static const _minGapBetweenPrompts = Duration(days: 60);

  static const _lastPromptKey = 'review_prompt_last_date';
  static const _promptCountKey = 'review_prompt_count';

  static Future<void> maybeShowPrompt(int currentStreak) async {
    if (!_milestones.contains(currentStreak)) return;

    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_promptCountKey) ?? 0;
    if (count >= _maxPrompts) return;

    final lastStr = prefs.getString(_lastPromptKey);
    if (lastStr != null) {
      final last = DateTime.parse(lastStr);
      if (DateTime.now().difference(last) < _minGapBetweenPrompts) return;
    }

    final inAppReview = InAppReview.instance;
    if (!await inAppReview.isAvailable()) return;

    await inAppReview.requestReview();
    await prefs.setString(_lastPromptKey, DateTime.now().toIso8601String());
    await prefs.setInt(_promptCountKey, count + 1);
  }
}
