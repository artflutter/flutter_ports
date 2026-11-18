// Original code, not ported from d3-color: the twin of the table of hex.

/// The twin test of the row `adapt-color-hex-table`: `hex2` reads a table of
/// 256 texts and gives the text of the plain translation of color.js:296 on
/// a large set of generated values.
library;

import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:test/test.dart';

/// color.js:292 `clampi(value)`, as the port had it before the row
/// `adapt-color-clamp-compare`.
int _clampiReference(double value) {
  final v = value.roundToDouble();
  return v > 0 ? (v < 255 ? v.toInt() : 255) : 0;
}

/// color.js:296 `hex(value)`: `value = clampi(value); return (value < 16 ?
/// "0" : "") + value.toString(16);`.
String _hexReference(double value) {
  final v = _clampiReference(value);
  return (v < 16 ? '0' : '') + v.toRadixString(16);
}

/// The values of the twin: the specials, each half from -4 to 300 with its
/// neighbors, and random values.
List<double> _values() {
  final random = Random(7);
  final data = ByteData(8);
  final values = <double>[
    double.nan,
    0,
    -0,
    double.infinity,
    double.negativeInfinity,
    double.maxFinite,
    double.minPositive,
    -double.minPositive,
    0.49999999999999994,
    254.49999999999997,
  ];
  for (var k = -8; k <= 600; k++) {
    final half = k / 2;
    values.add(half);
    if (half == 0) continue;
    for (final step in [-1, 1]) {
      data.setFloat64(0, half);
      final low = data.getUint32(4) + step;
      if (low < 0 || low > 0xffffffff) continue;
      data.setUint32(4, low);
      values.add(data.getFloat64(0));
    }
  }
  for (var i = 0; i < 20000; i++) {
    values
      ..add(random.nextDouble() * 300 - 20)
      ..add(random.nextInt(25600) / 100)
      ..add(random.nextDouble() * 255);
  }
  return values;
}

void main() {
  test('hex2 gives the text of the plain translation', () {
    final values = _values();
    final mismatches = <String>[];
    for (final x in values) {
      final actual = hex2(x);
      final expected = _hexReference(x);
      if (actual != expected) mismatches.add('hex2($x): $actual, $expected');
    }
    expect(mismatches, isEmpty);
    expect(values.length, greaterThan(60000));
  });

  test('the table has each text from 00 to ff', () {
    for (var v = 0; v < 256; v++) {
      expect(hex2(v.toDouble()), _hexReference(v.toDouble()));
    }
  });
}
