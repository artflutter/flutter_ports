// Ported from Chart.js v4.5.1 test/specs/helpers.canvas.tests.js (MIT, Chart.js Contributors).
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs/src/helpers/helpers.canvas.dart' as helpers;
import 'package:flutter_chartjs/src/types/geometric.dart';
import 'package:test/test.dart';

// The spec reads the functions from Chart.helpers. Here `helpers` is
// helpers.canvas.dart, and `_isPointInArea` is `isPointInArea` (Chart.js ADR
// 0004).

/// A JavaScript object literal `{x, y}`, passed as a [Point].
final class _Point implements Point {
  const _Point(this.x, this.y);

  @override
  final double? x;

  @override
  final double? y;
}

/// A JavaScript object literal `{left, top, right, bottom}`, passed as a
/// [TRBL].
final class _Area implements TRBL {
  const _Area({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  @override
  final double left;

  @override
  final double top;

  @override
  final double right;

  @override
  final double bottom;
}

void main() {
  setUpSpecs();
  group('Chart.helpers.canvas', () {
    // `describe('auto', jasmine.fixture.specs('helpers'))` makes no spec
    // cases. Chart.js v4.5.1 has no `test/fixtures/helpers` directory, so the
    // group has 0 fixtures. The fixture runner of phase 7 registers it.

    group('clearCanvas', () {
      // The spec calls acquireChart and spies on the canvas context.
      test(
        'should clear the chart canvas',
        () {},
        skip: 'blocked: core.controller',
      );

      test(
        'should not throw error when chart is null',
        () {},
        skip: 'blocked: core.controller',
      );
    });

    group('isPointInArea', () {
      test('should return true when no area is provided', () {
        expect(helpers.isPointInArea(const _Point(1, 1), null), true);
      });
      test('should determine if a point is in the area', () {
        const isPointInArea = helpers.isPointInArea;
        const area = _Area(left: 0, top: 0, right: 512, bottom: 256);

        expect(isPointInArea(const _Point(0, 0), area), true);
        expect(isPointInArea(const _Point(-1e-12, -1e-12), area), true);
        expect(isPointInArea(const _Point(512, 256), area), true);
        expect(
          isPointInArea(const _Point(512 + 1e-12, 256 + 1e-12), area),
          true,
        );
        expect(isPointInArea(const _Point(-0.5, 0), area), false);
        expect(isPointInArea(const _Point(0, 256.5), area), false);
      });
    });

    // The next cases call `_longestText`, `_measureText` and `renderText`
    // with `window.createMockContext()`. The canvas layer of phase 3 ports
    // these functions and the recorder context.
    test(
      'should return the width of the longest text in an Array and 2D Array',
      () {},
      skip: 'blocked: helpers.canvas',
    );

    test(
      'compare text with current longest and update',
      () {},
      skip: 'blocked: helpers.canvas',
    );

    group('renderText', () {
      test(
        'should render multiple lines of text',
        () {},
        skip: 'blocked: helpers.canvas',
      );

      test(
        'should accept the text maxWidth',
        () {},
        skip: 'blocked: helpers.canvas',
      );

      test(
        'should underline the text',
        () {},
        skip: 'blocked: helpers.canvas',
      );

      test(
        'should strikethrough the text',
        () {},
        skip: 'blocked: helpers.canvas',
      );

      test(
        'should set the fill style if supplied',
        () {},
        skip: 'blocked: helpers.canvas',
      );

      test(
        'should set the stroke style if supplied',
        () {},
        skip: 'blocked: helpers.canvas',
      );

      test(
        'should set the text alignment',
        () {},
        skip: 'blocked: helpers.canvas',
      );

      test(
        'should translate and rotate text',
        () {},
        skip: 'blocked: helpers.canvas',
      );
    });
  });
}
