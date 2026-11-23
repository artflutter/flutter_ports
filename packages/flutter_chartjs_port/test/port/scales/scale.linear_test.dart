// Original code, not ported from Chart.js: linear scale reference tests.
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_dataset.dart';
import 'scale_chart_harness.dart';
import 'scale_linear_reference.dart';

// The port-only tests of lib/src/scales/scale.linear.dart.
//
// The reference group compares real charts with the charts of
// tool/reference/scale_linear_reference.mjs: a build of the pinned Chart.js
// in Node.js v24.22.1 on arm64 (Chart.js ADR 0146), with a mock context that
// measures text in Liberation Sans 2.1.5, the test font of the harness
// (scale_chart_harness.dart, tool/reference/scale_chart_common.mjs). Each
// chart comes from acquireChart in a testWidgets case (Chart.js ADR 0022).
//
// The charts use three cartesian test controllers: `scaleTest` of the
// harness (category on the index axis and linear on the value axis),
// `scaleTest2` with the same overrides (a dataset of this type gets its own
// stacks), and `linearTest` (linear on both axes). lib/src/index.dart does
// not register the scales yet. Thus main() registers the category scale, the
// linear scale and the test controllers through their class values, before
// the snapshot of the defaults restore (Chart.js ADR 0020, section 8, and
// Chart.js ADR 0022, section 8). The generator registers the built-in
// components and the seven plugins of the dist first (registerBuiltins,
// Chart.js ADR 0041, section 1), as flutter_test_config.dart does. The other
// scales of the dist do not change these charts: a scale registers only its
// own defaults.
//
// The groups of Chart.js ADR 0186 pin the arithmetic of getPixelForValue
// (section 3) and the values of scaleValueOf (section 2) without
// generated values.

