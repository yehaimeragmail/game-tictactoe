import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../engine/ttt_engine.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/nordic_themes.dart';
import '../widgets/nordic.dart';
import 'game_screen.dart';
import 'pro_screen.dart';
import 'settings_screen.dart';

/// Main menu — Scandinavian craft aesthetic, theme-aware.
class MenuScreen extends StatefulWidget {
  final NordicAudio audio;
  final NordicSettings settings;

  const MenuScreen({super.key, required this.audio, required this.settings});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  @override
  void initState() {
    super.initState();
    widget.audio.startMenuMusic();
  }

  void _play({required bool vsBot}) {
    final audio = widget.audio;
    audio.click();
    audio.startGameMusic();
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => GameScreen(
              audio: audio,
              settings: widget.settings,
              vsBot: vsBot,
            ),
          ),
        )
        .then((_) {
      audio.startMenuMusic();
      if (mounted) setState(() {}); // refresh scores / theme
    });
  }

  void _openSettings() {
    widget.audio.click();
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => SettingsScreen(
              audio: widget.audio,
              settings: widget.settings,
            ),
          ),
        )
        .then((_) {
      if (mounted) setState(() {}); // theme / names may have changed
    });
  }

  void _openPro() {
    widget.audio.click();
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => ProScreen(
              audio: widget.audio,
              settings: widget.settings,
            ),
          ),
        )
        .then((_) {
      if (mounted) setState(() {}); // Pro may have been unlocked
    });
  }

  Future<void> _share() async {
    widget.audio.click();
    try {
      await Share.share(
        'Play Tic Tac Toe with me! https://play.google.com/store/apps/details?id=com.gameswajiha.tictactoe',
      );
    } catch (_) {}
  }

  Future<void> _rate() async {
    widget.audio.click();
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.requestReview();
      } else {
        await review.openStoreListing(appStoreId: null);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    final t = NordicThemes.byId(s.effectiveThemeId);
    final style = MarkerStyle.values[s.effectiveMarkerStyle];
    return Scaffold(
      backgroundColor: t.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Game logo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: t.accent, width: 2.5),
                      boxShadow: t.boardShadow,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset('assets/tictactoe_logo.png',
                        fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 20),
                  Text('Tic Tac Toe', style: t.heading(38)),
                  const SizedBox(height: 6),
                  Text('A quiet duel of wits',
                      style: t.body(15, color: t.textSoft)),
                  const SizedBox(height: 28),
                  // Marker preview in the chosen style
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      MarkerPiece(mark: 0, style: style, theme: t, size: 54),
                      const SizedBox(width: 18),
                      MarkerPiece(mark: 1, style: style, theme: t, size: 54),
                    ],
                  ),
                  const SizedBox(height: 30),
                  NordicButton(
                    label: 'Play vs Bot',
                    theme: t,
                    onTap: () => _play(vsBot: true),
                    width: double.infinity,
                  ),
                  const SizedBox(height: 14),
                  NordicButton(
                    label: 'Two Players',
                    theme: t,
                    primary: false,
                    onTap: () => _play(vsBot: false),
                    width: double.infinity,
                  ),
                  const SizedBox(height: 14),
                  _difficultyRow(s, t),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: _openSettings,
                        child: Text('Settings',
                            style: t.label(13, color: t.textSoft)),
                      ),
                      Text('·', style: t.body(14, color: t.textSoft)),
                      TextButton(
                        onPressed: _openPro,
                        child: Text(s.isPro ? 'Pro ✓' : 'Go Pro',
                            style: t.label(13, color: t.accent)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      NordicIconButton(
                        icon: Icons.share,
                        theme: t,
                        tooltip: 'Share with a friend',
                        onTap: _share,
                      ),
                      const SizedBox(width: 16),
                      NordicIconButton(
                        icon: Icons.star_rate,
                        theme: t,
                        tooltip: 'Rate this game',
                        onTap: _rate,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Session scores (solo)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ScorePlaque(
                          title: s.playerNames[0],
                          value: '${s.soloX}',
                          theme: t),
                      const SizedBox(width: 10),
                      ScorePlaque(
                          title: 'Draws',
                          value: '${s.soloDraws}',
                          theme: t),
                      const SizedBox(width: 10),
                      ScorePlaque(
                          title: s.playerNames[1],
                          value: '${s.soloO}',
                          theme: t),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _difficultyRow(NordicSettings s, NordicThemeDef t) {
    Widget seg(BotDifficulty d, String label) {
      // Show the difficulty the game actually uses (Hard is Pro-only).
      final active = s.effectiveDifficulty == d;
      final locked = d == BotDifficulty.hard && !s.isPro;
      return Expanded(
        child: GestureDetector(
          onTap: () async {
            widget.audio.click();
            if (locked) {
              _openPro();
              return;
            }
            await s.setDifficulty(d);
            setState(() {});
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: active ? t.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (locked)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(Icons.lock,
                        size: 12,
                        color: active ? t.onPrimary : t.textSoft),
                  ),
                Text(label.toUpperCase(),
                    style: t.label(11,
                        color: active ? t.onPrimary : t.textSoft)),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: t.woodLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.woodMid, width: 1),
      ),
      child: Row(
        children: [
          seg(BotDifficulty.easy, 'Easy'),
          seg(BotDifficulty.normal, 'Normal'),
          seg(BotDifficulty.hard, 'Hard'),
        ],
      ),
    );
  }
}
