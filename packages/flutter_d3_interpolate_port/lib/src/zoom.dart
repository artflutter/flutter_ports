// Ported from d3-interpolate v3.0.1 src/zoom.js (ISC, Mike Bostock).

/// Port of `src/zoom.js` of d3-interpolate 3.0.1: the smooth zoom and pan of
/// van Wijk and Nuij between two views, [interpolateZoom].
///
/// A view is the record [ZoomView] `(ux, uy, w)` in place of the upstream
/// array `[ux, uy, w]` (the row `adapt-interpolate-zoom-records`). The
/// upstream functions with the properties `duration` and `rho` are the
/// callable classes [ZoomInterpolator] and [InterpolateZoom] (the row
/// `adapt-interpolate-function-properties`).
library;

import 'dart:math' as math;

/// zoom.js:1 `epsilon2`: the squared distance below which two centers are
/// the same point.
const double _epsilon2 = 1e-12;

/// zoom.js:3 `cosh(x)`.
double _cosh(double x) {
  // DIVERGES(d3-interpolate): platform-interpolate-math-last-bit, exp.
  final e = math.exp(x);
  return (e + 1 / e) / 2;
}

/// zoom.js:7 `sinh(x)`.
double _sinh(double x) {
  // DIVERGES(d3-interpolate): platform-interpolate-math-last-bit, exp.
  final e = math.exp(x);
  return (e - 1 / e) / 2;
}

/// zoom.js:11 `tanh(x)`.
double _tanh(double x) {
  // DIVERGES(d3-interpolate): platform-interpolate-math-last-bit, exp.
  final e = math.exp(2 * x);
  return (e - 1) / (e + 1);
}

/// zoom.js:17 the view `[ux, uy, w]` of upstream: the center `(ux, uy)` of
/// the viewport and its width `w`.
///
/// For example, `(480.0, 250.0, 960.0)` is a viewport of width 960 around
/// the point (480, 250).
// DIVERGES(d3-interpolate): adapt-interpolate-zoom-records, a record.
typedef ZoomView = (double, double, double);

/// zoom.js:31 and zoom.js:48 the interpolator `i` of [InterpolateZoom.call]
/// with its property `duration` (zoom.js:60).
///
/// A call with t in [0, 1] returns the view at t: the start view at 0 and
/// the end view at 1. Each call returns a new record.
// DIVERGES(d3-interpolate): adapt-interpolate-function-properties, a class.
final class ZoomInterpolator._(
  /// The function `i` of upstream.
  final ZoomView Function(double t) _i,

  /// zoom.js:60 `i.duration`: the recommended duration of the transition in
  /// milliseconds, `S * 1000 * rho / sqrt(2)` for the length `S` of the
  /// path. For example, the zoom from `(0, 0, 1)` to `(0, 0, 2)` takes about
  /// 490 ms.
  final double duration,
) {
  /// The view at [t].
  ZoomView call(double t) => _i(t);
}

/// zoom.js:15 `zoomRho(rho, rho2, rho4)`: the zoom interpolator of the
/// curvature `rho`, with `rho2 = rho * rho` and `rho4 = rho2 * rho2`.
///
/// It is callable as the upstream function `zoom(p0, p1)`, and [rho] is the
/// upstream property `zoom.rho`. The default is [interpolateZoom].
// DIVERGES(d3-interpolate): adapt-interpolate-function-properties, a class.
final class const InterpolateZoom._(
  /// `rho`: the curvature.
  final double _rho,

  /// `rho2`: `rho * rho`.
  final double _rho2,

  /// `rho4`: `rho2 * rho2`.
  final double _rho4,
) {
  /// zoom.js:19 `zoom(p0, p1)`: the interpolator from the view [p0] to the
  /// view [p1] along the smooth path of "Smooth and efficient zooming and
  /// panning" (van Wijk and Nuij, 2003). The path zooms out, pans and zooms
  /// in.
  ///
  /// Two centers closer than 1e-6 take the path of a plain zoom (zoom.js:29).
  ZoomInterpolator call(ZoomView p0, ZoomView p1) {
    final ux0 = p0.$1;
    final uy0 = p0.$2;
    final w0 = p0.$3;
    final ux1 = p1.$1;
    final uy1 = p1.$2;
    final w1 = p1.$3;
    final dx = ux1 - ux0;
    final dy = uy1 - uy0;
    final d2 = dx * dx + dy * dy;
    final rho = _rho;
    final rho2 = _rho2;
    final rho4 = _rho4;
    ZoomView Function(double t) i;
    double S;

    // Special case for u0 ≅ u1.
    if (d2 < _epsilon2) {
      // DIVERGES(d3-interpolate): platform-interpolate-math-last-bit, log, exp.
      S = math.log(w1 / w0) / rho;
      i = (t) => (ux0 + t * dx, uy0 + t * dy, w0 * math.exp(rho * t * S));
    }
    // General case.
    else {
      final d1 = math.sqrt(d2);
      final b0 = (w1 * w1 - w0 * w0 + rho4 * d2) / (2 * w0 * rho2 * d1);
      final b1 = (w1 * w1 - w0 * w0 - rho4 * d2) / (2 * w1 * rho2 * d1);
      // DIVERGES(d3-interpolate): platform-interpolate-math-last-bit, log.
      final r0 = math.log(math.sqrt(b0 * b0 + 1) - b0);
      final r1 = math.log(math.sqrt(b1 * b1 + 1) - b1);
      S = (r1 - r0) / rho;
      i = (t) {
        final s = t * S;
        final coshr0 = _cosh(r0);
        final u = w0 / (rho2 * d1) * (coshr0 * _tanh(rho * s + r0) - _sinh(r0));
        return (ux0 + u * dx, uy0 + u * dy, w0 * coshr0 / _cosh(rho * s + r0));
      };
    }

    return ZoomInterpolator._(i, S * 1000 * rho / math.sqrt2);
  }

  /// zoom.js:65 `zoom.rho(rho)`: the zoom interpolator of the curvature
  /// [rho], at least 1e-3. A curvature near 0 zooms and pans at the same
  /// time, almost linearly; a larger one zooms out further.
  InterpolateZoom rho(double rho) {
    final rho1 = math.max(1e-3, rho);
    final rho2 = rho1 * rho1;
    final rho4 = rho2 * rho2;
    return InterpolateZoom._(rho1, rho2, rho4);
  }
}

/// zoom.js:15 the default export: the zoom interpolator of the curvature
/// `sqrt(2)` (zoom.js:71), the value that van Wijk and Nuij recommend.
///
/// ```dart
/// final i = interpolateZoom((30.0, 30.0, 40.0), (135.0, 85.0, 60.0));
/// final (ux, uy, w) = i(0.5); // the view half way
/// final ms = i.duration; // the recommended duration
/// final slow = interpolateZoom.rho(2)((0.0, 0.0, 1.0), (10.0, 0.0, 8.0));
/// ```
const InterpolateZoom interpolateZoom = InterpolateZoom._(math.sqrt2, 2, 4);