/// Native setups for selected reference cases. The generated expected scale,
/// point and draw observations remain the comparison oracle.
ChartConfig? _typedReference(String name) => switch (name) {
  'primitives' => const ChartConfig(
    labels: ['a', 'b', 'c', 'd', 'e', 'f'],
    datasets: [
      TestDataset(ChartKind('scaleTest'), data: [10, 5, 0, -5, 78, -100]),
    ],
  ),
  'string values' => const ChartConfig(
    labels: ['a', 'b', 'c', 'd', 'e', 'f'],
    datasets: [
      TestDataset(
        ChartKind('scaleTest'),
        // Preserve strings so this still exercises the numeric parser.
        extra: {
          'data': ['10', '5', '0', '-5', '78', '-100'],
        },
      ),
    ],
  ),
  'small numbers' => const ChartConfig(
    labels: ['a', 'b', 'c', 'd'],
    datasets: [
      TestDataset(ChartKind('scaleTest'), data: [-1e-8, 3e-8, -4e-8, 6e-8]),
    ],
  ),
  'empty data' => const ChartConfig(
    labels: ['a', 'b', 'c'],
    datasets: [TestDataset(ChartKind('scaleTest'), data: [])],
  ),
  'equal large positive values' => const ChartConfig(
    labels: ['a', 'b'],
    datasets: [
      TestDataset(ChartKind('scaleTest'), data: [10000, 10000]),
    ],
  ),
  'equal large negative values' => const ChartConfig(
    labels: ['a', 'b'],
    datasets: [
      TestDataset(ChartKind('scaleTest'), data: [-10000, -10000]),
    ],
  ),
  'equal values with beginAtZero' => const ChartConfig(
    labels: ['a', 'b'],
    datasets: [
      TestDataset(ChartKind('scaleTest'), data: [50, 50]),
    ],
    scales: [LinearAxis(.y, beginAtZero: true)],
  ),
  'all values zero' => const ChartConfig(
    labels: ['a', 'b'],
    datasets: [
      TestDataset(ChartKind('scaleTest'), data: [0, 0]),
    ],
  ),
  'suggestedMin and suggestedMax' => const ChartConfig(
    labels: ['a', 'b', 'c', 'd', 'e'],
    datasets: [
      TestDataset(ChartKind('scaleTest'), data: [1, -1, 0, -2, 1]),
    ],
    scales: [LinearAxis(.y, suggestedMin: -10, suggestedMax: 10)],
  ),
  'min and max' => const ChartConfig(
    labels: ['a', 'b', 'c', 'd', 'e', 'f'],
    datasets: [
      TestDataset(ChartKind('scaleTest'), data: [10, 5, 0, -5, 78, -100]),
    ],
    scales: [LinearAxis(.y, min: -1010, max: 1010)],
  ),
  'a user min of 0' => const ChartConfig(
    labels: ['S1', 'S2', 'S3'],
    datasets: [
      TestDataset(ChartKind('scaleTest'), data: [2500, 2000, 1500]),
    ],
    indexAxis: YAxis(),
    scales: [
      LinearAxis(.x, min: 0, max: 3000),
      CategoryAxis(.y, extra: {'offset': false}),
    ],
  ),
  'a user max of 0' => const ChartConfig(
    labels: ['S1', 'S2', 'S3'],
    datasets: [
      TestDataset(ChartKind('scaleTest'), data: [-2500, -2000, -1500]),
    ],
    indexAxis: YAxis(),
    scales: [LinearAxis(.x, min: -3000, max: 0)],
  ),
  'a user min above the data' => const ChartConfig(
    labels: ['a'],
    datasets: [
      TestDataset(ChartKind('scaleTest'), data: [200]),
    ],
    scales: [LinearAxis(.y, min: 250)],
  ),
  'a user max below the data' => const ChartConfig(
    labels: ['a'],
    datasets: [
      TestDataset(ChartKind('scaleTest'), data: [200]),
    ],
    scales: [LinearAxis(.y, max: 150)],
  ),
  'equal user min and max' => const ChartConfig(
    labels: ['a', 'b', 'c'],
    datasets: [
      TestDataset(ChartKind('scaleTest'), data: [0, 500, 1000]),
    ],
    scales: [
      LinearAxis(.y, min: 5, max: 5, ticks: AxisTicks(callback: _indexLabel)),
    ],
  ),
  'grace' => const ChartConfig(
    labels: ['a', 'b', 'c'],
    datasets: [
      TestDataset(ChartKind('scaleTest'), data: [20, 30, 40]),
    ],
    scales: [
      LinearAxis(.y, extra: {'grace': PercentGrace(10)}),
    ],
  ),
  'grace with beginAtZero' => const ChartConfig(
    labels: ['a', 'b', 'c'],
    datasets: [
      TestDataset(ChartKind('scaleTest'), data: [0, 30, 40]),
    ],
    scales: [
      LinearAxis(.y, beginAtZero: true, extra: {'grace': ValueGrace(5)}),
    ],
  ),
  'min, max and stepSize' => const ChartConfig(
    labels: ['a', 'b', 'c', 'd', 'e', 'f'],
    datasets: [
      TestDataset(ChartKind('scaleTest'), data: [10, 5, 0, -5, 78, -100]),
    ],
    scales: [LinearAxis(.y, min: 1, max: 11, ticks: AxisTicks(stepSize: 2))],
  ),
  'a max with a stepSize that does not fit' => const ChartConfig(
    labels: ['a', 'b', 'c'],
    datasets: [
      TestDataset(ChartKind('scaleTest'), data: [0.5, 2.5, 1.7]),
    ],
    scales: [LinearAxis(.y, max: 2.6, ticks: AxisTicks(stepSize: 0.4))],
  ),
  'count and includeBounds false' => ChartConfig(
    datasets: [
      TestDataset(
        const ChartKind('linearTest'),
        points: [
          DataPoint(10, 100),
          DataPoint(-10, 0),
          DataPoint(0, 0),
          DataPoint(99, 7),
        ],
      ),
    ],
    scales: const [
      LinearAxis(
        .x,
        min: -11,
        max: 103.5,
        ticks: AxisTicks(extra: {'includeBounds': false}),
      ),
      LinearAxis(.y, ticks: AxisTicks(extra: {'count': 6})),
    ],
  ),
  'the decimal places of the default format' => const ChartConfig(
    labels: ['a', 'b', 'c', 'd', 'e'],
    datasets: [
      TestDataset(
        ChartKind('scaleTest'),
        data: [0.06, 0.005, 0, 0.025, 0.0078],
      ),
    ],
  ),
  'maxTicksLimit 21' => const ChartConfig(
    labels: ['a', 'b'],
    datasets: [
      TestDataset(ChartKind('scaleTest'), data: [0.5, 2.5]),
    ],
    scales: [
      LinearAxis(
        .y,
        beginAtZero: false,
        ticks: AxisTicks(extra: {'maxTicksLimit': 21}),
      ),
    ],
  ),
  'bounds data' => const ChartConfig(
    labels: ['a', 'b'],
    datasets: [
      TestDataset(ChartKind('scaleTest'), data: [1, 99]),
    ],
    scales: [LinearAxis(.y, bounds: ScaleBounds.data)],
  ),
  'reverse' => const ChartConfig(
    labels: ['a', 'b', 'c', 'd', 'e', 'f'],
    datasets: [
      TestDataset(ChartKind('scaleTest'), data: [10, 5, 0, -5, 78, -100]),
    ],
    scales: [LinearAxis(.y, reverse: true)],
  ),
  _ => null,
};

