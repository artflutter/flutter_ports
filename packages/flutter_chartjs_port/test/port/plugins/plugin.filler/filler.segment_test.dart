// Original code, not ported from Chart.js: tests of the filler segments.

// The tests of lib/src/plugins/plugin.filler/filler.segment.dart (Chart.js
// ADR 0040, sections 1 and 3). The group `adapt-line-points-elements` pins
// the wraps of the difference: an edge object `{[property]: edge}` is a
// `PointElement` with only that property, and a boundary point `{x, y}` is
// a `PointElement` with only `x` and `y`. The radar case is the case P2 of
// a probe of the filler design on the pinned build in Node.js v24.12.0 on
// x64: a radar with a gap on a polygon grid, with the segments, the edge
// objects and the boundary points that `_segments` gives. The expected
// values here are the values that the probe logged. The file is a pure
// layer test: test:web runs it too.

import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/elements/element.line.dart';
import 'package:flutter_chartjs_port/src/elements/element.point.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.filler/filler.segment.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.filler/simpleArc.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:test/test.dart';

/// A point element with [x], [y] and [angle].
PointElement _point(double x, double y, double angle, {bool skip = false}) {
  final point = PointElement()
    ..x = x
    ..y = y
    ..angle = angle;
  if (skip) point['skip'] = true;
  return point;
}

/// The source line of the case P2: a radar line with a gap at index 2.
LineElement _radarSource() => LineElement(<String, Object?>{
  'points': [
    _point(256, 172.5, -1.5707963267948966),
    _point(460.477151003458, 213.56134620938633, -0.3141592653589793),
    _point(double.nan, double.nan, 0.9424777960769379, skip: true),
    _point(129.6261707571183, 453.93865379061367, 2.199114857512855),
    _point(153.76142449827097, 246.78067310469316, 3.4557519189487724),
  ],
  'options': <String, Object?>{},
  '_loop': true,
});

/// The target line of the case P2: the polygon of the origin, five wrapped
/// records `{x, y, angle}` at the center (filler.helper.js:28-33).
LineElement _radarTarget() => LineElement(<String, Object?>{
  'points': [
    for (final angle in [
      -1.5707963267948966,
      -0.3141592653589793,
      0.9424777960769379,
      2.199114857512855,
      3.4557519189487724,
    ])
      _point(256, 280, angle),
  ],
  'options': <String, Object?>{'tension': 0.0},
  '_loop': true,
  '_fullLoop': true,
});

/// `[x, y, angle]` of [point], read by name.
List<Object?> _byName(types.PointElement point) {
  final element = point as Element;
  return [element['x'], element['y'], element['angle']];
}

void main() {
  group('adapt-line-points-elements', () {
    test('the radar gap: edge objects with only angle (case P2)', () {
      final source = _radarSource();
      final target = _radarTarget();
      final parts = segments(source, target, 'angle');

      expect(parts, hasLength(1));
      final part = parts.single;
      expect(
        [part.source.start, part.source.end, part.source.loop],
        [
          3,
          1,
          false,
        ],
      );
      expect(part.target, isA<types.Segment>());
      // Math.max and Math.min of the bounds and the sub-bounds
      // (filler.segment.js:38-43): only the property `angle`.
      expect(_byName(part.start), [undefined, undefined, 2.199114857512855]);
      expect(_byName(part.end), [undefined, undefined, 5.969026041820607]);
      expect(part.start.x, isNaN);

      // interpolate of the edge objects gives the target points 1 and 3
      // themselves (p1 === p2), at (256, 280).
      expect(target.interpolate(part.end, 'angle'), same(target.points[1]));
      expect(target.interpolate(part.start, 'angle'), same(target.points[3]));
    });

    test('getBounds reads angle through the access by name', () {
      final first = PointElement()..angle = 7.5;
      final last = PointElement()..angle = -1;
      final bounds = getBounds('angle', first, last);
      expect(bounds, isNotNull);
      expect(bounds!.property, 'angle');
      // _normalizeAngle (helpers.math.ts:160).
      expect(bounds.start, closeTo(7.5 - 6.283185307179586, 1e-12));
      expect(bounds.end, closeTo(6.283185307179586 - 1, 1e-12));
      expect(getBounds('angle', first, last, true), isNull);
    });

    test('a bare point gives NaN bounds, where upstream gives undefined', () {
      final bounds = getBounds('x', PointElement(), PointElement()..x = 3);
      expect(bounds!.start, isNaN);
      expect(bounds.end, 3);
    });

    test('pointsFromSegments makes points with only x and y', () {
      final line = LineElement(<String, Object?>{
        'points': [
          PointElement()
            ..x = 10
            ..y = 20,
          PointElement()
            ..x = 30
            ..y = 40,
          PointElement()
            ..x = 50
            ..y = double.nan,
        ],
        'options': <String, Object?>{},
      });
      final horizontal = pointsFromSegments((x: null, y: 400), line);
      expect(
        [for (final p in horizontal) _byName(p)],
        [
          [10, 400, undefined],
          [30, 400, undefined],
        ],
      );
      final vertical = pointsFromSegments((x: 5, y: null), line);
      expect(
        [for (final p in vertical) _byName(p)],
        [
          [5, 20, undefined],
          [5, 40, undefined],
        ],
      );
      expect(pointsFromSegments(null, line), isEmpty);
      expect(pointsFromSegments((x: null, y: null), line), isEmpty);
      for (final p in [...horizontal, ...vertical]) {
        expect(p, isA<PointElement>());
        expect((p as Element)['skip'], same(undefined));
      }
    });
  });

  group('segments with a target that is not a line', () {
    LineElement source() => LineElement(<String, Object?>{
      'points': [
        PointElement()
          ..x = 10
          ..y = 20,
        PointElement()
          ..x = 30
          ..y = 40,
      ],
      'options': <String, Object?>{},
    });

    test('a SimpleArc takes the simpleArc branch (filler.segment.js:15)', () {
      final line = source();
      final parts = segments(
        line,
        SimpleArc(x: 0, y: 0, radius: 1),
        'x',
      );
      expect(parts, hasLength(1));
      expect(parts.single.target, (property: 'x', start: 10.0, end: 30.0));
      expect(parts.single.start, same(line.points[0]));
      expect(parts.single.end, same(line.points[1]));
    });

    test('true (shape) takes the simpleArc branch', () {
      final line = source();
      final parts = segments(line, true, 'y');
      expect(parts.single.target, (property: 'y', start: 20.0, end: 40.0));
    });
  });

  test('findSegmentEnd skips the points with a NaN x or y', () {
    final points = <types.PointElement>[
      for (final (x, y) in [(1.0, 1.0), (2.0, double.nan), (double.nan, 3.0)])
        PointElement()
          ..x = x
          ..y = y,
    ];
    expect(findSegmentEnd(0, 2, points), 0);
    expect(findSegmentEnd(1, 2, points), 1);
  });
}
