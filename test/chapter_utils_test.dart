// Locks in the Horner reading-plan cycling logic (lib/utils/chapter_utils.dart)
// that determines which chapters show up each day — the exact mechanism
// behind the "different reading every day" behavior that prompted the
// 2026-09-18 audit. That's intended behavior (see CLAUDE.md), but it should
// stay deterministic and correctly wrap each list at its own length.

import 'package:flutter_test/flutter_test.dart';
import 'package:bookmark_new/models/book_group.dart';
import 'package:bookmark_new/utils/chapter_utils.dart';

void main() {
  group('getChaptersForDay', () {
    final groups = [
      BibleGroup(name: 'A', books: [BibleBook(name: 'Alpha', chapters: 3)]),
      BibleGroup(name: 'B', books: [
        BibleBook(name: 'Beta', chapters: 2),
        BibleBook(name: 'Gamma', chapters: 2),
      ]),
    ];

    test('returns one chapter per group', () {
      expect(getChaptersForDay(1, groups), hasLength(2));
    });

    test('day 1 starts at chapter 1 of each group', () {
      expect(getChaptersForDay(1, groups), ['Alpha 1', 'Beta 1']);
    });

    test('advances one chapter per day within a group', () {
      expect(getChaptersForDay(2, groups), ['Alpha 2', 'Beta 2']);
      expect(getChaptersForDay(3, groups), ['Alpha 3', 'Gamma 1']);
    });

    test('wraps back to the start once a group is exhausted, at its own length', () {
      // Group A totals 3 chapters -> day 4 wraps back to Alpha 1.
      expect(getChaptersForDay(4, groups)[0], 'Alpha 1');
      // Group B totals 4 chapters (Beta 2 + Gamma 2) -> day 5 wraps to Beta 1.
      expect(getChaptersForDay(5, groups)[1], 'Beta 1');
    });

    test('is deterministic for the same day and groups', () {
      expect(getChaptersForDay(37, groups), equals(getChaptersForDay(37, groups)));
    });

    test('falls back to defaultBookGroups when groups is empty', () {
      expect(getChaptersForDay(1, const []), isNotEmpty);
    });
  });
}
