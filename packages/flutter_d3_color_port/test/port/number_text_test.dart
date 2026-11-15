// Original code, not ported from d3-color: the twin of the number texts.

/// The twin test of the row `adapt-color-number-text`: `numberText` writes
/// the text of a number k / 100 from the digits of k and gives the text of
/// the plain form, `double.toString` with no fraction for a whole number, on
/// a large set of generated values.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_d3_color_port/src/color.dart';
import 'package:test/test.dart';

/// The text of a number in a template literal of color.js, as the port had
/// it before the row `adapt-color-number-text`.
String _numberTextReference(double x) =>
    x == x.truncateToDouble() ? x.toInt().toString() : x.toString();

/// The text that [text] gives, or the type of the error that it throws.
String _outcome(String Function() text) {
  try {
    return text();
  } on Object catch (error) {
    return 'throws ${error.runtimeType}';
  }
}

/// The doubles next to [x] toward 0 and away from 0, for a finite [x] that
/// is not 0.
List<double> _neighbors(double x) {
  final data = ByteData(8);
  final result = <double>[];
  for (final step in [-1, 1]) {
    data.setFloat64(0, x);
    var high = data.getUint32(0);
    var low = data.getUint32(4) + step;
    if (low < 0) {
      low += 0x100000000;
      high -= 1;
    } else if (low > 0xffffffff) {
      low -= 0x100000000;
      high += 1;
    }
    data
      ..setUint32(0, high)
      ..setUint32(4, low);
    result.add(data.getFloat64(0));
  }
  return result;
}

/// The values of the twin: each k / 100 in [0, 360] with its neighbors, the
/// percentages of the HSL formats, random values and edge cases.
List<double> _values() {
  final random = math.Random(11);
  final values = <double>[
    double.nan,
    0,
    -0,
    double.infinity,
    double.negativeInfinity,
    double.maxFinite,
    -double.maxFinite,
    double.minPositive,
    -double.minPositive,
    1e-7,
    1e-6,
    9.999999999999999e-7,
    1.2345678901234567e-7,
    0.000001234567890123456,
    0.005,
    0.125,
    0.1 + 0.2,
    359.99999999999994,
    360.00000000000006,
    999,
    1000,
    1e21,
    1e300,
    -1,
    -0.5,
    -360,
  ];
  for (var k = 0; k <= 36000; k++) {
    final x = k / 100;
    values.add(x);
    if (k > 0) values.addAll(_neighbors(x));
  }
  for (var k = 0; k <= 1000; k++) {
    final s = k / 1000;
    values
      ..add(s * 100)
      ..add(k / 1000 * 360)
      ..add(k / 10000);
  }
  for (var i = 0; i < 20000; i++) {
    values
      ..add(random.nextDouble() * 360)
      ..add(random.nextDouble())
      ..add(random.nextDouble() * 100)
      ..add(random.nextInt(100000) / 1000)
      ..add(math.pow(10, -random.nextInt(30) - random.nextDouble()).toDouble());
  }
  return values;
}

void main() {
  test('numberText gives the text of the plain form', () {
    final values = _values();
    final mismatches = <String>[];
    for (final x in values) {
      final actual = _outcome(() => numberText(x));
      final expected = _outcome(() => _numberTextReference(x));
      if (actual != expected) {
        mismatches.add('numberText($x): $actual, $expected');
      }
    }
    expect(mismatches, isEmpty);
    expect(values.length, greaterThan(200000));
  });

  test('a number k / 100 has the digits of k', () {
    expect(numberText(0), '0');
    expect(numberText(-0), '0');
    expect(numberText(0.05), '0.05');
    expect(numberText(0.5), '0.5');
    expect(numberText(45.6), '45.6');
    expect(numberText(123.45), '123.45');
    expect(numberText(360), '360');
    expect(numberText(45.599999999999994), '45.599999999999994');
  });
}
