import 'dart:convert';

/// A single saved archive of gold calculator page state, including metadata.
class GoldCalculatorArchive {
  final String id;
  final String name;
  final DateTime savedAt;
  final List<int> waveValue;
  final List<num> formField;
  final List<bool> checkboxForm;
  final List<bool> isExpanded;

  const GoldCalculatorArchive({
    required this.id,
    required this.name,
    required this.savedAt,
    required this.waveValue,
    required this.formField,
    required this.checkboxForm,
    required this.isExpanded,
  });

  // ── JSON serialization ────────────────────────────────────────────────

  factory GoldCalculatorArchive.fromJson(String jsonString) {
    final map = json.decode(jsonString) as Map<String, dynamic>;
    return GoldCalculatorArchive(
      id: map['id'] as String,
      name: map['name'] as String,
      savedAt: DateTime.parse(map['savedAt'] as String),
      waveValue: (map['waveValue'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      formField: (map['formField'] as List<dynamic>)
          .map((e) => e as num)
          .toList(),
      checkboxForm: (map['checkboxForm'] as List<dynamic>)
          .map((e) => e == true)
          .toList(),
      isExpanded: (map['isExpanded'] as List<dynamic>)
          .map((e) => e == true)
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'savedAt': savedAt.toIso8601String(),
      'waveValue': waveValue,
      'formField': formField,
      'checkboxForm': checkboxForm,
      'isExpanded': isExpanded,
    };
  }

  String toJson() => json.encode(toMap());
}
