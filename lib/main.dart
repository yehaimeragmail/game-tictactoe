import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const TicTacToeApp());

class TicTacToeApp extends StatelessWidget {
  const TicTacToeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GameShell(
      variant: ShellVariant.softBlob,
      title: 'Tic Tac Toe',
      tagline: 'The timeless duel of Xs and Os. Outsmart your rival in seconds!',
      emoji: '❌',
      slug: 'tictactoe',
      howToPlay:
          '• Players take turns placing ✕ and ◯ on the 3×3 grid.\n• First to get 3 in a row — across, down or diagonal — wins the round.\n• Playing solo? The bot is sneakier than it looks. 🤖\n• With friends, pass the phone and battle it out!',
      playerOptions: const [1, 2],
      supportsBots: true,
      gameBuilder: (ctx, players, cb) => TicTacToeScreen(players: players, callbacks: cb),
    );
  }
}
