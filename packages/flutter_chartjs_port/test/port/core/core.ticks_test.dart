// Original code, not ported from Chart.js: core.ticks cases with no spec.
import 'dart:ui' show Locale;

import 'package:flutter_chartjs_port/src/core/core.ticks.dart';
import 'package:flutter_chartjs_port/src/js/js_array.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/types/index.dart';
import 'package:intl/intl.dart';
import 'package:test/test.dart';

// The spec core.ticks.tests.js calls formatters.numeric only with one to two
// ticks, and does not call formatters.values or formatters.logarithmic
// outside a chart. The expected values come from Node.js v24.12.0 (V8 13.6)
// on x64. It ran the upstream core.ticks.js with the same `this` objects and
// tick lists. The chart locale is a Locale and the tick format a NumberFormat
// of package:intl (Chart.js ADR 0119).

/// The `chart` of a `this` object `{chart: {options}, options}`.
final class _Chart(@override final Map<String, Object?> options)
    implements Chart {
  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A `this` object `{chart, options}`, passed as a [Scale].
final class _Scale(
  @override final Chart chart,
  @override final Map<String, Object?> options,
) implements Scale {
  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A tick object `{value}` or `{value, significand}`.
final class _Tick(double value, [double? significand]) extends Tick {
  this : super(value: value, significand: significand);
}

/// `{chart: {options: {locale}}, options: {ticks: {format}}}`.
_Scale _scale(Locale? locale, [NumberFormat? format]) =>
    _Scale(_Chart(<String, Object?>{'locale': ?locale}), <String, Object?>{
      'ticks': <String, Object?>{'format': ?format},
    });

/// The ticks with the values [values].
List<Tick> _ticks(List<double> values) => [
  for (final value in values) _Tick(value),
];

/// The one line of `formatters.<name>(scale, tickValue, index, ticks)`.
String _apply(
  TickFormatter? formatter,
  double tickValue,
  int index,
  List<Tick> ticks, [
  Scale? scale,
]) => formatter!(
  scale ?? _scale(const Locale('en', 'US')),
  tickValue,
  index,
  ticks,
)!.single;

void main() {
  group('formatters', () {
    test('is the formatters of the default export', () {
      expect(identical(ticks['formatters'], formatters), isTrue);
      expect(jsObjectKeys(formatters), ['values', 'numeric', 'logarithmic']);
      expect(identical(formatters['numeric'], formatters['numeric']), isTrue);
    });

    test('logarithmic calls the current formatters.numeric', () {
      // core.ticks.js:77 reads formatters.numeric when logarithmic runs.
      final numeric = formatters['numeric']!;
      final scale = _scale(const Locale('en', 'US'));
      addTearDown(() => formatters['numeric'] = numeric);
      formatters['numeric'] = (self, v, i, ticks) {
        final same = identical(self, scale);
        return ['patched ${jsNumberToString(v)} $i ${ticks.length} $same'];
      };
      expect(
        _apply(formatters['logarithmic'], 1, 0, _ticks([1, 2]), scale),
        'patched 1 0 2 true',
      );
      formatters['numeric'] = numeric;
      expect(
        _apply(formatters['logarithmic'], 1, 0, _ticks([1, 2]), scale),
        '1',
      );
    });
  });

  group('formatters.values', () {
    test("gives the line '' + value", () {
      // Row adapt-native-tick: the value of a tick is a number.
      final values = formatters['values'];
      expect(_apply(values, 5, 0, _ticks([5])), '5');
      expect(_apply(values, 0.1, 0, _ticks([0.1])), '0.1');
      expect(_apply(values, 1e21, 0, _ticks([1e21])), '1e+21');
      expect(_apply(values, double.nan, 0, _ticks([0])), 'NaN');
    });
  });

  group('formatters.numeric', () {
    final numeric = formatters['numeric'];

    test("gives '0' for 0", () {
      expect(_apply(numeric, 0, 0, _ticks([0, 1])), '0');
    });

    test('takes the decimals of the tick spacing', () {
      expect(_apply(numeric, 2.5, 1, _ticks([0, 2.5, 5, 7.5, 10])), '2.5');
      expect(_apply(numeric, 1500, 1, _ticks([0, 1500, 3000, 4500])), '1,500');
      // Three ticks: the spacing of the first two. 1.5 is not an integer.
      expect(_apply(numeric, 1.5, 1, _ticks([0, 1.5, 3])), '1.5');
      // Four ticks: the spacing of the second and the third tick.
      expect(_apply(numeric, 1.5, 1, _ticks([0, 1.5, 3, 4.5])), '1.5');
    });

    test('uses scientific notation for small and huge ticks', () {
      expect(
        _apply(numeric, 0.00003, 1, _ticks([0, 0.00003, 0.00006])),
        '3.00000E-5',
      );
      expect(
        _apply(numeric, 20000000000000000, 1, _ticks([0, 2e16, 4e16])),
        '2E16',
      );
    });

    test('gives NaN for a NaN tick', () {
      expect(_apply(numeric, double.nan, 1, _ticks([0, double.nan])), 'NaN');
    });

    test('reads the locale of the chart', () {
      final ticks = _ticks([0, 1234.5, 2469]);
      expect(
        _apply(numeric, 1234.5, 1, ticks, _scale(const Locale('de', 'DE'))),
        '1.234,5',
      );
      // An absent locale is the current locale of package:intl, en_US.
      expect(_apply(numeric, 1234.5, 1, ticks, _scale(null)), '1,234.5');
    });

    test('a NumberFormat formats the tick as it is', () {
      // Row adapt-intl-number-format: the format keeps its own digits and
      // locale. Dart cannot copy it to merge the digits of the tick.
      final ticks = _ticks([0, 1234.5, 2469]);
      final de = _scale(const Locale('de', 'DE'), NumberFormat.compact());
      expect(_apply(numeric, 1234.5, 1, ticks, de), '1.23K');
      expect(
        _apply(
          numeric,
          0.25,
          1,
          _ticks([0, 0.25, 0.5]),
          _scale(null, NumberFormat.percentPattern()),
        ),
        '25%',
      );
    });

    test('throws a TypeError without options.ticks', () {
      // this.options.ticks.format reads a property of undefined.
      final scale = _Scale(_Chart(<String, Object?>{}), <String, Object?>{});
      expect(
        () => _apply(numeric, 1, 0, <Tick>[], scale),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('formatters.logarithmic', () {
    final logarithmic = formatters['logarithmic'];
    final oneToTen = _ticks([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);

    test("gives '0' for 0", () {
      expect(_apply(logarithmic, 0, 0, _ticks([0, 1])), '0');
    });

    test('shows the significands 1, 2, 3, 5, 10 and 15', () {
      expect(_apply(logarithmic, 1, 0, oneToTen), '1');
      expect(_apply(logarithmic, 2, 1, oneToTen), '2');
      expect(_apply(logarithmic, 4, 3, oneToTen), '');
      expect(_apply(logarithmic, 7, 6, oneToTen), '');
      expect(_apply(logarithmic, 8, 7, oneToTen), '');
      // 8 is not above 0.8 * 10.
      expect(_apply(logarithmic, 9, 8, oneToTen), '');
      expect(
        _apply(logarithmic, 0.03, 1, _ticks([0.01, 0.03, 0.04, 0.05, 0.06])),
        '0.03',
      );
      expect(
        _apply(logarithmic, 0.04, 2, _ticks([0.01, 0.03, 0.04, 0.05, 0.06])),
        '',
      );
      // 150 / 100 is 1.5.
      expect(_apply(logarithmic, 150, 2, _ticks([100, 120, 150, 200])), '');
      final tens = _ticks([10, 15, 20, 30, 40, 50, 60, 70, 80, 90]);
      expect(_apply(logarithmic, 30, 3, tens), '30');
      expect(_apply(logarithmic, 15, 1, _ticks([10, 15, 20, 30])), '');
    });

    test('shows each tick above 80 % of the ticks', () {
      final ticks = _ticks([1, 2, 3, 4, 5, 6, 7, 8, 9, 7]);
      expect(_apply(logarithmic, 7, 9, ticks), '7');
    });

    test('reads a truthy significand of the tick', () {
      List<Tick> ticks(double significand) => [
        _Tick(10, 1),
        _Tick(40, significand),
        _Tick(50, 5),
      ];
      expect(_apply(logarithmic, 40, 1, ticks(4)), '');
      expect(_apply(logarithmic, 40, 1, ticks(5)), '40');
      // 0 and NaN are falsy: the formatter computes 40 / 10.
      expect(_apply(logarithmic, 40, 1, ticks(0)), '');
      expect(_apply(logarithmic, 40, 1, ticks(double.nan)), '');
    });

    test('gives an empty label for a negative tick', () {
      // log10(-4) is NaN, and so is the significand.
      expect(_apply(logarithmic, -4, 0, _ticks([-4, 0])), '');
      expect(_apply(logarithmic, 1.5, 0, _ticks([1.5, 3])), '');
    });

    test('throws a TypeError for an index that is not a tick', () {
      // ticks[index] is undefined, and the read of significand throws.
      final ticks = _ticks([1, 5]);
      for (final index in <int>[2, 5, -1]) {
        expect(
          () => _apply(logarithmic, 5, index, ticks),
          throwsA(isA<TypeError>()),
          reason: '$index',
        );
      }
      // A 0 tick returns before the read.
      expect(_apply(logarithmic, 0, 5, ticks), '0');
    });

    test('formats a shown tick with formatters.numeric', () {
      expect(
        _apply(logarithmic, 1e-7, 0, _ticks([1e-7, 2e-7])),
        '1.0000000E-7',
      );
    });
  });
}
