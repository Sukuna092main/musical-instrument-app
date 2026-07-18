import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide settings: theme mode + locale. Persisted to SharedPreferences.
/// Propagated to the whole tree via [AppSettingsScope] (InheritedNotifier)
/// so any screen can read/update without prop-drilling through 20 routes.
class AppSettings extends ChangeNotifier {
  static const _themeKey = 'themeMode';
  static const _localeKey = 'locale';

  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('en');

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  /// Load saved values from SharedPreferences. Call once at startup before runApp.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final themeName = prefs.getString(_themeKey);
    switch (themeName) {
      case 'dark':
        _themeMode = ThemeMode.dark;
      case 'light':
        _themeMode = ThemeMode.light;
      default:
        _themeMode = ThemeMode.system;
    }

    final lang = prefs.getString(_localeKey);
    _locale = lang == 'vi' ? const Locale('vi') : const Locale('en');
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }
}
