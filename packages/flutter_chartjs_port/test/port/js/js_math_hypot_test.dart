// Original code, not ported from Chart.js: jsHypot against V8 Math.hypot.
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_chartjs_port/src/js/js_math.dart';
import 'package:test/test.dart';

import 'hypot_reference.dart';

/// The double with the 16 hex digits [bits].
double _fromHex(String bits) {
  final words = ByteData(8)
    ..setUint32(0, int.parse(bits.substring(0, 8), radix: 16))
    ..setUint32(4, int.parse(bits.substring(8), radix: 16));
  return words.getFloat64(0);
}

/// The 16 hex digits of the bits of [x].
String _toHex(double x) {
  final words = ByteData(8)..setFloat64(0, x);
  return [
    words.getUint32(0),
    words.getUint32(4),
  ].map((word) => word.toRadixString(16).padLeft(8, '0')).join();
}

void main() {
  final triples = [
    for (final line in hypotReference.split('\n'))
      if (line.isNotEmpty) line.split(' '),
  ];

  group('jsHypot', () {
    test('has the generated number of inputs', () {
      expect(triples, hasLength(3000));
    });

    // The reference engine of Chart.js ADR 0045.
    test('has the reference of Node.js v24.22.1 on arm64', () {
      expect(hypotReferenceNode, 'v24.22.1');
      expect(hypotReferenceArch, 'arm64');
    });

    test('equals V8 $hypotReferenceV8 on $hypotReferenceArch Math.hypot '
        'bit for bit', () {
      final mismatches = <String>[];
      for (final [a, b, expected] in triples) {
        final actual = jsHypot(_fromHex(a), _fromHex(b));
        // JavaScript has one NaN; its bits are not observable.
        final same = _fromHex(expected).isNaN
            ? actual.isNaN
            : _toHex(actual) == expected;
        if (!same) {
          mismatches.add('$a $b: expected $expected, got ${_toHex(actual)}');
        }
      }
      expect(mismatches, isEmpty);
    });

    test('differs from the plain square root of the sum of the squares', () {
      // The reason for the V8 form (Chart.js ADR 0108): the plain form
      // differs from the reference for some inputs.
      var differences = 0;
      for (final [a, b, expected] in triples) {
        final x = _fromHex(a);
        final y = _fromHex(b);
        final plain = math.sqrt(x * x + y * y);
        final same = _fromHex(expected).isNaN
            ? plain.isNaN
            : _toHex(plain) == expected;
        if (!same) differences++;
      }
      expect(differences, greaterThan(0));
    });

    test('gives +Infinity for an infinite operand, also with NaN', () {
      expect(jsHypot(double.infinity, double.nan), double.infinity);
      expect(jsHypot(double.nan, double.negativeInfinity), double.infinity);
      expect(jsHypot(double.negativeInfinity, 0), double.infinity);
      expect(jsHypot(double.nan, 1), isNaN);
      expect(jsHypot(0, double.nan), isNaN);
    });

    test('gives +0 for two zeros of any sign', () {
      for (final (a, b) in const [(0.0, -0.0), (-0.0, -0.0), (-0.0, 0.0)]) {
        final result = jsHypot(a, b);
        expect(result, 0);
        expect(result.isNegative, isFalse);
      }
    });

    test('neither overflows nor underflows in the squares', () {
      // The V8 results (probe on the reference engine).
      expect(jsHypot(1e200, 1e200), 1.414213562373095e+200);
      expect(jsHypot(1e-200, 1e-200), 1.414213562373095e-200);
      expect(jsHypot(3, -4), 5);
      expect(jsHypot(double.maxFinite, double.maxFinite), double.infinity);
    });
  });
}
