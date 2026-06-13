import 'dart:convert';

/// Typed data model for the gold calculator page's persisted state.
class GoldCalculatorData {
  final List<int> waveValue;
  final List<num> formField;
  final List<bool> checkboxForm;
  final List<bool> isExpanded;

  const GoldCalculatorData({
    required this.waveValue,
    required this.formField,
    required this.checkboxForm,
    required this.isExpanded,
  });

  /// Default values used when no saved data exists.
  factory GoldCalculatorData.defaults() {
    return const GoldCalculatorData(
      waveValue: [1000000, 40000],
      formField: [],
      checkboxForm: [],
      isExpanded: [],
    );
  }

  // ── JSON serialization ────────────────────────────────────────────────

  factory GoldCalculatorData.fromJson(String jsonString) {
    final map = json.decode(jsonString) as Map<String, dynamic>;
    return GoldCalculatorData(
      waveValue: (map['waveValue'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [1000000, 40000],
      formField: (map['formField'] as List<dynamic>?)
              ?.map((e) => e as num)
              .toList() ??
          [],
      checkboxForm: (map['checkboxForm'] as List<dynamic>?)
              ?.map((e) => e == true || e == 'true')
              .toList() ??
          [],
      isExpanded: (map['isExpanded'] as List<dynamic>?)
              ?.map((e) => e == true || e == 'true')
              .toList() ??
          [],
    );
  }

  String toJson() {
    return json.encode({
      'waveValue': waveValue,
      'formField': formField,
      'checkboxForm': checkboxForm,
      'isExpanded': isExpanded,
    });
  }

  // ── Equality ──────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoldCalculatorData &&
          _listEquals(waveValue, other.waveValue) &&
          _listEquals(formField, other.formField) &&
          _listEquals(checkboxForm, other.checkboxForm) &&
          _listEquals(isExpanded, other.isExpanded);

  @override
  int get hashCode => Object.hash(
        Object.hashAll(waveValue),
        Object.hashAll(formField),
        Object.hashAll(checkboxForm),
        Object.hashAll(isExpanded),
      );

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
