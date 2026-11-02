// Original code, not ported from Chart.js: boundary segment differential tests.

import 'dart:math' as math;

import 'package:flutter_chartjs_port/src/elements/element.line.dart';
import 'package:flutter_chartjs_port/src/elements/element.point.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.segment.dart'
    show boundSegments, nativeSegmentType;
import 'package:flutter_chartjs_port/src/plugins/plugin.filler/boundary_point_search.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.filler/filler.helper.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.filler/filler.segment.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:test/test.dart';

PointElement _point(double x, double y) => PointElement()
  ..x = x
  ..y = y;

LineElement _line(List<types.PointElement> points) => LineElement({
  'points': points,
  'options': <String, Object?>{'tension': 0.0},
});

List<Object?> _segment(types.Segment segment) => [
  segment.start,
  segment.end,
  segment.loop,
  segment.style,
];

Object _number(double value) => value.isNaN ? 'NaN' : value;

List<Object?> _parts(List<FillPart> parts) => [
  for (final part in parts)
    [
      _segment(part.source),
      _segment(part.target! as types.Segment),
      _number(part.start.x),
      _number(part.start.y),
      _number(part.end.x),
      _number(part.end.y),
    ],
];

void main() {
  tearDown(() {
    boundaryPointSearchEnabled = true;
    boundarySegmentSearchEnabled = true;
  });

  test('ordered, overlapping and backward exact ranges match the scanner', () {
    final random = math.Random(60);
    for (final axis in ['x', 'y']) {
      for (var sample = 0; sample < 100; sample++) {
        var coordinate = -100.0;
        final points = <types.PointElement>[];
        for (var i = 0; i < 30; i++) {
          coordinate += 0.1 + random.nextDouble() * 10;
          final point = axis == 'x'
              ? _point(coordinate, 7)
              : _point(7, coordinate);
          if (i % 5 == 2) point.skip = true;
          points.add(point);
        }
        final target = createBoundaryLine(
          axis == 'x' ? (x: null, y: 2.0) : (x: 2.0, y: null),
          _line(points),
        )!;
        final search = BoundaryPointSearch.create(target, axis)!;
        final ranges = [
          for (var i = 0; i < target.points.length; i += 2) (i, i + 1),
          (0, target.points.length - 1),
          for (var i = target.points.length - 1; i >= 0; i--) (i, i),
          for (var i = 0; i < 20; i++)
            (random.nextInt(target.points.length), target.points.length - 1),
        ];
        for (final (first, last) in ranges) {
          final bounds = (
            property: axis,
            start: axis == 'x'
                ? target.points[first].x
                : target.points[first].y,
            end: axis == 'x' ? target.points[last].x : target.points[last].y,
          );
          final expected = boundSegments(target, bounds);
          final actual = search.bound(bounds)!;
          expect(expected, hasLength(1));
          expect(actual.runtimeType, nativeSegmentType);
          expect(_segment(actual), _segment(expected.single));
        }
      }
    }
  });

  test('misses and unsupported bounds do not leave a stale cursor', () {
    final target = _line([
      for (var i = 0; i < 8; i++) _point(i * 2.0, 3),
    ]);
    final search = BoundaryPointSearch.create(target, 'x')!;
    for (final bounds in [
      null,
      (property: 'y', start: 0.0, end: 2.0),
      (property: 'angle', start: 0.0, end: 2.0),
      (property: 'x', start: double.nan, end: 2.0),
      (property: 'x', start: 0.0, end: double.infinity),
      (property: 'x', start: 4.0, end: 2.0),
      (property: 'x', start: 0.0, end: 20.0),
      (property: 'x', start: -2.0, end: 2.0),
      (property: 'x', start: 0.0, end: 2.0 + 5e-7),
      (property: 'x', start: 1.0, end: 2.0),
    ]) {
      expect(search.bound(bounds), isNull);
      const valid = (property: 'x', start: 0.0, end: 4.0);
      expect(
        _segment(search.bound(valid)!),
        _segment(boundSegments(target, valid).single),
      );
    }
    boundarySegmentSearchEnabled = false;
    expect(search.bound((property: 'x', start: 0.0, end: 4.0)), isNull);
    // Disabling segment matching leaves the already shipped endpoint lookup on.
    expect(search.find(target.points[2]), same(target.points[2]));
  });

  test(
    'complete fill parts preserve source geometry and both color passes',
    () {
      final random = math.Random(600);
      for (final axis in ['x', 'y']) {
        for (var sample = 0; sample < 100; sample++) {
          final points = <types.PointElement>[
            for (var i = 0; i < 30; i++)
              (axis == 'x' ? _point(i * 2.0, 1) : _point(1, i * 2.0))
                ..skip = i % 5 == 2,
          ];
          final source = _line(points);
          final target = createBoundaryLine(
            axis == 'x' ? (x: null, y: 2.0) : (x: 2.0, y: null),
            source,
          )!;
          final search = BoundaryPointSearch.create(target, axis)!;
          // Change the source after the boundary is built. Interior crossings,
          // misses and reversed source ranges must still use original geometry.
          for (var i = 0; i < points.length; i++) {
            if (sample % 3 == 0 && random.nextBool()) {
              final value = random.nextInt(30) * 2.0;
              if (axis == 'x') {
                (points[i] as PointElement).x = value;
              } else {
                (points[i] as PointElement).y = value;
              }
            }
          }
          final expected = _parts(segments(source, target, axis));
          for (var pass = 0; pass < 2; pass++) {
            expect(
              _parts(segments(source, target, axis, boundarySearch: search)),
              expected,
            );
          }
        }
      }
    },
  );
}
