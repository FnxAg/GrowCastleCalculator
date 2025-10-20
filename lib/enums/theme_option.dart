import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
        return AppLocalizations.of(Get.context!)!.systemDefault;
      case ThemeOption.light:
        return AppLocalizations.of(Get.context!)!.lightMode;
      case ThemeOption.dark:
        return AppLocalizations.of(Get.context!)!.darkMode;
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
