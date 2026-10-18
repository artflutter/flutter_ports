// Ported from Chart.js v4.5.1 test/specs/helpers.color.tests.js (MIT, Chart.js Contributors).
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs/src/helpers/helpers.color.dart';
import 'package:flutter_chartjs/src/kurkle_color/index.esm.dart' show Color;
import 'package:test/test.dart';

// The spec reads `color` and `getHoverColor` from Chart.helpers. Here they
// come from helpers.color.dart.

void main() {
  setUpSpecs();
  group('Color helper', () {
    // `typeof obj === 'object' && obj.valid`. Of the objects that `color`
    // returns, only a Color has `valid`.
    bool isColorInstance(Object? obj) {
      return obj is Color && obj.valid;
    }

    test('should return a color when called with a color', () {
      expect(isColorInstance(color('rgb(1, 2, 3)')), isTrue);
    });
  });

  group('Background hover color helper', () {
    test(
      'should return a modified version of color when called with a color',
      () {
        const originalColorRGB = 'rgb(70, 191, 189)';

        expect(getHoverColor('#46BFBD'), isNot(originalColorRGB));
      },
    );
  });

  group('color and getHoverColor helpers', () {
    // The spec creates the pattern from an Image and two canvas contexts,
    // and the gradient from a canvas context. The canvas layer of phase 3
    // provides them.
    test(
      'should return a CanvasPattern when called with a CanvasPattern',
      () {},
      skip: 'blocked: helpers.canvas',
    );

    test(
      'should return a CanvasGradient when called with a CanvasGradient',
      () {},
      skip: 'blocked: helpers.canvas',
    );
  });
}
