// Original code, not ported from Chart.js: tests of the filler stack line.

// The tests of lib/src/plugins/plugin.filler/filler.target.stack.dart
// (Chart.js ADR 0040, section 2). The group `adapt-line-points-elements`
// pins the wrap of the results of `interpolate`: a point element stays the
// same object, a plain point becomes a `PointElement` with `x` and `y`, and
// an Array becomes a bare `PointElement`. The P4 table is the output of a
// probe of the filler design on the pinned build in Node.js v24.12.0 on
// x64 (P4): the stack line of the style case with a bare point gives the
// bound segments
// `[0, 2]` and `[2, 5]`, as the Array of upstream, and with a point of NaN
// `x` and `y` it gives `[0, 2]` and `[3, 5]`. The file is a pure layer
// test: test:web runs it too.

import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/elements/element.line.dart';
import 'package:flutter_chartjs_port/src/elements/element.point.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.interpolation.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.segment.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.filler/filler.target.stack.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:test/test.dart';

/// A point element at ([x], [y]).
PointElement _pe(double x, double y) => PointElement()
  ..x = x
  ..y = y;

/// The points of the stack line of the style case, with [odd] at the
/// indexes 2 and 3 (p4_bare_point.mjs).
List<types.PointElement> _make(types.PointElement Function() odd) => [
  _pe(30.681640625, 483.6),
  _pe(30.681640625, 483.6),
  odd(),
  odd(),
  _pe(386.917724609375, 333.0666666666667),
  _pe(505.6630859375, 483.6),
  _pe(505.6630859375, 483.6),
];

/// `[start, end, loop]` of each segment.
List<List<Object?>> _segs(List<types.Segment> segments) => [
  for (final s in segments) [s.start, s.end, s.loop],
];

void main() {
  group('adapt-line-points-elements', () {
    const bounds = (
      property: 'x',
      start: 30.681640625,
      end: 505.6630859375,
    );

    test('P4: a bare point gives the bound segments of the Array', () {
      final line = LineElement(<String, Object?>{
        'points': _make(PointElement.new),
        'options': <String, Object?>{},
      });
      expect(_segs(line.segments), [
        [0, 6, false],
      ]);
      final bound = boundSegments(line, bounds);
      expect(_segs(bound), [
        [0, 2, false],
        [2, 5, false],
      ]);
      // The sub-bounds read `undefined` by name at the bare point.
      expect((line.points[2] as Element)['x'], same(undefined));
      expect(line.points[2].x, isNaN);
    });

    test('P4: a point of NaN x and y gives other bound segments', () {
      final line = LineElement(<String, Object?>{
        'points': _make(() => _pe(double.nan, double.nan)),
        'options': <String, Object?>{},
      });
      expect(_segs(boundSegments(line, bounds)), [
        [0, 2, false],
        [3, 5, false],
      ]);
    });

    test('a point element result stays the same object', () {
      final point = _pe(1, 2);
      expect(stackResultPoint(point), same(point));
    });

    test('a plain point result gives x and y', () {
      final point = stackResultPoint(InterpolatedPoint(3, 4))! as Element;
      expect(point, isA<PointElement>());
      expect(point['x'], 3);
      expect(point['y'], 4);
      expect(point['angle'], same(undefined));
      expect(point['skip'], same(undefined));
      // A JS null member is 0, its ToNumber.
      final nullY = stackResultPoint(InterpolatedPoint(3, null))!;
      expect(nullY.y, 0);
    });

    test('a List result gives a bare point', () {
      final point =
          stackResultPoint(<types.Point>[_pe(1, 2), _pe(3, 4)])! as Element;
      expect(point, isA<PointElement>());
      for (final key in ['x', 'y', 'angle', 'skip', 'stop']) {
        expect(point[key], same(undefined), reason: key);
      }
      expect(point.x, isNaN);
      expect(point.y, isNaN);
    });

    test('no result stays null', () {
      expect(stackResultPoint(null), isNull);
    });
  });
}
