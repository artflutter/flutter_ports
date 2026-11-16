// Ported from d3-interpolate v3.0.1 src/rgb.js (ISC, Mike Bostock).

/// Port of `src/rgb.js` of d3-interpolate 3.0.1: the RGB interpolator
/// [interpolateRgb] with its gamma, and the RGB splines
/// [rgbBasis] and [rgbBasisClosed].
///
/// The interpolators take d3-color [Color] values and return an [Rgb]: a new
/// object at each call. Upstream returns the CSS text of one color object
/// that each call writes again; here `toString()` of the result gives that
/// text (decisions 1 and 2 of the design).
library;

import 'package:flutter_d3_color_port/d3_color.dart' show Color, Rgb;
import 'package:flutter_d3_interpolate_port/src/basis.dart'
    show interpolateBasis;
import 'package:flutter_d3_interpolate_port/src/basisClosed.dart'
    show interpolateBasisClosed;
import 'package:flutter_d3_interpolate_port/src/color.dart' show gamma, nogamma;

// The method `gamma` of [InterpolateRgb] hides the function `gamma` of
// color.dart in the class body. The class reads it through this name.
const double Function(double t) Function(double a, double b) Function(double y)
_gamma = gamma;

/// rgb.js:6 the function `rgb` of `rgbGamma(y)`, with its property `gamma`:
/// an RGB interpolator factory with the gamma of its creation.
///
/// Call it as a function of two colors, `interpolateRgb(a, b)`, and give
/// another gamma with [gamma], `interpolateRgb.gamma(2.2)(a, b)`.
// DIVERGES(d3-interpolate): adapt-interpolate-function-properties, a class.
final class const InterpolateRgb._(final double _y) {
  /// rgb.js:9 `rgb(start, end)`: the interpolator from [start] to [end] in
  /// RGB.
  ///
  /// Both colors convert to RGB with `Rgb.from`. The red, green and blue
  /// channels interpolate with the gamma of this factory, and the opacity
  /// linearly. A NaN channel of one color takes the channel of the other.
  /// Each call of the interpolator returns a new [Rgb].
  Rgb Function(double t) call(Color start, Color end) {
    // rgb.js:7 `var color = gamma(y)`, at the creation of the factory
    // upstream: the factory is a constant here.
    final color = _gamma(_y);
    final s = Rgb.from(start);
    final e = Rgb.from(end);
    final r = color(s.r, e.r);
    final g = color(s.g, e.g);
    final b = color(s.b, e.b);
    final opacity = nogamma(s.opacity, e.opacity);
    // DIVERGES(d3-interpolate): adapt-interpolate-color-values, a new Rgb.
    return (t) => Rgb(r(t), g(t), b(t), opacity(t));
  }

  /// rgb.js:23 `rgb.gamma` (`rgbGamma(y)`, rgb.js:6): a new RGB
  /// interpolator factory with the gamma [y].
  ///
  /// A gamma of 1 interpolates the channels linearly, as [interpolateRgb].
  ///
  /// The gamma 0 or -0 gives another result than upstream on the VM and
  /// with dart2wasm: `1 / y` is ±Infinity, and `pow(1, ±Infinity)` of
  /// `dart:math` is 1 there, so each channel that differs between the two
  /// colors is 1 at each finite t: `'rgb(1, 1, 1)'`, where upstream gives
  /// NaN channels, the text `'rgb(0, 0, 0)'`. DDC and dart2js call
  /// JavaScript `Math.pow` and give the upstream result. A gamma of NaN or
  /// ±Infinity gives the upstream results on each platform (the row
  /// `platform-interpolate-math-last-bit`).
  InterpolateRgb gamma(double y) => InterpolateRgb._(y);
}

/// rgb.js:6 the default export, `rgbGamma(1)`: the RGB interpolator factory
/// with the gamma 1.
///
/// ```dart
/// final i = interpolateRgb(color('steelblue')!, color('brown')!);
/// i(0.5).toString(); // 'rgb(118, 86, 111)'
/// ```
const InterpolateRgb interpolateRgb = InterpolateRgb._(1);

/// rgb.js:28 `rgbSpline(spline)`: the RGB spline of [colors] with the
/// number spline [spline] for each channel.
///
/// Upstream returns the function of `colors`; here [colors] is the second
/// parameter of the same function.
Rgb Function(double t) _rgbSpline(
  double Function(double t) Function(List<double> values) spline,
  List<Color> colors,
) {
  final n = colors.length;
  // DIVERGES(d3-interpolate): adapt-interpolate-color-values, no last color.
  if (n == 0) throw ArgumentError.value(colors, 'colors', 'is empty');
  final r = List<double>.filled(n, 0);
  final g = List<double>.filled(n, 0);
  final b = List<double>.filled(n, 0);
  for (var i = 0; i < n; ++i) {
    final color = Rgb.from(colors[i]);
    final cr = color.r;
    final cg = color.g;
    final cb = color.b;
    // `color.r || 0`: 0 for NaN and for 0.
    r[i] = cr.isNaN || cr == 0 ? 0.0 : cr;
    g[i] = cg.isNaN || cg == 0 ? 0.0 : cg;
    b[i] = cb.isNaN || cb == 0 ? 0.0 : cb;
  }
  final rs = spline(r);
  final gs = spline(g);
  final bs = spline(b);
  // rgb.js:44 `color.opacity = 1`: the opacity of each result is 1.
  // DIVERGES(d3-interpolate): adapt-interpolate-color-values, a new Rgb.
  return (t) => Rgb(rs(t), gs(t), bs(t));
}

/// rgb.js:54 `rgbBasis`, exported as `interpolateRgbBasis` (index.js:15): a
/// uniform nonrational B-spline through [colors] in RGB.
///
/// The colors convert to RGB with `Rgb.from`, and a NaN channel counts as
/// 0. The result is `colors[0]` at t = 0 and `colors[colors.length - 1]` at
/// t = 1, with the opacity 1: the spline does not interpolate the opacity.
/// Each call of the interpolator returns a new [Rgb]. [colors] must not be
/// empty: upstream throws there too.
Rgb Function(double t) rgbBasis(List<Color> colors) =>
    _rgbSpline(interpolateBasis, colors);

/// rgb.js:55 `rgbBasisClosed`, exported as `interpolateRgbBasisClosed`
/// (index.js:15): a closed uniform nonrational B-spline through [colors] in
/// RGB.
///
/// The control points repeat, so the spline is cyclic in t. The colors
/// convert to RGB with `Rgb.from`, and a NaN channel counts as 0. The
/// opacity of each result is 1. Each call of the interpolator returns a new
/// [Rgb]. [colors] must not be empty: upstream throws there too.
Rgb Function(double t) rgbBasisClosed(List<Color> colors) =>
    _rgbSpline(interpolateBasisClosed, colors);
