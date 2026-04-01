import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/bible_service.dart';

const kDefaultTranslation = 'kjv';
const kTranslationKey = 'bible_translation';

const translationLabels = {
  'kjv': 'KJV — King James Version',
  'bbe': 'BBE — Bible in Basic English',
};

class TranslationNotifier extends Notifier<String> {
  final String _initial;

  TranslationNotifier({String initial = kDefaultTranslation})
      : _initial = initial;

  @override
  String build() => _initial;

  /// Switch to a translation. Downloads it first if not already on device.
  /// On any failure, reverts to KJV and cleans up the partial download.
  Future<void> setTranslation(String translation) async {
    if (state == translation) return;
    try {
      if (!await BibleService.instance.isTranslationDownloaded(translation)) {
        await BibleService.instance.downloadTranslation(translation);
      }
      await BibleService.instance.initialize(translation);
      state = translation;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kTranslationKey, translation);
    } catch (e) {
      // Clean up any partial download so it won't be mistaken for complete
      await BibleService.instance.deleteTranslation(translation);
      // Revert to KJV
      await BibleService.instance.initialize(kDefaultTranslation);
      state = kDefaultTranslation;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kTranslationKey, kDefaultTranslation);
      rethrow;
    }
  }

  /// Delete a downloaded translation to free up space.
  /// Cannot delete KJV (always re-copied from bundle) or the active translation.
  Future<void> deleteTranslation(String translation) async {
    if (translation == 'kjv' || translation == state) return;
    await BibleService.instance.deleteTranslation(translation);
  }
}

final translationProvider = NotifierProvider<TranslationNotifier, String>(
  TranslationNotifier.new,
);
