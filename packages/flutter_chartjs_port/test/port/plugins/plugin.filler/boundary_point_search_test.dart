// Original code, not ported from Chart.js: boundary search differential tests.

import 'dart:math' as math;

import 'package:flutter_chartjs_port/src/elements/element.line.dart';
import 'package:flutter_chartjs_port/src/elements/element.point.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.filler/boundary_point_search.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.filler/filler.helper.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:test/test.dart';

PointElement _point(double x, double y) => PointElement()
  ..x = x
  ..y = y;

LineElement _line(List<types.PointElement> points) => LineElement({
  'points': points,
  'options': <String, Object?>{'tension': 0.0},
});

class _UnreadPoint extends PointElement {
  @override
  double get x => throw StateError('custom point read');
}

class _UnreadLine extends LineElement {
  @override
  List<types.PointElement> get points => throw StateError('custom line read');
}

void main() {
  tearDown(() => boundaryPointSearchEnabled = true);

  test('fresh gap boundaries return the original exact point on both axes', () {
    final random = math.Random(59);
    for (final axis in ['x', 'y']) {
      for (var sample = 0; sample < 100; sample++) {
        var value = -1000.0;
        final points = <types.PointElement>[];
        final count = 20 + 5 * random.nextInt(6);
        for (var i = 0; i < count; i++) {
          value += 0.1 + random.nextDouble() * 20;
          final point = axis == 'x' ? _point(value, 4) : _point(4, value);
          if (i % 5 == 2) point.skip = true;
          points.add(point);
        }
        final target = createBoundaryLine(
          axis == 'x' ? (x: null, y: 13.0) : (x: 13.0, y: null),
          _line(points),
        )!;
        final search = BoundaryPointSearch.create(target, axis)!;
        // Reverse and repeated queries must retain exact object identity too.
        final queries = [...target.points, ...target.points.reversed];
        for (final point in queries) {
          expect(search.find(point), same(target.interpolate(point, axis)));
        }
        final mid = axis == 'x'
            ? _point((target.points[0].x + target.points[1].x) / 2, 0)
            : _point(0, (target.points[0].y + target.points[1].y) / 2);
        expect(search.find(mid), isNull);
        expect(target.interpolate(mid, axis), isNotNull);
      }
    }
  });

  test(
    'duplicates, near coordinates, reversed and non-finite values fall back',
    () {
      for (final values in <List<double>>[
        [0, 1, 1, 3],
        [0, 1, 1 + 5e-7, 3],
        [3, 2, 1, 0],
        [0, 1, double.nan, 3],
        [0, 1, 2, double.infinity],
        [1e15, 1e15 + 1, 1e15 + 2, 1e15 + 3],
      ]) {
        expect(
          BoundaryPointSearch.create(
            _line([for (final value in values) _point(value, 3)]),
            'x',
          ),
          isNull,
        );
      }
    },
  );

  test(
    'short, nonconstant, skipped, stopped and looping boundaries fall back',
    () {
      expect(BoundaryPointSearch.create(_line([_point(0, 3)]), 'x'), isNull);
      for (var kind = 0; kind < 5; kind++) {
        final points = <types.PointElement>[
          for (var i = 0; i < 4; i++) _point(i.toDouble(), 3),
        ];
        final line = _line(points);
        switch (kind) {
          case 0:
            (points[1] as PointElement).y = 4;
          case 1:
            (points[1] as PointElement).skip = true;
          case 2:
            (points[1] as PointElement).stop = true;
          case 3:
            line.loop = true;
          case 4:
            for (final point in points) {
              (point as PointElement).y = double.infinity;
            }
        }
        expect(BoundaryPointSearch.create(line, 'x'), isNull);
      }
    },
  );

  test('foreign getters are not evaluated by validation or query lookup', () {
    expect(BoundaryPointSearch.create(_UnreadLine(), 'x'), isNull);
    expect(
      BoundaryPointSearch.create(
        _line([_UnreadPoint(), _point(1, 0), _point(2, 0), _point(3, 0)]),
        'x',
      ),
      isNull,
    );
    final target = _line([for (var i = 0; i < 4; i++) _point(i.toDouble(), 0)]);
    final search = BoundaryPointSearch.create(target, 'x')!;
    expect(search.find(_UnreadPoint()), isNull);
    expect(search.find(_point(double.nan, 0)), isNull);
    expect(search.find(_point(-1, 0)), isNull);
    expect(search.find(_point(4, 0)), isNull);
    expect(BoundaryPointSearch.create(target, 'angle'), isNull);
    boundaryPointSearchEnabled = false;
    expect(BoundaryPointSearch.create(target, 'x'), isNull);
  });
}
