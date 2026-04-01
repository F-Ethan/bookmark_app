import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../core/constants/app_constants.dart';

class BibleService {
  static final BibleService instance = BibleService._();
  BibleService._();

  // book name → chapters (0-indexed) → verse texts (0-indexed)
  Map<String, List<List<String>>>? _bible;
  String? _loadedTranslation;

  // Maps translation key → actual filename (without .json)
  static const _fileNames = {
    'kjv': 'en_kjv',
    'bbe': 'en_bbe',
  };

  static const _bundledTranslation = 'kjv';

  /// Call once at startup with the user's saved translation preference.
  Future<void> initialize(String translation) async {
    if (_loadedTranslation == translation && _bible != null) return;
    final file = await _fileForTranslation(translation);
    if (!await file.exists()) {
      if (translation != _bundledTranslation) {
        // File not downloaded yet — silently fall back to bundled KJV
        await initialize(_bundledTranslation);
        return;
      }
      await _copyBundledAsset(translation);
    }
    await _loadFromFile(file);
    _loadedTranslation = translation;
  }

  /// Returns all verse texts for a chapter (chapter is 1-indexed).
  /// Returns an empty list if the Bible isn't loaded yet.
  List<String> getChapter(String book, int chapter) {
    return _bible?[book]?[chapter - 1] ?? [];
  }

  bool get isLoaded => _bible != null;
  String? get loadedTranslation => _loadedTranslation;

  Future<bool> isTranslationDownloaded(String translation) async {
    if (translation == _bundledTranslation) return true; // always available
    final file = await _fileForTranslation(translation);
    return file.exists();
  }

  // ── Download a translation from Supabase Storage ───────────────────────────

  Future<void> downloadTranslation(
    String translation, {
    void Function(double progress)? onProgress,
  }) async {
    final fileName = _fileNames[translation];
    if (fileName == null) throw Exception('Unknown translation: $translation');

    final url =
        '${AppConstants.supabaseUrl}/storage/v1/object/public/bibles/$fileName.json';
    final file = await _fileForTranslation(translation);
    await file.parent.create(recursive: true);

    await Dio().download(
      url,
      file.path,
      onReceiveProgress: (received, total) {
        if (total > 0) onProgress?.call(received / total);
      },
    );
  }

  /// Deletes a downloaded translation file.
  /// If the user switches back to KJV it is re-copied from the bundle —
  /// no re-download needed.
  Future<void> deleteTranslation(String translation) async {
    final file = await _fileForTranslation(translation);
    if (await file.exists()) await file.delete();
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Future<File> _fileForTranslation(String translation) async {
    final fileName = _fileNames[translation] ?? translation;
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/bibles/$fileName.json');
  }

  Future<void> _copyBundledAsset(String translation) async {
    if (translation != _bundledTranslation) {
      throw Exception(
          'No bundled file for "$translation". Download it first.');
    }
    final fileName = _fileNames[translation]!;
    final data = await rootBundle.loadString('assets/bibles/$fileName.json');
    final file = await _fileForTranslation(translation);
    await file.parent.create(recursive: true);
    await file.writeAsString(data);
  }

  Future<void> _loadFromFile(File file) async {
    final jsonStr = await file.readAsString();
    final List<dynamic> raw = json.decode(jsonStr);

    final result = <String, List<List<String>>>{};
    for (final book in raw) {
      final name = book['name'] as String;
      final chapters = (book['chapters'] as List)
          .map((ch) => (ch as List).map((v) => v.toString()).toList())
          .toList();
      result[name] = chapters;
    }
    _bible = result;
  }

  /// Returns plain text with translator markers stripped — use for saving/previewing.
  static String cleanText(String text) =>
      text.replaceAll('{', '').replaceAll('}', '');

  /// Parses translator-added word markers ({word}) into italic spans for display.
  /// Words inside {} are rendered in italic; everything else uses [baseStyle].
  static List<InlineSpan> buildSpans(String text, TextStyle baseStyle) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'\{([^}]*)\}');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: baseStyle,
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: baseStyle.copyWith(fontStyle: FontStyle.italic),
      ));
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: baseStyle));
    }

    // No markers — return the whole text unstyled
    if (spans.isEmpty) {
      spans.add(TextSpan(text: text, style: baseStyle));
    }

    return spans;
  }
}
