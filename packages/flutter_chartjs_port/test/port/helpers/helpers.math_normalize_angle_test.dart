// Original code, not ported from Chart.js: normalizeAngle in range.
import 'dart:math' as dart_math;
import 'dart:typed_data';

import 'package:flutter_chartjs_port/src/helpers/helpers.math.dart';
import 'package:test/test.dart';

// differences.md `adapt-normalize-angle-range`: the form in range gives the
// bits of the two remainders of helpers.math.ts:160, for each value.

/// helpers.math.ts:160 `(a % TAU + TAU) % TAU`.
double _upstream(double a) => (a.remainder(tau) + tau).remainder(tau);

/// The next value above [a] in the order of the doubles.
double _next(double a, int steps) {
  final data = ByteData(8)..setFloat64(0, a);
  var high = data.getUint32(0);
  var low = data.getUint32(4);
  for (var i = 0; i < steps; i++) {
    if (a >= 0) {
      if (low == 0xFFFFFFFF) {
        low = 0;
        high++;
      } else {
        low++;
      }
    } else if (low == 0) {
      low = 0xFFFFFFFF;
      high--;
    } else {
      low--;
    }
  }
  data
    ..setUint32(0, high)
    ..setUint32(4, low);
  return data.getFloat64(0);
}

String _bits(double value) {
  final data = ByteData(8)..setFloat64(0, value);
  final high = data.getUint32(0).toRadixString(16).padLeft(8, '0');
  final low = data.getUint32(4).toRadixString(16).padLeft(8, '0');
  return value.isNaN ? 'nan' : '$high$low';
}

void _expectSame(double a) {
  expect(_bits(normalizeAngle(a)), _bits(_upstream(a)), reason: '$a');
}

void main() {
  group('normalizeAngle', () {
    test('the special values', () {
      const [
        0.0,
        -0.0,
        double.nan,
        double.infinity,
        double.negativeInfinity,
        double.maxFinite,
        -double.maxFinite,
        double.minPositive,
        -double.minPositive,
        1e-300,
        -1e-300,
      ].forEach(_expectSame);
    });

    test('the values at and around each edge of the range', () {
      for (final edge in const [tau, -tau, pi, -pi, halfPi, -halfPi]) {
        _expectSame(edge);
        for (var steps = 1; steps < 64; steps++) {
          _expectSame(_next(edge, steps));
          final data = ByteData(8)..setFloat64(0, edge);
          final bits = data.getUint32(4);
          data.setUint32(4, bits - steps);
          _expectSame(data.getFloat64(0));
        }
      }
    });

    test('a value whose sum with tau rounds to 2 tau gives 0', () {
      final below = () {
        final data = ByteData(8)..setFloat64(0, tau);
        data.setUint32(4, data.getUint32(4) - 1);
        return data.getFloat64(0);
      }();
      expect(below + tau, 2 * tau);
      expect(normalizeAngle(below), _upstream(below));
      expect(normalizeAngle(below), 0);
    });

    test('a tiny negative value whose sum rounds to tau gives 0', () {
      const a = -1e-30;
      expect(a + tau, tau);
      expect(_bits(normalizeAngle(a)), _bits(_upstream(a)));
      expect(normalizeAngle(a), 0);
    });

    test('random values in and past the range', () {
      final random = dart_math.Random(4242);
      for (var i = 0; i < 200000; i++) {
        final scale = const [1.0, tau, 2 * tau, 1000.0][i % 4];
        _expectSame((random.nextDouble() * 2 - 1) * scale);
      }
    });

    test('the angles of an index on a circle', () {
      for (final count in const [1, 3, 7, 360, 20000]) {
        final step = tau / count;
        for (var i = 0; i <= count; i += count > 1000 ? 7 : 1) {
          _expectSame(i * step);
          _expectSame(i * step + toRadians(33));
          _expectSame(i * step + toRadians(-725));
        }
      }
    });
  });
}
