// Ported from Chart.js v4.6.1 test/specs/core.scale.tests.js (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-title-text-lines, the lines of a title text.
// DIVERGES(chartjs): adapt-scale-display-enum, the scale display values.
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

// The spec reads Chart.defaults, which is `defaults` of core.defaults.dart.
// Its chart cases call `acquireChart`. Thus they are `testWidgets` cases, and
// the file runs on the VM (Chart.js ADR 0022, sections 1 and 2).
// flutter_test_config.dart registers the built-in components before main().
// Thus the category and linear scales of phase 6 and the controllers of
// phase 7 are in the registry.
//
// `Object.keys(chart.scales).sort()` is `jsSort` of the keys with
// `String.compareTo`: the keys are strings, and the default comparator of
// `Array.prototype.sort` and `String.compareTo` both compare the UTF-16 code
// units.
// `expect(fn).not.toThrow()` is `expect(fn, returnsNormally)`.
//
// An option function of the spec, for example `afterBuildTicks`, is a Dart
// closure. The scale calls it through `jsCall` (Chart.js ADR 0043).
// `scale.ticks.slice(1)` is `scale.ticks!.sublist(1)`. `expect(fn).toThrow()`
// with no argument is `throwsA(anything)`.
//
// A class `class X extends Chart.Scale` of the spec is a Dart subclass of
// Scale and a class value that constructs it: `JsClass('X', superclass:
// Scale.jsClass, construct: ...)`. The static properties that the spec writes
// after the class are writes with `operator []=` (Chart.js ADR 0020, section
// 8). Dart has no local classes, so the classes of the spec are private
// classes of this file. `chart.scales.x` is `chart.scales['x']!`, and
// `scale._layers()` is `scale.layers!()` (Chart.js ADR 0012, Underscore
// members). `new Error(m)` is a StateError with the message m.
//
// The other spec forms:
// - `xScale.ctx = window.createMockContext()` is
//   `xScale.ctx = createMockContext()` of
//   package:chartjs_test_utils/pure.dart. A call of `getCalls()` is a Map
//   with the keys `name` and `args`.
// - `toEqual` is `equals`. `toEqual` of an option scope is a compare of
//   its `Object.keys` (`jsKeys` of its face) and of each value that its
//   face reads. `toBeCloseTo(e, p)` is
//   `closeTo(e, 5e-(p + 1))`.
// - `new Array(300).fill(value)` is `List.filled(300, value)`.
// - `parseFloat(value.toFixed(2))` is
//   `double.parse(value.toStringAsFixed(2))`.
// - A chart config is a typed `ChartConfig` (Chart.js ADR 0052). The
//   three cases of a custom scale class keep a Map config: the scale type
//   of the class has no axis class. The options with no parameter go
//   through `extra`. The case with no title stroke reads the title options
//   through the face: `undefined` has no typed form.

/// The chart of the typed [config] (Chart.js ADR 0052).
Chart _acquire(ChartConfig config, [Map<String, Object?>? options]) =>
    acquireChartRoot(ChartConfigLowering(config).lower(), options);

/// The member read `object.key` of the option object [object]: a resolver,
/// read through its face (Chart.js ADR 0054 §5).
Object? _member(Object? object, String key) => (object! as JsObjectFace)[key];

/// core.scale.tests.js:1-3 `getLabels(scale)`: the labels of the ticks of
/// [scale].
List<Object?> _getLabels(Scale scale) {
  return scale.ticks!.map(upstreamTickLabel).toList();
}

/// core.scale.tests.js:514-519 `class CustomScale extends Chart.Scale`.
final class _CustomScale(super.cfg) extends Scale {
  @override
  void draw([ChartArea? chartArea]) {}

  /// core.scale.tests.js:516 `convertTicksToLabels()`. Scale of v4.5.1 has
  /// no member with this name, and nothing calls it.
  List<Object?> convertTicksToLabels() {
    return ['tick'];
  }
}

/// core.scale.tests.js:547-552 `class CustomScale1 extends Chart.Scale`.
final class _CustomScale1(super.cfg) extends Scale {
  @override
  void draw([ChartArea? chartArea]) {}

