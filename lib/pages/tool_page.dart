import 'package:flutter/material.dart';
import 'package:grow_castle_calculator/pages/tool_pages/wave_speed_query.dart';
import 'package:provider/provider.dart';
import 'package:grow_castle_calculator/l10n/app_localizations.dart';
import 'package:grow_castle_calculator/pages/tool_pages/gold_calculator.dart';
import 'package:grow_castle_calculator/providers/gold_calculator_provider.dart';
import 'package:grow_castle_calculator/utils/number_utils.dart';

class ToolPage extends StatefulWidget {
  const ToolPage({super.key});

  @override
  State<ToolPage> createState() => _ToolPageState();
}

class _ToolPageState extends State<ToolPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.tool),
        elevation: 1,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: ListView(
          children: [
            Consumer<GoldCalculatorProvider>(
              builder: (context, provider, child) {
                final dailyIncome =
                    decreaseNumSize(provider.dailyIncome, context);
                return ListTile(
                  leading: const Icon(Icons.monetization_on),
                  title: Text(AppLocalizations.of(context)!.goldCalculator),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dailyIncome,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const Icon(Icons.keyboard_arrow_right),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GoldCalculator(),
                      ),
                    );
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.document_scanner_outlined),
              title: Text(AppLocalizations.of(context)!.waveSpeedQuery),
              trailing: const Icon(Icons.keyboard_arrow_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WaveSpeedQueryPage(),
                  ),
                );
              },
            ),
          ],
        ),
    );
  }
}
