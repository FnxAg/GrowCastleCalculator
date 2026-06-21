import 'dart:async';
import 'package:flutter/material.dart';
import 'package:grow_castle_calculator/l10n/app_localizations.dart';
import 'package:grow_castle_calculator/services/player_api_service.dart';
import 'package:grow_castle_calculator/utils/game_calculations.dart';

class PlayerRankingPage extends StatefulWidget {
  const PlayerRankingPage({super.key});

  static const int seasonHours = 120;

  @override
  State<PlayerRankingPage> createState() => _PlayerRankingPageState();
}

class _PlayerRankingPageState extends State<PlayerRankingPage>
    with WidgetsBindingObserver {
  List<PlayerRankInfo> _players = [];
  bool _isLoading = true;
  String? _errorMessage;

  DateTime _now = DateTime.now();
  late Timer _clockTimer;
  Timer? _fetchTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _clockTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      setState(() => _now = DateTime.now());
    });
    _fetchPlayers();
    _fetchTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchPlayers();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clockTimer.cancel();
    _fetchTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      _fetchTimer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      _fetchPlayers();
      _fetchTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        _fetchPlayers();
      });
    }
  }

  Future<void> _fetchPlayers() async {
    final result = await PlayerApiService.queryPlayerRanking();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      switch (result) {
        case List<PlayerRankInfo> players:
          _players = players;
          _errorMessage = null;
        case TimeoutError():
          _errorMessage = 'Timeout';
        case NetworkError(:final message):
          _errorMessage = message;
        default:
          _errorMessage = 'Unknown error';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final progress = calculateSeasonProgress(_now);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.playerRanking),
        elevation: 1,
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          if (_errorMessage != null)
            IconButton(
              icon: Icon(Icons.warning_amber, color: Colors.orange.shade300),
              tooltip: _errorMessage,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_errorMessage!),
                    duration: const Duration(seconds: 3),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: loc.getInfo,
              onPressed: () {
                setState(() => _isLoading = true);
                _fetchPlayers();
              },
            ),
        ],
      ),
      body: _isLoading && _players.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                    child: _buildHeaderCard(theme, loc),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildPlayerCard(
                        context, index, theme, progress.seasonProgress),
                    childCount: _players.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
    );
  }

  Widget _buildHeaderCard(ThemeData theme, AppLocalizations loc) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withAlpha(120),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: Text(
                loc.rank,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Text(
                loc.gameName,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 72,
              child: Text(
                loc.seasonalScore,
                textAlign: TextAlign.end,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 48,
              child: Text(
                'WPH',
                textAlign: TextAlign.end,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCard(
      BuildContext context, int index, ThemeData theme, double seasonProgress) {
    final player = _players[index];
    final wph = seasonProgress > 0
        ? (player.score /
                (PlayerRankingPage.seasonHours * seasonProgress))
            .toStringAsFixed(0)
        : '—';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withAlpha(80),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                child: Text(
                  player.rank.toString(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: player.rank <= 3
                        ? theme.colorScheme.primary
                        : null,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  player.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 72,
                child: Text(
                  player.score.toString(),
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 48,
                child: Text(
                  wph,
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
