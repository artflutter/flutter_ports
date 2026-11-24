// Ported from Chart.js v4.6.1 test/specs/scale.linear.tests.js (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-stacked-option-enum, the scale stacked values.
// DIVERGES(chartjs): adapt-direct-colors, native color test inputs.
@TestOn('vm')
library;

import 'dart:ui' as native_ui;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/index.dart' as fixture;
import '../support/tick_label.dart';

// The spec reads Chart.registry and Chart.defaults: the static fields
// `Chart.registry` and `Chart.defaults` of core.controller.dart.
// flutter_test_config.dart registers the built-in components before main().
// Thus the linear scale is in the registry, and its defaults are in
// `Chart.defaults.scales.linear`.
//
// The chart cases call `acquireChart`. Thus they are `testWidgets` cases,
// and the file runs on the VM (Chart.js ADR 0022, sections 1 and 2). The
// cases at :998 and :1041 also need the legend, which
// flutter_test_config.dart registers: the legend changes the top of the
// chart area.
//
// The spec forms:
// - `not.toBe(undefined)` is `isNot(same(undefined))`.
// - `chart.scales.y` is `chart.scales['y']!`. `not.toEqual(undefined)` of a
//   scale is `isNotNull`: Dart null stands for JS undefined.
// - A property chain of the spec on an option object is a chain of
//   `jsGet`.
// - `typeof value === 'function'` is `isA<JsClass>()` for a class value and
//   `isA<Function>()` for a callback. `jasmine.any(Function)` matches a
//   value whose `typeof` is `'function'`.
// - `toBeLessThanOrEqual(x)` is `lessThanOrEqualTo(x)`.
//
// - `toBeCloseTo(e, p)` is `closeTo(e, 5e-(p + 1))`; the precision 1e-2
//   of :1300-1317 is the tolerance 0.49. `toEqual` is `equals`.
// - `chart.scales.y.options.stacked = true` writes through the resolver of
//   the scale options: `chart.scales['y']!.options['stacked'] =
//   StackMode.on` (row adapt-stacked-option-enum).
// - `chart.options.scales.y.ticks.maxTicksLimit = 11` writes into the
//   resolver of the last read of the chain (`_optionsY`).
// - `chart.scales.y.start` and `end` are fields of `LinearScaleBase`.
// - `index.toString()` of a tick callback is `jsToString(index)`.
// - `expect(fn).not.toThrow()` is `expect(fn, returnsNormally)`.
// - A chart config is a typed `ChartConfig` (Chart.js ADR 0052). Three
//   cases keep a Map config: two give string data values and one gives
//   `undefined` in its data, which a typed dataset cannot hold. A fourth
//   gives `plugins: false`, which has no typed form.

/// The chart of the typed [config] (Chart.js ADR 0052).
Chart _acquire(ChartConfig config, [AcquireOptions? options]) =>
    acquireChartRoot(ChartConfigLowering(config).lower(), options);

/// scale.linear.tests.js:1-3 `getLabels(scale)`.
List<Object?> _getLabels(Scale scale) => [
  for (final t in scale.ticks!) upstreamTickLabel(t),
];

/// `chart.data.datasets[index]`.
JsObjectFace _dataset(Chart chart, int index) =>
    (jsGet(chart.data, 'datasets')! as List<Object?>)[index]! as JsObjectFace;

/// `chart.options.scales.y`, or `chart.options.scales.y[key]` for a [key]:
/// a resolver of the chart options.
JsObjectFace _optionsY(Chart chart, [String? key]) {
  final y = jsGet(jsGet(chart.options, 'scales'), 'y');
  return (key == null ? y : jsGet(y, key))! as JsObjectFace;
}

// The second y axis of the specs, `y2` upstream (Chart.js ADR 0191).
const _y2 = LinearAxis(.y, position: ChartPosition.right);

