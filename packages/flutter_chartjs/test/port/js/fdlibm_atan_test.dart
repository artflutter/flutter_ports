// Original code, not ported from Chart.js: jsAtan2 against V8 Math.atan2.
import 'dart:typed_data';

import 'package:flutter_chartjs/src/js/js_math.dart';
import 'package:test/test.dart';

import 'atan2_reference.dart';

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
    for (final line in atan2Reference.split('\n'))
      if (line.isNotEmpty) line.split(' '),
  ];

  group('jsAtan2', () {
    test('has the generated number of inputs', () {
      expect(triples, hasLength(3000));
    });

    test('equals V8 $atan2ReferenceV8 on $atan2ReferenceArch Math.atan2 '
        '(fdlibm without fused multiply-add) bit for bit', () {
      final mismatches = <String>[];
      for (final [y, x, expected] in triples) {
        final actual = jsAtan2(_fromHex(y), _fromHex(x));
        // JavaScript has one NaN; its bits are not observable.
        final same = _fromHex(expected).isNaN
            ? actual.isNaN
            : _toHex(actual) == expected;
        if (!same) {
          mismatches.add(
            '$y $x: expected $expected, got ${_toHex(actual)}',
          );
        }
      }
      expect(mismatches, isEmpty);
    });

    test('returns +-pi/2 when |y/x| > 2**60, also when x < 0', () {
      // The line of the port that is not in netlib fdlibm 5.3, which returns
      // +-(pi/2 + 1 ulp) for these.
      expect(jsAtan2(1e300, -1e-300), 1.5707963267948966);
      expect(jsAtan2(-1e300, -1e-300), -1.5707963267948966);
      expect(jsAtan2(-1000, -5.551115123125783e-17), -1.5707963267948966);
      expect(jsAtan2(1e300, 1e-300), 1.5707963267948966);
    });

    test('keeps the V8 last bit where host libraries differ', () {
      // The macOS libm and the dart:math atan2 on the VM return
      // -1.5707963267948966 here.
      expect(jsAtan2(-100_000_000_000_000_000, -1), -1.5707963267948968);
      // Chrome 155 returns +0 here.
      final tiny = jsAtan2(-5e-324, 502.77);
      expect(tiny, 0);
      expect(tiny.isNegative, isTrue);
    });
  });
}
