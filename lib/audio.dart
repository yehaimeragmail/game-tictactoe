import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central sound manager. All game audio flows through here.
/// Music + SFX toggles and volume persist via SharedPreferences.
class Sound {
  Sound._();
  static final Sound I = Sound._();

  final AudioPlayer _sfx = AudioPlayer();
  final AudioPlayer _music = AudioPlayer();

  bool musicOn = true;
  bool sfxOn = true;
  double volume = 0.8; // 0..1
  bool _loaded = false;

  static const _kMusic = 'pref_music_on';
  static const _kSfx = 'pref_sfx_on';
  static const _kVol = 'pref_volume';

  Future<void> init() async {
    if (_loaded) return;
    _loaded = true;
    final p = await SharedPreferences.getInstance();
    musicOn = p.getBool(_kMusic) ?? true;
    sfxOn = p.getBool(_kSfx) ?? true;
    volume = p.getDouble(_kVol) ?? 0.8;
    await _music.setReleaseMode(ReleaseMode.loop);
    await _applyVolumes();
  }

  Future<void> _applyVolumes() async {
    await _sfx.setVolume(sfxOn ? volume : 0.0);
    await _music.setVolume(musicOn ? volume * 0.55 : 0.0);
  }

  Future<void> setMusic(bool on) async {
    musicOn = on;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kMusic, on);
    await _applyVolumes();
    if (!on) {
      await _music.stop();
    }
  }

  Future<void> setSfx(bool on) async {
    sfxOn = on;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kSfx, on);
    await _applyVolumes();
  }

  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0);
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_kVol, volume);
    await _applyVolumes();
  }

  // --- one-shot SFX -------------------------------------------------------
  Future<void> _play(String file) async {
    if (!sfxOn) return;
    try {
      await _sfx.play(AssetSource('sounds/$file'));
    } catch (_) {}
  }

  Future<void> click() => _play('click.wav');
  Future<void> placeX() => _play('place_x.wav');
  Future<void> placeO() => _play('place_o.wav');
  Future<void> invalid() => _play('invalid.wav');
  Future<void> gameStart() => _play('game_start.wav');
  Future<void> win() => _play('win.wav');
  Future<void> draw() => _play('draw.wav');

  // --- music ----------------------------------------------------------------
  Future<void> menuMusic() async {
    if (!musicOn) return;
    try {
      await _music.stop();
      await _music.play(AssetSource('sounds/menu_music.wav'));
    } catch (_) {}
  }

  Future<void> gameMusic() async {
    if (!musicOn) return;
    try {
      await _music.stop();
      await _music.play(AssetSource('sounds/game_music.wav'));
    } catch (_) {}
  }

  Future<void> stopMusic() async {
    try {
      await _music.stop();
    } catch (_) {}
  }

  void dispose() {
    _sfx.dispose();
    _music.dispose();
  }
}
