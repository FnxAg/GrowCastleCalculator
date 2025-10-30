import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grow_castle_calculator/main.dart';
import 'package:grow_castle_calculator/pages/calculator_page.dart';

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

class _GoldCalculatorState extends State<GoldCalculator> {
  bool _goldCalculatorWaveBox = true;
  bool _ironWheel = false;
  bool _includeGoldenTree = true;
  bool _includeSeasonalColony = true;

  final List<TextEditingController> _goldCalculatorWaveController = [
    TextEditingController(),
    TextEditingController(),
  ];
  final List<TextEditingController> _formFieldControllers = List.generate(
    9,
    (index) => TextEditingController(),
  );

  @override
  void initState() {
    super.initState();
    _initWaveValue();
  }

  void _initWaveValue() {
    if (!_goldCalculatorWaveBox) return;
    for (int i = 0; i < _goldCalculatorWaveController.length; i++) {
      _goldCalculatorWaveController[i].text = CalculatorPage.waveValue[i]
          .toString();
    }
  }

  @override
  void dispose() {
    for (var controller in _goldCalculatorWaveController) {
      controller.dispose();
    }
    for (var controller in _formFieldControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var goldPerCart =
        (_convertStringToInt(_formFieldControllers[3].text) * 5400 + 1374406) /
        1.2 *
        (1.2 + 0.01 * _convertStringToInt(_formFieldControllers[5].text));
    var wph =
        (3600 /
        _convertStringToDouble(_formFieldControllers[2].text) *
        _convertStringToDouble(_formFieldControllers[1].text));
    var cartCooldownTime =
        (60 /
        ((_convertStringToInt(_formFieldControllers[4].text) * 0.005 + 1.1) +
            (_ironWheel ? 0.15 : 0)));
    var icRatio =
        (_convertStringToInt(_formFieldControllers[3].text) *
        1000 /
        _convertStringToInt(_goldCalculatorWaveController[0].text));
    var cartsPerHour =
        (((_convertStringToDouble(_formFieldControllers[2].text) - 1.5) *
                _convertStringToDouble(_formFieldControllers[0].text) +
            1.5) *
        3600 /
        _convertStringToDouble(_formFieldControllers[2].text) /
        cartCooldownTime);
    var adGold =
        _convertStringToInt(_goldCalculatorWaveController[0].text) * 2160;
    var gabCost =
        456 * _convertStringToInt(_goldCalculatorWaveController[0].text) -
        29264;
    var gabBenefitGoldPerWave =
        gabCost * _convertStringToDouble(_formFieldControllers[7].text) * 0.01;
    var gabBenefitGoldPerHour =
        3600 /
        _convertStringToDouble(_formFieldControllers[2].text) *
        gabBenefitGoldPerWave;
    var tabGoldPerWave =
        gabCost *
        (1 + _convertStringToDouble(_formFieldControllers[7].text) * 0.01);
    var tabGoldPerHour =
        tabGoldPerWave *
        (3600 / _convertStringToDouble(_formFieldControllers[2].text));
    var tabGoldPerDay = tabGoldPerHour * _convertStringToDouble(_formFieldControllers[8].text);
    var gabBenefitGoldPerDay = gabBenefitGoldPerHour * _convertStringToDouble(_formFieldControllers[6].text);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gold Calculator'),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Padding(
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
                      flex: 1,
                      child: Column(
                        children: [
                          Text('Extend'),
                          Checkbox(
                            value: _goldCalculatorWaveBox,
                            onChanged: (value) {
                              setState(() {
                                _goldCalculatorWaveBox = value!;
                                if (_goldCalculatorWaveBox) {
                                  _initWaveValue();
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: TextFormField(
                        controller: _goldCalculatorWaveController[0],
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        readOnly: _goldCalculatorWaveBox ? true : false,
                        decoration: InputDecoration(
                          labelText: 'Current Wave',
                          hintText: 'Enter Current Wave',
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: TextFormField(
                        controller: _goldCalculatorWaveController[1],
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        readOnly: _goldCalculatorWaveBox ? true : false,
                        decoration: InputDecoration(
                          labelText: 'Seasonal Wave',
                          hintText: 'Enter Seasonal Wave',
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                Row(
                  spacing: 12,
                  children: [
                    Expanded(
                      child: ExpandedText(
                        name: 'AD Gold: ',
                        variable: decreaseNumSize(adGold.toDouble()),
                      ),
                    ),
                    Expanded(
                      child: ExpandedText(
                        name: 'GAB Cost: ',
                        variable: decreaseNumSize(gabCost.toDouble()),
                      ),
                    ),
                    Expanded(child: SizedBox()),
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
                          labelText: 'Game Speed',
                          hintText: 'Enter Game Speed',
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _formFieldControllers[1],
                        keyboardType: TextInputType.number,
                        inputFormatters: [FormatterWithMinusAndDot()],
                        decoration: InputDecoration(
                          labelText: 'Jump + Wave',
                          hintText: 'Enter Wave',
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _formFieldControllers[2],
                        keyboardType: TextInputType.number,
                        inputFormatters: [FormatterWithMinusAndDot()],
                        decoration: InputDecoration(
                          labelText: 'Wave Time (s)',
                          hintText: 'Enter Wave Time',
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [Text('WPH: ${wph.toStringAsFixed(2)}')],
                ),
                Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _formFieldControllers[3],
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: 'IC Level',
                          hintText: 'Enter Infinite Colony Level',
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) => setState(() {}),
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
                        controller: _formFieldControllers[4],
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: 'Extra Colony CD Skill LV',
                          hintText: 'Enter Skill LV',
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _formFieldControllers[5],
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: 'Extra Colony Gold Skill LV',
                          hintText: 'Enter Skill LV',
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                    Column(
                      children: [
                        Text('Iron Wheel'),
                        Checkbox(
                          value: _ironWheel,
                          onChanged: (value) {
                            setState(() {
                              _ironWheel = value ?? false;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  spacing: 12,
                  children: [
                    Expanded(
                      child: ExpandedText(
                        name: 'Gold/Cart: ',
                        variable: decreaseNumSize(goldPerCart),
                      ),
                    ),
                    Expanded(child: SizedBox()),
                    Expanded(
                      child: ExpandedText(
                        name: 'IC Ratio: ',
                        variable: icRatio.toStringAsFixed(2),
                      ),
                    ),
                  ],
                ),
                Row(
                  spacing: 12,
                  children: [
                    Expanded(
                      child: ExpandedText(
                        name: 'Sec/Cart',
                        variable: '${cartCooldownTime.toStringAsFixed(2)}s',
                      ),
                    ),
                    Expanded(
                      child: ExpandedText(
                        name: 'Gold/Hour: ',
                        variable: decreaseNumSize(goldPerCart * cartsPerHour),
                      ),
                    ),
                    Expanded(child: SizedBox()),
                  ],
                ),
                Row(
                  spacing: 12,
                  children: [
                    Expanded(
                      child: ExpandedText(
                        name: 'Carts/Hour: ',
                        variable: cartsPerHour.toStringAsFixed(2),
                      ),
                    ),
                    Expanded(
                      child: ExpandedText(
                        name: 'Gold/Day: ',
                        variable: decreaseNumSize(
                          goldPerCart * cartsPerHour * 24,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ExpandedText(
                        name: 'AD Num: ',
                        variable: (goldPerCart * cartsPerHour * 24 / adGold)
                            .toStringAsFixed(2),
                      ),
                    ),
                  ],
                ),
                Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _formFieldControllers[6],
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'GAB Hour/Day',
                          hintText: 'Enter Hour',
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _formFieldControllers[7],
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Profit %',
                          hintText: 'Enter Profit',
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                Row(
                  spacing: 12,
                  children: [
                    Expanded(
                      child: ExpandedText(
                        name: 'Gold/Wave: ',
                        variable: decreaseNumSize(gabBenefitGoldPerWave),
                      ),
                    ),
                    Expanded(
                      child: ExpandedText(
                        name: 'Gold/Hour: ',
                        variable: decreaseNumSize(gabBenefitGoldPerHour),
                      ),
                    ),
                    Expanded(child: SizedBox()),
                  ],
                ),
                Row(
                  spacing: 12,
                  children: [
                    Expanded(child: SizedBox()),
                    Expanded(
                      child: ExpandedText(
                        name: 'Gold/Day: ',
                        variable: decreaseNumSize(gabBenefitGoldPerDay),
                      ),
                    ),
                    Expanded(
                      child: ExpandedText(
                        name: 'AD Num: ',
                        variable: (gabBenefitGoldPerDay / adGold)
                            .toStringAsFixed(2),
                      ),
                    ),
                  ],
                ),
                Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _formFieldControllers[8],
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'TAB Hour/Day',
                          hintText: 'Enter Hour',
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                Row(
                  spacing: 12,
                  children: [
                    Expanded(
                      child: ExpandedText(
                        name: 'Gold/Wave: ',
                        variable: decreaseNumSize(tabGoldPerWave),
                      ),
                    ),
                    Expanded(
                      child: ExpandedText(
                        name: 'Gold/Hour: ',
                        variable: decreaseNumSize(tabGoldPerHour),
                      ),
                    ),
                    Expanded(child: SizedBox()),
                  ],
                ),
                Row(
                  spacing: 12,
                  children: [
                    Expanded(child: SizedBox()),
                    Expanded(
                      child: ExpandedText(
                        name: 'Gold/Day: ',
                        variable: decreaseNumSize(tabGoldPerDay),
                      ),
                    ),
                    Expanded(
                      child: ExpandedText(
                        name: 'AD Num: ',
                        variable: (tabGoldPerDay / adGold)
                            .toStringAsFixed(2),
                      ),
                    ),
                  ],
                ),
                Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text('Golden Tree'),
                          Checkbox(
                            value: _includeGoldenTree,
                            onChanged: (value) {
                              setState(() {
                                _includeGoldenTree = value ?? false;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text('Seasonal Colony'),
                          Checkbox(
                            value: _includeSeasonalColony,
                            onChanged: (value) {
                              setState(() {
                                _includeSeasonalColony = value ?? false;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
