import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:grow_castle_calculator/l10n/app_localizations.dart';
import 'package:grow_castle_calculator/services/player_api_service.dart';
import 'package:grow_castle_calculator/services/preferences_service.dart';
import 'package:grow_castle_calculator/utils/game_calculations.dart';

class PlayerInfoQueryPage extends StatefulWidget {
  const PlayerInfoQueryPage({super.key, this.initialName});

  /// If provided, the page auto-queries this name on init.
  final String? initialName;

  static const int seasonHours = 120;

  @override
  State<PlayerInfoQueryPage> createState() => _PlayerInfoQueryPageState();
}

class _PlayerInfoQueryPageState extends State<PlayerInfoQueryPage>
    with WidgetsBindingObserver {
  final TextEditingController _gameNameController = TextEditingController();

  bool _isQuerying = false;
  DateTime? _lastQueryTime;

  bool _hasResult = false;
  int _queriedWave = 0;
  int _queriedScore = 0;
  String? _queryDate;
  String _rawQueryDate = '';

  // Season history state.
  String? _apiUrl;
  bool _isQueryingSeason = false;
  Map<String, List<int?>>? _seasonData;
  int _seasonWphCount = 0;
  String? _seasonError;

  DateTime _now = DateTime.now();
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      setState(() => _now = DateTime.now());
    });
    if (widget.initialName != null && widget.initialName!.isNotEmpty) {
      _gameNameController.text = widget.initialName!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _queryPlayer());
    } else {
      _loadPlayerName();
    }
    _loadApiUrl();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _gameNameController.dispose();
    _timer.cancel();
    super.dispose();
  }

  Future<void> _queryPlayer() async {
    final loc = AppLocalizations.of(context)!;
    final name = _gameNameController.text.trim();
    if (name.isEmpty) return;

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
          _rawQueryDate = queryDate;
          _queryDate = _formatQueryDate(queryDate);
          _hasResult = true;
          PreferencesService.savePlayerName(name);
          if (_apiUrl != null) {
            _querySeasonHistory();
          }
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

    final lastOnline =
        PlayerApiService.formatLastOnline(_rawQueryDate, _now);

    return PopScope(
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          appBar: AppBar(
            title: Text(loc.playerInfoQuery),
            elevation: 1,
            backgroundColor: theme.scaffoldBackgroundColor,
            actions: [
              IconButton(
                icon: Icon(Icons.link),
                color: _apiUrl != null
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant.withAlpha(100),
                tooltip: 'API URL',
                onPressed: _showUrlDialog,
              ),
              if (_isQuerying)
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                        color:
                            theme.colorScheme.surfaceContainerHighest,
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
                                      const SizedBox(width: 12),
                                      _summaryChip(
                                        'Online',
                                        lastOnline,
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
              // ── Season history result ─────────────────────────────
              if (_isQueryingSeason || _seasonData != null || _seasonError != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                    child: _buildSeasonHistoryCard(theme),
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

  // ── Season API URL ──────────────────────────────────────────────────────

  Future<void> _loadApiUrl() async {
    final url = await PreferencesService.loadSeasonApiUrl();
    if (mounted) setState(() => _apiUrl = url);
  }

  Future<void> _loadPlayerName() async {
    final name = await PreferencesService.loadPlayerName();
    if (mounted && name != null && name.isNotEmpty) {
      _gameNameController.text = name;
    }
  }

  void _showUrlDialog() {
    final controller = TextEditingController(text: _apiUrl ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('API URL'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'https://example.com/api',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showInstructionsDialog();
            },
            child: const Text('说明'),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () {
                  controller.dispose();
                  Navigator.pop(ctx);
                },
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              const SizedBox(width: 4),
              TextButton(
                onPressed: () {
                  final url = controller.text.trim();
                  controller.dispose();
                  if (url.isNotEmpty) {
                    PreferencesService.saveSeasonApiUrl(url);
                    setState(() => _apiUrl = url);
                  }
                  Navigator.pop(ctx);
                },
                child: Text(AppLocalizations.of(context)!.confirm),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showInstructionsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('说明'),
        content: const Text(
          '从API返回的JSON数据中，必须包含以下字段：\n'
          '- season: 赛季名称\n'
          '- wph: 每小时波数\n'
          '示例JSON:\n'
          '[\n'
          '  {"season": "Season 1", "wph": 120},\n'
          '  {"season": "Season 2", "wph": 150},\n'
          '  {"season": "Season 3", "wph": null}\n'
          ']\n'
          '如需API，可联系作者或自行搭建。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.confirm),
          ),
        ],
      ),
    );
  }

  // ── Season history query ────────────────────────────────────────────────

  Future<void> _querySeasonHistory() async {
    final playerName = _gameNameController.text.trim();
    if (playerName.isEmpty) {
      _showToast('请先输入玩家名称');
      return;
    }

    setState(() {
      _isQueryingSeason = true;
      _seasonData = null;
      _seasonError = null;
      _seasonWphCount = 0;
    });

    // Strip trailing slash(es) from base URL, then build path.
    final base = _apiUrl!.replaceAll(RegExp(r'/+$'), '');
    final encodedName = Uri.encodeComponent(playerName);
    final url = '$base/season/all/players/$encodedName';

    final client = http.Client();
    try {
      final uri = Uri.parse(url);
      final request = http.Request('GET', uri);
      request.headers['Accept'] = 'application/json';
      request.headers['User-Agent'] = 'curl/8.0';
      final streamedResp =
          await client.send(request).timeout(const Duration(seconds: 10));
      final response = await http.Response.fromStream(streamedResp);

      if (response.statusCode != 200) {
        setState(() {
          _isQueryingSeason = false;
          _seasonError = 'HTTP ${response.statusCode}: '
              '${response.reasonPhrase ?? "Unknown"}';
        });
        return;
      }

      final dynamic decoded;
      try {
        decoded = json.decode(utf8.decode(response.bodyBytes));
      } catch (e) {
        setState(() {
          _isQueryingSeason = false;
          _seasonError = 'JSON解析错误: $e';
        });
        return;
      }

      if (decoded is! List) {
        setState(() {
          _isQueryingSeason = false;
          _seasonError = 'JSON格式错误: 期望数组，实际为 ${decoded.runtimeType}';
        });
        return;
      }

      // Group by season, preserving insertion order.
      final grouped = <String, List<int?>>{};
      int count = 0;
      for (final entry in decoded) {
        if (entry is! Map<String, dynamic>) continue;
        final season = entry['season']?.toString();
        if (season == null || season.isEmpty) continue;
        final wphRaw = entry['wph'];
        final wph = wphRaw is num ? wphRaw.toInt() : null;
        grouped.putIfAbsent(season, () => []).add(wph);
        if (wphRaw is num) count++;
      }

      if (!mounted) return;
      setState(() {
        _isQueryingSeason = false;
        _seasonData = grouped;
        _seasonWphCount = count;
        _seasonError = null;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _isQueryingSeason = false;
        _seasonError = '请求超时\nURL: $url';
      });
    } on http.ClientException catch (e) {
      if (!mounted) return;
      setState(() {
        _isQueryingSeason = false;
        _seasonError = '网络请求失败: ${e.message}\nURL: $url';
      });
    } on FormatException catch (e) {
      if (!mounted) return;
      setState(() {
        _isQueryingSeason = false;
        _seasonError = 'URL格式错误: ${e.message}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isQueryingSeason = false;
        _seasonError = '请求错误: $e\nURL: $url';
      });
    } finally {
      client.close();
    }
  }

  // ── Season history display ──────────────────────────────────────────────

  Widget _buildSeasonHistoryCard(ThemeData theme) {
    if (_seasonError != null) {
      return Card(
        elevation: 0,
        color: theme.colorScheme.errorContainer.withAlpha(80),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.error_outline,
                  color: theme.colorScheme.error, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _seasonError!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_seasonData == null) {
      // Still loading or no data yet.
      if (_isQueryingSeason) {
        return Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: count
            Text(
              '共 $_seasonWphCount 条记录',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Divider(height: 1),
            // Body: grouped by season
            ...(_seasonData!.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Season: ${e.key}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildWphGrid(e.value, theme),
                    ],
                  ),
                ))),
          ],
        ),
      ),
    );
  }

  /// Builds a grid of WPH chips: 5 per row, neatly aligned.
  Widget _buildWphGrid(List<int?> wphs, ThemeData theme) {
    const itemsPerRow = 5;
    final rows = <List<int?>>[];
    for (int i = 0; i < wphs.length; i += itemsPerRow) {
      final end =
          (i + itemsPerRow < wphs.length) ? i + itemsPerRow : wphs.length;
      rows.add(wphs.sublist(i, end));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: List.generate(itemsPerRow, (i) {
              final wph = i < row.length ? row[i] : null;
              final isNull = wph == null;
              final cell = Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                decoration: BoxDecoration(
                  color: isNull
                      ? theme.colorScheme.surfaceContainerHighest
                      : theme.colorScheme.primaryContainer.withAlpha(80),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isNull
                        ? theme.colorScheme.outlineVariant.withAlpha(50)
                        : theme.colorScheme.primary.withAlpha(60),
                    width: 0.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  isNull ? '—' : wph.toString(),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isNull
                        ? theme.colorScheme.onSurfaceVariant.withAlpha(120)
                        : theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              );

              if (i < itemsPerRow - 1) {
                return Expanded(child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: cell,
                ));
              }
              return Expanded(child: cell);
            }),
          ),
        );
      }).toList(),
    );
  }
}
