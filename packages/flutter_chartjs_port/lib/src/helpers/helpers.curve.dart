// Ported from Chart.js v4.6.1 src/helpers/helpers.curve.ts (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-cubic-interpolation-mode-objects, the mode classes.

/// Port of `src/helpers/helpers.curve.ts`.
///
/// Upstream reads and writes the members of a point by a computed key:
/// `pointCurrent[indexAxis]` and `` pointCurrent[`cp1${indexAxis}`] ``
/// (helpers.curve.ts:101-111). Here [_axisValue] and [_setControlPoint]
/// select the member of [SplinePoint] for the key. The upstream type of the
/// axis is `'x' | 'y'`. At runtime the axis can also be `'r'`: plugin.filler
/// passes the `indexAxis` of a radar chart (plugin.filler/index.js:31 and
/// :61). Upstream then reads the absent key `point.r`, which is undefined,
/// and writes `cp1r` and `cp2r`, which nothing reads.
library;

import 'dart:math' as math;

import 'package:flutter_chartjs_port/src/helpers/cubic_interpolation_mode.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.canvas.dart'
    show isPointInArea;
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart'
    show readOption;
import 'package:flutter_chartjs_port/src/helpers/helpers.math.dart'
    show almostEquals, distanceBetweenPoints, sign;
import 'package:flutter_chartjs_port/src/js/js_math.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart';
import 'package:flutter_chartjs_port/src/types/chart_axis.dart';
import 'package:flutter_chartjs_port/src/types/geometric.dart';

/// helpers.curve.ts:6 `EPSILON`. `Number.EPSILON` is truthy, so the
/// fallback `1e-14` never applies.
final double _epsilon = numberEpsilon != 0 && !numberEpsilon.isNaN
    ? numberEpsilon
    : 1e-14;

/// helpers.curve.ts:9 `getPoint`. Dart `null` stands for the upstream
/// `false` of `OptionalSplinePoint` (helpers.curve.ts:8). A `skip` of Dart
/// `null` is JS `undefined`, which is falsy.
SplinePoint? _getPoint(List<SplinePoint> points, int i) =>
    i < points.length && !(points[i].skip ?? false) ? points[i] : null;

/// helpers.curve.ts:10 `getValueAxis`: `indexAxis === 'x' ? 'y' : 'x'`.
ScaleAxis _getValueAxis(ScaleAxis indexAxis) =>
    indexAxis is XAxis ? const YAxis() : const XAxis();

/// The read `point[axis]` of helpers.curve.ts:101-109 and :141-144. Each
/// read is arithmetic. Thus another axis, for example [RAxis], reads
/// undefined, which `ToNumber` makes NaN.
double _axisValue(SplinePoint point, ScaleAxis axis) => switch (axis) {
  XAxis() => point.x,
  YAxis() => point.y,
  _ => double.nan,
};

/// The write `` point[`${cp}${axis}`] = value `` of helpers.curve.ts:105-111.
/// [cp] is `'cp1'` or `'cp2'`. The key is `'cp1x'`, `'cp1y'`, `'cp2x'` or
/// `'cp2y'`. Another axis, for example [RAxis], gives a key such as `'cp1r'`,
/// which has no [SplinePoint] member. Nothing reads it upstream. Thus the
/// port does not store it.
///
/// The function selects the member from [cp] and [axis]. It does not build
/// the key string, so a point costs no new string.
void _setControlPoint(
  SplinePoint point,
  String cp,
  ScaleAxis axis,
  double value,
) {
  final first = cp == 'cp1';
  switch (axis) {
    case XAxis() when first:
      point.cp1x = value;
    case XAxis():
      point.cp2x = value;
    case YAxis() when first:
      point.cp1y = value;
    case YAxis():
      point.cp2y = value;
  }
}

