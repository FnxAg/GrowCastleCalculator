import 'package:shared_preferences/shared_preferences.dart';

import 'package:grow_castle_calculator/models/calculator_data.dart';
import 'package:grow_castle_calculator/models/gold_calculator_data.dart';
import 'package:grow_castle_calculator/models/wave_speed_query_data.dart';

/// Centralized access to all persisted app state.
///
/// Each page's data is stored as a single JSON string so that a save or load
/// costs exactly **one** platform-channel call instead of 5–6.  The service
/// also auto-migrates data that was stored with the old per-field key scheme.
class PreferencesService {
  PreferencesService._();

  // ── Cached instance ────────────────────────────────────────────────────

  static SharedPreferences? _instance;

  static Future<SharedPreferences> get _prefs async {
    _instance ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  /// Call after a sign-out / data-clear to force a fresh instance next read.
  static void _invalidate() {
    _instance = null;
  }

  // ── Key constants ──────────────────────────────────────────────────────

  static const _keyLocaleChoice = 'localeChoice';
  static const _keyThemeChoice = 'themeChoice';

  /// Single-key JSON storage (new format).
  static const _keyCalculatorData = 'calculator_data';
  static const _keyGoldCalculatorData = 'gold_calculator_data';
  static const _keyWaveSpeedQueryData = 'wave_speed_query_data';

  /// Old per-field keys — kept for migration.
  static const _legacyCalculatorKeys = [
    'dynamicFormNum',
    'waveValue',
    'targetName',
    'targetLevel',
    'targetCheckbox',
  ];
  static const _legacyGoldCalculatorKeys = [
    'gc_waveValue',
    'gc_formField',
    'gc_checkboxForm',
    'gc_isExpanded',
  ];

  /// Keys that are removed during [clearAllData].
  static const List<String> allDataKeys = [
    _keyCalculatorData,
    _keyGoldCalculatorData,
    _keyWaveSpeedQueryData,
    ..._legacyCalculatorKeys,
    ..._legacyGoldCalculatorKeys,
  ];

  // ── Locale / Theme (kept as simple ints — trivial) ────────────────────

  static Future<int> getLocaleChoice() async {
    final prefs = await _prefs;
    return prefs.getInt(_keyLocaleChoice) ?? 0;
  }

  static Future<void> setLocaleChoice(int value) async {
    final prefs = await _prefs;
    await prefs.setInt(_keyLocaleChoice, value);
  }

  static Future<int> getThemeChoice() async {
    final prefs = await _prefs;
    return prefs.getInt(_keyThemeChoice) ?? 0;
  }

  static Future<void> setThemeChoice(int value) async {
    final prefs = await _prefs;
    await prefs.setInt(_keyThemeChoice, value);
  }

  // ── Calculator page (single JSON key) ─────────────────────────────────

  /// Loads calculator data, migrating from the old per-field keys if needed.
  static Future<CalculatorData> loadCalculatorData() async {
    final prefs = await _prefs;
    final jsonString = prefs.getString(_keyCalculatorData);

    if (jsonString != null) {
      return CalculatorData.fromJson(jsonString);
    }

    // ── Migration: try old per-field keys ────────────────────────────────
    final migrated = _migrateCalculatorData(prefs);
    if (migrated != null) {
      // Persist in new format so next load hits the fast path.
      await prefs.setString(_keyCalculatorData, migrated.toJson());
      // Remove old keys.
      for (final key in _legacyCalculatorKeys) {
        await prefs.remove(key);
      }
      return migrated;
    }

    return CalculatorData.defaults();
  }

  static Future<void> saveCalculatorData(CalculatorData data) async {
    final prefs = await _prefs;
    await prefs.setString(_keyCalculatorData, data.toJson());
  }

  /// Attempts to build a [CalculatorData] from the old per-field keys.
  static CalculatorData? _migrateCalculatorData(SharedPreferences prefs) {
    final waveStr = prefs.getStringList('waveValue');
    if (waveStr == null) return null; // no old data at all

    return CalculatorData(
      dynamicFormNum: prefs.getInt('dynamicFormNum') ?? 7,
      waveValue: waveStr.map((e) => int.tryParse(e) ?? 0).toList(),
      targetName: prefs.getStringList('targetName') ?? [],
      targetLevel: (prefs.getStringList('targetLevel') ?? [])
          .map((e) => int.tryParse(e) ?? 10000)
          .toList(),
      targetCheckbox: (prefs.getStringList('targetCheckbox') ?? [])
          .map((e) => e == 'true')
          .toList(),
    );
  }

  // ── Gold calculator page (single JSON key) ────────────────────────────

  static Future<GoldCalculatorData> loadGoldCalculatorData() async {
    final prefs = await _prefs;
    final jsonString = prefs.getString(_keyGoldCalculatorData);

    if (jsonString != null) {
      return GoldCalculatorData.fromJson(jsonString);
    }

    // ── Migration ────────────────────────────────────────────────────────
    final migrated = _migrateGoldCalculatorData(prefs);
    if (migrated != null) {
      await prefs.setString(_keyGoldCalculatorData, migrated.toJson());
      for (final key in _legacyGoldCalculatorKeys) {
        await prefs.remove(key);
      }
      return migrated;
    }

    return GoldCalculatorData.defaults();
  }

  static Future<void> saveGoldCalculatorData(GoldCalculatorData data) async {
    final prefs = await _prefs;
    await prefs.setString(_keyGoldCalculatorData, data.toJson());
  }

  static GoldCalculatorData? _migrateGoldCalculatorData(SharedPreferences prefs) {
    final waveStr = prefs.getStringList('gc_waveValue');
    if (waveStr == null) return null;

    return GoldCalculatorData(
      waveValue: waveStr.map((e) => int.tryParse(e) ?? 0).toList(),
      formField: (prefs.getStringList('gc_formField') ?? [])
          .map((e) => int.tryParse(e) != null ? int.parse(e) : double.parse(e))
          .toList(),
      checkboxForm: (prefs.getStringList('gc_checkboxForm') ?? [])
          .map((e) => e == 'true')
          .toList(),
      isExpanded: (prefs.getStringList('gc_isExpanded') ?? [])
          .map((e) => e == 'true')
          .toList(),
    );
  }

  // ── Wave speed query page (single JSON key) ─────────────────────────────

  static Future<WaveSpeedQueryData> loadWaveSpeedQueryData() async {
    final prefs = await _prefs;
    final jsonString = prefs.getString(_keyWaveSpeedQueryData);
    if (jsonString != null) {
      return WaveSpeedQueryData.fromJson(jsonString);
    }
    return WaveSpeedQueryData.defaults();
  }

  static Future<void> saveWaveSpeedQueryData(WaveSpeedQueryData data) async {
    final prefs = await _prefs;
    await prefs.setString(_keyWaveSpeedQueryData, data.toJson());
  }

  // ── Bulk operations ────────────────────────────────────────────────────

  /// Removes all app data (both old and new formats), but keeps locale/theme.
  static Future<void> clearAllData() async {
    final prefs = await _prefs;
    for (final key in allDataKeys) {
      await prefs.remove(key);
    }
    _invalidate();
  }

  /// Exports all stored data as a JSON-serializable [Map].
  static Future<Map<String, dynamic>> exportAllData() async {
    final prefs = await _prefs;
    final data = <String, dynamic>{};

    // New-format keys (JSON strings stored directly).
    final calcJson = prefs.getString(_keyCalculatorData);
    if (calcJson != null) {
      data[_keyCalculatorData] = calcJson;
    }
    final gcJson = prefs.getString(_keyGoldCalculatorData);
    if (gcJson != null) {
      data[_keyGoldCalculatorData] = gcJson;
    }
    final wsqJson = prefs.getString(_keyWaveSpeedQueryData);
    if (wsqJson != null) {
      data[_keyWaveSpeedQueryData] = wsqJson;
    }

    // Also export locale/theme for completeness.
    data[_keyLocaleChoice] = prefs.getInt(_keyLocaleChoice) ?? 0;
    data[_keyThemeChoice] = prefs.getInt(_keyThemeChoice) ?? 0;

    return data;
  }

  /// Imports data from a [Map] previously produced by [exportAllData].
  static Future<void> importData(Map<String, dynamic> data) async {
    final prefs = await _prefs;

    // New-format keys.
    if (data[_keyCalculatorData] is String) {
      await prefs.setString(_keyCalculatorData, data[_keyCalculatorData]);
    }
    if (data[_keyGoldCalculatorData] is String) {
      await prefs.setString(_keyGoldCalculatorData, data[_keyGoldCalculatorData]);
    }
    if (data[_keyWaveSpeedQueryData] is String) {
      await prefs.setString(_keyWaveSpeedQueryData, data[_keyWaveSpeedQueryData]);
    }

    // Locale / theme.
    if (data[_keyLocaleChoice] is int) {
      await prefs.setInt(_keyLocaleChoice, data[_keyLocaleChoice]);
    }
    if (data[_keyThemeChoice] is int) {
      await prefs.setInt(_keyThemeChoice, data[_keyThemeChoice]);
    }

    // Clean up any legacy keys that may have come from an older export.
    for (final key in [..._legacyCalculatorKeys, ..._legacyGoldCalculatorKeys]) {
      await prefs.remove(key);
    }
  }
}
