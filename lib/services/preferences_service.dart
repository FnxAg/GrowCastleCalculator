import 'dart:convert';

import 'package:grow_castle_calculator/models/calculator_archive.dart';
import 'package:grow_castle_calculator/models/calculator_data.dart';
import 'package:grow_castle_calculator/models/gold_calculator_archive.dart';
import 'package:grow_castle_calculator/models/gold_calculator_data.dart';
import 'package:grow_castle_calculator/models/wave_speed_query_data.dart';
import 'package:grow_castle_calculator/services/database_service.dart';

/// Centralized access to all persisted app state.
///
/// Each page's data is stored as a single JSON string so that a save or load
/// costs exactly **one** database call instead of 5–6.  The backend was
/// migrated from SharedPreferences to SQLite — see [DatabaseService] for the
/// storage layer.
class PreferencesService {
  PreferencesService._();

  // ── Key constants ──────────────────────────────────────────────────────

  static const _keyLocaleChoice = 'localeChoice';
  static const _keyThemeChoice = 'themeChoice';
  static const _keyCalculatorData = 'calculator_data';
  static const _keyGoldCalculatorData = 'gold_calculator_data';
  static const _keyWaveSpeedQueryData = 'wave_speed_query_data';
  static const _keyCalculatorArchives = 'calculator_archives';
  static const _keyGoldCalculatorArchives = 'gold_calculator_archives';
  static const _keyGuildSubscriptionName = 'guild_subscription_name';
  static const _keyCalcVisibleColumns = 'calc_visible_columns';

  /// Keys that are removed during [clearAllData].
  static const List<String> allDataKeys = [
    _keyCalculatorData,
    _keyGoldCalculatorData,
    _keyWaveSpeedQueryData,
    _keyCalculatorArchives,
    _keyGoldCalculatorArchives,
    _keyGuildSubscriptionName,
    _keyCalcVisibleColumns,
  ];

  // ── Locale / Theme (kept as simple ints) ──────────────────────────────

  static Future<int> getLocaleChoice() async {
    return (await DatabaseService.getInt(_keyLocaleChoice)) ?? 0;
  }

  static Future<void> setLocaleChoice(int value) async {
    await DatabaseService.setInt(_keyLocaleChoice, value);
  }

  static Future<int> getThemeChoice() async {
    return (await DatabaseService.getInt(_keyThemeChoice)) ?? 0;
  }

  static Future<void> setThemeChoice(int value) async {
    await DatabaseService.setInt(_keyThemeChoice, value);
  }

  // ── Calculator page (single JSON key) ─────────────────────────────────

  static Future<CalculatorData> loadCalculatorData() async {
    final jsonString = await DatabaseService.getString(_keyCalculatorData);
    if (jsonString != null) {
      return CalculatorData.fromJson(jsonString);
    }
    return CalculatorData.defaults();
  }

  static Future<void> saveCalculatorData(CalculatorData data) async {
    await DatabaseService.setString(_keyCalculatorData, data.toJson());
  }

  // ── Gold calculator page (single JSON key) ────────────────────────────

  static Future<GoldCalculatorData> loadGoldCalculatorData() async {
    final jsonString =
        await DatabaseService.getString(_keyGoldCalculatorData);
    if (jsonString != null) {
      return GoldCalculatorData.fromJson(jsonString);
    }
    return GoldCalculatorData.defaults();
  }

  static Future<void> saveGoldCalculatorData(GoldCalculatorData data) async {
    await DatabaseService.setString(_keyGoldCalculatorData, data.toJson());
  }

  // ── Wave speed query page (single JSON key) ───────────────────────────

  static Future<WaveSpeedQueryData> loadWaveSpeedQueryData() async {
    final jsonString =
        await DatabaseService.getString(_keyWaveSpeedQueryData);
    if (jsonString != null) {
      return WaveSpeedQueryData.fromJson(jsonString);
    }
    return WaveSpeedQueryData.defaults();
  }

  static Future<void> saveWaveSpeedQueryData(WaveSpeedQueryData data) async {
    await DatabaseService.setString(_keyWaveSpeedQueryData, data.toJson());
  }

  // ── Calculator archives ────────────────────────────────────────────────

