// Ported from d3-interpolate v3.0.1 src/color.js (ISC, Mike Bostock).

/// Port of `src/color.js` of d3-interpolate 3.0.1: the channel interpolators
/// of the color interpolators.
///
/// [nogamma] interpolates a channel linearly, [hue] takes the shortest path
/// between two angles in degrees, and [gamma] makes a channel interpolator
/// with a gamma correction. A NaN channel (an undefined channel of d3-color)
/// takes the channel of the other color. index.dart does not export these
/// functions, as upstream index.js does not.
library;

import 'dart:math' as math;

/// The interpolator of one channel: the closure of color.js `linear`,
/// `exponential` or `constant` as one object of one class.
///
/// A color interpolator calls four channel interpolators at each call. Calls
/// of four closures are four indirect calls; [call] of this final class is a
/// direct call that the compilers can inline.
// DIVERGES(d3-interpolate): adapt-interpolate-channel-objects, one class.
final class const Channel._(
  /// 0 for `linear`, 1 for `constant` and 2 for `exponential`.
  final int _kind,

  /// `a` of `linear` and `exponential`, or `x` of `constant`.
  final double _a,

  /// `d` of `linear`, or `b` of `exponential`.
  final double _d,

  /// `y` of `exponential`.
  final double _y,
) {
  /// The value of the channel at [t]: the line of the closure of color.js.
  double call(double t) {
    if (_kind == 0) return _a + t * _d;
    if (_kind == 1) return _a;
    return math.pow(_a + t * _d, _y).toDouble();
  }
}

/// color.js:3 `linear(a, d)`: `a + t * d`.
Channel _linear(double a, double d) => Channel._(0, a, d, 0);

/// constant.js:1 `constant(x)` of a channel: [x] at each `t`.
Channel _constant(double x) => Channel._(1, x, 0, 0);

/// color.js:9 `exponential(a, b, y)`: the interpolation of `a^y` and `b^y`,
/// raised to `1 / y`.
Channel _exponential(double a, double b, double y) {
  // DIVERGES(d3-interpolate): platform-interpolate-math-last-bit, pow.
  final a1 = math.pow(a, y).toDouble();
  final b1 = math.pow(b, y).toDouble() - a1;
  final y1 = 1 / y;
  return Channel._(2, a1, b1, y1);
}

/// color.js:15 `hue(a, b)`: the interpolator from the angle [a] to the angle
/// [b] in degrees along the shortest path, so a difference above 180 or
/// below -180 wraps by a multiple of 360. The result does not wrap to
/// [0, 360). A NaN angle takes the other angle.
Channel hue(double a, double b) {
  final d = b - a;
  // `d ?`: the test of a number (D3 ADR 0007 §4).
  return d != 0 && !d.isNaN
      ? _linear(a, d > 180 || d < -180 ? d - 360 * _mathRound(d / 360) : d)
      : _constant(a.isNaN ? b : a);
}

/// color.js:20 `gamma(y)`: the channel interpolator factory with the gamma
/// [y]. A gamma of 1 is [nogamma]; another gamma interpolates `a^y` and
/// `b^y` and raises the result to `1 / y`.
Channel Function(double a, double b) gamma(double y) {
  // DIVERGES(d3-interpolate): adapt-interpolate-typed-values, no +y.
  return y == 1
      ? nogamma
      : (a, b) {
          final d = b - a;
          return d != 0 && !d.isNaN
              ? _exponential(a, b, y)
              : _constant(a.isNaN ? b : a);
        };
}

/// color.js:26 the default export `nogamma(a, b)`: the linear interpolator
/// from [a] to [b]. A NaN channel takes the other channel; two equal
/// channels give a constant.
Channel nogamma(double a, double b) {
  final d = b - a;
  return d != 0 && !d.isNaN ? _linear(a, d) : _constant(a.isNaN ? b : a);
}

/// `Math.round(x)` of color.js:17: the whole number nearest to [x], where a
/// half rounds toward positive infinity.
///
/// [double.roundToDouble] rounds a half away from zero (D3 ADR 0007 §4). For
/// `d / 360 = -1.5` that changes the direction of the hue path, so a
/// negative half (`r - x` is exactly -0.5) takes the whole number above.
double _mathRound(double x) {
  final r = x.roundToDouble();
  return r - x == -0.5 ? -(-r - 1) : r;
}
