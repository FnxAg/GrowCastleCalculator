import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grow_castle_calculator/pages/calculator_page.dart';

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      // body: const Center(child: Text('Gold Calculator')),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
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
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    readOnly: _goldCalculatorWaveBox ? true : false,
                    decoration: InputDecoration(
                      labelText: 'Current Wave',
                      hintText: 'Enter Current Wave',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: TextFormField(
                    controller: _goldCalculatorWaveController[1],
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    readOnly: _goldCalculatorWaveBox ? true : false,
                    decoration: InputDecoration(
                      labelText: 'Seasonal Wave',
                      hintText: 'Enter Seasonal Wave',
                      border: const OutlineInputBorder(),
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
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Game Speed',
                      hintText: 'Enter Game Speed',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Jump + Wave',
                      hintText: 'Enter Wave',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Wave Time (s)',
                      hintText: 'Enter Wave Time',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'IC Level',
                      hintText: 'Enter Infinite Colony Level',
                      border: const OutlineInputBorder(),
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
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Extra Colony CD Skill LV',
                      hintText: 'Enter Skill LV',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Extra Colony Gold Skill LV',
                      hintText: 'Enter Skill LV',
                      border: const OutlineInputBorder(),
                    ),
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
              spacing: 8,
              children: [
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'GAB Hour/Day',
                      hintText: 'Enter Hour',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Profit %',
                      hintText: 'Enter Profit',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'TAB Hour/Day',
                      hintText: 'Enter Hour',
                      border: const OutlineInputBorder(),
                    ),
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
                      Checkbox(value: _includeGoldenTree, onChanged: (value) {
                        setState(() {
                          _includeGoldenTree = value ?? false;
                        });
                      }),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text('Seasonal Colony'),
                      Checkbox(value: _includeSeasonalColony, onChanged: (value) {
                        setState(() {
                          _includeSeasonalColony = value ?? false;
                        });
                      }),
                    ],
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
