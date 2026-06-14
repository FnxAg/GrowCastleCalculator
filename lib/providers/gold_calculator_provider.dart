import 'package:flutter/material.dart';

import 'package:grow_castle_calculator/models/gold_calculator_data.dart';
import 'package:grow_castle_calculator/services/preferences_service.dart';

/// Provides the computed daily gold income from the gold calculator,
/// making it globally readable across pages.
class GoldCalculatorProvider with ChangeNotifier {
  double _dailyIncome = 0;

  double get dailyIncome => _dailyIncome;

  // ── Initialization ──────────────────────────────────────────────────────

  /// Loads persisted data and computes the initial daily income.
  Future<void> init() async {
    final data = await PreferencesService.loadGoldCalculatorData();
    _dailyIncome = computeDailyIncome(data);
    notifyListeners();
  }

  // ── Update ──────────────────────────────────────────────────────────────

  /// Updates the daily income from the given input data.
  void updateFromData(GoldCalculatorData data) {
    _dailyIncome = computeDailyIncome(data);
    notifyListeners();
  }

  /// Sets the daily income directly (called by the calculator page).
  void setDailyIncome(double value) {
    if (_dailyIncome != value) {
      _dailyIncome = value;
      notifyListeners();
    }
  }

  // ── Computation ─────────────────────────────────────────────────────────

  /// Computes [totalGoldPerDay] from the raw input data.
  static double computeDailyIncome(GoldCalculatorData data) {
    final w0 = data.waveValue.isNotEmpty ? data.waveValue[0] : 1000000;

    final f0 = _numToDouble(data.formField, 0);
    final f2 = _numToDouble(data.formField, 2);
    final f3 = _numToInt(data.formField, 3);
    final f4 = _numToInt(data.formField, 4);
    final f5 = _numToInt(data.formField, 5);
    final f6 = _numToDouble(data.formField, 6);
    final f7 = _numToDouble(data.formField, 7);
    final f8 = _numToDouble(data.formField, 8);

    final ironWheel = _boolAt(data.checkboxForm, 1);
    final goldenTree = _boolAt(data.checkboxForm, 2);
    final seasonalColony = _boolAt(data.checkboxForm, 3);

    // Gold per cart
    final goldPerCart = (f3 * 5400 + 1374406) / 1.2 * (1.2 + 0.01 * f5);

    // Seconds per cart
    final secondsPerCart =
        60 / ((f4 * 0.005 + 1.1) + (ironWheel ? 0.15 : 0));

    // Carts per hour
    final cartsPerHour =
        f2 == 0 ? 0.0 : (((f2 - 1.5) * f0 + 1.5) * 3600 / f2 / secondsPerCart);

    // Colony gold per day
    final colonyGoldPerDay = goldPerCart * cartsPerHour * 24;

    // Ad gold
    final adGold = w0 * 2160;

    // GAB cost
    final gabCost = 456.0 * w0 - 29264;

    // GAB benefit
    final gabBenefitGoldPerWave = gabCost * f7 * 0.01;
    final gabBenefitGoldPerHour =
        f2 == 0 ? 0.0 : 3600 / f2 * gabBenefitGoldPerWave;
    final gabBenefitGoldPerDay = gabBenefitGoldPerHour * f6;

    // TAB
    final tabGoldPerWave = gabCost * (1 + f7 * 0.01);
    final tabGoldPerHour = f2 == 0 ? 0.0 : tabGoldPerWave * (3600 / f2);
    final tabGoldPerDay = tabGoldPerHour * f8;

    // Golden Tree
    final goldenTreeGoldPerHour =
        f2 == 0 ? 0.0 : 48 / 456 * gabCost * 3600 / f2 / 2;
    final goldenTreeGoldPerDay =
        goldenTree ? ((f6 + f8) * goldenTreeGoldPerHour) : 0.0;

    // Seasonal Colony
    final seasonalColonyGoldPerHour = 16 * adGold / 24;
    final seasonalColonyGoldPerDay =
        seasonalColony ? seasonalColonyGoldPerHour * 24 : 0.0;

    return colonyGoldPerDay +
        gabBenefitGoldPerDay +
        tabGoldPerDay +
        goldenTreeGoldPerDay +
        seasonalColonyGoldPerDay;
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  static double _numToDouble(List<num> list, int index) {
    if (index >= list.length) return 0;
    return list[index].toDouble();
  }

  static int _numToInt(List<num> list, int index) {
    if (index >= list.length) return 0;
    return list[index].toInt();
  }

  static bool _boolAt(List<bool> list, int index) {
    if (index >= list.length) return false;
    return list[index];
  }
}
