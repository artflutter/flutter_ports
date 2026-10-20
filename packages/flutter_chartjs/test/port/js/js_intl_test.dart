// Original code, not ported from Chart.js: tests of the package:intl adapter.
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_chartjs/src/js/js_intl.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:test/test.dart';

import 'intl_reference.dart';

// The V8 strings come from `new Intl.NumberFormat(locale, options)` in
// Node.js v24.12.0 (V8 13.6, ICU 77.1) on x64, with LANG=en_US.UTF-8.
// tool/reference/intl_reference.mjs writes the data of the group
// `V8 reference data`. The workspace resolves intl 0.20.3 (CLDR 48).

/// Whether the test runs on dart2js, where an int is a double.
const bool _dart2js = identical(1, 1.0);

/// `new Intl.NumberFormat(locale, options).format(value)`.
String _format(
  double value, [
  Object? locale = undefined,
  Map<String, Object?>? options,
]) => jsNumberFormat(locale, options).format(value);

/// The double with the IEEE-754 bit pattern [bits], 16 hex digits.
double _fromBits(String bits) {
  final words = ByteData(8)
    ..setUint32(0, int.parse(bits.substring(0, 8), radix: 16))
    ..setUint32(4, int.parse(bits.substring(8), radix: 16));
  return words.getFloat64(0);
}

/// The cases of [intlReference] in [section]: the locale, the options, the
/// value and the V8 string.
List<(String, Map<String, Object?>, double, String)> _reference(
  String section,
) {
  final cases = <(String, Map<String, Object?>, double, String)>[];
  String? name;
  var locale = '';
  var options = <String, Object?>{};
  for (final line in intlReference.split('\n')) {
    if (line.isEmpty) continue;
    if (line.startsWith('# ')) {
      final fields = line.split(' ');
      name = fields[1];
      locale = fields[2];
      options = (jsonDecode(fields.sublist(3).join(' ')) as Map)
          .cast<String, Object?>();
    } else if (name == section) {
      final value = _fromBits(line.substring(0, 16));
      cases.add((locale, options, value, jsonDecode(line.substring(17))));
    }
  }
  return cases;
}

/// Tags that V8 accepts in `new Intl.NumberFormat(tag)`.
const List<String> _validTags = [
  'en-US', 'en', 'eng', 'english', 'abcdefgh', 'und', 'EN-us', //
  'En-lAtN-Us', 'en-Latn-US', 'en-Zzzz', 'en-419', 'en-123', 'qaa', //
  'aa-bbbb-cc-ddddd', 'art-lojban', 'cel-gaulish', 'zh-guoyu', //
  'de-1996-1901', 'de-DE-1996', 'en-US-POSIX', 'en-1234', 'en-0123', //
  'en-1abc', 'en-a1234', 'en-12345', 'en-u-nu', 'en-u-nu-arab', //
  'en-u-ab-cd-ef', 'en-u-attr', 'en-u-attr-nu-arab', 'en-u-1a', //
  'en-u-ca-ab', 'en-u-ca-gregory-ca-buddhist', 'de-DE-u-co-phonebk', //
  'en-t-de', 'en-t-k0-abc', 'en-t-x0-abc', 'en-t-de-k0-abc', //
  'en-t-k0-abc-def', 'en-t-en-latn', 'en-t-en-US-h0-hybrid', 'en-a-bb', //
  'en-a-bb-b-cc', 'en-US-a-xxx-u-yyy', 'en-US-u-nu-arab-t-de', //
  'en-US-1996-u-nu-arab-1996', 'en-x-foo', 'en-x-a-x-b', 'en-US-x-u-u-u', //
  'en-a-bbb-x-a-ccc', 'de-DE-u-co-phonebk-t-en-k0-abc-x-y', //
];

/// Tags for which `new Intl.NumberFormat(tag)` throws a RangeError in V8.
const List<String> _invalidTags = [
  'en_US', 'de_DE', '', 'x', 'e', 'engl', 'abcdefghi', 'root', 'x-foo', //
  'Latn', 'Latn-US', 'en-', '-en', 'en--US', 'en-US-', ' en', 'en ', //
  'en-12', 'en-1a', 'en-1ab', 'en-123456789', 'en-Latn-Latn', //
  'en-US-Latn', 'en-US-US', 'en-1996-US', 'de-1996-1996', 'zh-yue', //
  'zh-min-nan', 'i-klingon', 'i-default', 'en-GB-oed', 'sgn-BE-FR', //
  'no-bok', 'aaa-bbb', 'aa-bbb-ccc', 'en-u', 'en-u-a1-xyz', //
  'en-u-ca-abcdefghi', 'de-u-co-', 'en-u-nu-arab-u-ca-gregory', //
  'en-u-ca-gregory-t-k0-abc-u-nu-x', 'en-t', 'en-t-k0', 'en-t-k0-ab', //
  'en-t-k0-abcdefghi', 'en-t-1996', 'en-t-latn', 'en-t-en-1996-1996', //
  'en-a', 'en-a-b', 'en-a-abcdefghi', 'en-a-bbb-a-ccc', 'en-x', //
  'en-x-123456789', 'en-US-x-aaaaaaaa-', '\u0435\u043D', 'en-\u00DCS', //
  'en-\u212Aa', 'en\u0000', //
];

