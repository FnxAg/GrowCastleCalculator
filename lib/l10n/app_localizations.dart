import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Grow Castle Calculator'**
  String get appName;

  /// No description provided for @calculator.
  ///
  /// In en, this message translates to:
  /// **'Calculator'**
  String get calculator;

  /// No description provided for @tool.
  ///
  /// In en, this message translates to:
  /// **'Tool'**
  String get tool;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @castleDefault.
  ///
  /// In en, this message translates to:
  /// **'Castle (Default)'**
  String get castleDefault;

  /// No description provided for @taDefault.
  ///
  /// In en, this message translates to:
  /// **'TA (Default)'**
  String get taDefault;

  /// No description provided for @clearInputFields.
  ///
  /// In en, this message translates to:
  /// **'Clear All Input Fields'**
  String get clearInputFields;

  /// No description provided for @loadData.
  ///
  /// In en, this message translates to:
  /// **'Load Data'**
  String get loadData;

  /// No description provided for @currentWave.
  ///
  /// In en, this message translates to:
  /// **'Current Wave'**
  String get currentWave;

  /// No description provided for @enterCurrentWave.
  ///
  /// In en, this message translates to:
  /// **'Enter Current Wave'**
  String get enterCurrentWave;

  /// No description provided for @seasonalWave.
  ///
  /// In en, this message translates to:
  /// **'Seasonal Wave'**
  String get seasonalWave;

  /// No description provided for @enterSeasonalWave.
  ///
  /// In en, this message translates to:
  /// **'Enter Seasonal Wave'**
  String get enterSeasonalWave;

  /// No description provided for @currentSeasonalWave.
  ///
  /// In en, this message translates to:
  /// **'Current Seasonal Wave'**
  String get currentSeasonalWave;

  /// No description provided for @enterCurrentSeasonalWave.
  ///
  /// In en, this message translates to:
  /// **'Enter Current Seasonal Wave'**
  String get enterCurrentSeasonalWave;

  /// No description provided for @totalWave.
  ///
  /// In en, this message translates to:
  /// **'Total Wave: '**
  String get totalWave;

  /// No description provided for @totalGold.
  ///
  /// In en, this message translates to:
  /// **'Total Gold: '**
  String get totalGold;

  /// No description provided for @gp.
  ///
  /// In en, this message translates to:
  /// **'GP: '**
  String get gp;

  /// No description provided for @ratio.
  ///
  /// In en, this message translates to:
  /// **'Ratio: '**
  String get ratio;

  /// No description provided for @seasonProgress.
  ///
  /// In en, this message translates to:
  /// **'Season Progress: '**
  String get seasonProgress;

  /// No description provided for @hellModeSeasonProgress.
  ///
  /// In en, this message translates to:
  /// **'Hell Mode Progress: '**
  String get hellModeSeasonProgress;

  /// No description provided for @seasonalColonyProgress.
  ///
  /// In en, this message translates to:
  /// **'Seasonal Colony Progress: '**
  String get seasonalColonyProgress;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @updateTime.
  ///
  /// In en, this message translates to:
  /// **'Update Time: '**
  String get updateTime;

  /// No description provided for @timeTillReset.
  ///
  /// In en, this message translates to:
  /// **'Time Till Reset: '**
  String get timeTillReset;

  /// No description provided for @wph.
  ///
  /// In en, this message translates to:
  /// **'WPH: '**
  String get wph;

  /// No description provided for @unitName.
  ///
  /// In en, this message translates to:
  /// **'Unit {index} Name'**
  String unitName(int index);

  /// No description provided for @enterUnitName.
  ///
  /// In en, this message translates to:
  /// **'Enter Unit Name'**
  String get enterUnitName;

  /// No description provided for @unitLevel.
  ///
  /// In en, this message translates to:
  /// **'Unit Level'**
  String get unitLevel;

  /// No description provided for @enterUnitLevel.
  ///
  /// In en, this message translates to:
  /// **'Enter Unit Level'**
  String get enterUnitLevel;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @todo.
  ///
  /// In en, this message translates to:
  /// **'Tool Page\nComing Soon!\nTodo List:\n- Gold Calculator\n- Time Till Reset\n- Level Cost Calculator\n- Infinite Colony Calculator\n- Damage Comparison\n- GPW'**
  String get todo;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get themeMode;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemDefault;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightMode;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkMode;

  /// No description provided for @clearSavedData.
  ///
  /// In en, this message translates to:
  /// **'Clear Data'**
  String get clearSavedData;

  /// No description provided for @clearDataWarning.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear saved data? This action cannot be undone.'**
  String get clearDataWarning;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @clearDataFinished.
  ///
  /// In en, this message translates to:
  /// **'Saved data cleared.'**
  String get clearDataFinished;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @developer.
  ///
  /// In en, this message translates to:
  /// **'by FnxAg aka Ariyara'**
  String get developer;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {versionNumber}'**
  String appVersion(String versionNumber);

  /// No description provided for @github.
  ///
  /// In en, this message translates to:
  /// **'GitHub'**
  String get github;

  /// No description provided for @repositoryUrl.
  ///
  /// In en, this message translates to:
  /// **'https://github.com/FnxAg/GrowCastleCalculator'**
  String get repositoryUrl;

  /// No description provided for @bilibili.
  ///
  /// In en, this message translates to:
  /// **'Bilibili'**
  String get bilibili;

  /// No description provided for @developerBilibiliUrl.
  ///
  /// In en, this message translates to:
  /// **'https://space.bilibili.com/505144597'**
  String get developerBilibiliUrl;

  /// No description provided for @cannotLaunchURL.
  ///
  /// In en, this message translates to:
  /// **'Cannot launch URL: {url}'**
  String cannotLaunchURL(String url);

  /// No description provided for @zh_CN_withCode.
  ///
  /// In en, this message translates to:
  /// **'zh_CN\t简体中文'**
  String get zh_CN_withCode;

  /// No description provided for @en_withCode.
  ///
  /// In en, this message translates to:
  /// **'en\tEnglish'**
  String get en_withCode;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
