import 'dart:convert';

/// Typed data model for the calculator page's persisted state.
class CalculatorData {
  final int dynamicFormNum;
  final List<int> waveValue;
  final List<String> targetName;
  final List<int> targetLevel;
  final List<bool> targetCheckbox;

  const CalculatorData({
    required this.dynamicFormNum,
    required this.waveValue,
    required this.targetName,
    required this.targetLevel,
    required this.targetCheckbox,
  });

  /// Default values used when no saved data exists.
  factory CalculatorData.defaults() {
    return const CalculatorData(
      dynamicFormNum: 7,
      waveValue: [1000000, 40000],
      targetName: [],
      targetLevel: [],
      targetCheckbox: [],
    );
  }

  // ── JSON serialization ────────────────────────────────────────────────

  factory CalculatorData.fromJson(String jsonString) {
    final map = json.decode(jsonString) as Map<String, dynamic>;
    return CalculatorData(
      dynamicFormNum: map['dynamicFormNum'] as int? ?? 7,
      waveValue: (map['waveValue'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [1000000, 40000],
      targetName: (map['targetName'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      targetLevel: (map['targetLevel'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
      targetCheckbox: (map['targetCheckbox'] as List<dynamic>?)
              ?.map((e) => e == true || e == 'true')
              .toList() ??
          [],
    );
  }

  String toJson() {
    return json.encode({
      'dynamicFormNum': dynamicFormNum,
      'waveValue': waveValue,
      'targetName': targetName,
      'targetLevel': targetLevel,
      'targetCheckbox': targetCheckbox,
    });
  }

  // ── Equality ──────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalculatorData &&
          dynamicFormNum == other.dynamicFormNum &&
          _listEquals(waveValue, other.waveValue) &&
          _listEquals(targetName, other.targetName) &&
          _listEquals(targetLevel, other.targetLevel) &&
          _listEquals(targetCheckbox, other.targetCheckbox);

  @override
  int get hashCode => Object.hash(
        dynamicFormNum,
        Object.hashAll(waveValue),
        Object.hashAll(targetName),
        Object.hashAll(targetLevel),
        Object.hashAll(targetCheckbox),
      );

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
