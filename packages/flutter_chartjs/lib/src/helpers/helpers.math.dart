// Ported from Chart.js v4.5.1 src/helpers/helpers.math.ts (MIT, Chart.js Contributors).

/// Port of `src/helpers/helpers.math.ts`.
///
/// @alias Chart.helpers.math
/// @namespace
library;

import 'dart:math' as math;

// Upstream imports isFinite as isFiniteNumber, to keep the global isFinite
// that isNumber calls. Here the global is jsIsFinite.
import 'package:flutter_chartjs/src/helpers/helpers.core.dart' show isFinite;
import 'package:flutter_chartjs/src/js/js_math.dart';
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/types/geometric.dart';

/// helpers.math.ts:9 `PI`.
const double pi = math.pi;

/// helpers.math.ts:10 `TAU`.
const double tau = 2 * pi;

/// helpers.math.ts:11 `PITAU`.
const double piTau = tau + pi;

/// helpers.math.ts:12 `INFINITY`.
const double infinity = double.infinity;

/// helpers.math.ts:13 `RAD_PER_DEG`.
const double radPerDeg = pi / 180;

/// helpers.math.ts:14 `HALF_PI`.
const double halfPi = pi / 2;

/// helpers.math.ts:15 `QUARTER_PI`.
const double quarterPi = pi / 4;

/// helpers.math.ts:16 `TWO_THIRDS_PI`.
const double twoThirdsPi = pi * 2 / 3;

/// helpers.math.ts:18 `log10 = Math.log10`.
const double Function(double) log10 = jsLog10;

/// helpers.math.ts:19 `sign = Math.sign`. `double.sign` is `Math.sign`.
double sign(double x) => x.sign;

/// helpers.math.ts:21 `almostEquals`.
bool almostEquals(double x, double y, double epsilon) {
  return (x - y).abs() < epsilon;
}

/// helpers.math.ts:28 `niceNum`.
///
/// Implementation of the nice number algorithm used in determining where axis
/// labels will go
double niceNum(double range) {
  final roundedRange = jsRound(range);
  // Upstream reassigns its parameter.
  // ignore: parameter_assignments
  range = almostEquals(range, roundedRange, range / 1000)
      ? roundedRange
      : range;
  // js-ok: the exponent is an integer, as porting-flow.md 2.3 requires.
  final niceRange = math.pow(10.0, log10(range).floorToDouble()).toDouble();
  final fraction = range / niceRange;
  final niceFraction = fraction <= 1
      ? 1.0
      : fraction <= 2
      ? 2.0
      : fraction <= 5
      ? 5.0
      : 10.0;
  return niceFraction * niceRange;
}

/// helpers.math.ts:41 `_factorize`.
///
/// Returns an array of factors sorted from 1 to sqrt(value)
List<double> factorize(double value) {
  final result = <double>[];
  final sqrt = math.sqrt(value);

  for (var i = 1.0; i < sqrt; i++) {
    if (value.remainder(i) == 0) {
      result
        ..add(i)
        ..add(value / i);
    }
  }
  if (sqrt == jsToInt32(sqrt)) {
    // if value is a square number
    result.add(sqrt);
  }

  // The factors are distinct and finite, so List.sort gives the order of
  // Array.prototype.sort with (a, b) => a - b.
  result.sort((a, b) => a.compareTo(b)); // js-ok: distinct finite numbers
  // pop() on an empty array does nothing.
  if (result.isNotEmpty) result.removeLast();
  return result;
}

/// helpers.math.ts:63 `isNonPrimitive`.
///
/// Verifies that attempting to coerce n to string or number won't throw a
/// TypeError.
bool _isNonPrimitive(Object? n) {
  // Every Dart object has toString(), so only the symbol test can hold.
  return n is Symbol;
}

/// helpers.math.ts:67 `isNumber`.
bool isNumber(Object? n) {
  return !_isNonPrimitive(n) && !jsIsNaN(jsParseFloat(n)) && jsIsFinite(n);
}

/// helpers.math.ts:71 `almostWhole`.
bool almostWhole(double x, double epsilon) {
  final rounded = jsRound(x);
  return ((rounded - epsilon) <= x) && ((rounded + epsilon) >= x);
}

/// helpers.math.ts:81 the type `{ min: number, max: number }` of the
/// `_setMinAndMaxByKey` target.
abstract interface class MinMax {
  /// helpers.math.ts:81 `min`.
  abstract double min;

  /// helpers.math.ts:81 `max`.
  abstract double max;
}

