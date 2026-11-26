// Ported from d3-format v3.1.2 test/format-type-p-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'package:flutter_d3_format_port/d3_format.dart';
import 'package:test/test.dart';

void main() {
  test('format("p") can output a percentage', () {
    final f = format('p');
    expect(f(0.00123), '0.123000%');
    expect(f(0.0123), '1.23000%');
    expect(f(0.123), '12.3000%');
    expect(f(0.234), '23.4000%');
    expect(f(1.23), '123.000%');
    expect(f(-0.00123), '−0.123000%');
    expect(f(-0.0123), '−1.23000%');
    expect(f(-0.123), '−12.3000%');
    expect(f(-1.23), '−123.000%');
  });

  test('format("+p") can output a percentage with rounding and sign', () {
    final f = format('+.2p');
    expect(f(0.00123), '+0.12%');
    expect(f(0.0123), '+1.2%');
    expect(f(0.123), '+12%');
    expect(f(1.23), '+120%');
    expect(f(-0.00123), '−0.12%');
    expect(f(-0.0123), '−1.2%');
    expect(f(-0.123), '−12%');
    expect(f(-1.23), '−120%');
  });
}
