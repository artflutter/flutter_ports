// Original code, not ported from d3-interpolate: the pins of the faster forms.

/// Pins the faster forms of `doc/performance.md` (the rows
/// `adapt-interpolate-typed-loops`, `adapt-interpolate-zoom-constants` and
/// `adapt-interpolate-channel-objects`):
/// each form gives the bits of the upstream lines, which the tests write
/// out here, and keeps the reads of upstream (a live read of a list, or a
/// copy at the creation).
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_d3_interpolate_port/d3_interpolate.dart';
import 'package:flutter_d3_interpolate_port/src/color.dart' as color;
import 'package:test/test.dart';

/// The values of `t` of the tests, also outside [0, 1].
const List<double> _ts = [
  -1.5,
  -1,
  -0.75,
  -0.0,
  0,
  1e-9,
  0.1,
  0.3,
  0.5,
  0.7,
  0.999999,
  1,
  1.25,
  2,
];

/// number.js:2 `a * (1 - t) + b * t`.
double _number(double a, double b, double t) => a * (1 - t) + b * t;

/// Expects the same bits: `-0.0` and `0.0` differ, and NaN equals NaN.
void _expectSame(double actual, double expected, [String? reason]) {
  if (expected.isNaN) {
    expect(actual, isNaN, reason: reason);
  } else {
    expect(actual, expected, reason: reason);
    expect(actual.isNegative, expected.isNegative, reason: reason);
  }
}

