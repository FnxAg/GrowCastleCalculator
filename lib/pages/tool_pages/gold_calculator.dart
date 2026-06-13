import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:grow_castle_calculator/l10n/app_localizations.dart';
import 'package:grow_castle_calculator/pages/calculator_page.dart';
import 'package:grow_castle_calculator/services/preferences_service.dart';
import 'package:grow_castle_calculator/utils/number_utils.dart';
import 'package:grow_castle_calculator/utils/text_input_formatter.dart';
import 'package:grow_castle_calculator/widgets/collapsible_section.dart';
import 'package:grow_castle_calculator/widgets/expanded_text.dart';

class GoldCalculator extends StatefulWidget {
  const GoldCalculator({super.key});

  @override
  State<GoldCalculator> createState() => _GoldCalculatorState();
}

class _GoldCalculatorState extends State<GoldCalculator>
    with WidgetsBindingObserver {
  // ── Layout constants ───────────────────────────────────────────────────

  static const int textExpandedFlex = 15;
  static const int sizedBoxExpandedFlex = 1;

  // ── State ──────────────────────────────────────────────────────────────

  List<bool> _isExpanded = List.filled(4, true);
  List<int> _waveValue = [1000000, 40000];
  List<dynamic> _formField = List.filled(9, 0);
  List<bool> _checkboxForm = List.filled(4, true);
  bool _isLoading = true;

  // ── Controllers ────────────────────────────────────────────────────────

  final List<TextEditingController> _waveValueControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  final List<TextEditingController> _formFieldControllers =
      List.generate(9, (_) => TextEditingController());

  // ── Lifecycle ──────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    for (final c in _waveValueControllers) {
      c.dispose();
    }
    for (final c in _formFieldControllers) {
      c.dispose();
    }
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
    final data = await PreferencesService.loadGoldCalculatorData();
    _checkboxForm = (data['gc_checkboxForm'] as List<String>)
        .map((e) => e == 'true')
        .toList();
    if (_checkboxForm.length < 4) {
      _checkboxForm = List.filled(4, true);
    }
    _formField = (data['gc_formField'] as List<String>)
        .map((e) => int.tryParse(e) != null ? int.parse(e) : double.parse(e))
        .toList();
    if (_formField.length < 9) {
      _formField = List.filled(9, 0);
    }
    _isExpanded = (data['gc_isExpanded'] as List<String>)
        .map((e) => e == 'true')
        .toList();
    if (_isExpanded.length < 4) {
      _isExpanded = List.filled(4, true);
    }
    _syncControllers();
    setState(() => _isLoading = false);
  }

  void _syncControllers() {
    for (int i = 0; i < _formFieldControllers.length; i++) {
      _formFieldControllers[i].text = _formField[i].toString();
    }
    _syncWaveControllers();
  }

  void _syncWaveControllers() {
    if (_checkboxForm[0]) {
      for (int i = 0; i < _waveValueControllers.length; i++) {
        _waveValueControllers[i].text =
            CalculatorPage.waveValue[i].toString();
      }
    } else {
      _waveValue = (CalculatorPage.waveValue.toList())..[0] = CalculatorPage.waveValue[0];
      for (int i = 0; i < _waveValueControllers.length; i++) {
        _waveValueControllers[i].text = _waveValue[i].toString();
      }
    }
  }

  Future<void> _saveData() async {
    await PreferencesService.saveGoldCalculatorData(
      gcWaveValue: _waveValue.map((e) => e.toString()).toList(),
      gcFormField: _formField.map((e) => e.toString()).toList(),
      gcCheckboxForm: _checkboxForm.map((e) => e.toString()).toList(),
      gcIsExpanded: _isExpanded.map((e) => e.toString()).toList(),
    );
  }

  // ── Build helpers ──────────────────────────────────────────────────────

  Widget _infoRowPair(
    String name1,
    String variable1,
    String name2,
    String variable2,
  ) {
    return Row(
      spacing: 12,
      children: [
        Expanded(
          flex: textExpandedFlex,
          child: ExpandedText(name: name1, variable: variable1),
        ),
        const Expanded(flex: sizedBoxExpandedFlex, child: SizedBox()),
        Expanded(
          flex: textExpandedFlex,
          child: ExpandedText(name: name2, variable: variable2),
        ),
      ],
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    // Parse fields from controllers
    final f0 = convertStringToDouble(_formFieldControllers[0].text);
    final f1 = convertStringToDouble(_formFieldControllers[1].text);
    final f2 = convertStringToDouble(_formFieldControllers[2].text);
    final f3 = convertStringToInt(_formFieldControllers[3].text);
    final f4 = convertStringToInt(_formFieldControllers[4].text);
    final f5 = convertStringToInt(_formFieldControllers[5].text);
    final f6 = convertStringToDouble(_formFieldControllers[6].text);
    final f7 = convertStringToDouble(_formFieldControllers[7].text);
    final f8 = convertStringToDouble(_formFieldControllers[8].text);
    final w0 = convertStringToInt(_waveValueControllers[0].text);

    // Computed values
    final wph = f2 == 0 ? 0 : (3600 / f2 * f1);
    final goldPerCart = (f3 * 5400 + 1374406) / 1.2 * (1.2 + 0.01 * f5);
    final secondsPerCart =
        60 / ((f4 * 0.005 + 1.1) + (_checkboxForm[1] ? 0.15 : 0));
    final icRatio = f0 == 0 ? 0 : (f3 * 1000 / w0);
    final cartsPerHour =
        f2 == 0 ? 0.0 : (((f2 - 1.5) * f0 + 1.5) * 3600 / f2 / secondsPerCart);
    final adGold = w0 * 2160;
    final gabCost = 456 * w0 - 29264;
    final gabBenefitGoldPerWave = gabCost * f7 * 0.01;
    final gabBenefitGoldPerHour =
        f2 == 0 ? 0.0 : 3600 / f2 * gabBenefitGoldPerWave;
    final tabGoldPerWave = gabCost * (1 + f7 * 0.01);
    final tabGoldPerHour = f2 == 0 ? 0.0 : tabGoldPerWave * (3600 / f2);
    final tabGoldPerDay = tabGoldPerHour * f8;
    final gabBenefitGoldPerDay = gabBenefitGoldPerHour * f6;
    final goldenTreeGoldPerHour =
        f2 == 0 ? 0.0 : 48 / 456 * gabCost * 3600 / f2 / 2;
    final goldenTreeGoldPerDay =
        _checkboxForm[2] ? ((f6 + f8) * goldenTreeGoldPerHour) : 0.0;
    final seasonalColonyGoldPerHour = 16 * adGold / 24;
    final seasonalColonyGoldPerDay =
        _checkboxForm[3] ? seasonalColonyGoldPerHour * 24 : 0.0;
    final colonyGoldPerDay = goldPerCart * cartsPerHour * 24;

    final totalGoldPerDay = colonyGoldPerDay +
        gabBenefitGoldPerDay +
        tabGoldPerDay +
        goldenTreeGoldPerDay +
        seasonalColonyGoldPerDay;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) async => _saveData(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.goldCalculator),
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(8),
                  child: ListView(
                    children: [
                      Column(
                        spacing: 8,
                        children: [
                          // ── Wave input row ────────────────────────────
                          Row(
                            spacing: 8,
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  children: [
                                    Text(loc.inherit),
                                    Checkbox(
                                      value: _checkboxForm[0],
                                      onChanged: (value) {
                                        setState(() {
                                          _checkboxForm[0] = value!;
                                          _syncWaveControllers();
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 4,
                                child: TextField(
                                  controller: _waveValueControllers[0],
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  readOnly: _checkboxForm[0],
                                  decoration: InputDecoration(
                                    labelText: loc.currentWave,
                                    hintText: loc.enterCurrentWave,
                                    border: const OutlineInputBorder(),
                                  ),
                                  onChanged: (value) => setState(() {
                                    _waveValue[0] = convertStringToInt(value);
                                  }),
                                ),
                              ),
                              Expanded(
                                flex: 4,
                                child: TextField(
                                  controller: _waveValueControllers[1],
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  readOnly: _checkboxForm[0],
                                  decoration: InputDecoration(
                                    labelText: loc.seasonalWave,
                                    hintText: loc.enterSeasonalWave,
                                    border: const OutlineInputBorder(),
                                  ),
                                  onChanged: (value) => setState(() {
                                    _waveValue[1] = convertStringToInt(value);
                                  }),
                                ),
                              ),
                            ],
                          ),

                          // ── GAB cost / Total gold per day ─────────────
                          _infoRowPair(
                            loc.gabCost,
                            decreaseNumSize(gabCost.toDouble(), context),
                            loc.goldDay,
                            decreaseNumSize(totalGoldPerDay, context),
                          ),

                          // ── Game speed / Jump & Wave / Wave time ──────
                          Row(
                            spacing: 8,
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _formFieldControllers[0],
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FormatterWithMinusAndDot()],
                                  decoration: InputDecoration(
                                    labelText: loc.gameSpeed,
                                    hintText: loc.enterGameSpeed,
                                    border: const OutlineInputBorder(),
                                  ),
                                  onChanged: (value) => setState(() {
                                    _formField[0] =
                                        convertStringToDouble(value);
                                  }),
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _formFieldControllers[1],
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FormatterWithMinusAndDot()],
                                  decoration: InputDecoration(
                                    labelText: loc.jumpAndWave,
                                    hintText: loc.enterWave,
                                    border: const OutlineInputBorder(),
                                  ),
                                  onChanged: (value) => setState(() {
                                    _formField[1] =
                                        convertStringToDouble(value);
                                  }),
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _formFieldControllers[2],
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FormatterWithMinusAndDot()],
                                  decoration: InputDecoration(
                                    labelText: loc.waveTime,
                                    hintText: loc.enterWaveTime,
                                    border: const OutlineInputBorder(),
                                  ),
                                  onChanged: (value) => setState(() {
                                    _formField[2] =
                                        convertStringToDouble(value);
                                  }),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('${loc.wph} ${wph.toStringAsFixed(2)}'),
                            ],
                          ),

                          // ── Infinite Colony section ────────────────────
                          CollapsibleSection(
                            title: loc.infiniteColony,
                            isExpanded: _isExpanded[0],
                            onToggle: () =>
                                setState(() => _isExpanded[0] = !_isExpanded[0]),
                            child: Column(
                              spacing: 8,
                              children: [
                                Row(
                                  spacing: 8,
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _formFieldControllers[3],
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                        ],
                                        decoration: InputDecoration(
                                          labelText: loc.icLevel,
                                          hintText: loc.enterLV,
                                          border: const OutlineInputBorder(),
                                        ),
                                        onChanged: (value) => setState(() {
                                          _formField[3] =
                                              convertStringToInt(value);
                                        }),
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        Text(loc.ironWheel),
                                        Checkbox(
                                          value: _checkboxForm[1],
                                          onChanged: (value) => setState(() {
                                            _checkboxForm[1] = value ?? false;
                                          }),
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
                                      child: TextField(
                                        controller: _formFieldControllers[4],
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                        ],
                                        decoration: InputDecoration(
                                          labelText: loc.extraColonyCD,
                                          hintText: loc.enterLV,
                                          border: const OutlineInputBorder(),
                                        ),
                                        onChanged: (value) => setState(() {
                                          _formField[4] =
                                              convertStringToInt(value);
                                        }),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 4,
                                      child: TextField(
                                        controller: _formFieldControllers[5],
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                        ],
                                        decoration: InputDecoration(
                                          labelText: loc.extraColonyGold,
                                          hintText: loc.enterLV,
                                          border: const OutlineInputBorder(),
                                        ),
                                        onChanged: (value) => setState(() {
                                          _formField[5] =
                                              convertStringToInt(value);
                                        }),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          _infoRowPair(
                            loc.secCart,
                            '${secondsPerCart.toStringAsFixed(2)}s',
                            loc.goldCart,
                            decreaseNumSize(goldPerCart, context),
                          ),
                          _infoRowPair(
                            loc.cartHour,
                            cartsPerHour.toStringAsFixed(2),
                            loc.icRatio,
                            icRatio.toStringAsFixed(2),
                          ),
                          _infoRowPair(
                            loc.goldHour,
                            decreaseNumSize(goldPerCart * cartsPerHour, context),
                            loc.goldDay,
                            decreaseNumSize(colonyGoldPerDay, context),
                          ),

                          // ── Gold Auto Battle section ───────────────────
                          CollapsibleSection(
                            title: loc.goldAutoBattle,
                            isExpanded: _isExpanded[1],
                            onToggle: () =>
                                setState(() => _isExpanded[1] = !_isExpanded[1]),
                            child: Row(
                              spacing: 8,
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _formFieldControllers[6],
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: loc.gabHourDay,
                                      hintText: loc.enterHour,
                                      border: const OutlineInputBorder(),
                                    ),
                                    onChanged: (value) => setState(() {
                                      _formField[6] =
                                          convertStringToDouble(value);
                                    }),
                                  ),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _formFieldControllers[7],
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: loc.gabProfit,
                                      hintText: loc.enterProfit,
                                      border: const OutlineInputBorder(),
                                    ),
                                    onChanged: (value) => setState(() {
                                      _formField[7] =
                                          convertStringToDouble(value);
                                    }),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          _infoRowPair(
                            loc.goldWave,
                            decreaseNumSize(gabBenefitGoldPerWave, context),
                            loc.goldDay,
                            decreaseNumSize(gabBenefitGoldPerDay, context),
                          ),

                          // ── Time Auto Battle section ───────────────────
                          CollapsibleSection(
                            title: loc.timeAutoBattle,
                            isExpanded: _isExpanded[2],
                            onToggle: () =>
                                setState(() => _isExpanded[2] = !_isExpanded[2]),
                            child: Row(
                              spacing: 8,
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _formFieldControllers[8],
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: loc.tabHourDay,
                                      hintText: loc.enterHour,
                                      border: const OutlineInputBorder(),
                                    ),
                                    onChanged: (value) => setState(() {
                                      _formField[8] =
                                          convertStringToDouble(value);
                                    }),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          _infoRowPair(
                            loc.goldWave,
                            decreaseNumSize(tabGoldPerWave, context),
                            loc.goldDay,
                            decreaseNumSize(tabGoldPerDay, context),
                          ),

                          // ── Golden Tree section ────────────────────────
                          CollapsibleSection(
                            title: loc.goldenTree,
                            isExpanded: true,
                            onToggle: () => setState(
                                () => _checkboxForm[2] = !_checkboxForm[2]),
                            trailing: Checkbox(
                              value: _checkboxForm[2],
                              onChanged: (value) => setState(() {
                                _checkboxForm[2] = value ?? false;
                              }),
                            ),
                            child: const SizedBox.shrink(),
                          ),

                          _infoRowPair(
                            loc.goldHour,
                            decreaseNumSize(goldenTreeGoldPerHour, context),
                            loc.goldDay,
                            decreaseNumSize(goldenTreeGoldPerDay, context),
                          ),

                          // ── Seasonal Colony section ────────────────────
                          CollapsibleSection(
                            title: loc.seasonalColony,
                            isExpanded: true,
                            onToggle: () => setState(
                                () => _checkboxForm[3] = !_checkboxForm[3]),
                            trailing: Checkbox(
                              value: _checkboxForm[3],
                              onChanged: (value) => setState(() {
                                _checkboxForm[3] = value ?? false;
                              }),
                            ),
                            child: const SizedBox.shrink(),
                          ),

                          _infoRowPair(
                            loc.goldHour,
                            decreaseNumSize(
                                seasonalColonyGoldPerHour.toDouble(), context),
                            loc.goldDay,
                            decreaseNumSize(
                                seasonalColonyGoldPerDay.toDouble(), context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
