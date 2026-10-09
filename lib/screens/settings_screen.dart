import 'package:flutter/material.dart';
import '../design.dart';
import '../audio.dart';
import '../scores.dart';
import '../engine.dart';
import '../widgets/nordic.dart';

/// Settings — vertical list of light wooden cards.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final s = ScoreStore.I;
    final snd = Sound.I;
    return Scaffold(
      backgroundColor: Nordic.canvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: NordicIconButton(
          icon: Icons.arrow_back,
          tooltip: 'Back',
          onTap: () {
            snd.click();
            Navigator.of(context).pop();
          },
        ),
        title: Text('Settings', style: Nordic.heading(22)),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _card('Music', 'Gentle Nordic ambience',
                  NordicToggle(value: snd.musicOn, onChanged: (v) async {
                await snd.setMusic(v);
                if (v) snd.menuMusic();
                setState(() {});
              })),
              _card('Sound effects', 'Taps, knocks and chimes',
                  NordicToggle(value: snd.sfxOn, onChanged: (v) async {
                await snd.setSfx(v);
                if (v) snd.click();
                setState(() {});
              })),
              _volumeCard(),
              _difficultyCard(s),
              _card('Alternate starting player',
                  'Loser starts the next round',
                  NordicToggle(
                      value: s.swapStarter,
                      onChanged: (v) async {
                        await s.setSwapStarter(v);
                        setState(() {});
                      })),
              const SizedBox(height: 8),
              _resetCard(s),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(String title, String sub, Widget trailing) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      decoration: BoxDecoration(
        color: Nordic.oakLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Nordic.oakMid, width: 1),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F2C2825), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Nordic.body(15)),
                const SizedBox(height: 2),
                Text(sub,
                    style: Nordic.body(12, color: Nordic.charcoalSoft)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _volumeCard() {
    final snd = Sound.I;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      decoration: BoxDecoration(
        color: Nordic.oakLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Nordic.oakMid, width: 1),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F2C2825), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Volume', style: Nordic.body(15)),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Nordic.terracotta,
              inactiveTrackColor: Nordic.oakMid,
              thumbColor: Nordic.charcoal,
              overlayColor: Nordic.terracotta.withValues(alpha: 0.15),
            ),
            child: Slider(
              value: snd.volume,
              onChanged: (v) async {
                await snd.setVolume(v);
                setState(() {});
              },
              onChangeEnd: (_) => snd.click(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _difficultyCard(ScoreStore s) {
    Widget seg(BotDifficulty d, String label) {
      final active = s.difficulty == d;
      return Expanded(
        child: GestureDetector(
          onTap: () async {
            Sound.I.click();
            await s.setDifficulty(d);
            setState(() {});
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: active ? Nordic.charcoal : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(label.toUpperCase(),
                style: Nordic.label(11,
                    color: active ? Nordic.chalkWhite : Nordic.charcoalSoft)),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      decoration: BoxDecoration(
        color: Nordic.oakLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Nordic.oakMid, width: 1),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F2C2825), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bot difficulty', style: Nordic.body(15)),
          const SizedBox(height: 4),
          Text('How sharp the bot plays',
              style: Nordic.body(12, color: Nordic.charcoalSoft)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Nordic.canvas,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Nordic.oakMid, width: 1),
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

  Widget _resetCard(ScoreStore s) {
    return GestureDetector(
      onTap: () async {
        Sound.I.click();
        final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: Nordic.surface,
            title: Text('Reset scores?', style: Nordic.heading(20)),
            content: Text('All saved scores will be cleared.',
                style: Nordic.body(14)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel',
                      style: Nordic.label(12, color: Nordic.charcoalSoft))),
              TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('Reset',
                      style: Nordic.label(12, color: Nordic.terracotta))),
            ],
          ),
        );
        if (ok == true) {
          await s.reset();
          setState(() {});
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        alignment: Alignment.center,
        child: Text('Reset scores',
            style: Nordic.label(13, color: Nordic.terracotta)),
      ),
    );
  }
}
