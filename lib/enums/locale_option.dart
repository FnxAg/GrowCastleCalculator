import 'dart:ui';
import 'package:get/get.dart';
import '../l10n/app_localizations.dart';

enum LocaleOption {
  sys,
  zh,
  en;

  int get localeCode {
    switch (this) {
      case LocaleOption.sys:
        return 0;
      case LocaleOption.zh:
        return 1;
      case LocaleOption.en:
        return 2;
    }
  }

  String get localeString {
    switch (this) {
      case LocaleOption.sys:
        return AppLocalizations.of(Get.context!)!.systemDefault;
      case LocaleOption.zh:
        return AppLocalizations.of(Get.context!)!.zh_CN_withCode;
      case LocaleOption.en:
        return AppLocalizations.of(Get.context!)!.en_withCode;
    }
  }

  Locale get localeType {
    switch (this) {
      case LocaleOption.sys:
        return Get.deviceLocale!;
      case LocaleOption.zh:
        return const Locale('zh');
      case LocaleOption.en:
        return const Locale('en');
    }
  }

  static LocaleOption fromLocaleCode2LocaleOption(int code) {
    for (var option in LocaleOption.values) {
      if (option.localeCode == code) {
        return option;
      }
    }
    return LocaleOption.values[0];
  }
}
