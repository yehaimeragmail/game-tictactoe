import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../engine/ttt_engine.dart';

/// Persisted settings + stats for Tic Tac Toe. Survives app restarts.
///
/// Stores: audio toggles, player names (4 slots: solo X/O, duo X/O), theme and
/// marker-style choices, bot difficulty, starter alternation, per-mode scores,
/// and the in-progress game snapshot (RULES.md §12: backgrounded mid-game
/// restores exactly).
class NordicSettings extends ChangeNotifier {
  static const _kMusic = 'ttt_music_on';
  static const _kSfx = 'ttt_sfx_on';
  static const _kVolume = 'ttt_volume';
  static const _kDifficulty = 'ttt_bot_difficulty'; // 0 easy, 1 normal, 2 hard
  static const _kTheme = 'ttt_theme_id';
  static const _kMarker = 'ttt_marker_style'; // MarkerStyle index
  static const _kSwapStarter = 'ttt_swap_starter';
  static const _kNames = 'ttt_player_names'; // StringList, 4 entries
  static const _kSoloX = 'ttt_solo_x';
  static const _kSoloO = 'ttt_solo_o';
  static const _kSoloD = 'ttt_solo_d';
  static const _kDuoX = 'ttt_duo_x';
  static const _kDuoO = 'ttt_duo_o';
  static const _kDuoD = 'ttt_duo_d';
  static const _kSavedGame = 'ttt_saved_game';

  /// Slots: 0 = solo X, 1 = solo O, 2 = duo X, 3 = duo O.
  static const defaultNames = ['You', 'Bot', 'Player 1', 'Player 2'];

  bool musicOn = true;
  bool sfxOn = true;
  double volume = 0.8;
  BotDifficulty difficulty = BotDifficulty.hard;
  String themeId = 'classic';
  int markerStyle = 0;
  bool swapStarter = false;
  List<String> playerNames = List.of(defaultNames);
  int soloX = 0, soloO = 0, soloDraws = 0;
  int duoX = 0, duoO = 0, duoDraws = 0;

  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    musicOn = p.getBool(_kMusic) ?? true;
    sfxOn = p.getBool(_kSfx) ?? true;
    volume = p.getDouble(_kVolume) ?? 0.8;
    difficulty =
        BotDifficulty.values[(p.getInt(_kDifficulty) ?? 2).clamp(0, 2)];
    themeId = p.getString(_kTheme) ?? 'classic';
    markerStyle = (p.getInt(_kMarker) ?? 0).clamp(0, 5);
    swapStarter = p.getBool(_kSwapStarter) ?? false;
    final names = p.getStringList(_kNames);
    if (names != null && names.length == 4) {
      playerNames = [
        for (int i = 0; i < 4; i++)
          names[i].trim().isEmpty ? defaultNames[i] : names[i].trim()
      ];
    }
    soloX = p.getInt(_kSoloX) ?? 0;
    soloO = p.getInt(_kSoloO) ?? 0;
    soloDraws = p.getInt(_kSoloD) ?? 0;
    duoX = p.getInt(_kDuoX) ?? 0;
    duoO = p.getInt(_kDuoO) ?? 0;
    duoDraws = p.getInt(_kDuoD) ?? 0;
    notifyListeners();
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    await p.setBool(_kMusic, musicOn);
    await p.setBool(_kSfx, sfxOn);
    await p.setDouble(_kVolume, volume);
    await p.setInt(_kDifficulty, difficulty.index);
    await p.setString(_kTheme, themeId);
    await p.setInt(_kMarker, markerStyle);
    await p.setBool(_kSwapStarter, swapStarter);
    await p.setStringList(_kNames, playerNames);
    await p.setInt(_kSoloX, soloX);
    await p.setInt(_kSoloO, soloO);
    await p.setInt(_kSoloD, soloDraws);
    await p.setInt(_kDuoX, duoX);
    await p.setInt(_kDuoO, duoO);
    await p.setInt(_kDuoD, duoDraws);
  }

  Future<void> setMusic(bool v) async {
    musicOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setSfx(bool v) async {
    sfxOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0);
    notifyListeners();
    await _save();
  }

  Future<void> setDifficulty(BotDifficulty d) async {
    difficulty = d;
    notifyListeners();
    await _save();
  }

  Future<void> setTheme(String id) async {
    themeId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setMarkerStyle(int v) async {
    markerStyle = v.clamp(0, 5);
    notifyListeners();
    await _save();
  }

  Future<void> setSwapStarter(bool v) async {
    swapStarter = v;
    notifyListeners();
    await _save();
  }

  Future<void> setPlayerName(int slot, String name) async {
    if (slot < 0 || slot > 3) return;
    final clean = name.trim();
    playerNames[slot] = clean.isEmpty ? defaultNames[slot] : clean;
    notifyListeners();
    await _save();
  }

  /// Record a finished game. [winnerMark]: 0 = X, 1 = O, null = draw.
  Future<void> recordGame({required bool vsBot, required int? winnerMark}) async {
    if (vsBot) {
      if (winnerMark == 0) {
        soloX++;
      } else if (winnerMark == 1) {
        soloO++;
      } else {
        soloDraws++;
      }
    } else {
      if (winnerMark == 0) {
        duoX++;
      } else if (winnerMark == 1) {
        duoO++;
      } else {
        duoDraws++;
      }
    }
    notifyListeners();
    await _save();
  }

  Future<void> resetScores() async {
    soloX = soloO = soloDraws = duoX = duoO = duoDraws = 0;
    notifyListeners();
    await _save();
  }

  // ------------------------------------------------- saved game snapshot
  /// Persist the in-progress game so backgrounding restores it exactly
  /// (RULES.md §12).
  Future<void> saveGame(Map<String, Object?> snapshot) async {
    final p = _prefs;
    if (p == null) return;
    await p.setString(_kSavedGame, jsonEncode(snapshot));
  }

  Map<String, Object?>? loadGame() {
    final raw = _prefs?.getString(_kSavedGame);
    if (raw == null || raw.isEmpty) return null;
    try {
      final m = jsonDecode(raw);
      if (m is Map<String, Object?>) return m;
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearSavedGame() async {
    await _prefs?.remove(_kSavedGame);
  }
}
