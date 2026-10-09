import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../engine/ttt_engine.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/nordic_themes.dart';
import '../widgets/nordic.dart';
import 'pro_screen.dart';

/// Settings — vertical list of light wooden cards, theme-aware.
class SettingsScreen extends StatefulWidget {
  final NordicAudio audio;
  final NordicSettings settings;

  const SettingsScreen(
      {super.key, required this.audio, required this.settings});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  NordicThemeDef get _t =>
      NordicThemes.byId(widget.settings.effectiveThemeId);

  void _refresh() => setState(() {});

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
    final audio = widget.audio;
    final t = _t;
    return Scaffold(
      backgroundColor: t.canvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: NordicIconButton(
          icon: Icons.arrow_back,
          theme: t,
          tooltip: 'Back',
          onTap: () {
            audio.click();
            Navigator.of(context).pop();
          },
        ),
        title: Text('Settings', style: t.heading(22)),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _proCard(s, t),
              _card(
                t,
                'Music',
                'Gentle Nordic ambience',
                NordicToggle(
                    theme: t,
                    value: audio.musicOn,
                    onChanged: (v) async {
                      await s.setMusic(v);
                      audio.configure(
                          musicOn: v,
                          sfxOn: audio.sfxOn,
                          volume: audio.volume);
                      if (v) {
                        audio.startMenuMusic();
                      } else {
                        audio.stopMusic();
                      }
                      _refresh();
                    }),
              ),
              _card(
                t,
                'Sound effects',
                'Taps, knocks and chimes',
                NordicToggle(
                    theme: t,
                    value: audio.sfxOn,
                    onChanged: (v) async {
                      await s.setSfx(v);
                      audio.configure(
                          musicOn: audio.musicOn,
                          sfxOn: v,
                          volume: audio.volume);
                      if (v) audio.click();
                      _refresh();
                    }),
              ),
              _volumeCard(t),
              _difficultyCard(s, t),
              _themeCard(s, t),
              _markerCard(s, t),
              _namesCard(s, t),
              _card(
                t,
                'Alternate starting player',
                'Loser starts the next round (2-player)',
                NordicToggle(
                    theme: t,
                    value: s.swapStarter,
                    onChanged: (v) async {
                      audio.click();
                      await s.setSwapStarter(v);
                      _refresh();
                    }),
              ),
              _shareRateCard(t),
              const SizedBox(height: 8),
              _resetCard(s, t),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(
      NordicThemeDef t, String title, String sub, Widget trailing) {
    return WoodCard(
      theme: t,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.body(15)),
                const SizedBox(height: 2),
                Text(sub, style: t.body(12, color: t.textSoft)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _volumeCard(NordicThemeDef t) {
    final audio = widget.audio;
    return WoodCard(
      theme: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Volume', style: t.body(15)),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: t.accent,
              inactiveTrackColor: t.woodMid,
              thumbColor: t.primary,
              overlayColor: t.accent.withValues(alpha: 0.15),
            ),
            child: Slider(
              value: audio.volume,
              onChanged: (v) {
                audio.configure(
                    musicOn: audio.musicOn,
                    sfxOn: audio.sfxOn,
                    volume: v);
                widget.settings.setVolume(v);
                _refresh();
              },
              onChangeEnd: (_) => audio.click(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _difficultyCard(NordicSettings s, NordicThemeDef t) {
    Widget seg(BotDifficulty d, String label) {
      // Show the difficulty the game actually uses (Hard is Pro-only).
      final active = s.effectiveDifficulty == d;
      // Hard bot is a Pro feature (Free-vs-Pro).
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
            _refresh();
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

    return WoodCard(
      theme: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bot difficulty', style: t.body(15)),
          const SizedBox(height: 4),
          Text('How sharp the bot plays',
              style: t.body(12, color: t.textSoft)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: t.canvas,
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
          ),
        ],
      ),
    );
  }

  Widget _themeCard(NordicSettings s, NordicThemeDef t) {
    return WoodCard(
      theme: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Table theme', style: t.body(15)),
          const SizedBox(height: 4),
          Text('Wood, ceramic and light — pick your table',
              style: t.body(12, color: t.textSoft)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.6,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: NordicThemes.all.length,
            itemBuilder: (_, i) {
              final th = NordicThemes.all[i];
              final active = s.themeId == th.id;
              // Pro-only tables show a lock for free players (Free-vs-Pro).
              final locked =
                  !s.isPro && !NordicSettings.freeThemeIds.contains(th.id);
              return GestureDetector(
                onTap: () async {
                  widget.audio.click();
                  if (locked) {
                    _openPro();
                    return;
                  }
                  await s.setTheme(th.id);
                  _refresh();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: th.canvas,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: active ? t.accent : th.woodMid,
                      width: active ? 2.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Mini board preview
                      Container(
                        width: 34,
                        height: 34,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: th.woodLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: GridView.count(
                          crossAxisCount: 3,
                          mainAxisSpacing: 2,
                          crossAxisSpacing: 2,
                          physics:
                              const NeverScrollableScrollPhysics(),
                          children: [
                            _miniCell(th, 0),
                            _miniCell(th, -1),
                            _miniCell(th, -1),
                            _miniCell(th, -1),
                            _miniCell(th, 1),
                            _miniCell(th, -1),
                            _miniCell(th, -1),
                            _miniCell(th, -1),
                            _miniCell(th, -1),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(th.name,
                            style: th.label(11, caps: false),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (locked)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(Icons.lock,
                              size: 14, color: th.textSoft),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _miniCell(NordicThemeDef th, int v) {
    return Container(
      decoration: BoxDecoration(
        color: th.surface,
        borderRadius: BorderRadius.circular(2),
      ),
      alignment: Alignment.center,
      child: v == -1
          ? const SizedBox.shrink()
          : Text(
              v == 0 ? '\u2715' : '\u25cb',
              style: TextStyle(
                fontSize: 7,
                fontWeight: FontWeight.w800,
                color: v == 0 ? th.xToken : th.oInk,
                height: 1.0,
              ),
            ),
    );
  }

  Widget _markerCard(NordicSettings s, NordicThemeDef t) {
    return WoodCard(
      theme: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Marker style', style: t.body(15)),
          const SizedBox(height: 4),
          Text('The X and O pieces on your board',
              style: t.body(12, color: t.textSoft)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (int i = 0; i < MarkerStyle.values.length; i++)
                Builder(builder: (context) {
                  // Pro-only marker styles show a lock for free players.
                  final locked = !s.isPro &&
                      i >= NordicSettings.freeMarkerStyles;
                  return GestureDetector(
                    onTap: () async {
                      widget.audio.click();
                      if (locked) {
                        _openPro();
                        return;
                      }
                      await s.setMarkerStyle(i);
                      _refresh();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 104,
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 6),
                      decoration: BoxDecoration(
                        color: s.markerStyle == i
                            ? t.surface
                            : t.canvas.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: s.markerStyle == i
                              ? t.accent
                              : t.woodMid,
                          width: s.markerStyle == i ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              MarkerPiece(
                                  mark: 0,
                                  style: MarkerStyle.values[i],
                                  theme: t,
                                  size: 30),
                              const SizedBox(width: 6),
                              MarkerPiece(
                                  mark: 1,
                                  style: MarkerStyle.values[i],
                                  theme: t,
                                  size: 30),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              if (locked)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(right: 3),
                                  child: Icon(Icons.lock,
                                      size: 10, color: t.textSoft),
                                ),
                              Flexible(
                                child: Text(
                                    MarkerStyle.values[i].name,
                                    style: t.label(9),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _namesCard(NordicSettings s, NordicThemeDef t) {
    const labels = ['Solo · X', 'Solo · O', '2P · X', '2P · O'];
    return WoodCard(
      theme: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Player names', style: t.body(15)),
          const SizedBox(height: 4),
          Text('Tap a name to rename that slot',
              style: t.body(12, color: t.textSoft)),
          const SizedBox(height: 8),
          for (int i = 0; i < 4; i++)
            GestureDetector(
              onTap: () async {
                widget.audio.click();
                final name = await showRenameDialog(
                  context,
                  current: s.playerNames[i],
                  title: 'Name ${labels[i]}',
                  theme: t,
                );
                if (name != null && name.trim().isNotEmpty) {
                  await s.setPlayerName(i, name.trim());
                  _refresh();
                }
              },
              child: Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.symmetric(
                    vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: t.canvas,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: t.woodMid, width: 1),
                ),
                child: Row(
                  children: [
                    Text(labels[i].toUpperCase(),
                        style: t.label(10, color: t.textSoft)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(s.playerNames[i],
                          style: t.body(14),
                          overflow: TextOverflow.ellipsis),
                    ),
                    Icon(Icons.edit, size: 14, color: t.textSoft),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _proCard(NordicSettings s, NordicThemeDef t) {
    return GestureDetector(
      onTap: _openPro,
      child: WoodCard(
        theme: t,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: t.accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                  s.isPro ? Icons.verified : Icons.workspace_premium,
                  color: t.accent,
                  size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(s.isPro ? 'Tic Tac Toe Pro' : 'Go Pro',
                          style: t.body(15)),
                      if (s.isPro) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: t.accent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('PRO',
                              style: t.label(9, color: Colors.white)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                      s.isPro
                          ? 'Every table, marker and the Hard bot are yours'
                          : 'All 10 tables, 6 markers, Hard bot \u2014 one purchase',
                      style: t.body(12, color: t.textSoft)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: t.textSoft),
          ],
        ),
      ),
    );
  }

  Widget _shareRateCard(NordicThemeDef t) {
    Widget action(IconData icon, String label, VoidCallback onTap) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: t.canvas,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: t.woodMid, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: t.accent),
                const SizedBox(width: 8),
                Text(label, style: t.label(11)),
              ],
            ),
          ),
        ),
      );
    }

    return WoodCard(
      theme: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Spread the word', style: t.body(15)),
          const SizedBox(height: 4),
          Text('Challenge a friend, or leave us a rating',
              style: t.body(12, color: t.textSoft)),
          const SizedBox(height: 12),
          Row(
            children: [
              action(Icons.share, 'Share', _share),
              const SizedBox(width: 10),
              action(Icons.star_rate, 'Rate', _rate),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resetCard(NordicSettings s, NordicThemeDef t) {
    return GestureDetector(
      onTap: () async {
        widget.audio.click();
        final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: t.surface,
            title: Text('Reset scores?', style: t.heading(20)),
            content: Text('All saved scores will be cleared.',
                style: t.body(14)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel',
                      style: t.label(12, color: t.textSoft))),
              TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child:
                      Text('Reset', style: t.label(12, color: t.accent))),
            ],
          ),
        );
        if (ok == true) {
          await s.resetScores();
          _refresh();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        alignment: Alignment.center,
        child: Text('Reset scores',
            style: t.label(13, color: t.accent)),
      ),
    );
  }
}
