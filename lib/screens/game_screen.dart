import 'package:flutter/material.dart';
import '../engine/ttt_engine.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/nordic_themes.dart';
import '../widgets/nordic.dart';
import 'settings_screen.dart';

/// Game screen — engine-owned turn state machine, per-side player trays,
/// visible bot thinking narration. Light oak board, physical pieces.
class GameScreen extends StatefulWidget {
  final NordicAudio audio;
  final NordicSettings settings;
  final bool vsBot;

  const GameScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.vsBot,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TttEngine _engine;
  late final AnimationController _shake;
  int _shakeCell = -1;
  int _seenInvalidSeq = 0;
  bool _userPaused = false;
  bool _backgrounded = false;
  bool _dialogShown = false;

  NordicThemeDef get _t =>
      NordicThemes.byId(widget.settings.effectiveThemeId);
  MarkerStyle get _style => MarkerStyle
      .values[widget.settings.effectiveMarkerStyle.clamp(0, 5)];

  /// Name slots: solo → 0,1 ; duo → 2,3.
  int _slot(int mark) => widget.vsBot ? mark : mark + 2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _shake = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320));
    final s = widget.settings;
    _engine = TttEngine(
      players: [
        TttPlayer(name: s.playerNames[_slot(0)], isBot: false),
        TttPlayer(
            name: s.playerNames[_slot(1)], isBot: widget.vsBot),
      ],
      botDifficulty: s.effectiveDifficulty,
      vsBot: widget.vsBot,
      swapStarter: s.swapStarter,
    );
    _engine.onEvent = _onEngineEvent;
    _engine.addListener(_onEngineChanged);
    s.addListener(_onSettingsChanged);

    // RULES.md §12: restore a backgrounded mid-game exactly.
    final snap = s.loadGame();
    if (snap != null) {
      if (!_engine.restore(snap) || _engine.over) {
        s.clearSavedGame();
      }
    }
    widget.audio.startGameMusic();
    _engine.onEvent?.call(TttEvent.gameStart);
    widget.audio.gameStart();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_backgrounded && !_engine.over) {
      widget.settings.saveGame(_engine.snapshot());
    }
    widget.settings.removeListener(_onSettingsChanged);
    _engine.removeListener(_onEngineChanged);
    _engine.dispose();
    _shake.dispose();
    super.dispose();
  }

  void _onSettingsChanged() {
    if (!mounted) return;
    // Keep engine player names in sync with renamed slots.
    _engine.players[0].name = widget.settings.playerNames[_slot(0)];
    _engine.players[1].name = widget.settings.playerNames[_slot(1)];
    setState(() {});
  }

  void _onEngineChanged() {
    if (!mounted) return;
    if (_engine.invalidSeq != _seenInvalidSeq) {
      _seenInvalidSeq = _engine.invalidSeq;
      _shakeCell = _engine.invalidCell;
      _shake.forward(from: 0);
    }
    setState(() {});
  }

  void _onEngineEvent(TttEvent e) {
    final audio = widget.audio;
    switch (e) {
      case TttEvent.placeX:
        audio.placeX();
      case TttEvent.placeO:
        audio.placeO();
      case TttEvent.invalid:
        audio.invalid();
      case TttEvent.gameStart:
        break; // played in initState / restart
      case TttEvent.thinking:
        break; // narration is visual
      case TttEvent.win:
        audio.win();
        _onGameOver();
      case TttEvent.lose:
        audio.lose();
        _onGameOver();
      case TttEvent.draw:
        audio.draw();
        _onGameOver();
    }
  }

  void _onGameOver() {
    widget.settings.recordGame(
        vsBot: widget.vsBot, winnerMark: _engine.winnerMark);
    widget.settings.clearSavedGame();
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted && _engine.over && !_dialogShown) {
        _dialogShown = true;
        _showGameOver();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // RULES.md §12: backgrounded mid-game → saved; restored exactly.
    if (state == AppLifecycleState.paused) {
      _backgrounded = true;
      if (!_engine.over) {
        widget.settings.saveGame(_engine.snapshot());
      }
      widget.audio.onAppPaused();
      _engine.setPaused(true);
    } else if (state == AppLifecycleState.resumed) {
      _backgrounded = false;
      widget.audio.onAppResumed();
      if (!_userPaused && !_engine.over) {
        _engine.setPaused(false);
      }
    }
  }

  void _togglePause() {
    if (_engine.over) return;
    widget.audio.click();
    setState(() => _userPaused = !_userPaused);
    if (_userPaused) {
      widget.settings.saveGame(_engine.snapshot());
      widget.audio.onAppPaused();
      _engine.setPaused(true);
    } else {
      widget.audio.onAppResumed();
      _engine.setPaused(false);
    }
  }

  void _restart() {
    widget.audio.click();
    widget.audio.gameStart();
    _dialogShown = false;
    _engine.restart();
  }

  Future<void> _rename(int mark) async {
    widget.audio.click();
    final s = widget.settings;
    final name = await showRenameDialog(
      context,
      current: s.playerNames[_slot(mark)],
      title: mark == 0 ? 'Name player X' : 'Name player O',
      theme: _t,
    );
    if (name != null && name.trim().isNotEmpty) {
      await s.setPlayerName(_slot(mark), name.trim());
    }
  }

  void _quitToMenu() {
    widget.audio.click();
    widget.settings.clearSavedGame(); // explicit quit discards the game
    Navigator.of(context).pop();
  }

  void _openSettings() {
    widget.audio.click();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          audio: widget.audio,
          settings: widget.settings,
        ),
      ),
    );
  }

  String _scoreFor(int mark) {
    final s = widget.settings;
    if (widget.vsBot) {
      return mark == 0 ? '${s.soloX}' : '${s.soloO}';
    }
    return mark == 0 ? '${s.duoX}' : '${s.duoO}';
  }

  void _showGameOver() {
    final t = _t;
    final w = _engine.winnerMark;
    final n0 = widget.settings.playerNames[_slot(0)];
    final n1 = widget.settings.playerNames[_slot(1)];
    final title = w == null
        ? 'Stalemate'
        : widget.vsBot
            ? (w == 0 ? 'Quiet Victory' : 'Bot Prevails')
            : '${w == 0 ? n0 : n1} Wins';
    final subtitle = w == null
        ? 'Nobody blinks. A perfectly balanced duel.'
        : widget.vsBot && w == 1
            ? 'The bot carved its name into the oak this time.'
            : 'A well-earned victory, carved in oak.';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: t.woodMid,
            borderRadius: BorderRadius.circular(24),
            boxShadow: t.boardShadow,
          ),
          child: Container(
            padding:
                const EdgeInsets.symmetric(vertical: 32, horizontal: 28),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(19),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    style: t.heading(30), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(subtitle,
                    style: t.body(14, color: t.textSoft),
                    textAlign: TextAlign.center),
                const SizedBox(height: 26),
                NordicButton(
                    label: 'Play Again',
                    theme: t,
                    onTap: () {
                      Navigator.of(context).pop();
                      _restart();
                    },
                    width: double.infinity),
                const SizedBox(height: 12),
                NordicButton(
                    label: 'Menu',
                    theme: t,
                    primary: false,
                    onTap: () {
                      Navigator.of(context).pop();
                      _quitToMenu();
                    },
                    width: double.infinity),
              ],
            ),
          ),
        ),
      ),
    ).then((_) => _dialogShown = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final thinking = _engine.phase == TttPhase.thinking;
    final paused = _userPaused || _engine.paused;
    return Scaffold(
      backgroundColor: t.canvas,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  child: Column(
                    children: [
                      // Top bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          NordicIconButton(
                            icon: Icons.arrow_back,
                            theme: t,
                            tooltip: 'Menu',
                            onTap: _quitToMenu,
                          ),
                          Flexible(
                            child: TurnCapsule(
                              text: paused ? 'Paused' : _engine.banner,
                              active: !_engine.over && !paused,
                              thinking:
                                  thinking && !_engine.over && !paused,
                              theme: t,
                            ),
                          ),
                          NordicIconButton(
                            icon: _userPaused
                                ? Icons.play_arrow
                                : Icons.pause,
                            theme: t,
                            tooltip: _userPaused ? 'Resume' : 'Pause',
                            onTap: _togglePause,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // O side tray (top)
                      PlayerTray(
                        mark: 1,
                        name: _engine.players[1].name,
                        score: _scoreFor(1),
                        active: !_engine.over &&
                            !paused &&
                            _engine.turn == 1,
                        isBot: _engine.players[1].isBot,
                        thinking: thinking &&
                            _engine.turn == 1 &&
                            !_engine.over,
                        winner: _engine.winnerMark == 1,
                        style: _style,
                        theme: t,
                        onEditName: () => _rename(1),
                      ),
                      const SizedBox(height: 10),
                      // Oak board
                      Expanded(
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: t.woodLight,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                    color: t.woodMid, width: 1.5),
                                boxShadow: t.boardShadow,
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
                                itemBuilder: (_, i) => _cell(i, t),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // X side tray (bottom)
                      PlayerTray(
                        mark: 0,
                        name: _engine.players[0].name,
                        score: _scoreFor(0),
                        active: !_engine.over &&
                            !paused &&
                            _engine.turn == 0,
                        isBot: _engine.players[0].isBot,
                        thinking: false,
                        winner: _engine.winnerMark == 0,
                        style: _style,
                        theme: t,
                        onEditName: () => _rename(0),
                      ),
                      const SizedBox(height: 10),
                      // Bottom controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          NordicButton(
                              label: 'Restart',
                              theme: t,
                              primary: false,
                              onTap: _restart),
                          const SizedBox(width: 12),
                          NordicIconButton(
                            icon: Icons.settings,
                            theme: t,
                            tooltip: 'Settings',
                            onTap: _openSettings,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ),
            ),
            // Pause veil
            if (_userPaused)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _togglePause,
                  child: Container(
                    color: t.canvas.withValues(alpha: 0.72),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Paused', style: t.heading(32)),
                          const SizedBox(height: 8),
                          Text('Tap to resume',
                              style: t.body(14, color: t.textSoft)),
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

  Widget _cell(int i, NordicThemeDef t) {
    final v = _engine.cells[i];
    final inWin = _engine.winLine?.contains(i) ?? false;
    final isShaking = _shakeCell == i;

    Widget inner = Container(
      decoration: BoxDecoration(
        color: inWin ? t.accent.withValues(alpha: 0.28) : t.canvas,
        borderRadius: BorderRadius.circular(12),
        boxShadow: inWin
            ? null
            : [
                BoxShadow(
                    color: t.text.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                    spreadRadius: -1),
              ],
        border:
            inWin ? Border.all(color: t.accent, width: 2) : null,
      ),
      alignment: Alignment.center,
      child: v == -1
          ? const SizedBox.shrink()
          : _PiecePop(
              key: ValueKey('p$i-${_engine.lastMoveSeq}'),
              mark: v,
              style: _style,
              theme: t,
            ),
    );

    if (isShaking) {
      inner = AnimatedBuilder(
        animation: _shake,
        builder: (_, child) {
          final tt = _shake.value;
          final dx =
              8 * (1 - tt) * (tt < 0.5 ? 1 : -1) * (tt * 4 % 2 < 1 ? 1 : -1);
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
        child: inner,
      );
    }

    return GestureDetector(
      onTap: () => _engine.tapCell(i),
      child: inner,
    );
  }
}

/// Piece placement: scale settle + shadow contraction (physical weight).
class _PiecePop extends StatefulWidget {
  final int mark;
  final MarkerStyle style;
  final NordicThemeDef theme;
  const _PiecePop(
      {super.key,
      required this.mark,
      required this.style,
      required this.theme});

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
      child: MarkerPiece(
          mark: widget.mark,
          style: widget.style,
          theme: widget.theme,
          size: 58),
    );
  }
}
