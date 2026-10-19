// Ported from Chart.js v4.5.1 test/specs/element.arc.tests.js (MIT, Chart.js Contributors).
import 'dart:math' as math;

import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs/src/elements/element.arc.dart';
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:test/test.dart';

// The spec constructs Chart.elements.ArcElement. Here it is the ArcElement
// of element.arc.dart (Chart.js ADR 0017). An object literal is a Dart Map
// literal, and the constructor writes each number as a double. `Math` is
// dart:math.

/// Jasmine `toBeCloseTo(expected, precision)`: within half a unit in the
/// `precision`-th decimal place. Jasmine's default precision is 2.
///
/// Jasmine 3.99 rounds the difference to `precision + 1` places before it
/// compares, so it also accepts differences up to about 1.1 times this bound.
Matcher _toBeCloseTo(double expected, [int precision = 2]) =>
    // js-ok: the exponent is an int, as in Jasmine's Math.pow(10, -precision).
    closeTo(expected, math.pow(10.0, -precision) / 2);

void main() {
  setUpSpecs();

  // Test the rectangle element

  group('Arc element tests', () {
    test('should determine if in range', () {
      // Mock out the arc as if the controller put it there
      final arc = ArcElement({
        'startAngle': 0,
        'endAngle': math.pi / 2,
        'x': 0,
        'y': 0,
        'innerRadius': 5,
        'outerRadius': 10,
        'options': <String, Object?>{
          'spacing': 0,
          'offset': 0,
          'borderWidth': 0,
        },
      });

      expect(arc.inRange(2, 2), isFalse);
      expect(arc.inRange(7, 0), isTrue);
      expect(arc.inRange(0, 11), isFalse);
      expect(arc.inRange(math.sqrt(32), math.sqrt(32)), isTrue);
      expect(arc.inRange(-1.0 * math.sqrt(7), math.sqrt(7)), isFalse);
    });

    test('should determine if in range when full circle', () {
      // Mock out the arc as if the controller put it there
      final arc = ArcElement({
        'startAngle': 0,
        'endAngle': math.pi * 2,
        'x': 0,
        'y': 0,
        'innerRadius': 5,
        'outerRadius': 10,
        'options': <String, Object?>{
          'spacing': 0,
          'offset': 0,
          'borderWidth': 0,
        },
      });

      for (final radius in [5.0, 7.5, 10.0]) {
        for (var angle = 0.0; angle <= 360; angle += 22.5) {
          final rad = angle / 180 * math.pi;
          final x = math.sin(rad) * radius;
          final y = math.cos(rad) * radius;
          expect(
            arc.inRange(x, y),
            isTrue,
            reason:
                'radius: ${jsNumberToString(radius)}, '
                'angle: ${jsNumberToString(angle)}',
          );
        }
      }
      for (final radius in [4.0, 11.0]) {
        for (var angle = 0.0; angle <= 360; angle += 22.5) {
          final rad = angle / 180 * math.pi;
          final x = math.sin(rad) * radius;
          final y = math.cos(rad) * radius;
          expect(
            arc.inRange(x, y),
            isFalse,
            reason:
                'radius: ${jsNumberToString(radius)}, '
                'angle: ${jsNumberToString(angle)}',
          );
        }
      }
    });

    test('should include spacing for in range check', () {
      // Mock out the arc as if the controller put it there
      final arc = ArcElement({
        'startAngle': 0,
        'endAngle': math.pi / 2,
        'x': 0,
        'y': 0,
        'innerRadius': 5,
        'outerRadius': 10,
        'options': <String, Object?>{
          'spacing': 10,
          'offset': 0,
          'borderWidth': 0,
        },
      });

      expect(arc.inRange(7, 0), isFalse);
      expect(arc.inRange(15, 0), isTrue);
    });

    test('should include borderWidth for in range check', () {
      // Mock out the arc as if the controller put it there
      final arc = ArcElement({
        'startAngle': 0,
        'endAngle': math.pi / 2,
        'x': 0,
        'y': 0,
        'innerRadius': 5,
        'outerRadius': 10,
        'options': <String, Object?>{
          'spacing': 0,
          'offset': 0,
          'borderWidth': 10,
        },
      });

      expect(arc.inRange(7, 0), isFalse);
      expect(arc.inRange(15, 0), isTrue);
    });

    test('should determine if in range, when full circle', () {
      // Mock out the arc as if the controller put it there
      final arc = ArcElement({
        'startAngle': -math.pi,
        'endAngle': math.pi * 1.5,
        'x': 0,
        'y': 0,
        'innerRadius': 0,
        'outerRadius': 10,
        'circumference': math.pi * 2,
        'options': <String, Object?>{
          'spacing': 0,
          'offset': 0,
          'borderWidth': 0,
        },
      });

      expect(arc.inRange(7, 7), isTrue);
    });

    test('should get the tooltip position', () {
      // Mock out the arc as if the controller put it there
      final arc = ArcElement({
        'startAngle': 0,
        'endAngle': math.pi / 2,
        'x': 0,
        'y': 0,
        'innerRadius': 0,
        'outerRadius': math.sqrt(2),
        'options': <String, Object?>{
          'spacing': 0,
          'offset': 0,
          'borderWidth': 0,
        },
      });

      final pos = arc.tooltipPosition();
      expect(pos.x, _toBeCloseTo(0.5));
      expect(pos.y, _toBeCloseTo(0.5));
    });

    test('should get the center', () {
      // Mock out the arc as if the controller put it there
      final arc = ArcElement({
        'startAngle': 0,
        'endAngle': math.pi / 2,
        'x': 0,
        'y': 0,
        'innerRadius': 0,
        'outerRadius': math.sqrt(2),
        'options': <String, Object?>{
          'spacing': 0,
          'offset': 0,
          'borderWidth': 0,
        },
      });

      final center = arc.getCenterPoint();
      expect(center.x, _toBeCloseTo(0.5, 6));
      expect(center.y, _toBeCloseTo(0.5, 6));
    });

    test('should get the center with offset and spacing', () {
      // Mock out the arc as if the controller put it there
      final arc = ArcElement({
        'startAngle': 0,
        'endAngle': math.pi / 2,
        'x': 0,
        'y': 0,
        'innerRadius': 0,
        'outerRadius': math.sqrt(2),
        'options': <String, Object?>{
          'spacing': 10,
          'offset': 10,
          'borderWidth': 0,
        },
      });

      final center = arc.getCenterPoint();
      expect(center.x, _toBeCloseTo(7.57, 1));
      expect(center.y, _toBeCloseTo(7.57, 1));
    });

    test('should get the center of full circle before and after draw', () {
      // Mock out the arc as if the controller put it there
      final arc = ArcElement({
        'startAngle': 0,
        'endAngle': math.pi * 2,
        'x': 2,
        'y': 2,
        'innerRadius': 0,
        'outerRadius': 2,
        'options': <String, Object?>{
          'spacing': 0,
          'offset': 0,
          'borderWidth': 0,
        },
      });

      var center = arc.getCenterPoint();
      expect(center.x, _toBeCloseTo(1, 6));
      expect(center.y, _toBeCloseTo(2, 6));

      final ctx = createMockContext();
      arc.draw(ctx);

      center = arc.getCenterPoint();
      expect(center.x, _toBeCloseTo(1, 6));
      expect(center.y, _toBeCloseTo(2, 6));
    });

    test('should not draw when radius < 0', () {
      final ctx = createMockContext();

      // Upstream assigns each arc to `var arc` and then draws it.
      ArcElement({
        'startAngle': 0,
        'endAngle': math.pi / 2,
        'x': 0,
        'y': 0,
        'innerRadius': -0.1,
        'outerRadius': math.sqrt(2),
        'options': <String, Object?>{
          'spacing': 0,
          'offset': 0,
          'borderWidth': 0,
        },
      }).draw(ctx);

      expect(ctx.getCalls().length, 0);

      ArcElement({
        'startAngle': 0,
        'endAngle': math.pi / 2,
        'x': 0,
        'y': 0,
        'innerRadius': 0,
        'outerRadius': -1,
        'options': <String, Object?>{
          'spacing': 0,
          'offset': 0,
          'borderWidth': 0,
        },
      }).draw(ctx);

      expect(ctx.getCalls().length, 0);
    });

    test('should draw when circular: false', () {
      final arc = ArcElement({
        'startAngle': 0,
        'endAngle': math.pi * 2,
        'x': 2,
        'y': 2,
        'innerRadius': 0,
        'outerRadius': 2,
        'options': <String, Object?>{
          'spacing': 0,
          'offset': 0,
          'borderWidth': 0,
          'scales': <String, Object?>{
            'r': <String, Object?>{
              'grid': <String, Object?>{
                'circular': false,
              },
            },
          },
          'elements': <String, Object?>{
            'arc': <String, Object?>{
              'circular': false,
            },
          },
        },
      });

      final ctx = createMockContext();
      arc.draw(ctx);

      expect(ctx.getCalls().length, greaterThan(0));
    });

    test('should determine not in range when angle 0', () {
      // Mock out the arc as if the controller put it there
      final arc = ArcElement({
        'startAngle': 0,
        'endAngle': 0,
        'x': 0,
        'y': 0,
        'innerRadius': 0,
        'outerRadius': 10,
        'circumference': 0,
        'options': <String, Object?>{
          'spacing': 0,
          'offset': 0,
          'borderWidth': 0,
        },
      });

      final center = arc.getCenterPoint();

      expect(arc.inRange(center.x, 1), isFalse);
    });
  });
}
