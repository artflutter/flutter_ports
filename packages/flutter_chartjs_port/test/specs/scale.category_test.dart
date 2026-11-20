// Ported from Chart.js v4.6.1 test/specs/scale.category.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart';
// The spec builds charts of flutter_chartjs_port, which does not export lib/src
// yet.
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/index.dart' as fixture;
import '../support/tick_label.dart';

// The spec reads Chart.registry and Chart.defaults, the static members
// `Chart.registry` and `Chart.defaults` of core.controller.dart. The
// harness registers the built-in scales before `main()`
// (`harness-register-builtins`). Thus `registry.getScale('category')` gives
// the class value `CategoryScale.jsClass`.
//
// Each chart case of the spec makes a line or a bar chart. Thus it needs a
// controller of phase 7, and it is a `testWidgets` case that calls
// `acquireChart` in its body (Chart.js ADR 0022, sections 1 and 2). The
// file runs on the VM. The cases that read a pixel of a vertical category
// axis (:287, :330, :406 and :479) also need the legend, which
// flutter_test_config.dart registers: the legend changes the top of the
// chart area.
//
// Two cases give a label string to `getPixelForValue` (Chart.js ADR 0025,
// scale.category.tests.js:247 and :534).
//
// The spec forms:
// - `chart.scales.x` is `chart.scales['x']!`.
// - A property chain of the spec, for example
//   `Chart.defaults.scales.category`, is a chain of `jsGet`.
// - `typeof Constructor === 'function'` is `isA<JsClass>()`.
//   `not.toBe(undefined)` is `isNot(same(undefined))`.
// - `toEqual` of an options object compares its `ownKeys` and the `raw` of
//   the typed cell of each key. Jasmine compares functions by identity. The
//   default tick callback is a top-level function, a `TickCallback` (row
//   `adapt-native-tick`).
// - `toEqual` of a number is `_equalsNumber`: Jasmine `eq` makes `0` and
//   `-0` different, and Dart `==` makes them equal. Thus the matcher also
//   compares the sign. `toEqual` of an array is `equals`.
// - `toBeLessThan` and `toBeGreaterThan` are `lessThan` and `greaterThan`.
// - `xScale.options.offset = true` writes through the resolver of the scale
//   options: `xScale.options['offset'] = true`.
// - `chart.options.scales.x.bounds = 'ticks'` writes into the resolver of
//   the last read of the chain.
// - A chart config is a typed `ChartConfig` (Chart.js ADR 0052). Seven
//   cases keep a Map config: five give `data.xLabels` or `data.yLabels`
//   (two of them also string data values), and two give the data as an
//   object by label, which the typed config cannot hold.

/// The chart of the typed [config] (Chart.js ADR 0052).
Chart _acquire(ChartConfig config, [Map<String, Object?>? options]) =>
    acquireChartRoot(ChartConfigLowering(config).lower(), options);

/// `toEqual(expected)` of a number: the value and the sign of a zero.
Matcher _equalsNumber(num expected) => allOf(
  equals(expected),
  isA<num>().having((v) => v.isNegative, 'isNegative', expected.isNegative),
);

/// scale.category.tests.js:1-3 `getLabels(scale)`.
List<Object?> _getLabels(Scale scale) => [
  for (final t in scale.ticks!) upstreamTickLabel(t),
];

