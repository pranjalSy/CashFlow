import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// UI preferences that hold no user data, work before login and survive logout (TRD 6.1).
class UiPrefs {
  UiPrefs(this._prefs);

  final SharedPreferences _prefs;

  static const _language = 'ui.language';
  static const _theme = 'ui.theme';
  static const _reduceGlass = 'ui.reduce_glass';
  static const _lockAfter = 'security.lock_after_seconds';

  String? get language => _prefs.getString(_language);
  Future<void> setLanguage(String code) => _prefs.setString(_language, code);

  ThemeMode get themeMode => ThemeMode.values.asNameMap()[_prefs.getString(_theme)] ?? ThemeMode.system;
  Future<void> setThemeMode(ThemeMode mode) => _prefs.setString(_theme, mode.name);

  bool get reduceGlass => _prefs.getBool(_reduceGlass) ?? false;
  Future<void> setReduceGlass(bool value) => _prefs.setBool(_reduceGlass, value);

  /// "Lock after" (FR-L8): 0 = immediately, 60 = 1 minute (default), 300 = 5 minutes. Per phone.
  int get lockAfterSeconds => _prefs.getInt(_lockAfter) ?? 60;
  Future<void> setLockAfterSeconds(int seconds) => _prefs.setInt(_lockAfter, seconds);
}

final uiPrefsProvider = Provider<UiPrefs>((ref) => throw UnimplementedError('uiPrefsProvider is overridden in bootstrap'));

/// App language; null until chosen (the system language is used, falling back to English).
final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(LocaleNotifier.new);

class LocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() {
    final code = ref.watch(uiPrefsProvider).language;
    return code == null ? null : Locale(code);
  }

  Future<void> set(String code) async {
    await ref.read(uiPrefsProvider).setLanguage(code);
    state = Locale(code);
  }
}

/// Theme: System (default) / Light / Dark (FR-U9). Applies at once.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.watch(uiPrefsProvider).themeMode;

  Future<void> set(ThemeMode mode) async {
    await ref.read(uiPrefsProvider).setThemeMode(mode);
    state = mode;
  }
}
