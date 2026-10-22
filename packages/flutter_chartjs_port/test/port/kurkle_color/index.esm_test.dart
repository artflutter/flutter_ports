// Original code, not ported from Chart.js: tests of the kurkle functions.
import 'dart:convert';

import 'package:flutter_chartjs_port/src/kurkle_color/index.esm.dart';
import 'package:flutter_chartjs_port/src/kurkle_color/srgb.dart';
import 'package:test/test.dart';

// The exports of src/index.esm.js, and interpolate of src/srgb.js, which the
// upstream test/index.js does not call. The expected values come from the
// @kurkle/color 0.3.2 sources in Node.js v24.12.0 on x64 (V8
// 13.6.233.17-node.37). JS undefined results are Dart null.

/// The members of [v] as a record, for `expect`.
({double r, double g, double b, double a})? _members(RGBA? v) =>
    v == null ? null : (r: v.r, g: v.g, b: v.b, a: v.a);

RGBA _rgba(double r, double g, double b, double a) =>
    RGBA(r: r, g: g, b: b, a: a);

void main() {
  group('byte.js', () {
    test('round truncates toward zero after + 0.5', () {
      expect(round(-50.5), -50);
      expect(round(-0.7), 0);
      expect(round(2.5), 3);
    });

    test('conversions', () {
      expect(p2b(50), 127);
      expect(b2p(128), 50);
      expect(n2b(0.5), 128);
      expect(b2n(51), 0.2);
      expect(n2p(0.333), 33);
      expect(lim(double.nan, 0, 1), isNaN);
    });
  });

  group('hue.js', () {
    test('hsl2rgb takes three numbers or a list', () {
      expect(hsl2rgb(30.0, 0.5, 0.5), [191, 128, 64]);
      expect(hsl2rgb([30.0, 0.5, 0.5]), [191, 128, 64]);
      // s and l are undefined, which gives NaN, and n2b(NaN) is 0.
      expect(hsl2rgb(30.0), [0, 0, 0]);
    });

    test('hsl2rgb, hwb2rgb and hsv2rgb take any JS number or array', () {
      expect(hsl2rgb(0, 1, 0.5), [255, 0, 0]);
      expect(hsl2rgb(<num>[0, 1, 0.5]), [255, 0, 0]);
      expect(hsl2rgb(jsonDecode('[120,1,0.5]') as Object), [0, 255, 0]);
      // The missing elements are undefined, which gives NaN.
      expect(hsl2rgb([1]), [0, 0, 0]);
      expect(hsl2rgb(<Object?>[]), [0, 0, 0]);
      expect(hwb2rgb(200, 0, 0), [0, 170, 255]);
      expect(hsv2rgb(120, 1, 1), [0, 255, 0]);
      expect(hwb2rgb([200, 1, 1]), [128, 128, 128]);
      expect(hsv2rgb([300, 1]), [0, 0, 0]);
    });

    test('hwb2rgb scales w + b > 1', () {
      expect(hwb2rgb(200.0, 0.7, 0.6), [137, 137, 137]);
    });

    test('hsv2rgb', () {
      expect(hsv2rgb(200.0, 0.3, 0.9), [161, 207, 230]);
    });

    test('rgb2hsl', () {
      expect(rgb2hsl(_rgba(128, 128, 128, 255)), [0, 0, 0.5019607843137255]);
      expect(rgb2hsl(_rgba(10, 200, 99, 255)), [
        148,
        0.9047619047619049,
        0.4117647058823529,
      ]);
    });

    test('hueParse', () {
      expect(
        _members(hueParse('hsl(1.5e2, 30%, 40%)')),
        (r: 71.0, g: 133.0, b: 102.0, a: 255.0),
      );
      // ToNumber('1..2') is NaN, and NaN gives 0 in each member.
      expect(
        _members(hueParse('hsl(1..2, 30%, 40%)')),
        (r: 0.0, g: 0.0, b: 0.0, a: 255.0),
      );
      expect(hueParse('hsl(120deg 40% 60% / 0.3)'), isNull);
    });

    test('hslString of undefined', () {
      expect(hslString(null), isNull);
    });
  });

  group('hex.js', () {
    test('hexParse', () {
      expect(
        _members(hexParse('#abc')),
        (r: 170.0, g: 187.0, b: 204.0, a: 255.0),
      );
      expect(hexParse('abc'), isNull);
      expect(hexParse('#ab'), isNull);
      expect(hexParse(''), isNull);
    });

    test('hexString', () {
      expect(hexString(_rgba(0x11, 0x22, 0x33, 255)), '#123');
      expect(hexString(_rgba(0x12, 0x22, 0x33, 128)), '#12223380');
      // isShort(undefined) reads v.r.
      expect(() => hexString(null), throwsA(isA<TypeError>()));
    });
  });

  group('rgb.js', () {
    test('rgbParse', () {
      expect(
        _members(rgbParse('rgb(1 2 3 / 50%)')),
        (r: 1.0, g: 2.0, b: 3.0, a: 127.0),
      );
      expect(
        _members(rgbParse('rgba(1, 2, 3)')),
        (r: 1.0, g: 2.0, b: 3.0, a: 255.0),
      );
      expect(rgbParse('rgb(1,2)'), isNull);
    });

    test('rgbString prints numbers as JavaScript does', () {
      expect(
        rgbString(_rgba(10.5, 1e21, 0.000001, 51)),
        'rgba(10.5, 1e+21, 0.000001, 0.2)',
      );
      expect(rgbString(null), isNull);
    });
  });

  group('names.js', () {
    test('nameParse', () {
      expect(
        _members(nameParse('Red')),
        (r: 255.0, g: 0.0, b: 0.0, a: 255.0),
      );
      expect(
        _members(nameParse('rebeccapurple')),
        (r: 102.0, g: 51.0, b: 153.0, a: 255.0),
      );
      expect(
        _members(nameParse('lightgoldenrodyellow')),
        (r: 250.0, g: 250.0, b: 210.0, a: 255.0),
      );
      expect(
        _members(nameParse('darkslategrey')),
        (r: 47.0, g: 79.0, b: 79.0, a: 255.0),
      );
      expect(
        [
          'aliceblue',
          'yellowgreen',
          'mediumspringgreen',
          'lightslategray',
          'darkorchid',
          'papayawhip',
        ].map((name) => _members(nameParse(name))),
        [
          (r: 240.0, g: 248.0, b: 255.0, a: 255.0),
          (r: 154.0, g: 205.0, b: 50.0, a: 255.0),
          (r: 0.0, g: 250.0, b: 154.0, a: 255.0),
          (r: 119.0, g: 136.0, b: 153.0, a: 255.0),
          (r: 153.0, g: 50.0, b: 204.0, a: 255.0),
          (r: 255.0, g: 239.0, b: 213.0, a: 255.0),
        ],
      );
    });
  });

  group('srgb.js', () {
    test('interpolate', () {
      expect(
        _members(
          interpolate(_rgba(255, 0, 0, 255), _rgba(0, 0, 255, 0), 0.3),
        ),
        (r: 218.0, g: 0.0, b: 149.0, a: 178.5),
      );
    });
  });
}
