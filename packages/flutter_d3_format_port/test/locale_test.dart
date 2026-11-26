// Ported from d3-format v3.1.2 test/locale-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_format_port/d3_format.dart';
import 'package:test/test.dart';

FormatLocale _locale(String tag) => formatLocale(formatLocales[tag]!);

void main() {
  test(
    'formatLocale({decimal: decimal}) observes the specified decimal point',
    () {
      expect(
        formatLocale(const FormatLocaleDefinition(decimal: '|'))
            .format('06.2f')(2),
        '002|00',
      );
      expect(
        formatLocale(const FormatLocaleDefinition(decimal: '/'))
            .format('06.2f')(2),
        '002/00',
      );
    },
  );

  test('formatLocale({currency: [prefix, suffix]}) observes the specified '
      'currency prefix and suffix', () {
    expect(
      formatLocale(const FormatLocaleDefinition(currency: ('฿', '')))
          .format(r'$06.2f')(2),
      '฿02.00',
    );
    expect(
      formatLocale(const FormatLocaleDefinition(currency: ('', '฿')))
          .format(r'$06.2f')(2),
      '02.00฿',
    );
  });

  test('formatLocale({currency: [prefix, suffix]}) places the currency suffix '
      'after the SI suffix', () {
    expect(
      formatLocale(
        const FormatLocaleDefinition(decimal: ',', currency: ('', ' €')),
      ).format(r'$.3s')(1.2e9),
      '1,20G €',
    );
  });

  test('formatLocale({grouping: undefined}) does not perform any grouping', () {
    expect(
      formatLocale(const FormatLocaleDefinition()).format('012,.2f')(2),
      '000000002.00',
    );
  });

  test(
    'formatLocale({grouping: [sizes…]}) observes the specified group sizes',
    () {
      expect(
        formatLocale(
          const FormatLocaleDefinition(grouping: [3], thousands: ','),
        ).format('012,.2f')(2),
        '0,000,002.00',
      );
      expect(
        formatLocale(
          const FormatLocaleDefinition(grouping: [2], thousands: ','),
        ).format('012,.2f')(2),
        '0,00,00,02.00',
      );
      expect(
        formatLocale(
          const FormatLocaleDefinition(grouping: [2, 3], thousands: ','),
        ).format('012,.2f')(2),
        '00,000,02.00',
      );
      expect(
        formatLocale(
          const FormatLocaleDefinition(
            grouping: [3, 2, 2, 2, 2, 2, 2],
            thousands: ',',
          ),
        ).format(',d')(1e12),
        '10,00,00,00,00,000',
      );
    },
  );

  test(
    'formatLocale(…) can format numbers using the Indian numbering system.',
    () {
      final f = _locale('en-IN').format(',');
      expect(f(10), '10');
      expect(f(100), '100');
      expect(f(1000), '1,000');
      expect(f(10000), '10,000');
      expect(f(100000), '1,00,000');
      expect(f(1000000), '10,00,000');
      expect(f(10000000), '1,00,00,000');
      expect(f(10000000.4543), '1,00,00,000.4543');
      expect(f(1000.321), '1,000.321');
      expect(f(10.5), '10.5');
      expect(f(-10), '−10');
      expect(f(-100), '−100');
      expect(f(-1000), '−1,000');
      expect(f(-10000), '−10,000');
      expect(f(-100000), '−1,00,000');
      expect(f(-1000000), '−10,00,000');
      expect(f(-10000000), '−1,00,00,000');
      expect(f(-10000000.4543), '−1,00,00,000.4543');
      expect(f(-1000.321), '−1,000.321');
      expect(f(-10.5), '−10.5');
    },
  );

  test('formatLocale({thousands: separator}) observes the specified group '
      'separator', () {
    expect(
      formatLocale(const FormatLocaleDefinition(grouping: [3], thousands: ' '))
          .format('012,.2f')(2),
      '0 000 002.00',
    );
    expect(
      formatLocale(const FormatLocaleDefinition(grouping: [3], thousands: '/'))
          .format('012,.2f')(2),
      '0/000/002.00',
    );
  });

  test(
    'formatLocale({percent: percent}) observes the specified percent sign',
    () {
      expect(
        formatLocale(const FormatLocaleDefinition(percent: '!'))
            .format('06.2%')(2),
        '200.00!',
      );
      expect(
        formatLocale(const FormatLocaleDefinition(percent: '﹪'))
            .format('06.2%')(2),
        '200.00﹪',
      );
    },
  );

  test('formatLocale({minus: minus}) observes the specified minus sign', () {
    expect(
      formatLocale(const FormatLocaleDefinition(minus: '-'))
          .format('06.2f')(-2),
      '-02.00',
    );
    expect(
      // Upstream test explicitly passes the default minus sign.
      // ignore: avoid_redundant_argument_values
      formatLocale(const FormatLocaleDefinition(minus: '−'))
          .format('06.2f')(-2),
      '−02.00',
    );
    expect(
      formatLocale(const FormatLocaleDefinition(minus: '➖'))
          .format('06.2f')(-2),
      '➖02.00',
    );
    expect(
      formatLocale(const FormatLocaleDefinition()).format('06.2f')(-2),
      '−02.00',
    );
  });

  test('formatLocale({nan: nan}) observes the specified not-a-number '
      'representation', () {
    // DIVERGES(d3-format): adapt-format-typed-api, double.nan for undefined
    expect(
      formatLocale(const FormatLocaleDefinition(nan: 'N/A'))
          .format('6.2f')(double.nan),
      '   N/A',
    );
    expect(
      formatLocale(const FormatLocaleDefinition(nan: '-'))
          .format('<6.2g')(double.nan),
      '-     ',
    );
    expect(
      formatLocale(const FormatLocaleDefinition()).format(' 6.2f')(double.nan),
      '   NaN',
    );
  });

  test('locale data is valid', () {
    expect(formatLocales, hasLength(59));
    for (final entry in formatLocales.entries) {
      final def = entry.value;
      expect(def.currency, isNotNull, reason: entry.key);
      expect(def.decimal, isNotEmpty, reason: entry.key);
      expect(def.grouping, isNotNull, reason: entry.key);
      expect(def.thousands, isNotNull, reason: entry.key);
      formatLocale(def);
    }
  });
}
