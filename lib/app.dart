import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'package:grow_castle_calculator/l10n/app_localizations.dart';
import 'package:grow_castle_calculator/pages/calculator_page.dart';
import 'package:grow_castle_calculator/pages/settings_page.dart';
import 'package:grow_castle_calculator/pages/tool_page.dart';
import 'package:grow_castle_calculator/enums/locale_option.dart';
import 'package:grow_castle_calculator/providers/theme_provider.dart';

/// Runtime locale choice. Initialized in [main] and mutated by [SettingsPage].
int localeChoice = 0;

/// Runtime theme choice. Initialized in [main] and mutated by [SettingsPage].
int themeChoice = 0;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const Color defaultColorSeed = Colors.blueAccent;

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final lightColorScheme = lightDynamic?.harmonized() ??
            ColorScheme.fromSeed(seedColor: defaultColorSeed);
        final darkColorScheme = darkDynamic?.harmonized() ??
            ColorScheme.fromSeed(
              seedColor: defaultColorSeed,
              brightness: Brightness.dark,
            );

        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) => GetMaterialApp(
            onGenerateTitle: (BuildContext context) =>
                AppLocalizations.of(context)!.appName,
            locale: LocaleOption.fromLocaleCode2LocaleOption(localeChoice).localeType,
            fallbackLocale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: ThemeData(useMaterial3: true, colorScheme: lightColorScheme),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: darkColorScheme,
            ),
            themeMode: themeProvider.themeMode,
            home: const HomePage(),
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

  static const List<Widget> _pages = [
    CalculatorPage(),
    ToolPage(),
    SettingsPage(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          FocusScope.of(context).unfocus();
          setState(() => _pageIndex = index);
        },
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.calculate_outlined),
            activeIcon: const Icon(Icons.calculate),
            label: AppLocalizations.of(context)!.calculator,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.build_outlined),
            activeIcon: const Icon(Icons.build),
            label: AppLocalizations.of(context)!.tool,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings),
            label: AppLocalizations.of(context)!.settings,
          ),
        ],
        currentIndex: _pageIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          FocusManager.instance.primaryFocus?.unfocus();
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
