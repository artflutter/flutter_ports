// Original code, not ported from Chart.js: the CSS conversions of the theme.

/// The conversions of Flutter values to their Chart.js option form (Chart.js
/// ADR 0050, theming.md §3.3).
///
/// - [rawColorOf] gives the [RawThemeColor] of a `Color`, the color token of
///   a raw Map theme of `compile.dart`. [colorToRgba] gives its `rgba()`
///   string through `themeColorToRgba`, the string that the compiled theme
///   holds for the token.
/// - [fontSpecOf] gives the `FontSpec` Map of a `TextStyle`.
///
/// `theme_data.dart` converts the tokens of `ChartThemeData` with these
/// functions. The typed API of Chart.js ADR 0052 converts its values with the
/// same functions, so that a `Color` or a `TextStyle` gives one option value
/// in both places. `test/port/theme/css_test.dart` pins that equality.
///
/// Not a pure layer: the file imports `dart:ui` and the painting library.
/// Ported files never import it (Chart.js ADR 0050, invariant 4). No public
/// library exports it.
library;

import 'dart:ui' show Color, ColorSpace, FontStyle;

import 'package:flutter/painting.dart' show TextStyle;
import 'package:flutter_chartjs_port/src/theme/compile.dart'
    show RawThemeColor, themeColorToRgba;
import 'package:flutter_chartjs_port/src/types/basic.dart';

/// The [RawThemeColor] of [color] through `ColorSpace.extendedSRGB`, or
/// Dart `null`.
///
/// `themeColorToRgba` then clamps the components. A direct conversion to
/// sRGB would only clamp a Display P3 color (theming.md §3.3).
RawThemeColor? rawColorOf(Color? color) {
  if (color == null) return null;
  final srgb = color.withValues(colorSpace: ColorSpace.extendedSRGB);
  return (alpha: srgb.a, red: srgb.r, green: srgb.g, blue: srgb.b);
}

/// The `rgba()` string of [color]: `themeColorToRgba` of [rawColorOf].
///
/// The compiled theme holds this string for a color token of [color], for
/// example `'rgba(54, 162, 235, 1)'` for `Color(0xFF36A2EB)` and
/// `'rgba(0, 0, 0, 0.1)'` for `Color.from(alpha: 0.1, red: 0, green: 0,
/// blue: 0)`.
String colorToRgba(Color color) => themeColorToRgba(rawColorOf(color)!);

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
/// left out with no assert. Each call gives a new Map.
AnyObject? fontSpecOf(TextStyle? font) {
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