  /// Loads all saved calculator archives.
  static Future<List<CalculatorArchive>> loadArchives() async {
    final jsonString =
        await DatabaseService.getString(_keyCalculatorArchives);
    if (jsonString == null || jsonString.isEmpty) return [];

    try {
      final list = json.decode(jsonString) as List<dynamic>;
      return list
          .map((e) => CalculatorArchive.fromJson(json.encode(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Saves the full list of calculator archives.
  static Future<void> saveArchives(List<CalculatorArchive> archives) async {
    final list = archives.map((a) => a.toMap()).toList();
    await DatabaseService.setString(
      _keyCalculatorArchives,
      json.encode(list),
    );
  }

  // ── Gold calculator archives ───────────────────────────────────────────

  /// Loads all saved gold calculator archives.
  static Future<List<GoldCalculatorArchive>> loadGoldArchives() async {
    final jsonString =
        await DatabaseService.getString(_keyGoldCalculatorArchives);
    if (jsonString == null || jsonString.isEmpty) return [];

    try {
      final list = json.decode(jsonString) as List<dynamic>;
      return list
          .map((e) => GoldCalculatorArchive.fromJson(json.encode(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Saves the full list of gold calculator archives.
  static Future<void> saveGoldArchives(
      List<GoldCalculatorArchive> archives) async {
    final list = archives.map((a) => a.toMap()).toList();
    await DatabaseService.setString(
      _keyGoldCalculatorArchives,
      json.encode(list),
    );
  }

  // ── Guild subscription (simple string key) ─────────────────────────────

  static Future<String?> loadGuildSubscriptionName() async {
    return DatabaseService.getString(_keyGuildSubscriptionName);
  }

  static Future<void> saveGuildSubscriptionName(String name) async {
    await DatabaseService.setString(_keyGuildSubscriptionName, name);
  }

  static Future<void> clearGuildSubscriptionName() async {
    await DatabaseService.remove(_keyGuildSubscriptionName);
  }

  // ── Column visibility (was previously raw SharedPreferences) ───────────

  /// Loads calculator column visibility.
  /// Defaults to all four columns visible (`[true, true, true, true]`).
  static Future<List<bool>> loadColumnVisibility() async {
    final jsonString =
        await DatabaseService.getString(_keyCalcVisibleColumns);
    if (jsonString == null) return List.filled(4, true);
    try {
      final list = json.decode(jsonString) as List<dynamic>;
      if (list.length != 4) return List.filled(4, true);
      return list.map((e) => e.toString() == 'true').toList();
    } catch (_) {
      return List.filled(4, true);
    }
  }

  /// Persists calculator column visibility.
  static Future<void> saveColumnVisibility(List<bool> columns) async {
    final list = columns.map((e) => e.toString()).toList();
    await DatabaseService.setString(
      _keyCalcVisibleColumns,
      json.encode(list),
    );
  }

  // ── Bulk operations ────────────────────────────────────────────────────

  /// Removes all app data, but keeps locale/theme.
  static Future<void> clearAllData() async {
    await DatabaseService.removeAll(allDataKeys);
  }

  /// Exports all stored data as a JSON-serializable [Map].
  static Future<Map<String, dynamic>> exportAllData() async {
    final data = <String, dynamic>{};

    final calcJson = await DatabaseService.getString(_keyCalculatorData);
    if (calcJson != null) {
      data[_keyCalculatorData] = calcJson;
    }
    final gcJson = await DatabaseService.getString(_keyGoldCalculatorData);
    if (gcJson != null) {
      data[_keyGoldCalculatorData] = gcJson;
    }
    final wsqJson =
        await DatabaseService.getString(_keyWaveSpeedQueryData);
    if (wsqJson != null) {
      data[_keyWaveSpeedQueryData] = wsqJson;
    }
    final archivesJson =
        await DatabaseService.getString(_keyCalculatorArchives);
    if (archivesJson != null) {
      data[_keyCalculatorArchives] = archivesJson;
    }
    final gcArchivesJson =
        await DatabaseService.getString(_keyGoldCalculatorArchives);
    if (gcArchivesJson != null) {
      data[_keyGoldCalculatorArchives] = gcArchivesJson;
    }
    final subName =
        await DatabaseService.getString(_keyGuildSubscriptionName);
    if (subName != null) {
      data[_keyGuildSubscriptionName] = subName;
    }
    final colVis =
        await DatabaseService.getString(_keyCalcVisibleColumns);
    if (colVis != null) {
      data[_keyCalcVisibleColumns] = colVis;
    }

    // Also export locale/theme for completeness.
    final locale = await DatabaseService.getInt(_keyLocaleChoice);
    data[_keyLocaleChoice] = locale ?? 0;
    final theme = await DatabaseService.getInt(_keyThemeChoice);
    data[_keyThemeChoice] = theme ?? 0;

    return data;
  }

  /// Imports data from a [Map] previously produced by [exportAllData].
  static Future<void> importData(Map<String, dynamic> data) async {
    // New-format keys.
    if (data[_keyCalculatorData] is String) {
      await DatabaseService.setString(
          _keyCalculatorData, data[_keyCalculatorData] as String);
    }
    if (data[_keyGoldCalculatorData] is String) {
      await DatabaseService.setString(
          _keyGoldCalculatorData, data[_keyGoldCalculatorData] as String);
    }
    if (data[_keyWaveSpeedQueryData] is String) {
      await DatabaseService.setString(
          _keyWaveSpeedQueryData, data[_keyWaveSpeedQueryData] as String);
    }
    if (data[_keyCalculatorArchives] is String) {
      await DatabaseService.setString(
          _keyCalculatorArchives, data[_keyCalculatorArchives] as String);
    }
    if (data[_keyGoldCalculatorArchives] is String) {
      await DatabaseService.setString(_keyGoldCalculatorArchives,
          data[_keyGoldCalculatorArchives] as String);
    }
    if (data[_keyGuildSubscriptionName] is String) {
      await DatabaseService.setString(_keyGuildSubscriptionName,
          data[_keyGuildSubscriptionName] as String);
    }
    if (data[_keyCalcVisibleColumns] is String) {
      await DatabaseService.setString(
          _keyCalcVisibleColumns, data[_keyCalcVisibleColumns] as String);
    }

    // Locale / theme.
    if (data[_keyLocaleChoice] is int) {
      await DatabaseService.setInt(
          _keyLocaleChoice, data[_keyLocaleChoice] as int);
    }
    if (data[_keyThemeChoice] is int) {
      await DatabaseService.setInt(
          _keyThemeChoice, data[_keyThemeChoice] as int);
    }
  }
}
