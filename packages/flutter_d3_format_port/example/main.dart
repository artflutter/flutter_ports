// Original code, not ported from d3-format: package example.

// Example prints formatted outputs.
// ignore_for_file: avoid_print

import 'package:flutter_d3_format_port/d3_format.dart';

void main() {
  print('SI prefix:   ${format('.3s')(145500000)}'); // 146M
  print('Currency:    ${format(r'+$,.2f')(-12345.67)}'); // −$12,345.67
  print('Percent:     ${format('.1%')(0.2345)}'); // 23.5%
  print('Hex:         ${format('#x')(0xdeadbeef)}'); // 0xdeadbeef
  print('French EUR:  ${formatLocale(localeFrFR).format(r'$,.2f')(12345.67)}');
  print(
    'Indian INR:  ${formatLocale(localeEnIN).format(r'$,.2f')(12345678.9)}',
  );
  print('Arabic AED:  ${formatLocale(localeArAE).format(r'$,.2f')(1234.56)}');
  final pf = precisionFixed(0.05);
  final pr = precisionRound(0.01, 1.01);
  print('Precision:   fixed=$pf, round=$pr');
}
