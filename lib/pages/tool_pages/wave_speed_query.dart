import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:grow_castle_calculator/l10n/app_localizations.dart';
import 'package:grow_castle_calculator/providers/wave_speed_query_provider.dart';

class WaveSpeedQueryPage extends StatefulWidget {
  const WaveSpeedQueryPage({super.key});

  @override
  State<WaveSpeedQueryPage> createState() => _WaveSpeedQueryPageState();
}

class _WaveSpeedQueryPageState extends State<WaveSpeedQueryPage>
    with WidgetsBindingObserver {
  bool _isLoading = true;

  // ── Dropdown entry data ─────────────────────────────────────────────────

  static const double _dropdownWidth = 130;

  static const _gameSpeedEntries = [
    DropdownMenuEntry<int>(value: 0, label: '2速'),
    DropdownMenuEntry<int>(value: 1, label: '2速+10广'),
    DropdownMenuEntry<int>(value: 2, label: '3速'),
  ];

  static const _chronoTypeEntries = [
    DropdownMenuEntry<int>(value: 0, label: '白闹钟(+10%)'),
    DropdownMenuEntry<int>(value: 1, label: '黄闹钟(+14%)'),
    DropdownMenuEntry<int>(value: 2, label: '蓝闹钟(+20%)'),
  ];

  static const _equipHornEntries = [
    DropdownMenuEntry<bool>(value: false, label: '未装备'),
    DropdownMenuEntry<bool>(value: true, label: '已装备'),
  ];

  static const _equipGoldenHornEntries = [
    DropdownMenuEntry<bool>(value: false, label: '未装备'),
    DropdownMenuEntry<bool>(value: true, label: '已装备'),
  ];

  static const _devilHornEntries = [
    DropdownMenuEntry<int>(value: 1, label: '无'),
    DropdownMenuEntry<int>(value: 2, label: '+1'),
    DropdownMenuEntry<int>(value: 3, label: '+2'),
    DropdownMenuEntry<int>(value: 4, label: '+3'),
    DropdownMenuEntry<int>(value: 5, label: '+4'),
    DropdownMenuEntry<int>(value: 6, label: '+5'),
  ];

  static const _autoBattleEntries = [
    DropdownMenuEntry<bool>(value: true, label: '金挂(GAB)'),
    DropdownMenuEntry<bool>(value: false, label: '时挂(TAB)'),
  ];

  // ── Lifecycle ───────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final provider = context.read<WaveSpeedQueryProvider>();
    provider.init().then((_) {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      FocusScope.of(context).unfocus();
    }
  }

  // ── Build helpers ───────────────────────────────────────────────────────

  /// Dropdown selector for the right side of a setting row.
  Widget _compactDropdown<T>({
    required T value,
    required List<DropdownMenuEntry<T>> entries,
    required ValueChanged<T?> onChanged,
  }) {
    final theme = Theme.of(context);
    return SizedBox(
      width: _dropdownWidth,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          alignment: AlignmentDirectional.centerEnd,
          value: value,
          isExpanded: true,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          icon: Icon(
            Icons.arrow_drop_down,
            size: 22,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          borderRadius: BorderRadius.circular(8),
          selectedItemBuilder: (_) => entries.map((e) {
            return Align(
              alignment: Alignment.centerRight,
              child: Text(
                e.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.right,
              ),
            );
          }).toList(),
          items: entries.map((e) {
            return DropdownMenuItem<T>(
              value: e.value,
              child: SizedBox(
                width: _dropdownWidth - 32, // compensate for icon + padding
                child: Text(
                  e.label,
                  style: theme.textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  /// A ListTile-like row: label (and optional info button) on the left,
  /// dropdown on the right.
  Widget _settingRow<T>({
    required String label,
    Widget? infoContent,
    required T value,
    required List<DropdownMenuEntry<T>> entries,
    required ValueChanged<T?> onChanged,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (infoContent != null) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(label),
                          content: infoContent,
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(AppLocalizations.of(context)!.cancel),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Icon(
                      Icons.info_outline,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          _compactDropdown<T>(
            value: value,
            entries: entries,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.waveSpeedQuery),
          elevation: 1,
          backgroundColor: theme.scaffoldBackgroundColor,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Consumer<WaveSpeedQueryProvider>(
                builder: (context, provider, child) {
                  final data = provider.data;
                  return CustomScrollView(
                    slivers: [
                      // ── Hero results ────────────────────────────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                          child: Card(
                            elevation: 0,
                            color: theme.colorScheme.primaryContainer,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _heroMetric(
                                      theme,
                                      label: 'WPH',
                                      value: '${provider.wph}',
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 36,
                                    color: theme.colorScheme.onPrimaryContainer
                                        .withAlpha(40),
                                  ),
                                  Expanded(
                                    child: _heroMetric(
                                      theme,
                                      label: 'WPS',
                                      value: '${provider.wps}',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // ── Parameters ──────────────────────────────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                          child: Card(
                            elevation: 0,
                            color: theme.colorScheme.surfaceContainerHighest,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              child: Column(
                                children: [
                                  _settingRow<int>(
                                    label: '游戏速度',
                                    value: data.gameSpeed,
                                    entries: _gameSpeedEntries,
                                    onChanged: (v) {
                                      if (v != null) {
                                        provider.setGameSpeed(v);
                                      }
                                    },
                                  ),
                                  _settingRow<int>(
                                    label: '闹钟类型',
                                    value: data.chronoBonus,
                                    entries: _chronoTypeEntries,
                                    onChanged: (v) {
                                      if (v != null) {
                                        provider.setChronoBonus(v);
                                      }
                                    },
                                  ),
                                  _settingRow<bool>(
                                    label: '10%角',
                                    value: data.equipHorn,
                                    entries: _equipHornEntries,
                                    onChanged: (v) {
                                      if (v != null) {
                                        provider.setEquipHorn(v);
                                      }
                                    },
                                  ),
                                  _settingRow<bool>(
                                    label: '30%角',
                                    value: data.equipGoldenHorn,
                                    entries: _equipGoldenHornEntries,
                                    onChanged: (v) {
                                      if (v != null) {
                                        provider.setEquipGoldenHorn(v);
                                      }
                                    },
                                  ),
                                  _settingRow<int>(
                                    label: '恶魔号角跳波数',
                                    value: data.devilHornSkip,
                                    entries: _devilHornEntries,
                                    onChanged: (v) {
                                      if (v != null) {
                                        provider.setDevilHornSkip(v);
                                      }
                                    },
                                  ),
                                  _settingRow<bool>(
                                    label: '挂机类型',
                                    value: data.isGoldAutoBattle,
                                    entries: _autoBattleEntries,
                                    infoContent: _autoBattleInfo(context),
                                    onChanged: (v) {
                                      if (v != null) {
                                        provider.setIsGoldAutoBattle(v);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],
                  );
                },
              ),
      ),
    );
  }

  // ── Sub-widgets ─────────────────────────────────────────────────────────

  Widget _heroMetric(ThemeData theme,
      {required String label, required String value}) {
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onPrimaryContainer.withAlpha(179),
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _autoBattleInfo(BuildContext context) {
    return const Text('时挂 (TAB) 选项默认启用释放乐队技能 (BAND SKILL) ，且兽人号角 (ORC BAND) 和经验号角 (MILITARY BANDS(F)) 同时上场。');
  }
}
