import 'package:shared_preferences/shared_preferences.dart';
import 'engine.dart';

/// Session score persistence per RULES.md §8.
/// Scores persist locally per mode (solo vs 2-player).
class ScoreStore {
  ScoreStore._();
  static final ScoreStore I = ScoreStore._();

  int soloX = 0, soloO = 0, soloDraws = 0;
  int p1Wins = 0, p2Wins = 0, duoDraws = 0;
  BotDifficulty difficulty = BotDifficulty.hard;
  bool swapStarter = false;

  static const _p = 'score_';

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    soloX = p.getInt('${_p}solo_x') ?? 0;
    soloO = p.getInt('${_p}solo_o') ?? 0;
    soloDraws = p.getInt('${_p}solo_draws') ?? 0;
    p1Wins = p.getInt('${_p}p1') ?? 0;
    p2Wins = p.getInt('${_p}p2') ?? 0;
    duoDraws = p.getInt('${_p}duo_draws') ?? 0;
    difficulty = BotDifficulty.values[p.getInt('${_p}difficulty') ?? 2];
    swapStarter = p.getBool('${_p}swap_starter') ?? false;
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('${_p}solo_x', soloX);
    await p.setInt('${_p}solo_o', soloO);
    await p.setInt('${_p}solo_draws', soloDraws);
    await p.setInt('${_p}p1', p1Wins);
    await p.setInt('${_p}p2', p2Wins);
    await p.setInt('${_p}duo_draws', duoDraws);
    await p.setInt('${_p}difficulty', difficulty.index);
    await p.setBool('${_p}swap_starter', swapStarter);
  }

  Future<void> recordSolo(int? winnerMark) async {
    if (winnerMark == 0) {
      soloX++;
    } else if (winnerMark == 1) {
      soloO++;
    } else {
      soloDraws++;
    }
    await _save();
  }

  Future<void> recordDuo(int? winnerMark) async {
    if (winnerMark == 0) {
      p1Wins++;
    } else if (winnerMark == 1) {
      p2Wins++;
    } else {
      duoDraws++;
    }
    await _save();
  }

  Future<void> setDifficulty(BotDifficulty d) async {
    difficulty = d;
    await _save();
  }

  Future<void> setSwapStarter(bool v) async {
    swapStarter = v;
    await _save();
  }

  Future<void> reset() async {
    soloX = soloO = soloDraws = p1Wins = p2Wins = duoDraws = 0;
    await _save();
  }
}
