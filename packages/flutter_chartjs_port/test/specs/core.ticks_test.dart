// Ported from Chart.js v4.6.1 test/specs/core.ticks.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'dart:ui' show Locale;

import 'package:chartjs_test_utils/flutter.dart';
// The spec builds charts of flutter_chartjs_port, which does not export lib/src
// yet.
import 'package:flutter_chartjs_port/src/core/core.scale.dart' as core;
import 'package:flutter_chartjs_port/src/core/core.ticks.dart' show ticks;
import 'package:flutter_chartjs_port/src/types/index.dart';
import 'package:flutter_chartjs_port/src/types/layout.dart' show ChartPosition;
import 'package:flutter_test/flutter_test.dart';

import '../support/jasmine.dart';
import '../support/tick_label.dart';

// The spec reads `Chart.Ticks`, which src/index.umd.ts:43 sets. Here it is
// `ticks` of core.ticks.dart. The two tick generator cases acquire a line
// chart. A chart case is a `testWidgets` case, and the file runs on the VM
// (Chart.js ADR 0030, section 12 item 5). It does not call `setUpSpecs()`:
// its charts need the built-in components.
//
// The spec forms:
// - `value.toString()` of a tick callback is `valueTickLabel`, a
//   `TickCallback` (row `adapt-native-tick`).
// - `chart.scales.x` is `chart.scales['x']!`.
// - `toEqual` of an array is `jasmineEquals`.

/// core.ticks.tests.js:1-3 `getLabels(scale)`.
List<Object?> _getLabels(core.Scale scale) => [
  for (final t in scale.ticks!) upstreamTickLabel(t),
];

/// The `chart` of the JavaScript object literal
/// `{chart: {options: {locale}}, ...}`, passed as a [Chart]. The formatters
/// read only its options.
final class _Chart(@override final Map<String, Object?> options)
    implements Chart {
  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The JavaScript object literal `{chart, options}` that the spec passes as
/// `this`, passed as a [Scale]. The formatters read only `chart` and
/// `options`.
final class _Scale(
  @override final Chart chart,
  @override final Map<String, Object?> options,
) implements Scale {
  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A JavaScript object literal `{value}`, passed as a [Tick].
final class _Tick(double value) extends Tick {
  this : super(value: value);
}

void main() {
  group('Test tick generators', () {
    // formatters are used as default config values so users want to be able
    // to reference them
    test('Should expose formatters api', () {
      // `typeof x` is a string, so the first two upstream expectations
      // always pass. The port checks that the two values exist.
      expect(ticks, isNotNull);
      final formatters = ticks['formatters'];
      expect(formatters, isNotNull);
      // typeof value === 'function': each formatter is a function.
      expect(formatters!['values'], isA<Function>());
      expect(formatters['numeric'], isA<Function>());
    });

    testWidgets('Should generate linear spaced ticks with correct precision', (
      tester,
    ) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{'data': <Object?>[]},
          ],
        },
        'options': <String, Object?>{
          'plugins': <String, Object?>{'legend': false},
          'scales': <String, Object?>{
            'x': <String, Object?>{
              'type': 'linear',
              'position': ChartPosition.bottom,
              'ticks': <String, Object?>{'callback': valueTickLabel},
            },
            'y': <String, Object?>{
              'type': 'linear',
              'ticks': <String, Object?>{'callback': valueTickLabel},
            },
          },
        },
      });

      final xLabels = _getLabels(chart.scales['x']!);
      final yLabels = _getLabels(chart.scales['y']!);

      expect(
        xLabels,
        jasmineEquals(<Object?>[
          '0', '0.1', '0.2', '0.3', '0.4', '0.5', '0.6', '0.7', '0.8', '0.9', //
          '1',
        ]),
      );
      expect(
        yLabels,
        jasmineEquals(<Object?>[
          '0', '0.1', '0.2', '0.3', '0.4', '0.5', '0.6', '0.7', '0.8', '0.9', //
          '1',
        ]),
      );
    });

    testWidgets(
      'Should generate logarithmic spaced ticks with correct precision',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{'data': <Object?>[]},
            ],
          },
          'options': <String, Object?>{
            'plugins': <String, Object?>{'legend': false},
            'scales': <String, Object?>{
              'x': <String, Object?>{
                'type': 'logarithmic',
                'position': ChartPosition.bottom,
                'min': 0.1,
                'max': 1,
                'ticks': <String, Object?>{
                  'autoSkip': false,
                  'callback': valueTickLabel,
                },
              },
              'y': <String, Object?>{
                'type': 'logarithmic',
                'min': 0.1,
                'max': 1,
                'ticks': <String, Object?>{
                  'autoSkip': false,
                  'callback': valueTickLabel,
                },
              },
            },
          },
        });

        final xLabels = _getLabels(chart.scales['x']!);
        final yLabels = _getLabels(chart.scales['y']!);

        const expected = <Object?>[
          '0.1', '0.11', '0.12', '0.13', '0.14', '0.15', '0.16', '0.17', //
          '0.18', '0.19', '0.2', '0.25', '0.3', '0.4', '0.5', '0.6', '0.7', //
          '0.8', '0.9', '1',
        ];
        expect(xLabels, jasmineEquals(expected));
        expect(yLabels, jasmineEquals(expected));
      },
    );

    group('formatters.numeric', () {
      test('should not fail on empty or 1 item array', () {
        // DIVERGES(chartjs): adapt-intl-number-format, the locale is a
        // Locale, and the empty format object of upstream (no options) is
        // no format.
        final scale = _Scale(
          _Chart(<String, Object?>{'locale': const Locale('en')}),
          <String, Object?>{'ticks': <String, Object?>{}},
        );
        // numeric.apply(scale, args): the scale is the first argument,
        // and the result is the one line of the label.
        final numeric = ticks['formatters']!['numeric']!;
        expect(numeric(scale, 1, 0, <Tick>[]), ['1']);
        expect(numeric(scale, 1, 0, <Tick>[_Tick(1)]), ['1']);
        expect(numeric(scale, 1, 0, <Tick>[_Tick(1), _Tick(1.01)]), ['1.00']);
      });
    });
  });
}
