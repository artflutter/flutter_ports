// Ported from d3-format v3.1.2 test/format-type-c-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'package:flutter_d3_format_port/d3_format.dart';
import 'package:test/test.dart';

void main() {
  test('format("c") unicode character', () {
    // DIVERGES(d3-format): adapt-format-typed-api, formatChar for String input
    expect(format('c').formatChar('☃'), '☃');
    expect(format('020c').formatChar('☃'), '0000000000000000000☃');
    expect(format(' ^20c').formatChar('☃'), '         ☃          ');
    expect(format(r'$c').formatChar('☃'), r'$☃');
  });

  test('format("c") does not localize a decimal point', () {
    // DIVERGES(d3-format): adapt-format-typed-api, formatChar for String input
    expect(
      formatLocale(const FormatLocaleDefinition(decimal: '/'))
          .format('c')
          .formatChar('.'),
      '.',
    );
  });
}
