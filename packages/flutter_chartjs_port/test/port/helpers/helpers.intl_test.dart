// Original code, not ported from Chart.js: helpers.intl cases with no spec.
import 'dart:ui' show Locale;

import 'package:flutter_chartjs_port/src/helpers/helpers.intl.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:intl/intl.dart';
import 'package:test/test.dart';

// Upstream has no spec for helpers.intl.ts (AGENTS.md rule 3). The port
// formats with package:intl as it is (Chart.js ADR 0119). The strings of the
// spec labels come from Node.js v24.12.0 (V8 13.6, ICU 77.1) on x64, with
// LANG=en_US.UTF-8: package:intl gives the same strings for them.

/// Whether asserts run: `dart test` and `flutter test` enable them on each
/// platform.
bool get _asserts {
  var enabled = false;
  assert(enabled = true, 'asserts run');
  return enabled;
}

/// The `formatNumber` calls behind the labels that the upstream specs
/// assert: the spec line, the locale and each (value, fraction digits,
/// V8 string).
///
/// x64 Node.js recorded the calls. It ran the upstream `formatters.numeric`
/// and `formatters.logarithmic` on tick lists with the values of the
/// asserted labels, and `formatNumber` for `getLabelForValue`. The tick
/// lists of `scale.linear.tests.js:653-654` are the labels of
/// `scale.radialLinear.tests.js:206`: the spec asserts only the first and
/// the last label. A `0` tick is `'0'` in `formatters.numeric` and does not
/// reach `formatNumber`.
const List<(String, Locale, List<(double, int?, String)>)> _specCases = [
  ('core.ticks.tests.js:101-103', Locale('en'), [(1, 0, '1'), (1, 2, '1.00')]),
  ('scale.linear.tests.js:354', Locale('en', 'US'), [(7, null, '7')]),
  ('scale.linear.tests.js:394', Locale('de', 'DE'), [(7.07, null, '7,07')]),
  (
    'scale.linear.tests.js:653-654',
    Locale('en', 'US'),
    [
      (-1010, 0, '-1,010'),
      (-500, 0, '-500'),
      (500, 0, '500'),
      (1010, 0, '1,010'),
    ],
  ),
  (
    'scale.linear.tests.js:684',
    Locale('en', 'US'),
    [
      (1, 0, '1'),
      (3, 0, '3'),
      (5, 0, '5'),
      (7, 0, '7'),
      (9, 0, '9'),
      (11, 0, '11'),
    ],
  ),
  (
    'scale.linear.tests.js:757',
    Locale('en', 'US'),
    [(2.5, 1, '2.5'), (5, 0, '5'), (7.5, 1, '7.5'), (10, 0, '10')],
  ),
  (
    'scale.linear.tests.js:786',
    Locale('en', 'US'),
    [(1, 0, '1'), (2, 0, '2')],
  ),
  (
    'scale.linear.tests.js:814',
    Locale('en', 'US'),
    [(0.01, 2, '0.01')],
  ),
  (
    'scale.linear.tests.js:840',
    Locale('en', 'US'),
    [
      (20, 0, '20'),
      (25, 0, '25'),
      (30, 0, '30'),
      (35, 0, '35'),
      (40, 0, '40'),
      (45, 0, '45'),
      (50, 0, '50'),
    ],
  ),
  (
    'scale.linear.tests.js:844',
    Locale('en', 'US'),
    [
      (5, 0, '5'),
      (10, 0, '10'),
      (15, 0, '15'),
      (20, 0, '20'),
      (25, 0, '25'),
      (30, 0, '30'),
      (35, 0, '35'),
      (40, 0, '40'),
      (45, 0, '45'),
      (50, 0, '50'),
    ],
  ),
  (
    'scale.linear.tests.js:848',
    Locale('en', 'US'),
    [
      (-50, 0, '-50'),
      (-45, 0, '-45'),
      (-40, 0, '-40'),
      (-35, 0, '-35'),
      (-30, 0, '-30'),
      (-25, 0, '-25'),
      (-20, 0, '-20'),
      (-15, 0, '-15'),
      (-10, 0, '-10'),
      (-5, 0, '-5'),
    ],
  ),
  (
    'scale.linear.tests.js:852',
    Locale('en', 'US'),
    [
      (-50, 0, '-50'),
      (-45, 0, '-45'),
      (-40, 0, '-40'),
      (-35, 0, '-35'),
      (-30, 0, '-30'),
      (-25, 0, '-25'),
      (-20, 0, '-20'),
    ],
  ),
  (
    'scale.linear.tests.js:875',
    Locale('en', 'US'),
    [
      (80, 0, '80'),
      (70, 0, '70'),
      (60, 0, '60'),
      (50, 0, '50'),
      (40, 0, '40'),
      (30, 0, '30'),
      (20, 0, '20'),
      (10, 0, '10'),
    ],
  ),
  (
    'scale.linear.tests.js:898',
    Locale('en', 'US'),
    [
      (0.01, 2, '0.01'),
      (0.02, 2, '0.02'),
      (0.03, 2, '0.03'),
      (0.04, 2, '0.04'),
      (0.05, 2, '0.05'),
      (0.06, 2, '0.06'),
    ],
  ),
  (
    'scale.linear.tests.js:919',
    Locale('en', 'US'),
    [
      (0.5, 1, '0.5'),
      (1, 1, '1.0'),
      (1.5, 1, '1.5'),
      (2, 1, '2.0'),
      (2.5, 1, '2.5'),
    ],
  ),
  (
    'scale.linear.tests.js:929',
    Locale('en', 'US'),
    [
      (0.5, 1, '0.5'),
      (0.6, 1, '0.6'),
      (0.7, 1, '0.7'),
      (0.8, 1, '0.8'),
      (0.9, 1, '0.9'),
      (1, 1, '1.0'),
      (1.1, 1, '1.1'),
      (1.2, 1, '1.2'),
      (1.3, 1, '1.3'),
      (1.4, 1, '1.4'),
      (1.5, 1, '1.5'),
      (1.6, 1, '1.6'),
      (1.7, 1, '1.7'),
      (1.8, 1, '1.8'),
      (1.9, 1, '1.9'),
      (2, 1, '2.0'),
      (2.1, 1, '2.1'),
      (2.2, 1, '2.2'),
      (2.3, 1, '2.3'),
      (2.4, 1, '2.4'),
      (2.5, 1, '2.5'),
    ],
  ),
  (
    'scale.linear.tests.js:945',
    Locale('en', 'US'),
    [
      (0.3, 1, '0.3'),
      (0.8, 1, '0.8'),
      (1.3, 1, '1.3'),
      (1.8, 1, '1.8'),
      (2.3, 1, '2.3'),
      (2.8, 1, '2.8'),
    ],
  ),
  (
    'scale.logarithmic.tests.js:660',
    Locale('en', 'US'),
    [
      (1, 0, '1'),
      (2, 0, '2'),
      (3, 0, '3'),
      (5, 0, '5'),
      (10, 0, '10'),
      (15, 0, '15'),
      (20, 0, '20'),
      (30, 0, '30'),
      (50, 0, '50'),
      (60, 0, '60'),
      (70, 0, '70'),
      (80, 0, '80'),
    ],
  ),
  (
    'scale.logarithmic.tests.js:719',
    Locale('en', 'US'),
    [(150, null, '150')],
  ),
  (
    'scale.logarithmic.tests.js:752',
    Locale('de', 'DE'),
    [(10.25, null, '10,25')],
  ),
  (
    'scale.radialLinear.tests.js:206',
    Locale('en', 'US'),
    [
      (-1010, 0, '-1,010'),
      (-500, 0, '-500'),
      (500, 0, '500'),
      (1010, 0, '1,010'),
    ],
  ),
  (
    'scale.radialLinear.tests.js:227',
    Locale('en', 'US'),
    [
      (20, 0, '20'),
      (25, 0, '25'),
      (30, 0, '30'),
      (35, 0, '35'),
      (40, 0, '40'),
      (45, 0, '45'),
      (50, 0, '50'),
    ],
  ),
  (
    'scale.radialLinear.tests.js:263',
    Locale('en', 'US'),
    [
      (80, 0, '80'),
      (70, 0, '70'),
      (60, 0, '60'),
      (50, 0, '50'),
      (40, 0, '40'),
      (30, 0, '30'),
      (20, 0, '20'),
      (10, 0, '10'),
    ],
  ),
  (
    'scale.radialLinear.tests.js:288',
    Locale('en', 'US'),
    [
      (0.5, 1, '0.5'),
      (1, 1, '1.0'),
      (1.5, 1, '1.5'),
      (2, 1, '2.0'),
      (2.5, 1, '2.5'),
    ],
  ),
  (
    'scale.radialLinear.tests.js:304',
    Locale('en', 'US'),
    [
      (0.3, 1, '0.3'),
      (0.8, 1, '0.8'),
      (1.3, 1, '1.3'),
      (1.8, 1, '1.8'),
      (2.3, 1, '2.3'),
      (2.8, 1, '2.8'),
    ],
  ),
  (
    'scale.radialLinear.tests.js:436',
    Locale('en', 'US'),
    [(5, null, '5')],
  ),
];

