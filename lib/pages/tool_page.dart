import 'package:flutter/material.dart';
import 'package:grow_castle_calculator/utils/page_transitions.dart';
import 'package:grow_castle_calculator/pages/tool_pages/wave_speed_query.dart';
import 'package:grow_castle_calculator/pages/tool_pages/player_info_query.dart';
import 'package:grow_castle_calculator/pages/tool_pages/player_ranking_page.dart';
import 'package:grow_castle_calculator/pages/tool_pages/guild_info_query.dart';
import 'package:grow_castle_calculator/pages/tool_pages/hell_ranking_page.dart';
import 'package:grow_castle_calculator/pages/tool_pages/guild_subscription_page.dart';
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
                      smoothPageRoute(
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
                  smoothPageRoute(
                    builder: (context) => const WaveSpeedQueryPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_search),
              title: Text(AppLocalizations.of(context)!.playerInfoQuery),
              trailing: const Icon(Icons.keyboard_arrow_right),
              onTap: () {
                Navigator.push(
                  context,
                  smoothPageRoute(
                    builder: (context) => const PlayerInfoQueryPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.leaderboard),
              title: Text(AppLocalizations.of(context)!.playerRanking),
              trailing: const Icon(Icons.keyboard_arrow_right),
              onTap: () {
                Navigator.push(
                  context,
                  smoothPageRoute(
                    builder: (context) => const PlayerRankingPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.shield),
              title: Text(AppLocalizations.of(context)!.guildInfoQuery),
              trailing: const Icon(Icons.keyboard_arrow_right),
              onTap: () {
                Navigator.push(
                  context,
                  smoothPageRoute(
                    builder: (context) => const GuildInfoQueryPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.whatshot),
              title: Text(AppLocalizations.of(context)!.hellRanking),
              trailing: const Icon(Icons.keyboard_arrow_right),
              onTap: () {
                Navigator.push(
                  context,
                  smoothPageRoute(
                    builder: (context) => const HellRankingPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_active),
              title: Text(AppLocalizations.of(context)!.guildSubscription),
              trailing: const Icon(Icons.keyboard_arrow_right),
              onTap: () {
                Navigator.push(
                  context,
                  smoothPageRoute(
                    builder: (context) => const GuildSubscriptionPage(),
                  ),
                );
              },
            ),
          ],
        ),
    );
  }
}
