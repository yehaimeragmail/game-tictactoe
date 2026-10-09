import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/nordic_themes.dart';
import '../widgets/nordic.dart';

/// Tic Tac Toe Pro — Free-vs-Pro comparison, the one-time Pro unlock (real
/// Play Billing IAP via `tictactoepro`), restore-purchases, and the
/// consumable tip jar (`tictactoecoffee` / `tictactoechocolate`).
///
/// Degrades gracefully when the products aren't created in Play Console yet:
/// instead of fake buttons it says the store unlocks after setup.
class ProScreen extends StatefulWidget {
  final NordicAudio audio;
  final NordicSettings settings;

  const ProScreen({super.key, required this.audio, required this.settings});

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  final TttStore _store = TttStore();
  bool _loading = true;
  bool _busy = false;

  NordicThemeDef get _t =>
      NordicThemes.byId(widget.settings.effectiveThemeId);

  @override
  void initState() {
    super.initState();
    _store.onProUnlocked = () => widget.settings.setPro(true);
    _store.init().then((_) {
      if (mounted) setState(() => _loading = false);
    });
    _store.lastThanks.addListener(_onThanks);
    widget.settings.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _onThanks() {
    final msg = _store.lastThanks.value;
    if (msg == null || !mounted) return;
    final t = _t;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: t.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Thank you!', style: t.heading(22)),
        content: Text(msg, style: t.body(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('You\u2019re welcome',
                style: t.label(12, color: t.accent)),
          ),
        ],
      ),
    );
    _store.lastThanks.value = null;
  }

  @override
  void dispose() {
    _store.lastThanks.removeListener(_onThanks);
    widget.settings.removeListener(_refresh);
    _store.dispose();
    super.dispose();
  }

  Future<void> _buyPro() async {
    if (_busy) return;
    widget.audio.click();
    setState(() => _busy = true);
    try {
      await _store.buyPro();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    if (_busy) return;
    widget.audio.click();
    setState(() => _busy = true);
    try {
      await _store.restore();
      // Restored purchases arrive on the purchase stream; give them a beat.
      await Future.delayed(const Duration(seconds: 2));
      if (mounted && !widget.settings.isPro) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('No previous Pro purchase found',
                  style: _t.body(14, color: Colors.white))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _tip(String id) async {
    if (_busy) return;
    final product = _store.products[id];
    if (product == null) return;
    widget.audio.click();
    setState(() => _busy = true);
    try {
      await _store.buyTip(product);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = widget.settings;
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
            widget.audio.click();
            Navigator.of(context).pop();
          },
        ),
        title: Text('Tic Tac Toe Pro', style: t.heading(22)),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                width: 110,
                height: 110,
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
              Text('Free forever. Pro for the collectors.',
                  style: t.heading(22), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'The full game is free — no ads, no pay-to-win. Pro unlocks '
                'every table, every marker and the unbeatable Hard bot, '
                'in one purchase, forever.',
                style: t.body(14, color: t.textSoft),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _comparisonCard(t),
              const SizedBox(height: 16),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else
                _storeSection(t, s),
              const SizedBox(height: 16),
              _tipJarCard(t),
              const SizedBox(height: 8),
              Text('Credits: WAJIHA',
                  style: t.label(12, color: t.textSoft),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------- Free-vs-Pro table
  Widget _comparisonCard(NordicThemeDef t) {
    Widget row(String feature, String free, String pro,
        {bool highlight = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Expanded(
                flex: 4,
                child: Text(feature,
                    style: highlight
                        ? t.body(14).copyWith(fontWeight: FontWeight.w700)
                        : t.body(14))),
            Expanded(
                flex: 3,
                child: Text(free,
                    style: t.body(13, color: t.textSoft),
                    textAlign: TextAlign.center)),
            Expanded(
                flex: 3,
                child: Text(pro,
                    style: t.body(13).copyWith(
                        fontWeight: FontWeight.w700, color: t.accent),
                    textAlign: TextAlign.center)),
          ],
        ),
      );
    }

    return WoodCard(
      theme: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(flex: 4, child: SizedBox.shrink()),
              Expanded(
                  flex: 3,
                  child: Text('FREE',
                      style: t.label(11), textAlign: TextAlign.center)),
              Expanded(
                  flex: 3,
                  child: Text('PRO',
                      style: t.label(11, color: t.accent),
                      textAlign: TextAlign.center)),
            ],
          ),
          Divider(color: t.woodMid, height: 18),
          row('Table themes', '3', 'All 10'),
          row('Marker styles', '2', 'All 6'),
          row('Bot difficulty', 'Easy · Normal', 'Adds Hard'),
          row('Player names', '4 slots', '4 slots'),
          row('Tip jar', 'Included', 'Included'),
          row('Price', 'Free', 'One-time', highlight: true),
        ],
      ),
    );
  }

  // ------------------------------------------------------- store section
  Widget _storeSection(NordicThemeDef t, NordicSettings s) {
    if (s.isPro) {
      return WoodCard(
        theme: t,
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: t.accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.verified, color: t.accent, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('You\u2019re Pro', style: t.heading(18)),
                  const SizedBox(height: 2),
                  Text('Every table, marker and the Hard bot are yours.',
                      style: t.body(13, color: t.textSoft)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final pro = _store.proProduct;
    if (!_store.available) {
      return WoodCard(
        theme: t,
        child: Text(
          _store.error ?? 'The store is unavailable on this device.',
          style: t.body(14, color: t.textSoft),
          textAlign: TextAlign.center,
        ),
      );
    }
    if (pro == null) {
      // Products not created in Play Console yet — graceful, no fake button.
      return WoodCard(
        theme: t,
        child: Column(
          children: [
            Icon(Icons.storefront_outlined, size: 34, color: t.textSoft),
            const SizedBox(height: 10),
            Text('Pro unlock coming to the store',
                style: t.body(15), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              'The one-time Pro purchase appears here automatically once '
              'it is set up in Play Console. The free game stays fully playable.',
              style: t.body(13, color: t.textSoft),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        NordicButton(
          label: _busy ? 'Working\u2026' : 'Unlock Pro \u00b7 ${pro.price}',
          theme: t,
          onTap: _buyPro,
          width: double.infinity,
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: _busy ? null : _restore,
          child: Text('Restore purchases',
              style: t.label(12, color: t.textSoft)),
        ),
      ],
    );
  }

  // ------------------------------------------------------------ tip jar
  Widget _tipJarCard(NordicThemeDef t) {
    final coffee = _store.coffeeProduct;
    final choco = _store.chocolateProduct;
    List<Widget> buttons = [];
    if (coffee != null) {
      buttons.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: NordicButton(
          label: _busy ? 'Working\u2026' : '${coffee.title} \u00b7 ${coffee.price}',
          theme: t,
          primary: false,
          onTap: () => _tip(TttStore.coffeeId),
          width: double.infinity,
        ),
      ));
    }
    if (choco != null) {
      buttons.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: NordicButton(
          label: _busy ? 'Working\u2026' : '${choco.title} \u00b7 ${choco.price}',
          theme: t,
          primary: false,
          onTap: () => _tip(TttStore.chocolateId),
          width: double.infinity,
        ),
      ));
    }
    return WoodCard(
      theme: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tip jar', style: t.body(15)),
          const SizedBox(height: 4),
          Text(
            'Tic Tac Toe is 100% free. A small tip keeps the workshop carving.',
            style: t.body(12, color: t.textSoft),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (buttons.isEmpty)
            Text(
              'Tips are brewing \u2014 they appear here automatically once '
              'set up in Play Console.',
              style: t.body(13, color: t.textSoft),
            )
          else
            ...buttons,
        ],
      ),
    );
  }
}
