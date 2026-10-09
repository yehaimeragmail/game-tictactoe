import 'package:flutter/material.dart';

/// Nordic Wood & Ceramic design system (from Stitch DESIGN.md).
/// Flat matte tones; depth conveyed through layered shadows only.
/// No gradients. No neon. Overhead-left natural daylight (315°).
abstract final class Nordic {
  // Palette
  static const canvas = Color(0xFFFAF7F2);      // warm off-white
  static const surface = Color(0xFFF5F3EF);     // chalk bone ceramic
  static const oakLight = Color(0xFFE8DCB8);    // secondary buttons
  static const oakMid = Color(0xFFDFD1B5);      // board tiles, borders
  static const terracotta = Color(0xFFC87D55);  // primary, X token
  static const sage = Color(0xFF6B7A68);        // turn indicator
  static const charcoal = Color(0xFF2C2825);    // body text
  static const charcoalSoft = Color(0xFF5A544E);
  static const chalkWhite = Color(0xFFFDFAF5);

  // Typography
  static const serif = 'Georgia'; // editorial serif fallback chain
  static const sans = 'Avenir';    // clean grotesque fallback chain

  static TextStyle heading(double size) => TextStyle(
        fontFamily: serif,
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: charcoal,
        letterSpacing: 0.2,
      );

  static TextStyle label(double size, {Color color = charcoalSoft, bool caps = true}) =>
      TextStyle(
        fontFamily: sans,
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: caps ? 1.6 : 0.2,
      );

  static TextStyle body(double size, {Color color = charcoal}) => TextStyle(
        fontFamily: sans,
        fontSize: size,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.45,
      );

  // Shadows — layered per DESIGN.md tokens
  static List<BoxShadow> get tileShadow => [
        const BoxShadow(
            color: Color(0x0F2C2825), blurRadius: 12, offset: Offset(0, 4)),
        const BoxShadow(
            color: Color(0x80555555), // top edge highlight via white overlay handled in widget
            blurRadius: 0,
            offset: Offset(0, 0)),
      ];

  static List<BoxShadow> get pieceShadow => [
        const BoxShadow(
            color: Color(0x1F2C2825), blurRadius: 16, offset: Offset(0, 8)),
      ];

  static List<BoxShadow> get boardShadow => [
        const BoxShadow(
            color: Color(0x142C2825), blurRadius: 28, offset: Offset(-6, 14)),
        const BoxShadow(
            color: Color(0x0A2C2825), blurRadius: 8, offset: Offset(0, 3)),
      ];

  static ThemeData theme() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: canvas,
      colorScheme: const ColorScheme.light(
        primary: terracotta,
        onPrimary: chalkWhite,
        surface: surface,
        onSurface: charcoal,
      ),
      textTheme: TextTheme(
        displayLarge: heading(34),
        titleLarge: heading(24),
        bodyLarge: body(16),
        labelLarge: label(13, caps: false),
      ),
    );
  }
}
