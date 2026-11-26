// Ported from d3-format v3.1.2 test/format-type-r-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'package:flutter_d3_format_port/d3_format.dart';
import 'package:test/test.dart';

void main() {
  test('format("r") can round to significant digits', () {
    expect(format('.1r')(0.049), '0.05');
    expect(format('.1r')(-0.049), '−0.05');
    expect(format('.1r')(0.49), '0.5');
    expect(format('.1r')(-0.49), '−0.5');
    expect(format('.2r')(0.449), '0.45');
    expect(format('.3r')(0.4449), '0.445');
    expect(format('.3r')(1.00), '1.00');
    expect(format('.3r')(0.9995), '1.00');
    expect(format('.5r')(0.444449), '0.44445');
    expect(format('r')(123.45), '123.450');
    expect(format('.1r')(123.45), '100');
    expect(format('.2r')(123.45), '120');
    expect(format('.3r')(123.45), '123');
    expect(format('.4r')(123.45), '123.5');
    expect(format('.5r')(123.45), '123.45');
    expect(format('.6r')(123.45), '123.450');
    expect(format('.1r')(0.9), '0.9');
    expect(format('.1r')(0.09), '0.09');
    expect(format('.1r')(0.949), '0.9');
    expect(format('.1r')(0.0949), '0.09');
    expect(format('.1r')(0.0000000129), '0.00000001');
    expect(format('.2r')(0.0000000129), '0.000000013');
    expect(format('.2r')(0.00000000129), '0.0000000013');
    expect(format('.3r')(0.00000000129), '0.00000000129');
    expect(format('.4r')(0.00000000129), '0.000000001290');
    expect(format('.10r')(0.9999999999), '0.9999999999');
    expect(format('.15r')(0.999999999999999), '0.999999999999999');
  });

  test('format("r") can round zero', () {
    expect(format('.2r')(0), '0');
    expect(format('.1r')(0), '0');
    expect(format('r')(0), '0');
  });

  test('format("r") can round very small numbers', () {
    final f = format('.2r');
    expect(f(1e-22), '0.00000000000000000000010');
  });
}
