// Original code, not ported from Chart.js: tests of the filler simpleArc.
// ignore_for_file: file_names

// The tests of lib/src/plugins/plugin.filler/simpleArc.dart (Chart.js ADR
// 0040, section 5). The arc calls are the calls that the circular radar
// probes of the filler design logged (the pinned build in Node.js v24.12.0
// on x64): `arc(256, 280, 0, 6.283185307179586, 0, true)`
// for a full circle and `arc(256, 280, 0, 5.969026041820607,
// 2.199114857512855, true)` for the bounds of a gap. The file is a pure
// layer test: test:web runs it too. The negative radius needs the dart:ui
// canvas: simpleArc_ui_test.dart.

import 'dart:math' as math;

import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/src/elements/element.point.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.filler/simpleArc.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:test/test.dart';

void main() {
  group('pathSegment', () {
    test('a full circle without bounds (simpleArc.js:13)', () {
      final ctx = createMockContext();
      final arc = SimpleArc(x: 256, y: 280, radius: 0);
      expect(
        arc.pathSegment(ctx, null, <String, Object?>{'move': false}),
        isTrue,
      );
      expect(ctx.getCalls(), [
        {
          'name': 'arc',
          'args': [256.0, 280.0, 0.0, 6.283185307179586, 0.0, true],
        },
      ]);
    });

    test('the bounds of a gap: from end to start, counterclockwise', () {
      final ctx = createMockContext();
      final arc = SimpleArc(x: 256, y: 280, radius: 0);
      const bounds = (
        property: 'angle',
        start: 2.199114857512855,
        end: 5.969026041820607,
      );
      final result = arc.pathSegment(ctx, bounds, <String, Object?>{
        'move': true,
        'reverse': true,
      });
      expect(result, isTrue);
      expect(ctx.getCalls(), [
        {
          'name': 'arc',
          'args': [
            256.0,
            280.0,
            0.0,
            5.969026041820607,
            2.199114857512855,
            true,
          ],
        },
      ]);
    });

    test('the result is !opts.bounds (simpleArc.js:15)', () {
      final arc = SimpleArc(x: 0, y: 0, radius: 1);
      final ctx = createMockContext();
      expect(
        arc.pathSegment(ctx, null, <String, Object?>{'bounds': 1}),
        isFalse,
      );
      expect(
        arc.pathSegment(ctx, null, <String, Object?>{'bounds': 0}),
        isTrue,
      );
      expect(arc.pathSegment(ctx, null, <String, Object?>{}), isTrue);
    });
  });

  group('interpolate', () {
    test('x + cos(angle) * radius and y + sin(angle) * radius', () {
      final arc = SimpleArc(x: 100, y: 50, radius: 10);
      final point = PointElement()..angle = 1.25;
      final result = arc.interpolate(point);
      expect(result.x, closeTo(100 + math.cos(1.25) * 10, 1e-12));
      expect(result.y, closeTo(50 + math.sin(1.25) * 10, 1e-12));
    });

    test('a point without angle gives NaN, as Math.cos(undefined)', () {
      final arc = SimpleArc(x: 100, y: 50, radius: 10);
      final result = arc.interpolate(PointElement()..x = 3);
      expect(result.x, isNaN);
      expect(result.y, isNaN);
    });
  });

  test(
    'SimpleArc is not a types.LineElement (Chart.js ADR 0040, section 4)',
    () {
      final Object arc = SimpleArc(x: 0, y: 0, radius: 0);
      expect(arc, isNot(isA<types.LineElement>()));
      expect(arc, isA<types.SimpleArc>());
    },
  );
}
