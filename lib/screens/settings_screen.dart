import 'package:flutter/material.dart';
import '../engine/ttt_engine.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/nordic_themes.dart';
import '../widgets/nordic.dart';
import 'support_screen.dart';

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
      NordicThemes.byId(widget.settings.themeId);

  void _refresh() => setState(() {});

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
              _supportCard(t),
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
      final active = s.difficulty == d;
      return Expanded(
        child: GestureDetector(
          onTap: () async {
            widget.audio.click();
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
            child: Text(label.toUpperCase(),
                style: t.label(11,
                    color: active ? t.onPrimary : t.textSoft)),
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
              return GestureDetector(
                onTap: () async {
                  widget.audio.click();
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
                GestureDetector(
                  onTap: () async {
                    widget.audio.click();
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
                        Text(MarkerStyle.values[i].name,
                            style: t.label(9),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ),
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

  Widget _supportCard(NordicThemeDef t) {
    return GestureDetector(
      onTap: () {
        widget.audio.click();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SupportScreen()),
        );
      },
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
              child: Icon(Icons.favorite,
                  color: t.accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Support Wajiha', style: t.body(15)),
                  const SizedBox(height: 2),
                  Text('This game is 100% free — tips keep the workshop open',
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
