import 'package:flutter/material.dart';
import 'package:grow_castle_calculator/app.dart';
import '../l10n/app_localizations.dart';

enum ThemeOption {
  system,
  light,
  dark;

  int get themeCode {
    switch (this) {
      case ThemeOption.system:
        return 0;
      case ThemeOption.light:
        return 1;
      case ThemeOption.dark:
        return 2;
    }
  }

  String get themeString {
    switch (this) {
      case ThemeOption.system:
        return AppLocalizations.of(globalNavigatorKey.currentContext!)!.systemDefault;
      case ThemeOption.light:
        return AppLocalizations.of(globalNavigatorKey.currentContext!)!.lightMode;
      case ThemeOption.dark:
        return AppLocalizations.of(globalNavigatorKey.currentContext!)!.darkMode;
    }
  }

  ThemeMode get themeMode {
    switch (this) {
      case ThemeOption.system:
        return ThemeMode.system;
      case ThemeOption.light:
        return ThemeMode.light;
      case ThemeOption.dark:
        return ThemeMode.dark;
    }
  }

  static ThemeOption fromThemeCode2ThemeOption(int code) {
    for (var option in ThemeOption.values) {
      if (option.themeCode == code) {
        return option;
      }
    }
    return ThemeOption.values[0];
  }
}
