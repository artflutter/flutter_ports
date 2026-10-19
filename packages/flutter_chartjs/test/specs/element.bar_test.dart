// Ported from Chart.js v4.5.1 test/specs/element.bar.tests.js (MIT, Chart.js Contributors).
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs/src/core/core.element.dart';
import 'package:flutter_chartjs/src/elements/element.bar.dart';
import 'package:test/test.dart';

// Test the bar element

// The spec constructs Chart.elements.BarElement. Here it is the BarElement of
// element.bar.dart (Chart.js ADR 0017). The object literal of a toEqual
// expectation is an ElementPoint, which the spec compares with equals.

void main() {
  setUpSpecs();

  group('Bar element tests', () {
    test('Should correctly identify as in range', () {
      final bar = BarElement({'base': 0, 'width': 4, 'x': 10, 'y': 15});

      expect(bar.inRange(10, 15), isTrue);
      expect(bar.inRange(10, 10), isTrue);
      expect(bar.inRange(10, 16), isFalse);
      expect(bar.inRange(5, 5), isFalse);

      // Test when the y is below the base (negative bar)
      final negativeBar = BarElement({
        'base': 0,
        'width': 4,
        'x': 10,
        'y': -15,
      });

      expect(negativeBar.inRange(10, -16), isFalse);
      expect(negativeBar.inRange(10, 1), isFalse);
      expect(negativeBar.inRange(10, -5), isTrue);
    });

    test('should get the correct tooltip position', () {
      final bar = BarElement({'base': 0, 'width': 4, 'x': 10, 'y': 15});

      expect(bar.tooltipPosition(), equals(const ElementPoint(10, 15)));

      // Test when the y is below the base (negative bar)
      final negativeBar = BarElement({
        'base': -10,
        'width': 4,
        'x': 10,
        'y': -15,
      });

      expect(
        negativeBar.tooltipPosition(),
        equals(const ElementPoint(10, -15)),
      );
    });

    test('should get the center', () {
      final bar = BarElement({'base': 0, 'width': 4, 'x': 10, 'y': 15});

      expect(bar.getCenterPoint(), equals(const ElementPoint(10, 7.5)));
    });
  });
}
