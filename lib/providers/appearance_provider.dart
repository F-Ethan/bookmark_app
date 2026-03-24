import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Option maps ────────────────────────────────────────────────────────────────

const themeModeOptions = {
  'system': 'System',
  'light': 'Light',
  'dark': 'Dark',
};

const fontOptions = {
  'default': 'Default',
  'lora': 'Lora',
  'merriweather': 'Merriweather',
  'garamond': 'EB Garamond',
};

const fontSizeOptions = {
  'small': 14.0,
  'medium': 17.0,
  'large': 20.0,
  'xlarge': 23.0,
};

const lineSpacingOptions = {
  'compact': 1.4,
  'normal': 1.65,
  'relaxed': 1.9,
};

// ── Settings model ─────────────────────────────────────────────────────────────

class AppearanceSettings {
  final String themeModeKey;
  final String fontKey;
  final String fontSizeKey;
  final String spacingKey;
  final bool justifyText;

  const AppearanceSettings({
    this.themeModeKey = 'system',
    this.fontKey = 'default',
    this.fontSizeKey = 'medium',
    this.spacingKey = 'normal',
    this.justifyText = false,
  });

  ThemeMode get themeMode => switch (themeModeKey) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  double get fontSize => fontSizeOptions[fontSizeKey] ?? 17.0;
  double get lineHeight => lineSpacingOptions[spacingKey] ?? 1.65;
  TextAlign get textAlign =>
      justifyText ? TextAlign.justify : TextAlign.left;

  /// Returns a TextStyle using the selected font family at the given size/height.
  TextStyle readerTextStyle({double? size, double? height}) {
    final s = size ?? fontSize;
    final h = height ?? lineHeight;
    return switch (fontKey) {
      'lora' => GoogleFonts.lora(fontSize: s, height: h),
      'merriweather' => GoogleFonts.merriweather(fontSize: s, height: h),
      'garamond' => GoogleFonts.ebGaramond(fontSize: s, height: h),
      _ => TextStyle(fontSize: s, height: h),
    };
  }

  AppearanceSettings copyWith({
    String? themeModeKey,
    String? fontKey,
    String? fontSizeKey,
    String? spacingKey,
    bool? justifyText,
  }) =>
      AppearanceSettings(
        themeModeKey: themeModeKey ?? this.themeModeKey,
        fontKey: fontKey ?? this.fontKey,
        fontSizeKey: fontSizeKey ?? this.fontSizeKey,
        spacingKey: spacingKey ?? this.spacingKey,
        justifyText: justifyText ?? this.justifyText,
      );
}

// ── SharedPreferences keys ─────────────────────────────────────────────────────

const _kThemeMode = 'appearance_theme';
const _kFont = 'appearance_font';
const _kFontSize = 'appearance_font_size';
const _kSpacing = 'appearance_spacing';
const _kJustify = 'appearance_justify';

Future<AppearanceSettings> loadAppearanceSettings() async {
  final prefs = await SharedPreferences.getInstance();
  return AppearanceSettings(
    themeModeKey: prefs.getString(_kThemeMode) ?? 'system',
    fontKey: prefs.getString(_kFont) ?? 'default',
    fontSizeKey: prefs.getString(_kFontSize) ?? 'medium',
    spacingKey: prefs.getString(_kSpacing) ?? 'normal',
    justifyText: prefs.getBool(_kJustify) ?? false,
  );
}

// ── Notifier ───────────────────────────────────────────────────────────────────

class AppearanceNotifier extends Notifier<AppearanceSettings> {
  final AppearanceSettings _initial;

  AppearanceNotifier({AppearanceSettings initial = const AppearanceSettings()})
      : _initial = initial;

  @override
  AppearanceSettings build() => _initial;

  Future<void> setThemeMode(String key) async {
    state = state.copyWith(themeModeKey: key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeMode, key);
  }

  Future<void> setFont(String key) async {
    state = state.copyWith(fontKey: key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kFont, key);
  }

  Future<void> setFontSize(String key) async {
    state = state.copyWith(fontSizeKey: key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kFontSize, key);
  }

  Future<void> setSpacing(String key) async {
    state = state.copyWith(spacingKey: key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSpacing, key);
  }

  Future<void> setJustifyText(bool value) async {
    state = state.copyWith(justifyText: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kJustify, value);
  }
}

final appearanceProvider =
    NotifierProvider<AppearanceNotifier, AppearanceSettings>(
  () => AppearanceNotifier(),
);
