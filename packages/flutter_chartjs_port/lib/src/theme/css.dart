// Original code, not ported from Chart.js: the CSS conversions of the theme.

/// The conversions of Flutter values to their Chart.js option form (Chart.js
/// ADR 0050, theming.md §3.3).
///
/// - [rawColorOf] gives the [RawThemeColor] of a `Color`, the color token of
///   a raw Map theme of `compile.dart`. [colorToRgba] is a legacy formatter
///   for reference tests; compiled themes hold native colors (ADR 0057).
/// - A font has no conversion: the theme, the typed API and the core take
///   the `TextStyle` itself (Chart.js ADR 0116).
///
/// `theme_data.dart` converts the color tokens of `ChartThemeData` with these
/// functions. The typed API of Chart.js ADR 0052 converts its colors with the
/// same functions, so that a `Color` gives one option value in both places.
/// `test/port/theme/css_test.dart` pins that equality.
///
/// Not a pure layer: the file imports `dart:ui`.
/// Ported files never import it (Chart.js ADR 0050, invariant 4). No public
/// library exports it.
library;

import 'dart:ui' show Color, ColorSpace;

import 'package:flutter_chartjs_port/src/theme/compile.dart'
    show RawThemeColor, themeColorToRgba;

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
/// Reference tests can format a color token of [color], for
/// example `'rgba(54, 162, 235, 1)'` for `Color(0xFF36A2EB)` and
/// `'rgba(0, 0, 0, 0.1)'` for `Color.from(alpha: 0.1, red: 0, green: 0,
/// blue: 0)`.
String colorToRgba(Color color) => themeColorToRgba(rawColorOf(color)!);
