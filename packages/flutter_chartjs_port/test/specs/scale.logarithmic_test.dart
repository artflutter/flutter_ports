// Ported from Chart.js v4.6.1 test/specs/scale.logarithmic.tests.js (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-stacked-option-enum, the scale stacked values.
@TestOn('vm')
library;

import 'dart:ui' show Locale;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart';
// The spec reads classes and scopes of flutter_chartjs_port, which does not
// export lib/src yet.
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/index.dart' as fixture;
import '../support/tick_label.dart';

// The spec reads `Chart.registry`, `Chart.defaults` and `Chart.Ticks`.
// `Chart.registry` and `Chart.defaults` are static fields of `Chart`.
// `Chart.Ticks` is `ticks` of core.ticks.dart (src/index.umd.ts:43).
// test/flutter_test_config.dart registers the built-in components before
// `main()` (`harness-register-builtins`). Thus the registry has the class
// value `LogarithmicScale.jsClass`, and the defaults have the scope
// `scales.logarithmic`. The file runs on the VM, because
// core.controller.dart reaches the platform layer.
//
// `typeof x === 'function'` of a class value is `isA<JsClass>()`. The
// default tick callback is the function `ticks.formatters.logarithmic`, a
// `TickCallback` (row `adapt-native-tick`). `jasmine.any(Function)` is
// `isA<Function>()`.
//
// Each chart case has a dataset, also the cases with an empty dataset. Thus
// each chart case needs the controller of phase 7 for its chart type or its
// datasets: the bar or the line controller. The chart cases are
// `testWidgets` cases that call `acquireChart` of
// package:chartjs_test_utils/flutter.dart (Chart.js ADR 0022, section 2).
// The `beforeEach` of the second and the third `when` group, which acquires
// the chart, is a local function that each body calls first
// (`_acquireWhenChart`).
//
// The spec forms:
// - `chart.scales.y` is `chart.scales['y']!`. `not.toEqual(undefined)` of a
//   scale is `isNotNull`.
// - `toBeCloseTo(e, p)` is `closeTo(e, 5e-(p + 1))`. `toEqual` is
//   `equals`, and of an options object a compare of its `ownKeys` and of
//   the `raw` of the typed cell of each key.
// - `chart.options.scales.y.stacked = true` writes `StackMode.on` into the
//   resolver of the last read of the chain (`_chartScaleOptions`, row
//   adapt-stacked-option-enum).
// - `chart.scales[axisID].options.reverse = true` writes through the
//   resolver of the scale options.
// - `chart.chartArea[side]` is `_side(chart.chartArea!, side)`.
// - `scale.start` and `scale.end` are fields of `LogarithmicScale`.
// - A tick callback `function(value) { return value; }` is a Dart function
//   that returns its argument. `index.toString()` is `jsToString(index)`.
// - The first `when` group keeps the shared `data`, `dataWithEmptyStacks`
//   and `config` of :756-839 in the group closure, as upstream.
// - A chart is a typed `ChartConfig` (Chart.js ADR 0052). The `when`
//   groups hold their datasets as typed datasets and their points as
//   `DataPoint`s. Three cases keep a Map config: two give string or
//   `undefined` data values, and one gives the invalid `min: 'zero'`; the
//   typed API holds none of them.

/// The chart of the typed [config] (Chart.js ADR 0052).
Chart _acquire(ChartConfig config, [AcquireOptions? options]) =>
    acquireChartRoot(lowerForTest(config), options);

/// scale.logarithmic.tests.js:1-3 `getLabels(scale)`.
List<Object?> _getLabels(Scale scale) => [
  for (final t in scale.ticks!) upstreamTickLabel(t),
];

/// `chart.data.datasets[index]`: the dataset scope of a typed config.
JsObjectFace _dataset(Chart chart, int index) =>
    (jsGet(chart.data, 'datasets')! as List<Object?>)[index]! as JsObjectFace;

/// `chart.options.scales[id]`: a resolver of the chart options.
JsObjectFace _chartScaleOptions(Chart chart, String id) =>
    jsGet(jsGet(chart.options, 'scales'), id)! as JsObjectFace;

/// `chartArea[side]` for the four sides of a chart area.
double _side(ChartArea area, String side) => switch (side) {
  'left' => area.left,
  'right' => area.right,
  'top' => area.top,
  'bottom' => area.bottom,
  _ => throw ArgumentError.value(side, 'side'),
};

/// The two `axes` items of the second and the third `when` group
/// (scale.logarithmic.tests.js:962-973 and :1084-1095).
const List<({String id, String start, String end})> _axes = [
  (id: 'x', start: 'left', end: 'right'), // horizontal scale
  (id: 'y', start: 'bottom', end: 'top'), // vertical scale
];

