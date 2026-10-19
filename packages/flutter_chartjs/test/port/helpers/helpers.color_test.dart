// Original code, not ported from Chart.js: helpers.color tests.
import 'package:flutter_chartjs/src/helpers/helpers.color.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/kurkle_color/index.esm.dart' show Color;
import 'package:flutter_chartjs/src/types/color.dart';
import 'package:test/test.dart';

// The behaviour of helpers.color that test/specs/helpers.color.tests.js does
// not check, or checks only with a canvas (blocked until phase 3). The
// expected strings come from @kurkle/color 0.3.2 in Node.js v24.12.0 on x64.

/// A gradient of the canvas layer.
final class _Gradient implements CanvasGradient {
  @override
  void addColorStop(double offset, String color) {}
}

/// A pattern of the canvas layer.
final class _Pattern implements CanvasPattern {}

void main() {
  group('platform-color-brand', () {
    test('isPatternOrGradient tests the canvas interfaces', () {
      expect(isPatternOrGradient(_Gradient()), isTrue);
      expect(isPatternOrGradient(_Pattern()), isTrue);
      expect(isPatternOrGradient('#fff'), isFalse);
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
    final c = color('rgb(1, 2, 3)');
    expect(c, isA<Color>());
    expect((c as Color).rgbString(), 'rgb(1, 2, 3)');
    expect((color('nope') as Color).valid, isFalse);
  });

  test('getHoverColor saturates by 0.5 and darkens by 0.1', () {
    expect(getHoverColor('#46BFBD'), '#20CBC8');
    expect(getHoverColor('rgb(70, 191, 189)'), '#20CBC8');
    expect(getHoverColor('red'), '#E60000');
    expect(getHoverColor('rgba(255, 99, 132, 0.5)'), '#FF40697F');
    expect(getHoverColor('transparent'), '#0000');
    expect(getHoverColor(<Object?>[10, 20, 30, 0.5]), '#04122080');
    expect(
      getHoverColor(<String, Object?>{'r': 10, 'g': 20, 'b': 30, 'a': 0.5}),
      '#04122080',
    );
  });

  test('getHoverColor of a color that does not parse is undefined', () {
    expect(getHoverColor('nope'), isNull);
    expect(getHoverColor('hsl(120deg 40% 60% / 0.3)'), isNull);
    expect(getHoverColor(undefined), isNull);
  });

  test('JS null throws, as new Color(null) does', () {
    expect(() => color(null), throwsA(isA<TypeError>()));
    expect(() => getHoverColor(null), throwsA(isA<TypeError>()));
  });
}
