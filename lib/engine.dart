import 'dart:math';

/// Tic Tac Toe engine — deterministic rules per RULES.md.
/// Cells: 0-8 left-to-right, top-to-bottom. Marks: 0 = X, 1 = O, -1 = empty.
class TttEngine {
  static const lines = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8],
    [0, 3, 6], [1, 4, 7], [2, 5, 8],
    [0, 4, 8], [2, 4, 6],
  ];

  /// Returns the winning line, or null.
  static List<int>? findWin(List<int> cells) {
    for (final l in lines) {
      if (cells[l[0]] != -1 &&
          cells[l[0]] == cells[l[1]] &&
          cells[l[1]] == cells[l[2]]) {
        return l;
      }
    }
    return null;
  }

  static bool get isDraw {
    return false; // instance-free helper below
  }

  static bool isDrawBoard(List<int> cells) =>
      !cells.contains(-1) && findWin(cells) == null;

  static List<int> empties(List<int> cells) =>
      [for (var i = 0; i < 9; i++) if (cells[i] == -1) i];
}

/// Difficulty per RULES.md §11.
enum BotDifficulty { easy, normal, hard }

/// Minimax bot with alpha-beta pruning. Never loses on hard.
class TttBot {
  final BotDifficulty difficulty;
  final Random _rng = Random();

  TttBot(this.difficulty);

  /// Returns the cell index for the bot (mark [botMark]) to play.
  int choose(List<int> cells, int botMark) {
    final foe = 1 - botMark;
    // Difficulty jitter: occasionally play randomly.
    final jitter = switch (difficulty) {
      BotDifficulty.easy => 0.40,
      BotDifficulty.normal => 0.15,
      BotDifficulty.hard => 0.0,
    };
    if (jitter > 0 && _rng.nextDouble() < jitter) {
      final e = TttEngine.empties(cells);
      return e[_rng.nextInt(e.length)];
    }
    var best = -1;
    var bestScore = -1000;
    for (final i in _orderedMoves(cells)) {
      cells[i] = botMark;
      final score = _minimax(cells, false, botMark, foe, -1000, 1000, 0);
      cells[i] = -1;
      if (score > bestScore) {
        bestScore = score;
        best = i;
      }
    }
    return best;
  }

  /// Move ordering for alpha-beta: center, corners, sides.
  List<int> _orderedMoves(List<int> cells) {
    const order = [4, 0, 2, 6, 8, 1, 3, 5, 7];
    return [for (final i in order) if (cells[i] == -1) i];
  }

  int _minimax(List<int> cells, bool maximizing, int bot, int foe,
      int alpha, int beta, int depth) {
    final win = TttEngine.findWin(cells);
    if (win != null) {
      return cells[win[0]] == bot ? 10 - depth : depth - 10;
    }
    if (!cells.contains(-1)) return 0;

    if (maximizing) {
      var best = -1000;
      for (final i in _orderedMoves(cells)) {
        cells[i] = bot;
        best = max(best, _minimax(cells, false, bot, foe, alpha, beta, depth + 1));
        cells[i] = -1;
        alpha = max(alpha, best);
        if (beta <= alpha) break;
      }
      return best;
    } else {
      var best = 1000;
      for (final i in _orderedMoves(cells)) {
        cells[i] = foe;
        best = min(best, _minimax(cells, true, bot, foe, alpha, beta, depth + 1));
        cells[i] = -1;
        beta = min(beta, best);
        if (beta <= alpha) break;
      }
      return best;
    }
  }
}
