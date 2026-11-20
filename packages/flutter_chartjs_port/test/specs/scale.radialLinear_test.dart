// Ported from Chart.js v4.6.1 test/specs/scale.radialLinear.tests.js (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-dash-lists, the dash patterns are lists of doubles.
// DIVERGES(chartjs): adapt-scale-display-enum, the scale display values.
// DIVERGES(chartjs): adapt-direct-colors, native color test inputs.
@TestOn('vm')
library;

import 'dart:math' as math;
import 'dart:ui' as native_ui;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter/painting.dart' show EdgeInsets;
// The spec reads the registry, the defaults and the charts of
// flutter_chartjs_port, which does not export lib/src yet.
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/index.dart' as fixture;
import '../support/tick_label.dart';

// `Chart.registry` and `Chart.defaults` are the statics of Chart of
// core.controller.dart. The two cases without a chart read only the
// registry and `Chart.defaults.scales.radialLinear`. They need the built-in
// scales that flutter_test_config.dart registers. Thus the file does not
// call `setUpSpecs()`. It runs on the VM, because core.controller.dart
// reaches the platform layer.
//
// Each chart case has the type `radar` or `polarArea`. The scale `r` gets
// the type `radialLinear` from the overrides of the controller. The chart
// cases are `testWidgets` cases with `acquireChart` (Chart.js ADR 0022,
// section 2). The case "Should ensure that the scale has a max and min that
// are not equal" has no dataset, but it needs the radar overrides too:
// without them, the scale has no radialLinear defaults. Three cases also
// need the legend plugin, which flutter_test_config.dart registers. The
// legend makes the chart area smaller, and the cases compare `drawingArea`
// (215), `yCenter` (280) and the values that come from them. Without the
// legend, these are 231 and 264.
//
// The spec forms:
// - A property chain of the spec, for example `Chart.defaults.scales`, is a
//   chain of `jsGet`.
// - `typeof x === 'function'` is `isA<JsClass>()`: the class value of a
//   scale is a `JsClass` (Chart.js ADR 0020).
// - `toEqual` of an options object compares its `ownKeys` with
//   `unorderedEquals` and the `raw` of the typed cell of each key with
//   `equals`. A routed key, for example `ticks.color`, reads its route
//   target through `lookup`. The key `backdropColor` holds the `undefined`
//   sentinel. Functions compare by identity.
// - `jasmine.any(Function)` is `isA<Function>()`. `ticks.callback` is the
//   function `formatters.numeric`, a `TickCallback` (row
//   `adapt-native-tick`).
//
// - The chart cases read `_pointLabels` and `_pointLabelItems` as
//   `pointLabels` and `pointLabelItems` (Chart.js ADR 0012, Underscore
//   members, and Chart.js ADR 0025, section 6). `chart.scales.r` is
//   `chart.scales['r']!`, or `_r(chart)` for a member of
//   `RadialLinearScale`.
// - `toEqual` of an array is `equals`.
// - `chart.scales.r.options.reverse = true` writes through the resolver of
//   the scale options. `chart.options.scales.r.ticks.maxTicksLimit = 11`
//   writes into the resolver of the last read of the chain (`_optionsR`).
// - `index.toString()` of a callback is `jsToString(index)`.
//   `Math.round` is `roundToDouble()`.
// - `expect(...).withContext(text)` is the `reason` of `expect`.
// - `scale.ctx = window.createMockContext()` is
//   `scale.ctx = createMockContext()`, a mock context of
//   package:chartjs_test_utils/pure.dart. A call of `getCalls()` is a Map
//   with the keys `name` and `args`.
// - A chart is a typed `ChartConfig` (Chart.js ADR 0052). The point label
//   callback of the spec is `_indexPointLabel`. Four cases keep a Map
//   config: three give string or `undefined` data values, and one gives
//   `undefined`, `null`, `NaN` and `false` labels; the typed API holds none
//   of them.

/// The chart of the typed [config] (Chart.js ADR 0052).
Chart _acquire(ChartConfig config, [Map<String, Object?>? options]) =>
    acquireChartRoot(ChartConfigLowering(config).lower(), options);