void main() {
  group('Category scale tests', () {
    group('auto', fixture.specs('scale.category'));

    test('Should register the constructor with the registry', () {
      final constructor = Chart.registry.getScale('category');
      expect(constructor, isNot(same(undefined)));
      expect(constructor, isA<JsClass>());
    });

    test('Should have the correct default config', () {
      final defaultConfig =
          jsGet(jsGet(Chart.defaults, 'scales'), 'category')!
              as ScaleOptionsScope;
      // `toEqual`: the own keys of each object and the value of each key.
      expect(defaultConfig.ownKeys, <Object>[OptionKey.ticks]);
      final ticks = defaultConfig.ticksCell!.raw! as TickOptionsScope;
      expect(ticks.ownKeys, <Object>[OptionKey.callback]);
      final categoryTicks =
          CategoryScale.defaults.ticksCell!.raw! as TickOptionsScope;
      expect(ticks.callbackCell?.raw, same(categoryTicks.callbackCell?.raw));
    });

    // A Map config: `data.xLabels` has no typed form.
    testWidgets('Should generate ticks from the data xLabels', (tester) async {
      final labels = <Object?>['tick1', 'tick2', 'tick3', 'tick4', 'tick5'];
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'xLabels': labels,
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[10, 5, 0, 25, 78],
            },
          ],
        },
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'x': <String, Object?>{'type': 'category'},
          },
        },
      });

      final scale = chart.scales['x']!;
      expect(_getLabels(scale), equals(labels));
    });

    // A Map config: `data.yLabels` has no typed form.
    testWidgets('Should generate ticks from the data yLabels', (tester) async {
      final labels = <Object?>['tick1', 'tick2', 'tick3', 'tick4', 'tick5'];
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'yLabels': labels,
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[10, 5, 0, 25, 78],
            },
          ],
        },
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'y': <String, Object?>{'type': 'category'},
          },
        },
      });

      final scale = chart.scales['y']!;
      expect(_getLabels(scale), equals(labels));
    });

    testWidgets('Should generate ticks from the axis labels', (tester) async {
      final labels = <Object>['tick1', 'tick2', 'tick3', 'tick4', 'tick5'];
      final chart = _acquire(
        ChartConfig(
          type: ChartKind.line,
          datasets: const [
            LineDataset(data: [10, 5, 0, 25, 78]),
          ],
          scales: {'x': CategoryAxis(labels: labels)},
        ),
      );

      final scale = chart.scales['x']!;
      expect(_getLabels(scale), equals(labels));
    });

    // A Map config: the data is an object by label, which a typed dataset
    // cannot hold.
    testWidgets('Should generate missing labels', (tester) async {
      final labels = <Object?>['a', 'b', 'c', 'd'];
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <String, Object?>{'a': 1, 'b': 3, 'c': -1, 'd': 10},
            },
          ],
        },
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'x': <String, Object?>{
              'type': 'category',
              'labels': <Object?>['a'],
            },
          },
        },
      });

      final scale = chart.scales['x']!;
      expect(_getLabels(scale), equals(labels));
    });

    testWidgets('should parse only to a valid index', (tester) async {
      final chart = _acquire(
        const ChartConfig(
          type: ChartKind.line,
          datasets: [
            LineDataset(xAxisID: 'x', yAxisID: 'y', data: [10, 5, 0, 25, 78]),
          ],
          labels: ['tick1', 'tick2', 'tick3', 'tick4', 'tick5'],
          scales: {
            'x': CategoryAxis(position: ChartPosition.bottom),
            'y': LinearAxis(),
          },
        ),
      );

      final scale = chart.scales['x']!;

      expect(scale.parse(-10), _equalsNumber(0));
      expect(scale.parse(-0.1), _equalsNumber(0));
      expect(scale.parse(4.1), _equalsNumber(4));
      expect(scale.parse(5), _equalsNumber(4));
      expect(scale.parse(1), _equalsNumber(1));
      expect(scale.parse(1.4), _equalsNumber(1));
      expect(scale.parse(1.5), _equalsNumber(2));
      expect(scale.parse('tick2'), _equalsNumber(1));
    });

    testWidgets('should get the correct label for the index', (tester) async {
      final chart = _acquire(
        const ChartConfig(
          type: ChartKind.line,
          datasets: [
            LineDataset(xAxisID: 'x', yAxisID: 'y', data: [10, 5, 0, 25, 78]),
          ],
          labels: ['tick1', 'tick2', 'tick3', 'tick4', 'tick5'],
          scales: {
            'x': CategoryAxis(position: ChartPosition.bottom),
            'y': LinearAxis(),
          },
        ),
      );

      final scale = chart.scales['x']!;

      expect(scale.getLabelForValue(1), 'tick2');
    });

    testWidgets('Should get the correct pixel for a value when horizontal', (
      tester,
    ) async {
      final chart = _acquire(
        const ChartConfig(
          type: ChartKind.line,
          datasets: [
            LineDataset(xAxisID: 'x', yAxisID: 'y', data: [10, 5, 0, 25, 78]),
          ],
          labels: ['tick1', 'tick2', 'tick3', 'tick4', 'tick_last'],
          scales: {
            'x': CategoryAxis(position: ChartPosition.bottom),
            'y': LinearAxis(),
          },
        ),
      );

      final xScale = chart.scales['x']!;
      expect(
        xScale.getPixelForValue(0),
        toBeCloseToPixel(23 + 6), // plus lineHeight
      );
      expect(xScale.getValueForPixel(23), 0);

      expect(xScale.getPixelForValue(4), toBeCloseToPixel(487));
      expect(xScale.getValueForPixel(487), 4);

      xScale.optionsView['offset'] = true;
      chart.update();

      expect(
        xScale.getPixelForValue(0),
        toBeCloseToPixel(71 + 6), // plus lineHeight
      );
      expect(xScale.getValueForPixel(69), 0);

      expect(xScale.getPixelForValue(4), toBeCloseToPixel(461));
      expect(xScale.getValueForPixel(417), 4);
    });

    testWidgets(
      'Should get the correct pixel for a value when there are repeated '
      'labels',
      (tester) async {
        final chart = _acquire(
          const ChartConfig(
            type: ChartKind.line,
            datasets: [
              LineDataset(xAxisID: 'x', yAxisID: 'y', data: [10, 5, 0, 25, 78]),
            ],
            labels: ['tick1', 'tick2', 'tick3', 'tick4', 'tick_last'],
            scales: {
              'x': CategoryAxis(position: ChartPosition.bottom),
              'y': LinearAxis(),
            },
          ),
        );

        final xScale = chart.scales['x']!;
        expect(
          xScale.getPixelForValue(scaleValueOf(xScale, 'tick1')),
          toBeCloseToPixel(23 + 6), // plus lineHeight
        );
      },
    );

    testWidgets(
      'Should get the correct pixel for a value when horizontal and zoomed',
      (tester) async {
        final chart = _acquire(
          const ChartConfig(
            type: ChartKind.line,
            datasets: [
              LineDataset(xAxisID: 'x', yAxisID: 'y', data: [10, 5, 0, 25, 78]),
            ],
            labels: ['tick1', 'tick2', 'tick3', 'tick4', 'tick_last'],
            scales: {
              'x': CategoryAxis(
                position: ChartPosition.bottom,
                min: 'tick2',
                max: 'tick4',
              ),
              'y': LinearAxis(),
            },
          ),
        );

        final xScale = chart.scales['x']!;
        expect(
          xScale.getPixelForValue(1),
          toBeCloseToPixel(23 + 6), // plus lineHeight
        );
        expect(xScale.getPixelForValue(3), toBeCloseToPixel(496));

        xScale.optionsView['offset'] = true;
        chart.update();

        expect(
          xScale.getPixelForValue(1),
          toBeCloseToPixel(103 + 6), // plus lineHeight
        );
        expect(xScale.getPixelForValue(3), toBeCloseToPixel(429));
      },
    );

    // A Map config: string data values and `data.yLabels`, which the typed
    // config cannot hold.
    testWidgets('should get the correct pixel for a value when vertical', (
      tester,
    ) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'xAxisID': 'x',
              'yAxisID': 'y',
              'data': <Object?>['3', '5', '1', '4', '2'],
            },
          ],
          'labels': <Object?>['tick1', 'tick2', 'tick3', 'tick4', 'tick5'],
          'yLabels': <Object?>['1', '2', '3', '4', '5'],
        },
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'x': <String, Object?>{
              'type': 'category',
              'position': ChartPosition.bottom,
            },
            'y': <String, Object?>{
              'type': 'category',
              'position': ChartPosition.left,
            },
          },
        },
      });

      final yScale = chart.scales['y']!;
      expect(yScale.getPixelForValue(0), toBeCloseToPixel(32));
      expect(yScale.getValueForPixel(257), 2);

      expect(yScale.getPixelForValue(4), toBeCloseToPixel(484));
      expect(yScale.getValueForPixel(144), 1);

      yScale.optionsView['offset'] = true;
      chart.update();

      expect(yScale.getPixelForValue(0), toBeCloseToPixel(77));
      expect(yScale.getValueForPixel(256), 2);

      expect(yScale.getPixelForValue(4), toBeCloseToPixel(438));
      expect(yScale.getValueForPixel(167), 1);
    });

    // A Map config: string data values and `data.yLabels`, which the typed
    // config cannot hold.
    testWidgets(
      'should get the correct pixel for a value when vertical and zoomed',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'xAxisID': 'x',
                'yAxisID': 'y',
                'data': <Object?>['3', '5', '1', '4', '2'],
              },
            ],
            'labels': <Object?>['tick1', 'tick2', 'tick3', 'tick4', 'tick5'],
            'yLabels': <Object?>['1', '2', '3', '4', '5'],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{
                'type': 'category',
                'position': ChartPosition.bottom,
              },
              'y': <String, Object?>{
                'type': 'category',
                'position': ChartPosition.left,
                'min': '2',
                'max': '4',
              },
            },
          },
        });

        final yScale = chart.scales['y']!;

        expect(yScale.getPixelForValue(1), toBeCloseToPixel(32));
        expect(yScale.getPixelForValue(3), toBeCloseToPixel(482));

        yScale.optionsView['offset'] = true;
        chart.update();

        expect(yScale.getPixelForValue(1), toBeCloseToPixel(107));
        expect(yScale.getPixelForValue(3), toBeCloseToPixel(407));
      },
    );

    testWidgets(
      'Should get the correct pixel for an object value when horizontal',
      (tester) async {
        final chart = _acquire(
          ChartConfig(
            type: ChartKind.line,
            datasets: [
              LineDataset(
                xAxisID: 'x',
                yAxisID: 'y',
                points: [
                  DataPoint(0, 10),
                  DataPoint(1, 5),
                  DataPoint(2, 0),
                  DataPoint(3, 25),
                  DataPoint(0, 78),
                ],
              ),
            ],
            labels: const [0, 1, 2, 3],
            scales: const {
              'x': CategoryAxis(position: ChartPosition.bottom),
              'y': LinearAxis(),
            },
          ),
        );

        final xScale = chart.scales['x']!;
        expect(xScale.getPixelForValue(0), toBeCloseToPixel(29));
        expect(xScale.getPixelForValue(3), toBeCloseToPixel(506));
        expect(xScale.getPixelForValue(4), toBeCloseToPixel(664));
      },
    );

    // A Map config: `data.yLabels` has no typed form.
    testWidgets(
      'Should get the correct pixel for an object value when vertical',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'xAxisID': 'x',
                'yAxisID': 'y',
                'data': <Object?>[
                  <String, Object?>{'x': 0, 'y': 2},
                  <String, Object?>{'x': 1, 'y': 4},
                  <String, Object?>{'x': 2, 'y': 0},
                  <String, Object?>{'x': 3, 'y': 3},
                  <String, Object?>{'x': 0, 'y': 1},
                ],
              },
            ],
            'labels': <Object?>[0, 1, 2, 3],
            'yLabels': <Object?>[0, 1, 2, 3, 4],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{
                'type': 'category',
                'position': ChartPosition.bottom,
              },
              'y': <String, Object?>{
                'type': 'category',
                'position': ChartPosition.left,
              },
            },
          },
        });

        final yScale = chart.scales['y']!;
        expect(yScale.getPixelForValue(0), toBeCloseToPixel(32));
        expect(yScale.getPixelForValue(4), toBeCloseToPixel(483));
      },
    );

    testWidgets(
      'Should get the correct pixel for an object value in a bar chart',
      (tester) async {
        final chart = _acquire(
          ChartConfig(
            type: ChartKind.bar,
            datasets: [
              BarDataset(
                xAxisID: 'x',
                yAxisID: 'y',
                points: [
                  DataPoint(0, 10),
                  DataPoint(1, 5),
                  DataPoint(2, 0),
                  DataPoint(3, 25),
                  DataPoint(0, 78),
                ],
              ),
            ],
            labels: const [0, 1, 2, 3],
            scales: const {
              'x': CategoryAxis(position: ChartPosition.bottom),
              'y': LinearAxis(),
            },
          ),
        );

        final xScale = chart.scales['x']!;
        expect(xScale.getPixelForValue(0), toBeCloseToPixel(89));
        expect(xScale.getPixelForValue(3), toBeCloseToPixel(451));
        expect(xScale.getPixelForValue(4), toBeCloseToPixel(572));
      },
    );

    testWidgets(
      'Should get the correct pixel for an object value in a horizontal bar '
      'chart',
      (tester) async {
        final chart = _acquire(
          ChartConfig(
            type: ChartKind.bar,
            datasets: [
              BarDataset(
                points: [
                  DataPoint(10, 0),
                  DataPoint(5, 1),
                  DataPoint(0, 2),
                  DataPoint(25, 3),
                  DataPoint(78, 0),
                ],
              ),
            ],
            labels: const [0, 1, 2, 3],
            indexAxis: const YAxis(),
            scales: const {
              'x': LinearAxis(position: ChartPosition.bottom),
              'y': CategoryAxis(),
            },
          ),
        );

        final yScale = chart.scales['y']!;
        expect(yScale.getPixelForValue(0), toBeCloseToPixel(88));
        expect(yScale.getPixelForValue(3), toBeCloseToPixel(426));
        expect(yScale.getPixelForValue(4), toBeCloseToPixel(538));
      },
    );

    testWidgets(
      'Should be consistent on pixels and values with autoSkipped ticks',
      (tester) async {
        final labels = <Object>[];
        for (var i = 0; i < 50; i++) {
          labels.add('very long label $i');
        }
        final chart = _acquire(
          ChartConfig(
            type: ChartKind.bar,
            labels: labels,
            datasets: const [
              BarDataset(data: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]),
            ],
          ),
        );

        final scale = chart.scales['x']!;
        expect(scale.ticks!.length, lessThan(50));

        var x = 0.0;
        for (var i = 0; i < 50; i++) {
          final x2 = scale.getPixelForValue(scaleValueOf(scale, labels[i]));
          final x3 = scale.getPixelForValue(i.toDouble());
          expect(x2, _equalsNumber(x3));
          expect(x2, greaterThan(x));
          expect(scale.getValueForPixel(x2), i);
          x = x2;
        }
      },
    );

    // A Map config: the data is an object by label, which a typed dataset
    // cannot hold.
    testWidgets('Should bound to ticks/data', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'labels': <Object?>['a', 'b', 'c', 'd'],
          'datasets': <Object?>[
            <String, Object?>{
              'data': <String, Object?>{'b': 1, 'c': 99},
            },
          ],
        },
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'x': <String, Object?>{
              'type': 'category',
              'bounds': ScaleBounds.data,
            },
          },
        },
      });

      expect(chart.scales['x']!.min, _equalsNumber(1));
      expect(chart.scales['x']!.max, _equalsNumber(2));

      (jsGet(jsGet(chart.options, 'scales'), 'x')! as JsObjectFace)['bounds'] =
          ScaleBounds.ticks;
      chart.update();

      expect(chart.scales['x']!.min, _equalsNumber(0));
      expect(chart.scales['x']!.max, _equalsNumber(3));
    });
  });
}
