// Ported from d3-format v3.1.2 test/format-type-e-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'package:flutter_d3_format_port/d3_format.dart';
import 'package:test/test.dart';

void main() {
  test('format("e") can output exponent notation', () {
    final f = format('e');
    expect(f(0), '0.000000e+0');
    expect(f(42), '4.200000e+1');
    expect(f(42000000), '4.200000e+7');
    expect(f(420000000), '4.200000e+8');
    expect(f(-4), '−4.000000e+0');
    expect(f(-42), '−4.200000e+1');
    expect(f(-4200000), '−4.200000e+6');
    expect(f(-42000000), '−4.200000e+7');
    expect(format('.0e')(42), '4e+1');
    expect(format('.3e')(42), '4.200e+1');
  });

  test('format("e") can format negative zero as zero', () {
    expect(format('1e')(-0.0), '0.000000e+0');
    expect(format('1e')(-1e-12), '−1.000000e-12');
  });

  test('format(",e") does not group Infinity', () {
    expect(format(',e')(double.infinity), 'Infinity');
  });

  test('format(".3e") can format negative infinity', () {
    expect(format('.3e')(double.negativeInfinity), '−Infinity');
  });
}