/// The `beforeEach` of the second and the third `when` group
/// (scale.logarithmic.tests.js:977-1003 and :1099-1125): a line chart with
/// the data of [setup] and two logarithmic scales.
///
/// `setup.data || {datasets: [{data: setup.dataset}]}`: the shared datasets
/// of the item, or a new dataset with the shared points. `setup.type` is
/// not read, as upstream. `Object.assign(xConfig, setup.scale)`: the keys of
/// `setup.scale` go into both axes.
Chart _acquireWhenChart(Map<String, Object?> setup) {
  final scale = setup['scale'] as Map<String, Object?>?;
  LogarithmicAxis axisAt(CartesianAxis direction, ChartPosition position) =>
      LogarithmicAxis(
        direction,
        position: position,
        min: (scale?['min'] as num?)?.toDouble(),
        max: (scale?['max'] as num?)?.toDouble(),
        stacked: scale?['stacked'] as StackMode?,
      );
  final datasets =
      setup['data'] as List<Dataset>? ??
      [LineDataset(data: .points(setup['dataset']! as List<DataPoint>))];
  return _acquire(
    ChartConfig(
      datasets: datasets,
      scales: [
        axisAt(.x, ChartPosition.bottom),
        axisAt(.y, ChartPosition.left),
      ],
    ),
  );
}

// The second, third and fourth y axes of the specs. Their options are equal
// upstream, so a hidden title text makes them distinct by `==` (Chart.js ADR
// 0191); a title with `display` false takes no space.
const _y1 = LogarithmicAxis(
  .y,
  position: ChartPosition.right,
  title: AxisTitle(text: ['y1']),
);
const _y2 = LogarithmicAxis(
  .y,
  position: ChartPosition.right,
  title: AxisTitle(text: ['y2']),
);
const _y3 = LogarithmicAxis(
  .y,
  position: ChartPosition.right,
  title: AxisTitle(text: ['y3']),
);

