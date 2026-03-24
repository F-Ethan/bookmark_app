import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/bible_service.dart';

const kDefaultTranslation = 'kjv';
const kTranslationKey = 'bible_translation';

const translationLabels = {
  'kjv': 'KJV — King James Version',
  'web': 'WEB — World English Bible',
  'asv': 'ASV — American Standard Version',
  'ylt': "YLT — Young's Literal Translation",
};

class TranslationNotifier extends Notifier<String> {
  final String _initial;

  TranslationNotifier({String initial = kDefaultTranslation})
      : _initial = initial;

  @override
  String build() => _initial;

  /// Switch to a translation. Downloads it first if not already on device.
  Future<void> setTranslation(String translation) async {
    if (state == translation) return;
    state = translation;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kTranslationKey, translation);
    // initialize() is a no-op if already loaded; downloads+loads if not
    await BibleService.instance.initialize(translation);
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
