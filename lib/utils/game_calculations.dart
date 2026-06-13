/// Holds the computed progress values for the three season types.
class SeasonProgress {
  final double seasonProgress;
  final double hellModeProgress;
  final double seasonalColonyProgress;

  /// Milliseconds remaining until the next season reset.
  final int seasonRemainingMs;
  final int hellModeRemainingMs;
  final int seasonalColonyRemainingMs;

  /// Timestamp (ms) of the next season update.
  final int seasonNextUpdateMs;
  final int hellModeNextUpdateMs;
  final int seasonalColonyNextUpdateMs;

  const SeasonProgress({
    required this.seasonProgress,
    required this.hellModeProgress,
    required this.seasonalColonyProgress,
    required this.seasonRemainingMs,
    required this.hellModeRemainingMs,
    required this.seasonalColonyRemainingMs,
    required this.seasonNextUpdateMs,
    required this.hellModeNextUpdateMs,
    required this.seasonalColonyNextUpdateMs,
  });
}

/// Calculates season progress based on the current time.
///
/// Season cycle:        432,000,000 ms (5 days), offset 312,900,000 ms
/// Hell Mode cycle:     604,800,000 ms (7 days), offset 310,800,000 ms
/// Seasonal Colony:     864,000,000 ms (10 days), offset 312,600,000 ms
SeasonProgress calculateSeasonProgress(DateTime now) {
  final nowMs = now.millisecondsSinceEpoch;

  final seasonPassedMs = _positiveMod(nowMs - 312900000, 432000000);
  final hellModePassedMs = _positiveMod(nowMs - 310800000, 604800000);
  final seasonalColonyPassedMs = _positiveMod(nowMs - 312600000, 864000000);

  return SeasonProgress(
    seasonProgress: seasonPassedMs / 432000000,
    hellModeProgress: hellModePassedMs / 604800000,
    seasonalColonyProgress: seasonalColonyPassedMs / 864000000,
    seasonRemainingMs: 432000000 - seasonPassedMs,
    hellModeRemainingMs: 604800000 - hellModePassedMs,
    seasonalColonyRemainingMs: 864000000 - seasonalColonyPassedMs,
    seasonNextUpdateMs: nowMs - seasonPassedMs + 432000000,
    hellModeNextUpdateMs: nowMs - hellModePassedMs + 604800000,
    seasonalColonyNextUpdateMs: nowMs - seasonalColonyPassedMs + 864000000,
  );
}

/// Computes `(value - offset) % modulus` ensuring a positive result.
int _positiveMod(int value, int modulus) {
  final diff = value % modulus;
  return diff >= 0 ? diff : diff + modulus;
}

/// Calculates the total gold cost to level a hero from level 1 to [level].
///
/// Uses predefined thresholds, base gold, base multiplier, and increment arrays
/// that model the in-game hero leveling cost curve.
double heroLevelSpendGold(int level) {
  if (level <= 0) return 0;

  const thresholds = [
    10000, 5000, 200, 180, 160, 140, 120, 100, 80, 60, 40, 20, 1,
  ];
  const baseGold = [
    187458432500, 37468432500, 35632500, 26157500, 18530000, 12530000,
    7997500, 4712500, 2475000, 1085000, 342500, 47500, 0,
  ];
  const baseMultiplier = [
    50000000, 20000000, 600000, 450000, 360000, 280000, 210000, 150000,
    100000, 60000, 30000, 10000, 250,
  ];
  const increment = [
    5000, 4000, 3000, 2500, 2250, 2000, 1750, 1500, 1250, 1000, 750, 500, 250,
  ];

  for (int i = 0; i < thresholds.length; i++) {
    if (level > thresholds[i]) {
      final diff = level - thresholds[i];
      return ((baseMultiplier[i] * 2 + increment[i] * (diff - 1)) / 2 * diff) +
          baseGold[i];
    }
  }

  return 0;
}

/// Wave gold formula: wave^2 * multiplier.
/// index 0 = castle (×1250), index 1 = town archer (×500), others = hero formula.
double waveLevelSpendGold(int level, int index) {
  if (index == 0) {
    return level * level * 1250.0;
  } else if (index == 1) {
    return level * level * 500.0;
  } else {
    return heroLevelSpendGold(level);
  }
}
