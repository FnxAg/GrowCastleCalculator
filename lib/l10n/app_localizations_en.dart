// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Grow Castle Calculator';

  @override
  String get calculator => 'Calculator';

  @override
  String get tool => 'Tool';

  @override
  String get settings => 'Settings';

  @override
  String get castleDefault => 'Castle (Default)';

  @override
  String get taDefault => 'TA (Default)';

  @override
  String get clearInputFields => 'Clear All Input Fields';

  @override
  String get loadData => 'Load Data';

  @override
  String get currentWave => 'Current Wave';

  @override
  String get typeCurrentWave => 'Type Current Wave';

  @override
  String get seasonalWave => 'Seasonal Wave';

  @override
  String get typeSeasonalWave => 'Type Seasonal Wave';

  @override
  String get currentSeasonalWave => 'Current Seasonal Wave';

  @override
  String get typeCurrentSeasonalWave => 'Type Current Seasonal Wave';

  @override
  String get totalWave => 'Total Wave: ';

  @override
  String get totalGold => 'Total Gold: ';

  @override
  String get gp => 'GP: ';

  @override
  String get ratio => 'Ratio: ';

  @override
  String get seasonProgress => 'Season Progress: ';

  @override
  String get wph => 'WPH: ';

  @override
  String get unitName => 'Unit Name';

  @override
  String get typeUnitName => 'Type Unit Name';

  @override
  String get unitLevel => 'Unit Level';

  @override
  String get typeUnitLevel => 'Type Unit Level';

  @override
  String get remove => 'Remove';

  @override
  String get add => 'Add';

  @override
  String get save => 'Save';

  @override
  String get todo =>
      'Tool Page\nComing Soon!\nTodo List:\n- Gold Calculator\n- Time Till Reset\n- Level Cost Calculator\n- Infinite Colony Calculator\n- Damage Comparison\n- GPW';

  @override
  String get language => 'Language';

  @override
  String get themeMode => 'Theme Mode';

  @override
  String get systemDefault => 'System';

  @override
  String get lightMode => 'Light';

  @override
  String get darkMode => 'Dark';

  @override
  String get clearSavedData => 'Clear Data';

  @override
  String get clearDataWarning =>
      'Are you sure you want to clear saved data? This action cannot be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get clearDataFinished => 'Saved data cleared.';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get developer => 'by FnxAg aka Ariyara';

  @override
  String appVersion(String versionNumber) {
    return 'Version $versionNumber';
  }

  @override
  String get github => 'GitHub';

  @override
  String get repositoryUrl => 'https://github.com/FnxAg/GrowCastleCalculator';

  @override
  String get bilibili => 'Bilibili';

  @override
  String get developerBilibiliUrl => 'https://space.bilibili.com/505144597';

  @override
  String cannotLaunchURL(String url) {
    return 'Cannot launch URL: $url';
  }

  @override
  String get zh_CN_withCode => 'zh_CN\t简体中文';

  @override
  String get en_withCode => 'en\tEnglish';
}
