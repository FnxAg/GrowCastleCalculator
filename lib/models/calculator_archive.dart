import 'dart:convert';

/// A single saved archive of calculator page state, including metadata.
class CalculatorArchive {
  final String id;
  final String name;
  final DateTime savedAt;
  final DateTime updatedAt;
  final bool isOnlineQuery;
  final String gameName;
  final int dynamicFormNum;
  final List<int> waveValue;
  final List<String> targetName;
  final List<int> targetLevel;
  final List<bool> targetCheckbox;
  final List<bool> visibleColumns;
  final int queriedWave;
  final int queriedScore;
  final String? lastQueryDate;
  final bool hasQueryResult;

  const CalculatorArchive({
    required this.id,
    required this.name,
    required this.savedAt,
    required this.updatedAt,
    required this.isOnlineQuery,
    required this.gameName,
    required this.dynamicFormNum,
    required this.waveValue,
    required this.targetName,
    required this.targetLevel,
    required this.targetCheckbox,
    required this.visibleColumns,
    required this.queriedWave,
    required this.queriedScore,
    this.lastQueryDate,
    required this.hasQueryResult,
  });

  // ── JSON serialization ────────────────────────────────────────────────

  factory CalculatorArchive.fromJson(String jsonString) {
    final map = json.decode(jsonString) as Map<String, dynamic>;
    return CalculatorArchive(
      id: map['id'] as String,
      name: map['name'] as String,
      savedAt: DateTime.parse(map['savedAt'] as String),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.parse(map['savedAt'] as String),
      isOnlineQuery: map['isOnlineQuery'] as bool? ?? true,
      gameName: map['gameName'] as String? ?? '',
      dynamicFormNum: map['dynamicFormNum'] as int,
      waveValue: (map['waveValue'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      targetName: (map['targetName'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      targetLevel: (map['targetLevel'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      targetCheckbox: (map['targetCheckbox'] as List<dynamic>)
          .map((e) => e == true)
          .toList(),
      visibleColumns: (map['visibleColumns'] as List<dynamic>?)
              ?.map((e) => e == true)
              .toList() ??
          List.filled(4, true),
      queriedWave: map['queriedWave'] as int? ?? 0,
      queriedScore: map['queriedScore'] as int? ?? 0,
      lastQueryDate: map['lastQueryDate'] as String?,
      hasQueryResult: map['hasQueryResult'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'savedAt': savedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isOnlineQuery': isOnlineQuery,
      'gameName': gameName,
      'dynamicFormNum': dynamicFormNum,
      'waveValue': waveValue,
      'targetName': targetName,
      'targetLevel': targetLevel,
      'targetCheckbox': targetCheckbox,
      'visibleColumns': visibleColumns,
      'queriedWave': queriedWave,
      'queriedScore': queriedScore,
      'lastQueryDate': lastQueryDate,
      'hasQueryResult': hasQueryResult,
    };
  }

  String toJson() => json.encode(toMap());
}
