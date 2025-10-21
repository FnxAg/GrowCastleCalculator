import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

int _convertStringToInt(String value) {
  if (value.isEmpty) {
    return 0;
  }
  try {
    return int.parse(value);
  } catch (e) {
    return 0;
  }
}

String _decreaseNumSize(double gold) {
  const suffixes = ['K', 'M', 'B', 'T', 'Qua', 'Qui', 'Sex', 'Sep'];
  double value = gold;
  int index = -1;

  while (value >= 1000000 && index < suffixes.length - 1) {
    value /= 1000;
    index++;
  }

  if (index == -1) {
    return gold.toStringAsFixed(0);
  }

  return '${value.toStringAsFixed(0)} ${suffixes[index]}';
}

double _heroLevelSpendGold(int level) {
  if (level <= 0) return 0;

  const thresholds = [
    10000,
    5000,
    200,
    180,
    160,
    140,
    120,
    100,
    80,
    60,
    40,
    20,
    1,
  ];
  const baseGold = [
    187458432500,
    37468432500,
    35632500,
    26157500,
    18530000,
    12530000,
    7997500,
    4712500,
    2475000,
    1085000,
    342500,
    47500,
    0,
  ];
  const baseMultiplier = [
    50000000,
    20000000,
    600000,
    450000,
    360000,
    280000,
    210000,
    150000,
    100000,
    60000,
    30000,
    10000,
    250,
  ];
  const increment = [
    5000,
    4000,
    3000,
    2500,
    2250,
    2000,
    1750,
    1500,
    1250,
    1000,
    750,
    500,
    250,
  ];

  for (int i = 0; i < thresholds.length; i++) {
    if (level > thresholds[i]) {
      final diff = level - thresholds[i];
      return ((baseMultiplier[i] * 2 + increment[i] * (diff - 1)) / 2 * diff) +
          baseGold[i];
    }
  }

  return 0;
}

