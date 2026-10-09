import 'package:flutter/material.dart';
import '../design.dart';
import '../engine.dart';
import '../audio.dart';
import '../scores.dart';
import '../widgets/nordic.dart';
import 'settings_screen.dart';

/// Game screen — light oak board, ceramic pieces, soft Nordic daylight.
class GameScreen extends StatefulWidget {
  final bool vsBot;

  const GameScreen({super.key, required this.vsBot});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  List<int> _cells = List.filled(9, -1);
  int _turn = 0; // 0 = X, 1 = O
  List<int>? _winLine;
  bool _over = false;
  bool _paused = false;
  int _starter = 0;

  // Shake animation for illegal moves
  late final AnimationController _shake;
  int _shakeCell = -1;

  // Piece placement animation keys
  final Map<int, DateTime> _placedAt = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _shake = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320));
    _starter = (ScoreStore.I.swapStarter ? 1 : 0);
    _turn = _starter;
    Sound.I.gameStart();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _maybeBotMove());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _shake.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause on background (RULES.md §12: state saved; restored exactly)
    if (state == AppLifecycleState.paused && !_over) {
      setState(() => _paused = true);
      Sound.I.stopMusic();
    } else if (state == AppLifecycleState.resumed && _paused) {
      Sound.I.gameMusic();
    }
  }

  String get _turnLabel {
    if (_over) return 'Game over';
    if (widget.vsBot) {
      return _turn == 0 ? 'Your move' : 'Bot is thinking';
    }
    return _turn == 0 ? "Player 1's move" : "Player 2's move";
  }

  void _tap(int i) {
    if (_over || _paused) return;
    if (_cells[i] != -1) {
      // Illegal move: gentle shake + knock (RULES.md §5)
      setState(() => _shakeCell = i);
      _shake.forward(from: 0);
      Sound.I.invalid();
      Future.delayed(const Duration(milliseconds: 350),
          () => mounted ? setState(() => _shakeCell = -1) : null);
      return;
    }
    if (widget.vsBot && _turn == 1) return; // bot's turn locked
    _place(i);
  }

  void _place(int i) {
    setState(() {
      _cells[i] = _turn;
      _placedAt[i] = DateTime.now();
    });
    if (_turn == 0) {
      Sound.I.placeX();
    } else {
      Sound.I.placeO();
    }

    final win = TttEngine.findWin(_cells);
    if (win != null) {
      _endGame(win);
      return;
    }
    if (TttEngine.isDrawBoard(_cells)) {
      _endGame(null);
      return;
    }
    setState(() => _turn = 1 - _turn);
    _maybeBotMove();
  }

  void _maybeBotMove() {
    if (!widget.vsBot || _over || _paused || _turn != 1) return;
    Future.delayed(const Duration(milliseconds: 550), () {
      if (!mounted || _over || _paused) return;
      final bot = TttBot(ScoreStore.I.difficulty);
      final move = bot.choose(List.of(_cells), 1);
      _place(move);
    });
  }

  void _endGame(List<int>? winLine) {
    setState(() {
      _over = true;
      _winLine = winLine;
    });
    final winnerMark = winLine == null ? null : _cells[winLine[0]];
    if (widget.vsBot) {
      ScoreStore.I.recordSolo(winnerMark);
    } else {
      ScoreStore.I.recordDuo(winnerMark);
    }
    if (winnerMark == null) {
      Sound.I.draw();
    } else {
      Sound.I.win();
    }
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) _showGameOver(winnerMark);
    });
  }

  void _showGameOver(int? winnerMark) {
    final title = winnerMark == null
        ? 'Stalemate'
        : widget.vsBot
            ? (winnerMark == 0 ? 'Quiet Victory' : 'Bot Prevails')
            : (winnerMark == 0 ? 'Player 1 Wins' : 'Player 2 Wins');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _GameOverDialog(
        title: title,
        isDraw: winnerMark == null,
        onAgain: () {
          Navigator.of(context).pop();
          _restart();
        },
        onMenu: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _restart() {
    setState(() {
      _cells = List.filled(9, -1);
      _winLine = null;
      _over = false;
      _placedAt.clear();
      // Alternate starter per settings (RULES.md §12)
      _starter = ScoreStore.I.swapStarter ? 1 - _starter : 0;
      _turn = _starter;
    });
    Sound.I.gameStart();
    _maybeBotMove();
  }

  void _togglePause() {
    if (_over) return;
    Sound.I.click();
    setState(() => _paused = !_paused);
    if (_paused) {
      Sound.I.stopMusic();
    } else {
      Sound.I.gameMusic();
      _maybeBotMove();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ScoreStore.I;
    return Scaffold(
      backgroundColor: Nordic.canvas,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  child: Column(
                    children: [
                      // Top bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          NordicIconButton(
                            icon: Icons.arrow_back,
                            tooltip: 'Menu',
                            onTap: () {
                              Sound.I.click();
                              Navigator.of(context).pop();
                            },
                          ),
                          TurnCapsule(
                              text: _paused ? 'Paused' : _turnLabel,
                              yourTurn: !_over &&
                                  !_paused &&
                                  (!widget.vsBot || _turn == 0)),
                          NordicIconButton(
                            icon: _paused ? Icons.play_arrow : Icons.pause,
                            tooltip: _paused ? 'Resume' : 'Pause',
                            onTap: _togglePause,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Score plaques
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: widget.vsBot
                            ? [
                                ScorePlaque(title: 'You', value: '${s.soloX}'),
                                const SizedBox(width: 10),
                                ScorePlaque(
                                    title: 'Draws', value: '${s.soloDraws}'),
                                const SizedBox(width: 10),
                                ScorePlaque(title: 'Bot', value: '${s.soloO}'),
                              ]
                            : [
                                ScorePlaque(title: 'P1', value: '${s.p1Wins}'),
                                const SizedBox(width: 10),
                                ScorePlaque(
                                    title: 'Draws', value: '${s.duoDraws}'),
                                const SizedBox(width: 10),
                                ScorePlaque(title: 'P2', value: '${s.p2Wins}'),
                              ],
                      ),
                      const SizedBox(height: 18),
                      // Oak board
                      Expanded(
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Nordic.oakLight,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                    color: Nordic.oakMid, width: 1.5),
                                boxShadow: Nordic.boardShadow,
                              ),
                              child: GridView.builder(
                                physics:
                                    const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 10,
                                ),
                                itemCount: 9,
                                itemBuilder: (_, i) => _cell(i),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Bottom controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          NordicButton(
                              label: 'Restart',
                              primary: false,
                              onTap: () {
                                Sound.I.click();
                                _restart();
                              }),
                          const SizedBox(width: 12),
                          NordicIconButton(
                            icon: Icons.settings,
                            tooltip: 'Settings',
                            onTap: () {
                              Sound.I.click();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const SettingsScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
            // Pause veil
            if (_paused)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _togglePause,
                  child: Container(
                    color: Nordic.canvas.withValues(alpha: 0.72),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Paused', style: Nordic.heading(32)),
                          const SizedBox(height: 8),
                          Text('Tap to resume',
                              style: Nordic.body(14,
                                  color: Nordic.charcoalSoft)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _cell(int i) {
    final v = _cells[i];
    final inWin = _winLine?.contains(i) ?? false;
    final isShaking = _shakeCell == i;

    Widget inner = Container(
      decoration: BoxDecoration(
        color: inWin ? Nordic.terracotta.withValues(alpha: 0.28) : Nordic.canvas,
        borderRadius: BorderRadius.circular(12),
        // Debossed groove dividers
        boxShadow: inWin
            ? null
            : const [
                BoxShadow(
                    color: Color(0x142C2825),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                    spreadRadius: -1),
              ],
        border: inWin
            ? Border.all(color: Nordic.terracotta, width: 2)
            : null,
      ),
      alignment: Alignment.center,
      child: v == -1
          ? const SizedBox.shrink()
          : _PiecePop(mark: v, key: ValueKey('p$i-$_placedAt[i]')),
    );

    if (isShaking) {
      inner = AnimatedBuilder(
        animation: _shake,
        builder: (_, child) {
          final t = _shake.value;
          final dx = 8 * (1 - t) * (t < 0.5 ? 1 : -1) * (t * 4 % 2 < 1 ? 1 : -1);
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
        child: inner,
      );
    }

    return GestureDetector(
      onTap: () => _tap(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: inner,
      ),
    );
  }
}

/// Piece placement: scale settle + shadow contraction (physical weight).
class _PiecePop extends StatefulWidget {
  final int mark;
  const _PiecePop({super.key, required this.mark});

  @override
  State<_PiecePop> createState() => _PiecePopState();
}

class _PiecePopState extends State<_PiecePop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200))
      ..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 1.18, end: 1.0).animate(
          CurvedAnimation(parent: _c, curve: Curves.easeOutCubic)),
      child: CeramicPiece(mark: widget.mark, size: 58),
    );
  }
}

/// Game-over: elevated ceramic slab in soft oak frame.
class _GameOverDialog extends StatelessWidget {
  final String title;
  final bool isDraw;
  final VoidCallback onAgain;
  final VoidCallback onMenu;

  const _GameOverDialog(
      {required this.title,
      required this.isDraw,
      required this.onAgain,
      required this.onMenu});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Nordic.oakMid,
          borderRadius: BorderRadius.circular(24),
          boxShadow: Nordic.boardShadow,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 28),
          decoration: BoxDecoration(
            color: Nordic.surface,
            borderRadius: BorderRadius.circular(19),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  style: Nordic.heading(30), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                  isDraw
                      ? 'Nobody blinks. A perfectly balanced duel.'
                      : 'A well-earned victory, carved in oak.',
                  style: Nordic.body(14, color: Nordic.charcoalSoft),
                  textAlign: TextAlign.center),
              const SizedBox(height: 26),
              NordicButton(
                  label: 'Play Again', onTap: onAgain, width: double.infinity),
              const SizedBox(height: 12),
              NordicButton(
                  label: 'Menu',
                  primary: false,
                  onTap: onMenu,
                  width: double.infinity),
            ],
          ),
        ),
      ),
    );
  }
}
