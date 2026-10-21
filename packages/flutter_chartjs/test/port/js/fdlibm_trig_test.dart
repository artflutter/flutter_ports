// Original code, not ported from Chart.js: jsSin and jsCos against V8 bits.
import 'dart:typed_data';

import 'package:flutter_chartjs/src/js/js_math.dart';
import 'package:test/test.dart';

import 'trig_reference.dart';

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
    for (final line in trigReference.split('\n'))
      if (line.isNotEmpty) line.split(' '),
  ];

  group('jsSin and jsCos', () {
    test('has the generated number of inputs', () {
      expect(triples, hasLength(4040));
    });

    test('equals V8 $trigReferenceV8 on $trigReferenceArch Math.sin and '
        'Math.cos bit for bit', () {
      final mismatches = <String>[];
      for (final [x, sin, cos] in triples) {
        for (final (name, actual, expected) in [
          ('sin', jsSin(_fromHex(x)), sin),
          ('cos', jsCos(_fromHex(x)), cos),
        ]) {
          // JavaScript has one NaN; its bits are not observable. The sign of
          // a zero is compared by the bits.
          final same = _fromHex(expected).isNaN
              ? actual.isNaN
              : _toHex(actual) == expected;
          if (!same) {
            mismatches.add(
              '$name($x): expected $expected, got ${_toHex(actual)}',
            );
          }
        }
      }
      expect(mismatches, isEmpty);
    });

    test('the hit ties of phase 7', () {
      // CI run 39544591156, Windows: the half angle of arc 0 of the doughnut
      // case `parsed: object items with the default key`.
      expect(_toHex(jsSin(-0.7853981633974483)), 'bfe6a09e667f3bcc');
      expect(jsSin(-0.7853981633974483), -0.7071067811865475);
      expect(_toHex(jsCos(-0.7853981633974483)), '3fe6a09e667f3bcd');
      expect(jsCos(-0.7853981633974483), 0.7071067811865476);
      // The half angle of arc 1 of the same case.
      expect(_toHex(jsSin(2.356194490192345)), '3fe6a09e667f3bcd');
      expect(jsSin(2.356194490192345), 0.7071067811865476);
      expect(_toHex(jsCos(2.356194490192345)), 'bfe6a09e667f3bcc');
      expect(jsCos(2.356194490192345), -0.7071067811865475);
      // The macOS libm gives -0.4999999999999998.
      expect(_toHex(jsSin(3.665191429188092)), 'bfdffffffffffffb');
      expect(jsSin(3.665191429188092), -0.4999999999999997);
      expect(_toHex(jsCos(3.665191429188092)), 'bfebb67ae8584cac');
      expect(jsCos(3.665191429188092), -0.8660254037844388);
    });

    test('special values', () {
      final negativeZero = _fromHex('8000000000000000');
      expect(_toHex(jsSin(negativeZero)), '8000000000000000');
      expect(jsCos(negativeZero), 1);
      expect(jsSin(5e-324), 5e-324);
      expect(jsSin(double.maxFinite), 0.004961954789184062);
      expect(_toHex(jsSin(double.maxFinite)), '3f7452fc98b34e97');
      expect(jsCos(double.maxFinite), -0.9999876894265599);
      expect(_toHex(jsCos(double.maxFinite)), 'bfefffe62ecfab75');
      expect(jsSin(1e22), -0.8522008497671888);
      expect(_toHex(jsSin(1e22)), 'bfeb453ab76bf397');
      expect(jsSin(3.141592653589793), 1.2246467991473532e-16);
      expect(jsCos(1.5707963267948966), 6.123233995736766e-17);
      for (final x in [double.nan, double.infinity, double.negativeInfinity]) {
        expect(jsSin(x), isNaN);
        expect(jsCos(x), isNaN);
      }
    });

    test('the bounds of the double tests', () {
      // |x| < D(0x3fe921fc) takes __kernel_sin directly; D(0x3fe921fc)
      // takes the reduction.
      expect(jsSin(0.7853984832763671), 0.707107007375064);
      expect(_toHex(jsSin(0.7853984832763671)), '3fe6a09edfee58ba');
      expect(jsSin(0.7853984832763672), 0.707107007375064);
      expect(_toHex(jsSin(0.7853984832763672)), '3fe6a09edfee58ba');
      // D(0x4002d97c): the medium reduction.
      expect(jsCos(2.3561935424804688), -0.7071061110527357);
      expect(_toHex(jsCos(2.3561935424804688)), 'bfe6a09cfeb8be6a');
      // D(0x413921fc): the reduction of __kernel_rem_pio2.
      expect(jsSin(1647100), 0.6216400379214212);
      expect(_toHex(jsSin(1647100)), '3fe3e479a61836eb');
      // D(0x3fd33333): the qx form of __kernel_cos.
      expect(jsCos(0.2999999523162842), 0.9553365032171065);
      expect(_toHex(jsCos(0.2999999523162842)), '3fee921ddbbfc253');
    });
  });
}
