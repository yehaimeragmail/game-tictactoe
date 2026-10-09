import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:tictactoe/engine/ttt_engine.dart';

/// RULES.md §13 test cases + regression tests for the exemplar upgrade.
///
/// The engine owns its turn timers; async tests drive the public API and wait
/// out the (short, injected) phase durations. Pure-logic tests (bot, rules)
/// run synchronously.
TttEngine makeEngine({
  bool vsBot = false,
  BotDifficulty difficulty = BotDifficulty.hard,
  bool swapStarter = false,
  int? lastLoserMark,
  bool watchdog = false,
}) {
  return TttEngine(
    players: [
      TttPlayer(name: 'X', isBot: false),
      TttPlayer(name: 'O', isBot: vsBot),
    ],
    botDifficulty: difficulty,
    vsBot: vsBot,
    swapStarter: swapStarter,
    lastLoserMark: lastLoserMark,
    thinkDelay: const Duration(milliseconds: 10),
    settleDelay: const Duration(milliseconds: 10),
    enableWatchdog: watchdog,
  );
}

Future<void> settle(TttEngine e) =>
    Future.delayed(const Duration(milliseconds: 60));

void main() {
  test('1. X wins top row: X0 O3 X1 O4 X2 → X wins, line (0,1,2)', () async {
    final e = makeEngine();
    addTearDown(e.dispose);
    for (final m in [0, 3, 1, 4, 2]) {
      e.tapCell(m);
      await settle(e);
    }
    expect(e.over, isTrue);
    expect(e.winnerMark, 0);
    expect(e.winLine, [0, 1, 2]);
    expect(e.phase, TttPhase.over);
  });

  test('2. O wins diagonal: X0 O2 X1 O4 X3 O6 → O wins (2,4,6)', () async {
    final e = makeEngine();
    addTearDown(e.dispose);
    for (final m in [0, 2, 1, 4, 3, 6]) {
      e.tapCell(m);
      await settle(e);
    }
    expect(e.over, isTrue);
    expect(e.winnerMark, 1);
    expect(e.winLine, [2, 4, 6]);
  });

  test('3. Draw: X0 O1 X2 O4 X3 O5 X7 O6 X8 → draw, no winner', () async {
    final e = makeEngine();
    addTearDown(e.dispose);
    for (final m in [0, 1, 2, 4, 3, 5, 7, 6, 8]) {
      e.tapCell(m);
      await settle(e);
    }
    expect(e.over, isTrue);
    expect(e.winnerMark, isNull);
    expect(e.winLine, isNull);
  });

  test('4. Illegal move: X0 then X tries 0 again → rejected, board unchanged',
      () async {
    final e = makeEngine();
    addTearDown(e.dispose);
    var invalids = 0;
    e.onEvent = (ev) {
      if (ev == TttEvent.invalid) invalids++;
    };
    e.tapCell(0);
    await settle(e);
    final before = List.of(e.cells);
    e.tapCell(0); // occupied
    expect(e.cells, before);
    expect(e.turn, 1); // turn did not advance
    expect(invalids, 1);
    expect(e.invalidCell, 0);
  });

  test('5. Bot blocks: X0 O4 X1 → bot (O) must play 2', () {
    final bot = TttBot(BotDifficulty.hard);
    final cells = List.filled(9, -1);
    cells[0] = 0;
    cells[4] = 1;
    cells[1] = 0;
    expect(bot.choose(cells, 1), 2);
  });

  test('6. Bot wins: O has 0,1 and X plays 4 → bot (O) must play 2', () {
    final bot = TttBot(BotDifficulty.hard);
    final cells = List.filled(9, -1);
    cells[0] = 1;
    cells[1] = 1;
    cells[4] = 0;
    expect(bot.choose(cells, 1), 2);
  });

  test('7. Hard bot never loses: 50 random games vs hard → 0 bot losses', () {
    // Bot plays O (second). Pure synchronous simulation.
    var losses = 0;
    final rng = Random(42);
    for (int g = 0; g < 50; g++) {
      final cells = List.filled(9, -1);
      final bot = TttBot(BotDifficulty.hard, rng: rng);
      var turn = 0;
      while (true) {
        final win = TttRules.findWin(cells);
        if (win != null) {
          if (cells[win[0]] == 0) losses++; // human (X) beat the bot
          break;
        }
        if (TttRules.isDraw(cells)) break;
        if (turn == 0) {
          final empt = TttRules.empties(cells);
          cells[empt[rng.nextInt(empt.length)]] = 0;
        } else {
          cells[bot.choose(cells, 1)] = 1;
        }
        turn = 1 - turn;
      }
    }
    expect(losses, 0);
  });

  test('8. Game-over lock: after win, taps do nothing', () async {
    final e = makeEngine();
    addTearDown(e.dispose);
    for (final m in [0, 3, 1, 4, 2]) {
      e.tapCell(m);
      await settle(e);
    }
    final before = List.of(e.cells);
    e.tapCell(5);
    e.tapCell(6);
    expect(e.cells, before);
    expect(e.phase, TttPhase.over);
  });

  test('10. Turn indicator: banner shows the correct next player', () async {
    final e = makeEngine();
    addTearDown(e.dispose);
    expect(e.banner, contains('X'));
    e.tapCell(0);
    await settle(e);
    expect(e.banner, contains('O'));
    expect(e.turn, 1);
  });

  test('Bot thinking: taps locked during bot turn, bot move lands', () async {
    final e = makeEngine(vsBot: true);
    addTearDown(e.dispose);
    e.tapCell(0); // human X
    await Future.delayed(const Duration(milliseconds: 30));
    e.tapCell(4); // attempt during bot's turn — must be ignored
    await Future.delayed(const Duration(milliseconds: 400));
    // O placed exactly one mark and the turn came back to the human.
    expect(e.cells.where((c) => c == 1).length, 1);
    expect(e.cells[0], 0);
    expect(e.over, isFalse);
    expect(e.turn, 0);
    expect(e.phase, TttPhase.awaitingMove);
  });

  test('Watchdog recovers a dead thinking phase', () async {
    final e = makeEngine(vsBot: true, watchdog: true);
    addTearDown(e.dispose);
    // Simulate: bot's turn, stuck in thinking with no live timer.
    e.turn = 1;
    e.phase = TttPhase.thinking;
    await Future.delayed(const Duration(seconds: 3));
    // Watchdog must have driven the game forward: the bot moved.
    expect(e.cells.where((c) => c == 1).length, 1);
  });

  test('Pause freezes and resume recovers the turn', () async {
    final e = makeEngine();
    addTearDown(e.dispose);
    e.tapCell(0); // animating phase with a live timer
    e.setPaused(true);
    expect(e.phase, TttPhase.animating);
    await Future.delayed(const Duration(milliseconds: 80));
    expect(e.phase, TttPhase.animating); // frozen, not settled
    expect(e.turn, 0);
    e.setPaused(false);
    await Future.delayed(const Duration(milliseconds: 80));
    expect(e.turn, 1); // recovered: settled to next turn
  });

  test('Starter alternation: loser starts next round when enabled', () async {
    final e = makeEngine(swapStarter: true);
    addTearDown(e.dispose);
    // X wins: X0 O3 X1 O4 X2. Loser is O (mark 1).
    for (final m in [0, 3, 1, 4, 2]) {
      e.tapCell(m);
      await settle(e);
    }
    expect(e.winnerMark, 0);
    expect(e.lastLoserMark, 1);
    e.restart();
    expect(e.turn, 1); // loser (O) starts
    expect(e.over, isFalse);
    expect(e.cells.every((c) => c == -1), isTrue);
  });

  test('Starter default: X starts when alternation is off', () async {
    final e = makeEngine();
    addTearDown(e.dispose);
    for (final m in [0, 3, 1, 4, 2]) {
      e.tapCell(m);
      await settle(e);
    }
    e.restart();
    expect(e.turn, 0);
  });

  test('vsBot: human (X) always starts', () {
    final e = makeEngine(vsBot: true, swapStarter: true, lastLoserMark: 1);
    addTearDown(e.dispose);
    expect(e.turn, 0);
    expect(e.players[1].isBot, isTrue);
  });

  test('Snapshot/restore round-trips a mid-game exactly', () async {
    final e = makeEngine();
    addTearDown(e.dispose);
    e.tapCell(0);
    await settle(e);
    e.tapCell(4);
    await settle(e);
    final snap = e.snapshot();
    final e2 = makeEngine();
    addTearDown(e2.dispose);
    expect(e2.restore(snap), isTrue);
    expect(e2.cells, e.cells);
    expect(e2.turn, e.turn);
    expect(e2.phase, TttPhase.awaitingMove);
  });

  test('Restore rejects garbage', () {
    final e = makeEngine();
    addTearDown(e.dispose);
    expect(e.restore({'cells': 'nope', 'turn': 0, 'vsBot': false}), isFalse);
    expect(e.restore({'cells': '0,0,0', 'turn': 0, 'vsBot': false}), isFalse);
  });

  test('Bot completes its turn and the game proceeds', () async {
    final e = makeEngine(vsBot: true);
    addTearDown(e.dispose);
    e.tapCell(4); // human X takes center
    // Bot acts after thinkDelay + jitter (up to ~360ms in tests); poll for
    // the move instead of assuming a fixed delay (was flaky at 200ms).
    final deadline = DateTime.now().add(const Duration(seconds: 3));
    while (e.cells.where((c) => c == 1).isEmpty &&
        DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(milliseconds: 25));
    }
    expect(e.cells.where((c) => c == 1).length, 1);
    expect(e.over || e.turn == 0 || e.phase == TttPhase.awaitingMove, isTrue);
  });
}

