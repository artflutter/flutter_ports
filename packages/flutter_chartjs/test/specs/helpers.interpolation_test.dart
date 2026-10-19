// Ported from Chart.js v4.5.1 test/specs/helpers.interpolation.tests.js (MIT, Chart.js Contributors).
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs/src/helpers/helpers.interpolation.dart';
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/types/geometric.dart';
import 'package:test/test.dart';

/// A JavaScript object literal `{x, y}`, passed as a [Point].
final class _Point implements Point {
  const _Point(this.x, this.y);

  @override
  final double? x;

  @override
  final double? y;
}

/// A JavaScript object literal `{x, y, cp1x, cp1y, cp2x, cp2y}`, passed as a
/// [SplinePoint]. A member that the literal does not set is `double.nan`,
/// which stands for JS `undefined` (row `adapt-spline-control-point-nan`).
final class _SplinePoint implements SplinePoint {
  _SplinePoint({
    required this.x,
    required this.y,
    this.cp1x = double.nan,
    this.cp1y = double.nan,
    this.cp2x = double.nan,
    this.cp2y = double.nan,
  });

  @override
  final double x;

  @override
  final double y;

  @override
  bool? get skip => null;

  @override
  double cp1x;

  @override
  double cp1y;

  @override
  double cp2x;

  @override
  double cp2y;
}

/// Jasmine `toEqual` on a number: SameValue, so NaN equals NaN and `-0` does
/// not equal `0`.
Matcher _sameValue(double expected) => predicate<double?>(
  (actual) =>
      actual != null &&
      (expected.isNaN
          ? actual.isNaN
          : actual == expected && actual.isNegative == expected.isNegative),
  'SameValue ${jsNumberToString(expected)}',
);

/// Jasmine `toEqual({x, y})`. The functions return a literal with exactly
/// the members `x` and `y`, which [InterpolatedPoint] has.
Matcher _toEqual(double x, double y) => isA<InterpolatedPoint>()
    .having((p) => p.x, 'x', _sameValue(x))
    .having((p) => p.y, 'y', _sameValue(y));

void main() {
  setUpSpecs();
  group('helpers.interpolation', () {
    test('Should interpolate a point in line', () {
      expect(
        pointInLine(const _Point(10, 10), const _Point(20, 20), 0),
        _toEqual(10, 10),
      );
      expect(
        pointInLine(const _Point(10, 10), const _Point(20, 20), 0.5),
        _toEqual(15, 15),
      );
      expect(
        pointInLine(const _Point(10, 10), const _Point(20, 20), 1),
        _toEqual(20, 20),
      );
    });

    test('Should interpolate a point in stepped line', () {
      expect(
        steppedInterpolation(
          const _Point(10, 10),
          const _Point(20, 20),
          0,
          'before',
        ),
        _toEqual(10, 10),
      );
      expect(
        steppedInterpolation(
          const _Point(10, 10),
          const _Point(20, 20),
          0.4,
          'before',
        ),
        _toEqual(14, 20),
      );
      expect(
        steppedInterpolation(
          const _Point(10, 10),
          const _Point(20, 20),
          0.5,
          'before',
        ),
        _toEqual(15, 20),
      );
      expect(
        steppedInterpolation(
          const _Point(10, 10),
          const _Point(20, 20),
          1,
          'before',
        ),
        _toEqual(20, 20),
      );

      expect(
        steppedInterpolation(
          const _Point(10, 10),
          const _Point(20, 20),
          0,
          'middle',
        ),
        _toEqual(10, 10),
      );
      expect(
        steppedInterpolation(
          const _Point(10, 10),
          const _Point(20, 20),
          0.4,
          'middle',
        ),
        _toEqual(14, 10),
      );
      expect(
        steppedInterpolation(
          const _Point(10, 10),
          const _Point(20, 20),
          0.5,
          'middle',
        ),
        _toEqual(15, 20),
      );
      expect(
        steppedInterpolation(
          const _Point(10, 10),
          const _Point(20, 20),
          1,
          'middle',
        ),
        _toEqual(20, 20),
      );

      expect(
        steppedInterpolation(
          const _Point(10, 10),
          const _Point(20, 20),
          0,
          'after',
        ),
        _toEqual(10, 10),
      );
      expect(
        steppedInterpolation(
          const _Point(10, 10),
          const _Point(20, 20),
          0.4,
          'after',
        ),
        _toEqual(14, 10),
      );
      expect(
        steppedInterpolation(
          const _Point(10, 10),
          const _Point(20, 20),
          0.5,
          'after',
        ),
        _toEqual(15, 10),
      );
      expect(
        steppedInterpolation(
          const _Point(10, 10),
          const _Point(20, 20),
          1,
          'after',
        ),
        _toEqual(20, 20),
      );
    });

    test('Should interpolate a point in curve', () {
      final pt1 = _SplinePoint(x: 10, y: 10, cp2x: 12, cp2y: 12);
      final pt2 = _SplinePoint(x: 20, y: 30, cp1x: 18, cp1y: 28);

      expect(bezierInterpolation(pt1, pt2, 0), _toEqual(10, 10));
      expect(
        bezierInterpolation(pt1, pt2, 0.2),
        toBeCloseToPoint({'x': 11.616, 'y': 12.656}),
      );
      expect(bezierInterpolation(pt1, pt2, 1), _toEqual(20, 30));
    });
  });
}
