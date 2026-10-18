// Original code, not ported from Chart.js: helpers.curve cases with no spec.
import 'package:flutter_chartjs/src/helpers/helpers.config.dart'
    show createResolver;
import 'package:flutter_chartjs/src/helpers/helpers.curve.dart';
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/types/geometric.dart';
import 'package:test/test.dart';

// Upstream behaviour that test/specs/helpers.curve.tests.js does not check
// (AGENTS.md rule 3). The spec has no case for `_updateBezierControlPoints`
// and `capBezierPoints`. The expected values come from the upstream
// `helpers.curve.ts` (Chart.js v4.5.1, loaded with type stripping) in
// Node.js v24.12.0 on x64.

/// A JavaScript object literal `{x, y, skip}`, passed as a [SplinePoint].
final class _P implements SplinePoint {
  _P(this.x, this.y, {this.skip});

  @override
  final double x;

  @override
  final double y;

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

/// A JavaScript object literal `{left, top, right, bottom, width, height}`.
final class _Area implements ChartArea {
  const _Area(this.left, this.top, this.right, this.bottom);

  @override
  final double left;

  @override
  final double top;

  @override
  final double right;

  @override
  final double bottom;

  @override
  double get width => right - left;

  @override
  double get height => bottom - top;
}

/// SameValue of two numbers. `null` stands for `undefined`.
bool _sameValue(double? actual, double? expected) => expected == null
    ? actual == null
    : actual != null &&
          (expected.isNaN
              ? actual.isNaN
              : actual == expected && actual.isNegative == expected.isNegative);

String _show(double? v) => v == null ? 'undefined' : jsNumberToString(v);

/// The control points `(cp1x, cp1y, cp2x, cp2y)` of each point, compared
/// with SameValue. An expected `null` is JS `undefined`. The port stores it as
/// `double.nan` (row `adapt-spline-control-point-nan`).
typedef _Cp = (double?, double?, double?, double?);

Matcher _hasControlPoints(List<_Cp> expected) => predicate<List<_P>>((points) {
  if (points.length != expected.length) return false;
  for (var i = 0; i < points.length; i++) {
    final p = points[i];
    final e = expected[i];
    if (!_sameValue(p.cp1x, e.$1 ?? double.nan) ||
        !_sameValue(p.cp1y, e.$2 ?? double.nan) ||
        !_sameValue(p.cp2x, e.$3 ?? double.nan) ||
        !_sameValue(p.cp2y, e.$4 ?? double.nan)) {
      return false;
    }
  }
  return true;
}, 'control points ${expected.map(_showCp).join(', ')}');

String _showCp(_Cp e) =>
    '(${_show(e.$1)}, ${_show(e.$2)}, ${_show(e.$3)}, ${_show(e.$4)})';

List<_P> _points() => [
  _P(0, 10),
  _P(10, 30),
  _P(20, -5),
  _P(30, 25),
  _P(40, 0),
];

const _area = _Area(0, 0, 40, 30);

void main() {
  group('_updateBezierControlPoints', () {
    test('splines the points and caps them to the area', () {
      final points = _points();
      updateBezierControlPoints(
        points,
        {'tension': 0.4, 'capBezierPoints': true},
        _area,
        false,
        'x',
      );
      expect(
        points,
        _hasControlPoints([
          (0, 10, 4, 18),
          (6.955723347345597, 30, 14.955723347345597, 26.283207489490803),
          (
            15.719050912544834,
            -3.9297627281362084,
            23.719050912544834,
            -5.929762728136208,
          ),
          (
            25.679107441347494,
            23.919776860336874,
            33.67910744134749,
            25.919776860336874,
          ),
          (36, 10, 40, 0),
        ]),
      );
    });

    test('splines a loop and does not cap without capBezierPoints', () {
      final points = _points();
      updateBezierControlPoints(points, {'tension': 0.4}, _area, true, 'x');
      expect(
        points,
        _hasControlPoints([
          (
            7.780455542707112,
            2.219544457292888,
            -4.219544457292888,
            14.219544457292887,
          ),
          (
            6.955723347345597,
            32.2832074894908,
            14.955723347345597,
            26.283207489490803,
          ),
          (
            15.719050912544834,
            -3.9297627281362084,
            23.719050912544834,
            -5.929762728136208,
          ),
          (
            25.679107441347494,
            23.919776860336874,
            33.67910744134749,
            25.919776860336874,
          ),
          (
            44.74067896072278,
            2.3703394803613906,
            32.740678960722775,
            -3.6296605196386107,
          ),
        ]),
      );
    });

    test('reads an absent tension as undefined, which gives NaN', () {
      for (final options in [
        <String, Object?>{},
        <String, Object?>{'tension': undefined},
      ]) {
        final points = _points();
        updateBezierControlPoints(points, options, _area, false, 'x');
        expect(
          points,
          _hasControlPoints([
            for (var i = 0; i < 5; i++)
              (double.nan, double.nan, double.nan, double.nan),
          ]),
        );
      }
    });

    test('reads a null tension as 0', () {
      final points = _points();
      updateBezierControlPoints(
        points,
        {'tension': null},
        _area,
        false,
        'x',
      );
      expect(
        points,
        _hasControlPoints([
          (0, 10, 0, 10),
          (10, 30, 10, 30),
          (20, -5, 20, -5),
          (30, 25, 30, 25),
          (40, 0, 40, 0),
        ]),
      );
    });

    test('reads a resolver through its get trap', () {
      // The has trap of a prefixed resolver does not know 'tension'. The get
      // trap gives the null of 'hoverTension', and null tension gives 0.
      final points = _points();
      updateBezierControlPoints(
        points,
        createResolver(
          [
            <String, Object?>{'hoverTension': null},
          ],
          ['hover', ''],
        ),
        _area,
        false,
        'x',
      );
      expect(
        points,
        _hasControlPoints([
          (0, 10, 0, 10),
          (10, 30, 10, 30),
          (20, -5, 20, -5),
          (30, 25, 30, 25),
          (40, 0, 40, 0),
        ]),
      );
    });

    test('drops skipped points with spanGaps, monotone on the y axis', () {
      final points = [
        _P(10, 0),
        _P(30, 10),
        _P(0, 20, skip: true),
        _P(5, 30),
        _P(25, 40),
      ];
      updateBezierControlPoints(
        points,
        {
          'cubicInterpolationMode': 'monotone',
          'spanGaps': true,
          'capBezierPoints': true,
        },
        const _Area(0, 0, 28, 40),
        false,
        'y',
      );
      expect(
        points,
        _hasControlPoints([
          (null, null, 16.666666666666668, 3.3333333333333335),
          (30, 6.666666666666666, 30, 16.666666666666668),
          (null, null, null, null),
          (5, 23.333333333333332, 5, 33.333333333333336),
          (18.333333333333332, 36.666666666666664, null, null),
        ]),
      );
    });

    test('reads the radar index axis r as undefined, monotone', () {
      // plugin.filler passes the indexAxis 'r' of a radar chart.
      final points = _points();
      updateBezierControlPoints(
        points,
        {'cubicInterpolationMode': 'monotone'},
        _area,
        false,
        'r',
      );
      expect(
        points,
        _hasControlPoints([
          (null, null, double.nan, null),
          (double.nan, null, double.nan, null),
          (double.nan, null, double.nan, null),
          (double.nan, null, double.nan, null),
          (double.nan, null, null, null),
        ]),
      );

      final capped = _points();
      updateBezierControlPoints(
        capped,
        {'cubicInterpolationMode': 'monotone', 'capBezierPoints': true},
        _area,
        false,
        'r',
      );
      expect(
        capped,
        _hasControlPoints([
          (null, null, double.nan, double.nan),
          (double.nan, double.nan, double.nan, null),
          (double.nan, null, double.nan, null),
          (double.nan, null, double.nan, double.nan),
          (double.nan, double.nan, null, null),
        ]),
      );
    });

    test('keeps a skipped point without spanGaps', () {
      final points = [
        _P(0, 0),
        _P(10, 10, skip: true),
        _P(20, 0),
        _P(30, 20),
      ];
      updateBezierControlPoints(
        points,
        {'tension': 0.5},
        _area,
        false,
        'x',
      );
      expect(
        points,
        _hasControlPoints([
          (0, 0, 0, 0),
          (5, 10, 15, 10),
          (20, 0, 25, 10),
          (25, 10, 30, 20),
        ]),
      );
    });

    test('accepts no points, and no drawn points', () {
      final empty = <_P>[];
      updateBezierControlPoints(
        empty,
        {'tension': 0.4, 'capBezierPoints': true},
        _area,
        true,
        'x',
      );
      expect(empty, isEmpty);

      final skipped = [_P(1, 1, skip: true)];
      updateBezierControlPoints(
        skipped,
        {'spanGaps': true, 'capBezierPoints': true},
        _area,
        true,
        'x',
      );
      expect(skipped, _hasControlPoints([(null, null, null, null)]));
    });
  });

  group('splineCurve', () {
    test('gives the middle point when all points are the same', () {
      final r = splineCurve(_P(1, 1), _P(1, 1), _P(1, 1), 0.4);
      expect([r.previous.x, r.previous.y, r.next.x, r.next.y], [1, 1, 1, 1]);
    });

    test('replaces a skipped neighbour with the middle point', () {
      final r = splineCurve(_P(0, 0, skip: true), _P(1, 1), _P(2, 5), 0.5);
      expect(
        [
          r.previous.x,
          r.previous.y,
          r.next.x,
          r.next.y,
        ],
        [1, 1, 1.5, 3],
      );
    });
  });

  group('adapt-spline-control-point-nan', () {
    // Upstream leaves an unset control point undefined. The port stores
    // double.nan. Every upstream reader gets NaN from both.
    test('reads an unset control point as NaN', () {
      final p = _P(1, 2);
      expect([p.cp1x, p.cp1y, p.cp2x, p.cp2y], everyElement(isNaN));
    });

    test('capBezierPoints keeps an unset control point NaN', () {
      // Monotone mode leaves cp1 of the point after a skipped point unset.
      // capBezierPoints then gives Math.max(Math.min(undefined, max), min),
      // which is NaN upstream.
      final points = [
        _P(0, 10),
        _P(10, 20, skip: true),
        _P(20, 5),
        _P(30, 25),
      ];
      updateBezierControlPoints(
        points,
        {'cubicInterpolationMode': 'monotone', 'capBezierPoints': true},
        _area,
        false,
        'x',
      );
      expect([points[2].cp1x, points[2].cp1y], everyElement(isNaN));
      expect(points[2].cp2x, 23.333333333333332);
      expect(
        [points[1].cp1x, points[1].cp1y, points[1].cp2x, points[1].cp2y],
        everyElement(isNaN),
      );
    });
  });
}
