// Original code, not ported from Chart.js: jsLog10 against V8 Math.log10.
import 'dart:typed_data';

import 'package:flutter_chartjs_port/src/js/js_math.dart';
import 'package:test/test.dart';

import 'log10_reference.dart';

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
  final pairs = [
    for (final line in log10Reference.split('\n'))
      if (line.isNotEmpty) line.split(' '),
  ];

  group('jsLog10', () {
    test('has the generated number of inputs', () {
      // 5,909 inputs, then 3 where V8 on arm64 differs from x64.
      expect(pairs, hasLength(5912));
    });

    // The frozen fdlibm data of Chart.js ADR 0045, section 2.
    test('has the reference of the x64 Node.js v24.12.0', () {
      expect(log10ReferenceNode, 'v24.12.0');
      expect(log10ReferenceArch, 'x64');
    });

    test('equals V8 $log10ReferenceV8 on $log10ReferenceArch Math.log10 '
        '(fdlibm without fused multiply-add) bit for bit', () {
      final mismatches = <String>[];
      for (final [input, expected] in pairs) {
        final actual = jsLog10(_fromHex(input));
        // JavaScript has one NaN; its bits are not observable.
        final same = _fromHex(expected).isNaN
            ? actual.isNaN
            : _toHex(actual) == expected;
        if (!same) {
          mismatches.add('$input: expected $expected, got ${_toHex(actual)}');
        }
      }
      expect(mismatches, isEmpty);
    });

    test('is the exponent at normal powers of ten', () {
      // fdlibm e_log10.c, note 1: log10(10**n) = n where 10**n is normal.
      for (var n = -307; n <= 308; n++) {
        final x = double.parse('1e$n');
        expect(jsLog10(x), n, reason: '1e$n');
        expect(jsLog10(x).floorToDouble(), n, reason: 'floor, 1e$n');
      }
    });
  });
}
