import 'package:flutter/material.dart';
import 'package:grow_castle_calculator/enums/locale_option.dart';

/// Manages the app's [Locale] state and notifies listeners on changes.
class LocaleProvider with ChangeNotifier {
  int _localeChoice;

  LocaleProvider(int localeChoice) : _localeChoice = localeChoice;

  int get localeChoice => _localeChoice;

  Locale get locale =>
      LocaleOption.fromLocaleCode2LocaleOption(_localeChoice).localeType;

  void setLocale(int choice) {
    if (_localeChoice != choice) {
      _localeChoice = choice;
      notifyListeners();
    }
  }
}