void main() {
  group('Logarithmic Scale tests', () {
    group('auto', fixture.specs('scale.logarithmic'));

    test('should register', () {
      final constructor = Chart.registry.getScale('logarithmic');
      expect(constructor, isNot(same(undefined)));
      expect(constructor, isA<JsClass>());
    });

    test('should have the correct default config', () {
      final defaultConfig =
          jsGet(Chart.defaults['scales'], 'logarithmic')! as ScaleOptionsScope;
      // `toEqual`: the own keys of each object and the value of each key.
      expect(defaultConfig.ownKeys, <Object>[OptionKey.ticks]);
      final ticksScope = defaultConfig.ticksCell!.raw! as TickOptionsScope;
      expect(
        ticksScope.ownKeys,
        unorderedEquals(<Object>[OptionKey.callback, OptionKey.major]),
      );
      expect(
        ticksScope.callbackCell?.raw,
        same(jsGet(ticks['formatters'], 'logarithmic')),
      );
      final major = ticksScope.majorCell!.raw! as MajorTickOptionsScope;
      expect(major.ownKeys, <Object>[OptionKey.enabled]);
      expect(major.enabledCell?.raw, true);

      // Is this actually a function
      expect(ticksScope.callbackCell?.raw, isA<Function>());
    });

    testWidgets('should correctly determine the max & min data values', (
      tester,
    ) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            BarDataset(data: .values([42, 1000, 64, 100])),
            BarDataset(yAxis: _y1, data: .values([10, 5, 5000, 78, 450])),
            BarDataset(yAxis: _y1, data: .values([150])),
            BarDataset(yAxis: _y2, data: .values([20, 0, 150, 1800, 3040])),
            BarDataset(yAxis: _y3, data: .values([67, 0.0004, 0, 820, 0.001])),
          ],
          labels: ['a', 'b', 'c', 'd', 'e'],
          scales: [LogarithmicAxis(.y), _y1, _y2, _y3],
        ),
      );

      expect(chart.scales['y'], isNotNull); // must construct
      expect(chart.scales['y']!.min, 10);
      expect(chart.scales['y']!.max, 1000);

      expect(chart.scales['y1'], isNotNull); // must construct
      expect(chart.scales['y1']!.min, 1);
      expect(chart.scales['y1']!.max, 5000);

      expect(chart.scales['y2'], isNotNull); // must construct
      expect(chart.scales['y2']!.min, 10);
      expect(chart.scales['y2']!.max, 4000);

      expect(chart.scales['y3'], isNotNull); // must construct
      expect(chart.scales['y3']!.min, closeTo(0.0001, 5e-5));
      expect(chart.scales['y3']!.max, 900);
    });

    // Native scopes preserve string inputs for the parser.
    testWidgets(
      'should correctly determine the max & min of string data values',
      (tester) async {
        final chart = acquireChartRoot(
          ChartConfigurationScope()
            ..type = 'line'
            ..data = (ChartDataScope()
              ..datasets = [
                scopeFromMap(
                  LineControllerDatasetOptionsScope(),
                  <String, Object?>{
                    'yAxisID': 'y',
                    'data': <Object?>['42', '1000', '64', '100'],
                  },
                ),
                scopeFromMap(
                  LineControllerDatasetOptionsScope(),
                  <String, Object?>{
                    'yAxisID': 'y1',
                    'data': <Object?>['10', '5', '5000', '78', '450'],
                  },
                ),
                scopeFromMap(
                  LineControllerDatasetOptionsScope(),
                  <String, Object?>{
                    'yAxisID': 'y1',
                    'data': <Object?>['150'],
                  },
                ),
                scopeFromMap(
                  LineControllerDatasetOptionsScope(),
                  <String, Object?>{
                    'yAxisID': 'y2',
                    'data': <Object?>['20', '0', '150', '1800', '3040'],
                  },
                ),
                scopeFromMap(
                  LineControllerDatasetOptionsScope(),
                  <String, Object?>{
                    'yAxisID': 'y3',
                    'data': <Object?>['67', '0.0004', '0', '820', '0.001'],
                  },
                ),
              ]
              ..labels = <Object?>['a', 'b', 'c', 'd', 'e'])
            ..options = scopeFromMap(ChartOptionsScope(), <String, Object?>{
              'scales': <String, Object?>{
                'y': <String, Object?>{'type': 'logarithmic'},
                'y1': <String, Object?>{
                  'position': ChartPosition.right,
                  'type': 'logarithmic',
                },
                'y2': <String, Object?>{
                  'position': ChartPosition.right,
                  'type': 'logarithmic',
                },
                'y3': <String, Object?>{
                  'position': ChartPosition.right,
                  'type': 'logarithmic',
                },
              },
            }),
        );

        expect(chart.scales['y'], isNotNull); // must construct
        expect(chart.scales['y']!.min, 40);
        expect(chart.scales['y']!.max, 1000);

        expect(chart.scales['y1'], isNotNull); // must construct
        expect(chart.scales['y1']!.min, 5);
        expect(chart.scales['y1']!.max, 5000);

        expect(chart.scales['y2'], isNotNull); // must construct
        expect(chart.scales['y2']!.min, 10);
        expect(chart.scales['y2']!.max, 4000);

        expect(chart.scales['y3'], isNotNull); // must construct
        expect(chart.scales['y3']!.min, closeTo(0.0001, 5e-5));
        expect(chart.scales['y3']!.max, 900);
      },
    );

    testWidgets(
      'should correctly determine the max & min data values when there are '
      'hidden datasets',
      (tester) async {
        final chart = _acquire(
          const ChartConfig(
            datasets: [
              LineDataset(yAxis: _y1, data: .values([10, 5, 5000, 78, 450])),
              LineDataset(data: .values([42, 1000, 64, 100])),
              LineDataset(yAxis: _y1, data: .values([50000]), hidden: true),
              LineDataset(yAxis: _y2, data: .values([20, 0, 7400, 14, 291])),
              LineDataset(
                yAxis: _y2,
                data: .values([6, 0.0007, 9, 890, 60000]),
                hidden: true,
              ),
            ],
            labels: ['a', 'b', 'c', 'd', 'e'],
            scales: [LogarithmicAxis(.y), _y1, _y2],
          ),
        );

        expect(chart.scales['y1'], isNotNull); // must construct
        expect(chart.scales['y1']!.min, 5);
        expect(chart.scales['y1']!.max, 5000);

        expect(chart.scales['y2'], isNotNull); // must construct
        expect(chart.scales['y2']!.min, 10);
        expect(chart.scales['y2']!.max, 8000);
      },
    );

    // Native scopes preserve `undefined` among the parser inputs.
    testWidgets(
      'should correctly determine the max & min data values when there is '
      'NaN data',
      (tester) async {
        final chart = acquireChartRoot(
          ChartConfigurationScope()
            ..type = 'bar'
            ..data = (ChartDataScope()
              ..datasets = [
                scopeFromMap(
                  BarControllerDatasetOptionsScope(),
                  <String, Object?>{
                    'yAxisID': 'y',
                    'data': <Object?>[
                      undefined,
                      10,
                      null,
                      5,
                      5000,
                      double.nan,
                      78,
                      450,
                    ],
                  },
                ),
                scopeFromMap(
                  BarControllerDatasetOptionsScope(),
                  <String, Object?>{
                    'yAxisID': 'y',
                    'data': <Object?>[
                      undefined,
                      28,
                      null,
                      1000,
                      500,
                      double.nan,
                      50,
                      42,
                      double.infinity,
                      double.negativeInfinity,
                    ],
                  },
                ),
                scopeFromMap(
                  BarControllerDatasetOptionsScope(),
                  <String, Object?>{
                    'yAxisID': 'y1',
                    'data': <Object?>[
                      undefined,
                      30,
                      null,
                      9400,
                      0,
                      double.nan,
                      54,
                      836,
                    ],
                  },
                ),
                scopeFromMap(
                  BarControllerDatasetOptionsScope(),
                  <String, Object?>{
                    'yAxisID': 'y1',
                    'data': <Object?>[
                      undefined,
                      0,
                      null,
                      800,
                      9,
                      double.nan,
                      894,
                      21,
                    ],
                  },
                ),
              ]
              ..labels = <Object?>['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i'])
            ..options = scopeFromMap(ChartOptionsScope(), <String, Object?>{
              'scales': <String, Object?>{
                'y': <String, Object?>{'type': 'logarithmic'},
                'y1': <String, Object?>{
                  'position': ChartPosition.right,
                  'type': 'logarithmic',
                },
              },
            }),
        );

        expect(chart.scales['y'], isNotNull); // must construct
        expect(chart.scales['y']!.min, 1);
        expect(chart.scales['y']!.max, 5000);

        // Turn on stacked mode since it uses it's own
        _chartScaleOptions(chart, 'y')['stacked'] = StackMode.on;
        chart.update();

        expect(chart.scales['y']!.min, 1);
        expect(chart.scales['y']!.max, 6000);

        expect(chart.scales['y1'], isNotNull); // must construct
        expect(chart.scales['y1']!.min, 1);
        expect(chart.scales['y1']!.max, 10000);
      },
    );

    testWidgets('should correctly determine the max & min for scatter data', (
      tester,
    ) async {
      final chart = _acquire(
        ChartConfig(
          datasets: [
            LineDataset(
              data: .points([
                DataPoint(10, 100),
                DataPoint(2, 6),
                DataPoint(65, 121),
                DataPoint(99, 7),
              ]),
            ),
          ],
          scales: const [
            LogarithmicAxis(.x, position: ChartPosition.bottom),
            LogarithmicAxis(.y),
          ],
        ),
      );

      expect(chart.scales['x']!.min, 2);
      expect(chart.scales['x']!.max, 100);

      expect(chart.scales['y']!.min, 6);
      expect(chart.scales['y']!.max, 150);
    });

    testWidgets(
      'should correctly determine the max & min for scatter data when 0 '
      'values are present',
      (tester) async {
        final chart = _acquire(
          ChartConfig(
            datasets: [
              LineDataset(
                data: .points([
                  DataPoint(7, 950),
                  DataPoint(289, 0),
                  DataPoint(0, 8),
                  DataPoint(23, 0.04),
                ]),
              ),
            ],
            scales: const [
              LogarithmicAxis(.x, position: ChartPosition.bottom),
              LogarithmicAxis(.y),
            ],
          ),
        );

        expect(chart.scales['x']!.min, 1);
        expect(chart.scales['x']!.max, 30);

        expect(chart.scales['y']!.min, 0.01);
        expect(chart.scales['y']!.max, 1000);
      },
    );

    testWidgets(
      'should correctly determine the min and max data values when stacked '
      'mode is turned on',
      (tester) async {
        final chart = _acquire(
          const ChartConfig(
            datasets: [
              BarDataset(data: .values([10, 5, 1, 5, 78, 100])),
              BarDataset(yAxis: _y1, data: .values([0, 1000])),
              BarDataset(data: .values([150, 10, 10, 100, 10, 9])),
              LineDataset(data: .values([100, 100, 100, 100, 100, 100])),
            ],
            labels: ['a', 'b', 'c', 'd', 'e', 'f'],
            scales: [
              LogarithmicAxis(.y, stacked: StackMode.on),
              _y1,
            ],
          ),
        );

        expect(chart.scales['y']!.min, 0.1);
        expect(chart.scales['y']!.max, 200);
      },
    );

    testWidgets(
      'should correctly determine the min and max data values when stacked '
      'mode is turned on ignoring hidden datasets',
      (tester) async {
        final chart = _acquire(
          const ChartConfig(
            datasets: [
              BarDataset(data: .values([10, 5, 1, 5, 78, 100])),
              BarDataset(yAxis: _y1, data: .values([0, 1000])),
              BarDataset(data: .values([150, 10, 10, 100, 10, 9])),
              BarDataset(
                data: .values([10000, 10000, 10000, 10000, 10000, 10000]),
                hidden: true,
              ),
            ],
            labels: ['a', 'b', 'c', 'd', 'e', 'f'],
            scales: [
              LogarithmicAxis(.y, stacked: StackMode.on),
              _y1,
            ],
          ),
        );

        expect(chart.scales['y']!.min, 0.1);
        expect(chart.scales['y']!.max, 200);
      },
    );

    testWidgets(
      'should ensure that the scale has a max and min that are not equal',
      (tester) async {
        final chart = _acquire(
          const ChartConfig(
            datasets: [BarDataset(data: .values([]))],
            labels: [],
            scales: [LogarithmicAxis(.y)],
          ),
        );

        expect(chart.scales['y']!.min, 1);
        expect(chart.scales['y']!.max, 10);

        _dataset(chart, 0)['data'] = <Object?>[0.15, 0.15];
        chart.update();

        expect(chart.scales['y']!.min, 0.1);
        expect(chart.scales['y']!.max, 0.15);
      },
    );

    testWidgets('should use the min and max options', (tester) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            BarDataset(data: .values([1, 1, 1, 2, 1, 0])),
          ],
          labels: [],
          scales: [
            LogarithmicAxis(
              .y,
              min: 10,
              max: 1010,
              ticks: AxisTicks(callback: valueTickLabel),
            ),
          ],
        ),
      );

      final yScale = chart.scales['y']!;
      final tickCount = yScale.ticks!.length;
      expect(yScale.min, 10);
      expect(yScale.max, 1010);
      expect(yScale.ticks![0].value, 10);
      expect(yScale.ticks![tickCount - 1].value, 1010);
    });

    testWidgets('should ignore negative min and max options', (tester) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            BarDataset(data: .values([1, 1, 1, 2, 1, 0])),
          ],
          labels: [],
          scales: [
            LogarithmicAxis(
              .y,
              min: -10,
              max: -1010,
              ticks: AxisTicks(callback: valueTickLabel),
            ),
          ],
        ),
      );

      final y = chart.scales['y']!;
      expect(y.min, 0.1);
      expect(y.max, 2);
    });

    // Preserve the string `min` input in the native scale scope.
    testWidgets('should ignore invalid min and max options', (tester) async {
      final chart = acquireChartRoot(
        ChartConfigurationScope()
          ..type = 'bar'
          ..data = (ChartDataScope()
            ..datasets = [
              scopeFromMap(
                BarControllerDatasetOptionsScope(),
                <String, Object?>{
                  'data': <Object?>[1, 1, 1, 2, 1, 0],
                },
              ),
            ]
            ..labels = <Object?>['a', 'b', 'c', 'd', 'e', 'f'])
          ..options = scopeFromMap(ChartOptionsScope(), <String, Object?>{
            'scales': <String, Object?>{
              'y': <String, Object?>{
                'type': 'logarithmic',
                'min': 'zero',
                'max': null,
                'ticks': <String, Object?>{'callback': valueTickLabel},
              },
            },
          }),
      );

      final y = chart.scales['y']!;
      expect(y.min, 0.1);
      expect(y.max, 2);
    });

    testWidgets('should generate tick marks', (tester) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            BarDataset(data: .values([10, 5, 2, 25, 78])),
          ],
          labels: [],
          scales: [
            LogarithmicAxis(
              .y,
              ticks: AxisTicks(autoSkip: false, callback: valueTickLabel),
            ),
          ],
        ),
      );

      final scale = chart.scales['y']! as LogarithmicScale;
      expect(
        // Row adapt-native-tick: the label is the line of the number.
        _getLabels(scale).map(jsToNumber).toList(),
        equals(<Object?>[
          1,
          2,
          3,
          4,
          5,
          6,
          7,
          8,
          9,
          10,
          15,
          20,
          30,
          40,
          50,
          60,
          70,
          80,
        ]),
      );
      expect(scale.start, equals(1));
      expect(scale.end, equals(80));
    });

    testWidgets('should generate tick marks when 0 values are present', (
      tester,
    ) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            BarDataset(data: .values([11, 0.8, 0, 28, 7])),
          ],
          labels: [],
          scales: [
            LogarithmicAxis(.y, ticks: AxisTicks(callback: valueTickLabel)),
          ],
        ),
      );

      final scale = chart.scales['y']! as LogarithmicScale;
      // Counts down because the lines are drawn top to bottom
      expect(
        // Row adapt-native-tick: the label is the line of the number.
        _getLabels(scale).map(jsToNumber).toList(),
        equals(<Object?>[
          0.1,
          0.2,
          0.3,
          0.4,
          0.5,
          0.6,
          0.7,
          0.8,
          0.9,
          1,
          1.5,
          2,
          3,
          4,
          5,
          6,
          7, //
          8, 9, 10, 15, 20, 30,
        ]),
      );
      expect(scale.start, equals(0.1));
      expect(scale.end, equals(30));
    });

    testWidgets(
      'should generate tick marks in the correct order in reversed mode',
      (tester) async {
        final chart = _acquire(
          const ChartConfig(
            datasets: [
              LineDataset(data: .values([10, 5, 1, 25, 78])),
            ],
            labels: [],
            scales: [
              LogarithmicAxis(
                .y,
                reverse: true,
                ticks: AxisTicks(autoSkip: false, callback: valueTickLabel),
              ),
            ],
          ),
        );

        final scale = chart.scales['y']! as LogarithmicScale;
        expect(
          // Row adapt-native-tick: the label is the line of the number.
          _getLabels(scale).map(jsToNumber).toList(),
          equals(<Object?>[
            80, 70, 60, 50, 40, 30, 20, 15, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, //
          ]),
        );
        expect(scale.start, equals(80));
        expect(scale.end, equals(1));
      },
    );

    testWidgets(
      'should generate tick marks in the correct order in reversed mode when '
      '0 values are present',
      (tester) async {
        final chart = _acquire(
          const ChartConfig(
            datasets: [
              LineDataset(data: .values([21, 9, 0, 10, 25])),
            ],
            labels: [],
            scales: [
              LogarithmicAxis(
                .y,
                reverse: true,
                ticks: AxisTicks(callback: valueTickLabel),
              ),
            ],
          ),
        );

        final scale = chart.scales['y']! as LogarithmicScale;
        expect(
          // Row adapt-native-tick: the label is the line of the number.
          _getLabels(scale).map(jsToNumber).toList(),
          equals(<Object?>[
            30, 20, 15, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, //
          ]),
        );
        expect(scale.start, equals(30));
        expect(scale.end, equals(1));
      },
    );

    testWidgets('should build labels using the default template', (
      tester,
    ) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            LineDataset(data: .values([10, 5, 1.1, 25, 0, 78])),
          ],
          labels: [],
          scales: [LogarithmicAxis(.y, ticks: AxisTicks(autoSkip: false))],
        ),
      );

      expect(
        _getLabels(chart.scales['y']!),
        equals(<Object?>[
          '1', '2', '3', '', '5', '', '', '', '', '10', '15', '20', '30', //
          '', '50', '60', '70', '80',
        ]),
      );
    });

    testWidgets('should build labels using the user supplied callback', (
      tester,
    ) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            BarDataset(data: .values([10, 5, 2, 25, 78])),
          ],
          labels: [],
          scales: [
            LogarithmicAxis(.y, ticks: AxisTicks(callback: indexTickLabel)),
          ],
        ),
      );

      // Just the index
      expect(
        _getLabels(chart.scales['y']!),
        equals(<Object?>[
          '0',
          '1',
          '2',
          '3',
          '4',
          '5',
          '6',
          '7',
          '8',
          '9',
          '10',
          '11',
          '12', //
          '13', '14', '15', '16', '17',
        ]),
      );
    });

    testWidgets('should correctly get the correct label for a data item', (
      tester,
    ) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            BarDataset(data: .values([10, 5, 5000, 78, 450])),
            BarDataset(yAxis: _y1, data: .values([1, 1000, 10, 100])),
            BarDataset(data: .values([150])),
          ],
          labels: [],
          scales: [LogarithmicAxis(.y), _y1],
        ),
      );

      expect(chart.scales['y']!.getLabelForValue(150), '150');
    });

    testWidgets('should correctly use the locale when generating the label', (
      tester,
    ) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            BarDataset(data: .values([10, 5, 5000, 78, 450])),
            BarDataset(yAxis: _y1, data: .values([1, 1000, 10, 100])),
            BarDataset(data: .values([150])),
          ],
          labels: [],
          scales: [LogarithmicAxis(.y), _y1],
          // DIVERGES(chartjs): adapt-intl-number-format, a Locale.
          locale: Locale('de', 'DE'),
        ),
      );

      expect(chart.scales['y']!.getLabelForValue(10.25), '10,25');
    });

    group('when', () {
      const data = <Dataset>[
        BarDataset(data: .values([1, 39]), stack: 'stack'),
        BarDataset(data: .values([1, 39]), stack: 'stack'),
      ];
      const dataWithEmptyStacks = <Dataset>[
        BarDataset(data: .values([])),
        BarDataset(data: .values([])),
        ...data,
      ];
      final config = <Map<String, Object?>>[
        <String, Object?>{
          'axis': 'y',
          'firstTick': 1, // start of the axis (minimum)
          'describe': 'all stacks are defined',
        },
        <String, Object?>{
          'axis': 'y',
          'data': dataWithEmptyStacks,
          'firstTick': 1,
          'describe': 'not all stacks are defined',
        },
        <String, Object?>{
          'axis': 'y',
          'scale': <String, Object?>{
            'y': <String, Object?>{'min': 0},
          },
          'firstTick': 0.1,
          'describe': 'all stacks are defined and min: 0',
        },
        <String, Object?>{
          'axis': 'y',
          'data': dataWithEmptyStacks,
          'scale': <String, Object?>{
            'y': <String, Object?>{'min': 0},
          },
          'firstTick': 0.1,
          'describe': 'not stacks are defined and min: 0',
        },
        <String, Object?>{
          'axis': 'x',
          'firstTick': 1,
          'describe': 'all stacks are defined',
        },
        <String, Object?>{
          'axis': 'x',
          'data': dataWithEmptyStacks,
          'firstTick': 1,
          'describe': 'not all stacks are defined',
        },
        <String, Object?>{
          'axis': 'x',
          'scale': <String, Object?>{
            'x': <String, Object?>{'min': 0},
          },
          'firstTick': 0.1,
          'describe': 'all stacks are defined and min: 0',
        },
        <String, Object?>{
          'axis': 'x',
          'data': dataWithEmptyStacks,
          'scale': <String, Object?>{
            'x': <String, Object?>{'min': 0},
          },
          'firstTick': 0.1,
          'describe': 'not all stacks are defined and min: 0',
        },
      ];
      for (final setup in config) {
        // `setup.axis` is the id of the scale; the index axis is the other
        // axis class (row adapt-axis-objects).
        final CartesianAxis indexAxis;
        final String chartStart;
        final String chartEnd;
        final axis = setup['axis']! as String;

        if (axis == 'x') {
          indexAxis = const YAxis();
          chartStart = 'left';
          chartEnd = 'right';
        } else {
          indexAxis = const XAxis();
          chartStart = 'bottom';
          chartEnd = 'top';
        }
        // `scaleConfig[axis]`: a logarithmic axis with `beginAtZero: false`.
        // Object.assign(scaleConfig, setup.scale) replaces it with the axis
        // object of `setup.scale` (an undefined source adds no key), and
        // the type stays logarithmic.
        final direction = axis == 'x' ? CartesianAxis.x : CartesianAxis.y;
        final scaleConfig = switch (setup['scale']) {
          final Map<String, Object?> scale => LogarithmicAxis(
            direction,
            min: ((scale[axis]! as Map<String, Object?>)['min']! as num)
                .toDouble(),
          ),
          _ => LogarithmicAxis(direction, beginAtZero: false),
        };

        final description =
            'dataset has stack option and ${setup['describe']}'
            ' and axis is "$axis";';
        group(description, () {
          testWidgets('should define the correct axis limits', (tester) async {
            final chart = _acquire(
              ChartConfig(
                labels: const ['category 1', 'category 2'],
                datasets: setup['data'] as List<Dataset>? ?? data,
                indexAxis: indexAxis,
                scales: [scaleConfig],
              ),
            );

            final axisID = axis;
            final scale = chart.scales[axisID]!;
            final firstTick = setup['firstTick']! as num;
            // last tick (should be first available tick after: 2 * 39)
            const lastTick = 80;
            var start = _side(chart.chartArea!, chartStart);
            var end = _side(chart.chartArea!, chartEnd);

            expect(
              scale.getPixelForValue(firstTick.toDouble()),
              toBeCloseToPixel(start),
            );
            expect(
              scale.getPixelForValue(lastTick.toDouble()),
              toBeCloseToPixel(end),
            );

            expect(scale.getValueForPixel(start), closeTo(firstTick, 5e-5));
            expect(scale.getValueForPixel(end), closeTo(lastTick, 5e-5));

            chart.scales[axisID]!.optionsView['reverse'] = true; // Reverse mode
            chart.update();

            // chartArea might have been resized in update
            start = _side(chart.chartArea!, chartEnd);
            end = _side(chart.chartArea!, chartStart);

            expect(
              scale.getPixelForValue(firstTick.toDouble()),
              toBeCloseToPixel(start),
            );
            expect(
              scale.getPixelForValue(lastTick.toDouble()),
              toBeCloseToPixel(end),
            );

            expect(scale.getValueForPixel(start), closeTo(firstTick, 5e-5));
            expect(scale.getValueForPixel(end), closeTo(lastTick, 5e-5));
          });
        });
      }
    });

    group('when', () {
      final config = <Map<String, Object?>>[
        <String, Object?>{
          'dataset': <DataPoint>[],
          'firstTick': 1, // value of the first tick
          'lastTick': 10, // value of the last tick
          'describe': 'empty dataset, without min/max',
        },
        <String, Object?>{
          'dataset': <DataPoint>[],
          'scale': <String, Object?>{'stacked': StackMode.on},
          'firstTick': 1,
          'lastTick': 10,
          'describe': 'empty dataset, without min/max, with stacked: true',
        },
        <String, Object?>{
          'data': const <Dataset>[
            LineDataset(data: .values([]), stack: 'stack'),
            LineDataset(data: .values([]), stack: 'stack'),
          ],
          'type': 'bar',
          'firstTick': 1,
          'lastTick': 10,
          'describe': 'empty dataset with stack option, without min/max',
        },
        <String, Object?>{
          'dataset': <DataPoint>[],
          'scale': <String, Object?>{'min': 1},
          'firstTick': 1,
          'lastTick': 10,
          'describe': 'empty dataset, min: 1, without max',
        },
        <String, Object?>{
          'dataset': <DataPoint>[],
          'scale': <String, Object?>{'max': 80},
          'firstTick': 1,
          'lastTick': 80,
          'describe': 'empty dataset, max: 80, without min',
        },
        <String, Object?>{
          'dataset': <DataPoint>[],
          'scale': <String, Object?>{'max': 0.8},
          'firstTick': 0.01,
          'lastTick': 0.8,
          'describe': 'empty dataset, max: 0.8, without min',
        },
        <String, Object?>{
          'dataset': <DataPoint>[
            DataPoint(10, 10),
            DataPoint(5, 5),
            DataPoint(1, 1),
            DataPoint(25, 25),
            DataPoint(78, 78),
          ],
          'firstTick': 1,
          'lastTick': 80,
          'describe': 'dataset min point {x: 1, y: 1}, max point {x:78, y:78}',
        },
      ];
      for (final setup in config) {
        for (final axis in _axes) {
          final expectation =
              'min = ${jsToString(setup['firstTick'])}, '
              'max = ${jsToString(setup['lastTick'])}';
          group('${setup['describe']} and axis is "${axis.id}"; expect: '
              '$expectation;', () {
            late Chart chart;

            // The beforeEach acquires a chart: a local function that the
            // case calls first.
            void beforeEach() {
              chart = _acquireWhenChart(setup);
            }

            testWidgets('should get the correct pixel value for a point', (
              tester,
            ) async {
              beforeEach();
              final axisID = axis.id;
              final scale = chart.scales[axisID]!;
              final firstTick = setup['firstTick']! as num;
              final lastTick = setup['lastTick']! as num;
              var start = _side(chart.chartArea!, axis.start);
              var end = _side(chart.chartArea!, axis.end);

              expect(
                scale.getPixelForValue(firstTick.toDouble()),
                toBeCloseToPixel(start),
              );
              expect(
                scale.getPixelForValue(lastTick.toDouble()),
                toBeCloseToPixel(end),
              );
              expect(
                scale.getPixelForValue(0),
                toBeCloseToPixel(start),
              ); // 0 is invalid, put it at the start.

              expect(scale.getValueForPixel(start), closeTo(firstTick, 5e-5));
              expect(scale.getValueForPixel(end), closeTo(lastTick, 5e-5));

              chart.scales[axisID]!.optionsView['reverse'] =
                  true; // Reverse mode
              chart.update();

              // chartArea might have been resized in update
              start = _side(chart.chartArea!, axis.end);
              end = _side(chart.chartArea!, axis.start);

              expect(
                scale.getPixelForValue(firstTick.toDouble()),
                toBeCloseToPixel(start),
              );
              expect(
                scale.getPixelForValue(lastTick.toDouble()),
                toBeCloseToPixel(end),
              );

              expect(scale.getValueForPixel(start), closeTo(firstTick, 5e-5));
              expect(scale.getValueForPixel(end), closeTo(lastTick, 5e-5));
            });
          });
        }
      }
    });

    group('when', () {
      final config = <Map<String, Object?>>[
        <String, Object?>{
          'dataset': <DataPoint>[],
          'scale': <String, Object?>{'min': 0},
          'lastTick': 10, // value of the last tick
          'describe': 'empty dataset, min: 0, without max',
        },
        <String, Object?>{
          'dataset': <DataPoint>[],
          'scale': <String, Object?>{'min': 0, 'max': 80},
          'lastTick': 80,
          'describe': 'empty dataset, min: 0, max: 80',
        },
        <String, Object?>{
          'dataset': <DataPoint>[],
          'scale': <String, Object?>{'min': 0, 'max': 0.8},
          'lastTick': 0.8,
          'describe': 'empty dataset, min: 0, max: 0.8',
        },
        <String, Object?>{
          'dataset': <DataPoint>[
            DataPoint(0, 0),
            DataPoint(10, 10),
            DataPoint(1.2, 1.2),
            DataPoint(25, 25),
            DataPoint(78, 78),
          ],
          'lastTick': 80,
          'describe': 'dataset min point {x: 0, y: 0}, max point {x:78, y:78}',
        },
        <String, Object?>{
          'dataset': <DataPoint>[
            DataPoint(0, 0),
            DataPoint(10, 10),
            DataPoint(6.3, 6.3),
            DataPoint(25, 25),
            DataPoint(78, 78),
          ],
          'lastTick': 80,
          'describe': 'dataset min point {x: 0, y: 0}, max point {x:78, y:78}',
        },
        <String, Object?>{
          'dataset': <DataPoint>[
            DataPoint(10, 10),
            DataPoint(1.2, 1.2),
            DataPoint(25, 25),
            DataPoint(78, 78),
          ],
          'scale': <String, Object?>{'min': 0},
          'lastTick': 80,
          'describe':
              'dataset min point {x: 1.2, y: 1.2}, max point {x:78, y:78}, '
              'min: 0',
        },
        <String, Object?>{
          'dataset': <DataPoint>[
            DataPoint(10, 10),
            DataPoint(6.3, 6.3),
            DataPoint(25, 25),
            DataPoint(78, 78),
          ],
          'scale': <String, Object?>{'min': 0},
          'lastTick': 80,
          'describe':
              'dataset min point {x: 6.3, y: 6.3}, max point {x:78, y:78}, '
              'min: 0',
        },
      ];
      // Two items have the same `describe`. Thus the cases of the second
      // item get ` #2` (porting-flow.md section 1, step 5).
      final describes = <String>{};
      for (final setup in config) {
        for (final axis in _axes) {
          final expectation = 'min = 0, max = ${jsToString(setup['lastTick'])}';
          final describe =
              '${setup['describe']} and axis is "${axis.id}"; expect: '
              '$expectation;';
          const name = 'should get the correct pixel value for a point';
          final isRepeat = !describes.add(describe);
          group(describe, () {
            late Chart chart;

            // The beforeEach acquires a chart: a local function that the
            // case calls first.
            void beforeEach() {
              chart = _acquireWhenChart(setup);
            }

            testWidgets(isRepeat ? '$name #2' : name, (tester) async {
              beforeEach();
              final axisID = axis.id;
              final scale = chart.scales[axisID]!;
              final lastTick = setup['lastTick']! as num;
              var start = _side(chart.chartArea!, axis.start);
              var end = _side(chart.chartArea!, axis.end);

              expect(scale.getPixelForValue(0), toBeCloseToPixel(start));
              expect(
                scale.getPixelForValue(lastTick.toDouble()),
                toBeCloseToPixel(end),
              );

              expect(scale.getValueForPixel(start), closeTo(scale.min, 5e-5));
              expect(scale.getValueForPixel(end), closeTo(lastTick, 5e-5));

              chart.scales[axisID]!.optionsView['reverse'] =
                  true; // Reverse mode
              chart.update();

              // chartArea might have been resized in update
              start = _side(chart.chartArea!, axis.end);
              end = _side(chart.chartArea!, axis.start);

              expect(scale.getPixelForValue(0), toBeCloseToPixel(start));
              expect(
                scale.getPixelForValue(lastTick.toDouble()),
                toBeCloseToPixel(end),
              );

              expect(scale.getValueForPixel(start), closeTo(scale.min, 5e-5));
              expect(scale.getValueForPixel(end), closeTo(lastTick, 5e-5));
            });
          });
        }
      }
    });

    testWidgets(
      'Should correctly determine the max & min when no values provided and '
      'suggested minimum and maximum are set',
      (tester) async {
        final chart = _acquire(
          const ChartConfig(
            datasets: [BarDataset(data: .values([]))],
            labels: ['a', 'b', 'c', 'd', 'e', 'f'],
            scales: [LogarithmicAxis(.y, suggestedMin: 10, suggestedMax: 100)],
          ),
        );

        expect(chart.scales['y'], isNotNull); // must construct
        expect(chart.scales['y']!.min, 10);
        expect(chart.scales['y']!.max, 100);
      },
    );

    testWidgets('Should bound to data', (tester) async {
      final chart = _acquire(
        const ChartConfig(
          labels: ['a', 'b'],
          datasets: [
            LineDataset(data: .values([1.1, 99])),
          ],
          scales: [LogarithmicAxis(.y, bounds: ScaleBounds.data)],
        ),
      );

      expect(chart.scales['y']!.min, equals(1.1));
      expect(chart.scales['y']!.max, equals(99));
    });
  });
}
