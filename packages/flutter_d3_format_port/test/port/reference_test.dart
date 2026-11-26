// Original code, not ported from d3-format: Node.js reference parity tests.

import 'package:flutter_d3_format_port/d3_format.dart';
import 'package:test/test.dart';

import 'd3_format_reference.dart';

void main() {
  test('format() across 50 specifiers x 23 values matches Node.js', () {
    for (final entry in referenceMatrix.entries) {
      final spec = entry.key;
      final expected = entry.value;
      final f = format(spec);
      expect(expected.length, referenceValues.length);
      for (var i = 0; i < referenceValues.length; ++i) {
        expect(
          f(referenceValues[i]),
          expected[i],
          reason: 'format("$spec")(${referenceValues[i]})',
        );
      }
    }
  });

  test('formatPrefix() matches Node.js across reference scales', () {
    const cases = <(String, double, List<double>)>[
      (',.0s', 1e-6, [0.00042, 0.0042, -0.00042, 0]),
      (',.3s', 1e-3, [0.00042, 0.001, -0.005]),
      (r' $12,.1s', 1e6, [-42e6, 4.2e6, 0, 1.5e7]),
      (r'($~s', 1e3, [1e3, -1e3, 2500, -2500]),
      (',.2s', 1e27, [1e24, 2.5e26]),
      (',.2s', 1e-27, [1e-24, 5e-25]),
    ];
    for (var c = 0; c < cases.length; ++c) {
      final (spec, ref, vals) = cases[c];
      final f = formatPrefix(spec, ref);
      for (var i = 0; i < vals.length; ++i) {
        expect(
          f(vals[i]),
          referencePrefixResults[c][i],
          reason: 'formatPrefix("$spec", $ref)(${vals[i]})',
        );
      }
    }
  });

  test('all 59 built-in locales match Node.js reference outputs', () {
    expect(formatLocales.length, referenceLocales.length);
    for (final entry in referenceLocales.entries) {
      final tag = entry.key;
      final expected = entry.value;
      final loc = formatLocale(formatLocales[tag]!);
      expect(loc.format(r'$,.2f')(1234567.89), expected[0], reason: '$tag #0');
      expect(loc.format(r'$,.2f')(-1234.56), expected[1], reason: '$tag #1');
      expect(loc.format(',.1%')(0.4567), expected[2], reason: '$tag #2');
      expect(loc.format('.3s')(145500000), expected[3], reason: '$tag #3');
    }
  });

  test('precisionFixed, precisionPrefix, precisionRound match Node.js', () {
    const fixedInputs = [
      8.9,
      1.1,
      0.89,
      0.11,
      0.089,
      0.011,
      1e-6,
      100.0,
      0.0,
      double.nan,
      double.infinity,
    ];
    for (var i = 0; i < fixedInputs.length; ++i) {
      expect(precisionFixed(fixedInputs[i]), referencePrecisionFixed[i]);
    }

    const prefixInputs = <(double, double)>[
      (1e-6, 1e-6),
      (1e-9, 1e-6),
      (1e-28, 1e-28),
      (1e23, 1e27),
      (1e24, 1e27),
      (0, 1),
      (double.nan, 1),
      (double.infinity, 1),
    ];
    for (var i = 0; i < prefixInputs.length; ++i) {
      final (s, v) = prefixInputs[i];
      expect(precisionPrefix(s, v), referencePrecisionPrefix[i]);
    }

    const roundInputs = <(double, double)>[
      (0.1, 1.1),
      (0.01, 0.99),
      (0.01, 1.0),
      (0.01, 1.01),
      (0.001, 100.0),
      (0, 1),
      (double.nan, 1),
      (double.infinity, 1),
    ];
    for (var i = 0; i < roundInputs.length; ++i) {
      final (s, m) = roundInputs[i];
      expect(precisionRound(s, m), referencePrecisionRound[i]);
    }
  });
}
