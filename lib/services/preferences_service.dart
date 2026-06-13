import 'package:shared_preferences/shared_preferences.dart';

/// Centralized access to all [SharedPreferences] keys used by the app.
///
/// All persistence keys and their read/write logic live here so that pages
/// don't scatter magic strings or duplicate save/load patterns.
class PreferencesService {
  PreferencesService._();

  // ── Key constants ──────────────────────────────────────────────────────

  static const _keyLocaleChoice = 'localeChoice';
  static const _keyThemeChoice = 'themeChoice';
  static const _keyDynamicFormNum = 'dynamicFormNum';
  static const _keyWaveValue = 'waveValue';
  static const _keyTargetName = 'targetName';
  static const _keyTargetLevel = 'targetLevel';
  static const _keyTargetCheckbox = 'targetCheckbox';
  static const _keyGcWaveValue = 'gc_waveValue';
  static const _keyGcFormField = 'gc_formField';
  static const _keyGcCheckboxForm = 'gc_checkboxForm';
  static const _keyGcIsExpanded = 'gc_isExpanded';

  /// All data keys used by the app (for export / clear-data operations).
  static const List<String> allDataKeys = [
    _keyDynamicFormNum,
    _keyWaveValue,
    _keyTargetName,
    _keyTargetLevel,
    _keyTargetCheckbox,
    _keyGcWaveValue,
    _keyGcFormField,
    _keyGcCheckboxForm,
    _keyGcIsExpanded,
  ];

  /// Subset of keys whose values are stored as [StringList].
  static const Set<String> stringListKeys = {
    _keyWaveValue,
    _keyTargetName,
    _keyTargetLevel,
    _keyTargetCheckbox,
    _keyGcWaveValue,
    _keyGcFormField,
    _keyGcCheckboxForm,
    _keyGcIsExpanded,
  };

  // ── Convenience getter ─────────────────────────────────────────────────

  static Future<SharedPreferences> get _prefs =>
      SharedPreferences.getInstance();

  // ── Locale ──────────────────────────────────────────────────────────────

  static Future<int> getLocaleChoice() async {
    final prefs = await _prefs;
    return prefs.getInt(_keyLocaleChoice) ?? 0;
  }

  static Future<void> setLocaleChoice(int value) async {
    final prefs = await _prefs;
    await prefs.setInt(_keyLocaleChoice, value);
  }

  // ── Theme ───────────────────────────────────────────────────────────────

  static Future<int> getThemeChoice() async {
    final prefs = await _prefs;
    return prefs.getInt(_keyThemeChoice) ?? 0;
  }

  static Future<void> setThemeChoice(int value) async {
    final prefs = await _prefs;
    await prefs.setInt(_keyThemeChoice, value);
  }

  // ── Calculator page data ───────────────────────────────────────────────

  static Future<Map<String, dynamic>> loadCalculatorData() async {
    final prefs = await _prefs;
    return {
      'dynamicFormNum': prefs.getInt(_keyDynamicFormNum) ?? 7,
      'waveValue': prefs.getStringList(_keyWaveValue) ?? ['1000000', '40000'],
      'targetName': prefs.getStringList(_keyTargetName) ?? [],
      'targetLevel': prefs.getStringList(_keyTargetLevel) ?? [],
      'targetCheckbox': prefs.getStringList(_keyTargetCheckbox) ?? [],
    };
  }

  static Future<void> saveCalculatorData({
    required int dynamicFormNum,
    required List<String> waveValue,
    required List<String> targetName,
    required List<String> targetLevel,
    required List<String> targetCheckbox,
  }) async {
    final prefs = await _prefs;
    await prefs.setInt(_keyDynamicFormNum, dynamicFormNum);
    await prefs.setStringList(_keyWaveValue, waveValue);
    await prefs.setStringList(_keyTargetName, targetName);
    await prefs.setStringList(_keyTargetLevel, targetLevel);
    await prefs.setStringList(_keyTargetCheckbox, targetCheckbox);
  }

  // ── Gold calculator page data ──────────────────────────────────────────

  static Future<Map<String, dynamic>> loadGoldCalculatorData() async {
    final prefs = await _prefs;
    return {
      'gc_waveValue':
          prefs.getStringList(_keyGcWaveValue) ?? ['1000000', '40000'],
      'gc_formField': prefs.getStringList(_keyGcFormField) ?? [],
      'gc_checkboxForm': prefs.getStringList(_keyGcCheckboxForm) ?? [],
      'gc_isExpanded': prefs.getStringList(_keyGcIsExpanded) ?? [],
    };
  }

  static Future<void> saveGoldCalculatorData({
    required List<String> gcWaveValue,
    required List<String> gcFormField,
    required List<String> gcCheckboxForm,
    required List<String> gcIsExpanded,
  }) async {
    final prefs = await _prefs;
    await prefs.setStringList(_keyGcWaveValue, gcWaveValue);
    await prefs.setStringList(_keyGcFormField, gcFormField);
    await prefs.setStringList(_keyGcCheckboxForm, gcCheckboxForm);
    await prefs.setStringList(_keyGcIsExpanded, gcIsExpanded);
  }

  // ── Bulk operations ────────────────────────────────────────────────────

  /// Removes all app data from SharedPreferences (does NOT remove locale / theme).
  static Future<void> clearAllData() async {
    final prefs = await _prefs;
    for (final key in allDataKeys) {
      await prefs.remove(key);
    }
  }

  /// Exports all stored data as a [Map].
  static Future<Map<String, dynamic>> exportAllData() async {
    final prefs = await _prefs;
    final data = <String, dynamic>{};
    for (final key in allDataKeys) {
      if (stringListKeys.contains(key)) {
        data[key] = prefs.getStringList(key);
      } else {
        data[key] = prefs.getInt(key);
      }
    }
    return data;
  }

  /// Imports data from a [Map] (only keys in [allDataKeys] are processed).
  static Future<void> importData(Map<String, dynamic> data) async {
    final prefs = await _prefs;
    for (final key in allDataKeys) {
      if (!data.containsKey(key)) continue;
      final value = data[key];
      if (stringListKeys.contains(key)) {
        if (value is List) {
          await prefs.setStringList(
            key,
            value.map((e) => e.toString()).toList(),
          );
        }
      } else {
        if (value is int) {
          await prefs.setInt(key, value);
        } else if (value is String) {
          await prefs.setInt(key, int.tryParse(value) ?? 0);
        }
      }
    }
  }
}