void main() {
  group('Linear Scale', () {
    group('auto', fixture.specs('scale.linear'));

    test('Should register the constructor with the registry', () {
      final constructor = Chart.registry.getScale('linear');
      expect(constructor, isNot(same(undefined)));
      expect(constructor, isA<JsClass>());
    });

    test('Should have the correct default config', () {
      final defaultConfig = jsGet(jsGet(Chart.defaults, 'scales'), 'linear');

      final ticks = jsGet(defaultConfig, 'ticks');
      expect(jsGet(ticks, 'callback'), isA<Function>());
    });

    testWidgets('Should correctly determine the max & min data values', (
      tester,
    ) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            BarDataset(data: .values([10, 5, 0, -5, 78, -100])),
            BarDataset(yAxis: _y2, data: .values([-1000, 1000])),
            BarDataset(data: .values([150])),
          ],
          labels: ['a', 'b', 'c', 'd', 'e', 'f'],
          scales: [LinearAxis(.y), _y2],
        ),
      );

      expect(chart.scales['y'], isNotNull); // must construct
      expect(chart.scales['y']!.min, -100);
      expect(chart.scales['y']!.max, 150);
    });

    testWidgets('Should handle when only a min value is provided', (
      tester,
    ) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            LineDataset(data: .values([200])),
          ],
          scales: [LinearAxis(.y, min: 250)],
        ),
      );

      expect(chart.scales['y']!.min, 250);
    });

    testWidgets('Should handle when only a max value is provided', (
      tester,
    ) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            LineDataset(data: .values([200])),
          ],
          scales: [LinearAxis(.y, max: 150)],
        ),
      );

      expect(chart.scales['y'], isNotNull); // must construct
      expect(chart.scales['y']!.max, 150);
    });

    // Native scopes preserve string inputs for the parser.
    testWidgets(
      'Should correctly determine the max & min of string data values',
      (tester) async {
        final chart = acquireChartRoot(
          ChartConfigurationScope()
            ..type = 'bar'
            ..data = (ChartDataScope()
              ..datasets = [
                mergeExtra(
                  BarControllerDatasetOptionsScope(),
                  <String, Object?>{
                    'yAxisID': 'y',
                    'data': <Object?>['10', '5', '0', '-5', '78', '-100'],
                  },
                ),
                mergeExtra(
                  BarControllerDatasetOptionsScope(),
                  <String, Object?>{
                    'yAxisID': 'y2',
                    'data': <Object?>['-1000', '1000'],
                  },
                ),
                mergeExtra(
                  BarControllerDatasetOptionsScope(),
                  <String, Object?>{
                    'yAxisID': 'y',
                    'data': <Object?>['150'],
                  },
                ),
              ]
              ..labels = <Object?>['a', 'b', 'c', 'd', 'e', 'f'])
            ..options = mergeExtra(ChartOptionsScope(), <String, Object?>{
              'scales': <String, Object?>{
                'y': <String, Object?>{'type': 'linear'},
                'y2': <String, Object?>{
                  'type': 'linear',
                  'position': ChartPosition.right,
                },
              },
            }),
        );

        expect(chart.scales['y'], isNotNull); // must construct
        expect(chart.scales['y']!.min, -100);
        expect(chart.scales['y']!.max, 150);
      },
    );

    testWidgets(
      'Should correctly determine the max & min when no values provided and '
      'suggested minimum and maximum are set',
      (tester) async {
        final chart = _acquire(
          const ChartConfig(
            datasets: [BarDataset(data: .values([]))],
            labels: ['a', 'b', 'c', 'd', 'e', 'f'],
            scales: [LinearAxis(.y, suggestedMin: -10, suggestedMax: 15)],
          ),
        );

        expect(chart.scales['y'], isNotNull); // must construct
        expect(chart.scales['y']!.min, -10);
        expect(chart.scales['y']!.max, 15);
      },
    );

    testWidgets('Should correctly determine the max & min when no datasets are '
        'associated and suggested minimum and maximum are set', (tester) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [BarDataset()],
          scales: [LinearAxis(.y, suggestedMin: -10, suggestedMax: 0)],
        ),
      );

      expect(chart.scales['y']!.min, -10);
      expect(chart.scales['y']!.max, 0);
    });

    // Native scopes preserve string inputs for the parser.
    testWidgets(
      'Should correctly determine the max & min data values ignoring hidden '
      'datasets',
      (tester) async {
        final chart = acquireChartRoot(
          ChartConfigurationScope()
            ..type = 'bar'
            ..data = (ChartDataScope()
              ..datasets = [
                mergeExtra(
                  BarControllerDatasetOptionsScope(),
                  <String, Object?>{
                    'yAxisID': 'y',
                    'data': <Object?>['10', '5', '0', '-5', '78', '-100'],
                  },
                ),
                mergeExtra(
                  BarControllerDatasetOptionsScope(),
                  <String, Object?>{
                    'yAxisID': 'y2',
                    'data': <Object?>['-1000', '1000'],
                  },
                ),
                mergeExtra(
                  BarControllerDatasetOptionsScope(),
                  <String, Object?>{
                    'yAxisID': 'y',
                    'data': <Object?>['150'],
                    'hidden': true,
                  },
                ),
              ]
              ..labels = <Object?>['a', 'b', 'c', 'd', 'e', 'f'])
            ..options = mergeExtra(ChartOptionsScope(), <String, Object?>{
              'scales': <String, Object?>{
                'y': <String, Object?>{'type': 'linear'},
                'y2': <String, Object?>{
                  'position': ChartPosition.right,
                  'type': 'linear',
                },
              },
            }),
        );

        expect(chart.scales['y'], isNotNull); // must construct
        expect(chart.scales['y']!.min, -100);
        expect(chart.scales['y']!.max, 80);
      },
    );

    // Native scopes preserve `undefined` in the data.
    testWidgets(
      'Should correctly determine the max & min data values ignoring data '
      'that is NaN',
      (tester) async {
        final chart = acquireChartRoot(
          ChartConfigurationScope()
            ..type = 'bar'
            ..data = (ChartDataScope()
              ..datasets = [
                mergeExtra(
                  BarControllerDatasetOptionsScope(),
                  <String, Object?>{
                    'yAxisID': 'y',
                    'data': <Object?>[
                      null,
                      90,
                      double.nan,
                      undefined,
                      45,
                      30,
                      double.infinity,
                      double.negativeInfinity,
                    ],
                  },
                ),
              ]
              ..labels = <Object?>['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'])
            ..options = mergeExtra(ChartOptionsScope(), <String, Object?>{
              'scales': <String, Object?>{
                'y': <String, Object?>{'type': 'linear', 'beginAtZero': false},
              },
            }),
        );

        expect(chart.scales['y']!.min, 30);
        expect(chart.scales['y']!.max, 90);

        // Scale is now stacked
        chart.scales['y']!.optionsView['stacked'] = StackMode.on;
        chart.update();

        expect(chart.scales['y']!.min, 30);
        expect(chart.scales['y']!.max, 90);

        chart.scales['y']!.optionsView['beginAtZero'] = true;
        chart.update();

        expect(chart.scales['y']!.min, 0);
        expect(chart.scales['y']!.max, 90);
      },
    );

    testWidgets(
      'Should correctly determine the max & min data values for small numbers',
      (tester) async {
        final chart = _acquire(
          const ChartConfig(
            datasets: [
              BarDataset(data: .values([-1e-8, 3e-8, -4e-8, 6e-8])),
            ],
            labels: ['a', 'b', 'c', 'd'],
            scales: [LinearAxis(.y)],
          ),
        );

        expect(chart.scales['y'], isNotNull); // must construct
        expect(chart.scales['y']!.min * 1e8, closeTo(-4, 5e-3));
        expect(chart.scales['y']!.max * 1e8, closeTo(6, 5e-3));
      },
    );

    testWidgets('Should correctly determine the max & min for scatter data', (
      tester,
    ) async {
      final chart = _acquire(
        ChartConfig(
          datasets: [
            LineDataset(
              data: .points([
                DataPoint(10, 100),
                DataPoint(-10, 0),
                DataPoint(0, 0),
                DataPoint(99, 7),
              ]),
            ),
          ],
          scales: const [
            LinearAxis(.x, position: ChartPosition.bottom),
            LinearAxis(.y),
          ],
        ),
      )..update();

      expect(chart.scales['x']!.min, -20);
      expect(chart.scales['x']!.max, 100);
      expect(chart.scales['y']!.min, 0);
      expect(chart.scales['y']!.max, 100);
    });

    testWidgets('Should correctly get the label for the given index', (
      tester,
    ) async {
      final chart = _acquire(
        ChartConfig(
          datasets: [
            LineDataset(
              data: .points([
                DataPoint(10, 100),
                DataPoint(-10, 0),
                DataPoint(0, 0),
                DataPoint(99, 7),
              ]),
            ),
          ],
          scales: const [
            LinearAxis(.x, position: ChartPosition.bottom),
            LinearAxis(.y),
          ],
        ),
      )..update();

      expect(chart.scales['y']!.getLabelForValue(7), '7');
    });

    testWidgets(
      'Should correctly use the locale setting when getting a label',
      (tester) async {
        final chart = _acquire(
          ChartConfig(
            datasets: [
              LineDataset(
                data: .points([
                  DataPoint(10, 100),
                  DataPoint(-10, 0),
                  DataPoint(0, 0),
                  DataPoint(99, 7),
                ]),
              ),
            ],
            scales: const [
              LinearAxis(.x, position: ChartPosition.bottom),
              LinearAxis(.y),
            ],
            // DIVERGES(chartjs): adapt-intl-number-format, a Locale.
            extra: const {'locale': native_ui.Locale('de', 'DE')},
          ),
        )..update();

        expect(chart.scales['y']!.getLabelForValue(7.07), '7,07');
      },
    );

    testWidgets(
      'Should correctly determine the min and max data values when stacked '
      'mode is turned on',
      (tester) async {
        final chart = _acquire(
          const ChartConfig(
            datasets: [
              BarDataset(data: .values([10, 5, 0, -5, 78, -100])),
              LineDataset(yAxis: _y2, data: .values([-1000, 1000])),
              BarDataset(data: .values([150, 0, 0, -100, -10, 9])),
              LineDataset(data: .values([10, 10, 10, 10, 10, 10])),
            ],
            labels: ['a', 'b', 'c', 'd', 'e', 'f'],
            scales: [
              LinearAxis(.y, stacked: StackMode.on),
              _y2,
            ],
          ),
        )..update();

        expect(chart.scales['y']!.min, -150);
        expect(chart.scales['y']!.max, 200);
      },
    );

    testWidgets(
      'Should correctly determine the min and max data values when stacked '
      'mode is turned on and there are hidden datasets',
      (tester) async {
        final chart = _acquire(
          const ChartConfig(
            datasets: [
              BarDataset(data: .values([10, 5, 0, -5, 78, -100])),
              BarDataset(yAxis: _y2, data: .values([-1000, 1000])),
              BarDataset(data: .values([150, 0, 0, -100, -10, 9])),
              BarDataset(data: .values([10, 20, 30, 40, 50, 60]), hidden: true),
            ],
            labels: ['a', 'b', 'c', 'd', 'e', 'f'],
            scales: [
              LinearAxis(.y, stacked: StackMode.on),
              _y2,
            ],
          ),
        )..update();

        expect(chart.scales['y']!.min, -150);
        expect(chart.scales['y']!.max, 200);
      },
    );

    testWidgets(
      'Should correctly determine the min and max data values when stacked '
      'mode is turned on there are multiple types of datasets',
      (tester) async {
        final chart = _acquire(
          const ChartConfig(
            datasets: [
              BarDataset(data: .values([10, 5, 0, -5, 78, -100])),
              LineDataset(data: .values([10, 10, 10, 10, 10, 10])),
              BarDataset(data: .values([150, 0, 0, -100, -10, 9])),
            ],
            labels: ['a', 'b', 'c', 'd', 'e', 'f'],
            scales: [LinearAxis(.y, stacked: StackMode.on)],
          ),
        );

        chart.scales['y']!.determineDataLimits();
        expect(chart.scales['y']!.min, -105);
        expect(chart.scales['y']!.max, 160);
      },
    );

    testWidgets(
      'Should ensure that the scale has a max and min that are not equal',
      (tester) async {
        final chart = _acquire(
          const ChartConfig(
            datasets: [BarDataset()],
            labels: ['a', 'b', 'c', 'd', 'e', 'f'],
            scales: [LinearAxis(.y)],
          ),
        );

        expect(chart.scales['y'], isNotNull); // must construct
        expect(chart.scales['y']!.min, 0);
        expect(chart.scales['y']!.max, 1);
      },
    );

    testWidgets(
      'Should ensure that the scale has a max and min that are not equal - '
      'large positive numbers',
      (tester) async {
        // https://github.com/chartjs/Chart.js/issues/9377
        final chart = _acquire(
          const ChartConfig(
            datasets: [
              // Value larger than Number.MAX_SAFE_INTEGER
              LineDataset(data: .values([10000000000000000])),
            ],
            labels: ['a'],
            scales: [LinearAxis(.y)],
          ),
        );

        expect(chart.scales['y'], isNotNull); // must construct
        expect(chart.scales['y']!.min, 10000000000000000 * 0.95);
        expect(chart.scales['y']!.max, 10000000000000000 * 1.05);
      },
    );

    testWidgets(
      'Should ensure that the scale has a max and min that are not equal - '
      'large negative numbers',
      (tester) async {
        // https://github.com/chartjs/Chart.js/issues/9377
        final chart = _acquire(
          const ChartConfig(
            datasets: [
              // Value larger than Number.MAX_SAFE_INTEGER
              LineDataset(data: .values([-10000000000000000])),
            ],
            labels: ['a'],
            scales: [LinearAxis(.y)],
          ),
        );

        expect(chart.scales['y'], isNotNull); // must construct
        expect(chart.scales['y']!.max, -10000000000000000 * 0.95);
        expect(chart.scales['y']!.min, -10000000000000000 * 1.05);
      },
    );

    testWidgets(
      'Should ensure that the scale has a max and min that are not equal when '
      'beginAtZero is set',
      (tester) async {
        final chart = _acquire(
          const ChartConfig(
            datasets: [BarDataset()],
            labels: ['a', 'b', 'c', 'd', 'e', 'f'],
            scales: [LinearAxis(.y, beginAtZero: true)],
          ),
        );

        expect(chart.scales['y'], isNotNull); // must construct
        expect(chart.scales['y']!.min, 0);
        expect(chart.scales['y']!.max, 1);
      },
    );

    testWidgets('Should use the suggestedMin and suggestedMax options', (
      tester,
    ) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            BarDataset(data: .values([1, 1, 1, 2, 1, 0])),
          ],
          labels: ['a', 'b', 'c', 'd', 'e', 'f'],
          scales: [LinearAxis(.y, suggestedMax: 10, suggestedMin: -10)],
        ),
      );

      expect(chart.scales['y'], isNotNull); // must construct
      expect(chart.scales['y']!.min, -10);
      expect(chart.scales['y']!.max, 10);
    });

    testWidgets('Should use the min and max options', (tester) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            BarDataset(data: .values([1, 1, 1, 2, 1, 0])),
          ],
          labels: ['a', 'b', 'c', 'd', 'e', 'f'],
          scales: [LinearAxis(.y, max: 1010, min: -1010)],
        ),
      );

      expect(chart.scales['y'], isNotNull); // must construct
      expect(chart.scales['y']!.min, -1010);
      expect(chart.scales['y']!.max, 1010);
      final labels = _getLabels(chart.scales['y']!);
      expect(labels[0], '-1,010');
      expect(labels[labels.length - 1], '1,010');
    });

    testWidgets(
      'Should use min, max and stepSize to create fixed spaced ticks',
      (tester) async {
        final chart = _acquire(
          const ChartConfig(
            datasets: [
              BarDataset(data: .values([10, 3, 6, 8, 3, 1])),
            ],
            labels: ['a', 'b', 'c', 'd', 'e', 'f'],
            scales: [
              LinearAxis(.y, min: 1, max: 11, ticks: AxisTicks(stepSize: 2)),
            ],
          ),
        );

        expect(chart.scales['y'], isNotNull); // must construct
        expect(chart.scales['y']!.min, 1);
        expect(chart.scales['y']!.max, 11);
        expect(
          _getLabels(chart.scales['y']!),
          equals(<Object?>['1', '3', '5', '7', '9', '11']),
        );
      },
    );

    testWidgets('Should not generate any ticks > max if max is specified', (
      tester,
    ) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [LineDataset()],
          scales: [
            LinearAxis(
              .x,
              min: 2.404e-8,
              max: 2.4143e-8,
              ticks: AxisTicks(includeBounds: false),
            ),
          ],
        ),
      );

      expect(chart.scales['x']!.min, 2.404e-8);
      expect(chart.scales['x']!.max, 2.4143e-8);
      expect(
        chart.scales['x']!.ticks![chart.scales['x']!.ticks!.length - 1].value,
        lessThanOrEqualTo(2.4143e-8),
      );
    });

    testWidgets(
      'Should not generate insane amounts of ticks with small stepSize and '
      'large range',
      (tester) async {
        final chart = _acquire(
          const ChartConfig(
            datasets: [BarDataset()],
            scales: [
              LinearAxis(
                .y,
                min: 1,
                max: 10000000000,
                ticks: AxisTicks(stepSize: 2, autoSkip: false),
              ),
            ],
          ),
        );

        expect(chart.scales['y']!.min, 1);
        expect(chart.scales['y']!.max, 1E10);
        expect(chart.scales['y']!.ticks!.length, lessThanOrEqualTo(1000));
      },
    );

    testWidgets('Should create decimal steps if stepSize is a decimal number', (
      tester,
    ) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            BarDataset(data: .values([10, 3, 6, 8, 3, 1])),
          ],
          labels: ['a', 'b', 'c', 'd', 'e', 'f'],
          scales: [LinearAxis(.y, ticks: AxisTicks(stepSize: 2.5))],
        ),
      );

      expect(chart.scales['y'], isNotNull); // must construct
      expect(chart.scales['y']!.min, 0);
      expect(chart.scales['y']!.max, 10);
      expect(
        _getLabels(chart.scales['y']!),
        equals(<Object?>['0', '2.5', '5', '7.5', '10']),
      );
    });

    group('precision', () {
      testWidgets('Should create integer steps if precision is 0', (
        tester,
      ) async {
        final chart = _acquire(
          const ChartConfig(
            datasets: [
              BarDataset(data: .values([0, 1, 2, 1, 0, 1])),
            ],
            labels: ['a', 'b', 'c', 'd', 'e', 'f'],
            scales: [LinearAxis(.y, ticks: AxisTicks(precision: 0))],
          ),
        );

        expect(chart.scales['y'], isNotNull); // must construct
        expect(chart.scales['y']!.min, 0);
        expect(chart.scales['y']!.max, 2);
        expect(
          _getLabels(chart.scales['y']!),
          equals(<Object?>['0', '1', '2']),
        );
      });

      testWidgets(
        'Should round the step size to the given number of decimal places',
        (tester) async {
          final chart = _acquire(
            const ChartConfig(
              datasets: [
                BarDataset(data: .values([0, 0.001, 0.002, 0.003, 0, 0.001])),
              ],
              labels: ['a', 'b', 'c', 'd', 'e', 'f'],
              scales: [LinearAxis(.y, ticks: AxisTicks(precision: 2))],
            ),
          );

          expect(chart.scales['y'], isNotNull); // must construct
          expect(chart.scales['y']!.min, 0);
          expect(chart.scales['y']!.max, 0.01);
          expect(
            _getLabels(chart.scales['y']!),
            equals(<Object?>['0', '0.01']),
          );
        },
      );
    });

    testWidgets(
      'should forcibly include 0 in the range if the beginAtZero option is '
      'used',
      (tester) async {
        final chart = _acquire(
          const ChartConfig(
            datasets: [
              BarDataset(data: .values([20, 30, 40, 50])),
            ],
            labels: ['a', 'b', 'c', 'd'],
            scales: [LinearAxis(.y, beginAtZero: false)],
          ),
        );

        expect(chart.scales['y'], isNotNull); // must construct
        expect(
          _getLabels(chart.scales['y']!),
          equals(<Object?>['20', '25', '30', '35', '40', '45', '50']),
        );

        chart.scales['y']!.optionsView['beginAtZero'] = true;
        chart.update();
        expect(
          _getLabels(chart.scales['y']!),
          equals(<Object?>[
            '0',
            '5',
            '10',
            '15',
            '20',
            '25',
            '30',
            '35',
            '40',
            '45',
            '50',
          ]),
        );

        _dataset(chart, 0)['data'] = <Object?>[-20, -30, -40, -50];
        chart.update();
        expect(
          _getLabels(chart.scales['y']!),
          equals(<Object?>[
            '-50',
            '-45',
            '-40',
            '-35',
            '-30',
            '-25',
            '-20',
            '-15',
            '-10',
            '-5',
            '0',
          ]),
        );

        chart.scales['y']!.optionsView['beginAtZero'] = false;
        chart.update();
        expect(
          _getLabels(chart.scales['y']!),
          equals(<Object?>['-50', '-45', '-40', '-35', '-30', '-25', '-20']),
        );
      },
    );

    testWidgets(
      'Should generate tick marks in the correct order in reversed mode',
      (tester) async {
        final chart = _acquire(
          const ChartConfig(
            datasets: [
              BarDataset(data: .values([10, 5, 0, 25, 78])),
            ],
            labels: ['a', 'b', 'c', 'd'],
            scales: [LinearAxis(.y, reverse: true)],
          ),
        );

        expect(
          _getLabels(chart.scales['y']!),
          equals(<Object?>[
            '80',
            '70',
            '60',
            '50',
            '40',
            '30',
            '20',
            '10',
            '0',
          ]),
        );
        expect((chart.scales['y']! as LinearScaleBase).start, 80);
        expect((chart.scales['y']! as LinearScaleBase).end, 0);
      },
    );

    testWidgets(
      'should use the correct number of decimal places in the default format '
      'function',
      (tester) async {
        final chart = _acquire(
          const ChartConfig(
            datasets: [
              BarDataset(data: .values([0.06, 0.005, 0, 0.025, 0.0078])),
            ],
            labels: ['a', 'b', 'c', 'd'],
            scales: [LinearAxis(.y)],
          ),
        );

        expect(
          _getLabels(chart.scales['y']!),
          equals(<Object?>[
            '0',
            '0.01',
            '0.02',
            '0.03',
            '0.04',
            '0.05',
            '0.06',
          ]),
        );
      },
    );

    testWidgets('Should correctly limit the maximum number of ticks', (
      tester,
    ) async {
      final chart = _acquire(
        const ChartConfig(
          labels: ['a', 'b'],
          datasets: [
            BarDataset(data: .values([0.5, 2.5])),
          ],
          scales: [LinearAxis(.y, beginAtZero: false)],
        ),
      );

      expect(
        _getLabels(chart.scales['y']!),
        equals(<Object?>['0.5', '1.0', '1.5', '2.0', '2.5']),
      );

      _optionsY(chart, 'ticks')['maxTicksLimit'] = 11;
      chart.update();

      expect(
        _getLabels(chart.scales['y']!),
        equals(<Object?>['0.5', '1.0', '1.5', '2.0', '2.5']),
      );

      _optionsY(chart, 'ticks')['maxTicksLimit'] = 21;
      chart.update();

      expect(
        _getLabels(chart.scales['y']!),
        equals(<Object?>[
          '0.5',
          '0.6',
          '0.7',
          '0.8',
          '0.9',
          '1.0',
          '1.1',
          '1.2',
          '1.3',
          '1.4',
          '1.5',
          '1.6',
          '1.7',
          '1.8',
          '1.9',
          '2.0',
          '2.1',
          '2.2',
          '2.3',
          '2.4',
          '2.5',
        ]),
      );

      _optionsY(chart, 'ticks')['maxTicksLimit'] = 11;
      _optionsY(chart, 'ticks')['stepSize'] = 0.01;
      chart.update();

      expect(
        _getLabels(chart.scales['y']!),
        equals(<Object?>['0.5', '1.0', '1.5', '2.0', '2.5']),
      );

      _optionsY(chart)['min'] = 0.3;
      _optionsY(chart)['max'] = 2.8;
      chart.update();

      expect(
        _getLabels(chart.scales['y']!),
        equals(<Object?>['0.3', '0.8', '1.3', '1.8', '2.3', '2.8']),
      );
    });

    testWidgets('Should bound to data', (tester) async {
      final chart = _acquire(
        const ChartConfig(
          labels: ['a', 'b'],
          datasets: [
            LineDataset(data: .values([1, 99])),
          ],
          scales: [LinearAxis(.y, bounds: ScaleBounds.data)],
        ),
      );

      expect(chart.scales['y']!.min, equals(1));
      expect(chart.scales['y']!.max, equals(99));
    });

    testWidgets('Should build labels using the user supplied callback', (
      tester,
    ) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            BarDataset(data: .values([10, 5, 0, 25, 78])),
          ],
          labels: ['a', 'b', 'c', 'd'],
          scales: [LinearAxis(.y, ticks: AxisTicks(callback: indexTickLabel))],
        ),
      );

      // Just the index
      expect(
        _getLabels(chart.scales['y']!),
        equals(<Object?>['0', '1', '2', '3', '4', '5', '6', '7', '8']),
      );
    });

    testWidgets('Should get the correct pixel value for a point', (
      tester,
    ) async {
      final chart = _acquire(
        const ChartConfig(
          labels: [-1, 1],
          datasets: [
            LineDataset(data: .values([-1, 1])),
          ],
          scales: [
            LinearAxis(.x, position: ChartPosition.bottom),
            LinearAxis(.y),
          ],
        ),
      );

      final xScale = chart.scales['x']!;
      expect(
        xScale.getPixelForValue(1),
        toBeCloseToPixel(501),
      ); // right - paddingRight
      expect(
        xScale.getPixelForValue(-1),
        toBeCloseToPixel(31 + 3),
      ); // left + paddingLeft + tick padding
      expect(
        xScale.getPixelForValue(0),
        toBeCloseToPixel(266 + 3 / 2),
      ); // halfway*/

      expect(xScale.getValueForPixel(501), closeTo(1, 0.49));
      expect(xScale.getValueForPixel(31), closeTo(-1, 0.49));
      expect(xScale.getValueForPixel(266), closeTo(0, 0.49));

      final yScale = chart.scales['y']!;
      expect(
        yScale.getPixelForValue(1),
        toBeCloseToPixel(32),
      ); // right - paddingRight
      expect(
        yScale.getPixelForValue(-1),
        toBeCloseToPixel(484),
      ); // left + paddingLeft
      expect(yScale.getPixelForValue(0), toBeCloseToPixel(258)); // halfway*/

      expect(yScale.getValueForPixel(32), closeTo(1, 0.49));
      expect(yScale.getValueForPixel(484), closeTo(-1, 0.49));
      expect(yScale.getValueForPixel(258), closeTo(0, 0.49));
    });

    testWidgets('should fit correctly', (tester) async {
      final chart = _acquire(
        ChartConfig(
          datasets: [
            LineDataset(
              data: .points([
                DataPoint(10, 100),
                DataPoint(-10, 0),
                DataPoint(0, 0),
                DataPoint(99, 7),
              ]),
            ),
          ],
          scales: const [
            LinearAxis(.x, position: ChartPosition.bottom),
            LinearAxis(.y),
          ],
        ),
      );

      final xScale = chart.scales['x']!;
      final yScale = chart.scales['y']!;
      expect(xScale.paddingTop, toBeCloseToPixel(0));
      expect(xScale.paddingBottom, toBeCloseToPixel(0));
      expect(xScale.paddingLeft, toBeCloseToPixel(12));
      expect(xScale.paddingRight, toBeCloseToPixel(13.5));
      expect(xScale.width, toBeCloseToPixel(468 - 3)); // minus tick padding
      expect(xScale.height, toBeCloseToPixel(30));

      expect(yScale.paddingTop, toBeCloseToPixel(10));
      expect(yScale.paddingBottom, toBeCloseToPixel(10));
      expect(yScale.paddingLeft, toBeCloseToPixel(0));
      expect(yScale.paddingRight, toBeCloseToPixel(0));
      expect(yScale.width, toBeCloseToPixel(31 + 3)); // plus tick padding
      expect(yScale.height, toBeCloseToPixel(450));

      // Extra size when scale label showing
      (jsGet(xScale.optionsView, 'title')! as JsObjectFace)['display'] = true;
      (jsGet(yScale.optionsView, 'title')! as JsObjectFace)['display'] = true;
      chart.update();

      expect(xScale.paddingTop, toBeCloseToPixel(0));
      expect(xScale.paddingBottom, toBeCloseToPixel(0));
      expect(xScale.paddingLeft, toBeCloseToPixel(12));
      expect(xScale.paddingRight, toBeCloseToPixel(13.5));
      expect(xScale.width, toBeCloseToPixel(442));
      expect(xScale.height, toBeCloseToPixel(50));

      expect(yScale.paddingTop, toBeCloseToPixel(10));
      expect(yScale.paddingBottom, toBeCloseToPixel(10));
      expect(yScale.paddingLeft, toBeCloseToPixel(0));
      expect(yScale.paddingRight, toBeCloseToPixel(0));
      expect(yScale.width, toBeCloseToPixel(58));
      expect(yScale.height, toBeCloseToPixel(429));
    });

    testWidgets('should fit correctly when display is turned off', (
      tester,
    ) async {
      final chart = _acquire(
        ChartConfig(
          datasets: [
            LineDataset(
              data: .points([
                DataPoint(10, 100),
                DataPoint(-10, 0),
                DataPoint(0, 0),
                DataPoint(99, 7),
              ]),
            ),
          ],
          scales: const [
            LinearAxis(.x, position: ChartPosition.bottom),
            LinearAxis(
              .y,
              grid: AxisGrid(drawTicks: false),
              border: AxisBorder(display: false),
              title: AxisTitle(display: false, extra: {'lineHeight': 1.2}),
              ticks: AxisTicks(display: false, padding: 0),
            ),
          ],
        ),
      );

      final yScale = chart.scales['y']!;
      expect(yScale.width, toBeCloseToPixel(0));
    });

    testWidgets(
      'max and min value should be valid and finite when charts datasets are '
      'hidden',
      (tester) async {
        final barData = <BarDataset>[
          const BarDataset(
            label: 'Closed',
            backgroundColor: ChartValue.constant(
              ChartPaint.solid(native_ui.Color.fromRGBO(56, 39, 101, 1)),
            ),
            data: .values([2500, 2000, 1500]),
          ),
          const BarDataset(
            label: 'In Progress',
            backgroundColor: ChartValue.constant(
              ChartPaint.solid(native_ui.Color.fromRGBO(123, 194, 37, 1)),
            ),
            data: .values([1000, 2000, 1500]),
          ),
          const BarDataset(
            label: 'Assigned',
            backgroundColor: ChartValue.constant(
              ChartPaint.solid(native_ui.Color.fromRGBO(255, 194, 37, 1)),
            ),
            data: .values([1000, 2000, 1500]),
          ),
        ];

        final chart = _acquire(
          ChartConfig(
            labels: const ['S1', 'S2', 'S3'],
            datasets: barData,
            indexAxis: const YAxis(),
            scales: const [
              LinearAxis(.x, stacked: StackMode.on),
              CategoryAxis(.y, stacked: StackMode.on),
            ],
          ),
        );

        // barData.datasets.forEach((data, index) => {...}).
        for (var index = 0; index < barData.length; index++) {
          chart.getDatasetMeta(index).hidden = true;
          chart.update();
        }

        expect(chart.scales['x']!.min, equals(0));
        expect(chart.scales['x']!.max, equals(1));
      },
    );

    testWidgets(
      'max and min value should be valid when min is set and all datasets are '
      'hidden',
      (tester) async {
        final barData = <BarDataset>[
          const BarDataset(
            label: 'dataset 1',
            backgroundColor: ChartValue.constant(
              ChartPaint.solid(native_ui.Color.fromRGBO(56, 39, 101, 1)),
            ),
            data: .values([2500, 2000, 1500]),
            hidden: true,
          ),
        ];

        final chart = _acquire(
          ChartConfig(
            labels: const ['S1', 'S2', 'S3'],
            datasets: barData,
            indexAxis: const YAxis(),
            scales: const [LinearAxis(.x, min: 20)],
          ),
        );

        expect(chart.scales['x']!.min, equals(20));
        expect(chart.scales['x']!.max, equals(21));
      },
    );

    testWidgets('min settings should be used if set to zero', (tester) async {
      final barData = <BarDataset>[
        const BarDataset(
          label: 'dataset 1',
          backgroundColor: ChartValue.constant(
            ChartPaint.solid(native_ui.Color.fromRGBO(56, 39, 101, 1)),
          ),
          data: .values([2500, 2000, 1500]),
        ),
      ];

      final chart = _acquire(
        ChartConfig(
          labels: const ['S1', 'S2', 'S3'],
          datasets: barData,
          indexAxis: const YAxis(),
          scales: const [LinearAxis(.x, min: 0, max: 3000)],
        ),
      );

      expect(chart.scales['x']!.min, equals(0));
    });

    testWidgets('max settings should be used if set to zero', (tester) async {
      final barData = <BarDataset>[
        const BarDataset(
          label: 'dataset 1',
          backgroundColor: ChartValue.constant(
            ChartPaint.solid(native_ui.Color.fromRGBO(56, 39, 101, 1)),
          ),
          data: .values([-2500, -2000, -1500]),
        ),
      ];

      final chart = _acquire(
        ChartConfig(
          labels: const ['S1', 'S2', 'S3'],
          datasets: barData,
          indexAxis: const YAxis(),
          scales: const [LinearAxis(.x, min: -3000, max: 0)],
        ),
      );

      expect(chart.scales['x']!.max, equals(0));
    });

    testWidgets('Should get correct pixel values when horizontal', (
      tester,
    ) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            BarDataset(data: .values([0.05, -25, 10, 15, 20, 25, 30, 35])),
          ],
          indexAxis: YAxis(),
          scales: [LinearAxis(.x)],
        ),
      );

      var start = chart.chartArea!.left;
      var end = chart.chartArea!.right;
      const min = -30;
      const max = 40;
      final scale = chart.scales['x']!;

      expect(scale.getPixelForValue(max.toDouble()), toBeCloseToPixel(end));
      expect(scale.getPixelForValue(min.toDouble()), toBeCloseToPixel(start));
      expect(scale.getValueForPixel(end), closeTo(max, 5e-5));
      expect(scale.getValueForPixel(start), closeTo(min, 5e-5));

      scale.optionsView['reverse'] = true;
      chart.update();

      start = chart.chartArea!.left;
      end = chart.chartArea!.right;

      expect(scale.getPixelForValue(max.toDouble()), toBeCloseToPixel(start));
      expect(scale.getPixelForValue(min.toDouble()), toBeCloseToPixel(end));
      expect(scale.getValueForPixel(end), closeTo(min, 5e-5));
      expect(scale.getValueForPixel(start), closeTo(max, 5e-5));
    });

    testWidgets('Should get correct pixel values when vertical', (
      tester,
    ) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            BarDataset(data: .values([0.05, -25, 10, 15, 20, 25, 30, 35])),
          ],
          scales: [LinearAxis(.y)],
        ),
      );

      var start = chart.chartArea!.bottom;
      var end = chart.chartArea!.top;
      const min = -30;
      const max = 40;
      final scale = chart.scales['y']!;

      expect(scale.getPixelForValue(max.toDouble()), toBeCloseToPixel(end));
      expect(scale.getPixelForValue(min.toDouble()), toBeCloseToPixel(start));
      expect(scale.getValueForPixel(end), closeTo(max, 5e-5));
      expect(scale.getValueForPixel(start), closeTo(min, 5e-5));

      scale.optionsView['reverse'] = true;
      chart.update();

      start = chart.chartArea!.bottom;
      end = chart.chartArea!.top;

      expect(scale.getPixelForValue(max.toDouble()), toBeCloseToPixel(start));
      expect(scale.getPixelForValue(min.toDouble()), toBeCloseToPixel(end));
      expect(scale.getValueForPixel(end), closeTo(min, 5e-5));
      expect(scale.getValueForPixel(start), closeTo(max, 5e-5));
    });

    // Preserve the sentinel that disables every plugin.
    testWidgets('should not throw errors when chart size is negative', (
      tester,
    ) async {
      // This case deliberately supplies the false sentinel outside the
      // scope's dictionary type; all other foreign values stay audited.
      final saved = foreignAudit;
      foreignAudit = (owner, key, raw) {
        if (owner == 'ChartOptionsScope' && key == 'plugins' && raw == false) {
          return;
        }
        saved?.call(owner, key, raw);
      };
      addTearDown(() => foreignAudit = saved);

      Chart createChart() {
        return acquireChartRoot(
          ChartConfigurationScope()
            ..type = 'bar'
            ..data = (ChartDataScope()
              ..labels = <Object?>[0, 1, 2, 3, 4, 5, 6, 7, '7+']
              ..datasets = [
                mergeExtra(
                  BarControllerDatasetOptionsScope(),
                  <String, Object?>{
                    'data': <Object?>[
                      29.05,
                      4,
                      15.69,
                      11.69,
                      2.84,
                      4,
                      0,
                      3.84,
                      4,
                    ],
                  },
                ),
              ])
            ..options = mergeExtra(ChartOptionsScope(), <String, Object?>{
              'plugins': false,
              'layout': <String, Object?>{
                'padding': const EdgeInsets.only(
                  left: 1,
                  top: 30,
                  right: 1,
                  bottom: 1,
                ),
              },
            }),
          const AcquireOptions(canvas: HarnessCanvas(width: 0, height: 0)),
        );
      }

      expect(createChart, returnsNormally);
    });
  });
}
