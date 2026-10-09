import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'design.dart';
import 'audio.dart';
import 'scores.dart';
import 'screens/menu_screen.dart';

/// Tic Tac Toe — Nordic Wood & Ceramic edition.
/// Stitch is the visual source of truth (see stitch-batch1/tictactoe/DESIGN.md).
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Sound.I.init();
  await ScoreStore.I.load();
  runApp(const TicTacToeApp());
}

class TicTacToeApp extends StatelessWidget {
  const TicTacToeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tic Tac Toe',
      debugShowCheckedModeBanner: false,
      theme: Nordic.theme(),
      home: const MenuScreen(),
    );
  }
}
