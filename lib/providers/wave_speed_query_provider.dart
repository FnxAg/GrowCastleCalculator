import 'package:flutter/foundation.dart';

import 'package:grow_castle_calculator/models/wave_speed_query_data.dart';
import 'package:grow_castle_calculator/services/preferences_service.dart';

// ── Constants ──────────────────────────────────────────────────────────────

const double baseSpeed = 74;
const double baseTabExtraWave = 44;
const List<double> gameSpeedRatio = [1, 1.0675, 1.459];
const List<double> chronoBonusRatio = [1, 1.037, 1.083];
const double hornRatio = 1.104;
const double goldenHornRatio = 1.365;

// ── Provider ───────────────────────────────────────────────────────────────

/// Manages the wave speed query state, persists it, and exposes computed WPH.
class WaveSpeedQueryProvider with ChangeNotifier {
  WaveSpeedQueryData _data = WaveSpeedQueryData.defaults();

  WaveSpeedQueryData get data => _data;

  // ── Computed results ────────────────────────────────────────────────────

  int get wph => getWph(
        _data.devilHornSkip,
        _data.isGoldAutoBattle,
        _data.gameSpeed,
        _data.chronoBonus,
        _data.equipHorn,
        _data.equipGoldenHorn,
      ).round();

  int get wps => wph * 120;

  // ── Initialization ──────────────────────────────────────────────────────

  Future<void> init() async {
    _data = await PreferencesService.loadWaveSpeedQueryData();
    notifyListeners();
  }

  // ── Mutations ───────────────────────────────────────────────────────────

  void setGameSpeed(int value) {
    if (_data.gameSpeed == value) return;
    _data = WaveSpeedQueryData(
      gameSpeed: value,
      chronoBonus: _data.chronoBonus,
      equipHorn: _data.equipHorn,
      equipGoldenHorn: _data.equipGoldenHorn,
      devilHornSkip: _data.devilHornSkip,
      isGoldAutoBattle: _data.isGoldAutoBattle,
    );
    _notify();
  }

  void setChronoBonus(int value) {
    if (_data.chronoBonus == value) return;
    _data = WaveSpeedQueryData(
      gameSpeed: _data.gameSpeed,
      chronoBonus: value,
      equipHorn: _data.equipHorn,
      equipGoldenHorn: _data.equipGoldenHorn,
      devilHornSkip: _data.devilHornSkip,
      isGoldAutoBattle: _data.isGoldAutoBattle,
    );
    _notify();
  }

  void setEquipHorn(bool value) {
    if (_data.equipHorn == value) return;
    _data = WaveSpeedQueryData(
      gameSpeed: _data.gameSpeed,
      chronoBonus: _data.chronoBonus,
      equipHorn: value,
      equipGoldenHorn: _data.equipGoldenHorn,
      devilHornSkip: _data.devilHornSkip,
      isGoldAutoBattle: _data.isGoldAutoBattle,
    );
    _notify();
  }

  void setEquipGoldenHorn(bool value) {
    if (_data.equipGoldenHorn == value) return;
    _data = WaveSpeedQueryData(
      gameSpeed: _data.gameSpeed,
      chronoBonus: _data.chronoBonus,
      equipHorn: _data.equipHorn,
      equipGoldenHorn: value,
      devilHornSkip: _data.devilHornSkip,
      isGoldAutoBattle: _data.isGoldAutoBattle,
    );
    _notify();
  }

  void setDevilHornSkip(int value) {
    if (_data.devilHornSkip == value) return;
    _data = WaveSpeedQueryData(
      gameSpeed: _data.gameSpeed,
      chronoBonus: _data.chronoBonus,
      equipHorn: _data.equipHorn,
      equipGoldenHorn: _data.equipGoldenHorn,
      devilHornSkip: value,
      isGoldAutoBattle: _data.isGoldAutoBattle,
    );
    _notify();
  }

  void setIsGoldAutoBattle(bool value) {
    if (_data.isGoldAutoBattle == value) return;
    _data = WaveSpeedQueryData(
      gameSpeed: _data.gameSpeed,
      chronoBonus: _data.chronoBonus,
      equipHorn: _data.equipHorn,
      equipGoldenHorn: _data.equipGoldenHorn,
      devilHornSkip: _data.devilHornSkip,
      isGoldAutoBattle: value,
    );
    _notify();
  }

  void _notify() {
    notifyListeners();
    PreferencesService.saveWaveSpeedQueryData(_data);
  }
}

// ── Calculation ────────────────────────────────────────────────────────────

double getWph(
  int devilHornSkip,
  bool isGoldAutoBattle,
  int gameSpeed,
  int chronoBonus,
  bool equipHorn,
  bool equipGoldenHorn,
) {
  return (baseSpeed * devilHornSkip + (isGoldAutoBattle ? 0 : baseTabExtraWave)) *
      gameSpeedRatio[gameSpeed] *
      chronoBonusRatio[chronoBonus] *
      (equipHorn ? hornRatio : 1) *
      (equipGoldenHorn ? goldenHornRatio : 1);
}
