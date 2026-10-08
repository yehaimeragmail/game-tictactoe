import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

/// Tic Tac Toe - the reference implementation all other games follow.
class TicTacToeScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;

  const TicTacToeScreen({super.key, required this.players, required this.callbacks});

  @override
  State<TicTacToeScreen> createState() => _TicTacToeScreenState();
}

class _TicTacToeScreenState extends State<TicTacToeScreen> {
  late List<int> cells; // -1 empty, else player index
  int turn = 0;
  List<int>? winLine;
  bool over = false;

  static const _lines = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8],
    [0, 3, 6], [1, 4, 7], [2, 5, 8],
    [0, 4, 8], [2, 4, 6],
  ];

  @override
  void initState() {
    super.initState();
    _reset();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeBotMove());
  }

  void _reset() {
    cells = List.filled(9, -1);
    turn = 0;
    winLine = null;
    over = false;
    widget.callbacks.setActivePlayer(0);
  }

  void _tap(int i) {
    if (over || cells[i] != -1 || widget.players[turn].isBot) return;
    _place(i);
  }

  void _place(int i) {
    setState(() => cells[i] = turn);
    Sfx.tap();
    final w = _findWin();
    if (w != null) {
      _endGame(winnerLine: w);
      return;
    }
    if (!cells.contains(-1)) {
      _endGame(draw: true);
      return;
    }
    setState(() => turn = (turn + 1) % widget.players.length);
    widget.callbacks.setActivePlayer(turn);
    _maybeBotMove();
  }

  void _maybeBotMove() {
    if (over || !widget.players[turn].isBot) return;
    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted || over) return;
      _place(_botChoice());
    });
  }

  /// Smart-ish bot: win > block > center > corner > random (with mistakes).
  int _botChoice() {
    final me = turn;
    final foe = (turn + 1) % widget.players.length;
    final empties = [for (int i = 0; i < 9; i++) if (cells[i] == -1) i];
    int? lineWin(List<int> b, int p) {
      for (final l in _lines) {
        final vals = l.map((i) => b[i]).toList();
        if (vals.where((v) => v == p).length == 2 && vals.contains(-1)) {
          return l[vals.indexOf(-1)];
        }
      }
      return null;
    }
    return lineWin(cells, me) ??
        lineWin(cells, foe) ??
        (cells[4] == -1 ? 4 : null) ??
        ([0, 2, 6, 8]..shuffle()).firstWhere((i) => cells[i] == -1, orElse: () => -1).let((c) => c == -1 ? (empties..shuffle()).first : c);
  }

  List<int>? _findWin() {
    for (final l in _lines) {
      if (cells[l[0]] != -1 && cells[l[0]] == cells[l[1]] && cells[l[1]] == cells[l[2]]) return l;
    }
    return null;
  }

  void _endGame({List<int>? winnerLine, bool draw = false}) {
    setState(() {
      over = true;
      winLine = winnerLine;
    });
    if (draw) {
      Sfx.lose();
      widget.callbacks.finish(headline: "It's a draw! 🤝", subline: 'Nobody blinks. Rematch?');
    } else {
      final w = widget.players[cells[winnerLine![0]]];
      w.score += 1;
      widget.callbacks.refreshHud();
      widget.callbacks.finish(winner: w, headline: '${w.name} wins! 🎉');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeController.of(context).theme;
    final current = widget.players[turn];
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (!over)
            TurnBanner(player: current, action: current.isBot ? ' is thinking… 🤖' : ', your move! 👆'),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: t.surface,
                    borderRadius: t.radius,
                    boxShadow: [BoxShadow(color: t.primary.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 10))],
                  ),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10),
                    itemCount: 9,
                    itemBuilder: (_, i) => _cell(i, t),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('First to a line of 3 wins the round 🏆',
              style: TextStyle(color: t.muted, fontSize: 13)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _cell(int i, GameTheme t) {
    final v = cells[i];
    final inWin = winLine?.contains(i) ?? false;
    return GestureDetector(
      onTap: () => _tap(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: inWin ? widget.players[v].color.withValues(alpha: 0.35) : t.background,
          borderRadius: t.radius,
          border: Border.all(
            color: inWin ? widget.players[v].color : t.primary.withValues(alpha: 0.25),
            width: inWin ? 3 : 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: v == -1
            ? const SizedBox.shrink()
            : TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.4, end: 1.0),
                duration: const Duration(milliseconds: 220),
                curve: Curves.elasticOut,
                builder: (_, s, _) => Transform.scale(
                  scale: s,
                  child: Text(
                    v == 0 ? '✕' : '◯',
                    style: TextStyle(
                      fontSize: 54,
                      fontWeight: FontWeight.w900,
                      color: widget.players[v].color,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

extension _Let<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
