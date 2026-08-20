import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _themePrefsKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.light;

  ThemeProvider() {
    loadTheme();
  }

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString(_themePrefsKey);
      _themeMode = value == 'dark' ? ThemeMode.dark : ThemeMode.light;
      notifyListeners();
    } catch (_) {
      // Keep default theme if loading fails.
    }
  }

  void toggleTheme(bool isOn) {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(
        _themePrefsKey,
        _themeMode == ThemeMode.dark ? 'dark' : 'light',
      );
    });
    notifyListeners();
  }
}
