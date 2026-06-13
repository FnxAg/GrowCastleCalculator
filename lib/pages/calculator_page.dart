import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:grow_castle_calculator/l10n/app_localizations.dart';
import 'package:grow_castle_calculator/models/calculator_data.dart';
import 'package:grow_castle_calculator/services/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:grow_castle_calculator/utils/game_calculations.dart';
import 'package:grow_castle_calculator/utils/number_utils.dart';
import 'package:grow_castle_calculator/widgets/season_progress_dialog.dart';

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  static const int seasonHours = 120;
  static const int hellModeSeasonHours = 168;
  static const int seasonalColonyHours = 240;

  /// Shared wave values — also read by [GoldCalculator] for inheritance.
  static List<int> waveValue = [1000000, 40000];

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  // ── Form limits ────────────────────────────────────────────────────────

  static const int _minFormLimit = 2;
  static const int _maxFormLimit = 20;
  static const int _defaultFormCount = 2;

  // ── State ──────────────────────────────────────────────────────────────

  int _dynamicFormNum = 7;
  List<String> _targetName = [];
  List<int> _targetLevel = List.filled(_maxFormLimit, 10000);
  List<bool> _targetCheckbox = List.filled(_maxFormLimit, true);

  /// Which stats columns are visible: [gold, pct, invRatio, ratio].
  List<bool> _visibleColumns = List.filled(4, true);

  static const List<String> _columnLabels = ['经济', '占比', '1/比例', '比例'];

  late List<double> _targetGold;
  late List<String> _targetGoldString;
  late double _totalGold;
  late String _totalGoldString;

  DateTime _now = DateTime.now();
  late Timer _timer;

  // ── Controllers ────────────────────────────────────────────────────────

  final List<TextEditingController> _waveValueControllers =
      List.generate(2, (_) => TextEditingController());

  final List<TextEditingController> _targetNameControllers =
      List.generate(_maxFormLimit - _defaultFormCount, (_) => TextEditingController());

  final List<TextEditingController> _targetLevelControllers =
      List.generate(_maxFormLimit, (_) => TextEditingController());

  final List<TextEditingController> _defaultFormNameControllers =
      List.generate(_defaultFormCount, (_) => TextEditingController());

  // ── Lifecycle ──────────────────────────────────────────────────────────

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    for (final c in _waveValueControllers) {
      c.dispose();
    }
    for (final c in _targetNameControllers) {
      c.dispose();
    }
    for (final c in _targetLevelControllers) {
      c.dispose();
    }
    for (final c in _defaultFormNameControllers) {
      c.dispose();
    }
    _timer.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      FocusScope.of(context).unfocus();
      _saveData();
    } else if (state == AppLifecycleState.resumed) {
      _saveData();
    }
  }

  // ── Data persistence ───────────────────────────────────────────────────

  Future<void> _loadData() async {
    final data = await PreferencesService.loadCalculatorData();
    setState(() {
      _dynamicFormNum = data.dynamicFormNum;
      CalculatorPage.waveValue = data.waveValue.toList();
      _targetName = _padList(data.targetName, '', _maxFormLimit - _defaultFormCount);
      _targetLevel = _padList(data.targetLevel, 10000, _maxFormLimit);
      _targetCheckbox = _padList(data.targetCheckbox, true, _maxFormLimit);
      _syncControllers();
    });
    // Load column visibility (UI preference, not in CalculatorData).
    final prefs = await SharedPreferences.getInstance();
    final savedCols = prefs.getStringList('calc_visible_columns');
    if (savedCols != null && savedCols.length == 4) {
      _visibleColumns = savedCols.map((e) => e == 'true').toList();
    }
  }

  static List<T> _padList<T>(List<T> list, T fillValue, int minLength) {
    if (list.length >= minLength) return List<T>.from(list);
    return [...list, for (int i = list.length; i < minLength; i++) fillValue];
  }

  void _syncControllers() {
    for (int i = 0; i < _waveValueControllers.length; i++) {
      _waveValueControllers[i].text = CalculatorPage.waveValue[i].toString();
    }
    for (int i = 0; i < _maxFormLimit; i++) {
      _targetLevelControllers[i].text = _targetLevel[i].toString();
    }
    for (int i = 0; i < _targetName.length; i++) {
      _targetNameControllers[i].text = _targetName[i];
    }
  }

  Future<void> _saveData() async {
    await PreferencesService.saveCalculatorData(
      CalculatorData(
        dynamicFormNum: _dynamicFormNum,
        waveValue: CalculatorPage.waveValue,
        targetName: _targetName,
        targetLevel: _targetLevel,
        targetCheckbox: _targetCheckbox,
      ),
    );
  }

  void _clearFormData() {
    setState(() {
      for (final c in _waveValueControllers) {
        c.clear();
      }
      for (final c in _targetNameControllers) {
        c.clear();
      }
      for (final c in _targetLevelControllers) {
        c.clear();
      }
    });
  }

  // ── Column visibility ──────────────────────────────────────────────────

  Future<void> _saveColumnVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'calc_visible_columns',
      _visibleColumns.map((e) => e.toString()).toList(),
    );
  }

  void _showDisplaySettingsDialog() {
    // Work on a local copy so the dialog's Cancel can discard changes.
    final local = List<bool>.from(_visibleColumns);
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => SimpleDialog(
          title: const Text('显示设置'),
          children: [
            for (int i = 0; i < _columnLabels.length; i++)
              CheckboxListTile(
                value: local[i],
                title: Text(_columnLabels[i]),
                onChanged: (v) {
                  setDialogState(() => local[i] = v ?? false);
                },
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _visibleColumns = local);
                    _saveColumnVisibility();
                    Navigator.pop(ctx);
                  },
                  child: Text(AppLocalizations.of(context)!.confirm),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Computed values ────────────────────────────────────────────────────

  void _updateComputedValues(BuildContext context) {
    _targetGold = List.generate(_maxFormLimit, (i) {
      return waveLevelSpendGold(_targetLevel[i], i);
    });
    _targetGoldString =
        _targetGold.map((g) => decreaseNumSize(g, context)).toList();
    _totalGold = _targetGold
        .asMap()
        .entries
        .where((e) => e.key < _dynamicFormNum && _targetCheckbox[e.key])
        .map((e) => e.value)
        .fold<double>(0, (a, b) => a + b);
    _totalGoldString = decreaseNumSize(_totalGold, context);
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _updateComputedValues(context);

    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final progress = calculateSeasonProgress(_now);

    _defaultFormNameControllers[0].text = loc.castleDefault;
    _defaultFormNameControllers[1].text = loc.taDefault;

    final gpValue = (_totalGold /
            (0.5 * (310 + CalculatorPage.waveValue[0] * 310) *
                CalculatorPage.waveValue[0]) *
            100)
        .toStringAsFixed(2);
    final ratioValue = (_totalGold /
            (CalculatorPage.waveValue[0] * CalculatorPage.waveValue[0]))
        .toStringAsFixed(2);
    final wphValue = (CalculatorPage.waveValue[1] /
            (CalculatorPage.seasonHours * progress.seasonProgress))
        .toStringAsFixed(2);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.calculator),
        elevation: 1,
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          // ── Season timer ────────────────────────────────────────────────
          InkWell(
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
              showSeasonProgressDialog(context, _now);
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 2),
                  Text(
                    '${(progress.seasonProgress * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Add / Remove rows ──────────────────────────────────────────
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: loc.add,
            onPressed: _dynamicFormNum < _maxFormLimit
                ? () => setState(() => _dynamicFormNum++)
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.remove),
            tooltip: loc.remove,
            onPressed: _dynamicFormNum > _minFormLimit
                ? () => setState(() => _dynamicFormNum--)
                : null,
          ),

          // ── Overflow menu ──────────────────────────────────────────────
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'clear':
                  _clearFormData();
                case 'load':
                  _loadData();
                case 'save':
                  _saveData();
                case 'display_settings':
                  _showDisplaySettingsDialog();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'display_settings',
                child: ListTile(
                  leading: const Icon(Icons.view_column),
                  title: const Text('显示设置'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'clear',
                child: ListTile(
                  leading: const Icon(Icons.delete),
                  title: Text(loc.clearInputFields),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'load',
                child: ListTile(
                  leading: const Icon(Icons.download),
                  title: Text(loc.loadData),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'save',
                child: ListTile(
                  leading: const Icon(Icons.save),
                  title: Text(loc.save),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: CustomScrollView(
          slivers: [
            // ── Wave inputs + Summary ────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 8,
                  children: [
                    // Wave value inputs
                    Row(
                      spacing: 8,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _waveValueControllers[0],
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              labelText: loc.currentWave,
                              hintText: loc.enterCurrentWave,
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (v) => setState(() {
                              CalculatorPage.waveValue[0] =
                                  convertStringToInt(v);
                            }),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _waveValueControllers[1],
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              labelText: loc.currentSeasonalWave,
                              hintText: loc.enterCurrentSeasonalWave,
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (v) => setState(() {
                              CalculatorPage.waveValue[1] =
                                  convertStringToInt(v);
                            }),
                          ),
                        ),
                      ],
                    ),

                    // Summary card
                    Card(
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Column(
                          spacing: 4,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  loc.totalGold,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  _totalGoldString,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 1),
                            Row(
                              children: [
                                _summaryChip(
                                  loc.wph,
                                  wphValue,
                                  theme,
                                ),
                                const SizedBox(width: 12),
                                _summaryChip(
                                  loc.gp,
                                  gpValue,
                                  theme,
                                ),
                                const SizedBox(width: 12),
                                _summaryChip(
                                  loc.ratio,
                                  ratioValue,
                                  theme,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Unit list ────────────────────────────────────────────────
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildUnitCard(context, index, theme),
                childCount: _dynamicFormNum,
              ),
            ),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
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

  Widget _buildUnitCard(BuildContext context, int index, ThemeData theme) {
    final loc = AppLocalizations.of(context)!;

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
          padding: const EdgeInsets.fromLTRB(4, 6, 10, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Input row
              Row(
                spacing: 6,
                children: [
                  Checkbox(
                    value: _targetCheckbox[index],
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (value) {
                      setState(() {
                        _targetCheckbox[index] = value ?? false;
                      });
                    },
                  ),
                  Expanded(
                    flex: 4,
                    child: TextField(
                      controller: index < _defaultFormCount
                          ? _defaultFormNameControllers[index]
                          : _targetNameControllers[index - _defaultFormCount],
                      readOnly: index < _defaultFormCount,
                      decoration: InputDecoration(
                        labelText: loc.unitName(index + 1),
                        hintText: loc.enterUnitName,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight:
                            index < _defaultFormCount ? FontWeight.w600 : null,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _targetName[index - _defaultFormCount] = value;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _targetLevelControllers[index],
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        labelText: loc.unitLevel,
                        hintText: loc.enterUnitLevel,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _targetLevel[index] = convertStringToInt(value);
                        });
                      },
                    ),
                  ),
                ],
              ),

              // Stats row — only visible columns are rendered.
              if (_visibleColumns.any((v) => v))
                Padding(
                  padding: const EdgeInsets.only(left: 40, top: 4),
                  child: DefaultTextStyle(
                    style: theme.textTheme.bodySmall!,
                    child: Row(
                      children: [
                        if (_visibleColumns[0])
                          _statCell(
                            _targetGoldString[index],
                            _columnLabels[0],
                            theme,
                            bold: true,
                          ),
                        if (_visibleColumns[1])
                          _statCell(
                            '${_targetCheckbox[index] ? (_targetGold[index] / _totalGold * 100).toStringAsFixed(2) : '0.00'}%',
                            _columnLabels[1],
                            theme,
                          ),
                        if (_visibleColumns[2])
                          _statCell(
                            (_targetLevel[index] /
                                    CalculatorPage.waveValue[0])
                                .toStringAsFixed(3),
                            _columnLabels[2],
                            theme,
                          ),
                        if (_visibleColumns[3])
                          _statCell(
                            (CalculatorPage.waveValue[0] /
                                    _targetLevel[index])
                                .toStringAsFixed(2),
                            _columnLabels[3],
                            theme,
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCell(String value, String label, ThemeData theme,
      {bool bold = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            textAlign: TextAlign.center,
            style: bold
                ? TextStyle(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                    fontSize: 12,
                  )
                : const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
