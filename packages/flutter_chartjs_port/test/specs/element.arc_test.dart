// Ported from Chart.js v4.6.1 test/specs/element.arc.tests.js (MIT, Chart.js Contributors).
import 'dart:math' as math;

import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/src/elements/element.arc.dart';
import 'package:flutter_chartjs_port/src/js/js_math.dart'
    show jsAtan2, jsCos, jsMin, jsSin;
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:test/test.dart';

// The spec constructs Chart.elements.ArcElement. Here it is the ArcElement
// of element.arc.dart (Chart.js ADR 0017). An object literal is a Dart Map
// literal, and the constructor writes each number as a double. `Math` is
// dart:math, with jsAtan2, jsMin, jsSin and jsCos of the JS runtime for
// Math.atan2, Math.min, Math.sin and Math.cos (Chart.js ADR 0045: the inputs
// of inRange are a hit test). `window.createMockContext()` is
// createMockContext of chartjs_test_utils. A recorded call is a Map with the
// keys 'name' and 'args'.

/// Jasmine `toBeCloseTo(expected, precision)`: within half a unit in the
/// `precision`-th decimal place. Jasmine's default precision is 2.
///
/// Jasmine 3.99 rounds the difference to `precision + 1` places before it
/// compares, so it also accepts differences up to about 1.1 times this bound.
Matcher _toBeCloseTo(double expected, [int precision = 2]) =>
    // js-ok: the exponent is an int, as in Jasmine's Math.pow(10, -precision).
    closeTo(expected, math.pow(10.0, -precision) / 2);

