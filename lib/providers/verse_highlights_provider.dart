import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/verse_highlight.dart';
import '../providers/guest_mode_provider.dart';
import '../providers/reading_plan_provider.dart';
import '../providers/translation_provider.dart';
import '../services/verse_highlight_service.dart';

class VerseHighlightsNotifier
    extends AsyncNotifier<List<VerseHighlight>> {
  @override
  Future<List<VerseHighlight>> build() async {
    final plan = await ref.watch(readingPlanProvider.future);
    if (plan == null) return [];
    final isGuest = ref.watch(guestModeProvider);
    if (isGuest) {
      return VerseHighlightService.fetchLocalForDay(plan.currentDay);
    }
    return VerseHighlightService.fetchForDay(plan.currentDay);
  }

  /// Adds if not yet saved, removes if already saved (for own verses).
  Future<void> toggle({
    required String book,
    required int chapter,
    required int verse,
    required String verseText,
  }) async {
    final plan = ref.read(readingPlanProvider).valueOrNull;
    if (plan == null) return;

    final current = state.valueOrNull ?? [];
    final existing = current
        .where((h) =>
            h.book == book &&
            h.chapter == chapter &&
            h.verse == verse &&
            h.isOwn)
        .firstOrNull;

    final isGuest = ref.read(guestModeProvider);

    if (existing != null) {
      if (isGuest) {
        await VerseHighlightService.removeLocal(existing.id);
      } else {
        await VerseHighlightService.remove(existing.id);
      }
      state = AsyncData(
          current.where((h) => h.id != existing.id).toList());
    } else {
      final translation = ref.read(translationProvider);
      final VerseHighlight highlight;
      if (isGuest) {
        highlight = await VerseHighlightService.addLocal(
          book: book,
          chapter: chapter,
          verse: verse,
          verseText: verseText,
          translation: translation,
          readingDay: plan.currentDay,
        );
      } else {
        highlight = await VerseHighlightService.add(
          book: book,
          chapter: chapter,
          verse: verse,
          verseText: verseText,
          translation: translation,
          readingDay: plan.currentDay,
        );
      }
      state = AsyncData([highlight, ...current]);
    }
  }

  bool isHighlighted(String book, int chapter, int verse) {
    return state.valueOrNull
            ?.any((h) =>
                h.book == book &&
                h.chapter == chapter &&
                h.verse == verse &&
                h.isOwn) ??
        false;
  }
}

final verseHighlightsProvider =
    AsyncNotifierProvider<VerseHighlightsNotifier, List<VerseHighlight>>(
  VerseHighlightsNotifier.new,
);
