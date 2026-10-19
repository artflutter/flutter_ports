// Ported from Chart.js v4.5.1 test/specs/element.point.tests.js (MIT, Chart.js Contributors).
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs/src/core/core.element.dart';
import 'package:flutter_chartjs/src/elements/element.point.dart';
import 'package:test/test.dart';

// The spec constructs Chart.elements.PointElement. Here it is the
// PointElement of element.point.dart (Chart.js ADR 0017). An object literal
// is a Map (Chart.js ADR 0006), and an integer becomes a double at the
// write. The literal {x, y} of tooltipPosition and getCenterPoint is an
// ElementPoint, which compares with equals.

void main() {
  setUpSpecs();

  group('Chart.elements.PointElement', () {
    // describe('auto', jasmine.fixture.specs('element.point')): a fixture
    // group of phase 7, not a case.

    test('Should correctly identify as in range', () {
      // Mock out the point as if we were made by the controller
      final point = PointElement({
        'options': <String, Object?>{'radius': 2, 'hitRadius': 3},
        'x': 10,
        'y': 15,
      });

      expect(point.inRange(10, 15), isTrue);
      expect(point.inRange(10, 10), isFalse);
      expect(point.inRange(10, 5), isFalse);
      expect(point.inRange(5, 5), isFalse);
    });

    test('should get the correct tooltip position', () {
      // Mock out the point as if we were made by the controller
      final point = PointElement({
        'options': <String, Object?>{'radius': 2, 'borderWidth': 6},
        'x': 10,
        'y': 15,
      });

      expect(point.tooltipPosition(), const ElementPoint(10, 15));
    });

    test('should get the correct center point', () {
      // Mock out the point as if we were made by the controller
      final point = PointElement({
        'options': <String, Object?>{'radius': 2},
        'x': 10,
        'y': 10,
      });

      expect(point.getCenterPoint(), const ElementPoint(10, 10));
    });

    test('should not draw if skipped', () {
      final mockContext = createMockContext();

      // Mock out the point as if we were made by the controller
      // (`var point = …; point.draw(mockContext)` is one expression here,
      // for the lint cascade_invocations).
      PointElement({
        'options': <String, Object?>{'radius': 2, 'hitRadius': 3},
        'x': 10,
        'y': 15,
        'skip': true,
      }).draw(mockContext);

      expect(mockContext.getCalls(), <ContextCall>[]);
    });
  });
}
