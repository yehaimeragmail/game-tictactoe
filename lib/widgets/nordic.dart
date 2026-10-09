import 'package:flutter/material.dart';
import '../theme/nordic_themes.dart';

/// Theme-aware Nordic widget kit. Depth comes from layered shadows only —
/// no gradients, no neon (Stitch DESIGN.md).

/// Carved-wood primary button. Tap = 1px deboss press.
class NordicButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool primary;
  final double? width;
  final NordicThemeDef theme;

  const NordicButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.theme,
    this.primary = true,
    this.width,
  });

  @override
  State<NordicButton> createState() => _NordicButtonState();
}

class _NordicButtonState extends State<NordicButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final bg = widget.primary ? t.primary : t.woodLight;
    final fg = widget.primary ? t.onPrimary : t.text;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        width: widget.width,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
        transform: Matrix4.translationValues(0, _pressed ? 1.5 : 0, 0),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border:
              widget.primary ? null : Border.all(color: t.woodMid, width: 1),
          boxShadow: _pressed
              ? [
                  BoxShadow(
                      color: t.text.withValues(alpha: 0.10),
                      blurRadius: 4,
                      offset: const Offset(0, 1)),
                ]
              : [
                  BoxShadow(
                      color: t.text.withValues(alpha: 0.15),
                      blurRadius: 14,
                      offset: const Offset(0, 6)),
                  const BoxShadow(
                      color: Color(0x59FFFFFF),
                      blurRadius: 0,
                      offset: Offset(0, 1)),
                ],
        ),
        alignment: Alignment.center,
        child: Text(widget.label.toUpperCase(), style: t.label(14, color: fg)),
      ),
    );
  }
}

/// Brushed-ceramic toggle switch.
class NordicToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final NordicThemeDef theme;

  const NordicToggle(
      {super.key,
      required this.value,
      required this.onChanged,
      required this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 52,
        height: 30,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? t.accent : t.woodMid,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
                color: t.text.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: t.surface,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: t.text.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small wooden score plaque.
class ScorePlaque extends StatelessWidget {
  final String title;
  final String value;
  final NordicThemeDef theme;

  const ScorePlaque(
      {super.key, required this.title, required this.value, required this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: t.woodLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.woodMid, width: 1),
        boxShadow: t.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title.toUpperCase(), style: t.label(10)),
          const SizedBox(height: 2),
          Text(value,
              style: t.heading(20).copyWith(fontFamily: NordicThemeDef.sans)),
        ],
      ),
    );
  }
}

/// Floating turn capsule pill with a breathing sage dot.
class TurnCapsule extends StatelessWidget {
  final String text;
  final bool active;
  final bool thinking;
  final NordicThemeDef theme;

  const TurnCapsule({
    super.key,
    required this.text,
    required this.active,
    required this.theme,
    this.thinking = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 18),
      decoration: BoxDecoration(
        color: t.canvas,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: active ? t.accent : t.woodMid, width: active ? 1.5 : 1),
        boxShadow: [
          BoxShadow(
              color: t.text.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BreathingDot(active: active, theme: t),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: t.label(12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (thinking) ...[
            const SizedBox(width: 6),
            _ThinkingDots(theme: t),
          ],
        ],
      ),
    );
  }
}

class _BreathingDot extends StatefulWidget {
  final bool active;
  final NordicThemeDef theme;
  const _BreathingDot({required this.active, required this.theme});

  @override
  State<_BreathingDot> createState() => _BreathingDotState();
}

class _BreathingDotState extends State<_BreathingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Opacity(
        opacity: widget.active ? 0.55 + 0.45 * _c.value : 0.35,
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: widget.theme.sage, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

class _ThinkingDots extends StatefulWidget {
  final NordicThemeDef theme;
  const _ThinkingDots({required this.theme});

  @override
  State<_ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<_ThinkingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < 3; i++)
            Container(
              width: 5,
              height: 5,
              margin: EdgeInsets.only(left: i == 0 ? 0 : 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.theme.textSoft.withValues(
                    alpha: 0.35 + 0.65 * (0.5 + 0.5 * ((_c.value * 3 - i * 0.5) % 1.0))),
              ),
            ),
        ],
      ),
    );
  }
}

/// The X / O piece in the selected marker style — a physical object with
/// pillowy contact shadow. All styles are matte and physical.
class MarkerPiece extends StatelessWidget {
  final int mark; // 0 = X, 1 = O
  final MarkerStyle style;
  final NordicThemeDef theme;
  final double size;

