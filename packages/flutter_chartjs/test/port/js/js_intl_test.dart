// Original code, not ported from Chart.js: tests of the package:intl adapter.
import 'package:flutter_chartjs/src/js/js_intl.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:test/test.dart';

// The V8 strings come from `new Intl.NumberFormat(locale, options)` in
// Node.js v24.12.0 (V8 13.6, ICU 77.1) on x64, with LANG=en_US.UTF-8.
// The workspace resolves intl 0.20.3 (CLDR 48).

/// Whether the test runs as JavaScript (dart2js). The VM and dart2wasm have
/// 64-bit integers, dart2js has JS numbers.
const bool _isJs = identical(1, 1.0);

/// `new Intl.NumberFormat(locale, options).format(value)`.
String _format(
  double value, [
  Object? locale = undefined,
  Map<String, Object?>? options,
]) => jsNumberFormat(locale, options).format(value);

void main() {
  group('jsNumberFormatLocale', () {
    test('maps a BCP 47 tag to an intl locale', () {
      expect(jsNumberFormatLocale('en-US'), 'en_US');
      expect(jsNumberFormatLocale('pt-BR'), 'pt_BR');
      // intl has no de_DE or zh_Hant_TW data: the language, or the language
      // and the region.
      expect(jsNumberFormatLocale('de-DE'), 'de');
      expect(jsNumberFormatLocale('zh-Hant-TW'), 'zh_TW');
      expect(jsNumberFormatLocale('en_US'), 'en_US');
    });

    test('takes the first tag with data from a list', () {
      expect(jsNumberFormatLocale(['de-DE']), 'de');
      expect(jsNumberFormatLocale(['xx-YY', 5, 'fr-CA', 'de']), 'fr_CA');
      expect(jsNumberFormatLocale(['xx-YY']), 'en_US');
      expect(jsNumberFormatLocale(<Object?>[]), 'en_US');
    });

    test('gives the current intl locale for undefined, null and others', () {
      expect(jsNumberFormatLocale(undefined), 'en_US');
      // V8 throws a TypeError for null.
      expect(jsNumberFormatLocale(null), 'en_US');
      expect(jsNumberFormatLocale(5), 'en_US');
    });

    test('falls back to the current locale for a tag without data', () {
      // V8 falls back to its default locale, en-US.
      expect(jsNumberFormatLocale('xx-YY'), 'en_US');
      // V8 throws a RangeError for ''.
      expect(jsNumberFormatLocale(''), 'en_US');
    });
  });

  group('jsNumberFormat gives the V8 string', () {
    test('for the default options', () {
      expect(_format(1234.5678), '1,234.568');
      expect(_format(1234.5678, 'en-US'), '1,234.568');
      expect(_format(1234.5678, 'de-DE'), '1.234,568');
      expect(_format(1234.5678, 'pt-BR'), '1.234,568');
      expect(_format(1234.5678, 'fr'), '1\u{202F}234,568');
      expect(
        _format(1234.5678, 'ar-EG'),
        '\u{661}\u{66C}\u{662}\u{663}\u{664}\u{66B}\u{665}\u{666}\u{668}',
      );
      expect(_format(12345678.9, 'en-IN'), '1,23,45,678.9');
      expect(_format(9007199254740992), '9,007,199,254,740,992');
    });

    test('for NaN, the infinities and negative zero', () {
      expect(_format(double.nan), 'NaN');
      expect(_format(double.negativeInfinity), '-\u{221E}');
      // Negative zero, spelled out.
      // ignore: prefer_int_literals
      expect(_format(-0.0), '-0');
    });

    test('for the fraction digits', () {
      final options = {'minimumFractionDigits': 2, 'maximumFractionDigits': 2};
      expect(_format(1, 'en', options), '1.00');
      expect(_format(1.01, 'en', options), '1.01');
      expect(
        _format(1234.5, undefined, {'minimumFractionDigits': 5}),
        '1,234.50000',
      );
      expect(
        _format(1234.5678, undefined, {'maximumFractionDigits': 1}),
        '1,234.6',
      );
      expect(_format(0.15, undefined, {'maximumFractionDigits': 1}), '0.2');
      expect(_format(2.5, undefined, {'maximumFractionDigits': 0}), '3');
      expect(_format(-2.5, undefined, {'maximumFractionDigits': 0}), '-3');
      // JS ToNumber of the option value.
      expect(
        _format(1234.5678, undefined, {'maximumFractionDigits': '1'}),
        '1,234.6',
      );
      expect(
        _format(1234.5678, undefined, {'maximumFractionDigits': null}),
        '1,235',
      );
    });

    test('for the significant digits, which win over the fraction digits', () {
      expect(_format(9.999, undefined, {'maximumSignificantDigits': 3}), '10');
      expect(_format(0.5, undefined, {'minimumSignificantDigits': 3}), '0.500');
      expect(
        _format(123.456, undefined, {'maximumSignificantDigits': 2}),
        '120',
      );
      expect(
        _format(1.994e-7, undefined, {'maximumSignificantDigits': 3}),
        '0.000000199',
      );
      expect(
        _format(9.999, undefined, {
          'maximumSignificantDigits': 3,
          'maximumFractionDigits': 0,
        }),
        '10',
      );
    });

    test('for minimumIntegerDigits and useGrouping', () {
      expect(_format(5, undefined, {'minimumIntegerDigits': 3}), '005');
      expect(_format(1234.5, undefined, {'useGrouping': false}), '1234.5');
      expect(_format(1234.5678, undefined, {'useGrouping': null}), '1234.568');
      expect(
        _format(1234.5678, undefined, {'useGrouping': 'always'}),
        '1,234.568',
      );
    });

    test('for scientific notation', () {
      Map<String, Object?> digits(String notation, int n) => {
        'notation': notation,
        'minimumFractionDigits': n,
        'maximumFractionDigits': n,
      };
      expect(_format(2e-5, undefined, digits('scientific', 5)), '2.00000E-5');
      expect(_format(1.5e-7, undefined, digits('scientific', 1)), '1.5E-7');
      expect(_format(0.1, undefined, digits('scientific', 1)), '1.0E-1');
      expect(
        _format(1234.5678, undefined, {
          'notation': 'scientific',
          'maximumSignificantDigits': 2,
        }),
        '1.2E3',
      );
    });

    test('for the percent and currency styles', () {
      expect(_format(0.256, undefined, {'style': 'percent'}), '26%');
      expect(
        _format(0.256, undefined, {
          'style': 'percent',
          'minimumFractionDigits': 1,
        }),
        '25.6%',
      );
      expect(
        _format(1234.5, undefined, {'style': 'currency', 'currency': 'USD'}),
        r'$1,234.50',
      );
      expect(
        _format(1234, undefined, {'style': 'currency', 'currency': 'JPY'}),
        '\u{A5}1,234',
      );
      expect(
        _format(1234.5, 'de-DE', {'style': 'currency', 'currency': 'EUR'}),
        '1.234,50\u{A0}\u{20AC}',
      );
      // ECMA-402 upper-cases the currency code.
      expect(
        _format(1234.5, undefined, {'style': 'currency', 'currency': 'usd'}),
        r'$1,234.50',
      );
    });
  });

  // The guards of js_intl.dart against package:intl failures. Without them,
  // intl throws or writes wrong digits for these values.
  group('jsNumberFormat guards', () {
    test('caps the fraction digits that significant digits ask for', () {
      final options = {'maximumSignificantDigits': 3};
      expect(_format(1.5e-14, undefined, options), '0.000000000000015');
      // V8: '0.00000000000000015', '0.000000000000000015' for both,
      // '0.0000000000000000199' and 1.5e-100 with 100 zeros. The cap of the
      // fraction digits cuts them.
      expect(_format(1.5e-16, undefined, options), '0');
      expect(_format(1.5e-17, undefined, options), '0');
      expect(_format(1.5e-17, undefined, {'notation': 'compact'}), '0');
      expect(_format(1.994e-17, undefined, options), '0');
      expect(_format(1.5e-100, undefined, options), '0');
      expect(_format(1.5e-100, undefined, {'notation': 'compact'}), '0');
      expect(_format(5e-324, undefined, options), '0');
    });

    test('caps the fraction digits at 15', () {
      Map<String, Object?> digits(int n, [Map<String, Object?>? more]) => {
        ...?more,
        'minimumFractionDigits': n,
        'maximumFractionDigits': n,
      };
      // V8: '2.0000000000000000000E-19', '9.5000000000000000000',
      // '0.10000000000000000000' and '25.60000000000000000000%'. Percent
      // has two fraction digits less.
      final zeros = '0' * 14;
      expect(
        _format(2e-19, undefined, digits(19, {'notation': 'scientific'})),
        '2.${zeros}0E-19',
      );
      expect(_format(9.5, undefined, digits(19)), '9.5$zeros');
      expect(_format(0.1, undefined, digits(20)), '0.1$zeros');
      expect(
        _format(0.256, undefined, digits(20, {'style': 'percent'})),
        '25.6${'0' * 12}%',
      );
      // V8: '0.00000000000000001'. Without the cap, dart2js gives
      // '0.00000000000000000'.
      expect(
        _format(1.2345678e-17, undefined, digits(17)),
        '0.000000000000000',
      );
    });

    test('writes NaN and the infinities in compact notation', () {
      final options = {'notation': 'compact'};
      expect(_format(double.nan, undefined, options), 'NaN');
      expect(_format(double.infinity, undefined, options), '\u{221E}');
      expect(
        _format(double.negativeInfinity, undefined, options),
        '-\u{221E}',
      );
    });

    test('writes a subnormal number in scientific notation', () {
      final options = {'notation': 'scientific'};
      // V8: the same strings.
      expect(_format(5e-324, undefined, options), '5E-324');
      expect(_format(-5e-324, undefined, options), '-5E-324');
      expect(_format(1.5e-320, undefined, options), '1.5E-320');
      expect(_format(2.3e-308, undefined, options), '2.3E-308');
      // V8: '1.00E-320'. The guard ignores the options.
      expect(
        _format(1e-320, undefined, {
          'notation': 'scientific',
          'minimumFractionDigits': 2,
        }),
        '1E-320',
      );
    });
  });

  group('jsNumberFormat', () {
    test('ignores the options that it does not support', () {
      // V8: '1,234.568 m', '+1,234.568' and a TypeError.
      expect(
        _format(1234.5678, undefined, {'style': 'unit', 'unit': 'meter'}),
        '1,234.568',
      );
      expect(
        _format(1234.5678, undefined, {'signDisplay': 'always'}),
        '1,234.568',
      );
      expect(_format(1234.5678, undefined, {'style': 'currency'}), '1,234.568');
      expect(
        _format(1234.5678, undefined, {
          'roundingMode': 'floor',
          'trailingZeroDisplay': 'stripIfInteger',
          'numberingSystem': 'arab',
        }),
        '1,234.568',
      );
    });

    test('throws where V8 throws a RangeError for digit options', () {
      for (final options in <Map<String, Object?>>[
        {'maximumFractionDigits': 101},
        {'minimumFractionDigits': -1},
        {'minimumFractionDigits': 3, 'maximumFractionDigits': 2},
        {'maximumSignificantDigits': 0},
        {'minimumSignificantDigits': 5, 'maximumSignificantDigits': 2},
        {'minimumIntegerDigits': 22},
        {'maximumFractionDigits': 'x'},
      ]) {
        expect(
          () => jsNumberFormat(undefined, options),
          throwsArgumentError,
          reason: '$options',
        );
      }
    });
  });

  // Chart.js ADR 0008 and differences.md row adapt-intl-number-format. A
  // package:intl upgrade that changes one of these strings fails here. Then
  // update the ADR and the row.
  group('adapt-intl-number-format', () {
    test('intl rounds the binary value of a double', () {
      // V8: '1.01' and '0.00008'. ICU rounds the shortest decimal string.
      expect(_format(1.005, undefined, {'maximumFractionDigits': 2}), '1');
      expect(
        _format(0.000075, undefined, {
          'minimumFractionDigits': 5,
          'maximumFractionDigits': 5,
        }),
        '0.00007',
      );
    });

    test('intl scientific notation', () {
      // V8: '1E15' and '1.235E3'.
      expect(
        _format(1000000000000000, undefined, {
          'notation': 'scientific',
          'minimumFractionDigits': 0,
          'maximumFractionDigits': 0,
        }),
        '10E14',
      );
      expect(_format(1234.5, undefined, {'notation': 'scientific'}), '1.234E3');
    });

    test('intl has CLDR 48 symbols and no minimum grouping digits', () {
      // V8 (CLDR 47): U+2019, '1234' and '1234,5'.
      expect(_format(1234.5678, 'de-CH'), "1'234.568");
      expect(_format(1234, 'es'), '1.234');
      expect(
        _format(1234.5, 'af', {'useGrouping': 'min2'}),
        '1\u{A0}234,5',
      );
    });

    test('intl compact notation', () {
      // V8: '1.2K'.
      expect(_format(1234.5, undefined, {'notation': 'compact'}), '1.23K');
    });

    test('the adapter trims options that Chart.js does not pass', () {
      // V8: '123.456E3', '1.2 million' and 'EUR\u{A0}1,234.50'.
      // Engineering notation falls back to scientific notation,
      // compactDisplay 'long' to compact notation and currencyDisplay 'code'
      // to the simple symbol.
      expect(
        _format(123456, undefined, {'notation': 'engineering'}),
        '1.235E5',
      );
      expect(
        _format(1234567, undefined, {
          'notation': 'compact',
          'compactDisplay': 'long',
        }),
        '1.23M',
      );
      expect(
        _format(1234.5, undefined, {
          'style': 'currency',
          'currency': 'EUR',
          'currencyDisplay': 'code',
        }),
        '\u{20AC}1,234.50',
      );
    });

    test('the percent and currency styles ignore some notations', () {
      // V8: '5E1%', '50%', '$2E16', '$1.2K' and '$NaN'.
      expect(
        _format(0.5, undefined, {'style': 'percent', 'notation': 'scientific'}),
        '50%',
      );
      expect(
        _format(0.5, undefined, {'style': 'percent', 'notation': 'compact'}),
        '50%',
      );
      expect(
        _format(20000000000000000, undefined, {
          'style': 'currency',
          'currency': 'USD',
          'notation': 'scientific',
        }),
        r'$20,000,000,000,000,000.00',
      );
      final compactCurrency = {
        'style': 'currency',
        'currency': 'USD',
        'notation': 'compact',
      };
      expect(_format(1234.5, undefined, compactCurrency), r'$1,234.50');
      expect(_format(double.nan, undefined, compactCurrency), 'NaN');
    });

    test('intl integers above 2^63', () {
      // V8: '100,000,000,000,000,000,000' and '10,000,000,000,000,000,000'.
      // On the VM and dart2wasm, intl overflows a 64-bit int above 2^63.
      // dart2js has the V8 string there.
      expect(
        _format(1e20),
        _isJs ? '100,000,000,000,000,000,000' : '92,233,720,368,547,758,070',
      );
      expect(
        _format(1e19, undefined, {'maximumSignificantDigits': 3}),
        _isJs ? '10,000,000,000,000,000,000' : '8,400,000,000,000,000,000',
      );
    });
  });
}
