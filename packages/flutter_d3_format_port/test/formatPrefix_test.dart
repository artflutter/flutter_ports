// Ported from d3-format v3.1.2 test/formatPrefix-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'package:flutter_d3_format_port/d3_format.dart';
import 'package:test/test.dart';

void main() {
  test('formatPrefix(",.0s", value)(number) formats with the SI prefix '
      'appropriate to the specified value', () {
    expect(formatPrefix(',.0s', 1e-6)(0.00042), '420µ');
    expect(formatPrefix(',.0s', 1e-6)(0.0042), '4,200µ');
  });

  test('formatPrefix(",.3s", value)(number) formats with the SI prefix '
      'appropriate to the specified value', () {
    expect(formatPrefix(',.3s', 1e-3)(0.00042), '0.420m');
  });

  test(
    'formatPrefix(",.0s", value)(number) uses yocto for very small reference '
    'values',
    () {
      expect(formatPrefix(',.0s', 1e-27)(1e-24), '1y');
    },
  );

  test(
    'formatPrefix(",.0s", value)(number) uses yotta for very small reference '
    'values',
    () {
      expect(formatPrefix(',.0s', 1e27)(1e24), '1Y');
    },
  );

  test(r'formatPrefix(" $12,.1s", value)(number) formats with the specified SI '
      'prefix', () {
    // The fixed length of 12 is inclusive of the unit 'M'
    final f = formatPrefix(r' $12,.1s', 1e6);
    expect(f(-42e6), r'     −$42.0M');
    expect(f(4.2e6), r'       $4.2M');
  });

  test(r'formatPrefix(" $12,.1s", value)(number) matches '
      r'format(" $12,.2s")(number) when the units are the same', () {
    // The fixed length of 12 is inclusive of the unit 'M'
    final fp = formatPrefix(r' $12,.1s', 1e6);
    final f = format(r' $12,.2s');
    expect(fp(4.2e6), r'       $4.2M');
    expect(f(4.2e6), r'       $4.2M');
  });

  test(r'formatPrefix("($~s", value)(number) formats with the SI prefix inside '
      'parentheses', () {
    expect(formatPrefix(r'($~s', 1e3)(1e3), r'$1k');
    expect(formatPrefix(r'($~s', 1e3)(-1e3), r'($1k)');
  });
}
