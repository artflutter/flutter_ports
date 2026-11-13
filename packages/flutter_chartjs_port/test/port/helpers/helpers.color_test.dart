// Original code, not ported from Chart.js: helpers.color tests.
import 'dart:ui' as ui;

import 'package:flutter_chartjs_port/src/helpers/helpers.color.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/types/chart_paint.dart';
import 'package:flutter_kurkle_color_port/flutter_kurkle_color_port.dart'
    show Color;
import 'package:test/test.dart';

// The behaviour of helpers.color that test/specs/helpers.color.tests.js does
// not check, or checks only with a canvas (blocked until phase 3). The
// expected strings come from @kurkle/color 0.3.2 in Node.js v24.12.0 on x64.

/// A gradient of the canvas layer.
ChartGradient _gradient() =>
    const ChartGradient.linear(ui.Offset.zero, ui.Offset(1, 1), []);

/// Another native shader variant. Image patterns are covered in the VM spec.
ChartGradient _radial() => const ChartGradient.radial(ui.Offset.zero, 1, []);

void main() {
  group('platform-color-brand', () {
    test('isPatternOrGradient tests native shader paints', () {
      expect(isPatternOrGradient(_gradient()), isTrue);
      expect(isPatternOrGradient(_radial()), isTrue);
      expect(
        isPatternOrGradient(const ui.Color.fromRGBO(255, 255, 255, 1)),
        isFalse,
      );
      expect(isPatternOrGradient(<String, Object?>{}), isFalse);
      expect(isPatternOrGradient(null), isFalse);
      expect(isPatternOrGradient(undefined), isFalse);
    });

    test('color and getHoverColor return shader paints as is', () {
      final gradient = _gradient();
      final radial = _radial();
      expect(identical(color(gradient), gradient), isTrue);
      expect(identical(color(radial), radial), isTrue);
      expect(identical(getHoverColor(gradient), gradient), isTrue);
      expect(identical(getHoverColor(radial), radial), isTrue);
    });
  });

  test('color returns a Color', () {
    final c = color(const ui.Color.fromRGBO(1, 2, 3, 1));
    expect(c, isA<Color>());
    expect((c as Color).rgbString(), 'rgb(1, 2, 3)');
    expect(() => color('nope'), throwsArgumentError);
  });

  test('getHoverColor saturates by 0.5 and darkens by 0.1', () {
    expect(
      getHoverColor(const ui.Color.fromRGBO(70, 191, 189, 1)),
      const ChartPaint.solid(ui.Color.fromRGBO(32, 203, 200, 1)),
    );
    expect(
      getHoverColor(const ui.Color.fromRGBO(70, 191, 189, 1)),
      const ChartPaint.solid(ui.Color.fromRGBO(32, 203, 200, 1)),
    );
    expect(
      getHoverColor(const ui.Color.fromRGBO(255, 0, 0, 1)),
      const ChartPaint.solid(ui.Color.fromRGBO(230, 0, 0, 1)),
    );
    expect(
      getHoverColor(const ui.Color.fromRGBO(255, 99, 132, 0.5)),
      const ChartPaint.solid(ui.Color.fromRGBO(255, 64, 105, 0.5)),
    );
    expect(
      getHoverColor(const ui.Color.fromRGBO(0, 0, 0, 0)),
      const ChartPaint.solid(ui.Color.fromRGBO(0, 0, 0, 0)),
    );
    expect(
      getHoverColor(const ui.Color.fromRGBO(10, 20, 30, 0.5)),
      const ChartPaint.solid(ui.Color.fromRGBO(4, 18, 32, 0.5)),
    );
    expect(
      getHoverColor(const ui.Color.fromRGBO(10, 20, 30, 0.5)),
      const ChartPaint.solid(ui.Color.fromRGBO(4, 18, 32, 0.5)),
    );
  });

  test('getHoverColor of a color that does not parse is undefined', () {
    expect(() => getHoverColor('nope'), throwsArgumentError);
    expect(
      () => getHoverColor('hsl(120deg 40% 60% / 0.3)'),
      throwsArgumentError,
    );
    expect(getHoverColor(undefined), isNull);
  });

  test('JS null throws, as new Color(null) does', () {
    expect(() => color(null), throwsArgumentError);
    expect(() => getHoverColor(null), throwsArgumentError);
  });
}