/// The point label callback `function(value, index) { return
/// index.toString(); }` of the spec. Chart.js ADR 0131: the scale, the lines
/// of the label and the index; the result is the lines.
List<String> _indexPointLabel(Scale scale, List<String> label, int index) => [
  '$index',
];

/// scale.radialLinear.tests.js:1-3 `getLabels(scale)`.
List<Object?> _getLabels(Scale scale) => [
  for (final t in scale.ticks!) upstreamTickLabel(t),
];

/// `chart.scales.r`, the radial linear scale of [chart].
RadialLinearScale _r(Chart chart) => chart.scales['r']! as RadialLinearScale;

/// `chart.data.datasets[index]`: the dataset scope of a typed config.
JsObjectFace _dataset(Chart chart, int index) =>
    (jsGet(chart.data, 'datasets')! as List<Object?>)[index]! as JsObjectFace;

/// `chart.options.scales.r`, or `chart.options.scales.r[key]` for a [key]:
/// a resolver of the chart options.
JsObjectFace _optionsR(Chart chart, [String? key]) {
  final r = jsGet(jsGet(chart.options, 'scales'), 'r');
  return (key == null ? r : jsGet(r, key))! as JsObjectFace;
}

void main() {
  // Tests for the radial linear scale used by the polar area and radar charts
  group('Test the radial linear scale', () {
    group('auto', fixture.specs('scale.radialLinear'));

    test('Should register the constructor with the registry', () {
      final constructor = Chart.registry.getScale('radialLinear');
      expect(constructor, isNot(same(undefined)));
      expect(constructor, isA<JsClass>());
    });

    test('Should have the correct default config', () {
      final defaultConfig =
          jsGet(jsGet(Chart.defaults, 'scales'), 'radialLinear')!
              as ScaleOptionsScope;
      // `toEqual`: the own keys of each object and the value of each key. A
      // routed key reads its route target (`lookup`).
      expect(
        defaultConfig.ownKeys,
        unorderedEquals(<Object>[
          OptionKey.display,
          OptionKey.animate,
          OptionKey.position,
          OptionKey.angleLines,
          OptionKey.grid,
          OptionKey.border,
          OptionKey.startAngle,
          OptionKey.ticks,
          OptionKey.pointLabels,
        ]),
      );
      expect(defaultConfig.displayCell?.raw, ScaleDisplay.on);
      expect(defaultConfig.animateCell?.raw, true);
      expect(defaultConfig.positionCell?.raw, ChartPosition.chartArea);

      final angleLines =
          defaultConfig.angleLinesCell!.raw! as AngleLineOptionsScope;
      expect(
        angleLines.ownKeys,
        unorderedEquals(<Object>[
          OptionKey.display,
          OptionKey.color,
          OptionKey.lineWidth,
          OptionKey.borderDash,
          OptionKey.borderDashOffset,
        ]),
      );
      expect(angleLines.displayCell?.raw, true);
      expect(
        angleLines.lookup(OptionKey.color)?.raw,
        const ChartPaint.solid(native_ui.Color.fromRGBO(0, 0, 0, 0.1)),
      );
      expect(angleLines.lineWidthCell?.raw, 1);
      expect(angleLines.borderDashCell?.raw, equals(<double>[]));
      expect(angleLines.borderDashOffsetCell?.raw, 0.0);

      final grid = defaultConfig.gridCell!.raw! as GridLineOptionsScope;
      expect(grid.ownKeys, <Object>[OptionKey.circular]);
      expect(grid.circularCell?.raw, false);

      // DIVERGES(chartjs): adapt-native-scale-border, the radial scale has
      // its own border object with the values of `defaults.scale`.
      expect(
        defaultConfig.borderCell?.raw,
        const RadialAxisBorder(dash: <double>[], dashOffset: 0),
      );

      expect(defaultConfig.startAngleCell?.raw, 0);

      final ticks = defaultConfig.ticksCell!.raw! as TickOptionsScope;
      expect(
        ticks.ownKeys,
        unorderedEquals(<Object>[
          OptionKey.color,
          OptionKey.showLabelBackdrop,
          OptionKey.callback,
        ]),
      );
      expect(
        ticks.lookup(OptionKey.color)?.raw,
        jsGet(Chart.defaults, 'color'),
      );
      expect(ticks.showLabelBackdropCell?.raw, true);
      expect(ticks.callbackCell?.raw, same(formatters['numeric']));

      final pointLabels =
          defaultConfig.pointLabelsCell!.raw! as PointLabelOptionsScope;
      expect(
        pointLabels.ownKeys,
        unorderedEquals(<Object>[
          OptionKey.backdropColor,
          OptionKey.backdropPadding,
          OptionKey.color,
          OptionKey.display,
          OptionKey.font,
          OptionKey.callback,
          OptionKey.padding,
          OptionKey.centerPointLabels,
        ]),
      );
      expect(pointLabels.backdropColorCell?.raw, same(undefined));
      expect(pointLabels.backdropPaddingCell?.raw, const EdgeInsets.all(2));
      expect(
        pointLabels.lookup(OptionKey.color)?.raw,
        jsGet(Chart.defaults, 'color'),
      );
      expect(pointLabels.displayCell?.raw, ScaleDisplay.on);
      expect(pointLabels.fontCell?.raw, const ChartTextStyle(fontSize: 10));
      expect(pointLabels.paddingCell?.raw, 5);
      expect(pointLabels.centerPointLabelsCell?.raw, false);

      // Is this actually a function
      expect(ticks.callbackCell?.raw, isA<Function>());
      expect(pointLabels.callbackCell?.raw, isA<Function>());
    });

    testWidgets('Should correctly determine the max & min data values', (
      tester,
    ) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            RadarDataset(data: [10, 5, 0, -5, 78, -100]),
            RadarDataset(data: [150]),
          ],
          labels: ['label1', 'label2', 'label3', 'label4', 'label5', 'label6'],
          scales: {},
        ),
      );

      expect(chart.scales['r']!.min, -100);
      expect(chart.scales['r']!.max, 150);
    });

    // Native scopes preserve string inputs for the parser.
    testWidgets(
      'Should correctly determine the max & min of string data values',
      (tester) async {
        final chart = acquireChartRoot(
          ChartConfigurationScope()
            ..type = 'radar'
            ..data = (ChartDataScope()
              ..datasets = [
                mergeExtra(
                  RadarControllerDatasetOptionsScope(),
                  <String, Object?>{
                    'data': <Object?>['10', '5', '0', '-5', '78', '-100'],
                  },
                ),
                mergeExtra(
                  RadarControllerDatasetOptionsScope(),
                  <String, Object?>{
                    'data': <Object?>['150'],
                  },
                ),
              ]
              ..labels = <Object?>[
                'label1',
                'label2',
                'label3',
                'label4',
                'label5',
                'label6',
              ])
            ..options = mergeExtra(ChartOptionsScope(), <String, Object?>{
              'scales': <String, Object?>{},
            }),
        );

        expect(chart.scales['r']!.min, -100);
        expect(chart.scales['r']!.max, 150);
      },
    );

    // Native scopes preserve string inputs for the parser.
    testWidgets(
      'Should correctly determine the max & min data values when there are '
      'hidden datasets',
      (tester) async {
        final chart = acquireChartRoot(
          ChartConfigurationScope()
            ..type = 'radar'
            ..data = (ChartDataScope()
              ..datasets = [
                mergeExtra(
                  RadarControllerDatasetOptionsScope(),
                  <String, Object?>{
                    'data': <Object?>['10', '5', '0', '-5', '78', '-100'],
                  },
                ),
                mergeExtra(
                  RadarControllerDatasetOptionsScope(),
                  <String, Object?>{
                    'data': <Object?>['150'],
                  },
                ),
                mergeExtra(
                  RadarControllerDatasetOptionsScope(),
                  <String, Object?>{
                    'data': <Object?>[1000],
                    'hidden': true,
                  },
                ),
              ]
              ..labels = <Object?>[
                'label1',
                'label2',
                'label3',
                'label4',
                'label5',
                'label6',
              ])
            ..options = mergeExtra(ChartOptionsScope(), <String, Object?>{
              'scales': <String, Object?>{},
            }),
        );

        expect(chart.scales['r']!.min, -100);
        expect(chart.scales['r']!.max, 150);
      },
    );

    // Native scopes preserve `undefined` among the parser inputs.
    testWidgets(
      'Should correctly determine the max & min data values when there is '
      'NaN data',
      (tester) async {
        final chart = acquireChartRoot(
          ChartConfigurationScope()
            ..type = 'radar'
            ..data = (ChartDataScope()
              ..datasets = [
                mergeExtra(
                  RadarControllerDatasetOptionsScope(),
                  <String, Object?>{
                    'data': <Object?>[
                      50,
                      60,
                      double.nan,
                      70,
                      null,
                      undefined,
                      double.infinity,
                      double.negativeInfinity,
                    ],
                  },
                ),
              ]
              ..labels = <Object?>[
                'label1',
                'label2',
                'label3',
                'label4',
                'label5',
                'label6',
                'label7',
                'label8',
              ])
            ..options = mergeExtra(ChartOptionsScope(), <String, Object?>{
              'scales': <String, Object?>{},
            }),
        );

        expect(chart.scales['r']!.min, 50);
        expect(chart.scales['r']!.max, 70);
      },
    );

    testWidgets(
      'Should ensure that the scale has a max and min that are not equal',
      (tester) async {
        final chart = _acquire(
          const ChartConfig(
            datasets: [RadarDataset()],
            labels: [],
            scales: {'rScale': RadialLinearAxis()},
          ),
        );

        final scale = chart.scales['rScale']!;

        expect(scale.min, -1);
        expect(scale.max, 1);
      },
    );

    testWidgets('Should use the suggestedMin and suggestedMax options', (
      tester,
    ) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            RadarDataset(data: [1, 1, 1, 2, 1, 0]),
          ],
          labels: ['label1', 'label2', 'label3', 'label4', 'label5', 'label6'],
          scales: {'r': RadialLinearAxis(suggestedMin: -10, suggestedMax: 10)},
        ),
      );

      expect(chart.scales['r']!.min, -10);
      expect(chart.scales['r']!.max, 10);
    });

    testWidgets('Should use the min and max options', (tester) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            RadarDataset(data: [1, 1, 1, 2, 1, 0]),
          ],
          labels: ['label1', 'label2', 'label3', 'label4', 'label5', 'label6'],
          scales: {'r': RadialLinearAxis(min: -1010, max: 1010)},
        ),
      );

      expect(chart.scales['r']!.min, -1010);
      expect(chart.scales['r']!.max, 1010);
      expect(
        _getLabels(chart.scales['r']!),
        equals(<Object?>['-1,010', '-500', '0', '500', '1,010']),
      );
    });

    testWidgets(
      'should forcibly include 0 in the range if the beginAtZero option is '
      'used',
      (tester) async {
        final chart = _acquire(
          const ChartConfig(
            datasets: [
              RadarDataset(data: [20, 30, 40, 50]),
            ],
            labels: ['label1', 'label2', 'label3', 'label4'],
            scales: {'r': RadialLinearAxis(beginAtZero: false)},
          ),
        );

        expect(
          _getLabels(chart.scales['r']!),
          equals(<Object?>['20', '25', '30', '35', '40', '45', '50']),
        );

        chart.scales['r']!.optionsView['beginAtZero'] = true;
        chart.update();

        expect(
          _getLabels(chart.scales['r']!),
          equals(<Object?>[
            '0', '5', '10', '15', '20', '25', '30', '35', '40', '45', '50', //
          ]),
        );

        _dataset(chart, 0)['data'] = <Object?>[-20, -30, -40, -50];
        chart.update();

        expect(
          _getLabels(chart.scales['r']!),
          equals(<Object?>[
            '-50', '-45', '-40', '-35', '-30', '-25', '-20', '-15', '-10', //
            '-5', '0',
          ]),
        );

        chart.scales['r']!.optionsView['beginAtZero'] = false;
        chart.update();

        expect(
          _getLabels(chart.scales['r']!),
          equals(<Object?>[
            '-50', '-45', '-40', '-35', '-30', '-25', '-20', //
          ]),
        );
      },
    );

    testWidgets(
      'Should generate tick marks in the correct order in reversed mode',
      (tester) async {
        final chart = _acquire(
          const ChartConfig(
            datasets: [
              RadarDataset(data: [10, 5, 0, 25, 78]),
            ],
            labels: ['label1', 'label2', 'label3', 'label4', 'label5'],
            scales: {'r': RadialLinearAxis(reverse: true)},
          ),
        );

        expect(
          _getLabels(chart.scales['r']!),
          equals(<Object?>[
            '80', '70', '60', '50', '40', '30', '20', '10', '0', //
          ]),
        );
        expect(_r(chart).start, 80);
        expect(_r(chart).end, 0);
      },
    );

    testWidgets('Should correctly limit the maximum number of ticks', (
      tester,
    ) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            RadarDataset(data: [0.5, 1.5, 2.5]),
          ],
          labels: ['label1', 'label2', 'label3'],
          scales: {'r': RadialLinearAxis(pointLabelsDisplay: ScaleDisplay.off)},
        ),
      );

      expect(
        _getLabels(chart.scales['r']!),
        equals(<Object?>['0.5', '1.0', '1.5', '2.0', '2.5']),
      );

      _optionsR(chart, 'ticks')['maxTicksLimit'] = 11;
      chart.update();

      expect(
        _getLabels(chart.scales['r']!),
        equals(<Object?>['0.5', '1.0', '1.5', '2.0', '2.5']),
      );

      _optionsR(chart, 'ticks')['stepSize'] = 0.01;
      chart.update();

      expect(
        _getLabels(chart.scales['r']!),
        equals(<Object?>['0.5', '1.0', '1.5', '2.0', '2.5']),
      );

      _optionsR(chart)['min'] = 0.3;
      _optionsR(chart)['max'] = 2.8;
      chart.update();

      expect(
        _getLabels(chart.scales['r']!),
        equals(<Object?>['0.3', '0.8', '1.3', '1.8', '2.3', '2.8']),
      );
    });

    testWidgets('Should build labels using the user supplied callback', (
      tester,
    ) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            RadarDataset(data: [10, 5, 0, 25, 78]),
          ],
          labels: ['label1', 'label2', 'label3', 'label4', 'label5'],
          scales: {
            'r': RadialLinearAxis(ticks: AxisTicks(callback: indexTickLabel)),
          },
        ),
      );

      expect(
        _getLabels(chart.scales['r']!),
        equals(<Object?>['0', '1', '2', '3', '4', '5', '6', '7', '8']),
      );
      expect(
        _r(chart).pointLabels,
        equals(<Object?>[
          ['label1'],
          ['label2'],
          ['label3'],
          ['label4'],
          ['label5'],
        ]),
      );
    });

    testWidgets('Should build point labels using the user supplied callback', (
      tester,
    ) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            RadarDataset(data: [10, 5, 0, 25, 78]),
          ],
          labels: ['label1', 'label2', 'label3', 'label4', 'label5'],
          scales: {
            'r': RadialLinearAxis(pointLabelsCallback: _indexPointLabel),
          },
        ),
      );

      expect(
        _r(chart).pointLabels,
        equals(<Object?>[
          ['0'],
          ['1'],
          ['2'],
          ['3'],
          ['4'],
        ]),
      );
    });

    // Preserve the `undefined`, `null`, `NaN` and `false` labels.
    testWidgets('Should build point labels from falsy values', (tester) async {
      final chart = acquireChartRoot(
        ChartConfigurationScope()
          ..type = 'radar'
          ..data = (ChartDataScope()
            ..datasets = [
              mergeExtra(
                RadarControllerDatasetOptionsScope(),
                <String, Object?>{
                  'data': <Object?>[10, 5, 0, 25, 78, 20],
                },
              ),
            ]
            ..labels = <Object?>[0, '', undefined, null, double.nan, false]),
      );

      expect(
        _r(chart).pointLabels,
        // Chart.js ADR 0131: each point label is its lines; a value that
        // Chart.js draws as '' is one empty line.
        equals(<Object?>[
          ['0'],
          [''],
          [''],
          [''],
          [''],
          [''],
        ]),
      );
    });

    testWidgets('Should build point labels considering hidden data', (
      tester,
    ) async {
      final chart =
          _acquire(
              const ChartConfig(
                datasets: [
                  PolarAreaDataset(data: [10, 5, 0, 25, 78, 20]),
                ],
                labels: ['a', 'b', 'c', 'd', 'e', 'f'],
              ),
            )
            ..toggleDataVisibility(3)
            ..update();

      expect(
        _r(chart).pointLabels,
        equals(<Object?>[
          ['a'],
          ['b'],
          ['c'],
          ['e'],
          ['f'],
        ]),
      );
    });

    testWidgets('should correctly set the center point', (tester) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            RadarDataset(data: [10, 5, 0, 25, 78]),
          ],
          labels: ['label1', 'label2', 'label3', 'label4', 'label5'],
          scales: {
            'r': RadialLinearAxis(pointLabelsCallback: _indexPointLabel),
          },
        ),
      );

      expect(_r(chart).drawingArea, 215);
      expect(_r(chart).xCenter, 256);
      expect(_r(chart).yCenter, 280);
    });

    testWidgets('should correctly get the label for a given data index', (
      tester,
    ) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            RadarDataset(data: [10, 5, 0, 25, 78]),
          ],
          labels: ['label1', 'label2', 'label3', 'label4', 'label5'],
          scales: {
            'r': RadialLinearAxis(pointLabelsCallback: _indexPointLabel),
          },
        ),
      );
      expect(chart.scales['r']!.getLabelForValue(5), '5');
    });

    testWidgets('should get the correct distance from the center point', (
      tester,
    ) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            RadarDataset(data: [10, 5, 0, 25, 78]),
          ],
          labels: ['label1', 'label2', 'label3', 'label4', 'label5'],
          scales: {
            'r': RadialLinearAxis(pointLabelsCallback: _indexPointLabel),
          },
        ),
      );

      expect(_r(chart).getDistanceFromCenterForValue(_r(chart).min), 0);
      expect(_r(chart).getDistanceFromCenterForValue(_r(chart).max), 215);

      final position = _r(chart).getPointPositionForValue(1, 5);
      expect(position.x, toBeCloseToPixel(269));
      expect(position.y, toBeCloseToPixel(276));

      _r(chart).optionsView['reverse'] = true;
      chart.update();

      expect(_r(chart).getDistanceFromCenterForValue(_r(chart).min), 215);
      expect(_r(chart).getDistanceFromCenterForValue(_r(chart).max), 0);
    });

    testWidgets(
      'should get the correct value for a distance from the center point',
      (tester) async {
        final chart = _acquire(
          const ChartConfig(
            datasets: [
              RadarDataset(data: [10, 5, 0, 25, 78]),
            ],
            labels: ['label1', 'label2', 'label3', 'label4', 'label5'],
            scales: {
              'r': RadialLinearAxis(pointLabelsCallback: _indexPointLabel),
            },
          ),
        );

        expect(_r(chart).getValueForDistanceFromCenter(0), _r(chart).min);
        expect(_r(chart).getValueForDistanceFromCenter(215), _r(chart).max);

        final dist = _r(chart).getDistanceFromCenterForValue(5);
        expect(_r(chart).getValueForDistanceFromCenter(dist), 5);

        _r(chart).optionsView['reverse'] = true;
        chart.update();

        expect(_r(chart).getValueForDistanceFromCenter(0), _r(chart).max);
        expect(_r(chart).getValueForDistanceFromCenter(215), _r(chart).min);
      },
    );

    testWidgets('should correctly get angles for all points', (tester) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            RadarDataset(data: [10, 5, 0, 25, 78]),
          ],
          labels: ['label1', 'label2', 'label3', 'label4', 'label5'],
          scales: {
            'r': RadialLinearAxis(
              startAngle: 15,
              pointLabelsCallback: _indexPointLabel,
            ),
          },
        ),
      );

      double radToNearestDegree(double rad) {
        return ((360 * rad) / (2 * math.pi)).roundToDouble();
      }

      const slice = 72; // (360 / 5)

      for (var i = 0; i < 5; i++) {
        expect(
          radToNearestDegree(_r(chart).getIndexAngle(i)),
          15 + (slice * i),
        );
      }

      _r(chart).optionsView['startAngle'] = 0;
      chart.update();

      for (var x = 0; x < 5; x++) {
        expect(radToNearestDegree(_r(chart).getIndexAngle(x)), slice * x);
      }
    });

    testWidgets(
      'should correctly get the correct label alignment for all points',
      (tester) async {
        final chart = _acquire(
          const ChartConfig(
            datasets: [
              RadarDataset(data: [10, 5, 0, 25, 78]),
            ],
            labels: ['label1', 'label2', 'label3', 'label4', 'label5'],
            scales: {
              'r': RadialLinearAxis(
                pointLabelsCallback: _indexPointLabel,
                ticks: AxisTicks(display: false),
              ),
            },
          ),
        );

        final scale = chart.scales['r']!;

        for (final expected in <Map<String, Object?>>[
          <String, Object?>{
            'startAngle': 30,
            'textAlign': <Object?>['right', 'right', 'left', 'left', 'left'],
          },
          <String, Object?>{
            'startAngle': -30,
            'textAlign': <Object?>['right', 'right', 'left', 'left', 'right'],
          },
          <String, Object?>{
            'startAngle': 750,
            'textAlign': <Object?>['right', 'right', 'left', 'left', 'left'],
          },
        ]) {
          scale.optionsView['startAngle'] = expected['startAngle'];
          chart.update();

          final ctx = createMockContext();
          scale.ctx = ctx;
          chart.draw();

          final calls = ctx
              .getCalls()
              .where((x) => x['name'] == 'setTextAlign')
              .toList();
          for (var i = 0; i < calls.length; i++) {
            expect(
              (calls[i]['args']! as List<Object?>)[0],
              (expected['textAlign']! as List<Object?>)[i],
              reason:
                  'startAngle: ${jsToString(expected['startAngle'])}, '
                  'tick: ${jsToString(i)}',
            );
          }
        }
      },
    );

    testWidgets('should correctly get the point positions in center', (
      tester,
    ) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            PolarAreaDataset(data: [10, 5, 0, 25, 78]),
          ],
          labels: ['label1', 'label2', 'label3', 'label4', 'label5'],
          scales: {
            'r': RadialLinearAxis(
              pointLabelsDisplay: ScaleDisplay.on,
              pointLabelsPadding: 5,
              ticks: AxisTicks(display: false),
              extra: {
                'pointLabels': {'centerPointLabels': true},
              },
            ),
          },
        ),
      );

      const pi = math.pi;
      const lavelNum = 5;
      const padding = 5;
      final pointLabelItems = _r(chart).pointLabelItems;
      const additionalAngle = pi / lavelNum;
      final opts = _r(chart).options;
      final outerDistance = _r(chart).getDistanceFromCenterForValue(
        jsTruthy(readOption(opts.ticks.view, OptionKey.reverse))
            ? _r(chart).min
            : _r(chart).max,
      );
      const tickBackdropHeight = 0;
      // The parameter `y` of upstream is the local `result`.
      double yForAngle(double y, double h, double angle) {
        var result = y;
        if (angle == 90 || angle == 270) {
          result -= h / 2;
        } else if (angle > 270 || angle < 90) {
          result -= h;
        }
        return result;
      }

      double toDegrees(double radians) {
        return radians * (180 / pi);
      }

      for (var i = 0; i < 5; i++) {
        final extra = i == 0 ? tickBackdropHeight / 2 : 0;
        final pointLabelItem = pointLabelItems[i];
        final pointPosition = _r(
          chart,
        ).getPointPosition(i, outerDistance + extra + padding, additionalAngle);
        expect(pointLabelItem.x, pointPosition.x);
        expect(
          pointLabelItem.y,
          yForAngle(
            pointPosition.y,
            12,
            toDegrees(pointPosition.angle + pi / 2),
          ),
        );
      }
    });
  });
}
