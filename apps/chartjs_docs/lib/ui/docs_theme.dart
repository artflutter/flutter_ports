// Original code, not ported from Chart.js: the look of the docs site.

import 'package:material_ui/material_ui.dart';

/// The colors of the chart benchmark lab.
abstract final class DocColors() {
  /// The text color.
  static const ink = Color(0xff17243b);

  /// The color of secondary text.
  static const muted = Color(0xff64748b);

  /// The page background.
  static const page = Color(0xfff4f6fa);

  /// The color of the card borders.
  static const border = Color(0xffe1e6ef);

  /// The accent color.
  static const primary = Color(0xff4f46e5);

  /// A light tint of [primary].
  static const primarySoft = Color(0xffeef2ff);

  /// The background of a code panel.
  static const code = Color(0xfff8fafc);
}

/// The font of code.
const String monoFont = 'RobotoMono';

/// The style of a small label above a block.
const TextStyle eyebrow = TextStyle(
  fontSize: 10,
  fontWeight: FontWeight.w700,
  letterSpacing: 1.1,
  color: DocColors.muted,
);

/// The theme of the site: the theme of the chart benchmark lab.
ThemeData docsTheme() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: DocColors.primary),
  scaffoldBackgroundColor: DocColors.page,
  cardTheme: CardThemeData(
    elevation: 0,
    margin: EdgeInsets.zero,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: DocColors.border),
    ),
  ),
  textTheme: ThemeData.light().textTheme.apply(
    bodyColor: DocColors.ink,
    displayColor: DocColors.ink,
  ),
);
