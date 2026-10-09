import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Rules (RULES.md §§1-10): pure, deterministic, UI-agnostic.
// Cells: 0-8 left-to-right, top-to-bottom. Marks: 0 = X, 1 = O, -1 = empty.
// ---------------------------------------------------------------------------
class TttRules {
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

  static bool isDraw(List<int> cells) =>
      !cells.contains(-1) && findWin(cells) == null;

  static List<int> empties(List<int> cells) =>
      [for (var i = 0; i < 9; i++) if (cells[i] == -1) i];
}

/// Difficulty per RULES.md §11.
enum BotDifficulty { easy, normal, hard }

/// Minimax bot with alpha-beta pruning. Plays optimally on hard (never loses).
class TttBot {
  final BotDifficulty difficulty;
  final Random _rng;

  TttBot(this.difficulty, {Random? rng}) : _rng = rng ?? Random();

  /// Returns the cell index for the bot (mark [botMark]) to play.
  /// Synchronous — on 3x3 it completes in well under 1ms; the UI's
  /// "thinking" delay is purely presentational.
  int choose(List<int> cells, int botMark) {
    final foe = 1 - botMark;
    // Difficulty jitter: occasionally play randomly (RULES.md §11).
    final jitter = switch (difficulty) {
      BotDifficulty.easy => 0.40,
      BotDifficulty.normal => 0.15,
      BotDifficulty.hard => 0.0,
    };
    final empties = TttRules.empties(cells);
    if (empties.isEmpty) return -1;
    if (jitter > 0 && _rng.nextDouble() < jitter) {
      return empties[_rng.nextInt(empties.length)];
    }
    var best = empties.first;
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
    final win = TttRules.findWin(cells);
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

// ---------------------------------------------------------------------------
// Players / phases / events
// ---------------------------------------------------------------------------
class TttPlayer {
  String name;
  final bool isBot;
  TttPlayer({required this.name, required this.isBot});
}

/// Turn phases owned entirely by the engine. The UI only renders.
enum TttPhase { awaitingMove, thinking, animating, over }

enum TttEvent {
  placeX,
  placeO,
  invalid,
  gameStart,
  win,
  draw,
  lose,
  thinking,
}

// ---------------------------------------------------------------------------
// Engine: deterministic rules, state, bot AI. UI-agnostic.
// ---------------------------------------------------------------------------
class TttEngine extends ChangeNotifier {
  final List<TttPlayer> players; // [X, O]
  final BotDifficulty botDifficulty;
  final bool vsBot;
  final bool swapStarter;
  final Duration thinkDelay;
  final Duration settleDelay;
  final bool enableWatchdog;

  List<int> cells = List.filled(9, -1);
  int turn = 0; // 0 = X, 1 = O
  TttPhase phase = TttPhase.awaitingMove;
  List<int>? winLine;
  bool over = false;
  int? winnerMark; // 0 = X, 1 = O, null = draw
  int? lastLoserMark; // for starter alternation (RULES.md §12)
  String banner = '';

  /// Illegal-move feedback: cell + sequence the UI watches to play the shake.
  int invalidCell = -1;
  int invalidSeq = 0;

  /// Placement animation: cell + sequence the UI watches to pop the piece.
  int lastMoveCell = -1;
  int lastMoveSeq = 0;

  Timer? _timer; // single phase-transition timer
  Timer? _watchdog; // stuck-state recovery
  bool _disposed = false;
  bool paused = false;
  final _rand = Random();

  /// UI hook for sounds / haptics. Set by the screen.
  void Function(TttEvent event)? onEvent;

  TttEngine({
    required this.players,
    this.botDifficulty = BotDifficulty.hard,
    this.vsBot = true,
    this.swapStarter = false,
    this.thinkDelay = const Duration(milliseconds: 800),
    this.settleDelay = const Duration(milliseconds: 380),
    this.enableWatchdog = true,
    this.lastLoserMark,
  }) {
    _restart(silent: true);
    if (enableWatchdog) {
      _watchdog = Timer.periodic(const Duration(seconds: 2), (_) => _recover());
    }
    _afterTurn();
  }

  TttPlayer get current => players[turn];
  bool get awaitingHuman =>
      phase == TttPhase.awaitingMove && !current.isBot && !over;

  int get _starter {
    if (vsBot) return 0; // RULES.md §2: human is X, X moves first.
    if (swapStarter && lastLoserMark != null) return lastLoserMark!;
    return 0;
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _watchdog?.cancel();
    super.dispose();
  }

  void _arm(Duration d, void Function() fn) {
    if (_disposed || paused) return;
    _timer?.cancel();
    _timer = Timer(d, () {
      _timer = null;
      if (!_disposed && !paused) fn();
    });
  }

  /// Pause: freeze the phase timer. Resume re-arms the current phase.
  void setPaused(bool v) {
    if (paused == v || _disposed) return;
    paused = v;
    if (v) {
      _timer?.cancel();
      _timer = null;
    } else {
      _recover();
    }
    notifyListeners();
  }

  /// Watchdog: if the single phase timer ever dies without progress, recover.
  /// This makes stuck states impossible by construction. Respects [paused].
  /// A human's [awaitingMove] is never "stuck" — waiting on the player is a
  /// legal state.
  void _recover() {
    if (_disposed || over || paused || _timer != null) return;
    if (phase == TttPhase.thinking && current.isBot) {
      // Thinking with no live timer: re-arm the bot act directly.
      final jitter = Duration(milliseconds: _rand.nextInt(350));
      _arm(thinkDelay + jitter, _botAct);
    } else if (phase == TttPhase.animating) {
      _settle();
    } else if (phase == TttPhase.awaitingMove && current.isBot) {
      _beginThinking();
    }
  }

  // ------------------------------------------------------------- turn flow
  /// Human taps a cell. Guarded: correct phase, human side, empty cell.
  /// Illegal moves are rejected with feedback; the board never changes.
  void tapCell(int i) {
    if (over || phase != TttPhase.awaitingMove || current.isBot) return;
    if (i < 0 || i > 8 || cells[i] != -1) {
      _flagInvalid(i);
      return;
    }
    _place(i);
  }

  void _flagInvalid(int i) {
    invalidCell = i.clamp(0, 8);
    invalidSeq++;
    onEvent?.call(TttEvent.invalid);
    notifyListeners();
  }

  void _place(int i) {
    cells[i] = turn;
    lastMoveCell = i;
    lastMoveSeq++;
    phase = TttPhase.animating;
    onEvent?.call(turn == 0 ? TttEvent.placeX : TttEvent.placeO);
    notifyListeners();
    _arm(settleDelay, _settle);
  }

  /// Engine-owned settle — the UI never calls this. No desync possible.
  void _settle() {
    if (over || phase != TttPhase.animating) return;
    final win = TttRules.findWin(cells);
    if (win != null) {
      _finish(cells[win[0]], win);
      return;
    }
    if (TttRules.isDraw(cells)) {
      _finish(null, null);
      return;
    }
    turn = 1 - turn;
    phase = TttPhase.awaitingMove;
    _updateBanner();
    notifyListeners();
    _afterTurn();
  }

  void _beginThinking() {
    if (over || phase != TttPhase.awaitingMove || !current.isBot) return;
    phase = TttPhase.thinking;
    banner = '${current.name} is thinking…';
    onEvent?.call(TttEvent.thinking);
    notifyListeners();
    // Slight human-like variance so the bot never feels instant.
    final jitter = Duration(milliseconds: _rand.nextInt(350));
    _arm(thinkDelay + jitter, _botAct);
  }

  void _botAct() {
    if (over || phase != TttPhase.thinking || !current.isBot) return;
    final bot = TttBot(botDifficulty);
    final cell = bot.choose(List.of(cells), turn);
    if (cell < 0) {
      // No legal move (should be unreachable — draw is detected at settle).
      _finish(null, null);
      return;
    }
    _place(cell);
  }

  /// Called whenever we enter awaitingMove: bots think for themselves.
  void _afterTurn() {
    if (over || phase != TttPhase.awaitingMove) return;
    _updateBanner();
    if (current.isBot) {
      _beginThinking();
    }
  }

  void _updateBanner() {
    if (over) return;
    if (current.isBot) {
      banner = '${current.name} is thinking…';
    } else {
      banner = '${current.name}\u2019s move';
    }
  }

  void _finish(int? winner, List<int>? line) {
    over = true;
    phase = TttPhase.over;
    winnerMark = winner;
    winLine = line;
    lastLoserMark = winner == null ? null : 1 - winner;
    if (winner == null) {
      banner = 'Stalemate';
      onEvent?.call(TttEvent.draw);
    } else {
      banner = '${players[winner].name} wins!';
      onEvent?.call(
          vsBot && winner == 1 ? TttEvent.lose : TttEvent.win);
    }
    notifyListeners();
  }

  void _restart({bool silent = false}) {
    _timer?.cancel();
    paused = false;
    cells = List.filled(9, -1);
    turn = _starter;
    phase = TttPhase.awaitingMove;
    winLine = null;
    over = false;
    winnerMark = null;
    invalidCell = -1;
    lastMoveCell = -1;
    _updateBanner();
    if (!silent) {
      onEvent?.call(TttEvent.gameStart);
      notifyListeners();
      _afterTurn();
    }
  }

  /// New round. Starter alternation per RULES.md §12.
  void restart() => _restart();

  // ------------------------------------------------------- persistence
  Map<String, Object?> snapshot() => {
        'cells': cells.join(','),
        'turn': turn,
        'vsBot': vsBot,
        'over': over,
        'winnerMark': winnerMark,
        'winLine': winLine?.join(','),
        'lastLoserMark': lastLoserMark,
      };

  /// Restore a mid-game snapshot (RULES.md §12). Returns false if invalid.
  bool restore(Map<String, Object?> m) {
    try {
      final rawCells = (m['cells'] as String).split(',').map(int.parse).toList();
      if (rawCells.length != 9 ||
          rawCells.any((c) => c < -1 || c > 1)) {
        return false;
      }
      if (m['vsBot'] != vsBot) return false;
      _timer?.cancel();
      cells = rawCells;
      turn = (m['turn'] as int).clamp(0, 1);
      over = (m['over'] as bool?) ?? false;
      winnerMark = m['winnerMark'] as int?;
      final wl = m['winLine'] as String?;
      winLine = wl == null || wl.isEmpty
          ? null
          : wl.split(',').map(int.parse).toList();
      lastLoserMark = m['lastLoserMark'] as int?;
      phase = over ? TttPhase.over : TttPhase.awaitingMove;
      _updateBanner();
      notifyListeners();
      _afterTurn();
      return true;
    } catch (_) {
      return false;
    }
  }
}
