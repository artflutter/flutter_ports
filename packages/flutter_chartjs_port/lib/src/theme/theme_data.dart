// Original code, not ported from Chart.js: theme data of Chart.js ADR 0050.

/// The public theme data of Chart.js ADR 0050 (theming.md §4 and §5.1).
///
/// [ChartThemeData] holds the tokens of a chart theme: 6 colors, 2 fonts and
/// the palette of the colors plugin. It stores the values of the app and
/// nothing derived. [compileThemeData] converts it to the raw Map theme of
/// `compile.dart` ([themeDataToRaw]) and compiles that Map with
/// `compileChartTheme`. The chart reads the result under `themeConfigKey`
/// of `core.config.dart`.
///
/// Not a pure layer: the file imports `dart:ui` and the painting library.
/// Ported files never import it (Chart.js ADR 0042, invariant 4).
library;

import 'dart:ui' show Color, ColorSpace, FontStyle, lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show ColorProperty, TextStyle;
import 'package:flutter_chartjs_port/src/theme/compile.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';

/// The tokens of a chart theme (Chart.js ADR 0050, theming.md §4).
///
/// A null token themes nothing. The Chart.js options of a chart beat each
/// key of the theme, key by key: the dataset, the user options and
/// `overrides[type]` come before the theme, and `defaults` after it
/// (theming.md §3.2).
@immutable
class ChartThemeData with Diagnosticable {
  /// A theme of the given tokens. `const ChartThemeData()` themes nothing:
  /// a chart with it equals an unthemed chart.
  ///
  /// [paletteBackgroundAlpha] is a number from 0 to 1. A debug assert
  /// checks it.
  const ChartThemeData({
    this.color,
    this.borderColor,
    this.backgroundColor,
    this.surface,
    this.inverseSurface,
    this.onInverseSurface,
    this.font,
    this.pointLabelsFont,
    this.palette,
    this.paletteBackgroundAlpha = 0.5,
  }) : assert(
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
  const ChartThemeData.light()
    : this(
        color: const Color.from(
          alpha: 1,
          red: 102 / 255,
          green: 102 / 255,
          blue: 102 / 255,
        ),
        borderColor: _black10,
        backgroundColor: _black10,
        surface: _white,
        inverseSurface: _black80,
        onInverseSurface: _white,
        font: _lightFont,
        pointLabelsFont: _pointLabelsFont,
        palette: _chartJsPalette,
      );

  /// The dark preset: each color token of [ChartThemeData.light] with red,
  /// green and blue mirrored (1 - x) and its alpha kept, the fonts of light,
  /// the Chart.js palette and the Chart.js hover colors.
  ///
  /// The tokens: [color] `#999999`, [borderColor] and [backgroundColor]
  /// white at alpha 0.1, [surface] `#000000`, [inverseSurface] white at
  /// alpha 0.8 and [onInverseSurface] `#000000`. Set [surface] with
  /// [copyWith] for another background.
  const ChartThemeData.dark()
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
        font: _lightFont,
        pointLabelsFont: _pointLabelsFont,
        palette: _chartJsPalette,
      );

  /// Replaces `Defaults.color` `'#666'` (`core.defaults.js:43`): the ticks,
  /// the scale titles, the point labels, the legend, the title and the
  /// subtitle.
  final Color? color;

  /// Replaces `Defaults.borderColor` (`core.defaults.js:42`): the grid, the
  /// scale border, the angle lines and the borders of points, lines and
  /// bars.
  final Color? borderColor;

  /// Replaces `Defaults.backgroundColor` (`core.defaults.js:41`) of the four
  /// elements.
  final Color? backgroundColor;

  /// Replaces the arc border `'#fff'` (`element.arc.ts:379`) and, at alpha
  /// 0.75, the tick backdrop (`core.scale.defaults.js:81`).
  final Color? surface;

  /// Replaces the tooltip background `'rgba(0,0,0,0.8)'`
  /// (`plugin.tooltip.js:1279`).
  final Color? inverseSurface;

  /// Replaces the `'#fff'` of the tooltip texts and of `multiKeyBackground`
  /// (`plugin.tooltip.js:1280, 1287, 1292, 1305`).
  final Color? onInverseSurface;

  /// Replaces `Defaults.font` (`core.defaults.js:54-60`).
  ///
  /// The theme reads `fontFamily`, `fontFamilyFallback`, `fontSize`,
  /// `fontStyle`, `fontWeight` and `height`, and no other field. Thus an app
  /// can give a `TextStyle` of its text theme. A px line height, `'oblique'`
  /// and `'lighter'` stay in the chart options.
  final TextStyle? font;