/// The test controller `scaleTest2` of the generator: the overrides of
/// `scaleTest`.
final JsClass _scaleTest2Controller = cartesianTestController('scaleTest2', {
  'scales': <String, Object?>{
    '_index_': <String, Object?>{'type': 'category'},
    '_value_': <String, Object?>{'type': 'linear'},
  },
});

/// The test controller `linearTest` of the generator: linear on both axes.
final JsClass _linearTestController = cartesianTestController('linearTest', {
  'scales': <String, Object?>{
    '_index_': <String, Object?>{'type': 'linear'},
    '_value_': <String, Object?>{'type': 'linear'},
  },
});

/// The values of the observation `pixelForValue`: `pixelValues` of the
/// generator. The integers below 1e6 are Dart `int` values: they take the
/// literal lines of [LinearScale.getPixelForValue], not the fast path. The
/// other numbers are `double` values: they take the fast path. The JS Date
/// is a `DateTime` (Chart.js ADR 0024).
final List<Object?> _pixelValues = [
  0,
  1,
  -1,
  5,
  1e6,
  -2.5,
  null,
  undefined,
  double.nan,
  double.infinity,
  double.negativeInfinity,
  '5',
  ' 12.5 ',
  '0x10',
  'abc',
  '',
  true,
  false,
  <Object?>[7.0],
  <String, Object?>{},
  DateTime.fromMillisecondsSinceEpoch(7, isUtc: true),
];

/// The observations of a linear scale: `linearObservations` of the
/// generator, with the same keys and the same calls.
Map<String, Object?> _linearObservations(Scale scale, Chart chart) {
  if (scale is! LinearScale) return const {};
  final horizontal = scale.isHorizontal();
  final start = horizontal ? scale.left : scale.top;
  final end = horizontal ? scale.right : scale.bottom;
  return {
    'startValue': scale.startValue,
    'endValue': scale.endValue,
    'valueRange': scale.valueRange,
    'tickLimit': scale.getTickLimit(),
    'pixelForValue': [
      for (final v in _pixelValues)
        scale.getPixelForValue(scaleValueOf(scale, v)),
    ],
    'valuesForPixels': [
      for (final p in [start - 50, start + 0.37 * (end - start), end + 50])
        scale.getValueForPixel(p),
    ],
  };
}

/// The options of the scale [id] in the config of [chart], as a Map.
JsObjectFace _scaleConfig(Chart chart, String id) {
  final scales = (chart.config.options as AnyObject)['scales']! as JsObjectFace;
  return scales[id]! as JsObjectFace;
}

/// The actions of the action cases of the generator (`runActionCase`), by
/// the case name. Each one changes the chart and calls `chart.update()`.
final Map<String, void Function(Chart chart)> _actions = {
  'stacked and beginAtZero after the creation': (chart) {
    _scaleConfig(chart, 'y')['stacked'] = StackMode.on;
    chart.update();
    _scaleConfig(chart, 'y')['beginAtZero'] = true;
    chart.update();
  },
  'a dataset hidden after the creation': (chart) {
    chart
      ..setDatasetVisibility(1, false)
      ..update();
  },
  'maxTicksLimit, stepSize, min and max after the creation': (chart) {
    _scaleConfig(chart, 'y')
      ..['ticks'] = <String, Object?>{'maxTicksLimit': 11.0, 'stepSize': 0.01}
      ..['min'] = 0.3
      ..['max'] = 2.8;
    chart.update();
  },
  'reverse after the creation': (chart) {
    _scaleConfig(chart, 'x')['reverse'] = true;
    chart.update();
  },
};

