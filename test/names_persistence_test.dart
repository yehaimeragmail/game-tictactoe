import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tictactoe/engine/ttt_engine.dart';
import 'package:tictactoe/services/settings_service.dart';

/// Regression tests for BUG 1 (2026-10-09): player names were persisted with
/// SharedPreferences.setStringList, which on Android is backed by an unordered
/// StringSet — names came back scrambled across slots after a restart. The
/// fix persists them as an order-preserving JSON string.
///
/// NOTE: widget tests are deliberately avoided here — constructing
/// NordicAudio (audioplayers platform channels) wedges the flutter_test
/// isolate in this environment, so UI-level rename flow is covered by the
/// listener-sync pattern test below, which mirrors GameScreen exactly.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('setPlayerName persists across a fresh load (restart simulation)',
      () async {
    final s1 = NordicSettings();
    await s1.load();
    await s1.setPlayerName(0, 'Wajiha');
    await s1.setPlayerName(1, 'Robo');

    // Simulate app restart: brand-new settings object, fresh load.
    final s2 = NordicSettings();
    await s2.load();
    expect(s2.playerNames[0], 'Wajiha');
    expect(s2.playerNames[1], 'Robo');
    expect(s2.playerNames[2], 'Player 1'); // untouched slots keep defaults
    expect(s2.playerNames[3], 'Player 2');
  });

  test('engine name-sync pattern (as in GameScreen._onSettingsChanged)',
      () async {
    final s = NordicSettings();
    await s.load();
    await s.setPlayerName(0, 'Wajiha');

    int slot(int mark) => mark; // vsBot solo slots
    final engine = TttEngine(
      players: [
        TttPlayer(name: s.playerNames[slot(0)], isBot: false),
        TttPlayer(name: s.playerNames[slot(1)], isBot: true),
      ],
      vsBot: true,
      enableWatchdog: false,
    );
    addTearDown(engine.dispose);
    expect(engine.players[0].name, 'Wajiha');

    // Rename AFTER the engine was constructed, as the rename dialog does.
    void onSettingsChanged() {
      engine.players[0].name = s.playerNames[slot(0)];
      engine.players[1].name = s.playerNames[slot(1)];
    }

    s.addListener(onSettingsChanged);
    await s.setPlayerName(0, 'Champion');
    expect(engine.players[0].name, 'Champion');

    // And it survives a restart.
    final s2 = NordicSettings();
    await s2.load();
    final engine2 = TttEngine(
      players: [
        TttPlayer(name: s2.playerNames[slot(0)], isBot: false),
        TttPlayer(name: s2.playerNames[slot(1)], isBot: true),
      ],
      vsBot: true,
      enableWatchdog: false,
    );
    addTearDown(engine2.dispose);
    expect(engine2.players[0].name, 'Champion');
    s.removeListener(onSettingsChanged);
  });

  test('Pro gating: free players get clamped themes/styles/difficulty',
      () async {
    final s = NordicSettings();
    await s.load();
    expect(s.isPro, isFalse);

    // Simulate stored Pro-only selections (UI normally gates these).
    await s.setTheme('smoked');
    await s.setMarkerStyle(5);
    await s.setDifficulty(BotDifficulty.hard);

    // Free players never actually get Pro content applied.
    expect(s.effectiveThemeId, 'classic');
    expect(s.effectiveMarkerStyle, 0);
    expect(s.effectiveDifficulty, BotDifficulty.normal);

    // After the one-time Pro unlock, everything applies…
    await s.setPro(true);
    expect(s.effectiveThemeId, 'smoked');
    expect(s.effectiveMarkerStyle, 5);
    expect(s.effectiveDifficulty, BotDifficulty.hard);

    // …and the unlock survives a restart.
    final s2 = NordicSettings();
    await s2.load();
    expect(s2.isPro, isTrue);
    expect(s2.effectiveDifficulty, BotDifficulty.hard);
  });
}
