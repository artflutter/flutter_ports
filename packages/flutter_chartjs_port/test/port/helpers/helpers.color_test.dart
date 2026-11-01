// Original code, not ported from Chart.js: helpers.color tests.
import 'package:flutter_chartjs_port/src/helpers/helpers.color.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/kurkle_color/index.esm.dart'
    show Color;
import 'package:flutter_chartjs_port/src/options/prepared_color.dart'
    as color_values;
import 'package:flutter_chartjs_port/src/types/color.dart';
import 'package:test/test.dart';

// The behaviour of helpers.color that test/specs/helpers.color.tests.js does
// not check, or checks only with a canvas (blocked until phase 3). The
// expected strings come from @kurkle/color 0.3.2 in Node.js v24.12.0 on x64.

/// A gradient of the canvas layer.
final class _Gradient implements CanvasGradient {
  @override
  void addColorStop(double offset, Object color) {}
}

/// A pattern of the canvas layer.
final class _Pattern implements CanvasPattern {}

void main() {
  group('platform-color-brand', () {
    test('isPatternOrGradient tests the canvas interfaces', () {
      expect(isPatternOrGradient(_Gradient()), isTrue);
      expect(isPatternOrGradient(_Pattern()), isTrue);
      expect(
        isPatternOrGradient(
          const color_values.PreparedColor(255, 255, 255, 1),
        ),
        isFalse,
      );
      expect(isPatternOrGradient(<String, Object?>{}), isFalse);
      expect(isPatternOrGradient(null), isFalse);
      expect(isPatternOrGradient(undefined), isFalse);
    });

    test('color and getHoverColor return a pattern or gradient as is', () {
      final gradient = _Gradient();
      final pattern = _Pattern();
      expect(identical(color(gradient), gradient), isTrue);
      expect(identical(color(pattern), pattern), isTrue);
      expect(identical(getHoverColor(gradient), gradient), isTrue);
      expect(identical(getHoverColor(pattern), pattern), isTrue);
    });
  });

  test('color returns a Color', () {
    final c = color(const color_values.PreparedColor(1, 2, 3, 1));
    expect(c, isA<Color>());
    expect((c as Color).rgbString(), 'rgb(1, 2, 3)');
    expect(() => color('nope'), throwsArgumentError);
  });

  test('getHoverColor saturates by 0.5 and darkens by 0.1', () {
    expect(
      getHoverColor(const color_values.PreparedColor(70, 191, 189, 1)),
      const color_values.PreparedColor(32, 203, 200, 1),
    );
    expect(
      getHoverColor(const color_values.PreparedColor(70, 191, 189, 1)),
      const color_values.PreparedColor(32, 203, 200, 1),
    );
    expect(
      getHoverColor(const color_values.PreparedColor(255, 0, 0, 1)),
      const color_values.PreparedColor(230, 0, 0, 1),
    );
    expect(
      getHoverColor(const color_values.PreparedColor(255, 99, 132, 0.5)),
      const color_values.PreparedColor(255, 64, 105, 0.5),
    );
    expect(
      getHoverColor(const color_values.PreparedColor(0, 0, 0, 0)),
      const color_values.PreparedColor(0, 0, 0, 0),
    );
    expect(
      getHoverColor(const color_values.PreparedColor(10, 20, 30, 0.5)),
      const color_values.PreparedColor(4, 18, 32, 0.5),
    );
    expect(
      getHoverColor(const color_values.PreparedColor(10, 20, 30, 0.5)),
      const color_values.PreparedColor(4, 18, 32, 0.5),
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
