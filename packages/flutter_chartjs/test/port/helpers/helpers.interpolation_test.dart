// Original code, not ported from Chart.js: interpolation cases with no spec.
import 'package:flutter_chartjs/src/helpers/helpers.interpolation.dart';
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/types/geometric.dart';
import 'package:test/test.dart';

// Upstream behaviour that test/specs/helpers.interpolation.tests.js does not
// check (AGENTS.md rule 3). The expected values come from
// src/helpers/helpers.interpolation.ts at v4.5.1 in Node.js v24.12.0 on x64.

/// A JavaScript object literal `{x, y}`, passed as a [Point].
final class _Point implements Point {
  const _Point(this.x, this.y);

  @override
  final double? x;

  @override
  final double? y;
}

/// A JavaScript object literal `{x, y}` with no control points, passed as a
/// [SplinePoint]. `double.nan` stands for JS `undefined` (row
/// `adapt-spline-control-point-nan`).
final class _SplinePoint implements SplinePoint {
  _SplinePoint(this.x, this.y);

  @override
  final double x;

  @override
  final double y;

  @override
  bool? get skip => null;

  @override
  double cp1x = double.nan;

  @override
  double cp1y = double.nan;

  @override
  double cp2x = double.nan;

  @override
  double cp2y = double.nan;
}

/// Matches a double with the same value as [expected], where -0 differs from
/// +0 and NaN matches NaN, as `Object.is` does. A `null` matches only `null`.
Matcher _isSame(double? expected) => predicate<double?>(
  (actual) => expected == null || actual == null
      ? expected == actual
      : expected.isNaN
      ? actual.isNaN
      : actual == expected && actual.isNegative == expected.isNegative,
  'Object.is with the expected value',
);

Matcher _isPoint(double? x, double? y) => isA<InterpolatedPoint>()
    .having((p) => p.x, 'x', _isSame(x))
    .having((p) => p.y, 'y', _isSame(y));

/// Point coordinates for the tests that compare a function with its earlier
/// `jsToNumber` form: JS `null`, the signed zeros, NaN (a copied
/// `undefined`), the infinities, a subnormal, large values and finites.
const List<double?> _coordinates = [
  null,
  0,
  -0,
  double.nan,
  double.infinity,
  double.negativeInfinity,
  double.minPositive,
  -double.minPositive,
  1.4e154,
  -1.4e154,
  -0.6,
  -0.4,
  1,
  255.75,
  512.4,
  512.5,
];

void main() {
  group('helpers.interpolation', () {
    test('pointInLine makes a JS null member 0 (ToNumber)', () {
      // {x: "10", y: "5"}
      expect(
        pointInLine(const _Point(null, 10), const _Point(20, null), 0.5),
        _isPoint(10, 5),
      );
    });

    test('pointInLine and steppedInterpolation give the jsToNumber form', () {
      // The form before Chart.js ADR 0010: ToNumber through jsToNumber.
      double before(double? a, double? b, double t) =>
          jsToNumber(a) + t * (jsToNumber(b) - jsToNumber(a));
      for (final t in const [0.0, -0.0, 0.25, 0.5, 1.0]) {
        for (final a in _coordinates) {
          for (final b in _coordinates) {
            final reason = '$a to $b at $t';
            expect(
              pointInLine(_Point(a, b), _Point(b, a), t),
              _isPoint(before(a, b, t), before(b, a, t)),
              reason: reason,
            );
            expect(
              steppedInterpolation(_Point(a, b), _Point(b, a), t, 'middle').x,
              _isSame(before(a, b, t)),
              reason: reason,
            );
          }
        }
      }
    });

    test('pointInLine adds -0 and 0 to 0, as JS does', () {
      // {x: "0", y: "0"}. The literal -0 in a double context is -0.0.
      expect(
        pointInLine(const _Point(-0, 0), const _Point(-0, -0), 0),
        _isPoint(0, 0),
      );
    });

    test('steppedInterpolation copies a JS null y unchanged', () {
      // {x: "14", y: null}
      expect(
        steppedInterpolation(
          const _Point(10, null),
          const _Point(20, 20),
          0.4,
          'middle',
        ),
        _isPoint(14, null),
      );
    });

    test('steppedInterpolation treats stepped: true as "before"', () {
      expect(
        steppedInterpolation(
          const _Point(10, 10),
          const _Point(20, 20),
          0,
          true,
        ),
        _isPoint(10, 10),
      );
      expect(
        steppedInterpolation(
          const _Point(10, 10),
          const _Point(20, 20),
          0.4,
          true,
        ),
        _isPoint(14, 20),
      );
    });

    test('steppedInterpolation with t NaN', () {
      // A NaN comparison is false: "middle" takes p2.y, "before" p1.y.
      expect(
        steppedInterpolation(
          const _Point(10, 10),
          const _Point(20, 20),
          double.nan,
          'middle',
        ),
        _isPoint(double.nan, 20),
      );
      expect(
        steppedInterpolation(
          const _Point(10, 10),
          const _Point(20, 20),
          double.nan,
          'before',
        ),
        _isPoint(double.nan, 10),
      );
    });

    test('bezierInterpolation without control points gives NaN', () {
      // The control-point literals hold undefined: {x: "NaN", y: "NaN"}.
      expect(
        bezierInterpolation(_SplinePoint(10, 10), _SplinePoint(20, 30), 0.5),
        _isPoint(double.nan, double.nan),
      );
    });

    test('bezierInterpolation gives the bits of the reference engine', () {
      final pt1 = _SplinePoint(10, 10)
        ..cp2x = 12
        ..cp2y = 12;
      final pt2 = _SplinePoint(20, 30)
        ..cp1x = 18
        ..cp1y = 28;
      // {x: "11.616", y: "12.655999999999999"}
      expect(
        bezierInterpolation(pt1, pt2, 0.2),
        _isPoint(11.616, 12.655999999999999),
      );
      // {x: "17.336", y: "25.176"}
      expect(bezierInterpolation(pt1, pt2, 0.7), _isPoint(17.336, 25.176));
    });
  });
}
