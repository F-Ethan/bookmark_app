// Regression test for PROGRESS.md #10: resetToDefaults() used to persist an
// empty list for signed-in users and rely on a separate empty-list fallback
// to *display* Horner's defaults — the stored data never actually reflected
// what was shown. This exercises the same provider logic via the guest
// (local-storage) path, which shares the fixed resetToDefaults() code.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bookmark_new/data/bible_sections.dart';
import 'package:bookmark_new/providers/book_groups_provider.dart';
import 'package:bookmark_new/providers/guest_mode_provider.dart';
import 'package:bookmark_new/services/local_data_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('resetToDefaults persists the actual default groups, not an empty list', () async {
    final container = ProviderContainer(overrides: [
      guestModeProvider.overrideWith((ref) => true),
    ]);
    addTearDown(container.dispose);

    await container.read(bookGroupsProvider.future);
    await container.read(bookGroupsProvider.notifier).setGroups([]);
    await container.read(bookGroupsProvider.notifier).resetToDefaults();

    final persisted = await LocalDataService.fetchBookGroups();
    expect(persisted.length, defaultBookGroups.length);
    expect(
      persisted.map((g) => g.name).toList(),
      defaultBookGroups.map((g) => g.name).toList(),
    );
  });
}
