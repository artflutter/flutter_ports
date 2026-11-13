// Ported from Chart.js v4.6.1 test/specs/helpers.interpolation.tests.js (MIT, Chart.js Contributors).
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.interpolation.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/types/geometric.dart';
import 'package:flutter_chartjs_port/src/types/line_option_enums.dart'
    show SteppedLine;
import 'package:test/test.dart';

/// A JavaScript object literal `{x, y}`, passed as a [Point].
final class const _Point(@override final double? x, @override final double? y)
    implements Point;

/// A JavaScript object literal `{x, y, cp1x, cp1y, cp2x, cp2y}`, passed as a
/// [SplinePoint]. A member that the literal does not set is `double.nan`,
/// which stands for JS `undefined` (row `adapt-spline-control-point-nan`).
final class _SplinePoint({
  @override required final double x,
  @override required final double y,
  @override var double cp1x = double.nan,
  @override var double cp1y = double.nan,
  @override var double cp2x = double.nan,
  @override var double cp2y = double.nan,
}) implements SplinePoint {
  @override
  bool? get skip => null;
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
          SteppedLine.before,
        ),
        _toEqual(10, 10),
      );
      expect(
        steppedInterpolation(
          const _Point(10, 10),
          const _Point(20, 20),
          0.4,
          SteppedLine.before,
        ),
        _toEqual(14, 20),
      );
      expect(
        steppedInterpolation(
          const _Point(10, 10),
          const _Point(20, 20),
          0.5,
          SteppedLine.before,
        ),
        _toEqual(15, 20),
      );
      expect(
        steppedInterpolation(
          const _Point(10, 10),
          const _Point(20, 20),
          1,
          SteppedLine.before,
        ),
        _toEqual(20, 20),
      );

      expect(
        steppedInterpolation(
          const _Point(10, 10),
          const _Point(20, 20),
          0,
          SteppedLine.middle,
        ),
        _toEqual(10, 10),
      );
      expect(
        steppedInterpolation(
          const _Point(10, 10),
          const _Point(20, 20),
          0.4,
          SteppedLine.middle,
        ),
        _toEqual(14, 10),
      );
      expect(
        steppedInterpolation(
          const _Point(10, 10),
          const _Point(20, 20),
          0.5,
          SteppedLine.middle,
        ),
        _toEqual(15, 20),
      );
      expect(
        steppedInterpolation(
          const _Point(10, 10),
          const _Point(20, 20),
          1,
          SteppedLine.middle,
        ),
        _toEqual(20, 20),
      );

      expect(
        steppedInterpolation(
          const _Point(10, 10),
          const _Point(20, 20),
          0,
          SteppedLine.after,
        ),
        _toEqual(10, 10),
      );
      expect(
        steppedInterpolation(
          const _Point(10, 10),
          const _Point(20, 20),
          0.4,
          SteppedLine.after,
        ),
        _toEqual(14, 10),
      );
      expect(
        steppedInterpolation(
          const _Point(10, 10),
          const _Point(20, 20),
          0.5,
          SteppedLine.after,
        ),
        _toEqual(15, 10),
      );
      expect(
        steppedInterpolation(
          const _Point(10, 10),
          const _Point(20, 20),
          1,
          SteppedLine.after,
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
