// Original code, not ported from Chart.js: helpers.intl cases with no spec.
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.intl.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:test/test.dart';

// Upstream has no spec for helpers.intl.ts (AGENTS.md rule 3). The expected
// strings come from Node.js v24.12.0 (V8 13.6, ICU 77.1) on x64, with
// LANG=en_US.UTF-8. test/port/js/js_intl_test.dart tests the option mapping
// and pins the known differences from V8 (Chart.js ADR 0026).

/// The options of `formatters.numeric` (core.ticks.js:56-57) with [digits]
/// fraction digits, or `ticks.format` (undefined by default) for `null`.
Map<String, Object?>? _tickOptions(int? digits) => digits == null
    ? null
    : {
        'notation': undefined,
        'minimumFractionDigits': digits,
        'maximumFractionDigits': digits,
      };

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
const List<(String, String, List<(double, int?, String)>)> _specCases = [
  ('core.ticks.tests.js:101-103', 'en', [(1, 0, '1'), (1, 2, '1.00')]),
  ('scale.linear.tests.js:354', 'en-US', [(7, null, '7')]),
  ('scale.linear.tests.js:394', 'de-DE', [(7.07, null, '7,07')]),
  (
    'scale.linear.tests.js:653-654',
    'en-US',
    [
      (-1010, 0, '-1,010'),
      (-500, 0, '-500'),
      (500, 0, '500'),
      (1010, 0, '1,010'),
    ],
  ),
  (
    'scale.linear.tests.js:684',
    'en-US',
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
    'en-US',
    [(2.5, 1, '2.5'), (5, 0, '5'), (7.5, 1, '7.5'), (10, 0, '10')],
  ),
  ('scale.linear.tests.js:786', 'en-US', [(1, 0, '1'), (2, 0, '2')]),
  ('scale.linear.tests.js:814', 'en-US', [(0.01, 2, '0.01')]),
  (
    'scale.linear.tests.js:840',
    'en-US',
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
    'en-US',
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
    'en-US',
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
    'en-US',
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
    'en-US',
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
    'en-US',
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
    'en-US',
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
    'en-US',
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
    'en-US',
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
    'en-US',
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
  ('scale.logarithmic.tests.js:719', 'en-US', [(150, null, '150')]),
  ('scale.logarithmic.tests.js:752', 'de-DE', [(10.25, null, '10,25')]),
  (
    'scale.radialLinear.tests.js:206',
    'en-US',
    [
      (-1010, 0, '-1,010'),
      (-500, 0, '-500'),
      (500, 0, '500'),
      (1010, 0, '1,010'),
    ],
  ),
  (
    'scale.radialLinear.tests.js:227',
    'en-US',
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
    'en-US',
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
    'en-US',
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
    'en-US',
    [
      (0.3, 1, '0.3'),
      (0.8, 1, '0.8'),
      (1.3, 1, '1.3'),
      (1.8, 1, '1.8'),
      (2.3, 1, '2.3'),
      (2.8, 1, '2.8'),
    ],
  ),
  ('scale.radialLinear.tests.js:436', 'en-US', [(5, null, '5')]),
];

void main() {
  group('formatNumber', () {
    test('gives the V8 strings of the spec labels', () {
      // Each recorded call. package:intl gives the V8 string for all of them
      // (Chart.js ADR 0026).
      for (final (spec, locale, calls) in _specCases) {
        for (final (value, digits, expected) in calls) {
          expect(
            formatNumber(value, locale, _tickOptions(digits)),
            expected,
            reason: '$spec: $value with $digits fraction digits',
          );
        }
      }
    });

    test('uses the current intl locale for undefined', () {
      // controller.doughnut.js:324 and controller.polarArea.js:101 pass
      // chart.options.locale, undefined by default. The V8 strings.
      expect(formatNumber(1234.5678, undefined), '1,234.568');
      expect(formatNumber(double.nan, undefined), 'NaN');
      expect(formatNumber(double.negativeInfinity, undefined), '-\u{221E}');
    });

    test('throws for null and for a tag that is not valid, as V8', () {
      // `new Intl.NumberFormat(locale)` in V8 throws a TypeError for null,
      // and a RangeError for 'en_US' and 'de_DE'. The cache does not keep
      // a throw: the second call throws again.
      for (var i = 0; i < 2; i++) {
        expect(
          () => formatNumber(1234.5, null),
          throwsA(isA<TypeError>()),
        );
        expect(() => formatNumber(1234.5, 'en_US'), throwsArgumentError);
        expect(
          () => formatNumber(1234.5, 'de_DE', {'maximumFractionDigits': 1}),
          throwsArgumentError,
        );
      }
      expect(formatNumber(1234.5, 'en-US'), '1,234.5');
    });

    test('gives the V8 strings at the guards of the adapter', () {
      // getLabelForValue (scale.linearbase.js:311) with the default
      // ticks.format. intl gives '922,337,203,685,477,580,700' on the VM.
      expect(formatNumber(1e21, 'en-US'), '1,000,000,000,000,000,000,000');
      expect(formatNumber(-1e21, 'en-US'), '-1,000,000,000,000,000,000,000');
      // formatters.numeric for ticks above 1e15 with a spacing of 1e15 or
      // more: scientific notation and no fraction digits. intl gives
      // '10E14' and '10E15'.
      final scientific = {...?_tickOptions(0), 'notation': 'scientific'};
      expect(formatNumber(1000000000000000, 'en-US', scientific), '1E15');
      expect(formatNumber(9500000000000000, 'en-US', scientific), '1E16');
      // A ticks.format of a user. intl gives 'NaN' and '\u{221E}'.
      final percent = {'style': 'percent'};
      expect(formatNumber(double.nan, 'en-US', percent), 'NaN%');
      expect(
        formatNumber(double.infinity, 'de-DE', percent),
        '\u{221E}\u{A0}%',
      );
    });

    test('caches one formatter for each intl locale and options', () {
      expect(
        formatNumber(1234.5678, 'en-US', {'maximumFractionDigits': 2}),
        '1,234.57',
      );
      // 2 and 2.0, or an undefined key, can give another key. The
      // formatters give the same string.
      expect(
        formatNumber(1234.5678, 'en-US', {
          'maximumFractionDigits': 2.0,
          'notation': undefined,
        }),
        '1,234.57',
      );
      expect(formatNumber(1234.5678, 'en-US'), '1,234.568');
      expect(formatNumber(1234.5678, 'en-US', {}), '1,234.568');
      expect(
        formatNumber(1e-7, undefined, {'notation': 'scientific'}),
        '1E-7',
      );
      expect(formatNumber(1e-7, undefined), '0');
      expect(formatNumber(1234.5, 'de-DE'), '1.234,5');
      expect(formatNumber(1234.5, 'en'), '1,234.5');
    });

    test('maps a list locale as V8 does, so its key holds the same format', () {
      // The key of ['de'] and of 'de-DE' is 'de', as for 'de'. V8 gives
      // '1.234,5' for all three.
      expect(formatNumber(1234.5, ['de']), '1.234,5');
      expect(formatNumber(1234.5, 'de'), '1.234,5');
      expect(formatNumber(1234.5, 'de-DE'), '1.234,5');
    });

    test('keys a resolver on its resolved options', () {
      // scale.linearbase.js:311 passes the resolver of ticks.format. Its
      // toString lists only its cache. V8: '1,234.57' and '1,235'.
      final two = createResolver([
        <String, Object?>{'maximumFractionDigits': 2},
      ]);
      final zero = createResolver([
        <String, Object?>{'maximumFractionDigits': 0},
      ]);
      // The options parameter of formatNumber takes a resolver, a typed
      // object with a face (Chart.js ADR 0054 §5): its entries are the keys
      // of its ownKeys trap with the values of its get trap.
      expect(formatNumber(1234.5678, 'en-US', two), '1,234.57');
      expect(formatNumber(1234.5678, 'en-US', zero), '1,235');
    });

    test('gives a String value and another value two keys', () {
      // V8: '1,234.5' and '1234.5'. The String 'false' is truthy.
      expect(formatNumber(1234.5, 'en', {'useGrouping': 'false'}), '1,234.5');
      expect(formatNumber(1234.5, 'en', {'useGrouping': false}), '1234.5');
      // V8: '1,235', then a RangeError.
      expect(
        formatNumber(1234.5, 'en', {
          'maximumFractionDigits': [0],
        }),
        '1,235',
      );
      expect(
        () => formatNumber(1234.5, 'en', {'maximumFractionDigits': '[0]'}),
        throwsArgumentError,
      );
    });

    test('throws for a digit option out of range, and caches nothing', () {
      // V8 throws a RangeError.
      for (var i = 0; i < 2; i++) {
        expect(
          () => formatNumber(1, undefined, {'maximumFractionDigits': 101}),
          throwsArgumentError,
        );
      }
    });
  });
}