void main() {
  group('jsNumberFormatLocale', () {
    test('maps a BCP 47 tag to an intl locale', () {
      expect(jsNumberFormatLocale('en-US'), 'en_US');
      expect(jsNumberFormatLocale('pt-BR'), 'pt_BR');
      // intl has no de_DE or zh_Hant_TW data: the language, or the language
      // and the region.
      expect(jsNumberFormatLocale('de-DE'), 'de');
      expect(jsNumberFormatLocale('zh-Hant-TW'), 'zh_TW');
    });

    test('takes the first tag with data from a list', () {
      expect(jsNumberFormatLocale(['de-DE']), 'de');
      expect(jsNumberFormatLocale(['xx-YY', 'fr-CA', 'de']), 'fr_CA');
      expect(jsNumberFormatLocale(['xx-YY']), 'en_US');
      expect(jsNumberFormatLocale(<Object?>[]), 'en_US');
      // An item that is an object gives its ToString. V8 gives de.
      expect(
        jsNumberFormatLocale([
          ['de'],
        ]),
        'de',
      );
    });

    test('reads a JS object as an array-like list', () {
      // The index keys below ToLength(length). V8 gives de, de, fr and
      // en-US.
      expect(jsNumberFormatLocale({'length': 1, '0': 'de'}), 'de');
      expect(
        jsNumberFormatLocale({
          'length': 2.5,
          '0': 'xx',
          '1': 'de',
          '2': 'en_US',
        }),
        'de',
      );
      expect(
        jsNumberFormatLocale({'length': 1, '00': 'en_US', '0': 'fr'}),
        'fr',
      );
      expect(jsNumberFormatLocale(<String, Object?>{'0': 'de'}), 'en_US');
    });

    test('gives the current intl locale for undefined and other values', () {
      // V8 gives its default locale, en-US.
      expect(jsNumberFormatLocale(undefined), 'en_US');
      expect(jsNumberFormatLocale(5), 'en_US');
      expect(jsNumberFormatLocale(true), 'en_US');
    });

    test('falls back to the current locale for a tag without data', () {
      // V8 falls back to its default locale, en-US.
      expect(jsNumberFormatLocale('xx-YY'), 'en_US');
      expect(jsNumberFormatLocale('zz'), 'en_US');
    });
  });

  // `new Intl.NumberFormat(locale)` in the reference engine throws for
  // these locales. Thus a chart with such an `options.locale` throws in
  // `new Chart(...)`: formatNumber runs when the chart makes its tick
  // labels. A throw is protected behavior (Chart.js ADR 0009).
  group('jsNumberFormatLocale throws as V8', () {
    test('a TypeError for null and for a primitive item of a list', () {
      // V8: "Cannot convert undefined or null to object" for null, and
      // "Language ID should be string or object." for the items.
      for (final locale in <Object?>[
        null,
        [null],
        [undefined],
        [true],
        [5],
        ['de', 5],
        {'length': 1, '0': 5},
      ]) {
        expect(
          () => jsNumberFormatLocale(locale),
          throwsA(isA<TypeError>()),
          reason: '$locale',
        );
      }
    });

    test('an ArgumentError for a tag that is not valid', () {
      // V8 throws a RangeError, "Incorrect locale information provided".
      for (final tag in _invalidTags) {
        expect(
          () => jsNumberFormatLocale(tag),
          throwsArgumentError,
          reason: tag,
        );
      }
      // Also in a list, after a tag with data, and in an object. ToString
      // of an object gives '[object Object]' and 'de,fr'.
      for (final locale in <Object?>[
        ['en_US'],
        ['de', 'en_US'],
        [<String, Object?>{}],
        [
          ['de', 'fr'],
        ],
        {'length': '1', '0': 'en_US'},
      ]) {
        expect(
          () => jsNumberFormatLocale(locale),
          throwsArgumentError,
          reason: '$locale',
        );
      }
    });

    test('nothing for a valid tag', () {
      // V8 accepts each of these tags.
      for (final tag in _validTags) {
        expect(() => jsNumberFormatLocale(tag), returnsNormally, reason: tag);
      }
    });

    test('in jsNumberFormat', () {
      expect(() => jsNumberFormat('en_US'), throwsArgumentError);
      expect(() => jsNumberFormat(null), throwsA(isA<TypeError>()));
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
      // The exponent and the rounding of the shortest decimal digits.
      expect(
        _format(1000000000000000, undefined, digits('scientific', 0)),
        '1E15',
      );
      expect(_format(1234.5, undefined, {'notation': 'scientific'}), '1.235E3');
      expect(_format(0, undefined, {'notation': 'scientific'}), '0E0');
      // Negative zero, spelled out.
      // ignore: prefer_int_literals
      expect(_format(-0.0, undefined, {'notation': 'scientific'}), '-0E0');
      // The decimal pattern and the exponent symbols of the locale.
      expect(_format(-1.5e-7, 'hi', {'notation': 'scientific'}), '-1.5E-7');
      expect(
        _format(-1.5e-7, 'sv', {'notation': 'scientific'}),
        '\u{2212}1,5\u{D7}10^\u{2212}7',
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

    test('for NaN and the infinities in each style', () {
      final percent = {'style': 'percent'};
      expect(_format(double.nan, undefined, percent), 'NaN%');
      expect(_format(double.infinity, undefined, percent), '\u{221E}%');
      expect(
        _format(double.negativeInfinity, 'de-DE', percent),
        '-\u{221E}\u{A0}%',
      );
      final euro = {'style': 'currency', 'currency': 'EUR'};
      expect(_format(double.nan, undefined, euro), '\u{20AC}NaN');
      expect(
        _format(double.negativeInfinity, undefined, euro),
        '-\u{20AC}\u{221E}',
      );
      expect(_format(double.nan, 'de-DE', euro), 'NaN\u{A0}\u{20AC}');
      expect(_format(double.nan, 'tr', percent), '%NaN');
    });
  });

  // tool/reference/intl_reference.mjs writes these V8 strings in the value
  // ranges of the guards. intl gives other strings for many of them.
  group('V8 reference data', () {
    test('is from the reference engine', () {
      expect(intlReferenceNode, 'v24.12.0');
      expect(intlReferenceArch, 'x64');
      expect(intlReferenceIcu, '77.1');
    });

    for (final (section, count) in [
      ('large', 2051),
      ('nonfinite', 96),
      ('scientific', 2985),
      ('compact', 418),
      ('fraction', 620),
    ]) {
      test('gives the V8 string for each $section case', () {
        final cases = _reference(section);
        expect(cases, hasLength(count));
        final failures = <String>[];
        for (final (locale, options, value, expected) in cases) {
          final actual = jsNumberFormat(locale, options).format(value);
          if (actual != expected) {
            failures.add('$locale $options $value: $actual, V8 $expected');
          }
        }
        expect(failures, isEmpty, reason: failures.take(10).join('\n'));
      });
    }
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

    test('writes more than 15 fraction digits below 2^53', () {
      Map<String, Object?> digits(int n, [Map<String, Object?>? more]) => {
        ...?more,
        'minimumFractionDigits': n,
        'maximumFractionDigits': n,
      };
      // V8: the same strings. intl gets at most 15 fraction digits (13 for
      // percent): before the fix, it gave '9.500000000000000',
      // '0.100000000000000', '25.6000000000000%' and '0.000000000000000'.
      expect(_format(9.5, undefined, digits(19)), '9.5${'0' * 18}');
      expect(_format(0.1, undefined, digits(20)), '0.1${'0' * 19}');
      expect(
        _format(0.256, undefined, digits(20, {'style': 'percent'})),
        '25.6${'0' * 19}%',
      );
      expect(
        _format(1.2345678e-17, undefined, digits(17)),
        '0.00000000000000001',
      );
      // The shortest decimal digits round half away from zero. The digits
      // after the last fraction digit round to 0 or to 1 in the last place.
      expect(
        _format(5e-21, undefined, digits(20)),
        '0.${'0' * 19}1',
      );
      expect(_format(-4.9999e-21, undefined, digits(20)), '-0.${'0' * 20}');
      expect(
        _format(999999999999999.9, 'de-DE', {'maximumFractionDigits': 16}),
        '999.999.999.999.999,9',
      );
      // formatters.numeric for the two ticks of the data 0.3 and 0.1 + 0.2
      // (core.ticks.js:56-57). intl gave '0.300000000000000' for both.
      expect(_format(0.3, 'en-US', digits(17)), '0.30000000000000000');
      expect(
        _format(0.1 + 0.2, 'en-US', digits(17)),
        '0.30000000000000004',
      );
      // V8: the same strings. The guards of scientific notation and of
      // numbers from 2^53 write the digits without intl.
      expect(
        _format(2e-19, undefined, digits(19, {'notation': 'scientific'})),
        '2.${'0' * 19}E-19',
      );
      expect(
        _format(1e21, undefined, digits(20)),
        '1,000,000,000,000,000,000,000.${'0' * 20}',
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
      // V8: the same strings. intl divides by pow(10.0, exponent), which is
      // subnormal or 0 there, and throws.
      expect(_format(5e-324, undefined, options), '5E-324');
      expect(_format(-5e-324, undefined, options), '-5E-324');
      expect(_format(1.5e-320, undefined, options), '1.5E-320');
      expect(_format(2.3e-308, undefined, options), '2.3E-308');
      expect(
        _format(1e-320, undefined, {
          'notation': 'scientific',
          'minimumFractionDigits': 2,
        }),
        '1.00E-320',
      );
    });

    test('carries the rounding of the mantissa into the exponent', () {
      // V8: the same strings. intl gives '10E14', '10E14', '10E20',
      // '10E-7', '10.0E14' and '9.999E-13': its exponent comes from a
      // logarithm, and a mantissa that rounds up to 10 keeps it.
      final none = {
        'notation': 'scientific',
        'minimumFractionDigits': 0,
        'maximumFractionDigits': 0,
      };
      expect(_format(1000000000000000, undefined, none), '1E15');
      expect(_format(950000000000000, undefined, none), '1E15');
      expect(_format(9.99e20, undefined, none), '1E21');
      expect(_format(9.5e-7, undefined, none), '1E-6');
      expect(
        _format(996000000000000, undefined, {
          'notation': 'scientific',
          'minimumFractionDigits': 1,
          'maximumFractionDigits': 1,
        }),
        '1.0E15',
      );
      expect(
        _format(9.9995e-13, undefined, {'notation': 'scientific'}),
        '1E-12',
      );
    });

    test('writes the shortest digits of a number from 2^53', () {
      // V8: the same strings. On the VM and dart2wasm, intl overflows a
      // 64-bit int from 2^63 and gives '922,337,203,685,477,580,700',
      // '92,233,720,368,547,758,070' and '8,400,000,000,000,000,000'. Below
      // 2^63, it writes the binary value: '1,152,921,504,606,846,976'.
      // dart2js gives 16 digits and zeros: '18,446,744,073,709,550,000'.
      expect(_format(1e21), '1,000,000,000,000,000,000,000');
      expect(_format(1e20), '100,000,000,000,000,000,000');
      expect(
        _format(1e19, undefined, {'maximumSignificantDigits': 3}),
        '10,000,000,000,000,000,000',
      );
      expect(_format(1152921504606846976), '1,152,921,504,606,847,000');
      expect(_format(18446744073709551616), '18,446,744,073,709,552,000');
      expect(
        _format(-1e21, undefined, {'style': 'percent'}),
        '-100,000,000,000,000,000,000,000%',
      );
      expect(
        _format(1e21, 'en-IN', {'style': 'currency', 'currency': 'USD'}),
        r'$1,00,00,00,00,00,00,00,00,00,000.00',
      );
    });

    test('groups a number from 2^53 as intl groups 2^53', () {
      // At 2^53, intl writes the V8 digits on every platform. The guard
      // takes the groups from the pattern of the style.
      for (final locale in [
        'en-US', 'en-IN', 'de-DE', 'de-CH', 'fr', 'es', 'ar-EG', 'fa', 'hi',
        'bn', 'ja', 'sv', 'tr', 'pt-BR', 'ru', 'he', 'my', 'ne', //
      ]) {
        for (final options in <Map<String, Object?>>[
          {},
          {'style': 'percent'},
          {'style': 'currency', 'currency': 'EUR'},
          {'useGrouping': false},
          {'minimumFractionDigits': 2},
          {'maximumSignificantDigits': 3},
          {'minimumSignificantDigits': 20},
          {'minimumIntegerDigits': 21},
        ]) {
          final format = jsNumberFormat(locale, options);
          for (final value in [9007199254740992.0, -9007199254740992.0]) {
            expect(
              format.format(value),
              format.intl.format(value),
              reason: '$locale $options $value',
            );
          }
        }
      }
    });

    test('writes the digits of a large compact number', () {
      final compact = {'notation': 'compact'};
      // V8: '10,000,000,000,000,000,000,000,000T' and
      // '-100,000,000,000,000\u{4EAC}'. intl does not group compact numbers.
      // On the VM and dart2wasm, intl overflows from 2^63 units:
      // '9223372036854775807000000T'.
      expect(_format(1e37, undefined, compact), '1${'0' * 25}T');
      expect(_format(-1e30, 'ja', compact), '-100000000000000\u{4EAC}');
      // From 2^53 units, the guard writes the shortest digits. Below, intl
      // writes them.
      expect(_format(9.0072e27, undefined, compact), '9007200000000000T');
      expect(
        _format(9.0071992547409e27, undefined, compact),
        '9007199254740900T',
      );
      // On dart2js, intl throws for these values.
      expect(
        _format(1.7976931348623157e308, 'de-DE', compact),
        startsWith('17976931348623157${'0' * 30}'),
      );
      expect(
        _format(-1.7976931348623157e308, 'ja', compact),
        startsWith('-17976931348623157${'0' * 30}'),
      );
    });

    test('applies the digit options to a large compact number', () {
      // V8: '12,300,000,000,000,000,000,000,000T',
      // '-100,000,000,000,000\u{4EAC}', '000,009,000,000,000,000,000T' and
      // '10,000,000,000,000,000,000,000,000T'. intl does not group compact
      // numbers. Before the fix, the guard ignored the significant digits
      // ('12345600000000000000000000T'), counted the zeros of the minimum
      // integer digits in the unit ('-10000000000000000\u{4EAC}', 100 times
      // the value), and kept the fraction zeros of 1e18 ('.00000' on the VM
      // and dart2wasm, '.00000000000000' on dart2js).
      expect(
        _format(1.23456e37, undefined, {
          'notation': 'compact',
          'maximumSignificantDigits': 3,
        }),
        '12300000000000000000000000T',
      );
      expect(
        _format(-1e30, 'ja', {
          'notation': 'compact',
          'minimumIntegerDigits': 5,
        }),
        '-100000000000000\u{4EAC}',
      );
      expect(
        _format(9.0072e27, undefined, {
          'notation': 'compact',
          'minimumIntegerDigits': 21,
          'maximumSignificantDigits': 1,
        }),
        '000009000000000000000T',
      );
      expect(
        _format(1e37, undefined, {
          'notation': 'compact',
          'minimumSignificantDigits': 21,
        }),
        isNot(contains('.')),
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

  // Chart.js ADR 0026 and differences.md row adapt-intl-number-format. A
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
      // V8: '5E1%', '50%', '$2E16' and '$1.2K'. The currency style keeps
      // its affixes for NaN, as V8 does.
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
      expect(_format(double.nan, undefined, compactCurrency), r'$NaN');
    });

    test('V8 writes a mantissa below 1 just below a power of ten', () {
      // V8: '0.1000000000000000E-11' and '0.09999999999999999000E1'. ICU
      // gives these strings from 17 significant digits for a value whose
      // shortest digits start with fifteen 9s.
      Map<String, Object?> digits(int n) => {
        'notation': 'scientific',
        'minimumFractionDigits': n,
        'maximumFractionDigits': n,
      };
      expect(
        _format(9.999999999999998e-13, undefined, digits(16)),
        '9.9999999999999980E-13',
      );
      expect(
        _format(0.9999999999999999, undefined, digits(20)),
        '9.99999999999999900000E-1',
      );
    });

    test('intl writes the binary value of a double below 2^53', () {
      // V8: '999,999,999,999,999.9' and '1,000,000,000,000,000.1', the
      // shortest decimal digits.
      expect(_format(999999999999999.9), '999,999,999,999,999.875');
      expect(_format(1000000000000000.1), '1,000,000,000,000,000.125');
    });

    test('intl compact notation can select a smaller unit than V8', () {
      // V8: '9,007,200,000,000,000.00000T' and '1,000,000.00000000000000T'.
      // On the VM and dart2wasm, intl overflows a 64-bit int when it selects
      // the unit for many significant or fraction digits. Then it selects a
      // smaller unit, and the count of units has more digits. The guard of
      // compact notation keeps that unit.
      final options = {'notation': 'compact', 'minimumSignificantDigits': 21};
      expect(
        _format(9.0072e27, undefined, options),
        _dart2js ? '9007200000000000.00000T' : '9007200000000000000000000K',
      );
      expect(
        _format(1000000000000000000, undefined, options),
        _dart2js ? '1000000.00000000000000T' : '1000000000000000.00000K',
      );
    });

    test('intl compact notation does not group the digits', () {
      // V8: '1,000,000T'.
      expect(
        _format(1000000000000000000, undefined, {'notation': 'compact'}),
        '1000000T',
      );
    });
  });
}
