import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:grow_castle_calculator/app.dart';
import 'package:grow_castle_calculator/providers/gold_calculator_provider.dart';
import 'package:grow_castle_calculator/providers/theme_provider.dart';
import 'package:grow_castle_calculator/services/preferences_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize shared mutable state from persisted preferences.
  localeChoice = await PreferencesService.getLocaleChoice();
  themeChoice = await PreferencesService.getThemeChoice();

  final goldCalculatorProvider = GoldCalculatorProvider();
  await goldCalculatorProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(themeChoice)),
        ChangeNotifierProvider.value(value: goldCalculatorProvider),
      ],
      child: const MyApp(),
    ),
  );
}