void main() {
  group('numberArray.js', () {
    final a = <double>[2.5, -1, 1e300, 0.1, 7];
    final b = <double>[4, 3, -1e300, 0.2, -7, 9];

    test('a Float64List pair gives the line of number.js', () {
      final i = interpolateNumberArray(
        Float64List.fromList(a),
        Float64List.fromList(b),
      );
      for (final t in _ts) {
        final c = i(t);
        expect(c, isA<Float64List>());
        for (var k = 0; k < a.length; k++) {
          _expectSame(c[k], _number(a[k], b[k], t), 't $t, item $k');
        }
        expect(c[5], 9, reason: 'the item of b past the end of a');
      }
    });

    test('a list of another class a with a Float64List b', () {
      final ints = <int>[2, -1, 0, 5, 7];
      final i = interpolateNumberArray(ints, Float64List.fromList(b));
      for (final t in _ts) {
        final c = i(t);
        for (var k = 0; k < ints.length; k++) {
          _expectSame(c[k], _number(ints[k].toDouble(), b[k], t));
        }
      }
    });

    test('a Float32List pair stores the float32 of the line', () {
      final a32 = Float32List.fromList(a);
      final b32 = Float32List.fromList(b);
      final i = interpolateNumberArray(a32, b32);
      for (final t in _ts) {
        final c = i(t);
        expect(c, isA<Float32List>());
        final expected = Float32List(b.length)..setAll(0, b32);
        for (var k = 0; k < a.length; k++) {
          expected[k] = _number(a32[k], b32[k], t);
        }
        expect(c, expected);
      }
    });

    test('reads a and b at each call, as upstream', () {
      final a64 = Float64List.fromList([0, 10]);
      final b64 = Float64List.fromList([10, 20]);
      final i = interpolateNumberArray(a64, b64);
      expect(i(0.5), [5, 15]);
      a64[0] = 100;
      b64[1] = 40;
      expect(i(0.5), [55, 25]);
    });
  });

  group('array.js', () {
    test('a pair of List<double> gives the line of number.js', () {
      final a = <double>[2.5, -1, 1e300, 0.1, double.nan];
      final b = <double>[4, 3, -1e300, 0.2, 1, 9];
      final i = interpolateArray<double>(a, b);
      for (final t in _ts) {
        final c = i(t);
        expect(c, isA<List<double>>());
        expect(c, hasLength(6));
        for (var k = 0; k < a.length; k++) {
          _expectSame(c[k], _number(a[k], b[k], t), 't $t, item $k');
        }
        expect(c[5], 9);
      }
    });

    test('keeps the numbers of the creation, as the item interpolators of '
        'upstream', () {
      final a = <double>[0, 10];
      final b = <double>[10, 20];
      final i = interpolateArray<double>(a, b);
      a[0] = 100;
      b[1] = 40;
      expect(i(0.5), [5, 15]);
      expect(identical(i(0.5), i(0.7)), isTrue);
    });
  });

  group('transform/index.js', () {
    test('each part that differs gives the line of number.js', () {
      final a = decompose(1, 0.5, -0.25, 2, 10, -20);
      final b = decompose(-0.5, 1, 1.5, 0.75, -30, 40);
      final i = interpolateTransform(a, b);
      // The shortest path of index.js:21.
      var ra = a.rotate;
      var rb = b.rotate;
      if (ra - rb > 180) {
        rb += 360;
      } else if (rb - ra > 180) {
        ra += 360;
      }
      for (final t in _ts) {
        final p = i(t);
        _expectSame(p.translateX, _number(a.translateX, b.translateX, t));
        _expectSame(p.translateY, _number(a.translateY, b.translateY, t));
        _expectSame(p.rotate, _number(ra, rb, t));
        _expectSame(p.skewX, _number(a.skewX, b.skewX, t));
        _expectSame(p.scaleX, _number(a.scaleX, b.scaleX, t));
        _expectSame(p.scaleY, _number(a.scaleY, b.scaleY, t));
      }
    });

    test('an equal part keeps its value, and a pair interpolates when one '
        'of its parts differs', () {
      const a = TransformParts(5, 7, 30, 0, 2, 3);
      const b = TransformParts(5, 8, 30, 0, 2, 3);
      final i = interpolateTransform(a, b);
      for (final t in _ts) {
        final p = i(t);
        _expectSame(p.translateX, _number(5, 5, t));
        _expectSame(p.translateY, _number(7, 8, t));
        expect(p.rotate, 30);
        expect(p.skewX, 0);
        expect(p.scaleX, 2);
        expect(p.scaleY, 3);
      }
    });

    test('two interpolators do not share their parts', () {
      final i = interpolateTransform(
        const TransformParts(0, 0, 0, 0, 1, 1),
        const TransformParts(10, 0, 0, 0, 1, 1),
      );
      final j = interpolateTransform(
        const TransformParts(0, 0, 90, 0, 1, 1),
        const TransformParts(0, 0, 0, 0, 2, 2),
      );
      expect(i(0.5).translateX, 5);
      expect(j(0.5).rotate, 45);
      expect(i(0.5).rotate, 0);
      expect(j(0.5).translateX, 0);
    });
  });

  group('zoom.js', () {
    /// zoom.js:48-56 with cosh(r0) and sinh(r0) at each call.
    ZoomView upstream(ZoomView p0, ZoomView p1, double t) {
      const rho = math.sqrt2;
      const rho2 = 2.0;
      const rho4 = 4.0;
      double cosh(double x) => (math.exp(x) + 1 / math.exp(x)) / 2;
      double sinh(double x) => (math.exp(x) - 1 / math.exp(x)) / 2;
      double tanh(double x) => (math.exp(2 * x) - 1) / (math.exp(2 * x) + 1);
      final (ux0, uy0, w0) = p0;
      final (ux1, uy1, w1) = p1;
      final dx = ux1 - ux0;
      final dy = uy1 - uy0;
      final d2 = dx * dx + dy * dy;
      final d1 = math.sqrt(d2);
      final b0 = (w1 * w1 - w0 * w0 + rho4 * d2) / (2 * w0 * rho2 * d1);
      final b1 = (w1 * w1 - w0 * w0 - rho4 * d2) / (2 * w1 * rho2 * d1);
      final r0 = math.log(math.sqrt(b0 * b0 + 1) - b0);
      final r1 = math.log(math.sqrt(b1 * b1 + 1) - b1);
      final s = t * ((r1 - r0) / rho);
      final coshr0 = cosh(r0);
      final u = w0 / (rho2 * d1) * (coshr0 * tanh(rho * s + r0) - sinh(r0));
      return (ux0 + u * dx, uy0 + u * dy, w0 * coshr0 / cosh(rho * s + r0));
    }

    test('the constants of the creation give the bits of each call', () {
      const views = <(ZoomView, ZoomView)>[
        ((0, 0, 1), (100, 50, 4)),
        ((300, 200, 60), (10, 20, 2)),
        ((-5, 7, 0.5), (12, -3, 9)),
      ];
      for (final (p0, p1) in views) {
        final i = interpolateZoom(p0, p1);
        for (final t in _ts) {
          final (x, y, w) = i(t);
          final (ex, ey, ew) = upstream(p0, p1, t);
          _expectSame(x, ex, '$p0 $p1 $t');
          _expectSame(y, ey, '$p0 $p1 $t');
          _expectSame(w, ew, '$p0 $p1 $t');
        }
      }
    });
  });

  group('basis.js and basisClosed.js', () {
    final values = <double>[0.5, 3, -2, 8, 10000000000, 4];

    test('a Float64List gives the values of a List<double>', () {
      final typed = interpolateBasis(Float64List.fromList(values));
      final plain = interpolateBasis(values);
      for (final t in [..._ts, double.nan]) {
        _expectSame(typed(t), plain(t), 't $t');
      }
    });

    test('a Float64List is read at each call, as upstream', () {
      final v = Float64List.fromList([0, 1, 2]);
      final i = interpolateBasis(v);
      final before = i(0.5);
      v[1] = 5;
      expect(i(0.5), isNot(before));
    });

    test('the closed spline gives the remainder of t for t in (-1, 1)', () {
      final closed = interpolateBasisClosed(values);
      double withRemainder(double t) {
        var x = t.remainder(1);
        if (x < 0) ++x;
        final n = values.length;
        final i = (x * n).floor();
        double v(int k) => values[k.remainder(n)];
        final t1 = (x - i / n) * n;
        final t2 = t1 * t1;
        final t3 = t2 * t1;
        return ((1 - 3 * t1 + 3 * t2 - t3) * v(i + n - 1) +
                (4 - 6 * t2 + 3 * t3) * v(i) +
                (1 + 3 * t1 + 3 * t2 - 3 * t3) * v(i + 1) +
                t3 * v(i + 2)) /
            6;
      }

      for (final t in [..._ts, -0.999999, 0.999999999, -1e-300]) {
        _expectSame(closed(t), withRemainder(t), 't $t');
      }
    });
  });
  group('color.js', () {
    /// Pairs of channels: equal, NaN on one side or both, -0.0, and hue
    /// differences of more than 180 degrees.
    const pairs = <(double, double)>[
      (0, 255),
      (255, 0),
      (12.5, 12.5),
      (double.nan, 30),
      (30, double.nan),
      (double.nan, double.nan),
      (-0.0, -0.0),
      (-0.0, 5),
      (350, 10),
      (10, 350),
      (540, 0),
      (-540, 0),
      (1, 1e300),
    ];

    test('nogamma gives the lines of linear and constant', () {
      for (final (a, b) in pairs) {
        final i = color.nogamma(a, b);
        final d = b - a;
        for (final t in [..._ts, double.nan, double.infinity]) {
          final expected = d != 0 && !d.isNaN ? a + t * d : (a.isNaN ? b : a);
          _expectSame(i(t), expected, '$a $b $t');
        }
      }
    });

    test('hue gives the lines of linear and constant', () {
      for (final (a, b) in pairs) {
        final i = color.hue(a, b);
        var d = b - a;
        if (d > 180 || d < -180) {
          // Math.round of d / 360: a negative half rounds up.
          final x = d / 360;
          final r = x.roundToDouble();
          d -= 360 * (r - x == -0.5 ? r + 1 : r);
        }
        for (final t in [..._ts, double.nan]) {
          final expected = b - a != 0 && !(b - a).isNaN
              ? a + t * d
              : (a.isNaN ? b : a);
          _expectSame(i(t), expected, '$a $b $t');
        }
      }
    });

    test('gamma gives the lines of exponential and constant', () {
      for (final y in [2.2, 0.5, 3.0]) {
        for (final (a, b) in pairs) {
          final i = color.gamma(y)(a, b);
          final a1 = math.pow(a, y).toDouble();
          final b1 = math.pow(b, y).toDouble() - a1;
          for (final t in _ts) {
            final expected = b - a != 0 && !(b - a).isNaN
                ? math.pow(a1 + t * b1, 1 / y).toDouble()
                : (a.isNaN ? b : a);
            _expectSame(i(t), expected, '$y $a $b $t');
          }
        }
      }
    });
  });
}
