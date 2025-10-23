import 'package:dynamic_color/dynamic_color.dart';
import 'package:grow_castle_calculator/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:grow_castle_calculator/pages/calculator_page.dart';
import 'package:grow_castle_calculator/pages/settings_page.dart';
import 'package:grow_castle_calculator/pages/tool_page.dart';
import 'package:grow_castle_calculator/enums/locale_option.dart';
import 'package:grow_castle_calculator/enums/theme_option.dart';

int localeChoice = 0;
int themeChoice = 0;

Future<void> loadLocale() async {
  final prefs = await SharedPreferences.getInstance();
  localeChoice = prefs.getInt('localeChoice') ?? 0;
}

Future<void> loadTheme() async {
  final prefs = await SharedPreferences.getInstance();
  themeChoice = prefs.getInt('themeChoice') ?? 0;
}

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeOption.fromThemeCode2ThemeOption(
    themeChoice,
  ).themeMode;

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadLocale();
  await loadTheme();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static const defaultColorSeed = Colors.blueAccent;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightColorScheme;
        ColorScheme darkColorScheme;

        if (lightDynamic != null && darkDynamic != null) {
          lightColorScheme = lightDynamic.harmonized();
          darkColorScheme = darkDynamic.harmonized();
        } else {
          lightColorScheme = ColorScheme.fromSeed(
            seedColor: MyApp.defaultColorSeed,
          );
          darkColorScheme = ColorScheme.fromSeed(
            seedColor: MyApp.defaultColorSeed,
            brightness: Brightness.dark,
          );
        }

        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) => GetMaterialApp(
            onGenerateTitle: (BuildContext context) =>
                AppLocalizations.of(context)!.appName,
            locale: LocaleOption.fromLocaleCode2LocaleOption(
              localeChoice,
            ).localeType,
            fallbackLocale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: ThemeData(useMaterial3: true, colorScheme: lightColorScheme),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: darkColorScheme,
            ),
            themeMode: themeProvider.themeMode,
            home: HomePage(),
          ),
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _pageIndex = 0;
  final PageController _pageController = PageController(initialPage: 0);

  final List<Widget> _pages = [CalculatorPage(), ToolPage(), SettingsPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _pageIndex = index;
          });
        },
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate_outlined),
            activeIcon: Icon(Icons.calculate),
            label: AppLocalizations.of(context)!.calculator,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build_outlined),
            activeIcon: Icon(Icons.build),
            label: AppLocalizations.of(context)!.tool,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: AppLocalizations.of(context)!.settings,
          ),
        ],
        currentIndex: _pageIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
          );
        },
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class FormatterWithMinusAndDot extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String validChars = newValue.text.replaceAll(RegExp(r'[^0-9.-]'), '');

    String processedText = '';
    bool hasMinus = false;
    bool hasDot = false;

    for (int i = 0; i < validChars.length; i++) {
      final char = validChars[i];
      if (char == '-') {
        if (i == 0 && !hasMinus) {
          processedText += char;
          hasMinus = true;
        }
      } else if (char == '.') {
        if (!hasDot && processedText.isNotEmpty) {
          processedText += char;
          hasDot = true;
        }
      } else {
        processedText += char;
      }
    }

    return TextEditingValue(
      text: processedText,
      selection: TextSelection.collapsed(offset: processedText.length),
    );
  }
}
