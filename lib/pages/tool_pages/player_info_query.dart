import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:grow_castle_calculator/l10n/app_localizations.dart';
import 'package:grow_castle_calculator/services/player_api_service.dart';
import 'package:grow_castle_calculator/utils/game_calculations.dart';

class PlayerInfoQueryPage extends StatefulWidget {
  const PlayerInfoQueryPage({super.key});

  static const int seasonHours = 120;

  @override
  State<PlayerInfoQueryPage> createState() => _PlayerInfoQueryPageState();
}

class _PlayerInfoQueryPageState extends State<PlayerInfoQueryPage> {
  final TextEditingController _gameNameController = TextEditingController();

  bool _isQuerying = false;
  DateTime? _lastQueryTime;

  bool _hasResult = false;
  int _queriedWave = 0;
  int _queriedScore = 0;
  String? _queryDate;

  DateTime _now = DateTime.now();
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _gameNameController.dispose();
    _timer.cancel();
    super.dispose();
  }

  Future<void> _queryPlayer() async {
    final loc = AppLocalizations.of(context)!;
    final name = _gameNameController.text.trim();
    if (name.isEmpty) return;

    // Debounce: prevent requests within 3 seconds.
    final now = DateTime.now();
    if (_lastQueryTime != null &&
        now.difference(_lastQueryTime!).inSeconds < 3) {
      _showToast(loc.tooManyRequests);
      return;
    }
    _lastQueryTime = now;

    setState(() => _isQuerying = true);

    final result = await PlayerApiService.query(name);

    if (!mounted) return;

    setState(() {
      _isQuerying = false;

      switch (result) {
        case PlayerQueryResult(:final wave, :final seasonalScore,
              :final queryDate):
          _queriedWave = wave;
          _queriedScore = seasonalScore;
          _queryDate = _formatQueryDate(queryDate);
          _hasResult = true;
        default:
          _hasResult = false;
          _showToast(loc.nameNotFound);
      }
    });
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Parses an ISO 8601 UTC timestamp string and formats it as local time.
  String _formatQueryDate(String raw) {
    if (raw.isEmpty) return raw;
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final progress = calculateSeasonProgress(_now);

    final wphValue = _hasResult && progress.seasonProgress > 0
        ? (_queriedScore /
                (PlayerInfoQueryPage.seasonHours * progress.seasonProgress))
            .toStringAsFixed(2)
        : '—';

    return PopScope(
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          appBar: AppBar(
            title: Text(loc.playerInfoQuery),
            elevation: 1,
            backgroundColor: theme.scaffoldBackgroundColor,
          ),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Game name + query button ──────────────────────
                      Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: TextField(
                              controller: _gameNameController,
                              decoration: InputDecoration(
                                labelText: loc.gameName,
                                hintText: loc.gameName,
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 40,
                            child: ElevatedButton(
                              onPressed:
                                  _isQuerying ? null : _queryPlayer,
                              child: _isQuerying
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.send, size: 18),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // ── Query result card ─────────────────────────────
                      Card(
                        elevation: 0,
                        color: theme
                            .colorScheme.surfaceContainerHighest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    loc.queryResult,
                                    style: theme
                                        .textTheme.bodyMedium
                                        ?.copyWith(
                                      color: theme
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                  if (_hasResult && _queryDate != null)
                                    Text(
                                      _queryDate!,
                                      style: theme
                                          .textTheme.labelSmall
                                          ?.copyWith(
                                        color: theme
                                            .colorScheme.primary,
                                      ),
                                    ),
                                ],
                              ),
                              const Divider(height: 1),
                              if (_hasResult)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      _summaryChip(
                                        loc.currentWave,
                                        _queriedWave.toString(),
                                        theme,
                                      ),
                                      const SizedBox(width: 12),
                                      _summaryChip(
                                        loc.currentSeasonalWave,
                                        _queriedScore.toString(),
                                        theme,
                                      ),
                                      const SizedBox(width: 12),
                                      _summaryChip(
                                        loc.wph,
                                        wphValue,
                                        theme,
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(
                                          vertical: 4),
                                  child: Text(
                                    loc.notQueried,
                                    style: theme
                                        .textTheme.bodySmall
                                        ?.copyWith(
                                      color: theme
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryChip(String label, String value, ThemeData theme) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
