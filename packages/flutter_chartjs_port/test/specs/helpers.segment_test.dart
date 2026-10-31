// Ported from Chart.js v4.6.1 test/specs/helpers.segment.tests.js (MIT, Chart.js Contributors).
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.segment.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/types/index.dart';
import 'package:test/test.dart';

/// A JavaScript object literal `{x, y}`, passed as a [PointElement]. The
/// members that the literal does not set are `null`, which stands for JS
/// `undefined` (index.dart). The control points are NaN, which stands for JS
/// `undefined` (`SplinePoint`).
final class _Point implements PointElement {
  _Point(this.x, this.y);

  @override
  final double x;

  @override
  final double y;

  @override
  bool? get skip => null;

  @override
  bool? get stop => null;

  @override
  Map<String, Object?>? get options => null;

  @override
  double cp1x = double.nan;

  @override
  double cp1y = double.nan;

  @override
  double cp2x = double.nan;

  @override
  double cp2y = double.nan;

  // The members of Chart.js ADR 0028 that this test does not read.
  @override
  bool get active => false;

  @override
  Object? get hidden => undefined;

  @override
  double size([Object? options]) => throw UnsupportedError('size');
}

/// A JavaScript object literal `{start, end, loop}`, passed as a [Segment].
/// It has no `style`, which is JS `undefined`.
final class _Segment implements Segment {
  const _Segment({required this.start, required this.end, required this.loop});

  @override
  final double start;

  @override
  final double end;

  @override
  final bool loop;

  @override
  Object? get style => null;
}

/// Jasmine `toEqual` on a number: SameValue, so NaN equals NaN and `-0` does
/// not equal `0`.
Matcher _sameValue(double expected) => predicate<double>(
  (actual) => expected.isNaN
      ? actual.isNaN
      : actual == expected && actual.isNegative == expected.isNegative,
  'SameValue ${jsNumberToString(expected)}',
);

/// Jasmine `toEqual({start, end, loop, style: undefined})` on a segment.
/// Dart `null` is the `undefined` of [Segment.style].
Matcher _toEqual({
  required double start,
  required double end,
  required bool loop,
}) => isA<Segment>()
    .having((s) => s.start, 'start', _sameValue(start))
    .having((s) => s.end, 'end', _sameValue(end))
    .having((s) => s.loop, 'loop', loop)
    .having((s) => s.style, 'style', isNull);

void main() {
  setUpSpecs();
  group('helpers.segments', () {
    group('_boundSegment', () {
      final points = [_Point(10, 1), _Point(20, 2), _Point(30, 3)];
      const segment = _Segment(start: 0, end: 2, loop: false);

      test('should not find segment from before the line', () {
        expect(
          boundSegment(segment, points, (
            property: 'x',
            start: 5,
            end: 9.99999,
          )),
          <Matcher>[],
        );
      });

      test('should not find segment from after the line', () {
        expect(
          boundSegment(segment, points, (
            property: 'x',
            start: 30.00001,
            end: 800,
          )),
          <Matcher>[],
        );
      });

      test('should find segment when starting before line', () {
        expect(
          boundSegment(segment, points, (property: 'x', start: 5, end: 15)),
          [_toEqual(start: 0, end: 1, loop: false)],
        );
      });

      test('should find segment directly on point', () {
        expect(
          boundSegment(segment, points, (property: 'x', start: 10, end: 10)),
          [_toEqual(start: 0, end: 0, loop: false)],
        );
      });

      test('should find segment from range between points', () {
        expect(
          boundSegment(segment, points, (property: 'x', start: 11, end: 14)),
          [_toEqual(start: 0, end: 1, loop: false)],
        );
      });

      test('should find segment from point between points', () {
        expect(
          boundSegment(segment, points, (property: 'x', start: 22, end: 22)),
          [_toEqual(start: 1, end: 2, loop: false)],
        );
      });

      test('should find whole segment', () {
        expect(
          boundSegment(segment, points, (property: 'x', start: 0, end: 50)),
          [_toEqual(start: 0, end: 2, loop: false)],
        );
      });

      test('should find correct segment from near points', () {
        expect(
          boundSegment(segment, points, (
            property: 'x',
            start: 10.001,
            end: 29.999,
          )),
          [_toEqual(start: 0, end: 2, loop: false)],
        );
      });

      test('should find segment from after the line', () {
        expect(
          boundSegment(segment, points, (property: 'x', start: 25, end: 35)),
          [_toEqual(start: 1, end: 2, loop: false)],
        );
      });

      test('should find multiple segments', () {
        final points2 = [
          _Point(0, 100),
          _Point(1, 50),
          _Point(2, 70),
          _Point(4, 80),
          _Point(5, -100),
        ];
        expect(
          boundSegment(
            const _Segment(start: 0, end: 4, loop: false),
            points2,
            (property: 'y', start: 60, end: 60),
          ),
          [
            _toEqual(start: 0, end: 1, loop: false),
            _toEqual(start: 1, end: 2, loop: false),
            _toEqual(start: 3, end: 4, loop: false),
          ],
        );
      });

      test(
        'should find correct segments when there are multiple points with '
        'same property value',
        () {
          final repeatedPoints = [
            _Point(1, 5),
            _Point(1, 6),
            _Point(2, 5),
            _Point(2, 6),
            _Point(3, 5),
            _Point(3, 6),
            _Point(3, 7),
          ];
          expect(
            boundSegment(
              const _Segment(start: 0, end: 6, loop: false),
              repeatedPoints,
              (property: 'x', start: 1, end: 1.1),
            ),
            [_toEqual(start: 0, end: 2, loop: false)],
          );
          expect(
            boundSegment(
              const _Segment(start: 0, end: 6, loop: false),
              repeatedPoints,
              (property: 'x', start: 2, end: 2.1),
            ),
            [_toEqual(start: 2, end: 4, loop: false)],
          );
          expect(
            boundSegment(
              const _Segment(start: 0, end: 6, loop: false),
              repeatedPoints,
              (property: 'x', start: 2, end: 3.1),
            ),
            [_toEqual(start: 2, end: 6, loop: false)],
          );
          expect(
            boundSegment(
              const _Segment(start: 0, end: 6, loop: false),
              repeatedPoints,
              (property: 'x', start: 0, end: 8),
            ),
            [_toEqual(start: 0, end: 6, loop: false)],
          );
        },
      );
    });
  });
}