  /// core.scale.tests.js:549 `convertTicksToLabels()`. Scale of v4.5.1 has
  /// no member with this name, and nothing calls it.
  List<Object?> convertTicksToLabels() {
    return ['tick'];
  }
}

/// core.scale.tests.js:580-582 `class CustomScale2 extends Chart.Scale`.
final class _CustomScale2(super.cfg) extends Scale {
  @override
  void draw([ChartArea? chartArea]) {}
}

/// The eight items of `gridLineTests` (core.scale.tests.js:110-150). The
/// last four repeat the flags of the first four with one label. Their test
/// names get ` #2` (porting-flow.md section 1, step 5).
const List<
  ({
    List<Object> labels,
    bool offsetGridLines,
    bool offset,
    List<Object?> expected,
  })
>
_gridLineTests = [
  (
    labels: ['tick1', 'tick2', 'tick3', 'tick4', 'tick5'],
    offsetGridLines: false,
    offset: false,
    expected: [0.5, 128.5, 256.5, 384.5, 512.5],
  ),
  (
    labels: ['tick1', 'tick2', 'tick3', 'tick4', 'tick5'],
    offsetGridLines: false,
    offset: true,
    expected: [51.5, 153.5, 256.5, 358.5, 460.5],
  ),
  (
    labels: ['tick1', 'tick2', 'tick3', 'tick4', 'tick5'],
    offsetGridLines: true,
    offset: false,
    expected: [64.5, 192.5, 320.5, 448.5],
  ),
  (
    labels: ['tick1', 'tick2', 'tick3', 'tick4', 'tick5'],
    offsetGridLines: true,
    offset: true,
    expected: [0.5, 102.5, 204.5, 307.5, 409.5, 512.5],
  ),
  (labels: ['tick1'], offsetGridLines: false, offset: false, expected: [0.5]),
  (labels: ['tick1'], offsetGridLines: false, offset: true, expected: [256.5]),
  (labels: ['tick1'], offsetGridLines: true, offset: false, expected: [512.5]),
  (
    labels: ['tick1'],
    offsetGridLines: true,
    offset: true,
    expected: [0.5, 512.5],
  ),
];

/// `x.args[index]` of a call of the mock context.
Object? _arg(ContextCall call, int index) =>
    (call['args']! as List<Object?>)[index];

/// A case of `gridLineTests` with a line at 0: `roundToDouble()` places the
/// line at -0.5, where upstream places it at 0.5 (Chart.js ADR 0146 §7).
void _skipGridLineCase(String name) =>
    test(name, () {}, skip: 'diverges: adapt-dart-round');

/// The names of the cases that `gridLineTests.forEach` makes from [prefix],
/// with ` #2` for a repeated name.
List<String> _gridLineNames(String prefix) {
  final names = <String>[];
  for (final test in _gridLineTests) {
    final name =
        '$prefix when offsetGridLines is ${test.offsetGridLines} and offset '
        'is ${test.offset}';
    names.add(names.contains(name) ? '$name #2' : name);
  }
  return names;
}

