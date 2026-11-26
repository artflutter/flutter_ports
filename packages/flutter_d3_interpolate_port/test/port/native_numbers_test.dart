// Original code, not ported from d3-interpolate: the pins of the number rules.

/// Pins the results where the number rules of `dart:math` and of Dart
/// [int] give another result than upstream d3-interpolate v3.0.1. Each
/// upstream value comes from the source of `third_party/d3-interpolate` in
/// Node.js v24.22.1 on arm64.
///
/// The VM and dart2wasm keep the Dart rules: `pow(1, y)` and
/// `pow(-1, ±Infinity)` are 1, `toInt()` saturates at the bounds of a 64-bit
/// int, and an `int` is not a `double`. DDC and dart2js run on JavaScript
/// numbers and call `Math.pow`, so there each result is the upstream one.
library;

import 'dart:typed_data';

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_interpolate_port/d3_interpolate.dart';
import 'package:test/test.dart';

/// Whether the code runs on JavaScript numbers (DDC or dart2js).
const bool _jsNumbers =
    bool.fromEnvironment('dart.library.js_interop') &&
    !bool.fromEnvironment('dart.tool.dart2wasm');

void main() {
  group('platform-interpolate-math-last-bit', () {
    test('interpolateRgb.gamma(0) and gamma(-0) give 1 for each channel '
        'that differs, where upstream gives NaN', () {
      for (final y in [0.0, -0.0]) {
        final c = interpolateRgb.gamma(y)(
          const Rgb(10, 20, 30),
          const Rgb(200, 100, 50),
        )(0.5);
        if (_jsNumbers) {
          expect(c.r, isNaN, reason: 'gamma $y');
          expect(c.g, isNaN, reason: 'gamma $y');
          expect(c.b, isNaN, reason: 'gamma $y');
          expect(c.toString(), 'rgb(0, 0, 0)', reason: 'gamma $y');
        } else {
          expect([c.r, c.g, c.b], [1, 1, 1], reason: 'gamma $y');
          expect(c.toString(), 'rgb(1, 1, 1)', reason: 'gamma $y');
        }
      }
    });

    test('interpolateRgb.gamma of NaN or ±Infinity gives the upstream '
        'results', () {
      // d3.interpolateRgb.gamma(g)(rgb(1, 20, 30), rgb(200, 1, 50))(t) in
      // Node.js, for t = 0, 0.5 and 1.
      const expected = [
        (double.infinity, 'rgb(1, 1, 1)'),
        (double.negativeInfinity, 'rgb(1, 1, 1)'),
        (double.nan, 'rgb(0, 0, 0)'),
      ];
      for (final (y, text) in expected) {
        final i = interpolateRgb.gamma(y)(
          const Rgb(1, 20, 30),
          const Rgb(200, 1, 50),
        );
        for (final t in [0.0, 0.5, 1.0]) {
          expect(i(t).toString(), text, reason: 'gamma $y, t $t');
        }
      }
    });

    test('interpolateCubehelix.gamma of NaN or ±Infinity gives the end '
        'lightness at t = 1, where upstream gives NaN', () {
      const end = Rgb(200, 1, 50);
      final endL = Cubehelix.from(end).l;
      for (final y in [double.nan, double.infinity, double.negativeInfinity]) {
        final c = interpolateCubehelix.gamma(y)(const Rgb(1, 20, 30), end)(1);
        if (_jsNumbers) {
          expect(c.l, isNaN, reason: 'gamma $y');
          expect(c.toString(), 'rgb(0, 0, 0)', reason: 'gamma $y');
        } else {
          expect(c.l, endL, reason: 'gamma $y');
          expect(c.toString(), 'rgb(200, 1, 50)', reason: 'gamma $y');
        }
      }
    });

    test('interpolateCubehelix.gamma of ±Infinity gives the end lightness at '
        't = -1, where upstream gives NaN', () {
      const end = Rgb(200, 1, 50);
      final endL = Cubehelix.from(end).l;
      for (final y in [double.infinity, double.negativeInfinity]) {
        final c = interpolateCubehelix.gamma(y)(const Rgb(1, 20, 30), end)(-1);
        if (_jsNumbers) {
          expect(c.l, isNaN, reason: 'gamma $y');
          expect(c.toString(), 'rgb(0, 0, 0)', reason: 'gamma $y');
        } else {
          expect(c.l, endL, reason: 'gamma $y');
        }
      }
    });
  });

  group('adapt-interpolate-typed-values', () {
    test('a list of integers stores the low bits of upstream for a value '
        'below 2^63', () {
      // d3.interpolateNumberArray([3e9, -3e9, 5e15, 1e18],
      // new Int32Array(4))(0) in Node.js.
      expect(
        interpolateNumberArray(<num>[3e9, -3e9, 5e15, 1e18], Int32List(4))(0),
        [-1294967296, 1294967296, 937459712, -1486618624],
      );
    });

    test('a list of integers stores the saturated toInt() of a value of '
        'magnitude 2^63 or more', () {
      final i32 = interpolateNumberArray(<num>[1e20], Int32List(1))(0);
      final u8 = interpolateNumberArray(<num>[1e20], Uint8List(1))(0);
      final u32 = interpolateNumberArray(<num>[
        9.3e18,
        1e20,
        -1e20,
      ], Uint32List(3))(0);
      if (_jsNumbers) {
        // The values of upstream in Node.js.
        expect(i32, [1661992960]);
        expect(u8, [0]);
        expect(u32, [4213309440, 1661992960, 2632974336]);
      } else {
        expect(i32, [-1]);
        expect(u8, [255]);
        expect(u32, [4294967295, 4294967295, 0]);
      }
    });

    test('a NaN or infinite value throws in a list of integers', () {
      for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
        expect(
          () => interpolateNumberArray(<num>[v], Int32List(1))(0),
          throwsUnsupportedError,
          reason: '$v',
        );
      }
    });

    test('an int b throws an ArgumentError on the VM and with dart2wasm, and '
        'interpolates on JavaScript numbers', () {
      if (_jsNumbers) {
        expect(interpolate<num>(1, 2)(0.5), 1.5);
        final i = interpolateArray<int>([1], [2]);
        expect(() => i(0.5), throwsA(isA<TypeError>()));
      } else {
        expect(() => interpolate<num>(1, 2), throwsArgumentError);
        expect(() => interpolateArray<int>([1], [2]), throwsArgumentError);
      }
    });
  });
}
