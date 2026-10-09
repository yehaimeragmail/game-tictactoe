import 'package:flutter/material.dart';
import '../services/iap_service.dart';
import '../theme/nordic_themes.dart';
import '../widgets/nordic.dart';

/// Tasteful tip-jar screen. Degrades gracefully when the products are not
/// configured in Play Console yet.
class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final TipJar _tipJar = TipJar();
  bool _loading = true;
  // Theme here is standalone (no settings passed in); default to classic.
  final NordicThemeDef _t = NordicThemes.byId('classic');

  @override
  void initState() {
    super.initState();
    _tipJar.init().then((_) {
      if (mounted) setState(() => _loading = false);
    });
    _tipJar.lastThanks.addListener(_onThanks);
  }

  void _onThanks() {
    final msg = _tipJar.lastThanks.value;
    if (msg == null || !mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _t.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Thank you!', style: _t.heading(22)),
        content: Text(msg, style: _t.body(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('You\u2019re welcome',
                style: _t.label(12, color: _t.accent)),
          ),
        ],
      ),
    );
    _tipJar.lastThanks.value = null;
  }

  @override
  void dispose() {
    _tipJar.lastThanks.removeListener(_onThanks);
    _tipJar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          onTap: () => Navigator.of(context).pop(),
        ),
        title: Text('Support', style: t.heading(22)),
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
              Text('Tic Tac Toe is 100% free.',
                  style: t.heading(22), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'No ads, no pay-to-win — just a quiet board and a sharp bot. '
                'If it brought you a smile, a small tip keeps the workshop carving.',
                style: t.body(14, color: t.textSoft),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_tipJar.products.isEmpty)
                WoodCard(
                  theme: t,
                  child: Column(
                    children: [
                      Icon(Icons.coffee_outlined,
                          size: 36, color: t.textSoft),
                      const SizedBox(height: 10),
                      Text('Tips are brewing…',
                          style: t.body(15),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 6),
                      Text(
                        _tipJar.error ??
                            'Tip products are not available on this device right now.',
                        style: t.body(13, color: t.textSoft),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                for (final p in _tipJar.products)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: NordicButton(
                      label:
                          '${p.title} · ${p.price}',
                      theme: t,
                      primary: p.id == TipJar.coffeeId,
                      onTap: () => _tipJar.buy(p),
                      width: double.infinity,
                    ),
                  ),
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
}
