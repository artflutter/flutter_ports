// Original code, not ported from Chart.js: theme data of Chart.js ADR 0147.

/// The public theme data of Chart.js ADR 0147 (theming.md §4 and §5.1).
///
/// [ChartThemeData] holds the tokens of a chart theme: 6 colors, 2 fonts and
/// the palette of the colors plugin. It stores the values of the app and
/// nothing derived. [compileThemeData] gives its fields to
/// `compileChartTheme` of `compile.dart` (Chart.js ADR 0147 §10). The chart
/// reads the result under `themeConfigKey` of `core.config.dart`.
///
/// Not a pure layer: the file imports `dart:ui` and the painting library.
/// Ported files never import it (Chart.js ADR 0147, invariant 4).
library;

import 'dart:ui' show Color, lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show ColorProperty, TextStyle;
import 'package:flutter_chartjs_port/src/options/scopes.g.dart'
    show ChartOptionsScope;
import 'package:flutter_chartjs_port/src/theme/compile.dart';
import 'package:flutter_chartjs_port/src/theme/presets.dart';

/// The tokens of a chart theme (Chart.js ADR 0147, theming.md §4).
///
/// A null token themes nothing. The Chart.js options of a chart beat each
/// key of the theme, key by key: the dataset, the user options and
/// `overrides[type]` come before the theme, and `defaults` after it
/// (theming.md §3.2).
@immutable
class const ChartThemeData({
  /// Replaces `Defaults.color` `'#666'` (`core.defaults.js:43`): the ticks,
  /// the scale titles, the point labels, the legend, the title and the
  /// subtitle.
  final Color? color,

  /// Replaces `Defaults.borderColor` (`core.defaults.js:42`): the grid, the
  /// scale border, the angle lines and the borders of points, lines and
  /// bars.
  final Color? borderColor,

  /// Replaces `Defaults.backgroundColor` (`core.defaults.js:41`) of the four
  /// elements.
  final Color? backgroundColor,

  /// Replaces the arc border `'#fff'` (`element.arc.ts:379`) and, at alpha
  /// 0.75, the tick backdrop (`core.scale.defaults.js:81`).
  final Color? surface,

  /// Replaces the tooltip background `'rgba(0,0,0,0.8)'`
  /// (`plugin.tooltip.js:1279`).
  final Color? inverseSurface,

  /// Replaces the `'#fff'` of the tooltip texts and of `multiKeyBackground`
  /// (`plugin.tooltip.js:1280, 1287, 1292, 1305`).
  final Color? onInverseSurface,

  /// Replaces `Defaults.font` (`core.defaults.js:54-60`).
  ///
  /// The chart takes the `TextStyle` itself (Chart.js ADR 0116): it lays out
  /// the texts with it, and its line height in pixels is `fontSize *
  /// height`. Thus an app can give a `TextStyle` of its text theme. The
  /// color of the texts is [color], not the color of the `TextStyle`.
  final TextStyle? font,

  /// The point-label font of the radial linear scale, over [font] without
  /// its size (`scale.radialLinear.js:383-385`, theming.md §3.4).
  final TextStyle? pointLabelsFont,

  /// The palette of the colors plugin (`plugin.colors.ts:14-22`).
  ///
  /// Null and an empty list keep the Chart.js palette. The plugin colors
  /// only datasets with no colors (`plugin.colors.ts:102-125`). Do not
  /// change the list after the construction: the compiled theme is kept for
  /// each instance.
  final List<Color>? palette,

  /// The alpha of the background colors of [palette]
  /// (`plugin.colors.ts:25`), from 0 to 1. No effect without [palette].
  final double paletteBackgroundAlpha = 0.5,
}) with Diagnosticable {
  /// A theme of the given tokens. `const ChartThemeData()` themes nothing:
  /// a chart with it equals an unthemed chart.
  ///
  /// [paletteBackgroundAlpha] is a number from 0 to 1. A debug assert
  /// checks it.
  this
    : assert(
        paletteBackgroundAlpha >= 0 && paletteBackgroundAlpha <= 1,
        'paletteBackgroundAlpha is a number from 0 to 1',
      );

  /// The Chart.js v4.6.1 defaults and the 7 colors of
  /// `plugin.colors.ts:14-22`. A chart with it equals an unthemed chart.
  ///
  /// The tokens: [color] `'#666'` (`core.defaults.js:43`), [borderColor] and
  /// [backgroundColor] `'rgba(0,0,0,0.1)'` (`core.defaults.js:41-42`, the
  /// alpha 0.1 exactly), [surface] `'#fff'` (`element.arc.ts:379`),
  /// [inverseSurface] `'rgba(0,0,0,0.8)'` (`plugin.tooltip.js:1279`),
  /// [onInverseSurface] `'#fff'` (`plugin.tooltip.js:1280`), [font]
  /// `Defaults.font` (`core.defaults.js:54-60`, no weight), [pointLabelsFont]
  /// the size 10 (`scale.radialLinear.js:383-385`) and [palette] the colors
  /// of `BORDER_COLORS` at alpha 1 with the alpha 0.5 of `BACKGROUND_COLORS`
  /// (`plugin.colors.ts:14-25`).
  const new light()
    : this(
        color: LightThemeTokens.color,
        borderColor: LightThemeTokens.borderColor,
        backgroundColor: LightThemeTokens.backgroundColor,
        surface: LightThemeTokens.surface,
        inverseSurface: LightThemeTokens.inverseSurface,
        onInverseSurface: LightThemeTokens.onInverseSurface,
        font: LightThemeTokens.font,
        pointLabelsFont: LightThemeTokens.pointLabelsFont,
        palette: LightThemeTokens.palette,
        paletteBackgroundAlpha: LightThemeTokens.paletteBackgroundAlpha,
      );

  /// The dark preset: each color token of [ChartThemeData.light] with red,
  /// green and blue mirrored (1 - x) and its alpha kept, the fonts of light,
  /// the Chart.js palette and the Chart.js hover colors.
  ///
  /// The tokens: [color] `#999999`, [borderColor] and [backgroundColor]
  /// white at alpha 0.1, [surface] `#000000`, [inverseSurface] white at
  /// alpha 0.8 and [onInverseSurface] `#000000`. Set [surface] with
  /// [copyWith] for another background.
  const new dark()
    : this(
        color: const Color.from(
          alpha: 1,
          red: 153 / 255,
          green: 153 / 255,
          blue: 153 / 255,
        ),
        borderColor: _white10,
        backgroundColor: _white10,
        surface: _black,
        inverseSurface: _white80,
        onInverseSurface: _black,
        font: LightThemeTokens.font,
        pointLabelsFont: LightThemeTokens.pointLabelsFont,
        palette: LightThemeTokens.palette,
        paletteBackgroundAlpha: LightThemeTokens.paletteBackgroundAlpha,
      );

  /// A copy with the given tokens. A null argument keeps the token.
  ChartThemeData copyWith({
    Color? color,
    Color? borderColor,
    Color? backgroundColor,
    Color? surface,
    Color? inverseSurface,
    Color? onInverseSurface,
    TextStyle? font,
    TextStyle? pointLabelsFont,
    List<Color>? palette,
    double? paletteBackgroundAlpha,
  }) => ChartThemeData(
    color: color ?? this.color,
    borderColor: borderColor ?? this.borderColor,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    surface: surface ?? this.surface,
    inverseSurface: inverseSurface ?? this.inverseSurface,
    onInverseSurface: onInverseSurface ?? this.onInverseSurface,
    font: font ?? this.font,
    pointLabelsFont: pointLabelsFont ?? this.pointLabelsFont,
    palette: palette ?? this.palette,
    paletteBackgroundAlpha:
        paletteBackgroundAlpha ?? this.paletteBackgroundAlpha,
  );

  /// Interpolates [a] and [b]. Gives [a] for `identical(a, b)`, as
  /// `ThemeData.lerp` does: `Color.lerp(c, c, t)` is not always `c`.
  ///
  /// A token interpolates when both ends have it, else it switches at
  /// `t = 0.5`: a null token means the Chart.js value, and `Color.lerp` of
  /// a null end would fade the alpha. The colors interpolate with
  /// `Color.lerp` and the fonts with `TextStyle.lerp`. Two fonts switch at
  /// 0.5 when one of them sets `fontSize`, `fontWeight` or `height` and the
  /// other does not. Palettes of one length interpolate pairwise, else they
  /// switch at 0.5.
  /// [paletteBackgroundAlpha] interpolates, clamped to the range from 0 to
  /// 1. Each new theme compiles anew and costs one chart update.
  // The static form of `ThemeData.lerp` and `IconThemeData.lerp`.
  // ignore: prefer_constructors_over_static_methods
  static ChartThemeData lerp(ChartThemeData a, ChartThemeData b, double t) {
    if (identical(a, b)) return a;
    return ChartThemeData(
      color: _lerpColor(a.color, b.color, t),
      borderColor: _lerpColor(a.borderColor, b.borderColor, t),
      backgroundColor: _lerpColor(a.backgroundColor, b.backgroundColor, t),
      surface: _lerpColor(a.surface, b.surface, t),
      inverseSurface: _lerpColor(a.inverseSurface, b.inverseSurface, t),
      onInverseSurface: _lerpColor(a.onInverseSurface, b.onInverseSurface, t),
      font: _lerpFont(a.font, b.font, t),
      pointLabelsFont: _lerpFont(a.pointLabelsFont, b.pointLabelsFont, t),
      palette: _lerpPalette(a.palette, b.palette, t),
      paletteBackgroundAlpha: clampDouble(
        lerpDouble(a.paletteBackgroundAlpha, b.paletteBackgroundAlpha, t)!,
        0,
        1,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is ChartThemeData &&
        other.color == color &&
        other.borderColor == borderColor &&
        other.backgroundColor == backgroundColor &&
        other.surface == surface &&
        other.inverseSurface == inverseSurface &&
        other.onInverseSurface == onInverseSurface &&
        other.font == font &&
        other.pointLabelsFont == pointLabelsFont &&
        listEquals(other.palette, palette) &&
        other.paletteBackgroundAlpha == paletteBackgroundAlpha;
  }

  @override
  int get hashCode {
    final palette = this.palette;
    return Object.hash(
      color,
      borderColor,
      backgroundColor,
      surface,
      inverseSurface,
      onInverseSurface,
      font,
      pointLabelsFont,
      palette == null ? null : Object.hashAll(palette),
      paletteBackgroundAlpha,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ColorProperty('color', color, defaultValue: null))
      ..add(ColorProperty('borderColor', borderColor, defaultValue: null))
      ..add(
        ColorProperty('backgroundColor', backgroundColor, defaultValue: null),
      )
      ..add(ColorProperty('surface', surface, defaultValue: null))
      ..add(ColorProperty('inverseSurface', inverseSurface, defaultValue: null))
      ..add(
        ColorProperty('onInverseSurface', onInverseSurface, defaultValue: null),
      )
      ..add(DiagnosticsProperty<TextStyle>('font', font, defaultValue: null))
      ..add(
        DiagnosticsProperty<TextStyle>(
          'pointLabelsFont',
          pointLabelsFont,
          defaultValue: null,
        ),
      )
      ..add(IterableProperty<Color>('palette', palette, defaultValue: null))
      ..add(
        DoubleProperty(
          'paletteBackgroundAlpha',
          paletteBackgroundAlpha,
          defaultValue: 0.5,
        ),
      );
  }
}

/// Black: `'#000'`, the mirror of the white of the light preset.
const Color _black = Color.from(alpha: 1, red: 0, green: 0, blue: 0);

/// White at alpha 0.1, the mirror of the black at alpha 0.1 of the light
/// preset (`'rgba(0,0,0,0.1)'`, the alpha 0.1 exactly).
const Color _white10 = Color.from(alpha: 0.1, red: 1, green: 1, blue: 1);

/// White at alpha 0.8, the mirror of the black at alpha 0.8 of the light
/// preset (`'rgba(0,0,0,0.8)'`).
const Color _white80 = Color.from(alpha: 0.8, red: 1, green: 1, blue: 1);

/// The interpolation of a color token: `Color.lerp` when both ends have a
/// color, else a switch at 0.5.
Color? _lerpColor(Color? a, Color? b, double t) =>
    a != null && b != null ? Color.lerp(a, b, t) : (t < 0.5 ? a : b);

/// The interpolation of a font token: `TextStyle.lerp` when both ends have
/// a font and each of `fontSize`, `fontWeight` and `height` is set at both
/// ends or at none, else a switch at 0.5.
///
/// `TextStyle.lerp` gives a size or a height that one end lacks from the
/// other end, and a weight that one end lacks as `FontWeight.normal`. Thus
/// `lerp(a, b, 1)` would not be `b`, and the theme would emit a field that
/// the end lacks. The switch keeps the rule of a token with a null end.
TextStyle? _lerpFont(TextStyle? a, TextStyle? b, double t) {
  if (a == null ||
      b == null ||
      (a.fontSize == null) != (b.fontSize == null) ||
      (a.fontWeight == null) != (b.fontWeight == null) ||
      (a.height == null) != (b.height == null)) {
    return t < 0.5 ? a : b;
  }
  return TextStyle.lerp(a, b, t);
}

/// The interpolation of the palette: pairwise for two lists of one length,
/// else a switch at 0.5.
List<Color>? _lerpPalette(List<Color>? a, List<Color>? b, double t) {
  if (a == null || b == null || a.length != b.length) return t < 0.5 ? a : b;
  return [for (var i = 0; i < a.length; i++) Color.lerp(a[i], b[i], t)!];
}

/// The compiled theme scope of [data] for `themeConfigKey`: the fields of
/// [data] given to `compileChartTheme` of `compile.dart` (Chart.js ADR
/// 0147 §10), or Dart `null`. Dart `null` and a theme without tokens, for
/// example `const ChartThemeData()`, give Dart `null`.
///
/// Each call compiles [data]: no memo (judge-c §3.9, Chart.js ADR 0054 §4).
/// The theme switch of `ChartView` keeps the compiled theme of its current
/// theme and compiles again only for a new theme.
@internal
ChartOptionsScope? compileThemeData(ChartThemeData? data) {
  if (data == null) return null;
  return compileChartTheme(
    color: data.color,
    borderColor: data.borderColor,
    backgroundColor: data.backgroundColor,
    surface: data.surface,
    inverseSurface: data.inverseSurface,
    onInverseSurface: data.onInverseSurface,
    font: data.font,
    pointLabelsFont: data.pointLabelsFont,
    palette: data.palette,
    paletteBackgroundAlpha: data.paletteBackgroundAlpha,
  );
}