/// helpers.math.ts:79 `_setMinAndMaxByKey`.
void setMinAndMaxByKey(
  List<Map<String, Object?>> array,
  MinMax target,
  String property,
) {
  for (var i = 0, ilen = array.length; i < ilen; i++) {
    final value = array[i][property];
    // An absent key reads as undefined, and isNaN(undefined) is true.
    if (array[i].containsKey(property) && !jsIsNaN(value)) {
      target
        ..min = math.min(target.min, jsToNumber(value))
        ..max = math.max(target.max, jsToNumber(value));
    }
  }
}

/// helpers.math.ts:95 `toRadians`.
double toRadians(double degrees) {
  return degrees * (pi / 180);
}

/// helpers.math.ts:99 `toDegrees`.
double toDegrees(double radians) {
  return radians * (180 / pi);
}

/// helpers.math.ts:110 `_decimalPlaces`. Null stands for upstream's
/// `undefined`.
///
/// Returns the number of decimal places
/// i.e. the number of digits after the decimal point, of the value of this
/// Number.
double? decimalPlaces(Object? x) {
  if (!isFinite(x)) {
    return null;
  }
  final value = (x! as num).toDouble();
  var e = 1.0;
  var p = 0.0;
  while (jsRound(value * e) / e != value) {
    e *= 10;
    p++;
  }
  return p;
}

/// helpers.math.ts:124 `getAngleFromPoint`. `Math.atan2` is [jsAtan2], so
/// the angle has the bits of V8 on every target.
///
/// Gets the angle from vertical upright to the point about a centre.
({double angle, double distance}) getAngleFromPoint(
  Point centrePoint,
  Point anglePoint,
) {
  final distanceFromXCenter =
      jsToNumber(anglePoint.x) - jsToNumber(centrePoint.x);
  final distanceFromYCenter =
      jsToNumber(anglePoint.y) - jsToNumber(centrePoint.y);
  final radialDistanceFromCenter = math.sqrt(
    distanceFromXCenter * distanceFromXCenter +
        distanceFromYCenter * distanceFromYCenter,
  );

  var angle = jsAtan2(distanceFromYCenter, distanceFromXCenter);

  if (angle < (-0.5 * pi)) {
    // make sure the returned angle is in the range of (-PI/2, 3PI/2]
    angle += tau;
  }

  return (angle: angle, distance: radialDistanceFromCenter);
}

/// helpers.math.ts:144 `distanceBetweenPoints`.
double distanceBetweenPoints(Point pt1, Point pt2) {
  return math.sqrt(
    // js-ok: integer exponent, as Chart.js ADR 0002 requires.
    math.pow(jsToNumber(pt2.x) - jsToNumber(pt1.x), 2.0) +
        // js-ok: integer exponent, as Chart.js ADR 0002 requires.
        math.pow(jsToNumber(pt2.y) - jsToNumber(pt1.y), 2.0),
  );
}

/// helpers.math.ts:152 `_angleDiff`. JS `%` is Dart `remainder`.
///
/// Shortest distance between angles, in either direction.
double angleDiff(double a, double b) {
  return (a - b + piTau).remainder(tau) - pi;
}

/// helpers.math.ts:160 `_normalizeAngle`.
///
/// Normalize angle to be between 0 and 2*PI
double normalizeAngle(double a) {
  return (a.remainder(tau) + tau).remainder(tau);
}

/// helpers.math.ts:167 `_angleBetween`.
bool angleBetween(
  double angle,
  double start,
  double end, [
  // The upstream signature.
  // ignore: avoid_positional_boolean_parameters
  bool? sameAngleIsFullCircle,
]) {
  final a = normalizeAngle(angle);
  final s = normalizeAngle(start);
  final e = normalizeAngle(end);
  final angleToStart = normalizeAngle(s - a);
  final angleToEnd = normalizeAngle(e - a);
  final startToAngle = normalizeAngle(a - s);
  final endToAngle = normalizeAngle(a - e);
  return a == s ||
      a == e ||
      ((sameAngleIsFullCircle ?? false) && s == e) ||
      (angleToStart > angleToEnd && startToAngle < endToAngle);
}

/// helpers.math.ts:186 `_limitValue`.
///
/// Limit `value` between `min` and `max`
double limitValue(double value, double min, double max) {
  return math.max(min, math.min(max, value));
}

/// helpers.math.ts:194 `_int16Range`.
double int16Range(double value) {
  return limitValue(value, -32768, 32767);
}

/// helpers.math.ts:205 `_isBetween`.
bool isBetween(
  double value,
  double start,
  double end, [
  double epsilon = 1e-6,
]) {
  return value >= math.min(start, end) - epsilon &&
      value <= math.max(start, end) + epsilon;
}
