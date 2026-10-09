import 'package:flutter/material.dart';
import '../design.dart';
import '../audio.dart';
import '../scores.dart';
import '../widgets/nordic.dart';
import 'game_screen.dart';
import 'settings_screen.dart';

/// Main menu — Scandinavian craft aesthetic.
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  @override
  void initState() {
    super.initState();
    Sound.I.menuMusic();
  }

  void _play({required bool vsBot}) {
    Sound.I.click();
    Sound.I.gameMusic();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GameScreen(vsBot: vsBot)),
    ).then((_) => Sound.I.menuMusic());
  }

  void _openSettings() {
    Sound.I.click();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ScoreStore.I;
    return Scaffold(
      backgroundColor: Nordic.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Ceramic X/O emblem
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      CeramicPiece(mark: 0, size: 64),
                      SizedBox(width: 18),
                      CeramicPiece(mark: 1, size: 64),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text('Tic Tac Toe', style: Nordic.heading(38)),
                  const SizedBox(height: 8),
                  Text('A quiet duel of wits',
                      style: Nordic.body(15, color: Nordic.charcoalSoft)),
                  const SizedBox(height: 40),
                  NordicButton(
                    label: 'Play vs Bot',
                    onTap: () => _play(vsBot: true),
                    width: double.infinity,
                  ),
                  const SizedBox(height: 14),
                  NordicButton(
                    label: 'Two Players',
                    primary: false,
                    onTap: () => _play(vsBot: false),
                    width: double.infinity,
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: _openSettings,
                    child: Text('Settings',
                        style: Nordic.label(13, color: Nordic.charcoalSoft)),
                  ),
                  const SizedBox(height: 28),
                  // Session scores
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ScorePlaque(title: 'You', value: '${s.soloX}'),
                      const SizedBox(width: 10),
                      ScorePlaque(title: 'Draws', value: '${s.soloDraws}'),
                      const SizedBox(width: 10),
                      ScorePlaque(title: 'Bot', value: '${s.soloO}'),
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
}
