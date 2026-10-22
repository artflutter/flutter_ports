// Original code, not ported from Chart.js: tests of the Color port.
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/kurkle_color/index.esm.dart';
import 'package:test/test.dart';

// The behaviour of Color that the upstream test/index.js does not check. The
// expected values come from src/index.esm.js of @kurkle/color 0.3.2 in
// Node.js v24.12.0 on x64 (V8 13.6.233.17-node.37). JS undefined results are
// Dart null.

/// The members of [v] as a record, for `expect`.
({double r, double g, double b, double a})? _members(RGBA? v) =>
    v == null ? null : (r: v.r, g: v.g, b: v.b, a: v.a);

void main() {
  group('constructor', () {
    test('a Color input gives the same instance', () {
      final c = Color('red');
      expect(identical(Color(c), c), isTrue);
      expect(identical(color(c), c), isTrue);
    });

    test('inputs that are not objects or strings are not valid', () {
      expect(Color(undefined).valid, isFalse);
      expect(Color(5).valid, isFalse);
      expect(Color(true).valid, isFalse);
      expect(Color(() => 1).valid, isFalse);
      expect(Color('').valid, isFalse);
    });

    test('JS null throws, as the TypeError of `v.a` does', () {
      expect(() => Color(null), throwsA(isA<TypeError>()));
    });

    test('short arrays and empty objects give opaque black', () {
      const black = (r: 0.0, g: 0.0, b: 0.0, a: 1.0);
      expect(_members(Color(<Object?>[]).rgb), black);
      expect(_members(Color(<Object?>[1, 2]).rgb), black);
      expect(_members(Color(<String, Object?>{}).rgb), black);
      expect(_members(Color(Object()).rgb), black);
    });

    test('a non-hex digit is 0 in r, g and b, and NaN in a', () {
      expect(_members(Color('#ggg').rgb), (r: 0.0, g: 0.0, b: 0.0, a: 1.0));
      // b2n(NaN) is 0, and NaN < 255 is false.
      expect(
        _members(Color('#fffg').rgb),
        (r: 255.0, g: 255.0, b: 255.0, a: 0.0),
      );
      expect(Color('#fffg').hexString(), '#FFF');
      expect(Color('#fffg').rgbString(), 'rgb(255, 255, 255)');
    });

    test('a member string is ToNumber in arithmetic', () {
      expect(
        Color(<Object?>[1, 20, 30, '0.5']).rgbString(),
        'rgba(1, 20, 30, 0.5)',
      );
    });
  });

  group('adapt-kurkle-rgba', () {
    // JavaScript keeps the member values as they are. A template literal
    // then prints them: 'rgb(010, 20, 30)', 'rgb(null, 20, 30)' and
    // 'rgb(undefined, 20, 30)'. The port converts them with ToNumber.
    test('object and array members are numbers', () {
      expect(
        Color(<String, Object?>{'r': '010', 'g': 20, 'b': 30}).rgbString(),
        'rgb(10, 20, 30)',
      );
      expect(
        Color(<Object?>['010', 20, 30]).rgbString(),
        'rgb(10, 20, 30)',
      );
      expect(
        Color(<String, Object?>{'r': null, 'g': 20, 'b': 30}).rgbString(),
        'rgb(0, 20, 30)',
      );
      expect(
        Color(<String, Object?>{'r': undefined, 'g': 20, 'b': 30}).rgbString(),
        'rgb(NaN, 20, 30)',
      );
    });

    test('other keys of an object input are not copied', () {
      // JavaScript gives {r: 1, g: 20, b: 30, a: 1, x: 5}.
      expect(
        _members(
          Color(<String, Object?>{'r': 1, 'g': 20, 'b': 30, 'x': 5}).rgb,
        ),
        (r: 1.0, g: 20.0, b: 30.0, a: 1.0),
      );
    });
  });

  group('adapt-kurkle-names-proto', () {
    test('Object.prototype members are not colors', () {
      // JavaScript gives 'rgb(undefined, undefined, undefined)' for both.
      expect(Color('constructor').valid, isFalse);
      expect(Color('__proto__').valid, isFalse);
    });
  });

  group('names', () {
    test('toLowerCase maps U+0130 as JavaScript does', () {
      // JS lowercases U+0130 to 'i' + U+0307, so no name matches.
      expect(Color('LİME').valid, isFalse);
      expect(Color('hotpİnk').valid, isFalse);
      expect(Color('LIME').rgbString(), 'rgb(0, 255, 0)');
    });
  });

  group('set rgb', () {
    test('takes an array with a normalized alpha', () {
      final c = Color('red')..rgb = <Object?>[1, 2, 3, 0.4];
      expect(_members(c.rgb), (r: 1.0, g: 2.0, b: 3.0, a: 0.4));
    });

    test('takes a truthy primitive as an empty object', () {
      final c = Color('red')..rgb = 5;
      expect(_members(c.rgb), (r: 0.0, g: 0.0, b: 0.0, a: 1.0));
    });

    test('throws for a falsy value', () {
      expect(() => Color('red').rgb = 0, throwsA(isA<TypeError>()));
      expect(() => Color('red').rgb = undefined, throwsA(isA<TypeError>()));
    });

    test('does not make an invalid color valid', () {
      final c = Color('nope')
        ..rgb = <String, Object?>{'r': 1, 'g': 2, 'b': 3, 'a': 0.5};
      expect(c.valid, isFalse);
      expect(_members(c.rgb), (r: 1.0, g: 2.0, b: 3.0, a: 0.5));
      expect(c.rgbString(), isNull);
      expect(c.hexString(), isNull);
    });
  });

  group('invalid colors', () {
    test('the string methods give undefined', () {
      expect(Color('x').rgbString(), isNull);
      expect(Color('x').hexString(), isNull);
      expect(Color('x').hslString(), isNull);
      expect(Color('x').rgb, isNull);
      expect(Color('x').clone().valid, isFalse);
    });

    test('the methods that read the color throw', () {
      expect(() => Color('x').alpha(0.5), throwsA(isA<TypeError>()));
      expect(() => Color('x').clearer(0.5), throwsA(isA<TypeError>()));
      expect(() => Color('x').opaquer(0.5), throwsA(isA<TypeError>()));
      expect(() => Color('x').negate(), throwsA(isA<TypeError>()));
      expect(() => Color('x').greyscale(), throwsA(isA<TypeError>()));
      expect(() => Color('x').rotate(5), throwsA(isA<TypeError>()));
      expect(
        () => Color('red').mix(Color('nope'), 0.5),
        throwsA(isA<TypeError>()),
      );
      expect(
        () => Color('red').interpolate(Color('nope'), 0.5),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('manipulation', () {
    test('mix', () {
      expect(
        _members(Color('rgba(255, 0, 0, 0.2)').mix(Color('#00f'), 0.25).rgb),
        (r: 9.0, g: 0.0, b: 246.0, a: 0.8),
      );
      // w * a === -1.
      expect(
        _members(Color('rgba(255, 0, 0, 0)').mix(Color('#00f'), 0).rgb),
        (r: 0.0, g: 0.0, b: 255.0, a: 1.0),
      );
    });

    test('greyscale', () {
      expect(
        _members(Color('#ff0080').greyscale().rgb),
        (r: 91.0, g: 91.0, b: 91.0, a: 1.0),
      );
    });

    test('rotate by a negative fraction', () {
      expect(
        _members(Color('#7743CE').rotate(-400.5).rgb),
        (r: 67.0, g: 110.0, b: 206.0, a: 1.0),
      );
      expect(Color('#7743CE').rotate(33.3).hslString(), 'hsl(295, 59%, 54%)');
    });

    test('lighten black, saturate gray', () {
      expect(Color('black').lighten(0.5).rgbString(), 'rgb(0, 0, 0)');
      expect(Color('#808080').saturate(0.5).rgbString(), 'rgb(128, 128, 128)');
      expect(Color('#808080').hslString(), 'hsl(0, 0%, 50%)');
    });

    test('clearer with hexString', () {
      expect(
        Color('rgba(10, 10, 10, 0.8)').clearer(0.5).hexString(),
        '#0A0A0A66',
      );
    });

    test('greyscale with rgbString', () {
      expect(Color('#7743CE').greyscale().rgbString(), 'rgb(98, 98, 98)');
    });

    test('hwb and hsv with alpha', () {
      expect(
        _members(Color('hwb(120, 10%, 20%)').rgb),
        (r: 26.0, g: 204.0, b: 26.0, a: 1.0),
      );
      expect(
        _members(Color('hsv(300, 30%, 70%, 50%)').rgb),
        (r: 179.0, g: 125.0, b: 179.0, a: 0.5),
      );
    });
  });
}
