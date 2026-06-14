import 'dart:convert';

/// Typed data model for the wave speed query page's persisted state.
class WaveSpeedQueryData {
  final int gameSpeed;
  final int chronoBonus;
  final bool equipHorn;
  final bool equipGoldenHorn;
  final int devilHornSkip;
  final bool isGoldAutoBattle;

  const WaveSpeedQueryData({
    required this.gameSpeed,
    required this.chronoBonus,
    required this.equipHorn,
    required this.equipGoldenHorn,
    required this.devilHornSkip,
    required this.isGoldAutoBattle,
  });

  /// Default values used when no saved data exists.
  factory WaveSpeedQueryData.defaults() {
    return const WaveSpeedQueryData(
      gameSpeed: 0,
      chronoBonus: 0,
      equipHorn: false,
      equipGoldenHorn: false,
      devilHornSkip: 1,
      isGoldAutoBattle: true,
    );
  }

  // ── JSON serialization ──────────────────────────────────────────────────

  factory WaveSpeedQueryData.fromJson(String jsonString) {
    final map = json.decode(jsonString) as Map<String, dynamic>;
    return WaveSpeedQueryData(
      gameSpeed: (map['gameSpeed'] as int?) ?? 0,
      chronoBonus: (map['chronoBonus'] as int?) ?? 0,
      equipHorn: map['equipHorn'] == true,
      equipGoldenHorn: map['equipGoldenHorn'] == true,
      devilHornSkip: (map['devilHornSkip'] as int?) ?? 1,
      isGoldAutoBattle: (map['isGoldAutoBattle'] as bool?) ?? true,
    );
  }

  String toJson() {
    return json.encode({
      'gameSpeed': gameSpeed,
      'chronoBonus': chronoBonus,
      'equipHorn': equipHorn,
      'equipGoldenHorn': equipGoldenHorn,
      'devilHornSkip': devilHornSkip,
      'isGoldAutoBattle': isGoldAutoBattle,
    });
  }

  // ── Equality ────────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WaveSpeedQueryData &&
          gameSpeed == other.gameSpeed &&
          chronoBonus == other.chronoBonus &&
          equipHorn == other.equipHorn &&
          equipGoldenHorn == other.equipGoldenHorn &&
          devilHornSkip == other.devilHornSkip &&
          isGoldAutoBattle == other.isGoldAutoBattle;

  @override
  int get hashCode => Object.hash(
        gameSpeed,
        chronoBonus,
        equipHorn,
        equipGoldenHorn,
        devilHornSkip,
        isGoldAutoBattle,
      );
}
