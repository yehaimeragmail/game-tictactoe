import 'package:flutter/material.dart';
import '../design.dart';

/// Carved-wood primary button. Tap = 1px deboss press.
class NordicButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool primary;
  final double? width;

  const NordicButton(
      {super.key, required this.label, required this.onTap, this.primary = true, this.width});

  @override
  State<NordicButton> createState() => _NordicButtonState();
}

class _NordicButtonState extends State<NordicButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.primary ? Nordic.charcoal : Nordic.oakLight;
    final fg = widget.primary ? Nordic.chalkWhite : Nordic.charcoal;
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
          border: widget.primary
              ? null
              : Border.all(color: Nordic.oakMid, width: 1),
          boxShadow: _pressed
              ? [
                  const BoxShadow(
                      color: Color(0x1A2C2825), blurRadius: 4, offset: Offset(0, 1)),
                ]
              : [
                  const BoxShadow(
                      color: Color(0x262C2825), blurRadius: 14, offset: Offset(0, 6)),
                  const BoxShadow(
                      color: Color(0x59FFFFFF),
                      blurRadius: 0,
                      offset: Offset(0, 1)),
                ],
        ),
        alignment: Alignment.center,
        child: Text(widget.label.toUpperCase(),
            style: Nordic.label(14, color: fg)),
      ),
    );
  }
}

/// Brushed-ceramic toggle switch.
class NordicToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const NordicToggle({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 52,
        height: 30,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? Nordic.terracotta : Nordic.oakMid,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
                color: Color(0x142C2825), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Nordic.surface,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                  color: Color(0x262C2825), blurRadius: 4, offset: Offset(0, 2)),
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

  const ScorePlaque({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: Nordic.oakLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Nordic.oakMid, width: 1),
        boxShadow: const [
          BoxShadow(
              color: Color(0x122C2825), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title.toUpperCase(), style: Nordic.label(10)),
          const SizedBox(height: 2),
          Text(value,
              style: Nordic.heading(20).copyWith(fontFamily: Nordic.sans)),
        ],
      ),
    );
  }
}

/// Floating turn capsule pill.
class TurnCapsule extends StatelessWidget {
  final String text;
  final bool yourTurn;

  const TurnCapsule({super.key, required this.text, required this.yourTurn});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 18),
      decoration: BoxDecoration(
        color: Nordic.canvas,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Nordic.oakMid, width: 1),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F2C2825), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BreathingDot(active: yourTurn),
          const SizedBox(width: 8),
          Text(text, style: Nordic.label(12)),
        ],
      ),
    );
  }
}

class _BreathingDot extends StatefulWidget {
  final bool active;
  const _BreathingDot({required this.active});

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
          decoration: const BoxDecoration(
              color: Nordic.sage, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

/// Matte ceramic X / O piece with pillowy contact shadow.
class CeramicPiece extends StatelessWidget {
  final int mark; // 0 = X, 1 = O
  final double size;

  const CeramicPiece({super.key, required this.mark, this.size = 56});

  @override
  Widget build(BuildContext context) {
    final isX = mark == 0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isX ? Nordic.terracotta : Nordic.surface,
        shape: isX ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: isX ? BorderRadius.circular(size * 0.22) : null,
        border: isX
            ? null
            : Border.all(color: Nordic.oakMid, width: 1.5),
        boxShadow: Nordic.pieceShadow,
      ),
      alignment: Alignment.center,
      child: Text(
        isX ? '✕' : '◯',
        style: TextStyle(
          fontSize: size * 0.52,
          fontWeight: FontWeight.w800,
          color: isX ? Nordic.chalkWhite : Nordic.charcoal,
          fontFamily: Nordic.sans,
        ),
      ),
    );
  }
}

/// Round icon button (carved wood / brushed ceramic).
class NordicIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  const NordicIconButton(
      {super.key, required this.icon, required this.onTap, this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Nordic.surface,
            shape: BoxShape.circle,
            border: Border.all(color: Nordic.oakMid, width: 1),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x142C2825), blurRadius: 8, offset: Offset(0, 3)),
            ],
          ),
          child: Icon(icon, color: Nordic.charcoal, size: 20),
        ),
      ),
    );
  }
}
