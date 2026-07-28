import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:grow_castle_calculator/l10n/app_localizations.dart';
import 'package:grow_castle_calculator/models/calculator_archive.dart';
import 'package:grow_castle_calculator/models/calculator_data.dart';
import 'package:grow_castle_calculator/pages/history_archives_page.dart';
import 'package:grow_castle_calculator/services/player_api_service.dart';
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
  Timer? _autoRefreshTimer;

  // ── Player query state ──────────────────────────────────────────────────
  bool _isOnlineQuery = true;
  final TextEditingController _gameNameController = TextEditingController();
  DateTime? _lastQueryTime;
  bool _isQuerying = false;
  String? _lastQueryDate;
  int _queriedWave = 0;
  int _queriedScore = 0;
  bool _hasQueryResult = false;
  String? _loadedArchiveId;

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
    _gameNameController.dispose();
    _timer.cancel();
    _autoRefreshTimer?.cancel();
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
      _autoRefreshTimer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      _saveData();
      if (_shouldAutoRefresh) _startAutoRefresh();
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
      _isOnlineQuery = data.isOnlineQuery;
      _gameNameController.text = data.gameName;
      _queriedWave = data.queriedWave;
      _queriedScore = data.queriedScore;
      _lastQueryDate = data.lastQueryDate;
      _hasQueryResult = data.hasQueryResult;
      _loadedArchiveId = data.loadedArchiveId;
      _syncControllers();
    });
    // Load column visibility (UI preference, not in CalculatorData).
    final prefs = await SharedPreferences.getInstance();
    final savedCols = prefs.getStringList('calc_visible_columns');
    if (savedCols != null && savedCols.length == 4) {
      _visibleColumns = savedCols.map((e) => e == 'true').toList();
    }

    // Resume auto-refresh if applicable.
    if (_shouldAutoRefresh) _startAutoRefresh();
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
        isOnlineQuery: _isOnlineQuery,
        gameName: _gameNameController.text,
        queriedWave: _queriedWave,
        queriedScore: _queriedScore,
        lastQueryDate: _lastQueryDate,
        hasQueryResult: _hasQueryResult,
        loadedArchiveId: _loadedArchiveId,
      ),
    );
  }

  void _clearFormData() {
    setState(() {
      // Reset state to defaults.
      _dynamicFormNum = 7;
      CalculatorPage.waveValue = [1000000, 40000];
      _targetName = List.filled(_maxFormLimit - _defaultFormCount, '');
      _targetLevel = List.filled(_maxFormLimit, 10000);
      _targetCheckbox = List.filled(_maxFormLimit, true);
      _isOnlineQuery = true;

      // Sync controllers to reflect the reset state.
      _syncControllers();
      _gameNameController.clear();

      // Reset query state.
      _hasQueryResult = false;
      _stopAutoRefresh();
      _queriedWave = 0;
      _queriedScore = 0;
      _lastQueryDate = null;
      _loadedArchiveId = null;
    });
  }

  // ── Archive operations ─────────────────────────────────────────────────

  /// Opens a dialog for the user to name and save the current state as an
  /// archive.
  Future<void> _showSaveArchiveDialog() async {
    final loc = AppLocalizations.of(context)!;
    final gameName = _gameNameController.text.trim();
    final defaultName = gameName.isNotEmpty
        ? gameName
        : DateFormat('yyyyMMddHHmmss').format(DateTime.now());
    final controller = TextEditingController(text: defaultName);

    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.saveArchive),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: loc.archiveName,
            hintText: loc.enterArchiveName,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(loc.save),
          ),
        ],
      ),
    );

    controller.dispose();
    if (name == null || name.trim().isEmpty) return;

    final now = DateTime.now();
    final archive = CalculatorArchive(
      id: now.microsecondsSinceEpoch.toString(),
      name: name.trim(),
      savedAt: now,
      updatedAt: now,
      isOnlineQuery: _isOnlineQuery,
      gameName: gameName,
      dynamicFormNum: _dynamicFormNum,
      waveValue: CalculatorPage.waveValue.toList(),
      targetName: _targetName.toList(),
      targetLevel: _targetLevel.toList(),
      targetCheckbox: _targetCheckbox.toList(),
      visibleColumns: _visibleColumns.toList(),
      queriedWave: _queriedWave,
      queriedScore: _queriedScore,
      lastQueryDate: _lastQueryDate,
      hasQueryResult: _hasQueryResult,
    );

    final archives = await PreferencesService.loadArchives();
    archives.insert(0, archive); // newest first
    await PreferencesService.saveArchives(archives);

    _loadedArchiveId = archive.id;
    _saveData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${loc.saveArchive}: ${archive.name}')),
      );
    }
  }

  /// Opens the history archives page and applies the selected archive if
  /// the user chooses to load one.
  Future<void> _openHistoryArchives() async {
    final archive = await Navigator.push<CalculatorArchive>(
      context,
      MaterialPageRoute(
        builder: (_) => const HistoryArchivesPage(),
      ),
    );
    if (archive != null) {
      _applyArchive(archive);
    }
  }

  /// Applies the data from [archive] to the current calculator state.
  void _applyArchive(CalculatorArchive archive) {
    setState(() {
      _dynamicFormNum = archive.dynamicFormNum;
      CalculatorPage.waveValue = archive.waveValue.toList();
      _targetName = _padList(
        archive.targetName.toList(),
        '',
        _maxFormLimit - _defaultFormCount,
      );
      _targetLevel = _padList(archive.targetLevel.toList(), 10000, _maxFormLimit);
      _targetCheckbox = _padList(
        archive.targetCheckbox.toList(),
        true,
        _maxFormLimit,
      );
      _visibleColumns = archive.visibleColumns.toList();
      _isOnlineQuery = archive.isOnlineQuery;
      _gameNameController.text = archive.gameName;
      _queriedWave = archive.queriedWave;
      _queriedScore = archive.queriedScore;
      _lastQueryDate = archive.lastQueryDate;
      _hasQueryResult = archive.hasQueryResult;
      _loadedArchiveId = archive.id;
      _syncControllers();
    });
    _saveData();
    _saveColumnVisibility();
  }

  Future<void> _updateCurrentArchive() async {
    if (_loadedArchiveId == null) return;
    final loc = AppLocalizations.of(context)!;
    final archives = await PreferencesService.loadArchives();
    final index = archives.indexWhere((a) => a.id == _loadedArchiveId);
    if (index == -1) {
      _loadedArchiveId = null;
      return;
    }

    final old = archives[index];
    final now = DateTime.now();
    archives[index] = CalculatorArchive(
      id: old.id,
      name: old.name,
      savedAt: old.savedAt,
      updatedAt: now,
      isOnlineQuery: _isOnlineQuery,
      gameName: _gameNameController.text.trim(),
      dynamicFormNum: _dynamicFormNum,
      waveValue: CalculatorPage.waveValue.toList(),
      targetName: _targetName.toList(),
      targetLevel: _targetLevel.toList(),
      targetCheckbox: _targetCheckbox.toList(),
      visibleColumns: _visibleColumns.toList(),
      queriedWave: _queriedWave,
      queriedScore: _queriedScore,
      lastQueryDate: _lastQueryDate,
      hasQueryResult: _hasQueryResult,
    );
    await PreferencesService.saveArchives(archives);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${loc.updateArchive}: ${old.name}')),
      );
    }
  }

  // ── Player query ───────────────────────────────────────────────────────

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

    setState(() => _isQuerying = false);

    switch (result) {
      case PlayerQueryResult(:final wave, :final seasonalScore,
            :final queryDate):
        _lastQueryDate = _formatQueryDate(queryDate);
        _queriedWave = wave;
        _queriedScore = seasonalScore;
        _hasQueryResult = true;

        // Start auto-refresh.
        _startAutoRefresh();

        // Update wave values.
        CalculatorPage.waveValue[0] = wave;
        CalculatorPage.waveValue[1] = seasonalScore;
        _waveValueControllers[0].text = wave.toString();
        _waveValueControllers[1].text = seasonalScore.toString();
        setState(() {});

      case NameNotFound():
        _showToast(loc.nameNotFound);
        setState(() {});

      case TimeoutError():
        _showToast(loc.nameNotFound);
        setState(() {});

      case NetworkError():
        _showToast(loc.nameNotFound);
        setState(() {});

      default:
        setState(() {});
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

  // ── Auto-refresh ────────────────────────────────────────────────────────

  bool get _shouldAutoRefresh =>
      _isOnlineQuery && _hasQueryResult && _gameNameController.text.trim().isNotEmpty;

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _queryPlayer();
    });
  }

  void _stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
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

  // ── Reorder ──────────────────────────────────────────────────────────────

  void _reorderUnitCards(int oldIndex, int newIndex) {
    // First two slots (castle / TA) are pinned — ignore drags involving them.
    if (oldIndex < _defaultFormCount || newIndex < _defaultFormCount) return;

    setState(() {
      // When moving down, the target index shifts up after removal.
      final to = oldIndex < newIndex ? newIndex - 1 : newIndex;

      void swap(List<dynamic> list, int i, int j) {
        final temp = list[i];
        list[i] = list[j];
        list[j] = temp;
      }

      // Swap level / checkbox / gold data (full-size lists, indices 0.._maxFormLimit-1).
      swap(_targetLevel, oldIndex, to);
      swap(_targetCheckbox, oldIndex, to);
      swap(_targetGold, oldIndex, to);
      swap(_targetGoldString, oldIndex, to);

      // Swap level controller text.
      final tmpLevel = _targetLevelControllers[oldIndex].text;
      _targetLevelControllers[oldIndex].text = _targetLevelControllers[to].text;
      _targetLevelControllers[to].text = tmpLevel;

      // Swap name data — indices 0..1 use _defaultFormNameControllers,
      // indices ≥2 use _targetName / _targetNameControllers.
      String readName(int idx) => idx < _defaultFormCount
          ? _defaultFormNameControllers[idx].text
          : _targetName[idx - _defaultFormCount];

      void writeName(int idx, String v) {
        if (idx < _defaultFormCount) {
          _defaultFormNameControllers[idx].text = v;
        } else {
          _targetName[idx - _defaultFormCount] = v;
          _targetNameControllers[idx - _defaultFormCount].text = v;
        }
      }

      final tmpName = readName(oldIndex);
      writeName(oldIndex, readName(to));
      writeName(to, tmpName);
    });
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
                case 'save':
                  _showSaveArchiveDialog();
                case 'display_settings':
                  _showDisplaySettingsDialog();
                case 'history_archives':
                  _openHistoryArchives();
                case 'update_archive':
                  _updateCurrentArchive();
                case 'mode_online':
                  setState(() => _isOnlineQuery = true);
                case 'mode_free':
                  setState(() {
                    _isOnlineQuery = false;
                    _stopAutoRefresh();
                  });
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'mode_online',
                child: ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(loc.onlineQuery),
                  trailing: _isOnlineQuery
                      ? Icon(Icons.check, color: theme.colorScheme.primary)
                      : null,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'mode_free',
                child: ListTile(
                  leading: const Icon(Icons.edit),
                  title: Text(loc.freeInput),
                  trailing: !_isOnlineQuery
                      ? Icon(Icons.check, color: theme.colorScheme.primary)
                      : null,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'display_settings',
                child: ListTile(
                  leading: const Icon(Icons.view_column),
                  title: const Text('显示设置'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'history_archives',
                child: ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(loc.historyArchives),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (_loadedArchiveId != null) ...[
                PopupMenuItem(
                  value: 'update_archive',
                  child: ListTile(
                    leading: const Icon(Icons.update),
                    title: Text(loc.updateArchive),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
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
                    // ── Game name + query button (always shown) ────────
                    Row(
                      spacing: 8,
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

                    // ── Free-input wave fields ─────────────────────────
                    if (!_isOnlineQuery)
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
                                hintText:
                                    loc.enterCurrentSeasonalWave,
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

                    // ── Query result card (always shown) ───────────
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
                          spacing: 4,
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
                                if (_lastQueryDate != null)
                                  Text(
                                    _lastQueryDate!,
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
                            if (_hasQueryResult)
                              Row(
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
                                ],
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.symmetric(
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
            SliverReorderableList(
              itemBuilder: (context, index) =>
                  _buildUnitCard(context, index, theme, key: ValueKey(index)),
              itemCount: _dynamicFormNum,
              onReorder: _reorderUnitCards,
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

  Widget _buildUnitCard(BuildContext context, int index, ThemeData theme,
      {Key? key}) {
    final loc = AppLocalizations.of(context)!;

    return Padding(
      key: key,
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
              if (_visibleColumns.any((v) => v) ||
                  index >= _defaultFormCount)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: DefaultTextStyle(
                    style: theme.textTheme.bodySmall!,
                    child: Row(
                      children: [
                        if (index >= _defaultFormCount)
                          ReorderableDragStartListener(
                            index: index,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(Icons.drag_handle,
                                  size: 20,
                                  color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ),
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
