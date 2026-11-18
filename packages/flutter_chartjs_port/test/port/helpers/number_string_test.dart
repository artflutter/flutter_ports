// Original code, not ported from Chart.js: tests of lib/src/helpers/number_string.dart.
import 'dart:typed_data';

import 'package:flutter_chartjs_port/src/helpers/number_string.dart';
import 'package:test/test.dart';

import '../js/number_to_string_reference.dart';

void main() {
  group('numberString', () {
    final pairs = [
      for (final line in numberToStringReference.split('\n'))
        if (line.isNotEmpty) line.split(' '),
    ];

    test('has the generated number of inputs', () {
      expect(pairs, hasLength(10000));
    });

    test('has the reference of Node.js v24.22.1 on arm64', () {
      expect(numberToStringReferenceNode, 'v24.22.1');
      expect(numberToStringReferenceArch, 'arm64');
    });

    test('equals V8 $numberToStringReferenceV8 on '
        '$numberToStringReferenceArch String(x) for every input', () {
      final mismatches = <String>[];
      for (final [input, expected] in pairs) {
        final actual = numberString(_fromHex(input));
        if (actual != expected) {
          mismatches.add('$input: expected $expected, got $actual');
        }
      }
      expect(mismatches, isEmpty);
    });

    test('formats the notation boundaries', () {
      const cases = <(num, String)>[
        (0, '0'),
        (-0.0, '0'),
        (double.nan, 'NaN'),
        (double.infinity, 'Infinity'),
        (double.negativeInfinity, '-Infinity'),
        (12, '12'),
        (12.0, '12'),
        (-12.5, '-12.5'),
        (0.1 + 0.2, '0.30000000000000004'),
        (0.000001, '0.000001'),
        (0.0000001, '1e-7'),
        (-0.00000015, '-1.5e-7'),
        (1e20, '100000000000000000000'),
        (123456789012345680000.0, '123456789012345680000'),
        (1e21, '1e+21'),
        (1.5e21, '1.5e+21'),
        (double.maxFinite, '1.7976931348623157e+308'),
        (double.minPositive, '5e-324'),
        (9007199254740991, '9007199254740991'),
        (-9007199254740991, '-9007199254740991'),
        (9007199254740992.0, '9007199254740992'),
        (-9007199254740992.0, '-9007199254740992'),
        (18014398509481984.0, '18014398509481984'),
        (1152921504606846976.0, '1152921504606847000'),
        (999999999999999900000.0, '999999999999999900000'),
        (-1e20, '-100000000000000000000'),
        (4503599627370495.5, '4503599627370495.5'),
        (255, '255'),
        (255.0, '255'),
        (-1.0, '-1'),
      ];
      for (final (x, expected) in cases) {
        expect(numberString(x), expected, reason: '$x');
      }
    });
  });
}

/// The double of the 16 hex digits [bits] of its IEEE 754 form.
double _fromHex(String bits) {
  final words = ByteData(8)
    ..setUint32(0, int.parse(bits.substring(0, 8), radix: 16))
    ..setUint32(4, int.parse(bits.substring(8), radix: 16));
  return words.getFloat64(0);
}
