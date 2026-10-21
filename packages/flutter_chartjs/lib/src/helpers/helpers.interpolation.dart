// Ported from Chart.js v4.5.1+7169e651 src/helpers/helpers.interpolation.ts (MIT, Chart.js Contributors).

/// Port of `src/helpers/helpers.interpolation.ts`.
///
/// `element.line.js:195-205` selects one of the three functions and calls it
/// with four arguments: `_interpolate(p1, p2, t, options.stepped)`
/// (element.line.js:373). Thus each function takes the fourth argument
/// `mode`, also where it does not read it. Its type is `Object?`, because
/// `options.stepped` is an option value (Chart.js ADR 0006).
library;

import 'package:flutter_chartjs/src/types/geometric.dart';

/// The object literal `{x, y}` that the three functions return
/// (helpers.interpolation.ts:7-10, :21-26), and the control-point literals
/// of `_bezierInterpolation` (:33-34).
///
/// TypeScript gives the literal no declared type. The fields are mutable,
/// because `element.line.js:374` writes `interpolated[property]`. A JS object
/// compares by identity. Thus the class has no `==`.
final class InterpolatedPoint implements Point {
  /// The literal `{x, y}`.
  InterpolatedPoint(this.x, this.y);

  /// The `x` member. Dart `null` is JS `null`, as in [Point.x]. Only
  /// `_steppedInterpolation` copies a `y`, so `x` is never `null` in the
  /// results of this file.
  @override
  double? x;

  /// The `y` member. Dart `null` is JS `null`, as in [Point.y].
  /// `_steppedInterpolation` copies `p1.y` or `p2.y` unchanged, also a JS
  /// `null`.
  @override
  double? y;
}

/// helpers.interpolation.ts:6 `_pointInLine`. Upstream does not read
/// `mode`. `ToNumber` makes a JS `null` member 0, as in
/// `distanceBetweenPoints` (helpers.math.ts:144): the port writes
/// `p1.x ?? 0` (Chart.js ADR 0032).
InterpolatedPoint pointInLine(
  Point p1,
  Point p2,
  double t, [
  Object? mode,
]) {
  return InterpolatedPoint(
    (p1.x ?? 0) + t * ((p2.x ?? 0) - (p1.x ?? 0)),
    (p1.y ?? 0) + t * ((p2.y ?? 0) - (p1.y ?? 0)),
  );
}

/// helpers.interpolation.ts:16 `_steppedInterpolation`. JS `===` on a
/// string is Dart `==`.
InterpolatedPoint steppedInterpolation(
  Point p1,
  Point p2,
  double t,
  Object? mode,
) {
  return InterpolatedPoint(
    (p1.x ?? 0) + t * ((p2.x ?? 0) - (p1.x ?? 0)),
    mode == 'middle'
        ? t < 0.5
              ? p1.y
              : p2.y
        : mode == 'after'
        ? t < 1
              ? p1.y
              : p2.y
        : t > 0
        ? p2.y
        : p1.y,
  );
}

/// helpers.interpolation.ts:32 `_bezierInterpolation`. Upstream does not read
/// `mode`.
///
/// An unset control point is JS `undefined` in the literal. The port stores
/// it as `double.nan`, its `ToNumber` value (row
/// `adapt-spline-control-point-nan`), and the copy passes it, as [Point.x]
/// states. `_pointInLine` only does arithmetic on it. Thus the result is the
/// same NaN.
InterpolatedPoint bezierInterpolation(
  SplinePoint p1,
  SplinePoint p2,
  double t, [
  Object? mode,
]) {
  // DIVERGES(chartjs): adapt-spline-control-point-nan, NaN is undefined.
  final cp1 = InterpolatedPoint(p1.cp2x, p1.cp2y);
  final cp2 = InterpolatedPoint(p2.cp1x, p2.cp1y);
  final a = pointInLine(p1, cp1, t);
  final b = pointInLine(cp1, cp2, t);
  final c = pointInLine(cp2, p2, t);
  final d = pointInLine(a, b, t);
  final e = pointInLine(b, c, t);
  return pointInLine(d, e, t);
}
