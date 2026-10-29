// Ported from Chart.js v4.6.1 test/specs/helpers.color.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:ui' as ui;

import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.color.dart';
import 'package:flutter_chartjs_port/src/kurkle_color/index.esm.dart'
    show Color;
import 'package:flutter_test/flutter_test.dart';

// The spec reads `color` and `getHoverColor` from Chart.helpers. Here they
// come from helpers.color.dart.
//
// The two canvas cases need a real gradient and pattern, so they use the
// dart:ui canvas layer (canvas_ui.dart), and the file runs on the VM only.
// test/port/helpers/helpers.color_test.dart tests `color` and
// `getHoverColor` on the web legs with test classes of CanvasGradient and
// CanvasPattern.

/// `document.createElement('canvas').getContext('2d')`.
UiCanvasContext _createContext([UiCanvasElement? canvas]) =>
    (canvas ?? UiCanvasElement()).getContext2d();

/// `new Image()` with the data URL [src], after its `onload`.
Future<UiImageSource> _loadImage(String src) async {
  final bytes = base64Decode(src.substring(src.indexOf(',') + 1));
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  codec.dispose();
  return UiImageSource(frame.image);
}

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
    test(
      'should return a CanvasPattern when called with a CanvasPattern',
      () async {
        // `dots.onload` runs after the image decodes: the test awaits it
        // where upstream calls `done()`.
        final dots = await _loadImage(
          'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAMAAAAolt3jAAAAD1BMVEUAAAD///////////////+PQt5oAAAABXRSTlMAHlFhZsfk/BEAAAAqSURBVHgBY2BgZGJmYmSAAUYWEIDzmcBcJhiXGcxlRpPFrhdmMiqgvX0AcGIBEUAo6UAAAAAASUVORK5CYII=',
        );
        final chartContext = _createContext();
        final patternCanvas = UiCanvasElement();
        final patternContext = _createContext(patternCanvas);
        final pattern = patternContext.createPattern(dots, 'repeat');
        patternContext.fillStyle = pattern;
        // The DOM reads the canvas element itself; the canvas layer takes
        // a snapshot of its bitmap (UiCanvasElement.toImageSource).
        final chartPattern = chartContext.createPattern(
          patternCanvas.toImageSource(),
          'repeat',
        );

        expect(color(chartPattern) is CanvasPattern, isTrue);
        expect(getHoverColor(chartPattern) is CanvasPattern, isTrue);
      },
    );

    test(
      'should return a CanvasGradient when called with a CanvasGradient',
      () {
        final context = _createContext();
        final gradient = context.createLinearGradient(0, 1, 2, 3);

        expect(color(gradient) is CanvasGradient, isTrue);
        expect(getHoverColor(gradient) is CanvasGradient, isTrue);
      },
    );
  });
}