/// helpers.curve.ts:12 `splineCurve`.
///
/// The result is the object literal `{previous: {x, y}, next: {x, y}}`
/// (helpers.curve.ts:42-51). Ported code only reads it. Thus it is a record
/// (`lib/src/types/index.dart`).
({({double x, double y}) previous, ({double x, double y}) next}) splineCurve(
  SplinePoint firstPoint,
  SplinePoint middlePoint,
  SplinePoint afterPoint,
  double t,
) {
  // Props to Rob Spencer at scaled innovation for his post on splining
  // between points
  // http://scaledinnovation.com/analytics/splines/aboutSplines.html

  // This function must also respect "skipped" points

  final previous = (firstPoint.skip ?? false) ? middlePoint : firstPoint;
  final current = middlePoint;
  final next = (afterPoint.skip ?? false) ? middlePoint : afterPoint;
  final d01 = distanceBetweenPoints(current, previous);
  final d12 = distanceBetweenPoints(next, current);

  var s01 = d01 / (d01 + d12);
  var s12 = d12 / (d01 + d12);

  // If all points are the same, s01 & s02 will be inf
  s01 = s01.isNaN ? 0 : s01;
  s12 = s12.isNaN ? 0 : s12;

  final fa = t * s01; // scaling factor for triangle Ta
  final fb = t * s12;

  return (
    previous: (
      x: current.x - fa * (next.x - previous.x),
      y: current.y - fa * (next.y - previous.y),
    ),
    next: (
      x: current.x + fb * (next.x - previous.x),
      y: current.y + fb * (next.y - previous.y),
    ),
  );
}

/// The loop body of helpers.curve.ts:204-217: [splineCurve] of the three points
/// with its four results written into [middlePoint]. The reads and the writes
/// have the order of the two functions, with no record of the result.
// DIVERGES(chartjs): adapt-spline-scalar-writes, no result object for a point.
void _writeSplineControlPoints(
  SplinePoint firstPoint,
  SplinePoint middlePoint,
  SplinePoint afterPoint,
  double t,
) {
  final previous = (firstPoint.skip ?? false) ? middlePoint : firstPoint;
  final current = middlePoint;
  final next = (afterPoint.skip ?? false) ? middlePoint : afterPoint;
  final d01 = math.sqrt(
    jsSquare(previous.x - current.x) + jsSquare(previous.y - current.y),
  );
  final d12 = math.sqrt(
    jsSquare(current.x - next.x) + jsSquare(current.y - next.y),
  );

  var s01 = d01 / (d01 + d12);
  var s12 = d12 / (d01 + d12);

  s01 = s01.isNaN ? 0 : s01;
  s12 = s12.isNaN ? 0 : s12;

  final fa = t * s01;
  final fb = t * s12;

  final previousX = current.x - fa * (next.x - previous.x);
  final previousY = current.y - fa * (next.y - previous.y);
  final nextX = current.x + fb * (next.x - previous.x);
  final nextY = current.y + fb * (next.y - previous.y);
  middlePoint
    ..cp1x = previousX
    ..cp1y = previousY
    ..cp2x = nextX
    ..cp2y = nextY;
}

/// helpers.curve.ts:57 `monotoneAdjust`.
///
/// Adjust tangents to ensure monotonic properties
void _monotoneAdjust(
  List<SplinePoint> points,
  List<double> deltaK,
  List<double> mK,
) {
  final pointsLen = points.length;

  SplinePoint? pointCurrent;
  var pointAfter = _getPoint(points, 0);
  for (var i = 0; i < pointsLen - 1; ++i) {
    pointCurrent = pointAfter;
    pointAfter = _getPoint(points, i + 1);
    if (pointCurrent == null || pointAfter == null) {
      continue;
    }

    if (almostEquals(deltaK[i], 0, _epsilon)) {
      mK[i] = mK[i + 1] = 0;
      continue;
    }

    final alphaK = mK[i] / deltaK[i];
    final betaK = mK[i + 1] / deltaK[i];
    final squaredMagnitude = jsSquare(alphaK) + jsSquare(betaK);
    if (squaredMagnitude <= 9) {
      continue;
    }

    final tauK = 3 / math.sqrt(squaredMagnitude);
    mK[i] = alphaK * tauK * deltaK[i];
    mK[i + 1] = betaK * tauK * deltaK[i];
  }
}

/// helpers.curve.ts:87 `monotoneCompute`.
void _monotoneCompute(
  List<SplinePoint> points,
  List<double> mK, [
  ScaleAxis indexAxis = const XAxis(),
]) {
  final valueAxis = _getValueAxis(indexAxis);
  final pointsLen = points.length;
  SplinePoint? pointBefore;
  SplinePoint? pointCurrent;
  var pointAfter = _getPoint(points, 0);

  for (var i = 0; i < pointsLen; ++i) {
    pointBefore = pointCurrent;
    pointCurrent = pointAfter;
    pointAfter = _getPoint(points, i + 1);
    if (pointCurrent == null) {
      continue;
    }

    final iPixel = _axisValue(pointCurrent, indexAxis);
    final vPixel = _axisValue(pointCurrent, valueAxis);
    if (pointBefore != null) {
      final delta = (iPixel - _axisValue(pointBefore, indexAxis)) / 3;
      _setControlPoint(pointCurrent, 'cp1', indexAxis, iPixel - delta);
      _setControlPoint(pointCurrent, 'cp1', valueAxis, vPixel - delta * mK[i]);
    }
    if (pointAfter != null) {
      final delta = (_axisValue(pointAfter, indexAxis) - iPixel) / 3;
      _setControlPoint(pointCurrent, 'cp2', indexAxis, iPixel + delta);
      _setControlPoint(pointCurrent, 'cp2', valueAxis, vPixel + delta * mK[i]);
    }
  }
}

