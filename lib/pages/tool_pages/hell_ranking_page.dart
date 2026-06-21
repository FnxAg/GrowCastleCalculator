import 'dart:async';
import 'package:flutter/material.dart';
import 'package:grow_castle_calculator/l10n/app_localizations.dart';
import 'package:grow_castle_calculator/services/player_api_service.dart';

class HellRankingPage extends StatefulWidget {
  const HellRankingPage({super.key});

  @override
  State<HellRankingPage> createState() => _HellRankingPageState();
}

class _HellRankingPageState extends State<HellRankingPage>
    with WidgetsBindingObserver {
  List<HellRankInfo> _players = [];
  bool _isLoading = true;
  String? _errorMessage;

  Timer? _fetchTimer;
  final ScrollController _scrollController = ScrollController();

  static const _cardHeight = 48.0;

  static const List<int> _jumpRanks = [1, 10, 50, 100, 200, 300];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchPlayers();
    _fetchTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchPlayers();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fetchTimer?.cancel();
    _scrollController.dispose();
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
    final result = await PlayerApiService.queryHellRanking();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      switch (result) {
        case List<HellRankInfo> players:
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

  void _jumpToRank(int rank) {
    if (_players.isEmpty) return;
    // Find the index of the target rank, or use approximate position.
    final targetIndex = _players.indexWhere((p) => p.rank == rank);
    final index = targetIndex >= 0 ? targetIndex : (rank - 1).clamp(0, _players.length - 1);
    final offset = index * _cardHeight;
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Formats [n] with commas every 3 digits (English style).
  String _formatComma(int n) {
    return n.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.hellRanking),
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
          PopupMenuButton<int>(
            icon: const Icon(Icons.arrow_drop_down_circle_outlined),
            tooltip: 'Jump to rank',
            onSelected: _jumpToRank,
            itemBuilder: (context) => _jumpRanks.map((r) {
              // Find the name for this rank to show alongside.
              final player = _players.isNotEmpty
                  ? _players.cast<HellRankInfo?>().firstWhere(
                        (p) => p?.rank == r,
                        orElse: () => null,
                      )
                  : null;
              final label = player != null ? '#$r  ${player.name}' : '#$r';
              return PopupMenuItem(value: r, child: Text(label));
            }).toList(),
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
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                    child: _buildHeaderCard(theme, loc),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _buildPlayerCard(context, index, theme),
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
              width: 152,
              child: Text(
                loc.damage,
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
      BuildContext context, int index, ThemeData theme) {
    final player = _players[index];
    final damage = _formatComma(player.score);

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
                width: 152,
                child: Text(
                  damage,
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