  /// The point-label font of the radial linear scale, over [font] without
  /// its size (`scale.radialLinear.js:383-385`, theming.md §3.4). It reads
  /// the fields of [font].
  final TextStyle? pointLabelsFont;

  /// The palette of the colors plugin (`plugin.colors.ts:14-22`).
  ///
  /// Null and an empty list keep the Chart.js palette. The plugin colors
  /// only datasets with no colors (`plugin.colors.ts:102-125`). Do not
  /// change the list after the construction: the compiled theme is kept for
  /// each instance.
  final List<Color>? palette;

  /// The alpha of the background colors of [palette]
  /// (`plugin.colors.ts:25`), from 0 to 1. No effect without [palette].
  final double paletteBackgroundAlpha;

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
      ..add(
        ColorProperty('inverseSurface', inverseSurface, defaultValue: null),
      )
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

/// Black at alpha 0.1: `'rgba(0,0,0,0.1)'` with the exact alpha, not the
/// 8-bit alpha of `Color(0x1A000000)` (theming.md §4).
const Color _black10 = Color.from(alpha: 0.1, red: 0, green: 0, blue: 0);

/// Black at alpha 0.8: `'rgba(0,0,0,0.8)'`.
const Color _black80 = Color.from(alpha: 0.8, red: 0, green: 0, blue: 0);

/// Black: `'#000'`.
const Color _black = Color.from(alpha: 1, red: 0, green: 0, blue: 0);

/// White: `'#fff'`.
const Color _white = Color.from(alpha: 1, red: 1, green: 1, blue: 1);

/// White at alpha 0.1, the mirror of [_black10].
const Color _white10 = Color.from(alpha: 0.1, red: 1, green: 1, blue: 1);

/// White at alpha 0.8, the mirror of [_black80].
const Color _white80 = Color.from(alpha: 0.8, red: 1, green: 1, blue: 1);

/// `Defaults.font` (`core.defaults.js:54-60`): the family
/// `"'Helvetica Neue', 'Helvetica', 'Arial', sans-serif"`, the size 12, the
/// style `'normal'` and the line height 1.2. Its weight is null, which
/// themes nothing: the title, subtitle, tooltip title and tooltip footer
/// fonts keep their local weights (theming.md §3.4).
const TextStyle _lightFont = TextStyle(
  fontFamily: 'Helvetica Neue',
  fontFamilyFallback: ['Helvetica', 'Arial', 'sans-serif'],
  fontSize: 12,
  fontStyle: FontStyle.normal,
  height: 1.2,
);

/// The point-label size 10 (`scale.radialLinear.js:383-385`).
const TextStyle _pointLabelsFont = TextStyle(fontSize: 10);

/// `BORDER_COLORS` (`plugin.colors.ts:14-22`) at alpha 1.
const List<Color> _chartJsPalette = [
  Color.from(alpha: 1, red: 54 / 255, green: 162 / 255, blue: 235 / 255),
  Color.from(alpha: 1, red: 255 / 255, green: 99 / 255, blue: 132 / 255),
  Color.from(alpha: 1, red: 255 / 255, green: 159 / 255, blue: 64 / 255),
  Color.from(alpha: 1, red: 255 / 255, green: 205 / 255, blue: 86 / 255),
  Color.from(alpha: 1, red: 75 / 255, green: 192 / 255, blue: 192 / 255),
  Color.from(alpha: 1, red: 153 / 255, green: 102 / 255, blue: 255 / 255),
  Color.from(alpha: 1, red: 201 / 255, green: 203 / 255, blue: 207 / 255),
];

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

/// The compiled theme of each [ChartThemeData] instance, or [_noTheme].
final Expando<Object> _compiled = Expando<Object>('compileThemeData');

/// The memo value of a theme that compiles to Dart `null`.
const Object _noTheme = Object();

/// The compiled theme map of [data] for `themeConfigKey`
/// (`compileChartTheme` of `compile.dart` over [themeDataToRaw]), or Dart
/// `null`. Dart `null` and a theme without tokens, for example
/// `const ChartThemeData()`, give Dart `null`.
///
/// The result is kept for each instance of [data] in an [Expando]. Thus a
/// const preset compiles one time, and the palette list of [data] must not
/// change after its first compile.
@internal
AnyObject? compileThemeData(ChartThemeData? data) {
  if (data == null) return null;
  final memo = _compiled[data];
  if (memo != null) {
    return identical(memo, _noTheme) ? null : memo as AnyObject;
  }
  final result = compileChartTheme(themeDataToRaw(data));
  _compiled[data] = result ?? _noTheme;
  return result;
}

/// The raw Map theme of [data]: the input of `compileChartTheme`
/// (`compile.dart`).
///
/// - `colors`: each color token that is not null, as a [RawThemeColor] of
///   `Color.withValues(colorSpace: ColorSpace.extendedSRGB)`.
///   `themeColorToRgba` then clamps the components. A direct conversion to
///   sRGB would only clamp a Display P3 color (theming.md §3.3).
/// - `typography`: `font` and `pointLabels`, the `FontSpec` Maps of the
///   fonts that are not null ([_fontSpec]).
/// - `palette`: `{colors, backgroundAlpha}` for a non-empty palette.
///
/// A part without a value is left out.
@internal
AnyObject themeDataToRaw(ChartThemeData data) {
  final colors = <String, Object?>{
    'color': ?_rawColor(data.color),
    'borderColor': ?_rawColor(data.borderColor),
    'backgroundColor': ?_rawColor(data.backgroundColor),
    'surface': ?_rawColor(data.surface),
    'inverseSurface': ?_rawColor(data.inverseSurface),
    'onInverseSurface': ?_rawColor(data.onInverseSurface),
  };
  final typography = <String, Object?>{
    'font': ?_fontSpec(data.font),
    'pointLabels': ?_fontSpec(data.pointLabelsFont),
  };
  final palette = data.palette;
  return <String, Object?>{
    if (colors.isNotEmpty) 'colors': colors,
    if (typography.isNotEmpty) 'typography': typography,
    if (palette != null && palette.isNotEmpty)
      'palette': <String, Object?>{
        'colors': <Object?>[for (final color in palette) _rawColor(color)],
        'backgroundAlpha': data.paletteBackgroundAlpha,
      },
  };
}

/// The [RawThemeColor] of [color] through `ColorSpace.extendedSRGB`, or
/// Dart `null`.
RawThemeColor? _rawColor(Color? color) {
  if (color == null) return null;
  final srgb = color.withValues(colorSpace: ColorSpace.extendedSRGB);
  return (alpha: srgb.a, red: srgb.r, green: srgb.g, blue: srgb.b);
}

/// The CSS generic families (CSS Fonts 4 §4.2), the names that the family
/// string gives without quotes. The canvas layer knows the same names.
const Set<String> _genericFamilies = {
  'serif',
  'sans-serif',
  'monospace',
  'cursive',
  'fantasy',
  'system-ui',
  'ui-serif',
  'ui-sans-serif',
  'ui-monospace',
  'ui-rounded',
  'math',
  'emoji',
  'fangsong',
};

/// The `FontSpec` Map of [font] (`index.d.ts:1817-1836`), or Dart `null`.
///
/// The keys come in the order `family`, `size`, `style`, `weight`,
/// `lineHeight`, each only for a field that is not null:
/// - `family`: `fontFamily` and `fontFamilyFallback`, joined with `', '`.
///   Each name is in single quotes (in double quotes when it holds a single
///   quote), except a CSS generic family. An empty name is left out.
/// - `size`: `fontSize`.
/// - `style`: `'italic'` for `FontStyle.italic`, else `'normal'`.
/// - `weight`: `fontWeight.value` as a number.
/// - `lineHeight`: `height`, a factor of the size.
///
/// The other fields of [font], for example `color` and `letterSpacing`, are
/// left out with no assert.
AnyObject? _fontSpec(TextStyle? font) {
  if (font == null) return null;
  final names = [
    ?font.fontFamily,
    ...?font.fontFamilyFallback,
  ].where((name) => name.isNotEmpty);
  final fontStyle = font.fontStyle;
  return <String, Object?>{
    if (names.isNotEmpty) 'family': names.map(_familyName).join(', '),
    'size': ?font.fontSize,
    if (fontStyle != null)
      'style': fontStyle == FontStyle.italic ? 'italic' : 'normal',
    'weight': ?font.fontWeight?.value.toDouble(),
    'lineHeight': ?font.height,
  };
}

/// The CSS form of the family [name] in a family list.
String _familyName(String name) {
  if (_genericFamilies.contains(name.toLowerCase())) return name;
  return name.contains("'") ? '"$name"' : "'$name'";
}