/// The shared tick callback of the typed and generated reference configs.
List<String> _indexLabel(
  Scale scale,
  double value,
  int index,
  List<Tick> ticks,
) => ['$index'];

/// The named functions of the configs of the generator.
final Map<String, Object?> _functions = {
  'indexLabel': _indexLabel,
  'withUnit': (Object? scale, double value, int index, Object? ticks) => [
    '${jsToString(value)} kg',
  ],
  'labelOfThis': (Object? scale, double value, int index, Object? ticks) => [
    '[${jsToString((scale! as Scale).getLabelForValue(value))}]',
  ],
};

/// A chart of the test controller `linearTest` with the points [points]
/// and the axes [scales].
Chart _linearChart(List<DataPoint> points, [List<ChartAxis>? scales]) =>
    acquireChartRoot(
      ChartConfigLowering(
        ChartConfig(
          datasets: [
            TestDataset(const ChartKind('linearTest'), points: points),
          ],
          scales: scales,
        ),
      ).lower(),
    );

/// The points of the case 'objects on two linear axes' of the generator.
List<DataPoint> _scatter() => [
  DataPoint(10, 100),
  DataPoint(-10, 0),
  DataPoint(0, 0),
  DataPoint(99, 7),
];

/// The linear scale [id] of [chart].
LinearScale _scale(Chart chart, String id) => chart.scales[id]! as LinearScale;

/// A matcher of [pixel]: [isNaN] for NaN, else [equals].
Matcher _samePixel(double pixel) => pixel.isNaN ? isNaN : equals(pixel);

