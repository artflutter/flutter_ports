// Original code, not ported from Chart.js: tests of the filler drawing.

// The tests of lib/src/plugins/plugin.filler/filler.drawing.dart. The group
// `adapt-filler-target-classes` pins the dispatch of Chart.js ADR 0040,
// section 4: a fill target that is not a `types.LineElement` and not a
// `types.SimpleArc` throws a TypeError, as the call of the missing member
// `interpolate` or `pathSegment` throws upstream. It also pins
// `clipToIndexBounds` (#12283, Chart.js ADR 0040, section 8). The drawfill
// calls of the dispatch throw and of the radar without a layout are in
// filler.target_test.dart. The file is a pure layer test: test:web runs it
// too.

import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/src/elements/element.line.dart';
import 'package:flutter_chartjs_port/src/elements/element.point.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.filler/filler.drawing.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.filler/simpleArc.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:test/test.dart';

/// A chart area.
final class _Area implements types.ChartArea {
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

/// A cartesian index scale: `getPixelForValue(v)` is `10 * v`.
final class _IndexScale implements types.Scale {
  _IndexScale({required this.horizontal, required this.min, required this.max});

  final bool horizontal;
  @override
  final double min;
  @override
  final double max;
  @override
  bool isHorizontal() => horizontal;
  @override
  double getPixelForValue(Object? value, [double? index]) =>
      10 * jsToNumber(value);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A radial scale that the code tests by its type only.
final class _RadialScale implements types.RadialLinearScale {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// `[left, top, right, bottom]` of [trbl].
List<double> _edges(types.TRBL trbl) => [
  trbl.left,
  trbl.top,
  trbl.right,
  trbl.bottom,
];

/// A line of two points from (10, 20) to (30, 40).
LineElement _line() => LineElement(<String, Object?>{
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

void main() {
  group('adapt-filler-target-classes', () {
    final point = PointElement()..x = 20;

    test('a point element as the target throws a TypeError', () {
      final ctx = createMockContext();
      expect(
        () => interpolatedLineTo(ctx, PointElement(), point, 'x'),
        throwsA(isA<TypeError>()),
      );
      expect(ctx.getCalls(), isEmpty);
    });

    test('true (shape) as the target throws a TypeError', () {
      expect(
        () => interpolatedLineTo(createMockContext(), true, point, 'x'),
        throwsA(isA<TypeError>()),
      );
    });

    test('a line target calls lineTo at the interpolated point', () {
      final ctx = createMockContext();
      interpolatedLineTo(ctx, _line(), point, 'x');
      expect(ctx.getCalls(), [
        {
          'name': 'lineTo',
          'args': [20.0, 30.0],
        },
      ]);
    });

    test('a line target without the value makes no call', () {
      final ctx = createMockContext();
      interpolatedLineTo(ctx, _line(), PointElement()..x = 99, 'x');
      expect(ctx.getCalls(), isEmpty);
    });

    test('a List result calls lineTo(NaN, NaN)', () {
      // A line whose x goes back: the value 2 lies in two parts.
      final line = LineElement(<String, Object?>{
        'points': [
          for (final (x, y) in [(0.0, 1.0), (4.0, 2.0), (1.0, 3.0)])
            PointElement()
              ..x = x
              ..y = y,
        ],
        'options': <String, Object?>{},
      });
      expect(
        line.interpolate(PointElement()..x = 2, 'x'),
        isA<List<Object?>>(),
      );
      final ctx = createMockContext();
      interpolatedLineTo(ctx, line, PointElement()..x = 2, 'x');
      final args = ctx.getCalls().single['args']! as List<Object?>;
      expect(args, hasLength(2));
      expect(args[0], isNaN);
      expect(args[1], isNaN);
    });

    test('a SimpleArc target calls lineTo on the circle', () {
      final ctx = createMockContext();
      interpolatedLineTo(
        ctx,
        SimpleArc(x: 5, y: 6, radius: 0),
        PointElement()..angle = 1,
        'angle',
      );
      expect(ctx.getCalls(), [
        {
          'name': 'lineTo',
          'args': [5.0, 6.0],
        },
      ]);
    });
  });

  group('clipToIndexBounds (#12283)', () {
    const area = _Area(30, 20, 500, 480);

    test('no index scale and a radial scale give the area', () {
      expect(clipToIndexBounds(area, null), same(area));
      expect(clipToIndexBounds(area, _RadialScale()), same(area));
      expect(clipToIndexBounds(null, _RadialScale()), isNull);
    });

    test('a horizontal index scale clips left and right', () {
      final iScale = _IndexScale(horizontal: true, min: 10, max: 60);
      expect(_edges(clipToIndexBounds(area, iScale)!), [100, 20, 500, 480]);
      final wide = _IndexScale(horizontal: true, min: 1, max: 40);
      expect(_edges(clipToIndexBounds(area, wide)!), [30, 20, 400, 480]);
    });

    test('a vertical index scale clips top and bottom', () {
      final iScale = _IndexScale(horizontal: false, min: 40, max: 5);
      expect(_edges(clipToIndexBounds(area, iScale)!), [30, 50, 500, 400]);
    });

    test('a cartesian index scale without an area throws a TypeError', () {
      final iScale = _IndexScale(horizontal: true, min: 10, max: 60);
      expect(
        () => clipToIndexBounds(null, iScale),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
