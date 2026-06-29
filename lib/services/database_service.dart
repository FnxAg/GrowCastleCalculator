import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:grow_castle_calculator/models/calculator_data.dart';
import 'package:grow_castle_calculator/models/gold_calculator_data.dart';

/// Low-level SQLite key-value store backing [PreferencesService].
///
/// Call [ensureInitialized] once at startup before any read/write.  The first
/// call automatically migrates existing SharedPreferences data into the
/// database.
class DatabaseService {
  DatabaseService._();

  // ── Cached database handle ──────────────────────────────────────────────

  static sqflite.Database? _database;
  static Completer<void>? _initCompleter;

  // ── Key constants ────────────────────────────────────────────────────────

  /// Keys stored in the database (mirrors PreferencesService key set).
  static const keyLocaleChoice = 'localeChoice';
  static const keyThemeChoice = 'themeChoice';
  static const keyCalculatorData = 'calculator_data';
  static const keyGoldCalculatorData = 'gold_calculator_data';
  static const keyWaveSpeedQueryData = 'wave_speed_query_data';
  static const keyCalculatorArchives = 'calculator_archives';
  static const keyGoldCalculatorArchives = 'gold_calculator_archives';
  static const keyGuildSubscriptionName = 'guild_subscription_name';
  static const keyCalcVisibleColumns = 'calc_visible_columns';

  /// Internal flag written after the SharedPreferences → SQLite migration.
  static const _keyMigrationComplete = '_migration_complete';

  /// All app-data keys (cleared by clearAllData, excludes locale/theme).
  static const List<String> allDataKeys = [
    keyCalculatorData,
    keyGoldCalculatorData,
    keyWaveSpeedQueryData,
    keyCalculatorArchives,
    keyGoldCalculatorArchives,
    keyGuildSubscriptionName,
    keyCalcVisibleColumns,
  ];

  /// Every key the migration reads from SharedPreferences.
  static const _allMigrationKeys = [
    keyLocaleChoice,
    keyThemeChoice,
    keyCalculatorData,
    keyGoldCalculatorData,
    keyWaveSpeedQueryData,
    keyCalculatorArchives,
    keyGoldCalculatorArchives,
    keyGuildSubscriptionName,
    keyCalcVisibleColumns,
    // Legacy per-field keys (may not exist in new-format stores but kept
    // so older installs are fully migrated).
    'dynamicFormNum',
    'waveValue',
    'targetName',
    'targetLevel',
    'targetCheckbox',
    'gc_waveValue',
    'gc_formField',
    'gc_checkboxForm',
    'gc_isExpanded',
  ];

  // ── Initialisation ───────────────────────────────────────────────────────

  /// Opens (or creates) the SQLite database and runs the one-time
  /// SharedPreferences → SQLite migration if needed.
  ///
  /// Must be called before any other [DatabaseService] method.  Safe to call
  /// multiple times — subsequent calls return immediately.
  static Future<void> ensureInitialized() async {
    if (_database != null) return;
    if (_initCompleter != null) {
      await _initCompleter!.future;
      return;
    }

    _initCompleter = Completer<void>();
    try {
      final factory = _resolveFactory();
      final dbPath = await factory.getDatabasesPath();
      final path = p.join(dbPath, 'grow_castle_calculator.db');

      _database = await _openDatabase(factory, path);
      await _migrateFromSharedPreferences();
      _initCompleter!.complete();
    } catch (e) {
      _initCompleter!.completeError(e);
      _initCompleter = null;
      rethrow;
    }
  }

