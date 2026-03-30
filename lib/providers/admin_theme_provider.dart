import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminThemeProvider with ChangeNotifier {
  static const String _themeKey = 'admin_theme_mode';
  ThemeMode _themeMode = ThemeMode.dark; // Default to dark for Admin as requested earlier

  AdminThemeProvider() {
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, _themeMode.index);
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt(_themeKey);
    if (savedIndex != null) {
      _themeMode = ThemeMode.values[savedIndex];
      notifyListeners();
    }
  }
}