  const MarkerPiece({
    super.key,
    required this.mark,
    required this.style,
    required this.theme,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final isX = mark == 0;
    late final Color token;
    late final Color ink;
    late final double radius;
    BoxBorder? border;

    switch (style) {
      case MarkerStyle.ceramic:
        token = isX ? t.xToken : t.oToken;
        ink = isX ? t.xInk : t.oInk;
        radius = isX ? size * 0.22 : size * 0.5;
        if (!isX) border = Border.all(color: t.woodMid, width: 1.5);
      case MarkerStyle.chalk:
        token = const Color(0xFF33302C);
        ink = const Color(0xFFF5F1E6);
        radius = size * 0.18;
      case MarkerStyle.carved:
        token = t.woodMid;
        ink = t.text;
        radius = size * 0.28;
        border = Border.all(color: t.text.withValues(alpha: 0.25), width: 1.5);
      case MarkerStyle.ink:
        token = t.surface;
        ink = isX ? t.text : t.accent;
        radius = size * 0.12;
        border = Border.all(color: t.woodMid, width: 1.5);
      case MarkerStyle.stone:
        token = const Color(0xFF9AA0A3);
        ink = const Color(0xFF2E3234);
        radius = size * 0.42;
      case MarkerStyle.porcelain:
        token = const Color(0xFFFDFEFF);
        ink = const Color(0xFF2F5D8A);
        radius = size * 0.5;
        border = Border.all(color: const Color(0xFF2F5D8A), width: 1.5);
    }

    Widget glyph;
    if (isX) {
      glyph = Text(
        '\u2715',
        style: TextStyle(
          fontSize: size * 0.5,
          fontWeight: FontWeight.w800,
          color: ink,
          fontFamily: NordicThemeDef.sans,
          height: 1.0,
        ),
      );
    } else {
      // O is a ring, not a filled disc.
      glyph = Container(
        width: size * 0.52,
        height: size * 0.52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ink, width: size * 0.13),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: token,
        borderRadius: BorderRadius.circular(radius),
        border: border,
        boxShadow: t.pieceShadow,
      ),
      alignment: Alignment.center,
      child: glyph,
    );
  }
}

/// Round icon button (carved wood / brushed ceramic).
class NordicIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final NordicThemeDef theme;

  const NordicIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.theme,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: t.surface,
            shape: BoxShape.circle,
            border: Border.all(color: t.woodMid, width: 1),
            boxShadow: [
              BoxShadow(
                  color: t.text.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3)),
            ],
          ),
          child: Icon(icon, color: t.text, size: 20),
        ),
      ),
    );
  }
}

/// Light wooden settings card.
class WoodCard extends StatelessWidget {
  final Widget child;
  final NordicThemeDef theme;
  final EdgeInsetsGeometry? padding;

  const WoodCard(
      {super.key, required this.child, required this.theme, this.padding});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: padding ?? const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      decoration: BoxDecoration(
        color: t.woodLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.woodMid, width: 1),
        boxShadow: t.cardShadow,
      ),
      child: child,
    );
  }
}

/// Per-side player tray: each side (X / O) owns its marker, name, score and
/// activity state. The active side highlights; a bot side narrates thinking.
class PlayerTray extends StatelessWidget {
  final int mark; // 0 = X, 1 = O
  final String name;
  final String score;
  final bool active;
  final bool isBot;
  final bool thinking;
  final bool winner;
  final MarkerStyle style;
  final NordicThemeDef theme;
  final VoidCallback onEditName;

  const PlayerTray({
    super.key,
    required this.mark,
    required this.name,
    required this.score,
    required this.active,
    required this.isBot,
    required this.thinking,
    required this.winner,
    required this.style,
    required this.theme,
    required this.onEditName,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: active ? t.surface : t.woodLight.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: winner
              ? t.accent
              : active
                  ? t.accent
                  : t.woodMid,
          width: active || winner ? 2 : 1,
        ),
        boxShadow: active ? t.cardShadow : null,
      ),
      child: Row(
        children: [
          MarkerPiece(mark: mark, style: style, theme: t, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: t.body(15).copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: onEditName,
                      child: Icon(Icons.edit,
                          size: 14, color: t.textSoft),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: thinking
                      ? Row(
                          key: const ValueKey('thinking'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('thinking',
                                style: t.label(10, color: t.textSoft)),
                            const SizedBox(width: 6),
                            _ThinkingDots(theme: t),
                          ],
                        )
                      : Text(
                          isBot ? 'BOT \u00b7 $score PTS' : '$score PTS',
                          key: const ValueKey('idle'),
                          style: t.label(10, color: t.textSoft),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _BreathingDot(active: active, theme: t),
        ],
      ),
    );
  }
}

/// Rename dialog for a player slot.
Future<String?> showRenameDialog(
  BuildContext context, {
  required String current,
  required String title,
  required NordicThemeDef theme,
}) {
  final t = theme;
  final ctrl = TextEditingController(text: current);
  return showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: t.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(title, style: t.heading(20)),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        maxLength: 16,
        style: t.body(16),
        decoration: InputDecoration(
          hintText: 'Enter a name',
          hintStyle: t.body(14, color: t.textSoft),
          enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: t.woodMid)),
          focusedBorder:
              UnderlineInputBorder(borderSide: BorderSide(color: t.accent)),
        ),
        onSubmitted: (_) => Navigator.of(context).pop(ctrl.text.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: t.label(12, color: t.textSoft)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(ctrl.text.trim()),
          child: Text('Save', style: t.label(12, color: t.accent)),
        ),
      ],
    ),
  );
}