class _CalculatorPageState extends State<CalculatorPage>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  List<int> _waveValue = List.generate(2, (index) => 1000000 - index * 960000);
  List<String> _targetName = List.filled(_maxFormLimit - _defaultForm, '');
  List<int> _targetLevel = List.filled(_maxFormLimit, 10000);
  List<bool> _targetCheckbox = List.filled(_maxFormLimit, true);
  List<double> get _targetGold => List.generate(_maxFormLimit, (index) {
    if (index == 0) {
      return _targetLevel[0] * _targetLevel[0] * 1250;
    } else if (index == 1) {
      return _targetLevel[1] * _targetLevel[1] * 500;
    } else {
      return _heroLevelSpendGold(_targetLevel[index]);
    }
  });
  List<String> get _targetGoldString => List.generate(_maxFormLimit, (index) {
    double gold = _targetGold[index];
    return _decreaseNumSize(gold);
  });

  late Timer _timer;

  double get _totalGold => _targetGold
      .asMap()
      .entries
      .where(
        (entry) => entry.key < _dynamicFormNum && _targetCheckbox[entry.key],
      )
      .map((entry) => entry.value)
      .fold<double>(0, (previousValue, element) => previousValue + element);

  String get _totalGoldString => _decreaseNumSize(_totalGold);

  int _dynamicFormNum = 7;
  static const int _minFormLimit = 2;
  static const int _maxFormLimit = 20;
  static const int _defaultForm = 2;

  @override
  bool get wantKeepAlive => true;

  Future<void> loadCalculatorData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dynamicFormNum = prefs.getInt('dynamicFormNum') ?? 7;
      _waveValue =
          prefs.getStringList('waveValue')?.map(int.parse).toList() ??
          [1000000, 40000];
      _targetName =
          prefs.getStringList('targetName') ??
          List.filled(_maxFormLimit - _defaultForm, '');
      _targetLevel =
          prefs.getStringList('targetLevel')?.map(int.parse).toList() ??
          List.filled(_maxFormLimit, 10000);
      _targetCheckbox =
          prefs.getStringList('targetCheckbox')?.map(bool.parse).toList() ??
          List.filled(_maxFormLimit, true);
      for (int i = 0; i < _waveValueControllers.length; i++) {
        _waveValueControllers[i].text = _waveValue[i].toString();
      }
      for (int i = 0; i < _maxFormLimit; i++) {
        _targetLevelControllers[i].text = _targetLevel[i].toString();
      }
      for (int i = 0; i < _maxFormLimit - _defaultForm; i++) {
        _targetNameControllers[i].text = _targetName[i];
      }
    });
  }

  Future<void> _saveCalculatorData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('dynamicFormNum', _dynamicFormNum);
    prefs.setStringList(
      'waveValue',
      _waveValue.map((e) => e.toString()).toList(),
    );
    prefs.setStringList('targetName', _targetName);
    prefs.setStringList(
      'targetLevel',
      _targetLevel.map((e) => e.toString()).toList(),
    );
    prefs.setStringList(
      'targetCheckbox',
      _targetCheckbox.map((e) => e.toString()).toList(),
    );
  }

  Future<void> _clearCalculatorFormData() async {
    setState(() {
      for (var c in _waveValueControllers) {
        c.text = '';
      }
      for (var c in _targetNameControllers) {
        c.text = '';
      }
      for (var c in _targetLevelControllers) {
        c.text = '';
      }
    });
  }

  DateTime now = DateTime.now();

  final List<TextEditingController> _waveValueControllers = List.generate(
    2,
    (index) => TextEditingController(),
  );
  final List<TextEditingController> _targetNameControllers = List.generate(
    _maxFormLimit - _defaultForm,
    (index) => TextEditingController(),
  );
  final List<TextEditingController> _targetLevelControllers = List.generate(
    _maxFormLimit,
    (index) => TextEditingController(),
  );
  final List<TextEditingController> _defaultFormNameControllers = List.generate(
    _defaultForm,
    (index) => TextEditingController(),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadCalculatorData();
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      setState(() {
        now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    for (var c in _waveValueControllers) {
      c.dispose();
    }
    for (var c in _targetNameControllers) {
      c.dispose();
    }
    for (var c in _targetLevelControllers) {
      c.dispose();
    }
    for (var c in _defaultFormNameControllers) {
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
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.resumed) {
      _saveCalculatorData();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _defaultFormNameControllers[0].text = AppLocalizations.of(
      context,
    )!.castleDefault;
    _defaultFormNameControllers[1].text = AppLocalizations.of(
      context,
    )!.taDefault;
    var seasonProgress =
        ((now.millisecondsSinceEpoch / 1000 % 432000 - 312900 > 0
            ? now.millisecondsSinceEpoch / 1000 % 432000 - 312900
            : now.millisecondsSinceEpoch / 1000 % 432000 + 119100) /
        432000);
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
                Icon(Icons.timer),
                SizedBox(width: 8),
                Text('${(seasonProgress * 100).toStringAsFixed(2)}%'),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              spacing: 8,
              children: [
                Expanded(
                  flex: 5,
                  child: TextFormField(
                    controller: _waveValueControllers[0],
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.currentWave,
                      hintText: AppLocalizations.of(context)!.typeCurrentWave,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _waveValue[0] = _convertStringToInt(value);
                      });
                    },
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: TextFormField(
                    controller: _waveValueControllers[1],
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(
                        context,
                      )!.currentSeasonalWave,
                      hintText: AppLocalizations.of(
                        context,
                      )!.typeCurrentSeasonalWave,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _waveValue[1] = _convertStringToInt(value);
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
                Text(
                  AppLocalizations.of(context)!.totalGold + _totalGoldString,
                ),
                Text(
                  AppLocalizations.of(context)!.wph +
                      (_waveValue[1] / (120 * seasonProgress)).toStringAsFixed(
                        2,
                      ),
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
                                  (310 + _waveValue[0] * 310) *
                                  _waveValue[0]) *
                              100)
                          .toStringAsFixed(2),
                ),
                Text(
                  AppLocalizations.of(context)!.ratio +
                      (_totalGold / (_waveValue[0] * _waveValue[0]))
                          .toStringAsFixed(2),
                ),
              ],
            ),
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
                              child: TextFormField(
                                controller: index < _defaultForm
                                    ? _defaultFormNameControllers[index]
                                    : _targetNameControllers[index -
                                          _defaultForm],
                                readOnly: index < _defaultForm ? true : false,
                                decoration: InputDecoration(
                                  labelText: AppLocalizations.of(
                                    context,
                                  )!.unitName,
                                  hintText: AppLocalizations.of(
                                    context,
                                  )!.typeUnitName,
                                  border: const OutlineInputBorder(),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _targetName[index - _defaultForm] = value;
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              flex: 5,
                              child: TextFormField(
                                controller: _targetLevelControllers[index],
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: InputDecoration(
                                  labelText: AppLocalizations.of(
                                    context,
                                  )!.unitLevel,
                                  hintText: AppLocalizations.of(
                                    context,
                                  )!.typeUnitLevel,
                                  border: const OutlineInputBorder(),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _targetLevel[index] = _convertStringToInt(
                                      value,
                                    );
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
                              '${_targetCheckbox[index] ? (_targetGold[index] / _totalGold * 100).toStringAsFixed(2) : 0.toStringAsFixed(2)}%',
                            ),
                            Text(
                              (_targetLevel[index] / _waveValue[0])
                                  .toStringAsFixed(3),
                            ),
                            Text(
                              (_waveValue[0] / _targetLevel[index])
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 8,
              children: [
                Tooltip(
                  message: AppLocalizations.of(context)!.clearInputFields,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _clearCalculatorFormData();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                    ),
                    child: const Icon(Icons.delete),
                  ),
                ),
                Tooltip(
                  message: AppLocalizations.of(context)!.loadData,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        loadCalculatorData();
                      });
                    },
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
                        _dynamicFormNum > _minFormLimit
                            ? _dynamicFormNum--
                            : _dynamicFormNum;
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
                        _dynamicFormNum < _maxFormLimit
                            ? _dynamicFormNum++
                            : _dynamicFormNum;
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
                    onPressed: () {
                      _saveCalculatorData();
                    },
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
    );
  }
}
