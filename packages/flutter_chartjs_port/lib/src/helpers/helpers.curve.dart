// Ported from Chart.js v4.5.1+7169e651 src/helpers/helpers.curve.ts (MIT, Chart.js Contributors).

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

import 'package:flutter_chartjs_port/src/helpers/helpers.canvas.dart'
    show isPointInArea;
import 'package:flutter_chartjs_port/src/helpers/helpers.math.dart'
    show almostEquals, distanceBetweenPoints, sign;
import 'package:flutter_chartjs_port/src/js/js_math.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
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

/// helpers.curve.ts:10 `getValueAxis`.
String _getValueAxis(String indexAxis) => indexAxis == 'x' ? 'y' : 'x';

/// The read `point[axis]` of helpers.curve.ts:101-109 and :141-144. Each
/// read is arithmetic. Thus another axis, for example `'r'`, reads
/// undefined, which `ToNumber` makes NaN.
double _axisValue(SplinePoint point, String axis) => switch (axis) {
  'x' => point.x,
  'y' => point.y,
  _ => double.nan,
};

/// The write `` point[`${cp}${axis}`] = value `` of helpers.curve.ts:105-111.
/// [cp] is `'cp1'` or `'cp2'`. The key is `'cp1x'`, `'cp1y'`, `'cp2x'` or
/// `'cp2y'`. Another axis, for example `'r'`, gives a key such as `'cp1r'`,
/// which has no [SplinePoint] member. Nothing reads it upstream. Thus the
/// port does not store it.
///
/// The function selects the member from [cp] and [axis]. It does not build
/// the key string, so a point costs no new string.
void _setControlPoint(SplinePoint point, String cp, String axis, double value) {
  final first = cp == 'cp1';
  switch (axis) {
    case 'x' when first:
      point.cp1x = value;
    case 'x':
      point.cp2x = value;
    case 'y' when first:
      point.cp1y = value;
    case 'y':
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
  String indexAxis = 'x',
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
void splineCurveMonotone(List<SplinePoint> points, [String indexAxis = 'x']) {
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
/// [options] is an option object (Chart.js ADR 0006). `options.tension`
/// goes to the parameter `t` of [splineCurve] through `ToNumber`, as the
/// upstream `t * s01` does: undefined gives NaN, and JS `null` gives 0.
/// Dart `null` for [area] is JS `undefined` (see [_capBezierPoints]).
void updateBezierControlPoints(
  List<SplinePoint> points,
  Map<String, Object?> options,
  ChartArea? area,
  // The upstream signature.
  // ignore: avoid_positional_boolean_parameters
  bool loop,
  String indexAxis,
) {
  // Only consider points that are drawn in case the spanGaps option is used
  if (jsTruthy(jsGet(options, 'spanGaps'))) {
    // Upstream reassigns its parameter.
    // ignore: parameter_assignments
    points = points.where((pt) => !(pt.skip ?? false)).toList();
  }

  if (jsGet(options, 'cubicInterpolationMode') == 'monotone') {
    splineCurveMonotone(points, indexAxis);
  } else {
    // `points[0]` of an empty array is undefined. The loop does not run then.
    var prev = points.isEmpty
        ? null
        : loop
        ? points[points.length - 1]
        : points[0];
    final tension = jsToNumber(jsGet(options, 'tension'));
    for (var i = 0, ilen = points.length; i < ilen; ++i) {
      final point = points[i];
      // The indexes are list indexes: non-negative integers.
      final controlPoints = splineCurve(
        prev!,
        point,
        points[math.min<int>(i + 1, ilen - (loop ? 0 : 1)).remainder(ilen)],
        tension,
      );
      point
        ..cp1x = controlPoints.previous.x
        ..cp1y = controlPoints.previous.y
        ..cp2x = controlPoints.next.x
        ..cp2y = controlPoints.next.y;
      prev = point;
    }
  }

  if (jsTruthy(jsGet(options, 'capBezierPoints'))) {
    _capBezierPoints(points, area);
  }
}
