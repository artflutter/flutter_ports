// Original code, not ported from Chart.js: color fast-path equivalence tests.

import 'package:flutter_chartjs_port/src/js/js_math.dart' show jsToInt32;
import 'package:flutter_chartjs_port/src/js/js_number.dart'
    show jsNumberToString;
import 'package:flutter_chartjs_port/src/kurkle_color/index.esm.dart';
import 'package:test/test.dart';

({double r, double g, double b, double a})? _members(RGBA? v) =>
    v == null ? null : (r: v.r, g: v.g, b: v.b, a: v.a);

void main() {
  group('adapt-kurkle-color-dispatch', () {
    test('routing keeps names, functions and invalid hex behavior', () {
      for (final input in [
        'red',
        'RED',
        '#f00',
        'rgb(255,0,0)',
        'hsl(0,100%,50%)',
      ]) {
        expect(Color(input).hexString(), '#F00');
      }
      for (final input in ['', '#ab', 'rgb(', 'RGB(255,0,0)', 'constructor']) {
        expect(Color(input).valid, isFalse);
      }
      expect(Color('#ggg').valid, isTrue);
      expect(Color('#ggg').hexString(), '#000');
      expect(Color('LİME').valid, isFalse);
      expect(Color('LIME').hexString(), '#0F0');
    });
  });

  group('adapt-kurkle-hue-arrays', () {
    test('results stay fresh and growable without changing the input', () {
      final input = <double>[120, 1, 0.5];
      final first = hsl2rgb(input)
        ..[0] = 99
        ..add(42);
      expect(first, [99, 255, 0, 42]);
      expect(input, [120, 1, 0.5]);
      expect(hsl2rgb(input), [0, 255, 0]);
      final hsl = rgb2hsl(RGBA(r: 255, g: 0, b: 0, a: 255))..add(42);
      expect(hsl, [0, 1, 0.5, 42]);
    });
  });

  group('adapt-kurkle-simple-colors', () {
    test('integer channels clamp but RGB alpha keeps its fractional byte', () {
      expect(
        _members(rgbParse('rgba(000, 999, 256, 0.5)')),
        (r: 0.0, g: 255.0, b: 255.0, a: 127.5),
      );
      expect(
        _members(rgbParse('rgba(12, 34, 56)')),
        (r: 12.0, g: 34.0, b: 56.0, a: 255.0),
      );
      expect(
        _members(rgbParse('rgb(12,34,56,.25)')),
        (r: 12.0, g: 34.0, b: 56.0, a: 63.75),
      );
    });

    test('short decimal alpha has the same rounding as Number(string)', () {
      for (var i = 0; i <= 100; i++) {
        final text = (i / 100).toStringAsFixed(2);
        final value = double.parse(text);
        expect(rgbParse('rgba(1,2,3,$text)')!.a, value * 255);
        expect(hueParse('hsla(120,100%,50%,$text)')!.a, n2b(value));
        if (i < 100) {
          expect(rgbParse('rgba(1,2,3,${text.substring(1)})')!.a, value * 255);
        }
      }
    });

    test('HSL, HSV and HWB keep their distinct conversions', () {
      expect(
        _members(hueParse('hsl(120,100%,50%)')),
        (r: 0.0, g: 255.0, b: 0.0, a: 255.0),
      );
      expect(
        _members(hueParse('hsv(240,100%,100%,0.5)')),
        (r: 0.0, g: 0.0, b: 255.0, a: 128.0),
      );
      expect(
        _members(hueParse('hwb(0,0%,0%,.25)')),
        (r: 255.0, g: 0.0, b: 0.0, a: 64.0),
      );
    });

    test('uncommon syntax falls back to the upstream expressions', () {
      expect(
        _members(rgbParse('rgb(100% 0% 0% / 50%)')),
        (r: 255.0, g: 0.0, b: 0.0, a: 127.0),
      );
      expect(
        _members(rgbParse('rgba(+1,\t2e1,3,.5)')),
        (r: 1.0, g: 20.0, b: 3.0, a: 127.5),
      );
      expect(
        _members(rgbParse('rgb(1\u00a02\u20283)')),
        (r: 1.0, g: 2.0, b: 3.0, a: 255.0),
      );
      expect(rgbParse('rgb(1,2,3)\n'), isNull);
      expect(hueParse('hsl(120deg 100% 50%)'), isNotNull);
      expect(rgbParse('rgb(1,2,3,)'), isNull);
      expect(rgbParse('rgb(1,2,3)extra'), isNull);
      expect(hueParse('hsl(120,100,50)'), isNull);
      expect(hueParse('HSL(120,100%,50%)'), isNull);
    });
  });

  group('adapt-kurkle-decimal-groups', () {
    test('malformed numeric captures keep valid colors with NaN values', () {
      expect(rgbParse('rgba(1,2,3,1..2)')!.a, isNaN);
      expect(rgbParse('rgba(1,2,3,0..)')!.a, isNaN);
      expect(
        _members(rgbParse('rgb(1..2,20,30)')),
        (r: 0.0, g: 20.0, b: 30.0, a: 255.0),
      );
      expect(
        _members(hueParse('hsl(1..2,20%,30%)')),
        (r: 0.0, g: 0.0, b: 0.0, a: 255.0),
      );
    });

    test('overflow keeps RGB clamping and HSL ToInt32 wrapping', () {
      expect(rgbParse('rgba(1,2,3,1e999)')!.a, 255);
      expect(hueParse('hsla(120,100%,50%,1e999)')!.a, 0);
      expect(rgbParse('rgba(1,2,3,-0)')!.a.isNegative, isFalse);
    });
  });

  group('adapt-kurkle-byte-bounds', () {
    test('mix retains wrapping for wide channels and exceptional weights', () {
      // Results from the pinned src/color.js mix on arm64 Node.js v24.22.1.
      final cases = <(List<double>, List<double>, double, List<double>)>[
        (
          [2147483647.9, -2147483648.75, 4294967295, 0.5],
          [1, 2, 3, 0.5],
          0.5,
          [0, 2, 1, 0.5],
        ),
        (
          [2147483648, -2147483649, 4294967296, 0.5],
          [0, 0, 0, 0.5],
          1,
          [0, 0, 0, 0.5],
        ),
        ([-0.9, 255.9, 256.1, 0.25], [0, 0, 0, 0.75], 2, [2, 1, 1, 0]),
        (
          [double.nan, double.infinity, double.negativeInfinity, 0.5],
          [12, 34, 56, 0.5],
          0,
          [0, 0, 0, 0.5],
        ),
        ([12, 34, 56, 0.5], [255, 128, 0, 0.5], double.nan, [0, 0, 0, 0]),
        ([12, 34, 56, 0.5], [255, 128, 0, 0.5], double.infinity, [0, 0, 0, 0]),
        ([12, 34, 56, 0.5], [255, 128, 0, 0.5], -1, [242, 222, 201, 0.5]),
      ];
      for (final (from, to, weight, expected) in cases) {
        final rgb = Color(from).mix(Color(to), weight).rgb!;
        expect([rgb.r, rgb.g, rgb.b, rgb.a], expected);
      }
    });

    test('fast ranges and fallbacks match the upstream arithmetic', () {
      final values = <double>[
        double.nan,
        double.infinity,
        double.negativeInfinity,
        // Keep the sign explicit in this boundary test.
        // ignore: prefer_int_literals
        -0.0,
        -1,
        1 - 1e-15,
        1 + 1e-15,
        100 - 1e-12,
        100 + 1e-12,
        255 - 1e-12,
        255 + 1e-12,
        256,
        1e20,
        -1e20,
        double.maxFinite,
        for (var i = 0; i <= 1024; i++) ...[
          i / 1024,
          i / 1024 * 100,
          i / 1024 * 255,
        ],
      ];
      final functions = <(double Function(double), double Function(double))>[
        (p2b, (v) => lim(jsToInt32(v * 2.55 + 0.5), 0, 255)),
        (b2p, (v) => lim(jsToInt32(v / 2.55 + 0.5), 0, 100)),
        (n2b, (v) => lim(jsToInt32(v * 255 + 0.5), 0, 255)),
        (b2n, (v) => lim(jsToInt32(v / 2.55 + 0.5) / 100, 0, 1)),
        (n2p, (v) => lim(jsToInt32(v * 100 + 0.5), 0, 100)),
      ];
      for (final (actual, reference) in functions) {
        for (final value in values) {
          final expected = reference(value);
          final result = actual(value);
          expect(result, expected, reason: 'input $value');
          if (expected == 0) expect(result.isNegative, expected.isNegative);
        }
      }
    });
  });

  group('adapt-kurkle-color-strings', () {
    test('hex formatting preserves ToInt32 at signed range boundaries', () {
      for (final value in <double>[
        -2147483649,
        -2147483648.75,
        -2147483648,
        -2147483647.9,
        2147483647.9,
        2147483648,
        4294967295,
        4294967296,
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        final byte = jsToInt32(value).toInt() & 255;
        final expected =
            '#${byte.toRadixString(16).padLeft(2, '0').toUpperCase()}1122';
        // Alpha 300 is omitted but forces the long form in upstream.
        expect(hexString(RGBA(r: value, g: 17, b: 34, a: 300)), expected);
      }
    });

    test('byte RGB formatting matches the upstream template', () {
      for (var i = 0; i <= 255; i++) {
        for (final alpha in <double>[
          0,
          1,
          25.5,
          127.5,
          128,
          254.9,
          255,
          256,
          -1,
          double.nan,
          double.infinity,
        ]) {
          final v = RGBA(
            r: i.toDouble(),
            g: 255 - i.toDouble(),
            b: 17,
            a: alpha,
          );
          final expected = alpha < 255
              ? 'rgba($i, ${255 - i}, 17, ${jsNumberToString(b2n(alpha))})'
              : 'rgb($i, ${255 - i}, 17)';
          expect(rgbString(v), expected);
        }
      }
    });

    test('unusual channels and omitted alpha retain their formatting', () {
      expect(
        // Negative zero must serialize as JavaScript's "0".
        // ignore: prefer_int_literals
        rgbString(RGBA(r: -0.0, g: 1.5, b: 1e21, a: 128)),
        'rgba(0, 1.5, 1e+21, 0.5)',
      );
      expect(
        rgbString(RGBA(r: double.nan, g: 0, b: double.infinity, a: 255)),
        'rgb(NaN, 0, Infinity)',
      );
      expect(hexString(RGBA(r: 17, g: 34, b: 51, a: 256)), '#123');
      expect(hexString(RGBA(r: 17, g: 34, b: 51, a: 300)), '#112233');
      expect(hexString(RGBA(r: 17, g: 34, b: 51, a: -1)), '#123F');
      expect(hexString(RGBA(r: -1, g: 256, b: 17.9, a: 255)), '#F01');
      expect(() => hexString(null), throwsA(isA<TypeError>()));
    });
  });

  group('adapt-kurkle-color-copies', () {
    test('clone retains alpha quantization and independent mutation', () {
      final original = Color('rgba(1,2,3,0.5)');
      final copied = original.clone();
      expect(original.hexString(), '#0102037F');
      expect(copied.hexString(), '#01020380');
      copied.negate();
      expect(original.hexString(), '#0102037F');
      final rgb = original.rgb!..r = 200;
      expect(rgb.r, 200);
      expect(original.rgb!.r, 1);
    });

    test('clone of an invalid color with assigned RGB becomes valid', () {
      final c = Color('invalid')..rgb = [1, 2, 3, 0.4];
      expect(c.valid, isFalse);
      expect(c.clone().valid, isTrue);
      expect(_members(c.clone().rgb), (r: 1.0, g: 2.0, b: 3.0, a: 0.4));
      expect(Color('invalid').clone().valid, isFalse);
    });

    test('self-mixing keeps the setter alpha conversion', () {
      final c = Color('rgba(12,34,56,0.5)');
      c.mix(c, 0.25);
      expect(c.hexString(), '#0C223880');
      final other = Color('#ff638480');
      final before = other.hexString();
      c.mix(other, 0.3);
      expect(other.hexString(), before);
    });
  });
}