/// helpers.curve.ts:122 `splineCurveMonotone`.
///
/// This function calculates Bézier control points in a similar way than
/// |splineCurve|, but preserves monotonicity of the provided data and ensures
/// no local extremums are added between the dataset discrete points due to
/// the interpolation.
/// See : https://en.wikipedia.org/wiki/Monotone_cubic_interpolation
void splineCurveMonotone(
  List<SplinePoint> points, [
  ScaleAxis indexAxis = const XAxis(),
]) {
  final valueAxis = _getValueAxis(indexAxis);
  final pointsLen = points.length;
  final deltaK = List<double>.filled(pointsLen, 0);
  // `Array(pointsLen)` has holes, which read as undefined. Each read of `mK`
  // is arithmetic, where undefined becomes NaN. Thus NaN fills the holes.
  final mK = List<double>.filled(pointsLen, double.nan);

  // Calculate slopes (deltaK) and initialize tangents (mK)
  SplinePoint? pointBefore;
  SplinePoint? pointCurrent;
  var pointAfter = _getPoint(points, 0);

  for (var i = 0; i < pointsLen; ++i) {
    pointBefore = pointCurrent;
    pointCurrent = pointAfter;
    pointAfter = _getPoint(points, i + 1);
    if (pointCurrent == null) {
      continue;
    }

    if (pointAfter != null) {
      final slopeDelta =
          _axisValue(pointAfter, indexAxis) -
          _axisValue(pointCurrent, indexAxis);

      // In the case of two points that appear at the same x pixel,
      // slopeDeltaX is 0
      deltaK[i] = slopeDelta != 0
          ? (_axisValue(pointAfter, valueAxis) -
                    _axisValue(pointCurrent, valueAxis)) /
                slopeDelta
          : 0;
    }
    // JS `!==` on numbers is Dart `!=`: NaN differs from NaN, and -0 equals 0.
    mK[i] = pointBefore == null
        ? deltaK[i]
        : pointAfter == null
        ? deltaK[i - 1]
        : (sign(deltaK[i - 1]) != sign(deltaK[i]))
        ? 0
        : (deltaK[i - 1] + deltaK[i]) / 2;
  }

  _monotoneAdjust(points, deltaK, mK);

  _monotoneCompute(points, mK, indexAxis);
}

/// helpers.curve.ts:157 `capControlPoint`.
double _capControlPoint(double pt, double min, double max) {
  return jsMax(jsMin(pt, max), min);
}

/// helpers.curve.ts:161 `capBezierPoints`.
///
/// An unset control point is `double.nan`, which stands for JS `undefined`
/// (row `adapt-spline-control-point-nan`). `Math.min` makes `undefined` NaN.
/// Thus the result is the same.
///
/// Dart `null` for [area] is JS `undefined`: [isPointInArea] gives `true`
/// for each point, and the first cap of a control point throws a
/// [TypeError] at the read of `area.left`, as upstream does.
void _capBezierPoints(List<SplinePoint> points, ChartArea? area) {
  var inArea = false;
  // `points[0]` of an empty array is undefined.
  var inAreaNext = isPointInArea(points.isEmpty ? null : points[0], area);
  for (var i = 0, ilen = points.length; i < ilen; ++i) {
    final inAreaPrev = inArea;
    inArea = inAreaNext;
    inAreaNext = i < ilen - 1 && isPointInArea(points[i + 1], area);
    if (!inArea) {
      continue;
    }
    final point = points[i];
    if (inAreaPrev) {
      // DIVERGES(chartjs): adapt-spline-control-point-nan, NaN is undefined.
      point
        ..cp1x = _capControlPoint(point.cp1x, area!.left, area.right)
        ..cp1y = _capControlPoint(point.cp1y, area.top, area.bottom);
    }
    if (inAreaNext) {
      // DIVERGES(chartjs): adapt-spline-control-point-nan, NaN is undefined.
      point
        ..cp2x = _capControlPoint(point.cp2x, area!.left, area.right)
        ..cp2y = _capControlPoint(point.cp2y, area.top, area.bottom);
    }
  }
}

