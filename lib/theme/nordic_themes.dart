import 'package:flutter/material.dart';

/// Theme, marker-style and board-accent catalogs for Tic Tac Toe.
///
/// Every theme stays inside the Nordic Wood & Ceramic material world —
/// real woods, matte ceramics, chalk, stone and ink. No neon, no gradients,
/// no glow: depth comes from shadows only (see Stitch DESIGN.md).
class NordicThemeDef {
  final String id;
  final String name;
  final Color canvas; // app background
  final Color surface; // ceramic slabs, cards
  final Color woodLight; // board tray, secondary buttons
  final Color woodMid; // cell tiles, borders
  final Color xToken; // X token body
  final Color xInk; // X glyph
  final Color oToken; // O token body
  final Color oInk; // O ring
  final Color primary; // primary button fill
  final Color onPrimary; // primary button text
  final Color accent; // warm highlight (win inlay, active borders)
  final Color text;
  final Color textSoft;
  final Color sage; // turn indicator dot

  const NordicThemeDef({
    required this.id,
    required this.name,
    required this.canvas,
    required this.surface,
    required this.woodLight,
    required this.woodMid,
    required this.xToken,
    required this.xInk,
    required this.oToken,
    required this.oInk,
    required this.primary,
    required this.onPrimary,
    required this.accent,
    required this.text,
    required this.textSoft,
    required this.sage,
  });

  // --- typography -----------------------------------------------------------
  static const serif = 'Georgia';
  static const sans = 'Avenir';

  TextStyle heading(double size) => TextStyle(
        fontFamily: serif,
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: text,
        letterSpacing: 0.2,
      );

  TextStyle label(double size, {Color? color, bool caps = true}) => TextStyle(
        fontFamily: sans,
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color ?? textSoft,
        letterSpacing: caps ? 1.6 : 0.2,
      );

  TextStyle body(double size, {Color? color}) => TextStyle(
        fontFamily: sans,
        fontSize: size,
        fontWeight: FontWeight.w400,
        color: color ?? text,
        height: 1.45,
      );