  /// Opens the database file, creating the schema on first access.
  /// Retries once after deleting a corrupt file.
  static Future<sqflite.Database> _openDatabase(
    sqflite.DatabaseFactory factory,
    String path,
  ) async {
    sqflite.OpenDatabaseOptions makeOptions() => sqflite.OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS app_data (
                key  TEXT PRIMARY KEY NOT NULL,
                value TEXT NOT NULL
              )
            ''');
          },
        );

    try {
      return await factory.openDatabase(path, options: makeOptions());
    } catch (_) {
      // Corrupt database — delete and retry once.
      await factory.deleteDatabase(path);
      return factory.openDatabase(path, options: makeOptions());
    }
  }

  // ── Platform dispatching ─────────────────────────────────────────────────

  /// Returns the correct database factory for the current platform.
  static sqflite.DatabaseFactory _resolveFactory() {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      return databaseFactoryFfi;
    }
    // Android, iOS, macOS use the native sqflite plugin.
    return sqflite.databaseFactory;
  }

  // ── Core CRUD ────────────────────────────────────────────────────────────

  /// Reads a string value, or `null` if the key doesn't exist.
  static Future<String?> getString(String key) async {
    final db = _database!;
    final rows = await db.query(
      'app_data',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String;
  }

  /// Stores (inserts or replaces) a string value.
  static Future<void> setString(String key, String value) async {
    final db = _database!;
    await db.insert(
      'app_data',
      {'key': key, 'value': value},
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  /// Reads an integer value, or `null` if the key doesn't exist.
  static Future<int?> getInt(String key) async {
    final raw = await getString(key);
    if (raw == null) return null;
    return int.tryParse(raw);
  }

  /// Stores an integer value (as its string representation).
  static Future<void> setInt(String key, int value) async {
    await setString(key, value.toString());
  }

  /// Returns `true` when the key is present in the database.
  static Future<bool> containsKey(String key) async {
    final db = _database!;
    final count = sqflite.Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM app_data WHERE key = ?',
        [key],
      ),
    );
    return (count ?? 0) > 0;
  }

  /// Removes a single key.
  static Future<void> remove(String key) async {
    final db = _database!;
    await db.delete('app_data', where: 'key = ?', whereArgs: [key]);
  }

  /// Removes multiple keys in one operation.
  static Future<void> removeAll(Iterable<String> keys) async {
    final db = _database!;
    final batch = db.batch();
    for (final key in keys) {
      batch.delete('app_data', where: 'key = ?', whereArgs: [key]);
    }
    await batch.commit(noResult: true);
  }

  /// Reads multiple keys and returns a map with their parsed values.
  ///
  /// Keys that are not found are omitted from the result.  Integer values
  /// are returned as `int`, everything else as `String`.
  static Future<Map<String, dynamic>> getAll(Iterable<String> keys) async {
    final db = _database!;
    final keyList = keys.toList();
    if (keyList.isEmpty) return {};

    final placeholders = keyList.map((_) => '?').join(',');
    final rows = await db.rawQuery(
      'SELECT key, value FROM app_data WHERE key IN ($placeholders)',
      keyList,
    );

    final result = <String, dynamic>{};
    for (final row in rows) {
      final k = row['key'] as String;
      final v = row['value'] as String;
      // Try to parse as int; keep as String otherwise.
      final parsed = int.tryParse(v);
      result[k] = parsed ?? v;
    }
    return result;
  }

  // ── Legacy key conversion helpers ─────────────────────────────────────────

  /// If [rawValues] contains legacy calculator per-field keys but no
  /// `calculator_data` key, builds a [CalculatorData] and inserts it.
  static void _convertLegacyCalculatorData(
    Map<String, dynamic> rawValues,
    SharedPreferences prefs,
  ) {
    if (rawValues.containsKey(keyCalculatorData)) return;

    final waveStr = prefs.getStringList('waveValue');
    if (waveStr == null) return; // no legacy data

    final data = CalculatorData(
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
    rawValues[keyCalculatorData] = data.toJson();

    // Remove legacy keys so they are not stored separately.
    for (final k in _legacyCalculatorKeys) {
      rawValues.remove(k);
    }
  }

  /// If [rawValues] contains legacy gold-calculator per-field keys but no
  /// `gold_calculator_data` key, builds a [GoldCalculatorData] and inserts it.
  static void _convertLegacyGoldCalculatorData(
    Map<String, dynamic> rawValues,
    SharedPreferences prefs,
  ) {
    if (rawValues.containsKey(keyGoldCalculatorData)) return;

    final waveStr = prefs.getStringList('gc_waveValue');
    if (waveStr == null) return; // no legacy data

    final data = GoldCalculatorData(
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
    rawValues[keyGoldCalculatorData] = data.toJson();

    // Remove legacy keys so they are not stored separately.
    for (final k in _legacyGoldCalculatorKeys) {
      rawValues.remove(k);
    }
  }

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

  // ── SharedPreferences → SQLite migration ────────────────────────────────

  /// Copies all known keys from SharedPreferences into the SQLite database,
  /// then marks the migration as complete.
  ///
  /// SharedPreferences keys are **not** deleted so the user can safely roll
  /// back to a previous app version.
  static Future<void> _migrateFromSharedPreferences() async {
    // Guard: only run once.
    if (await containsKey(_keyMigrationComplete)) return;

    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {
      // SharedPreferences unavailable (fresh install without the package,
      // or platform issue).  Mark done and move on.
      await setString(_keyMigrationComplete, 'true');
      return;
    }

    // Read every known key from SharedPreferences.
    final rawValues = <String, dynamic>{};
    final keys = prefs.getKeys();
    for (final key in _allMigrationKeys) {
      if (!keys.contains(key)) continue;
      final value = prefs.get(key);
      if (value != null) rawValues[key] = value;
    }

    // Convert legacy per-field keys to new-format JSON strings.
    _convertLegacyCalculatorData(rawValues, prefs);
    _convertLegacyGoldCalculatorData(rawValues, prefs);

    // Build the final key→value map for SQLite.
    final toInsert = <String, String>{};
    for (final entry in rawValues.entries) {
      final v = entry.value;
      if (v is String) {
        toInsert[entry.key] = v;
      } else if (v is int) {
        toInsert[entry.key] = v.toString();
      } else if (v is double) {
        toInsert[entry.key] = v.toString();
      } else if (v is bool) {
        toInsert[entry.key] = v.toString();
      } else if (v is List<String>) {
        toInsert[entry.key] = json.encode(v);
      }
    }

    // Batch-write all migrated data inside a transaction.
    if (toInsert.isNotEmpty) {
      final db = _database!;
      final batch = db.batch();
      for (final entry in toInsert.entries) {
        batch.insert(
          'app_data',
          {'key': entry.key, 'value': entry.value},
          conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    }

    await setString(_keyMigrationComplete, 'true');
  }
}