void main() {
  group('Core.scale', () {
    group('auto', fixture.specs('core.scale'));

    test('should provide default scale label options', () {
      final scale = _member(defaults, 'scale');
      final title = _member(scale, 'title')! as JsObjectFace;
      expect(
        title.jsKeys(),
        unorderedEquals(<String>['color', 'display', 'text', 'padding']),
      );
      expect(title['color'], equals(defaults['color']));
      expect(title['display'], equals(false));
      expect(title['text'], equals(<String>['']));
      expect(
        title['padding'],
        equals(const EdgeInsets.only(top: 4, bottom: 4)),
      );
    });

    group('displaying xAxis ticks with autoSkip=true', () {
      Chart getChart(List<Object> labels, List<num?> data) {
        return _acquire(
          ChartConfig(
            type: ChartKind.line,
            labels: labels,
            datasets: [LineDataset(data: data)],
            scales: const {'x': CategoryAxis(ticks: AxisTicks(autoSkip: true))},
          ),
        );
      }

      Chart getChartBigData(int maxTicksLimit) {
        return _acquire(
          ChartConfig(
            type: ChartKind.line,
            labels: List<Object>.filled(300, 'red'),
            datasets: [LineDataset(data: List<num?>.filled(300, 5))],
            scales: {
              'x': CategoryAxis(
                ticks: AxisTicks(
                  autoSkip: true,
                  extra: {'maxTicksLimit': maxTicksLimit},
                ),
              ),
            },
          ),
        );
      }

      Tick lastTick(Chart chart) {
        final xAxis = chart.scales['x']!;
        final ticks = xAxis.getTicks()!;
        return ticks[ticks.length - 1];
      }

      testWidgets(
        'should use autoSkip amount of ticks when maxTicksLimit is set to a '
        'larger number as autoSkip calculation',
        (tester) async {
          final chart = getChartBigData(300);
          expect(chart.scales['x']!.ticks!.length, equals(20));
        },
      );

      testWidgets(
        'should use maxTicksLimit amount of ticks when maxTicksLimit is set '
        'to a smaller number as autoSkip calculation',
        (tester) async {
          final chart = getChartBigData(3);
          expect(chart.scales['x']!.ticks!.length, equals(3));
        },
      );

      testWidgets(
        'should display the last tick if it fits evenly with other ticks',
        (tester) async {
          final chart = getChart(
            [
              'January 2018', 'February 2018', 'March 2018', 'April 2018', //
              'May 2018', 'June 2018', 'July 2018', 'August 2018',
              'September 2018',
            ],
            [12, 19, 3, 5, 2, 3, 7, 8, 9],
          );

          expect(upstreamTickLabel(lastTick(chart)), equals('September 2018'));
        },
      );

      testWidgets(
        'should not display the last tick if it does not fit evenly',
        (tester) async {
          final chart = getChart(
            [
              'January 2018', 'February 2018', 'March 2018', 'April 2018', //
              'May 2018', 'June 2018', 'July 2018', 'August 2018',
              'September 2018', 'October 2018', 'November 2018',
              'December 2018',
              'January 2019', 'February 2019', 'March 2019', 'April 2019',
              'May 2019', 'June 2019', 'July 2019', 'August 2019',
              'September 2019', 'October 2019', 'November 2019',
              'December 2019',
              'January 2020', 'February 2020', 'March 2020', 'April 2020',
            ],
            [
              1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, //
              6, 6, 6, 6, 7, 7, 7, 7,
            ],
          );

          expect(upstreamTickLabel(lastTick(chart)), equals('March 2020'));
        },
      );
    });

    final horizontalNames = _gridLineNames(
      'should get the correct pixels for gridLine(s) for the horizontal scale',
    );
    for (var t = 0; t < _gridLineTests.length; t++) {
      // A grid line at 0 rounds -0.5 away from zero: it draws at -0.5, where
      // upstream draws it at 0.5. test/port/helpers/helpers.canvas_test.dart
      // pins it.
      if (const {0, 4, 7}.contains(t)) {
        _skipGridLineCase(horizontalNames[t]);
        continue;
      }
      final test = _gridLineTests[t];
      testWidgets(horizontalNames[t], (tester) async {
        final chart = _acquire(
          ChartConfig(
            type: ChartKind.line,
            datasets: const [LineDataset(data: [])],
            labels: test.labels,
            scales: {
              'x': CategoryAxis(
                grid: AxisGrid(offset: test.offsetGridLines, drawTicks: false),
                ticks: const AxisTicks(display: false),
                extra: {'offset': test.offset},
              ),
              'y': const LinearAxis(display: ScaleDisplay.off),
            },
            extra: const {
              'plugins': {'legend': false},
            },
          ),
        );

        final xScale = chart.scales['x']!;
        final ctx = createMockContext();
        xScale.ctx = ctx;
        chart.draw();

        expect(
          ctx
              .getCalls()
              .where((x) => x['name'] == 'moveTo' && _arg(x, 1) == 0)
              .map((x) => _arg(x, 0))
              .toList(),
          equals(test.expected),
        );
      });
    }

    // Each line starts at x = 0, which rounds -0.5 away from zero: the line
    // starts at -0.5, where upstream starts it at 0.5.
    // test/port/helpers/helpers.canvas_test.dart pins it.
    _gridLineNames(
      'should get the correct pixels for gridLine(s) for the vertical scale',
    ).forEach(_skipGridLineCase);

    testWidgets('should add the correct padding for long tick labels', (
      tester,
    ) async {
      final chart = _acquire(
        const ChartConfig(
          type: ChartKind.line,
          labels: ['This is a very long label', 'This is a very long label'],
          datasets: [
            LineDataset(data: [0, 1]),
          ],
          scales: {'y': LinearAxis(display: ScaleDisplay.off)},
          extra: {
            'plugins': {'legend': false},
          },
        ),
        {
          'canvas': <String, Object?>{'height': 100, 'width': 200},
        },
      );

      final scale = chart.scales['x']!;
      expect(scale.left, greaterThan(100));
      expect(scale.right, greaterThan(190));
    });

    group('given the axes display option is set to auto', () {
      group('for the x axes', () {
        testWidgets(
          'should draw the axes if at least one associated dataset is '
          'visible',
          (tester) async {
            final chart = _acquire(
              const ChartConfig(
                type: ChartKind.line,
                datasets: [
                  LineDataset(
                    data: [100, 200, 100, 50],
                    hidden: true,
                    extra: {
                      'xAxisId': 'foo',
                      'labels': ['Q1', 'Q2', 'Q3', 'Q4'],
                    },
                  ),
                  LineDataset(
                    data: [100, 200, 100, 50],
                    extra: {
                      'xAxisId': 'foo',
                      'labels': ['Q1', 'Q2', 'Q3', 'Q4'],
                    },
                  ),
                ],
                scales: {
                  'x': CategoryAxis(display: ScaleDisplay.auto),
                  'y': CategoryAxis(),
                },
              ),
            );

            final scale = chart.scales['x']!;
            final ctx = createMockContext();
            scale.ctx = ctx;
            chart.draw();

            expect(ctx.getCalls().length, greaterThan(0));
            expect(scale.height, greaterThan(0));
          },
        );

        testWidgets(
          'should not draw the axes if no associated datasets are visible',
          (tester) async {
            final chart = _acquire(
              const ChartConfig(
                type: ChartKind.line,
                datasets: [
                  LineDataset(
                    data: [100, 200, 100, 50],
                    hidden: true,
                    extra: {
                      'xAxisId': 'foo',
                      'labels': ['Q1', 'Q2', 'Q3', 'Q4'],
                    },
                  ),
                ],
                scales: {'x': CategoryAxis(display: ScaleDisplay.auto)},
              ),
            );

            final scale = chart.scales['x']!;
            final ctx = createMockContext();
            scale.ctx = ctx;
            chart.draw();

            expect(ctx.getCalls().length, 0);
            expect(scale.height, 0);
          },
        );
      });

      group('for the y axes', () {
        testWidgets(
          'should draw the axes if at least one associated dataset is '
          'visible',
          (tester) async {
            final chart = _acquire(
              const ChartConfig(
                type: ChartKind.line,
                datasets: [
                  LineDataset(
                    data: [100, 200, 100, 50],
                    hidden: true,
                    extra: {
                      'yAxisId': 'foo',
                      'labels': ['Q1', 'Q2', 'Q3', 'Q4'],
                    },
                  ),
                  LineDataset(
                    data: [100, 200, 100, 50],
                    extra: {
                      'yAxisId': 'foo',
                      'labels': ['Q1', 'Q2', 'Q3', 'Q4'],
                    },
                  ),
                ],
                scales: {'y': LinearAxis(display: ScaleDisplay.auto)},
              ),
            );

            final scale = chart.scales['y']!;
            final ctx = createMockContext();
            scale.ctx = ctx;
            chart.draw();

            expect(ctx.getCalls().length, greaterThan(0));
            expect(scale.width, greaterThan(0));
          },
        );

        testWidgets(
          'should not draw the axes if no associated datasets are visible',
          (tester) async {
            final chart = _acquire(
              const ChartConfig(
                type: ChartKind.line,
                datasets: [
                  LineDataset(
                    data: [100, 200, 100, 50],
                    hidden: true,
                    extra: {
                      'yAxisId': 'foo',
                      'labels': ['Q1', 'Q2', 'Q3', 'Q4'],
                    },
                  ),
                ],
                scales: {'y': LinearAxis(display: ScaleDisplay.auto)},
              ),
            );

            final scale = chart.scales['y']!;
            final ctx = createMockContext();
            scale.ctx = ctx;
            chart.draw();

            expect(ctx.getCalls().length, 0);
            expect(scale.width, 0);
          },
        );
      });
    });

    group('afterBuildTicks', () {
      testWidgets('should allow filtering of ticks', (tester) async {
        final labels = <Object>['tick1', 'tick2', 'tick3', 'tick4', 'tick5'];
        final chart = _acquire(
          ChartConfig(
            type: ChartKind.line,
            datasets: const [],
            scales: {
              'x': CategoryAxis(
                labels: labels,
                extra: {
                  'afterBuildTicks': (Scale scale) {
                    scale.ticks = scale.ticks!.sublist(1);
                  },
                },
              ),
            },
          ),
        );

        final scale = chart.scales['x']!;
        expect(_getLabels(scale), labels.sublist(1));
      });

      testWidgets('should allow no return value from callback', (tester) async {
        final labels = <Object>['tick1', 'tick2', 'tick3', 'tick4', 'tick5'];
        final chart = _acquire(
          ChartConfig(
            type: ChartKind.line,
            datasets: const [],
            scales: {
              'x': CategoryAxis(
                labels: labels,
                extra: {'afterBuildTicks': (_) {}},
              ),
            },
          ),
        );

        final scale = chart.scales['x']!;
        expect(_getLabels(scale), labels);
      });

      testWidgets('should allow empty ticks', (tester) async {
        final labels = <Object>['tick1', 'tick2', 'tick3', 'tick4', 'tick5'];
        final chart = _acquire(
          ChartConfig(
            type: ChartKind.line,
            datasets: const [],
            scales: {
              'x': CategoryAxis(
                labels: labels,
                extra: {
                  'afterBuildTicks': (Scale scale) {
                    scale.ticks = [];
                  },
                },
              ),
            },
          ),
        );

        final scale = chart.scales['x']!;
        expect(scale.ticks!.length, 0);
      });
    });

    group('_layers', () {
      testWidgets('should default to three layers', (tester) async {
        final chart = _acquire(
          const ChartConfig(
            type: ChartKind.line,
            datasets: [],
            scales: {'x': LinearAxis()},
          ),
        );

        final scale = chart.scales['x']!;
        expect(scale.layers!().length, 3);
      });

      testWidgets(
        'should create the chart with custom scale ids without axis or '
        'position options',
        (tester) async {
          Chart createChart() {
            return _acquire(
              ChartConfig(
                type: ChartKind.scatter,
                datasets: [
                  ScatterDataset(
                    points: [DataPoint(0, 0), DataPoint(1, 1), DataPoint(2, 2)],
                    xAxisID: 'customIDx',
                    yAxisID: 'customIDy',
                  ),
                ],
                scales: const {
                  'customIDx': LinearAxis(display: ScaleDisplay.off),
                  'customIDy': LinearAxis(display: ScaleDisplay.off),
                },
              ),
            );
          }

          expect(createChart, returnsNormally);
        },
      );

      // Native scopes preserve the custom scale type.
      testWidgets('should default to one layer for custom scales', (
        tester,
      ) async {
        final customScale = JsClass(
          'CustomScale',
          superclass: Scale.jsClass,
          construct: (newTarget, args) => _CustomScale(scaleCfgArg(args)),
        );
        customScale['id'] = 'customScale';
        customScale['defaults'] = <String, Object?>{};
        Chart.register([customScale]);

        final chart = acquireChartRoot(
          ChartConfigurationScope()
            ..type = 'line'
            ..options = mergeExtra(ChartOptionsScope(), <String, Object?>{
              'scales': <String, Object?>{
                'x': <String, Object?>{
                  'type': 'customScale',
                  'grid': <String, Object?>{'z': 10},
                  'ticks': <String, Object?>{'z': 20},
                },
              },
            }),
        );

        final scale = chart.scales['x']!;
        expect(scale.layers!().length, 1);
        expect(scale.layers!()[0].z, 20);
      });

      // Native scopes preserve the custom scale type.
      testWidgets('should default to one layer for custom scales for axis', (
        tester,
      ) async {
        final customScale1 = JsClass(
          'CustomScale1',
          superclass: Scale.jsClass,
          construct: (newTarget, args) => _CustomScale1(scaleCfgArg(args)),
        );
        customScale1['id'] = 'customScale1';
        customScale1['defaults'] = <String, Object?>{'axis': const XAxis()};
        Chart.register([customScale1]);

        final chart = acquireChartRoot(
          ChartConfigurationScope()
            ..type = 'line'
            ..options = mergeExtra(ChartOptionsScope(), <String, Object?>{
              'scales': <String, Object?>{
                'my': <String, Object?>{
                  'type': 'customScale1',
                  'grid': <String, Object?>{'z': 10},
                  'ticks': <String, Object?>{'z': 20},
                },
              },
            }),
        );

        final scale = chart.scales['my']!;
        expect(scale.layers!().length, 1);
        expect(scale.layers!()[0].z, 20);
      });

      // Native scopes preserve the custom scale type.
      testWidgets(
        'should fail for custom scales without any axis or position',
        (tester) async {
          final customScale2 = JsClass(
            'CustomScale2',
            superclass: Scale.jsClass,
            construct: (newTarget, args) => _CustomScale2(scaleCfgArg(args)),
          );
          customScale2['id'] = 'customScale2';
          customScale2['defaults'] = <String, Object?>{};
          Chart.register([customScale2]);

          Chart createChart() {
            return acquireChartRoot(
              ChartConfigurationScope()
                ..type = 'line'
                ..options = mergeExtra(ChartOptionsScope(), <String, Object?>{
                  'scales': <String, Object?>{
                    'my': <String, Object?>{'type': 'customScale2'},
                  },
                }),
            );
          }

          expect(
            createChart,
            throwsA(
              isA<StateError>().having(
                (error) => error.message,
                'message',
                "Cannot determine type of 'my' axis. Please provide 'axis' "
                    "or 'position' option.",
              ),
            ),
          );
        },
      );

      testWidgets(
        'should return 3 layers when z is not equal between ticks and grid',
        (tester) async {
          var chart = _acquire(
            const ChartConfig(
              type: ChartKind.line,
              datasets: [],
              scales: {
                'x': LinearAxis(ticks: AxisTicks(extra: {'z': 10})),
              },
            ),
          );

          expect(chart.scales['x']!.layers!().length, 3);

          chart = _acquire(
            const ChartConfig(
              type: ChartKind.line,
              datasets: [],
              scales: {
                'x': LinearAxis(grid: AxisGrid(extra: {'z': 11})),
              },
            ),
          );

          expect(chart.scales['x']!.layers!().length, 3);

          chart = _acquire(
            const ChartConfig(
              type: ChartKind.line,
              datasets: [],
              scales: {
                'x': LinearAxis(
                  ticks: AxisTicks(extra: {'z': 10}),
                  grid: AxisGrid(extra: {'z': 11}),
                ),
              },
            ),
          );

          expect(chart.scales['x']!.layers!().length, 3);
        },
      );
    });

    group('min and max', () {
      testWidgets('should be limited to visible data', (tester) async {
        final chart = _acquire(
          ChartConfig(
            type: ChartKind.scatter,
            datasets: [
              ScatterDataset(
                points: [DataPoint(100, 100), DataPoint(-100, -100)],
              ),
              ScatterDataset(points: [DataPoint(10, 10), DataPoint(-10, -10)]),
            ],
            scales: const {
              'x': LinearAxis(min: -20, max: 20, extra: {'id': 'x'}),
              'y': LinearAxis(extra: {'id': 'y'}),
            },
          ),
        );

        expect(chart.scales['x']!.min, equals(-20));
        expect(chart.scales['x']!.max, equals(20));
        expect(chart.scales['y']!.min, equals(-10));
        expect(chart.scales['y']!.max, equals(10));
      });
    });

    group('overrides', () {
      testWidgets('should create new scale', (tester) async {
        final chart = _acquire(
          ChartConfig(
            type: ChartKind.scatter,
            datasets: [
              ScatterDataset(
                points: [DataPoint(100, 100), DataPoint(-100, -100)],
              ),
              ScatterDataset(points: [DataPoint(10, 10), DataPoint(-10, -10)]),
            ],
            scales: const {'x2': LinearAxis(min: -20, max: 20)},
          ),
        );

        expect(
          jsSort(chart.scales.keys.toList(), (a, b) => a.compareTo(b)),
          equals(<Object?>['x', 'x2', 'y']),
        );
      });

      testWidgets('should create new scale with custom name', (tester) async {
        final chart = _acquire(
          ChartConfig(
            type: ChartKind.scatter,
            datasets: [
              ScatterDataset(
                points: [DataPoint(100, 100), DataPoint(-100, -100)],
              ),
              ScatterDataset(points: [DataPoint(10, 10), DataPoint(-10, -10)]),
            ],
            scales: const {
              'scaleX': LinearAxis(min: -20, max: 20, extra: {'axis': XAxis()}),
            },
          ),
        );

        expect(
          jsSort(chart.scales.keys.toList(), (a, b) => a.compareTo(b)),
          equals(<Object?>['scaleX', 'x', 'y']),
        );
      });

      // :743-763 the Error comes from determineAxis (core.config.js:52), in
      // the first loop of mergeScaleConfig. That loop runs in the Config
      // constructor, before the chart reads its controller. It needs
      // `defaults.scales.linear`: without it, determineAxis throws a
      // TypeError first. The bare `toThrow()` of upstream can only catch the
      // determineAxis Error. The matcher checks the message of
      // determineAxis, so another Error does not pass the case.
      testWidgets(
        'should throw error on scale with custom name without axis type',
        (tester) async {
          expect(
            () => _acquire(
              ChartConfig(
                type: ChartKind.scatter,
                datasets: [
                  ScatterDataset(
                    points: [DataPoint(100, 100), DataPoint(-100, -100)],
                  ),
                  ScatterDataset(
                    points: [DataPoint(10, 10), DataPoint(-10, -10)],
                  ),
                ],
                scales: const {'scaleX': LinearAxis(min: -20, max: 20)},
              ),
            ),
            throwsA(
              isA<StateError>().having(
                (error) => error.message,
                'message',
                "Cannot determine type of 'scaleX' axis. Please provide "
                    "'axis' or 'position' option.",
              ),
            ),
          );
        },
      );

      testWidgets('should read options first to determine axis', (
        tester,
      ) async {
        final chart = _acquire(
          ChartConfig(
            type: ChartKind.scatter,
            datasets: [
              ScatterDataset(
                points: [DataPoint(100, 100), DataPoint(-100, -100)],
              ),
              ScatterDataset(points: [DataPoint(10, 10), DataPoint(-10, -10)]),
            ],
            scales: const {
              'xavier': LinearAxis(min: -20, max: 20, extra: {'axis': YAxis()}),
            },
          ),
        );

        expect(chart.scales['xavier']!.axis, isA<YAxis>());
      });

      testWidgets('should center labels when rotated in x axis', (
        tester,
      ) async {
        final chart = _acquire(
          const ChartConfig(
            type: ChartKind.line,
            labels: ['Red', 'Blue', 'Yellow', 'Green', 'Purple', 'Orange'],
            datasets: [
              LineDataset(label: '# of Votes', data: [12, 19, 3, 5, 2, 3]),
            ],
            scales: {
              'x': CategoryAxis(ticks: AxisTicks(extra: {'minRotation': 90})),
            },
          ),
        );
        // `parseFloat(value.toFixed(2))`.
        double mapper(LabelItem item) =>
            double.parse(item.options.translation!.$1.toStringAsFixed(2));
        const expected = <double>[20.15, 113.6, 207.05, 300.5, 393.95, 487.4];
        final actual = chart.scales['x']!.getLabelItems().map(mapper).toList();
        final len = expected.length;
        for (var i = 0; i < len; ++i) {
          final actualValue = actual[i];
          final expectedValue = expected[i];
          expect(actualValue, closeTo(expectedValue, 0.05));
        }
      });
    });

    // :820-899. The charts have no datasets. Thus they need the linear
    // scale of phase 6 and no controller of phase 7. `scale.options.title`
    // is a resolver, and `toBeUndefined()` is `same(undefined)`.
    group('Scale Title stroke', () {
      /// core.scale.tests.js:821-849 `getChartWithScaleTitleStroke()`.
      Chart getChartWithScaleTitleStroke() {
        return _acquire(
          const ChartConfig(
            type: ChartKind.line,
            datasets: [],
            scales: {
              'x': LinearAxis(
                title: AxisTitle(
                  display: true,
                  text: ['title-x'],
                  color: ChartPaint.solid(
                    native_ui.Color.fromRGBO(221, 221, 221, 1),
                  ),
                  extra: {
                    'strokeWidth': 1,
                    'strokeColor': ChartPaint.solid(
                      native_ui.Color.fromRGBO(51, 51, 51, 1),
                    ),
                  },
                ),
              ),
              'y': LinearAxis(
                title: AxisTitle(
                  display: true,
                  text: ['title-y'],
                  color: ChartPaint.solid(
                    native_ui.Color.fromRGBO(221, 221, 221, 1),
                  ),
                  extra: {
                    'strokeWidth': 2,
                    'strokeColor': ChartPaint.solid(
                      native_ui.Color.fromRGBO(34, 34, 34, 1),
                    ),
                  },
                ),
              ),
            },
          ),
        );
      }

      /// core.scale.tests.js:851-875 `getChartWithoutScaleTitleStroke()`.
      Chart getChartWithoutScaleTitleStroke() {
        return _acquire(
          const ChartConfig(
            type: ChartKind.line,
            datasets: [],
            scales: {
              'x': LinearAxis(
                title: AxisTitle(
                  display: true,
                  text: ['title-x'],
                  color: ChartPaint.solid(
                    native_ui.Color.fromRGBO(221, 221, 221, 1),
                  ),
                ),
              ),
              'y': LinearAxis(
                title: AxisTitle(
                  display: true,
                  text: ['title-y'],
                  color: ChartPaint.solid(
                    native_ui.Color.fromRGBO(221, 221, 221, 1),
                  ),
                ),
              ),
            },
          ),
        );
      }

      testWidgets('should draw a scale title stroke when provided x-axis', (
        tester,
      ) async {
        final chart = getChartWithScaleTitleStroke();
        final scale = chart.scales['x']!;
        expect(
          scale.options.title.strokeColor,
          const ChartPaint.solid(native_ui.Color.fromRGBO(51, 51, 51, 1)),
        );
        expect(scale.options.title.strokeWidth, 1);
      });

      testWidgets('should draw a scale title stroke when provided y-axis', (
        tester,
      ) async {
        final chart = getChartWithScaleTitleStroke();
        final scale = chart.scales['y']!;
        expect(
          scale.options.title.strokeColor,
          const ChartPaint.solid(native_ui.Color.fromRGBO(34, 34, 34, 1)),
        );
        expect(scale.options.title.strokeWidth, 2);
      });

      testWidgets('should not draw a scale title stroke when not provided', (
        tester,
      ) async {
        final chart = getChartWithoutScaleTitleStroke();
        final scales = chart.scales;
        final yTitle = scales['y']!.optionsView['title'];
        final xTitle = scales['x']!.optionsView['title'];
        expect(_member(yTitle, 'strokeColor'), same(undefined));
        expect(_member(yTitle, 'strokeWidth'), same(undefined));
        expect(_member(xTitle, 'strokeColor'), same(undefined));
        expect(_member(xTitle, 'strokeWidth'), same(undefined));
      });
    });
  });
}
