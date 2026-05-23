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
  String get enterCurrentWave => 'Enter Current Wave';

  @override
  String get seasonalWave => 'Seasonal Wave';

  @override
  String get enterSeasonalWave => 'Enter Seasonal Wave';

  @override
  String get currentSeasonalWave => 'Current Seasonal Wave';

  @override
  String get enterCurrentSeasonalWave => 'Enter Current Seasonal Wave';

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
  String get hellModeSeasonProgress => 'Hell Mode Progress: ';

  @override
  String get seasonalColonyProgress => 'Seasonal Colony Progress: ';

  @override
  String get progress => 'Progress';

  @override
  String get updateTime => 'Update Time: ';

  @override
  String get timeTillReset => 'Time Till Reset: ';

  @override
  String get wph => 'WPH: ';

  @override
  String unitName(int index) {
    return 'Unit $index';
  }

  @override
  String get enterUnitName => 'Enter Unit Name';

  @override
  String get unitLevel => 'Unit Level';

  @override
  String get enterUnitLevel => 'Enter Unit Level';

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
  String get exportData => 'Export Data';

  @override
  String get importData => 'Import Data';

  @override
  String get exportSuccess => 'Data exported successfully';

  @override
  String get exportFailed => 'Failed to export data';

  @override
  String get importSuccess => 'Data imported successfully';

  @override
  String get importFailed => 'Failed to import data';

  @override
  String get invalidDataFormat => 'Invalid file format';

  @override
  String get importWarning => 'This will overwrite the current data. Continue?';

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
  String get checkForUpdates => 'Check for Updates';

  @override
  String get checkForUpdateFailed => 'Check for Update Failed';

  @override
  String get isLatestVersion => 'Already the Latest Version';

  @override
  String get findNewVersion => 'New Version Found!';

  @override
  String get currentVersion => 'Current Version: ';

  @override
  String get latestVersion => 'Latest Version: ';

  @override
  String get updateContent => 'Update Content: ';

  @override
  String get fixedKnownIssues => 'Optimized experience, fixed known issues';

  @override
  String get updateLater => 'Update Later';

  @override
  String get updateNow => 'Update Now';

  @override
  String get newVersionAvailable => 'New Version Available';

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

  @override
  String get goldCalculator => 'Gold Calculator';

  @override
  String get inherit => 'Inherit';

  @override
  String get gabCost => 'GAB Cost: ';

  @override
  String get goldDay => 'Gold/Day: ';

  @override
  String get gameSpeed => 'Game Speed';

  @override
  String get enterGameSpeed => 'Enter Game Speed';

  @override
  String get jumpAndWave => 'Jump + Wave';

  @override
  String get enterWave => 'Enter Wave';

  @override
  String get waveTime => 'Wave Time (s)';

  @override
  String get enterWaveTime => 'Enter Wave Time';

  @override
  String get infiniteColony => 'Infinite Colony';

  @override
  String get icLevel => 'IC Level';

  @override
  String get enterLV => 'Enter Level';

  @override
  String get ironWheel => 'Iron Wheel';

  @override
  String get extraColonyCD => 'Colony CD+';

  @override
  String get extraColonyGold => 'Colony Gold+';

  @override
  String get secCart => 'Sec/Cart: ';

  @override
  String get goldCart => 'Gold/Cart: ';

  @override
  String get cartHour => 'Carts/Hour: ';

  @override
  String get icRatio => 'IC Ratio: ';

  @override
  String get goldHour => 'Gold/Hour: ';

  @override
  String get goldAutoBattle => 'Gold Auto Battle';

  @override
  String get gabHourDay => 'GAB Hours/Day';

  @override
  String get enterHour => 'Enter Hours';

  @override
  String get gabProfit => 'GAB Profit %';

  @override
  String get enterProfit => 'Enter Profit Percentage';

  @override
  String get goldWave => 'Gold/Wave: ';

  @override
  String get timeAutoBattle => 'Time Auto Battle';

  @override
  String get tabHourDay => 'TAB Hours/Day';

  @override
  String get goldenTree => 'Golden Tree';

  @override
  String get seasonalColony => 'Seasonal Colony';
}