void main() {
  group('formatNumber', () {
    test('gives the V8 strings of the spec labels', () {
      for (final (spec, locale, calls) in _specCases) {
        for (final (value, digits, expected) in calls) {
          expect(
            digits == null
                ? formatNumber(value, locale)
                : formatNumberDigits(
                    value,
                    locale,
                    scientific: false,
                    fractionDigits: digits,
                  ),
            expected,
            reason: '$spec: $value with $digits fraction digits',
          );
        }
      }
    });

    test('uses the current intl locale without a locale', () {
      // controller.doughnut.js:324 and controller.polarArea.js:101 pass
      // chart.options.locale, absent by default.
      expect(formatNumber(1234.5678, null), '1,234.568');
    });

    test('uses the current intl locale for a locale without intl data', () {
      expect(formatNumber(1234.5678, const Locale('xx', 'YY')), '1,234.568');
    });

    test('a change of Intl.defaultLocale reaches the next call', () {
      final old = Intl.defaultLocale;
      addTearDown(() => Intl.defaultLocale = old);
      expect(formatNumber(1.5, null), '1.5');
      Intl.defaultLocale = 'de';
      expect(formatNumber(1.5, null), '1,5');
      expect(
        formatNumberDigits(1.5, null, scientific: false, fractionDigits: 2),
        '1,50',
      );
    });

    test('a NumberFormat formats the value as it is', () {
      // The tick option format (Chart.js ADR 0119): the locale of the chart
      // does not change it.
      expect(
        formatNumber(
          0.25,
          const Locale('de', 'DE'),
          NumberFormat.percentPattern('en'),
        ),
        '25%',
      );
    });
  });

  group('formatNumberDigits', () {
    test('writes the fraction digits in both notations', () {
      expect(
        formatNumberDigits(
          7,
          const Locale('en', 'US'),
          scientific: false,
          fractionDigits: 2,
        ),
        '7.00',
      );
      expect(
        formatNumberDigits(
          1.5e-5,
          const Locale('en', 'US'),
          scientific: true,
          fractionDigits: 6,
        ),
        '1.500000E-5',
      );
    });
  });

  group('the option values', () {
    test('localeOf gives the Locale, or null when absent', () {
      const locale = Locale('de', 'DE');
      expect(localeOf(locale), same(locale));
      expect(localeOf(undefined), isNull);
      expect(localeOf(null), isNull);
    });

    test('numberFormatOf gives the NumberFormat, or null when absent', () {
      final format = NumberFormat.compact();
      expect(numberFormatOf(format), same(format));
      expect(numberFormatOf(undefined), isNull);
      expect(numberFormatOf(null), isNull);
    });

    test('a language tag or an options object stops a debug build', () {
      if (_asserts) {
        expect(() => localeOf('de-DE'), throwsA(isA<AssertionError>()));
        expect(
          () => numberFormatOf(<String, Object?>{'style': 'percent'}),
          throwsA(isA<AssertionError>()),
        );
      } else {
        expect(localeOf('de-DE'), isNull);
        expect(numberFormatOf(<String, Object?>{}), isNull);
      }
    });
  });
}
