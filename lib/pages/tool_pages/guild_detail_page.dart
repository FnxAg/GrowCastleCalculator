import 'dart:async';
import 'package:flutter/material.dart';
import 'package:grow_castle_calculator/l10n/app_localizations.dart';
import 'package:grow_castle_calculator/pages/tool_pages/player_info_query.dart';
import 'package:grow_castle_calculator/services/player_api_service.dart';
import 'package:grow_castle_calculator/utils/game_calculations.dart';

class GuildDetailPage extends StatefulWidget {
  const GuildDetailPage({super.key, required this.guildName});

  final String guildName;

  static const int seasonHours = 120;

  @override
  State<GuildDetailPage> createState() => _GuildDetailPageState();
}

class _GuildDetailPageState extends State<GuildDetailPage> {
  List<GuildMember> _members = [];
  Map<String, String> _lastOnline = {};
  bool _isLoading = true;
  String? _errorMessage;

  DateTime _now = DateTime.now();
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      setState(() => _now = DateTime.now());
    });
    _fetchMembers();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _fetchMembers() async {
    final result =
        await PlayerApiService.queryGuildDetail(widget.guildName);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      switch (result) {
        case List<GuildMember> members:
          _members = members;
          _errorMessage = null;
        case TimeoutError():
          _errorMessage = 'Timeout';
        case NetworkError(:final message):
          _errorMessage = message;
        default:
          _errorMessage = 'Unknown error';
      }
    });

    // Fetch last-online for each member (in parallel).
    if (result is List<GuildMember>) {
      _fetchLastOnline(result);
    }
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final progress = calculateSeasonProgress(_now);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.guildName),
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
        ],
      ),
      body: _isLoading && _members.isEmpty
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
                        (context, index) => _buildMemberCard(
                            context, index, theme, progress.seasonProgress),
                        childCount: _members.length,
                      ),
                    ),
                    const SliverToBoxAdapter(
                        child: SizedBox(height: 80)),
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
            const SizedBox(width: 8),
            SizedBox(
              width: 52,
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
      ),
    );
  }

  Widget _buildMemberCard(
      BuildContext context, int index, ThemeData theme, double seasonProgress) {
    final member = _members[index];
    final rank = index + 1;
    final wph = seasonProgress > 0
        ? (member.score /
                (GuildDetailPage.seasonHours * seasonProgress))
            .toStringAsFixed(0)
        : '—';
    final online = _lastOnline[member.name] ?? '';

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
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    PlayerInfoQueryPage(initialName: member.name),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
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
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 72,
                child: Text(
                  member.score.toString(),
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
              const SizedBox(width: 8),
              SizedBox(
                width: 52,
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
      ),
    );
  }
}