void main() {
  // Before the snapshot of the defaults restore (Chart.js ADR 0022, section
  // 8). The restore does not reset the items of the registry.
  Chart.register([
    CategoryScale.jsClass,
    LinearScale.jsClass,
    scaleTestController,
    _scaleTest2Controller,
    _linearTestController,
  ]);

  testReferenceOrigin(
    node: scaleLinearReferenceNode,
    arch: scaleLinearReferenceArch,
    dist: scaleLinearReferenceDist,
    commit: scaleLinearReferenceCommit,
  );

  group('the class value (Chart.js ADR 0020)', () {
    test('the registry gives the class value of the id linear', () {
      // scale.linear.tests.js:8-12.
      final scale = registry.getScale('linear');
      expect(scale, same(LinearScale.jsClass));
      expect(scale, isA<JsClass>());
      expect(LinearScale.jsClass['id'], 'linear');
      expect(LinearScale.jsClass['defaults'], same(LinearScale.defaults));
      expect(LinearScale.jsClass.superclass, same(LinearScaleBase.jsClass));
    });

    test('defaults.scales.linear has the numeric tick callback', () {
      // scale.linear.tests.js:14-18: the callback is the function object of
      // Ticks.formatters.numeric.
      final scales = defaults['scales']! as JsObjectFace;
      final linear = scales['linear']! as JsObjectFace;
      expect(linear.jsKeys(), ['ticks']);
      final ticks = linear['ticks']! as JsObjectFace;
      expect(ticks.jsKeys(), ['callback']);
      expect(ticks['callback'], same(formatters['numeric']));
      expect(ticks['callback'], isA<Function>());
    });

    testWidgets('jsConstruct makes a LinearScale from the cfg object', (
      tester,
    ) async {
      final chart = _linearChart(_scatter());
      final scale = jsConstruct(LinearScale.jsClass, [
        <String, Object?>{
          'id': 'z',
          'type': 'linear',
          'ctx': null,
          'chart': chart,
        },
      ]);
      expect(scale, isA<LinearScale>());
      expect((scale as LinearScale).id, 'z');
      expect(scale.startValue, isNaN);
      expect(scale.valueRange, 0);
    });
  });

  group('linear scale charts against upstream', () {
    test('each action names a case', () {
      final names = [for (final c in scaleLinearReference) c.name];
      expect(_actions.keys, everyElement(isIn(names)));
    });

    for (final c in scaleLinearReference) {
      testWidgets(c.name, (tester) async {
        final typed = _typedReference(c.name);
        final options = copyReference(c.options)! as AnyObject;
        final chart = typed == null
            ? acquireChart(
                copyReference(c.config, _functions)! as AnyObject,
                options,
              )
            : acquireChartRoot(ChartConfigLowering(typed).lower(), options);
        _actions[c.name]?.call(chart);
        expectScaleChart(chart, c.expected, extra: _linearObservations);
      });
    }
  });

  group('the arithmetic (Chart.js ADR 0186)', () {
    for (final (name, scales) in <(String, List<ChartAxis>)>[
      ('a horizontal scale', []),
      (
        'a reversed vertical scale with offset',
        [
          const LinearAxis(.y, reverse: true, extra: {'offset': true}),
        ],
      ),
    ]) {
      testWidgets('a double and an int give the same pixel, $name', (
        tester,
      ) async {
        final chart = _linearChart(_scatter(), scales);
        for (final id in ['x', 'y']) {
          final s = _scale(chart, id);
          final min = s.min;
          final max = s.max;
          for (final value in [
            0.0,
            -0.0,
            double.nan,
            double.infinity,
            double.negativeInfinity,
            min,
            max,
            (min + max) / 2,
            min - 1,
            max + 1,
            1.0,
            2.0,
            3.0,
            -7.0,
            100.0,
          ]) {
            final pixel = s.getPixelForValue(value);
            expect(
              pixel,
              _samePixel(
                s.getPixelForDecimal((value - s.startValue) / s.valueRange),
              ),
              reason: '$id: $value',
            );
            if (value.isFinite && value == value.truncateToDouble()) {
              expect(
                s.getPixelForValue(value.toInt().toDouble()),
                _samePixel(pixel),
                reason: '$id: ${value.toInt()} as an int',
              );
            }
          }
        }
      });
    }
  });

  group('value types (Chart.js ADR 0186)', () {
    testWidgets('null gives NaN', (tester) async {
      final y = _scale(_linearChart(_scatter()), 'y');
      expect(y.getPixelForValue(scaleValueOf(y, null)), isNaN);
      expect(y.getPixelForValue(scaleValueOf(y, null), 0), isNaN);
    });

    testWidgets("undefined and 'B' give NaN", (tester) async {
      final y = _scale(_linearChart(_scatter()), 'y');
      expect(y.getPixelForValue(scaleValueOf(y, undefined)), isNaN);
      expect(y.getPixelForValue(scaleValueOf(y, 'B')), isNaN);
    });

    testWidgets("'5' and 5 give the same pixel", (tester) async {
      final y = _scale(_linearChart(_scatter()), 'y');
      expect(y.getPixelForValue(scaleValueOf(y, '5')), y.getPixelForValue(5));
      expect(y.getPixelForValue(scaleValueOf(y, '5')), y.getPixelForValue(5));
      expect(y.getPixelForValue(scaleValueOf(y, '5')), isNot(isNaN));
    });

    testWidgets('true equals 1 and false equals 0', (tester) async {
      final y = _scale(_linearChart(_scatter()), 'y');
      expect(y.getPixelForValue(scaleValueOf(y, true)), y.getPixelForValue(1));
      expect(y.getPixelForValue(scaleValueOf(y, false)), y.getPixelForValue(0));
    });

    testWidgets('getValueForPixel inverts getPixelForValue', (tester) async {
      final chart = _linearChart(_scatter());
      for (final id in ['x', 'y']) {
        final s = _scale(chart, id);
        for (final value in [s.min, s.max, (s.min + s.max) / 2, 17.25]) {
          expect(
            s.getValueForPixel(s.getPixelForValue(value)),
            closeTo(value, 1e-9),
            reason: '$id: $value',
          );
        }
      }
    });
  });

  group('Liberation Sans widths of the generator', () {
    testReferenceWidths(scaleLinearReferenceWidths);
  });
}
