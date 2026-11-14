// Original code, not ported from Chart.js: the tokens of the light theme.

/// The tokens of the light preset of Chart.js ADR 0147 (theming.md §5.1), a
/// pure layer.
///
/// The public presets are `ChartThemeData.light()` and `.dark()` of
/// `theme_data.dart`. `ChartThemeData.light()` takes its tokens from
/// [LightThemeTokens], and `.dark()` takes its fonts and its palette from
/// it. The pure tests give the same tokens to `compileChartTheme` of
/// `compile.dart`. The library exports no `LightThemeTokens`. Ported files
/// never import this file (Chart.js ADR 0147, invariant 4).
library;

import 'dart:ui' show Color, FontStyle;

import 'package:flutter/painting.dart' show TextStyle;
import 'package:flutter_chartjs_port/src/types/chart_text_style.dart';

/// The tokens of the light preset at their Chart.js v4.5.1 values
/// (theming.md §4). A chart with them equals an unthemed chart. The tokens
/// restate these values (theming.md §9).
abstract final class LightThemeTokens() {
  /// `Defaults.color` `'#666'` (`core.defaults.js:43`), also the value of
  /// the title and subtitle color routes (`plugin.title.js:158-160`,
  /// `plugin.subtitle.js:45-47`).
  static const Color color = Color.from(
    alpha: 1,
    red: 102 / 255,
    green: 102 / 255,
    blue: 102 / 255,
  );

  /// `Defaults.borderColor` `'rgba(0,0,0,0.1)'` (`core.defaults.js:42`). The
  /// alpha is 0.1 exactly, not the 8-bit alpha of `Color(0x1A000000)`.
  static const Color borderColor = Color.from(
    alpha: 0.1,
    red: 0,
    green: 0,
    blue: 0,
  );

  /// `Defaults.backgroundColor` `'rgba(0,0,0,0.1)'` (`core.defaults.js:41`).
  static const Color backgroundColor = borderColor;

  /// The arc `borderColor` `'#fff'` (`element.arc.ts:379`) and, at alpha
  /// 0.75, the tick backdrop `'rgba(255, 255, 255, 0.75)'`
  /// (`core.scale.defaults.js:81`).
  static const Color surface = Color.from(alpha: 1, red: 1, green: 1, blue: 1);

  /// The tooltip `backgroundColor` `'rgba(0,0,0,0.8)'`
  /// (`plugin.tooltip.js:1279`).
  static const Color inverseSurface = Color.from(
    alpha: 0.8,
    red: 0,
    green: 0,
    blue: 0,
  );

  /// The `'#fff'` of the tooltip `titleColor`, `bodyColor`, `footerColor`
  /// and `multiKeyBackground` (`plugin.tooltip.js:1280, 1287, 1292, 1305`).
  static const Color onInverseSurface = surface;

  /// `Defaults.font` (`core.defaults.js:54-60`), a `ChartTextStyle`
  /// (Chart.js ADR 0116). Its weight is null, which themes nothing: the
  /// title, subtitle, tooltip title and tooltip footer fonts keep their
  /// local `'bold'` (`plugin.title.js:148-150`,
  /// `plugin.tooltip.js:1281-1283, 1295-1297`) and `'normal'`
  /// (`plugin.subtitle.js:35-37`).
  static const TextStyle font = ChartTextStyle(
    fontFamily: 'Helvetica Neue',
    fontFamilyFallback: ['Helvetica', 'Arial', 'sans-serif'],
    fontSize: 12,
    fontStyle: FontStyle.normal,
    height: 1.2,
  );

  /// The point-label size 10 (`scale.radialLinear.js:383-385`).
  static const TextStyle pointLabelsFont = ChartTextStyle(fontSize: 10);

  /// The 7 colors of `BORDER_COLORS` at alpha 1 (`plugin.colors.ts:14-22`).
  /// With [paletteBackgroundAlpha], the compiled background colors equal
  /// `BACKGROUND_COLORS` (`plugin.colors.ts:25`), Chart.js ADR 0147.
  static const List<Color> palette = [
    Color.from(alpha: 1, red: 54 / 255, green: 162 / 255, blue: 235 / 255),
    Color.from(alpha: 1, red: 255 / 255, green: 99 / 255, blue: 132 / 255),
    Color.from(alpha: 1, red: 255 / 255, green: 159 / 255, blue: 64 / 255),
    Color.from(alpha: 1, red: 255 / 255, green: 205 / 255, blue: 86 / 255),
    Color.from(alpha: 1, red: 75 / 255, green: 192 / 255, blue: 192 / 255),
    Color.from(alpha: 1, red: 153 / 255, green: 102 / 255, blue: 255 / 255),
    Color.from(alpha: 1, red: 201 / 255, green: 203 / 255, blue: 207 / 255),
  ];

  /// The alpha 0.5 of `BACKGROUND_COLORS` (`plugin.colors.ts:25`).
  static const double paletteBackgroundAlpha = 0.5;
}
