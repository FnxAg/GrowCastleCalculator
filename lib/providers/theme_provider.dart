import 'package:flutter/material.dart';
import 'package:grow_castle_calculator/enums/theme_option.dart';

/// Manages the app's [ThemeMode] state and notifies listeners on changes.
class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode;

  ThemeProvider(int themeChoice)
      : _themeMode = ThemeOption.fromThemeCode2ThemeOption(themeChoice).themeMode;

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}
