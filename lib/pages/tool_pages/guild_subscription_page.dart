import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:grow_castle_calculator/l10n/app_localizations.dart';
import 'package:grow_castle_calculator/services/player_api_service.dart';
import 'package:grow_castle_calculator/pages/tool_pages/player_info_query.dart';
import 'package:grow_castle_calculator/services/preferences_service.dart';
import 'package:grow_castle_calculator/utils/game_calculations.dart';
import 'package:grow_castle_calculator/utils/page_transitions.dart';

class GuildSubscriptionPage extends StatefulWidget {
  const GuildSubscriptionPage({super.key});

  static const int seasonHours = 120;

  @override
  State<GuildSubscriptionPage> createState() => _GuildSubscriptionPageState();
}

class _GuildSubscriptionPageState extends State<GuildSubscriptionPage>
    with WidgetsBindingObserver {
  final TextEditingController _guildNameController = TextEditingController();

  bool _isQuerying = false;
  DateTime? _lastQueryTime;

  bool _hasResult = false;
  String _guildName = '';
  int _totalScore = 0;
  List<GuildMember> _members = [];
  Map<String, String> _lastOnline = {};
  DateTime? _lastUpdateTime;
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
    _loadAndAutoSubscribe();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _guildNameController.dispose();
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
    } else if (state == AppLifecycleState.resumed && _hasResult) {
      _fetchMembers();
      _fetchTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        _fetchMembers();
      });
    }
  }

  Future<void> _loadAndAutoSubscribe() async {
    final savedName = await PreferencesService.loadGuildSubscriptionName();
    if (savedName == null || savedName.isEmpty || !mounted) return;

    _guildNameController.text = savedName;
    // Auto-subscribe without debounce.
    setState(() => _isQuerying = true);

    final result = await PlayerApiService.queryGuildDetail(savedName);

    if (!mounted) return;

    setState(() {
      _isQuerying = false;
      switch (result) {
        case List<GuildMember> members:
          _guildName = savedName;
          _members = members;
          _totalScore =
              members.fold<int>(0, (sum, m) => sum + m.score);
          _hasResult = true;
          _lastUpdateTime = DateTime.now();

          _fetchTimer?.cancel();
          _fetchTimer = Timer.periodic(const Duration(seconds: 10), (_) {
            _fetchMembers();
          });

          _fetchLastOnline(members);
        default:
          break;
      }
    });
  }

  Future<void> _subscribe() async {
    final loc = AppLocalizations.of(context)!;
    final name = _guildNameController.text.trim();
    if (name.isEmpty) return;

    // Debounce.
    final now = DateTime.now();
    if (_lastQueryTime != null &&
        now.difference(_lastQueryTime!).inSeconds < 3) {
      _showToast(loc.tooManyRequests);
      return;
    }
    _lastQueryTime = now;

    setState(() => _isQuerying = true);

    final result = await PlayerApiService.queryGuildDetail(name);

    if (!mounted) return;

    setState(() {
      _isQuerying = false;
      switch (result) {
        case List<GuildMember> members:
          _guildName = name;
          _members = members;
          _totalScore =
              members.fold<int>(0, (sum, m) => sum + m.score);
          _hasResult = true;
          _lastUpdateTime = DateTime.now();

          // Persist guild name.
          PreferencesService.saveGuildSubscriptionName(name);

          // Fetch last-online for members.
          _fetchLastOnline(members);

          // Start auto-refresh.
          _fetchTimer?.cancel();
          _fetchTimer = Timer.periodic(const Duration(seconds: 10), (_) {
            _fetchMembers();
          });
        case TimeoutError():
          _showToast(loc.nameNotFound);
        case NetworkError():
          _showToast(loc.nameNotFound);
        default:
          break;
      }
    });
  }

  Future<void> _fetchLastOnline(List<GuildMember> members) async {
    final results = await Future.wait(
      members.map((m) => PlayerApiService.query(m.name)),
    );

    if (!mounted) return;

    final online = <String, String>{};
    for (int i = 0; i < members.length; i++) {
      final r = results[i];
      if (r is PlayerQueryResult) {
        online[members[i].name] =
            PlayerApiService.formatLastOnline(r.queryDate, _now);
      }
    }

    setState(() => _lastOnline = online);
  }

  Future<void> _fetchMembers() async {
    final result =
        await PlayerApiService.queryGuildDetail(_guildName);

    if (!mounted) return;

    setState(() {
      switch (result) {
        case List<GuildMember> members:
          _members = members;
          _totalScore =
              members.fold<int>(0, (sum, m) => sum + m.score);
          _lastUpdateTime = DateTime.now();
          _errorMessage = null;
        case TimeoutError():
          _errorMessage = 'Timeout';
        case NetworkError(:final message):
          _errorMessage = message;
        default:
          _errorMessage = 'Unknown error';
      }
    });

    if (result is List<GuildMember>) {
      _fetchLastOnline(result);
    }
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

  String _formatUpdateTime(DateTime? time) {
    if (time == null) return '';
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(time.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final progress = calculateSeasonProgress(_now);

    return PopScope(
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          appBar: AppBar(
            title: Text(loc.guildSubscription),
            elevation: 1,
            backgroundColor: theme.scaffoldBackgroundColor,
            actions: [
              if (_errorMessage != null)
                IconButton(
                  icon: Icon(Icons.warning_amber,
                      color: Colors.orange.shade300),
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
            ],
          ),
          body: CustomScrollView(
            slivers: [
              // ── Input row ──────────────────────────────────────────
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
                              controller: _guildNameController,
                              decoration: InputDecoration(
                                labelText: loc.guildName,
                                hintText: loc.guildName,
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
                                  _isQuerying ? null : _subscribe,
                              child: _isQuerying
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(loc.subscribe),
                            ),
                          ),
                        ],
                      ),
                      if (_hasResult) ...[
                        const SizedBox(height: 8),
                        // ── Guild summary card ──────────────────────
                        _buildSummaryCard(loc, theme, progress),
                      ],
                    ],
                  ),
                ),
              ),
              // ── Member list ─────────────────────────────────────────
              if (_hasResult)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 4),
                    child: _buildHeaderCard(theme, loc),
                  ),
                ),
              if (_hasResult)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildMemberCard(
                        context, index, theme, progress.seasonProgress),
                    childCount: _members.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
      AppLocalizations loc, ThemeData theme, SeasonProgress progress) {
    final guildWph = progress.seasonProgress > 0
        ? (_totalScore /
                (GuildSubscriptionPage.seasonHours *
                    progress.seasonProgress))
            .toStringAsFixed(0)
        : '—';

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _guildName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (_lastUpdateTime != null)
                  Text(
                    _formatUpdateTime(_lastUpdateTime),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  _summaryChip(
                      loc.seasonalScore, _totalScore.toString(), theme),
                  const SizedBox(width: 12),
                  _summaryChip(loc.seasonalWph, guildWph, theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(ThemeData theme, AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withAlpha(100)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
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
          const SizedBox(width: 4),
          SizedBox(
            width: 64,
            child: Text(
              loc.seasonalScore,
              textAlign: TextAlign.end,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 44,
            child: Text(
              'WPH',
              textAlign: TextAlign.end,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 48,
            child: Text(
              'Online',
              textAlign: TextAlign.end,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(
      BuildContext context, int index, ThemeData theme, double seasonProgress) {
    final member = _members[index];
    final rank = index + 1;
    final wph = seasonProgress > 0
        ? (member.score /
                (GuildSubscriptionPage.seasonHours * seasonProgress))
            .toStringAsFixed(0)
        : '—';
    final online = _lastOnline[member.name] ?? '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              smoothPageRoute(
                builder: (_) =>
                    PlayerInfoQueryPage(initialName: member.name),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Text(
                    rank.toString(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: rank <= 3
                          ? theme.colorScheme.primary
                          : null,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    member.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 64,
                  child: Text(
                    member.score.toString(),
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 44,
                  child: Text(
                    wph,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 48,
                  child: Text(
                    online,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Divider(
          height: 0,
          thickness: 0.5,
          indent: 16,
          endIndent: 16,
          color: theme.dividerColor.withAlpha(80),
        ),
      ],
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