/// helpers.curve.ts:186 `_updateBezierControlPoints`.
///
/// @private
///
/// [options] is an option object: the resolved options of a line, or a
/// plain Map. Its reads go through [readOption] (Chart.js ADR 0054 §4): the
/// typed fields of resolved element options, else the read by name.
/// `options.tension` goes to the parameter `t` of [splineCurve] through
/// `ToNumber`, as the upstream `t * s01` does: undefined gives NaN, and JS
/// `null` gives 0. The mode of the option `cubicInterpolationMode` writes
/// the control points ([CubicInterpolationMode.updateControlPoints]).
/// Dart `null` for [area] is JS `undefined` (see [_capBezierPoints]).
void updateBezierControlPoints(
  List<SplinePoint> points,
  Object options,
  ChartArea? area,
  bool loop,
  ScaleAxis indexAxis,
) {
  // Only consider points that are drawn in case the spanGaps option is used
  if (jsTruthy(readOption(options, OptionKey.spanGaps))) {
    // Upstream reassigns its parameter.
    // ignore: parameter_assignments
    points = points.where((pt) => !(pt.skip ?? false)).toList();
  }

  // DIVERGES(chartjs): adapt-cubic-interpolation-mode-objects, the mode
  // writes the control points.
  cubicInterpolationModeOf(
    readOption(options, OptionKey.cubicInterpolationMode),
  ).updateControlPoints(
    points,
    tension: jsToNumber(readOption(options, OptionKey.tension)),
    loop: loop,
    indexAxis: indexAxis,
  );

  if (jsTruthy(readOption(options, OptionKey.capBezierPoints))) {
    _capBezierPoints(points, area);
  }
}

/// The else branch of helpers.curve.ts:202-216: [splineCurve] of each point
/// of [points], with its neighbors, into its control points. [t] is the
/// tension, and [loop] joins the last point to the first.
// DIVERGES(chartjs): adapt-cubic-interpolation-mode-objects, the default mode.
void splineCurveDefault(List<SplinePoint> points, double t, bool loop) {
  // `points[0]` of an empty array is undefined. The loop does not run then.
  var prev = points.isEmpty
      ? null
      : loop
      ? points[points.length - 1]
      : points[0];
  for (var i = 0, ilen = points.length; i < ilen; ++i) {
    final point = points[i];
    // The indexes are list indexes: non-negative integers.
    _writeSplineControlPoints(
      prev!,
      point,
      points[math.min<int>(i + 1, ilen - (loop ? 0 : 1)).remainder(ilen)],
      t,
    );
    prev = point;
  }
}

/// The mode of the option value [value] (`cubicInterpolationMode`): the
/// [CubicInterpolationMode] itself, else [DefaultCubicInterpolationMode], as
/// upstream takes the default branch for each value that is not
/// `'monotone'` (helpers.curve.ts:200).
CubicInterpolationMode cubicInterpolationModeOf(Object? value) =>
    CubicInterpolationMode.of(value) ?? const DefaultCubicInterpolationMode();

/// `cubicInterpolationMode: 'default'` (index.d.ts:1984), the default: a
/// curve of weighted tangents through each point ([splineCurve]). A line of
/// this mode draws curves when its `tension` is truthy.
final class const DefaultCubicInterpolationMode()
    extends CubicInterpolationMode {
  /// The default mode.
  this;

  @override
  bool drawsCurves(Object? tension) => jsTruthy(tension);

  @override
  void updateControlPoints(
    List<SplinePoint> points, {
    required double tension,
    required bool loop,
    required ScaleAxis indexAxis,
  }) => splineCurveDefault(points, tension, loop);
}

/// `cubicInterpolationMode: 'monotone'` (index.d.ts:1984): a monotone cubic
/// curve on the index axis ([splineCurveMonotone]), which keeps the
/// monotonicity of the data. A line of this mode always draws curves, and
/// the mode reads no `tension`.
final class const MonotoneCubicInterpolationMode()
    extends CubicInterpolationMode {
  /// The monotone mode.
  this;

  @override
  bool drawsCurves(Object? tension) => true;

  @override
  void updateControlPoints(
    List<SplinePoint> points, {
    required double tension,
    required bool loop,
    required ScaleAxis indexAxis,
  }) => splineCurveMonotone(points, indexAxis);
}