/// The number `args[index]` of the recorded [call].
double _arg(ContextCall call, int index) =>
    (call['args']! as List<Object?>)[index]! as double;

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
          final x = jsSin(rad) * radius;
          final y = jsCos(rad) * radius;
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
          final x = jsSin(rad) * radius;
          final y = jsCos(rad) * radius;
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

    test(
      'should use angular spacing mode independently from proportional mode',
      () {
        ArcElement createArc(String spacingMode) {
          return ArcElement({
            'startAngle': 0,
            'endAngle': math.pi / 2,
            'x': 0,
            'y': 0,
            'innerRadius': 0,
            'outerRadius': 100,
            'options': <String, Object?>{
              'circular': true,
              'spacingMode': spacingMode,
              'spacing': 20,
              'offset': 0,
              'borderWidth': 0,
              'borderRadius': 0,
              'backgroundColor': 'red',
              'borderColor': 'black',
            },
          });
        }

        double firstOuterArcStartAngle(ArcElement arc) {
          final ctx = createMockContext();
          arc.draw(ctx);

          final arcCall = ctx
              .getCalls()
              .where((x) => x['name'] == 'arc')
              .firstOrNull;
          if (arcCall != null) {
            return _arg(arcCall, 3);
          }

          final lineToCall = ctx
              .getCalls()
              .where((x) => x['name'] == 'lineTo')
              .first;
          final dx = _arg(lineToCall, 0) - arc.x;
          final dy = _arg(lineToCall, 1) - arc.y;
          return jsAtan2(dy, dx);
        }

        final proportionalStart = firstOuterArcStartAngle(
          createArc('proportional'),
        );
        final angularStart = firstOuterArcStartAngle(createArc('angular'));
        const alpha = math.pi / 2;
        const spacing = 10.0; // draw() passes spacing / 2 to pathArc
        const avgNoSpacingRadius = 50.0;
        const adjustedAngle =
            (alpha * avgNoSpacingRadius) / (avgNoSpacingRadius + spacing);
        const proportionalSpacingOffset = (alpha - adjustedAngle) / 2;
        // js-ok: the test compares to 6 decimal places.
        final angularSpacingOffset = math.asin(
          jsMin(1, spacing / avgNoSpacingRadius),
        );

        expect(
          angularStart - proportionalStart,
          _toBeCloseTo(angularSpacingOffset - proportionalSpacingOffset, 6),
        );
      },
    );

    test('should keep valid arc direction with large parallel spacing', () {
      final arc = ArcElement({
        'startAngle': 0,
        'endAngle': math.pi / 2,
        'x': 0,
        'y': 0,
        'innerRadius': 40,
        'outerRadius': 100,
        'options': <String, Object?>{
          'circular': true,
          'spacingMode': 'parallel',
          'spacing': 40,
          'offset': 0,
          'borderWidth': 0,
          'borderRadius': 0,
          'backgroundColor': 'red',
          'borderColor': 'black',
        },
      });

      final ctx = createMockContext();
      arc.draw(ctx);

      final arcCalls = ctx.getCalls().where((x) => x['name'] == 'arc').toList();

      // First two calls are the split outer arc segments; ensure they keep
      // forward direction.
      expect(_arg(arcCalls[0], 3), lessThan(_arg(arcCalls[0], 4)));
      expect(_arg(arcCalls[1], 3), lessThan(_arg(arcCalls[1], 4)));
    });

    test(
      'should not reverse end separator angle in parallel mode with large '
      'spacing',
      () {
        final arc = ArcElement({
          'startAngle': 0,
          'endAngle': math.pi / 3,
          'x': 0,
          'y': 0,
          'innerRadius': 40,
          'outerRadius': 100,
          'options': <String, Object?>{
            'circular': true,
            'spacingMode': 'parallel',
            'spacing': 20,
            'offset': 0,
            'borderWidth': 0,
            'borderRadius': 0,
            'backgroundColor': 'red',
            'borderColor': 'black',
          },
        });

        final ctx = createMockContext();
        arc.draw(ctx);

        final arcCalls = ctx
            .getCalls()
            .where((x) => x['name'] == 'arc')
            .toList();
        final lineToCalls = ctx
            .getCalls()
            .where((x) => x['name'] == 'lineTo')
            .toList();

        final outerEndAngle = _arg(arcCalls[1], 4);
        final innerEndAngle = jsAtan2(
          _arg(lineToCalls[0], 1) - arc.y,
          _arg(lineToCalls[0], 0) - arc.x,
        );

        expect(innerEndAngle, lessThan(outerEndAngle));
      },
    );

    test(
      'should create a non-zero root for parallel spacing when innerRadius is '
      'zero',
      () {
        final arc = ArcElement({
          'startAngle': 0,
          'endAngle': math.pi / 3,
          'x': 0,
          'y': 0,
          'innerRadius': 0,
          'outerRadius': 100,
          'options': <String, Object?>{
            'circular': true,
            'spacingMode': 'parallel',
            'spacing': 20,
            'offset': 0,
            'borderWidth': 0,
            'borderRadius': 0,
            'backgroundColor': 'red',
            'borderColor': 'black',
          },
        });

        final ctx = createMockContext();
        arc.draw(ctx);

        final lineToCalls = ctx
            .getCalls()
            .where((x) => x['name'] == 'lineTo')
            .toList();
        // Math.hypot of the two distances. Dart has no hypot.
        final dx = _arg(lineToCalls[0], 0) - arc.x;
        final dy = _arg(lineToCalls[0], 1) - arc.y;
        final rootDistance = math.sqrt(dx * dx + dy * dy);

        expect(rootDistance, greaterThan(0));
      },
    );

    test(
      'should render full-circle geometry for selfJoin with borderRadius',
      () {
        final arc = ArcElement({
          'startAngle': 0,
          'endAngle': math.pi * 2,
          'x': 0,
          'y': 0,
          'innerRadius': 50,
          'outerRadius': 100,
          'options': <String, Object?>{
            'circular': true,
            'selfJoin': true,
            'spacing': 0,
            'offset': 0,
            'borderWidth': 6,
            'borderRadius': 12,
            'backgroundColor': 'red',
            'borderColor': 'black',
          },
        });

        final ctx = createMockContext();
        arc.draw(ctx);

        final arcCalls = ctx
            .getCalls()
            .where((x) => x['name'] == 'arc')
            .toList();
        // Array.from(new Set(...)): a Dart Set literal keeps the insertion
        // order.
        final radii = {
          for (final x in arcCalls) _arg(x, 2).toStringAsFixed(3),
        }.toList();

        expect(radii.length, 2);
        expect(
          (_arg(arcCalls[0], 4) - _arg(arcCalls[0], 3)).abs(),
          _toBeCloseTo(math.pi * 2, 3),
        );
      },
    );

    test('should apply spacing to a full circle when selfJoin is false', () {
      final arc = ArcElement({
        'startAngle': 0,
        'endAngle': math.pi * 2,
        'x': 0,
        'y': 0,
        'innerRadius': 40,
        'outerRadius': 100,
        'options': <String, Object?>{
          'circular': true,
          'selfJoin': false,
          'spacingMode': 'angular',
          'spacing': 20,
          'offset': 0,
          'borderWidth': 0,
          'borderRadius': 0,
          'backgroundColor': 'red',
          'borderColor': 'black',
        },
      });

      final ctx = createMockContext();
      arc.draw(ctx);

      final firstOuterArc = ctx
          .getCalls()
          .where((x) => x['name'] == 'arc')
          .first;

      expect(
        _arg(firstOuterArc, 4) - _arg(firstOuterArc, 3),
        lessThan(math.pi * 2),
      );
    });

    test(
      'should not clip full-circle selfJoin borders with evenodd clipping',
      () {
        final arc = ArcElement({
          'startAngle': 0,
          'endAngle': math.pi * 2,
          'x': 0,
          'y': 0,
          'innerRadius': 40,
          'outerRadius': 100,
          'options': <String, Object?>{
            'circular': true,
            'selfJoin': true,
            'spacing': 20,
            'offset': 0,
            'borderWidth': 2,
            'borderRadius': 0,
            'borderJoinStyle': 'round',
            'backgroundColor': 'red',
            'borderColor': 'black',
          },
        });

        final ctx = createMockContext();
        arc.draw(ctx);

        final evenOddClipCall = ctx
            .getCalls()
            .where(
              (x) =>
                  x['name'] == 'clip' &&
                  (x['args']! as List<Object?>)[0] == 'evenodd',
            )
            .firstOrNull;

        expect(evenOddClipCall, isNull);
      },
    );

    test('should not draw a radial seam for full-circle selfJoin pie', () {
      final arc = ArcElement({
        'startAngle': 0,
        'endAngle': math.pi * 2,
        'x': 10,
        'y': 20,
        'innerRadius': 0,
        'outerRadius': 100,
        'options': <String, Object?>{
          'circular': true,
          'selfJoin': true,
          'spacing': 0,
          'offset': 0,
          'borderWidth': 10,
          'borderRadius': 1,
          'borderJoinStyle': 'round',
          'backgroundColor': 'red',
          'borderColor': 'black',
        },
      });

      final ctx = createMockContext();
      arc.draw(ctx);

      final radialLineToCenter = ctx
          .getCalls()
          .where(
            (x) =>
                x['name'] == 'lineTo' &&
                _arg(x, 0) == arc.x &&
                _arg(x, 1) == arc.y,
          )
          .firstOrNull;

      expect(radialLineToCenter, isNull);
    });
  });
}
