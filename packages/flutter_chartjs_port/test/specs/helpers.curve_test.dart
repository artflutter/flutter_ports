// Ported from Chart.js v4.5.1+7169e651 test/specs/helpers.curve.tests.js (MIT, Chart.js Contributors).
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.curve.dart' as helpers;
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/types/geometric.dart';
import 'package:test/test.dart';

/// A JavaScript object literal `{x, y, skip}`, passed as a [SplinePoint]. A
/// control point that the literal does not set is `double.nan`, which stands
/// for JS `undefined` (row `adapt-spline-control-point-nan`).
///
/// The spec gives one skipped point the members `x: null` and `y: null`.
/// [SplinePoint.x] and [SplinePoint.y] are `number` upstream. Thus the
/// getters throw on a JS `null`. `helpers.curve.ts` never reads the members
/// of a skipped point.
final class _SplinePoint implements SplinePoint {
  _SplinePoint(this.rawX, this.rawY, {this.skip});

  /// The literal member `x`. Dart `null` is JS `null`.
  final double? rawX;

  /// The literal member `y`. Dart `null` is JS `null`.
  final double? rawY;

  @override
  double get x => rawX!;

  @override
  double get y => rawY!;

  @override
  final bool? skip;

  @override
  double cp1x = double.nan;

  @override
  double cp1y = double.nan;

  @override
  double cp2x = double.nan;

  @override
  double cp2y = double.nan;
}

/// Jasmine `toEqual` on a number: SameValue, so NaN equals NaN and `-0` does
/// not equal `0`. A `null` expected value stands for an absent member or JS
/// `null`.
bool _sameValue(double? actual, double? expected) => expected == null
    ? actual == null
    : actual != null &&
          (expected.isNaN
              ? actual.isNaN
              : actual == expected && actual.isNegative == expected.isNegative);

String _show(double? v) => v == null ? 'undefined' : jsNumberToString(v);

/// Jasmine `toEqual({x, y})` on a point literal of `splineCurve`.
Matcher _toEqualPoint(double x, double y) => predicate<({double x, double y})>(
  (p) => _sameValue(p.x, x) && _sameValue(p.y, y),
  '{x: ${_show(x)}, y: ${_show(y)}}',
);

/// Jasmine `toEqual({previous: {x, y}, next: {x, y}})` on the result of
/// `splineCurve`.
Matcher _toEqualControlPoints(
  ({double x, double y}) previous,
  ({double x, double y}) next,
) => isA<({({double x, double y}) previous, ({double x, double y}) next})>()
    .having(
      (r) => r.previous,
      'previous',
      _toEqualPoint(previous.x, previous.y),
    )
    .having((r) => r.next, 'next', _toEqualPoint(next.x, next.y));

/// Jasmine `toEqual` on a point literal `{x, y, skip, cp1x, cp1y, cp2x,
/// cp2y}`. A control point that the expected literal leaves out is JS
/// `undefined`. It compares as `double.nan`, with SameValue (row
/// `adapt-spline-control-point-nan`).
Matcher _toEqualSplinePoint({
  required double? x,
  required double? y,
  required bool skip,
  double? cp1x,
  double? cp1y,
  double? cp2x,
  double? cp2y,
}) => predicate<_SplinePoint>(
  (p) =>
      _sameValue(p.rawX, x) &&
      _sameValue(p.rawY, y) &&
      p.skip == skip &&
      _sameValue(p.cp1x, cp1x ?? double.nan) &&
      _sameValue(p.cp1y, cp1y ?? double.nan) &&
      _sameValue(p.cp2x, cp2x ?? double.nan) &&
      _sameValue(p.cp2y, cp2y ?? double.nan),
  '{x: ${_show(x)}, y: ${_show(y)}, skip: $skip, cp1x: ${_show(cp1x)}, '
  'cp1y: ${_show(cp1y)}, cp2x: ${_show(cp2x)}, cp2y: ${_show(cp2y)}}',
);

