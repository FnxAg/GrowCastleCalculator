import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:grow_castle_calculator/l10n/app_localizations.dart';
import 'package:grow_castle_calculator/services/preferences_service.dart';
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
      _dynamicFormNum = data['dynamicFormNum'] as int;
      CalculatorPage.waveValue = (data['waveValue'] as List<String>)
          .map(int.parse)
          .toList();
      _targetName = List<String>.from(data['targetName'] as List);
      if (_targetName.length < _maxFormLimit - _defaultFormCount) {
        _targetName = List.filled(_maxFormLimit - _defaultFormCount, '');
      }
      _targetLevel = (data['targetLevel'] as List<String>)
          .map(int.parse)
          .toList();
      if (_targetLevel.length < _maxFormLimit) {
        _targetLevel = List.filled(_maxFormLimit, 10000);
      }
      _targetCheckbox = (data['targetCheckbox'] as List<String>)
          .map((e) => e == 'true')
          .toList();
      if (_targetCheckbox.length < _maxFormLimit) {
        _targetCheckbox = List.filled(_maxFormLimit, true);
      }
      _syncControllers();
    });
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
      dynamicFormNum: _dynamicFormNum,
      waveValue: CalculatorPage.waveValue.map((e) => e.toString()).toList(),
      targetName: _targetName,
      targetLevel: _targetLevel.map((e) => e.toString()).toList(),
      targetCheckbox: _targetCheckbox.map((e) => e.toString()).toList(),
    );
  }

  Future<void> _clearFormData() async {
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

    final progress = calculateSeasonProgress(_now);

    // Set default names for the two fixed rows (Castle / Town Archer).
    _defaultFormNameControllers[0].text =
        AppLocalizations.of(context)!.castleDefault;
    _defaultFormNameControllers[1].text =
        AppLocalizations.of(context)!.taDefault;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.calculator),
        elevation: 1,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                InkWell(
                  onTap: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    showSeasonProgressDialog(context, _now);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      const Icon(Icons.timer),
                      const SizedBox(width: 4),
                      Column(
                        children: [
                          Text(
                            '${(progress.seasonProgress * 100).toStringAsFixed(2)}%',
                          ),
                          Text(
                            '${((CalculatorPage.seasonHours * (1 - progress.seasonProgress) / 24).truncateToDouble() / 1).toStringAsFixed(0)}d '
                            '${((CalculatorPage.seasonHours * (1 - progress.seasonProgress)) % 24).toStringAsFixed(0)}h',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // ── Wave value inputs ──────────────────────────────────────
              Row(
                spacing: 8,
                children: [
                  Expanded(
                    flex: 5,
                    child: TextField(
                      controller: _waveValueControllers[0],
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.currentWave,
                        hintText:
                            AppLocalizations.of(context)!.enterCurrentWave,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          CalculatorPage.waveValue[0] =
                              convertStringToInt(value);
                        });
                      },
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: TextField(
                      controller: _waveValueControllers[1],
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText:
                            AppLocalizations.of(context)!.currentSeasonalWave,
                        hintText: AppLocalizations.of(context)!
                            .enterCurrentSeasonalWave,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          CalculatorPage.waveValue[1] =
                              convertStringToInt(value);
                        });
                      },
                    ),
                  ),
                ],
              ),

              // ── Summary row ────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                spacing: 8,
                children: [
                  Text(
                    AppLocalizations.of(context)!.totalGold + _totalGoldString,
                  ),
                  Text(
                    AppLocalizations.of(context)!.wph +
                        (CalculatorPage.waveValue[1] /
                                (CalculatorPage.seasonHours *
                                    progress.seasonProgress))
                            .toStringAsFixed(2),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                spacing: 8,
                children: [
                  Text(
                    AppLocalizations.of(context)!.gp +
                        (_totalGold /
                                (0.5 *
                                    (310 +
                                        CalculatorPage.waveValue[0] * 310) *
                                    CalculatorPage.waveValue[0]) *
                                100)
                            .toStringAsFixed(2),
                  ),
                  Text(
                    AppLocalizations.of(context)!.ratio +
                        (_totalGold /
                                (CalculatorPage.waveValue[0] *
                                    CalculatorPage.waveValue[0]))
                            .toStringAsFixed(2),
                  ),
                ],
              ),

              // ── Unit list ──────────────────────────────────────────────
              Expanded(
                child: ListView.builder(
                  itemCount: _dynamicFormNum,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                      child: Column(
                        children: [
                          Row(
                            spacing: 8,
                            children: [
                              Expanded(
                                flex: 1,
                                child: Checkbox(
                                  value: _targetCheckbox[index],
                                  onChanged: (value) {
                                    setState(() {
                                      _targetCheckbox[index] = value ?? false;
                                    });
                                  },
                                ),
                              ),
                              Expanded(
                                flex: 4,
                                child: TextField(
                                  controller: index < _defaultFormCount
                                      ? _defaultFormNameControllers[index]
                                      : _targetNameControllers[
                                          index - _defaultFormCount],
                                  readOnly: index < _defaultFormCount,
                                  decoration: InputDecoration(
                                    labelText: AppLocalizations.of(context)!
                                        .unitName(index + 1),
                                    hintText: AppLocalizations.of(context)!
                                        .enterUnitName,
                                    border: const OutlineInputBorder(),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _targetName[index - _defaultFormCount] =
                                          value;
                                    });
                                  },
                                ),
                              ),
                              Expanded(
                                flex: 5,
                                child: TextField(
                                  controller: _targetLevelControllers[index],
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: InputDecoration(
                                    labelText: AppLocalizations.of(context)!
                                        .unitLevel,
                                    hintText: AppLocalizations.of(context)!
                                        .enterUnitLevel,
                                    border: const OutlineInputBorder(),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _targetLevel[index] =
                                          convertStringToInt(value);
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            spacing: 8,
                            children: [
                              Text(_targetGoldString[index]),
                              Text(
                                '${_targetCheckbox[index] ? (_targetGold[index] / _totalGold * 100).toStringAsFixed(2) : '0.00'}%',
                              ),
                              Text(
                                (_targetLevel[index] /
                                        CalculatorPage.waveValue[0])
                                    .toStringAsFixed(3),
                              ),
                              Text(
                                (CalculatorPage.waveValue[0] /
                                        _targetLevel[index])
                                    .toStringAsFixed(2),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // ── Action buttons ─────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 8,
                children: [
                  Tooltip(
                    message: AppLocalizations.of(context)!.clearInputFields,
                    child: ElevatedButton(
                      onPressed: () => setState(_clearFormData),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(12),
                      ),
                      child: const Icon(Icons.delete),
                    ),
                  ),
                  Tooltip(
                    message: AppLocalizations.of(context)!.loadData,
                    child: ElevatedButton(
                      onPressed: () => setState(() {
                        _loadData();
                      }),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(12),
                      ),
                      child: const Icon(Icons.download),
                    ),
                  ),
                  Tooltip(
                    message: AppLocalizations.of(context)!.remove,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          if (_dynamicFormNum > _minFormLimit) {
                            _dynamicFormNum--;
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(12),
                      ),
                      child: const Icon(Icons.remove),
                    ),
                  ),
                  Tooltip(
                    message: AppLocalizations.of(context)!.add,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          if (_dynamicFormNum < _maxFormLimit) {
                            _dynamicFormNum++;
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(12),
                      ),
                      child: const Icon(Icons.add),
                    ),
                  ),
                  Tooltip(
                    message: AppLocalizations.of(context)!.save,
                    child: ElevatedButton(
                      onPressed: _saveData,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(12),
                      ),
                      child: const Icon(Icons.save),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
