// Ported from d3-format v3.1.2 test/defaultLocale-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'package:flutter_d3_format_port/d3_format.dart';
import 'package:test/test.dart';

const FormatLocaleDefinition _enUs = FormatLocaleDefinition(
  thousands: ',',
  grouping: [3],
  currency: (r'$', ''),
);

const FormatLocaleDefinition _frFr = FormatLocaleDefinition(
  decimal: ',',
  thousands: '.',
  grouping: [3],
  currency: ('', '\u00a0€'),
  percent: '\u202f%',
);

void main() {
  test('formatDefaultLocale(definition) returns the new default locale', () {
    final locale = formatDefaultLocale(_frFr);
    try {
      expect(locale.format(r'$,.2f')(12345678.90), '12.345.678,90\u00a0€');
      expect(locale.format(',.0%')(12345678.90), '1.234.567.890\u202f%');
    } finally {
      formatDefaultLocale(_enUs);
    }
  });

  test('formatDefaultLocale(definition) affects format', () {
    final locale = formatDefaultLocale(_frFr);
    try {
      // DIVERGES(d3-format): adapt-format-typed-api, top-level delegating fn
      expect(defaultLocale, same(locale));
      expect(format(r'$,.2f')(12345678.90), '12.345.678,90\u00a0€');
    } finally {
      formatDefaultLocale(_enUs);
    }
  });

  test('formatDefaultLocale(definition) affects formatPrefix', () {
    final locale = formatDefaultLocale(_frFr);
    try {
      // DIVERGES(d3-format): adapt-format-typed-api, top-level delegating fn
      expect(defaultLocale, same(locale));
      expect(formatPrefix(',.2', 1e3)(12345678.90), '12.345,68k');
    } finally {
      formatDefaultLocale(_enUs);
    }
  });
}