void main() {
  setUpSpecs();
  group('Curve helper tests', () {
    test('should spline curves', () {
      expect(
        helpers.splineCurve(
          _SplinePoint(0, 0),
          _SplinePoint(1, 1),
          _SplinePoint(2, 0),
          0,
        ),
        _toEqualControlPoints((x: 1, y: 1), (x: 1, y: 1)),
      );

      expect(
        helpers.splineCurve(
          _SplinePoint(0, 0),
          _SplinePoint(1, 1),
          _SplinePoint(2, 0),
          1,
        ),
        _toEqualControlPoints((x: 0, y: 1), (x: 2, y: 1)),
      );
    });

    test('should spline curves with monotone cubic interpolation', () {
      final dataPoints = <_SplinePoint>[
        _SplinePoint(0, 0, skip: false),
        _SplinePoint(3, 6, skip: false),
        _SplinePoint(9, 6, skip: false),
        _SplinePoint(12, 60, skip: false),
        _SplinePoint(15, 60, skip: false),
        _SplinePoint(18, 120, skip: false),
        _SplinePoint(null, null, skip: true),
        _SplinePoint(21, 180, skip: false),
        _SplinePoint(24, 120, skip: false),
        _SplinePoint(27, 125, skip: false),
        _SplinePoint(30, 105, skip: false),
        _SplinePoint(33, 110, skip: false),
        _SplinePoint(33, 110, skip: false),
        _SplinePoint(36, 170, skip: false),
      ];
      helpers.splineCurveMonotone(dataPoints);
      expect(dataPoints, [
        _toEqualSplinePoint(x: 0, y: 0, skip: false, cp2x: 1, cp2y: 2),
        _toEqualSplinePoint(
          x: 3,
          y: 6,
          skip: false,
          cp1x: 2,
          cp1y: 6,
          cp2x: 5,
          cp2y: 6,
        ),
        _toEqualSplinePoint(
          x: 9,
          y: 6,
          skip: false,
          cp1x: 7,
          cp1y: 6,
          cp2x: 10,
          cp2y: 6,
        ),
        _toEqualSplinePoint(
          x: 12,
          y: 60,
          skip: false,
          cp1x: 11,
          cp1y: 60,
          cp2x: 13,
          cp2y: 60,
        ),
        _toEqualSplinePoint(
          x: 15,
          y: 60,
          skip: false,
          cp1x: 14,
          cp1y: 60,
          cp2x: 16,
          cp2y: 60,
        ),
        _toEqualSplinePoint(x: 18, y: 120, skip: false, cp1x: 17, cp1y: 100),
        _toEqualSplinePoint(x: null, y: null, skip: true),
        _toEqualSplinePoint(x: 21, y: 180, skip: false, cp2x: 22, cp2y: 160),
        _toEqualSplinePoint(
          x: 24,
          y: 120,
          skip: false,
          cp1x: 23,
          cp1y: 120,
          cp2x: 25,
          cp2y: 120,
        ),
        _toEqualSplinePoint(
          x: 27,
          y: 125,
          skip: false,
          cp1x: 26,
          cp1y: 125,
          cp2x: 28,
          cp2y: 125,
        ),
        _toEqualSplinePoint(
          x: 30,
          y: 105,
          skip: false,
          cp1x: 29,
          cp1y: 105,
          cp2x: 31,
          cp2y: 105,
        ),
        _toEqualSplinePoint(
          x: 33,
          y: 110,
          skip: false,
          cp1x: 32,
          cp1y: 110,
          cp2x: 33,
          cp2y: 110,
        ),
        _toEqualSplinePoint(
          x: 33,
          y: 110,
          skip: false,
          cp1x: 33,
          cp1y: 110,
          cp2x: 34,
          cp2y: 110,
        ),
        _toEqualSplinePoint(x: 36, y: 170, skip: false, cp1x: 35, cp1y: 150),
      ]);
    });
  });
}
