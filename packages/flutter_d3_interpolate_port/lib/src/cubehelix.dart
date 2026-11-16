// Ported from d3-interpolate v3.0.1 src/cubehelix.js (ISC, Mike Bostock).

/// Port of `src/cubehelix.js` of d3-interpolate 3.0.1: the Cubehelix
/// interpolators [interpolateCubehelix] (the shortest hue path) and
/// [cubehelixLong], each with its gamma.
///
/// The interpolators take d3-color [Color] values and return a [Cubehelix]:
/// a new object at each call. Upstream returns the CSS text of one color
/// object that each call writes again; here `toString()` of the result gives
/// that text (decisions 1 and 2 of the design).
library;

import 'dart:math' as math;

import 'package:flutter_d3_color_port/d3_color.dart' show Color, Cubehelix;
import 'package:flutter_d3_interpolate_port/src/color.dart'
    show Channel, hue, nogamma;

/// cubehelix.js:4 `cubehelix(hue)` with cubehelix.js:5 `cubehelixGamma(y)`:
/// a Cubehelix interpolator factory with the hue interpolation of its kind
/// and the gamma of its creation.
///
/// Call it as a function of two colors, `interpolateCubehelix(a, b)`, and
/// give another gamma with [gamma], `interpolateCubehelix.gamma(3)(a, b)`.
/// The two kinds are the constants [interpolateCubehelix] and
/// [cubehelixLong].
// DIVERGES(d3-interpolate): adapt-interpolate-function-properties, a class.
final class const InterpolateCubehelix._(
  final Channel Function(double a, double b) _hue,
  final double _y,
) {
  /// cubehelix.js:8 `cubehelix(start, end)`: the interpolator from [start]
  /// to [end] in Cubehelix.
  ///
  /// Both colors convert to Cubehelix with `Cubehelix.from`. The hue
  /// interpolates with the hue interpolation of this factory, the
  /// saturation and the opacity linearly, and the lightness linearly in
  /// `pow(t, gamma)`. A NaN channel of one color takes the channel of the
  /// other. Each call of the interpolator returns a new [Cubehelix], whose
  /// `toString()` is the RGB text of upstream.
  Cubehelix Function(double t) call(Color start, Color end) {
    // cubehelix.js:6 `y = +y`: the gamma is a double, with no coercion.
    // DIVERGES(d3-interpolate): adapt-interpolate-typed-values, no `+y`.
    final y = _y;
    final st = Cubehelix.from(start);
    final e = Cubehelix.from(end);
    final h = _hue(st.h, e.h);
    final s = nogamma(st.s, e.s);
    final l = nogamma(st.l, e.l);
    final opacity = nogamma(st.opacity, e.opacity);
    // DIVERGES(d3-interpolate): adapt-interpolate-color-values, a new color.
    // DIVERGES(d3-interpolate): platform-interpolate-math-last-bit, the pow.
    return (t) =>
        Cubehelix(h(t), s(t), l(math.pow(t, y).toDouble()), opacity(t));
  }

  /// cubehelix.js:22 `cubehelix.gamma` (`cubehelixGamma(y)`,
  /// cubehelix.js:5): a new Cubehelix interpolator factory of the same hue
  /// interpolation with the gamma [y].
  ///
  /// The lightness interpolates in `pow(t, y)`: a gamma above 1 emphasizes
  /// the high intensities.
  ///
  /// A gamma of NaN or ±Infinity gives another result than upstream on the
  /// VM and with dart2wasm: `pow(1, y)` and `pow(-1, ±Infinity)` of
  /// `dart:math` are 1 there. So the lightness is `l(1)`, the lightness of
  /// the end color, at t = 1 for a gamma of NaN or ±Infinity and at t = -1
  /// for ±Infinity, where upstream gives a NaN lightness, the text
  /// `'rgb(0, 0, 0)'`. DDC and dart2js call JavaScript `Math.pow` and give
  /// the upstream result (the row `platform-interpolate-math-last-bit`).
  InterpolateCubehelix gamma(double y) => InterpolateCubehelix._(_hue, y);
}

/// cubehelix.js:28 the default export, `cubehelix(hue)`: the Cubehelix
/// interpolator factory on the shortest path between the hues, with the
/// gamma 1.
///
/// ```dart
/// final i = interpolateCubehelix(color('purple')!, color('orange')!);
/// i(0.2).toString(); // 'rgb(208, 1, 127)'
/// ```
const InterpolateCubehelix interpolateCubehelix = InterpolateCubehelix._(
  hue,
  1,
);

/// cubehelix.js:29 `cubehelixLong`, exported as `interpolateCubehelixLong`
/// (index.js:19): as [interpolateCubehelix], but the hue interpolates
/// linearly, not on the shortest path.
const InterpolateCubehelix cubehelixLong = InterpolateCubehelix._(nogamma, 1);
