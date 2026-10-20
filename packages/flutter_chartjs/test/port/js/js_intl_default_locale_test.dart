// Original code, not ported from Chart.js: Intl.defaultLocale in js_intl.
@TestOn('vm')
library;

import 'package:flutter_chartjs/src/helpers/helpers.intl.dart';
import 'package:flutter_chartjs/src/js/js_intl.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:intl/intl.dart';
import 'package:test/test.dart';

// These tests set Intl.defaultLocale, so they import package:intl. The web
// test legs compile only files that import pure layers and package:test
// (check:lib-imports). Thus these tests run on the VM only.
// test/port/js/js_intl_test.dart has the other tests of the adapter.

void main() {
  late String? saved;
  setUp(() => saved = Intl.defaultLocale);
  tearDown(() => Intl.defaultLocale = saved);

  test('jsNumberFormatLocale follows Intl.defaultLocale', () {
    Intl.defaultLocale = 'de_DE';
    expect(jsNumberFormatLocale(undefined), 'de');
    expect(jsNumberFormatLocale(<Object?>[]), 'de');
    expect(jsNumberFormatLocale('xx-YY'), 'de');
    expect(jsNumberFormatLocale('fr'), 'fr');
    expect(jsNumberFormat(undefined).format(1234.5), '1.234,5');
    // A current locale without data gives en_US.
    Intl.defaultLocale = 'xx';
    expect(jsNumberFormatLocale(undefined), 'en_US');
  });

  test('formatNumber follows a change of Intl.defaultLocale', () {
    // The cache key holds the resolved intl locale, not 'undefined'. Thus a
    // later change of Intl.defaultLocale gives another key.
    final options = {'minimumIntegerDigits': 2};
    expect(formatNumber(1234.5, undefined, options), '1,234.5');
    Intl.defaultLocale = 'de_DE';
    expect(formatNumber(1234.5, undefined, options), '1.234,5');
    Intl.defaultLocale = 'en_US';
    expect(formatNumber(1234.5, undefined, options), '1,234.5');
  });
}
