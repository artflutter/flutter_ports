// Original code, not ported from @kurkle/color: tests of the Color port.
import 'package:flutter_kurkle_color_port/src/index.esm.dart';
import 'package:test/test.dart';

import '../support/reference.dart';

// The behaviour of Color that the upstream test/index.js does not check. The
// expected values come from src/index.esm.js of @kurkle/color 0.3.2 in
// Node.js v24.12.0 on x64 (V8 13.6.233.17-node.37). Dart null stands for JS
// undefined, in the inputs and in the results.

/// The members of [v] as a record, for `expect`.
({double r, double g, double b, double a})? _members(RGBA? v) =>
    v == null ? null : (r: v.r, g: v.g, b: v.b, a: v.a);

void main() {
  group('constructor', () {
    test('a Color input gives the same instance', () {
      final c = cssColor('red');
      expect(identical(cssColor(c), c), isTrue);
      expect(identical(color(c), c), isTrue);
    });

    test('inputs that are not objects or strings are not valid', () {
      expect(cssColor(null).valid, isFalse);
      expect(cssColor(5).valid, isFalse);
      expect(cssColor(true).valid, isFalse);
      expect(cssColor(() => 1).valid, isFalse);
      expect(cssColor('').valid, isFalse);
    });

    test('short arrays and empty objects give opaque black', () {
      const black = (r: 0.0, g: 0.0, b: 0.0, a: 1.0);
      expect(_members(cssColor(<Object?>[]).rgb), black);
      expect(_members(cssColor(<Object?>[1, 2]).rgb), black);
      expect(_members(cssColor(<String, Object?>{}).rgb), black);
      expect(_members(cssColor(Object()).rgb), black);
    });

    test('a non-hex digit is 0 in r, g and b, and NaN in a', () {
      expect(_members(cssColor('#ggg').rgb), (r: 0.0, g: 0.0, b: 0.0, a: 1.0));
      // b2n(NaN) is 0, and NaN < 255 is false.
      expect(_members(cssColor('#fffg').rgb), (
        r: 255.0,
        g: 255.0,
        b: 255.0,
        a: 0.0,
      ));
      expect(cssColor('#fffg').hexString(), '#FFF');
      expect(cssColor('#fffg').rgbString(), 'rgb(255, 255, 255)');
    });

    test('a member string is ToNumber in arithmetic', () {
      expect(
        cssColor(<Object?>[1, 20, 30, '0.5']).rgbString(),
        'rgba(1, 20, 30, 0.5)',
      );
    });
  });

  group('adapt-kurkle-rgba', () {
    // JavaScript keeps the member values as they are. A template literal
    // then prints them: 'rgb(010, 20, 30)' and 'rgb(undefined, 20, 30)'. The
    // port converts them to numbers.
    test('object and array members are numbers', () {
      expect(
        cssColor(<String, Object?>{'r': '010', 'g': 20, 'b': 30}).rgbString(),
        'rgb(10, 20, 30)',
      );
      expect(cssColor(<Object?>['010', 20, 30]).rgbString(), 'rgb(10, 20, 30)');
      expect(
        cssColor(<String, Object?>{'r': null, 'g': 20, 'b': 30}).rgbString(),
        'rgb(NaN, 20, 30)',
      );
    });

    test('other keys of an object input are not copied', () {
      // JavaScript gives {r: 1, g: 20, b: 30, a: 1, x: 5}.
      expect(
        _members(
          cssColor(<String, Object?>{'r': 1, 'g': 20, 'b': 30, 'x': 5}).rgb,
        ),
        (r: 1.0, g: 20.0, b: 30.0, a: 1.0),
      );
    });
  });

  group('adapt-kurkle-names-proto', () {
    test('Object.prototype members are not colors', () {
      // JavaScript gives 'rgb(undefined, undefined, undefined)' for both.
      expect(cssColor('constructor').valid, isFalse);
      expect(cssColor('__proto__').valid, isFalse);
    });
  });

  group('names', () {
    test('toLowerCase maps U+0130 as JavaScript does', () {
      // JS lowercases U+0130 to 'i' + U+0307, so no name matches.
      expect(cssColor('LİME').valid, isFalse);
      expect(cssColor('hotpİnk').valid, isFalse);
      expect(cssColor('LIME').rgbString(), 'rgb(0, 255, 0)');
    });
  });

  group('set rgb', () {
    test('takes an array with a normalized alpha', () {
      final c = cssColor('red')..rgb = <Object?>[1, 2, 3, 0.4];
      expect(_members(c.rgb), (r: 1.0, g: 2.0, b: 3.0, a: 0.4));
    });

    test('takes a truthy primitive as an empty object', () {
      final c = cssColor('red')..rgb = 5;
      expect(_members(c.rgb), (r: 0.0, g: 0.0, b: 0.0, a: 1.0));
    });

    test('throws for a falsy value', () {
      expect(() => cssColor('red').rgb = 0, throwsA(isA<TypeError>()));
      expect(() => cssColor('red').rgb = null, throwsA(isA<TypeError>()));
    });

    test('does not make an invalid color valid', () {
      final c = cssColor('nope')
        ..rgb = <String, Object?>{'r': 1, 'g': 2, 'b': 3, 'a': 0.5};
      expect(c.valid, isFalse);
      expect(_members(c.rgb), (r: 1.0, g: 2.0, b: 3.0, a: 0.5));
      expect(c.rgbString(), isNull);
      expect(c.hexString(), isNull);
    });
  });

  group('invalid colors', () {
    test('the string methods give undefined', () {
      expect(cssColor('x').rgbString(), isNull);
      expect(cssColor('x').hexString(), isNull);
      expect(cssColor('x').hslString(), isNull);
      expect(cssColor('x').rgb, isNull);
      expect(cssColor('x').clone().valid, isFalse);
    });

    test('the methods that read the color throw', () {
      expect(() => cssColor('x').alpha(0.5), throwsA(isA<TypeError>()));
      expect(() => cssColor('x').clearer(0.5), throwsA(isA<TypeError>()));
      expect(() => cssColor('x').opaquer(0.5), throwsA(isA<TypeError>()));
      expect(() => cssColor('x').negate(), throwsA(isA<TypeError>()));
      expect(() => cssColor('x').greyscale(), throwsA(isA<TypeError>()));
      expect(() => cssColor('x').rotate(5), throwsA(isA<TypeError>()));
      expect(
        () => cssColor('red').mix(cssColor('nope'), 0.5),
        throwsA(isA<TypeError>()),
      );
      expect(
        () => cssColor('red').interpolate(cssColor('nope'), 0.5),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('manipulation', () {
    test('mix', () {
      expect(
        _members(
          cssColor('rgba(255, 0, 0, 0.2)').mix(cssColor('#00f'), 0.25).rgb,
        ),
        (r: 9.0, g: 0.0, b: 246.0, a: 0.8),
      );
      // w * a === -1.
      expect(
        _members(cssColor('rgba(255, 0, 0, 0)').mix(cssColor('#00f'), 0).rgb),
        (r: 0.0, g: 0.0, b: 255.0, a: 1.0),
      );
    });

    test('greyscale', () {
      expect(_members(cssColor('#ff0080').greyscale().rgb), (
        r: 91.0,
        g: 91.0,
        b: 91.0,
        a: 1.0,
      ));
    });

    test('rotate by a negative fraction', () {
      expect(_members(cssColor('#7743CE').rotate(-400.5).rgb), (
        r: 67.0,
        g: 110.0,
        b: 206.0,
        a: 1.0,
      ));
      expect(
        cssColor('#7743CE').rotate(33.3).hslString(),
        'hsl(295, 59%, 54%)',
      );
    });

    test('lighten black, saturate gray', () {
      expect(cssColor('black').lighten(0.5).rgbString(), 'rgb(0, 0, 0)');
      expect(
        cssColor('#808080').saturate(0.5).rgbString(),
        'rgb(128, 128, 128)',
      );
      expect(cssColor('#808080').hslString(), 'hsl(0, 0%, 50%)');
    });

    test('clearer with hexString', () {
      expect(
        cssColor('rgba(10, 10, 10, 0.8)').clearer(0.5).hexString(),
        '#0A0A0A66',
      );
    });

    test('greyscale with rgbString', () {
      expect(cssColor('#7743CE').greyscale().rgbString(), 'rgb(98, 98, 98)');
    });

    test('hwb and hsv with alpha', () {
      expect(_members(cssColor('hwb(120, 10%, 20%)').rgb), (
        r: 26.0,
        g: 204.0,
        b: 26.0,
        a: 1.0,
      ));
      expect(_members(cssColor('hsv(300, 30%, 70%, 50%)').rgb), (
        r: 179.0,
        g: 125.0,
        b: 179.0,
        a: 0.5,
      ));
    });
  });
}
