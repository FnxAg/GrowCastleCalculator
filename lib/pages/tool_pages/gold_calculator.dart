import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grow_castle_calculator/l10n/app_localizations.dart';
import 'package:grow_castle_calculator/main.dart';
import 'package:grow_castle_calculator/pages/calculator_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

int _convertStringToInt(String value) {
  return int.tryParse(value) ?? 0;
}

double _convertStringToDouble(String value) {
  return double.tryParse(value) ?? 0.0;
}

class GoldCalculator extends StatefulWidget {
  const GoldCalculator({super.key});

  @override
  State<GoldCalculator> createState() => _GoldCalculatorState();
}

class _GoldCalculatorState extends State<GoldCalculator> with WidgetsBindingObserver {
  List<bool> _isExpanded = List.filled(3, true);
  List<int> _waveValue = List.generate(2, (index) => 1000000 - index * 960000);
  List<dynamic> _formField = List.filled(9, 0);
  List<bool> _checkboxForm = List.filled(4, true);

  final List<TextEditingController> _waveValueControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  final List<TextEditingController> _formFieldControllers = List.generate(
    9,
    (index) => TextEditingController(),
  );

  Future<void> _saveCalculatorData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList(
      'gc_waveValue',
      _waveValue.map((e) => e.toString()).toList(),
    );
    prefs.setStringList(
      'gc_formField',
      _formField.map((e) => e.toString()).toList(),
    );
    prefs.setStringList(
      'gc_checkboxForm',
      _checkboxForm.map((e) => e.toString()).toList(),
    );
    prefs.setStringList(
      'gc_isExpanded',
      _isExpanded.map((e) => e.toString()).toList(),
    );
  }

  Future<void> _loadCalculatorData() async {
    final prefs = await SharedPreferences.getInstance();
    _checkboxForm =
        prefs.getStringList('gc_checkboxForm')?.map(bool.parse).toList() ??
        List.filled(4, true);
    _formField =
        prefs
            .getStringList('gc_formField')
            ?.map(
              (e) => int.tryParse(e) != null ? int.parse(e) : double.parse(e),
            )
            .toList() ??
        List.filled(9, 0);
    _isExpanded =
        prefs.getStringList('gc_isExpanded')?.map(bool.parse).toList() ??
        List.filled(4, true);
    for (int i = 0; i < _formFieldControllers.length; i++) {
      _formFieldControllers[i].text = _formField[i].toString();
    }
    if (!_checkboxForm[0]) {
      _waveValue =
          prefs.getStringList('gc_waveValue')?.map(int.parse).toList() ??
          [1000000, 40000];
      for (int i = 0; i < _waveValueControllers.length; i++) {
        _waveValueControllers[i].text = _waveValue[i].toString();
      }
    } else {
      for (int i = 0; i < _waveValueControllers.length; i++) {
        _waveValueControllers[i].text = CalculatorPage.waveValue[i].toString();
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCalculatorData();
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

  Future<void> _initWaveValue() async {
    if (!_checkboxForm[0]) return;
    for (int i = 0; i < _waveValueControllers.length; i++) {
      _waveValueControllers[i].text = CalculatorPage.waveValue[i].toString();
    }
  }

  @override
  void dispose() {
    for (var controller in _waveValueControllers) {
      controller.dispose();
    }
    for (var controller in _formFieldControllers) {
      controller.dispose();
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    double wph = _convertStringToDouble(_formFieldControllers[2].text) == 0
        ? 0
        : (3600 /
              _convertStringToDouble(_formFieldControllers[2].text) *
              _convertStringToDouble(_formFieldControllers[1].text));
    var goldPerCart =
        (_convertStringToInt(_formFieldControllers[3].text) * 5400 + 1374406) /
        1.2 *
        (1.2 + 0.01 * _convertStringToInt(_formFieldControllers[5].text));
    var secondsPerCart =
        (60 /
        ((_convertStringToInt(_formFieldControllers[4].text) * 0.005 + 1.1) +
            (_checkboxForm[1] ? 0.15 : 0)));
    double icRatio = _convertStringToDouble(_formFieldControllers[0].text) == 0
        ? 0
        : (_convertStringToInt(_formFieldControllers[3].text) *
              1000 /
              _convertStringToInt(_waveValueControllers[0].text));
    double cartsPerHour =
        _convertStringToDouble(_formFieldControllers[2].text) == 0
        ? 0
        : (((_convertStringToDouble(_formFieldControllers[2].text) - 1.5) *
                      _convertStringToDouble(_formFieldControllers[0].text) +
                  1.5) *
              3600 /
              _convertStringToDouble(_formFieldControllers[2].text) /
              secondsPerCart);
    var adGold = _convertStringToInt(_waveValueControllers[0].text) * 2160;
    var gabCost =
        456 * _convertStringToInt(_waveValueControllers[0].text) - 29264;
    var gabBenefitGoldPerWave =
        gabCost * _convertStringToDouble(_formFieldControllers[7].text) * 0.01;
    double gabBenefitGoldPerHour =
        _convertStringToDouble(_formFieldControllers[2].text) == 0
        ? 0
        : 3600 /
              _convertStringToDouble(_formFieldControllers[2].text) *
              gabBenefitGoldPerWave;
    var tabGoldPerWave =
        gabCost *
        (1 + _convertStringToDouble(_formFieldControllers[7].text) * 0.01);
    double tabGoldPerHour =
        _convertStringToDouble(_formFieldControllers[2].text) == 0
        ? 0
        : tabGoldPerWave *
              (3600 / _convertStringToDouble(_formFieldControllers[2].text));
    var tabGoldPerDay =
        tabGoldPerHour * _convertStringToDouble(_formFieldControllers[8].text);
    var gabBenefitGoldPerDay =
        gabBenefitGoldPerHour *
        _convertStringToDouble(_formFieldControllers[6].text);
    double goldenTreeGoldPerHour =
        _convertStringToDouble(_formFieldControllers[2].text) == 0
        ? 0
        : 48 /
              456 *
              gabCost *
              3600 /
              _convertStringToDouble(_formFieldControllers[2].text) /
              2;
    var goldenTreeGoldPerDay = _checkboxForm[2]
        ? (_convertStringToDouble(_formFieldControllers[6].text) +
                  _convertStringToDouble(_formFieldControllers[8].text)) *
              goldenTreeGoldPerHour
        : 0.toDouble();
    var seasonalColonyGoldPerHour = 16 * adGold / 24;
    var seasonalColonyGoldPerDay = _checkboxForm[3]
        ? seasonalColonyGoldPerHour * 24
        : 0;
    var colonyGoldPerDay = goldPerCart * cartsPerHour * 24;
    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        await _saveCalculatorData();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.goldCalculator),
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(8),
                child: ListView(
                  children: [
                    Column(
                      spacing: 8,
                      children: [
                        Row(
                          spacing: 8,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                children: [
                                  Text(AppLocalizations.of(context)!.inherit),
                                  Checkbox(
                                    value: _checkboxForm[0],
                                    onChanged: (value) {
                                      setState(() {
                                        _checkboxForm[0] = value!;
                                        if (_checkboxForm[0]) {
                                          _initWaveValue();
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: TextFormField(
                                controller: _waveValueControllers[0],
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                readOnly: _checkboxForm[0] ? true : false,
                                decoration: InputDecoration(
                                  labelText: AppLocalizations.of(context)!.currentWave,
                                  hintText: AppLocalizations.of(context)!.enterCurrentWave,
                                  border: const OutlineInputBorder(),
                                ),
                                onChanged: (value) => setState(() {
                                  _waveValue[0] = _convertStringToInt(value);
                                }),
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: TextFormField(
                                controller: _waveValueControllers[1],
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                readOnly: _checkboxForm[0] ? true : false,
                                decoration: InputDecoration(
                                  labelText: AppLocalizations.of(context)!.seasonalWave,
                                  hintText: AppLocalizations.of(context)!.enterSeasonalWave,
                                  border: const OutlineInputBorder(),
                                ),
                                onChanged: (value) => setState(() {
                                  _waveValue[1] = _convertStringToInt(value);
                                }),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          spacing: 12,
                          children: [
                            Expanded(
                              flex: 3,
                              child: ExpandedText(
                                name: AppLocalizations.of(context)!.gabCost,
                                variable: decreaseNumSize(gabCost.toDouble()),
                              ),
                            ),
                            Expanded(flex: 1, child: SizedBox()),
                            Expanded(
                              flex: 3,
                              child: ExpandedText(
                                name: AppLocalizations.of(context)!.goldDay,
                                variable: decreaseNumSize(
                                  colonyGoldPerDay +
                                      gabBenefitGoldPerDay +
                                      tabGoldPerDay +
                                      goldenTreeGoldPerDay +
                                      seasonalColonyGoldPerDay,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          spacing: 8,
                          children: [
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: _formFieldControllers[0],
                                keyboardType: TextInputType.number,
                                inputFormatters: [FormatterWithMinusAndDot()],
                                decoration: InputDecoration(
                                  labelText: AppLocalizations.of(context)!.gameSpeed,
                                  hintText: AppLocalizations.of(context)!.enterGameSpeed,
                                  border: const OutlineInputBorder(),
                                ),
                                onChanged: (value) => setState(() {
                                  _formField[0] = _convertStringToDouble(value);
                                }),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: _formFieldControllers[1],
                                keyboardType: TextInputType.number,
                                inputFormatters: [FormatterWithMinusAndDot()],
                                decoration: InputDecoration(
                                  labelText: AppLocalizations.of(context)!.jumpAndWave,
                                  hintText: AppLocalizations.of(context)!.enterWave,
                                  border: const OutlineInputBorder(),
                                ),
                                onChanged: (value) => setState(() {
                                  _formField[1] = _convertStringToDouble(value);
                                }),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: _formFieldControllers[2],
                                keyboardType: TextInputType.number,
                                inputFormatters: [FormatterWithMinusAndDot()],
                                decoration: InputDecoration(
                                  labelText: AppLocalizations.of(context)!.waveTime,
                                  hintText: AppLocalizations.of(context)!.enterWaveTime,
                                  border: const OutlineInputBorder(),
                                ),
                                onChanged: (value) => setState(() {
                                  _formField[2] = _convertStringToDouble(value);
                                }),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [Text('${AppLocalizations.of(context)!.wph} ${wph.toStringAsFixed(2)}')],
                        ),
                        InkWell(
                          onTap: () => setState(() {
                            _isExpanded[0] = !_isExpanded[0];
                          }),
                          borderRadius: BorderRadius.circular(8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.infiniteColony,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              AnimatedRotation(
                                turns: _isExpanded[0] ? 0.5 : 0,
                                duration: const Duration(milliseconds: 150),
                                child: const Icon(Icons.keyboard_arrow_down),
                              ),
                            ],
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeInOut,
                          height: _isExpanded[0] ? null : 0,
                          child: _isExpanded[0]
                              ? Column(
                                  spacing: 8,
                                  children: [
                                    Row(
                                      spacing: 8,
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller:
                                                _formFieldControllers[3],
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly,
                                            ],
                                            decoration: InputDecoration(
                                              labelText: AppLocalizations.of(context)!.icLevel,
                                              hintText: AppLocalizations.of(context)!.enterLV,
                                              border:
                                                  const OutlineInputBorder(),
                                            ),
                                            onChanged: (value) => setState(() {
                                              _formField[3] =
                                                  _convertStringToInt(value);
                                            }),
                                          ),
                                        ),
                                        Column(
                                          children: [
                                            Text(AppLocalizations.of(context)!.ironWheel),
                                            Checkbox(
                                              value: _checkboxForm[1],
                                              onChanged: (value) {
                                                setState(() {
                                                  _checkboxForm[1] =
                                                      value ?? false;
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Row(
                                      spacing: 8,
                                      children: [
                                        Expanded(
                                          flex: 4,
                                          child: TextFormField(
                                            controller:
                                                _formFieldControllers[4],
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly,
                                            ],
                                            decoration: InputDecoration(
                                              labelText: AppLocalizations.of(context)!.extraColonyCD,
                                              hintText: AppLocalizations.of(context)!.enterLV,
                                              border:
                                                  const OutlineInputBorder(),
                                            ),
                                            onChanged: (value) => setState(() {
                                              _formField[4] =
                                                  _convertStringToInt(value);
                                            }),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 4,
                                          child: TextFormField(
                                            controller:
                                                _formFieldControllers[5],
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly,
                                            ],
                                            decoration: InputDecoration(
                                              labelText: AppLocalizations.of(context)!.extraColonyGold,
                                              hintText: AppLocalizations.of(context)!.enterLV,
                                              border:
                                                  const OutlineInputBorder(),
                                            ),
                                            onChanged: (value) => setState(() {
                                              _formField[5] =
                                                  _convertStringToInt(value);
                                            }),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              : null,
                        ),
                        Row(
                          spacing: 12,
                          children: [
                            Expanded(
                              flex: 3,
                              child: ExpandedText(
                                name: AppLocalizations.of(context)!.secCart,
                                variable:
                                    '${secondsPerCart.toStringAsFixed(2)}s',
                              ),
                            ),
                            Expanded(flex: 1, child: SizedBox()),
                            Expanded(
                              flex: 3,
                              child: ExpandedText(
                                name: AppLocalizations.of(context)!.goldCart,
                                variable: decreaseNumSize(goldPerCart),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          spacing: 12,
                          children: [
                            Expanded(
                              flex: 3,
                              child: ExpandedText(
                                name: AppLocalizations.of(context)!.cartHour,
                                variable: cartsPerHour.toStringAsFixed(2),
                              ),
                            ),
                            Expanded(flex: 1, child: SizedBox()),
                            Expanded(
                              flex: 3,
                              child: ExpandedText(
                                name: AppLocalizations.of(context)!.icRatio,
                                variable: icRatio.toStringAsFixed(2),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          spacing: 12,
                          children: [
                            Expanded(
                              flex: 3,
                              child: ExpandedText(
                                name: AppLocalizations.of(context)!.goldHour,
                                variable: decreaseNumSize(
                                  goldPerCart * cartsPerHour,
                                ),
                              ),
                            ),
                            Expanded(flex: 1, child: SizedBox()),
                            Expanded(
                              flex: 3,
                              child: ExpandedText(
                                name: AppLocalizations.of(context)!.goldDay,
                                variable: decreaseNumSize(colonyGoldPerDay),
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => setState(() {
                            _isExpanded[1] = !_isExpanded[1];
                          }),
                          borderRadius: BorderRadius.circular(8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.goldAutoBattle,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              AnimatedRotation(
                                turns: _isExpanded[1] ? 0.5 : 0,
                                duration: const Duration(milliseconds: 150),
                                child: Icon(Icons.keyboard_arrow_down),
                              ),
                            ],
                          ),
                        ),
                        AnimatedContainer(
                          duration: Duration(milliseconds: 150),
                          curve: Curves.easeInOut,
                          height: _isExpanded[1] ? null : 0,
                          child: _isExpanded[1]
                              ? Row(
                                  spacing: 8,
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _formFieldControllers[6],
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          labelText: AppLocalizations.of(context)!.gabHourDay,
                                          hintText: AppLocalizations.of(context)!.enterHour,
                                          border: const OutlineInputBorder(),
                                        ),
                                        onChanged: (value) => setState(() {
                                          _formField[6] =
                                              _convertStringToDouble(value);
                                        }),
                                      ),
                                    ),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _formFieldControllers[7],
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          labelText: AppLocalizations.of(context)!.gabProfit,
                                          hintText: AppLocalizations.of(context)!.enterProfit,
                                          border: const OutlineInputBorder(),
                                        ),
                                        onChanged: (value) => setState(() {
                                          _formField[7] =
                                              _convertStringToDouble(value);
                                        }),
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                        Row(
                          spacing: 12,
                          children: [
                            Expanded(
                              flex: 3,
                              child: ExpandedText(
                                name: AppLocalizations.of(context)!.goldWave,
                                variable: decreaseNumSize(
                                  gabBenefitGoldPerWave,
                                ),
                              ),
                            ),
                            Expanded(flex: 1, child: SizedBox()),
                            Expanded(
                              flex: 3,
                              child: ExpandedText(
                                name: AppLocalizations.of(context)!.goldDay,
                                variable: decreaseNumSize(gabBenefitGoldPerDay),
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => setState(() {
                            _isExpanded[2] = !_isExpanded[2];
                          }),
                          borderRadius: BorderRadius.circular(8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.timeAutoBattle,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              AnimatedRotation(
                                turns: _isExpanded[2] ? 0.5 : 0,
                                duration: Duration(milliseconds: 150),
                                child: Icon(Icons.keyboard_arrow_down),
                              ),
                            ],
                          ),
                        ),
                        AnimatedContainer(
                          duration: Duration(milliseconds: 150),
                          curve: Curves.easeInOut,
                          height: _isExpanded[2] ? null : 0,
                          child: _isExpanded[2]
                              ? Row(
                                  spacing: 8,
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _formFieldControllers[8],
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          labelText: AppLocalizations.of(context)!.tabHourDay,
                                          hintText: AppLocalizations.of(context)!.enterHour,
                                          border: const OutlineInputBorder(),
                                        ),
                                        onChanged: (value) => setState(() {
                                          _formField[8] =
                                              _convertStringToDouble(value);
                                        }),
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                        Row(
                          spacing: 12,
                          children: [
                            Expanded(
                              flex: 3,
                              child: ExpandedText(
                                name: AppLocalizations.of(context)!.goldWave,
                                variable: decreaseNumSize(tabGoldPerWave),
                              ),
                            ),
                            Expanded(flex: 1, child: SizedBox()),
                            Expanded(
                              flex: 3,
                              child: ExpandedText(
                                name: AppLocalizations.of(context)!.goldDay,
                                variable: decreaseNumSize(tabGoldPerDay),
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => setState(() {
                            _checkboxForm[2] = !_checkboxForm[2];
                          }),
                          borderRadius: BorderRadius.circular(8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.goldenTree,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Checkbox(
                                value: _checkboxForm[2],
                                onChanged: (value) {
                                  setState(() {
                                    _checkboxForm[2] = value ?? false;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        Row(
                          spacing: 12,
                          children: [
                            Expanded(
                              flex: 3,
                              child: ExpandedText(
                                name: AppLocalizations.of(context)!.goldHour,
                                variable: decreaseNumSize(
                                  goldenTreeGoldPerHour,
                                ),
                              ),
                            ),
                            Expanded(flex: 1, child: SizedBox()),
                            Expanded(
                              flex: 3,
                              child: ExpandedText(
                                name: AppLocalizations.of(context)!.goldDay,
                                variable: decreaseNumSize(goldenTreeGoldPerDay),
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => setState(() {
                            _checkboxForm[3] = !_checkboxForm[3];
                          }),
                          borderRadius: BorderRadius.circular(8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.seasonalColony,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Checkbox(
                                value: _checkboxForm[3],
                                onChanged: (value) {
                                  setState(() {
                                    _checkboxForm[3] = value ?? false;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        Row(
                          spacing: 12,
                          children: [
                            Expanded(
                              flex: 3,
                              child: ExpandedText(
                                name: AppLocalizations.of(context)!.goldHour,
                                variable: decreaseNumSize(
                                  seasonalColonyGoldPerHour.toDouble(),
                                ),
                              ),
                            ),
                            Expanded(flex: 1, child: SizedBox()),
                            Expanded(
                              flex: 3,
                              child: ExpandedText(
                                name: AppLocalizations.of(context)!.goldDay,
                                variable: decreaseNumSize(
                                  seasonalColonyGoldPerDay.toDouble(),
                                ),
                              ),
                            ),
                          ],
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