  // --- shadows (layered, per Stitch DESIGN.md) ------------------------------
  List<BoxShadow> get boardShadow => [
        BoxShadow(
            color: text.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(-6, 14)),
        BoxShadow(
            color: text.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3)),
      ];

  List<BoxShadow> get pieceShadow => [
        BoxShadow(
            color: text.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 8)),
      ];

  List<BoxShadow> get cardShadow => [
        BoxShadow(
            color: text.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3)),
      ];

  ThemeData materialTheme() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: canvas,
      colorScheme: ColorScheme.light(
        primary: primary,
        onPrimary: onPrimary,
        surface: surface,
        onSurface: text,
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

class NordicThemes {
  static const List<NordicThemeDef> all = [
    // The Stitch art direction default (DESIGN.md palette).
    NordicThemeDef(
      id: 'classic',
      name: 'Classic Oak',
      canvas: Color(0xFFFAF7F2),
      surface: Color(0xFFF5F3EF),
      woodLight: Color(0xFFE8DCB8),
      woodMid: Color(0xFFDFD1B5),
      xToken: Color(0xFFC87D55),
      xInk: Color(0xFFFDFAF5),
      oToken: Color(0xFFF5F3EF),
      oInk: Color(0xFF2C2825),
      primary: Color(0xFF2C2825),
      onPrimary: Color(0xFFFDFAF5),
      accent: Color(0xFFC87D55),
      text: Color(0xFF2C2825),
      textSoft: Color(0xFF5A544E),
      sage: Color(0xFF6B7A68),
    ),
    NordicThemeDef(
      id: 'smoked',
      name: 'Smoked Oak',
      canvas: Color(0xFF292019),
      surface: Color(0xFF372B21),
      woodLight: Color(0xFF4A3A2B),
      woodMid: Color(0xFF5F4C37),
      xToken: Color(0xFFC87D55),
      xInk: Color(0xFF211812),
      oToken: Color(0xFFE9DCC4),
      oInk: Color(0xFF292019),
      primary: Color(0xFFC87D55),
      onPrimary: Color(0xFF211812),
      accent: Color(0xFFD89A6E),
      text: Color(0xFFF3EADB),
      textSoft: Color(0xFFB9A98F),
      sage: Color(0xFF8FA084),
    ),
    NordicThemeDef(
      id: 'birch',
      name: 'Birch & Moss',
      canvas: Color(0xFFF7F5EE),
      surface: Color(0xFFFEFDFB),
      woodLight: Color(0xFFF0E8D2),
      woodMid: Color(0xFFD9CBA8),
      xToken: Color(0xFFA9714B),
      xInk: Color(0xFFFEFDFB),
      oToken: Color(0xFFFEFDFB),
      oInk: Color(0xFF5C6E58),
      primary: Color(0xFF3A4A3E),
      onPrimary: Color(0xFFF7F5EE),
      accent: Color(0xFF6B7A68),
      text: Color(0xFF33382F),
      textSoft: Color(0xFF6E7568),
      sage: Color(0xFF6B7A68),
    ),
    NordicThemeDef(
      id: 'fjord',
      name: 'Fjord Stone',
      canvas: Color(0xFFF2F4F6),
      surface: Color(0xFFEDEFF2),
      woodLight: Color(0xFFDCE2E8),
      woodMid: Color(0xFFC3CDD6),
      xToken: Color(0xFF5B6E7E),
      xInk: Color(0xFFF7F9FA),
      oToken: Color(0xFFF7F9FA),
      oInk: Color(0xFF33414E),
      primary: Color(0xFF2E3D4A),
      onPrimary: Color(0xFFF2F4F6),
      accent: Color(0xFF7A93A8),
      text: Color(0xFF2B3640),
      textSoft: Color(0xFF5D6C78),
      sage: Color(0xFF6E8B7A),
    ),
    NordicThemeDef(
      id: 'cherry',
      name: 'Cherrywood',
      canvas: Color(0xFFFAF3EC),
      surface: Color(0xFFF7EDE4),
      woodLight: Color(0xFFEBD3BC),
      woodMid: Color(0xFFD9B797),
      xToken: Color(0xFF8E3B22),
      xInk: Color(0xFFFBF3E8),
      oToken: Color(0xFFF9F1E6),
      oInk: Color(0xFF3A2A22),
      primary: Color(0xFF3A2A22),
      onPrimary: Color(0xFFFAF3EC),
      accent: Color(0xFFB4653A),
      text: Color(0xFF38281F),
      textSoft: Color(0xFF6E5A4C),
      sage: Color(0xFF6B7A68),
    ),
    NordicThemeDef(
      id: 'honey',
      name: 'Honey Pine',
      canvas: Color(0xFFFBF6E9),
      surface: Color(0xFFFDF9F0),
      woodLight: Color(0xFFF3E3BE),
      woodMid: Color(0xFFE4CC97),
      xToken: Color(0xFFC98A2D),
      xInk: Color(0xFF2E2113),
      oToken: Color(0xFFFDF9F0),
      oInk: Color(0xFF4A3A22),
      primary: Color(0xFF4A3A22),
      onPrimary: Color(0xFFFBF6E9),
      accent: Color(0xFFD9A441),
      text: Color(0xFF3A2D18),
      textSoft: Color(0xFF7A6A4E),
      sage: Color(0xFF7A8464),
    ),
    NordicThemeDef(
      id: 'walnut',
      name: 'Walnut & Brass',
      canvas: Color(0xFF241D16),
      surface: Color(0xFF2F261E),
      woodLight: Color(0xFF4E3D2C),
      woodMid: Color(0xFF635038),
      xToken: Color(0xFFC9A227),
      xInk: Color(0xFF241D16),
      oToken: Color(0xFFEDE4D2),
      oInk: Color(0xFF3A2E22),
      primary: Color(0xFFC9A227),
      onPrimary: Color(0xFF241D16),
      accent: Color(0xFFD4AF37),
      text: Color(0xFFEDE4D2),
      textSoft: Color(0xFFAE9C7E),
      sage: Color(0xFF93A086),
    ),
    NordicThemeDef(
      id: 'driftwood',
      name: 'Driftwood',
      canvas: Color(0xFFF4F3F1),
      surface: Color(0xFFECEEEC),
      woodLight: Color(0xFFDEDFD9),
      woodMid: Color(0xFFC6C8BF),
      xToken: Color(0xFF7C8478),
      xInk: Color(0xFFF7F8F5),
      oToken: Color(0xFFF7F8F5),
      oInk: Color(0xFF3C4038),
      primary: Color(0xFF3C4038),
      onPrimary: Color(0xFFF4F3F1),
      accent: Color(0xFF9AA394),
      text: Color(0xFF33362F),
      textSoft: Color(0xFF6B6F64),
      sage: Color(0xFF7C8478),
    ),
    NordicThemeDef(
      id: 'chestnut',
      name: 'Chestnut Hearth',
      canvas: Color(0xFFF7EFE6),
      surface: Color(0xFFF3E8D8),
      woodLight: Color(0xFFE6CFAE),
      woodMid: Color(0xFFD3B68C),
      xToken: Color(0xFFB4653A),
      xInk: Color(0xFFFBF3E8),
      oToken: Color(0xFFFBF3E8),
      oInk: Color(0xFF4A3423),
      primary: Color(0xFF4A3423),
      onPrimary: Color(0xFFF7EFE6),
      accent: Color(0xFFC97F4A),
      text: Color(0xFF402E1E),
      textSoft: Color(0xFF75604A),
      sage: Color(0xFF7A8464),
    ),
    NordicThemeDef(
      id: 'porcelain',
      name: 'Nordic Porcelain',
      canvas: Color(0xFFF6F8FA),
      surface: Color(0xFFFFFFFF),
      woodLight: Color(0xFFE4EAF0),
      woodMid: Color(0xFFC9D6E2),
      xToken: Color(0xFF2F5D8A),
      xInk: Color(0xFFF6F8FA),
      oToken: Color(0xFFF6F8FA),
      oInk: Color(0xFF2F5D8A),
      primary: Color(0xFF2F5D8A),
      onPrimary: Color(0xFFF6F8FA),
      accent: Color(0xFF7FA3C4),
      text: Color(0xFF27333E),
      textSoft: Color(0xFF5F6E7A),
      sage: Color(0xFF6E8B7A),
    ),
  ];

  static NordicThemeDef byId(String id) =>
      all.firstWhere((t) => t.id == id, orElse: () => all.first);
}

/// Marker styles for the X / O pieces. All stay physical — matte materials,
/// no neon, no glow. Rendered in code (Flutter shapes), fitting each theme.
enum MarkerStyle {
  ceramic('Ceramic', 'Matte fired clay, the classic set'),
  chalk('Chalk', 'Hand-drawn chalk on dark slate'),
  carved('Carved Wood', 'Knife-carved oak tokens'),
  ink('Ink & Paper', 'Calligraphy ink on pressed paper'),
  stone('River Stone', 'Smooth tumbled pebbles'),
  porcelain('Porcelain', 'Glazed white with cobalt marks');

  final String name;
  final String blurb;
  const MarkerStyle(this.name, this.blurb);
}
