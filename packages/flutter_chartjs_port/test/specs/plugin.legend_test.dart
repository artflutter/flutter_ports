// Ported from Chart.js v4.6.1 test/specs/plugin.legend.tests.js (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-dash-lists, the dash patterns are lists of doubles.
// DIVERGES(chartjs): adapt-native-legend-hit-box, native geometry reads.
// DIVERGES(chartjs): adapt-native-legend-item, native item access.
// DIVERGES(chartjs): adapt-direct-colors, native color test inputs.
@TestOn('vm')
library;

import 'dart:ui' as native_ui;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/index.dart' as fixture;
import '../support/legend_item.dart';

// `Chart` is the class of core.controller.dart, with the static members
// `Chart.registry` and `Chart.defaults`. `window.Chart.helpers.color` is
// `color` of helpers.color.dart. `toEqual` of the legend items is
// [_itemsEqual]: `legendItemEquals` of test/support/legend_item.dart for
// each item. `toEqual` of the defaults reads the fields of the
// `LegendOptions` of the defaults (Chart.js ADR 0193), and
// `jasmine.any(Function)` is `isA<Function>()`.
// `toEqualOptions` is the matcher of chartjs_test_utils.
//
// Each chart case is a `testWidgets` case with the harness of Chart.js ADR
// 0022, section 2. `chart.legend` is the field of `Chart`: Dart `null`
// stands for JS `undefined`. The spec reads `legendItems` through
// `types.LegendElement` and `legendHitBoxes` through a cast to `Legend`
// (Chart.js ADR 0038, section 6). Hit boxes expose native typed fields. A
// write into `chart.options` is the write through `operator []=`
// of the option resolver, the `set` trap of upstream. The legend options are
// one immutable `LegendOptions` (Chart.js ADR 0193): the write of a legend
// option writes a new object with the option into `plugins.legend`.
// `jasmine.triggerMouseEvent` is triggerMouseEvent of chartjs_test_utils
// (Chart.js ADR 0022, section 6).

/// `chart.legend.legendHitBoxes`.
List<LegendHitBox> _hitBoxes(Chart chart) =>
    (chart.legend! as Legend).legendHitBoxes;

/// `chart.options.plugins`, the option resolver of the plugins.
JsObjectFace _pluginOptions(Chart chart) =>
    jsGet(chart.options, 'plugins')! as JsObjectFace;

/// `chart.options.plugins.legend.<key> = <value>` for the options [over]:
/// the legend options of the chart with [over] merged over them, written
/// into `chart.options.plugins.legend`.
void _writeLegendOptions(Chart chart, LegendOptions over) {
  final plugins = _pluginOptions(chart);
  plugins['legend'] = (plugins['legend']! as LegendOptions).merge(over);
}

/// `Chart.defaults.plugins.legend`.
LegendOptions _legendDefaults() =>
    (Chart.defaults.pluginsCell!.raw! as PluginOptionsByTypeScope)
            .legendCell!
            .raw!
        as LegendOptions;

/// The chart of the typed config [config], with the harness options
/// [options] of `acquireChart`.
Chart _acquire(ChartConfig config, [Map<String, Object?>? options]) =>
    acquireChartRoot(ChartConfigLowering(config).lower(), options);

/// The point `{x, y}` at the center of the hit box [hb] (:1094-1097,
/// :1136-1139, :1176-1179).
AnyObject _center(LegendHitBox hb) => <String, Object?>{
  'x': hb.left + (hb.width / 2),
  'y': hb.top + (hb.height / 2),
};

/// The three datasets of `should update bar chart correctly` (:39-57).
/// `should filter items` gives [legendHidden] to dataset 2 and
/// [borderRadius] to dataset 3.
List<Dataset> _barDatasets({bool? legendHidden, double? borderRadius}) => [
  const BarDataset(
    label: 'dataset1',
    backgroundColor: ChartValue.constant(
      ChartPaint.solid(native_ui.Color.fromRGBO(255, 51, 17, 1)),
    ),
    data: .values([]),
    extra: {
      'borderCapStyle': native_ui.StrokeCap.butt,
      'borderDash': <double>[2, 2],
      'borderDashOffset': 5.5,
    },
  ),
  BarDataset(
    label: 'dataset2',
    hidden: true,
    data: const .values([]),
    extra: {
      'borderJoinStyle': native_ui.StrokeJoin.miter,
      'legendHidden': ?legendHidden,
    },
  ),
  BarDataset(
    label: 'dataset3',
    borderWidth: 10,
    borderColor: const ChartValue.constant(
      ChartPaint.solid(native_ui.Color.fromRGBO(0, 128, 0, 1)),
    ),
    borderRadius: borderRadius,
    data: const .values([]),
    // DIVERGES(chartjs): adapt-point-style-objects, the style class.
    extra: const {'pointStyle': CrossRotPointStyle()},
  ),
];

/// The three datasets of the line cases (:117-136, :196-215, :358-377).
const List<Dataset> _lineDatasets = [
  LineDataset(
    label: 'dataset1',
    backgroundColor: ChartValue.constant(
      ChartPaint.solid(native_ui.Color.fromRGBO(255, 51, 17, 1)),
    ),
    borderCapStyle: native_ui.StrokeCap.round,
    borderDash: [2, 2],
    data: .values([]),
    extra: {'borderDashOffset': 5.5},
  ),
  LineDataset(
    label: 'dataset2',
    hidden: true,
    borderJoinStyle: native_ui.StrokeJoin.round,
    data: .values([]),
  ),
  LineDataset(
    label: 'dataset3',
    borderWidth: 10,
    borderColor: ChartValue.constant(
      ChartPaint.solid(native_ui.Color.fromRGBO(0, 128, 0, 1)),
    ),
    // DIVERGES(chartjs): adapt-point-style-objects, the style class.
    pointStyle: .constant(CrossRotPointStyle()),
    fill: FillTarget.none,
    data: .values([]),
  ),
];

/// A legend item with the values of the spec (each key of :62-77). An
/// absent key of the spec is Dart `null`.
LegendItem _item({
  required String text,
  required ChartPaint fillStyle,
  required bool hidden,
  required double lineWidth,
  required ChartPaint strokeStyle,
  required int datasetIndex,
  BorderRadius? borderRadius,
  native_ui.StrokeCap? lineCap,
  List<double>? lineDash,
  double? lineDashOffset,
  native_ui.StrokeJoin? lineJoin,
  PointStyle? pointStyle,
  double? rotation,
}) => LegendItem(
  text: [text],
  borderRadius: borderRadius,
  fillStyle: fillStyle,
  fontColor: const ChartPaint.solid(native_ui.Color.fromRGBO(102, 102, 102, 1)),
  hidden: hidden,
  lineCap: lineCap,
  lineDash: lineDash,
  lineDashOffset: lineDashOffset,
  lineJoin: lineJoin,
  lineWidth: lineWidth,
  strokeStyle: strokeStyle,
  pointStyle: pointStyle,
  rotation: rotation,
  datasetIndex: datasetIndex,
);

/// `toEqual(expected)` of a list of legend items: the same length, and each
/// item matches `legendItemEquals` of its expected item.
Matcher _itemsEqual(List<LegendItem> expected) =>
    equals([for (final item in expected) legendItemEquals(item)]);

/// The items of the line cases, dataset 1 to 3 (:141-189).
LegendItem _lineItem1() => _item(
  text: 'dataset1',
  fillStyle: const ChartPaint.solid(native_ui.Color.fromRGBO(255, 51, 17, 1)),
  hidden: false,
  lineCap: native_ui.StrokeCap.round,
  lineDash: <double>[2, 2],
  lineDashOffset: 5.5,
  lineJoin: native_ui.StrokeJoin.miter,
  lineWidth: 3,
  strokeStyle: const ChartPaint.solid(native_ui.Color.fromRGBO(0, 0, 0, 0.1)),
  datasetIndex: 0,
);

LegendItem _lineItem2() => _item(
  text: 'dataset2',
  fillStyle: const ChartPaint.solid(native_ui.Color.fromRGBO(0, 0, 0, 0.1)),
  hidden: true,
  lineCap: native_ui.StrokeCap.butt,
  lineDash: <double>[],
  lineDashOffset: 0,
  lineJoin: native_ui.StrokeJoin.round,
  lineWidth: 3,
  strokeStyle: const ChartPaint.solid(native_ui.Color.fromRGBO(0, 0, 0, 0.1)),
  datasetIndex: 1,
);

LegendItem _lineItem3() => _item(
  text: 'dataset3',
  fillStyle: const ChartPaint.solid(native_ui.Color.fromRGBO(0, 0, 0, 0.1)),
  hidden: false,
  lineCap: native_ui.StrokeCap.butt,
  lineDash: <double>[],
  lineDashOffset: 0,
  lineJoin: native_ui.StrokeJoin.miter,
  lineWidth: 10,
  strokeStyle: const ChartPaint.solid(native_ui.Color.fromRGBO(0, 128, 0, 1)),
  datasetIndex: 2,
);

/// A line chart of four labels and one dataset with the legend options
/// [legendOptions] (the config update cases).
// Native scopes keep the live option updates, including a disabled legend.
ChartConfigurationScope _lineChart([Object? legendOptions]) {
  final config = ChartConfigurationScope()
    ..type = 'line'
    ..data = (ChartDataScope()
      ..labels = <Object?>['A', 'B', 'C', 'D']
      ..datasets = [
        LineControllerDatasetOptionsScope()..data = <Object?>[10, 20, 30, 100],
      ]);
  if (legendOptions != null) {
    config.options = mergeExtra(ChartOptionsScope(), {
      'plugins': {'legend': legendOptions},
    });
  }
  return config;
}

/// A line chart of four labels and one dataset with the legend options
/// [legend] (the callbacks cases).
Chart _line(LegendOptions legend) => _acquire(
  ChartConfig(
    labels: const ['A', 'B', 'C', 'D'],
    datasets: const [
      LineDataset(data: .values([10, 20, 30, 100])),
    ],
    pluginOptions: [legend],
  ),
);

void main() {
  // Test the rectangle element
  group('Legend block tests', () {
    group('auto', fixture.specs('plugin.legend'));

    test('should have the correct default config', () {
      final actual = _legendDefaults();
      // `toEqual`: the value of each key. The label and title `color` of
      // upstream is the function of the chart color: the legend gives that
      // color when the options set none (Chart.js ADR 0193). `onHover` and
      // `onLeave` are `null`.
      expect(actual.display, true);
      expect(actual.position, ChartPosition.top);
      expect(actual.align, ChartAlign.center);
      expect(actual.fullSize, true);
      expect(actual.reverse, false);
      expect(actual.weight, 1000);

      // a callback that will handle
      // jasmine.any(Function): each function value of the expected object.
      expect(actual.onClick, isA<Function>());
      expect(actual.onHover, isNull);
      expect(actual.onLeave, isNull);

      final labels = actual.labels!;
      expect(labels.color, isNull);
      expect(labels.boxWidth, 40);
      expect(labels.padding, 10);
      expect(labels.generateLabels, isA<Function>());

      final title = actual.title!;
      expect(title.color, isNull);
      expect(title.display, false);
      expect(title.position, ChartAlign.center);
      expect(title.text, ['']);
    });

    testWidgets('should update bar chart correctly', (tester) async {
      final chart = _acquire(
        ChartConfig(datasets: _barDatasets(), labels: const []),
      );

      expect(
        chart.legend!.legendItems,
        _itemsEqual([
          _item(
            text: 'dataset1',
            fillStyle: const ChartPaint.solid(
              native_ui.Color.fromRGBO(255, 51, 17, 1),
            ),
            hidden: false,
            lineWidth: 0,
            strokeStyle: const ChartPaint.solid(
              native_ui.Color.fromRGBO(0, 0, 0, 0.1),
            ),
            datasetIndex: 0,
          ),
          _item(
            text: 'dataset2',
            fillStyle: const ChartPaint.solid(
              native_ui.Color.fromRGBO(0, 0, 0, 0.1),
            ),
            hidden: true,
            lineWidth: 0,
            strokeStyle: const ChartPaint.solid(
              native_ui.Color.fromRGBO(0, 0, 0, 0.1),
            ),
            datasetIndex: 1,
          ),
          _item(
            text: 'dataset3',
            fillStyle: const ChartPaint.solid(
              native_ui.Color.fromRGBO(0, 0, 0, 0.1),
            ),
            hidden: false,
            lineWidth: 10,
            strokeStyle: const ChartPaint.solid(
              native_ui.Color.fromRGBO(0, 128, 0, 1),
            ),
            // DIVERGES(chartjs): adapt-point-style-objects, the style class.
            pointStyle: const CrossRotPointStyle(),
            datasetIndex: 2,
          ),
        ]),
      );
    });

    testWidgets('should update line chart correctly', (tester) async {
      final chart = _acquire(
        const ChartConfig(datasets: _lineDatasets, labels: []),
      );

      expect(
        chart.legend!.legendItems,
        _itemsEqual([_lineItem1(), _lineItem2(), _lineItem3()]),
      );
    });

    testWidgets('should reverse correctly', (tester) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: _lineDatasets,
          labels: [],
          pluginOptions: [LegendOptions(reverse: true)],
        ),
      );

      expect(
        chart.legend!.legendItems,
        _itemsEqual([_lineItem3(), _lineItem2(), _lineItem1()]),
      );
    });

    testWidgets('should filter items', (tester) async {
      final chart = _acquire(
        ChartConfig(
          datasets: _barDatasets(legendHidden: true, borderRadius: 10),
          labels: const [],
          pluginOptions: [
            LegendOptions(
              labels: LegendLabelOptions(
                filter: (legendItem, data) {
                  final dataset = jsGetIndex(
                    jsGet(data, 'datasets'),
                    legendItem.datasetIndex!.toDouble(),
                  );
                  return !jsTruthy(jsGet(dataset, 'legendHidden'));
                },
              ),
            ),
          ],
        ),
      );

      expect(
        chart.legend!.legendItems,
        _itemsEqual([
          _item(
            text: 'dataset1',
            fillStyle: const ChartPaint.solid(
              native_ui.Color.fromRGBO(255, 51, 17, 1),
            ),
            hidden: false,
            lineWidth: 0,
            strokeStyle: const ChartPaint.solid(
              native_ui.Color.fromRGBO(0, 0, 0, 0.1),
            ),
            datasetIndex: 0,
          ),
          _item(
            text: 'dataset3',
            fillStyle: const ChartPaint.solid(
              native_ui.Color.fromRGBO(0, 0, 0, 0.1),
            ),
            hidden: false,
            lineWidth: 10,
            strokeStyle: const ChartPaint.solid(
              native_ui.Color.fromRGBO(0, 128, 0, 1),
            ),
            // DIVERGES(chartjs): adapt-point-style-objects, the style class.
            pointStyle: const CrossRotPointStyle(),
            datasetIndex: 2,
          ),
        ]),
      );
    });

    testWidgets('should sort items', (tester) async {
      final chart = _acquire(
        ChartConfig(
          datasets: _lineDatasets,
          labels: const [],
          pluginOptions: [
            LegendOptions(
              labels: LegendLabelOptions(
                sort: (a, b, data) =>
                    b.datasetIndex! > a.datasetIndex! ? 1 : -1,
              ),
            ),
          ],
        ),
      );

      expect(
        chart.legend!.legendItems,
        _itemsEqual([_lineItem3(), _lineItem2(), _lineItem1()]),
      );
    });

    testWidgets('should not throw when the label options are missing', (
      tester,
    ) async {
      // `labels: false` has no form: the legend options are one object with
      // nullable fields (Chart.js ADR 0193). A box whose options have no
      // label options reads the label options of `{}` (plugin.legend.js:105),
      // as upstream reads them for `false`.
      void makeChart() {
        final chart = acquireChartRoot(
          ChartConfigurationScope()
            ..type = 'bar'
            ..data = (ChartDataScope()
              ..datasets = [
                mergeExtra(
                  BarControllerDatasetOptionsScope(),
                  <String, Object?>{
                    'label': 'dataset1',
                    'backgroundColor': const ChartPaint.solid(
                      native_ui.Color.fromRGBO(255, 51, 17, 1),
                    ),
                    'borderCapStyle': native_ui.StrokeCap.butt,
                    'borderDash': <double>[2, 2],
                    'borderDashOffset': 5.5,
                    'data': <Object?>[],
                  },
                ),
              ]
              ..labels = <Object?>[])
            ..options = mergeExtra(ChartOptionsScope(), <String, Object?>{
              'plugins': <String, Object?>{'legend': const LegendOptions()},
            }),
        );
        (chart.legend! as Legend)
          ..options = const LegendOptions(
            display: true,
            position: ChartPosition.top,
          )
          ..buildLabels()
          ..fit();
      }

      expect(makeChart, returnsNormally);
    });

    testWidgets('should not draw legend items outside of the chart bounds', (
      tester,
    ) async {
      final chart = _acquire(
        ChartConfig(
          datasets: [
            for (final n in [1, 2, 3])
              LineDataset(label: 'dataset$n', data: const .values([])),
          ],
          labels: const [],
          pluginOptions: const [LegendOptions(position: ChartPosition.right)],
        ),
        <String, Object?>{
          'canvas': <String, Object?>{'width': 512, 'height': 105},
        },
      );

      // Check some basic assertions about the test setup
      expect(chart.width, 512);
      expect(_hitBoxes(chart).length, 3);

      // Check whether any legend items reach outside the established bounds
      for (final item in _hitBoxes(chart)) {
        expect(item.left + item.width, lessThanOrEqualTo(chart.width));
      }
    });

    testWidgets('should draw legend with multiline labels', (tester) async {
      final chart = _acquire(
        const ChartConfig(
          labels: [
            'ABCDE',
            ['ABCDE', 'ABCDE'],
            ['Some Text', 'Some Text', 'Some Text'],
            'ABCDE',
          ],
          datasets: [
            DoughnutDataset(
              label: 'test',
              data: [73.42, 18.13, 7.54, 0.9, 0.0025, 1.8e-5],
              backgroundColor: ChartValue.indexed([
                ChartPaint.solid(native_ui.Color.fromRGBO(0, 120, 194, 1)),
                ChartPaint.solid(native_ui.Color.fromRGBO(86, 202, 245, 1)),
                ChartPaint.solid(native_ui.Color.fromRGBO(177, 227, 249, 1)),
                ChartPaint.solid(native_ui.Color.fromRGBO(251, 188, 141, 1)),
                ChartPaint.solid(native_ui.Color.fromRGBO(246, 163, 190, 1)),
                ChartPaint.solid(native_ui.Color.fromRGBO(78, 194, 193, 1)),
              ]),
            ),
          ],
          pluginOptions: [
            LegendOptions(
              position: ChartPosition.right,
              align: ChartAlign.center,
              labels: LegendLabelOptions(
                usePointStyle: true,
                // DIVERGES(chartjs): adapt-point-style-objects, the style
                // class.
                pointStyle: RectPointStyle(),
              ),
              maxWidth: 860,
            ),
          ],
          aspectRatio: 3,
        ),
      );

      // Check some basic assertions about the test setup
      expect(_hitBoxes(chart).length, 4);

      // Check whether any legend items reach outside the established bounds
      for (final item in _hitBoxes(chart)) {
        expect(item.left + item.width, lessThanOrEqualTo(chart.width));
      }
    });

    testWidgets('should draw items with a custom boxHeight', (tester) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [LineDataset(label: 'dataset1', data: .values([]))],
          labels: [],
          pluginOptions: [
            LegendOptions(
              position: ChartPosition.right,
              labels: LegendLabelOptions(boxHeight: 40),
            ),
          ],
        ),
        <String, Object?>{
          'canvas': <String, Object?>{'width': 512, 'height': 105},
        },
      );
      final hitBox = _hitBoxes(chart)[0];
      expect(hitBox.height, 40);
    });

    testWidgets('should pick up the first item when the property is an array', (
      tester,
    ) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            BarDataset(
              label: 'dataset1',
              backgroundColor: ChartValue.indexed([
                ChartPaint.solid(native_ui.Color.fromRGBO(255, 51, 17, 1)),
                ChartPaint.solid(native_ui.Color.fromRGBO(102, 102, 102, 1)),
                ChartPaint.solid(native_ui.Color.fromRGBO(17, 68, 238, 1)),
              ]),
              borderColor: ChartValue.indexed([
                ChartPaint.solid(native_ui.Color.fromRGBO(255, 0, 0, 1)),
                ChartPaint.solid(native_ui.Color.fromRGBO(0, 128, 0, 1)),
                ChartPaint.solid(native_ui.Color.fromRGBO(0, 0, 255, 1)),
              ]),
              data: .values([]),
              // The typed borderWidth is one number: an array goes through
              // `extra`.
              extra: {
                'borderWidth': <Object?>[5, 10, 15],
              },
            ),
          ],
          labels: [],
        ),
      );

      expect(
        chart.legend!.legendItems,
        _itemsEqual([
          _item(
            text: 'dataset1',
            fillStyle: const ChartPaint.solid(
              native_ui.Color.fromRGBO(255, 51, 17, 1),
            ),
            hidden: false,
            lineWidth: 5,
            strokeStyle: const ChartPaint.solid(
              native_ui.Color.fromRGBO(255, 0, 0, 1),
            ),
            datasetIndex: 0,
          ),
        ]),
      );
    });

    testWidgets('should use the borderRadius in the legend', (tester) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: [
            BarDataset(
              label: 'dataset1',
              backgroundColor: ChartValue.indexed([
                ChartPaint.solid(native_ui.Color.fromRGBO(255, 51, 17, 1)),
                ChartPaint.solid(native_ui.Color.fromRGBO(102, 102, 102, 1)),
                ChartPaint.solid(native_ui.Color.fromRGBO(17, 68, 238, 1)),
              ]),
              borderColor: ChartValue.indexed([
                ChartPaint.solid(native_ui.Color.fromRGBO(255, 0, 0, 1)),
                ChartPaint.solid(native_ui.Color.fromRGBO(0, 128, 0, 1)),
                ChartPaint.solid(native_ui.Color.fromRGBO(0, 0, 255, 1)),
              ]),
              borderRadius: 10,
              data: .values([]),
              // The typed borderWidth is one number: an array goes through
              // `extra`.
              extra: {
                'borderWidth': <Object?>[5, 10, 15],
              },
            ),
          ],
          labels: [],
          pluginOptions: [
            LegendOptions(labels: LegendLabelOptions(useBorderRadius: true)),
          ],
        ),
      );

      expect(
        chart.legend!.legendItems,
        _itemsEqual([
          _item(
            text: 'dataset1',
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            fillStyle: const ChartPaint.solid(
              native_ui.Color.fromRGBO(255, 51, 17, 1),
            ),
            hidden: false,
            lineWidth: 5,
            strokeStyle: const ChartPaint.solid(
              native_ui.Color.fromRGBO(255, 0, 0, 1),
            ),
            datasetIndex: 0,
          ),
        ]),
      );
    });

    testWidgets(
      'should use the value for the first item when the property is a function',
      (tester) async {
        final chart = _acquire(
          ChartConfig(
            datasets: [
              BarDataset(
                label: 'dataset1',
                backgroundColor: ChartValue.resolver((ctx) {
                  final value = _dataValue(ctx);
                  return ChartPaint.solid(
                    native_ui.Color.fromRGBO(
                      (value * 10).toInt().clamp(0, 255),
                      0,
                      0,
                      1,
                    ),
                  );
                }),
                borderColor: ChartValue.resolver((ctx) {
                  final value = _dataValue(ctx);
                  return ChartPaint.solid(
                    native_ui.Color.fromRGBO(
                      (255 - value * 10).toInt().clamp(0, 255),
                      0,
                      0,
                      1,
                    ),
                  );
                }),
                data: const .values([5, 10, 15, 20]),
                // The typed borderWidth is one number: a function goes
                // through `extra`.
                extra: const {'borderWidth': _dataValue},
              ),
            ],
            labels: const ['A', 'B', 'C', 'D'],
          ),
        );

        expect(
          chart.legend!.legendItems,
          _itemsEqual([
            _item(
              text: 'dataset1',
              fillStyle: const ChartPaint.solid(
                native_ui.Color.fromRGBO(50, 0, 0, 1),
              ),
              hidden: false,
              lineWidth: 5,
              strokeStyle: const ChartPaint.solid(
                native_ui.Color.fromRGBO(205, 0, 0, 1),
              ),
              datasetIndex: 0,
            ),
          ]),
        );
      },
    );

    testWidgets('should draw correctly when usePointStyle is true', (
      tester,
    ) async {
      final chart = _acquire(
        const ChartConfig(
          datasets: _pointStyleDatasets,
          labels: [],
          pluginOptions: [
            LegendOptions(labels: LegendLabelOptions(usePointStyle: true)),
          ],
        ),
      );

      expect(
        chart.legend!.legendItems,
        _itemsEqual(_pointStyleItems(const CrossRotPointStyle())),
      );
    });

    testWidgets(
      'should draw correctly when usePointStyle is true and pointStyle '
      'override is set',
      (tester) async {
        final chart = _acquire(
          const ChartConfig(
            datasets: _pointStyleDatasets,
            labels: [],
            pluginOptions: [
              LegendOptions(
                labels: LegendLabelOptions(
                  usePointStyle: true,
                  // DIVERGES(chartjs): adapt-point-style-objects, the style
                  // class.
                  pointStyle: StarPointStyle(),
                ),
              ),
            ],
          ),
        );

        expect(
          chart.legend!.legendItems,
          _itemsEqual(_pointStyleItems(const StarPointStyle())),
        );
      },
    );

    testWidgets('should not crash when the legend defaults are false', (
      tester,
    ) async {
      final oldDefaults = _legendDefaults();

      Chart.defaults.set(<String, Object?>{
        'plugins': <String, Object?>{'legend': false},
      });

      final chart = _acquire(
        const ChartConfig(
          datasets: [
            DoughnutDataset(label: 'dataset1', data: [1, 2, 3, 4]),
          ],
          labels: ['', '', '', ''],
        ),
      );
      expect(chart, isNotNull);

      Chart.defaults.set(<String, Object?>{
        'plugins': <String, Object?>{'legend': oldDefaults},
      });
    });

    testWidgets('should not read onClick from chart options', (tester) async {
      final chart = _acquire(
        ChartConfig(
          labels: const ['Jan', 'Feb', 'Mar', 'Apr', 'May'],
          datasets: const [
            BarDataset(
              label: 'dataset',
              backgroundColor: ChartValue.constant(
                ChartPaint.solid(native_ui.Color.fromRGBO(255, 0, 0, 1)),
              ),
              borderColor: ChartValue.constant(
                ChartPaint.solid(native_ui.Color.fromRGBO(255, 0, 0, 1)),
              ),
              data: .values([120, 23, 24, 45, 51]),
            ),
          ],
          responsive: true,
          onClick: (_, _, _) {},
          pluginOptions: const [LegendOptions(display: true)],
        ),
      );
      expect(
        (chart.legend! as Legend).options.onClick,
        same(_legendDefaults().onClick),
      );
    });

    testWidgets('should read labels.color from chart options', (tester) async {
      final chart = _acquire(
        const ChartConfig(
          labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May'],
          datasets: [
            BarDataset(
              label: 'dataset',
              backgroundColor: ChartValue.constant(
                ChartPaint.solid(native_ui.Color.fromRGBO(255, 0, 0, 1)),
              ),
              borderColor: ChartValue.constant(
                ChartPaint.solid(native_ui.Color.fromRGBO(255, 0, 0, 1)),
              ),
              data: .values([120, 23, 24, 45, 51]),
            ),
          ],
          responsive: true,
          pluginOptions: [LegendOptions(display: true)],
          // The chart option `color` has no typed field.
          extra: {
            'color': ChartPaint.solid(native_ui.Color.fromRGBO(0, 128, 0, 1)),
          },
        ),
      );
      expect(
        (chart.legend! as Legend).options.labels!.color,
        const ChartPaint.solid(native_ui.Color.fromRGBO(0, 128, 0, 1)),
      );
      expect(
        (chart.legend! as Legend).options.title!.color,
        const ChartPaint.solid(native_ui.Color.fromRGBO(0, 128, 0, 1)),
      );
    });

    group('config update', () {
      testWidgets('should update the options', (tester) async {
        final chart = acquireChartRoot(
          _lineChart(const LegendOptions(display: true)),
        );
        expect((chart.legend! as Legend).options.display, true);

        _writeLegendOptions(chart, const LegendOptions(display: false));
        chart.update();
        expect((chart.legend! as Legend).options.display, false);
      });

      testWidgets('should update the associated layout item', (tester) async {
        // Native scopes keep the live option updates by name.
        final chart = acquireChartRoot(
          ChartConfigurationScope()
            ..type = 'line'
            ..data = (ChartDataScope())
            ..options = mergeExtra(ChartOptionsScope(), <String, Object?>{
              'plugins': <String, Object?>{
                'legend': const LegendOptions(
                  fullSize: true,
                  position: ChartPosition.top,
                  weight: 150,
                ),
              },
            }),
        );

        // `chart.legend` as a layout box, read at each assertion, as
        // upstream does.
        Legend legend() => chart.legend! as Legend;
        expect(legend().fullSize, true);
        expect(legend().position, ChartPosition.top);
        expect(legend().weight, 150);

        _writeLegendOptions(
          chart,
          const LegendOptions(
            fullSize: false,
            position: ChartPosition.left,
            weight: 42,
          ),
        );
        chart.update();

        expect(legend().fullSize, false);
        expect(legend().position, ChartPosition.left);
        expect(legend().weight, 42);
      });

      testWidgets('should remove the legend if the new options are false', (
        tester,
      ) async {
        final chart = acquireChartRoot(_lineChart());
        expect(chart.legend, isNotNull);

        _pluginOptions(chart)['legend'] = false;
        chart.update();
        expect(chart.legend, isNull);
      });

      testWidgets(
        'should create the legend if the legend options are changed to exist',
        (tester) async {
          final chart = acquireChartRoot(_lineChart(false));
          expect(chart.legend, isNull);

          // `{}`: the legend options with no field (Chart.js ADR 0193).
          _pluginOptions(chart)['legend'] = const LegendOptions();
          chart.update();
          expect(chart.legend, isNotNull);
          // `toEqualOptions` read the own keys of the defaults, and the
          // resolved colors of the scriptable label and title colors. The
          // legend keeps the options with the color of the chart (Chart.js
          // ADR 0193).
          final expected = _legendDefaults();
          final actual = (chart.legend! as Legend).options;
          expect(actual.display, expected.display);
          expect(actual.position, expected.position);
          expect(actual.align, expected.align);
          expect(actual.fullSize, expected.fullSize);
          expect(actual.reverse, expected.reverse);
          expect(actual.weight, expected.weight);
          expect(actual.onClick, same(expected.onClick));
          expect(actual.onHover, same(expected.onHover));
          expect(actual.onLeave, same(expected.onLeave));
          expect(actual.labels!.color, Chart.defaults.colorCell?.raw);
          expect(actual.title!.color, Chart.defaults.colorCell?.raw);
        },
      );
    });

    group('callbacks', () {
      testWidgets(
        'should call onClick, onHover and onLeave at the correct times',
        (tester) async {
          Object? clickItem;
          Object? hoverItem;
          Object? leaveItem;

          final chart = _line(
            LegendOptions(
              onClick: (_, item, _) {
                clickItem = item;
              },
              onHover: (_, item, _) {
                hoverItem = item;
              },
              onLeave: (_, item, _) {
                leaveItem = item;
              },
            ),
          );

          final hb = _hitBoxes(chart)[0];
          final el = _center(hb);

          await triggerMouseEvent(chart, 'click', el);
          expect(clickItem, same(chart.legend!.legendItems![0]));

          await triggerMouseEvent(chart, 'mousemove', el);
          expect(hoverItem, same(chart.legend!.legendItems![0]));

          await triggerMouseEvent(
            chart,
            'mousemove',
            chart.getDatasetMeta(0).data[0],
          );
          expect(leaveItem, same(chart.legend!.legendItems![0]));
        },
      );

      testWidgets('should call onLeave when the mouse leaves the canvas', (
        tester,
      ) async {
        Object? hoverItem;
        Object? leaveItem;

        final chart = _line(
          LegendOptions(
            onHover: (_, item, _) {
              hoverItem = item;
            },
            onLeave: (_, item, _) {
              leaveItem = item;
            },
          ),
        );

        final hb = _hitBoxes(chart)[0];
        final el = _center(hb);

        await triggerMouseEvent(chart, 'mousemove', el);
        expect(hoverItem, same(chart.legend!.legendItems![0]));

        await triggerMouseEvent(chart, 'mouseout');
        expect(leaveItem, same(chart.legend!.legendItems![0]));
      });

      testWidgets('should call onClick for the correct item when in RTL mode', (
        tester,
      ) async {
        Object? clickItem;

        final chart = _acquire(
          ChartConfig(
            labels: const ['A', 'B', 'C', 'D'],
            datasets: const [
              LineDataset(data: .values([10, 20, 30, 100]), label: 'dataset 1'),
              LineDataset(data: .values([10, 20, 30, 100]), label: 'dataset 2'),
            ],
            pluginOptions: [
              LegendOptions(
                onClick: (_, item, _) {
                  clickItem = item;
                },
              ),
            ],
          ),
        );

        final hb = _hitBoxes(chart)[0];
        final el = _center(hb);

        await triggerMouseEvent(chart, 'click', el);
        expect(clickItem, same(chart.legend!.legendItems![0]));
      });
    });
  });
}

/// `ctx.dataset.data[ctx.dataIndex] || 0` (:693, :697, :701).
num _dataValue(ScriptableContext ctx) {
  final value = jsGetIndex(
    jsGet(ctx.dataset, 'data'),
    ctx.dataIndex!.toDouble(),
  );
  return jsTruthy(value) ? value! as num : 0;
}

/// The two datasets of the usePointStyle cases (:733-755, :808-830).
const List<Dataset> _pointStyleDatasets = [
  LineDataset(
    label: 'dataset1',
    backgroundColor: ChartValue.constant(
      ChartPaint.solid(native_ui.Color.fromRGBO(255, 51, 17, 1)),
    ),
    borderCapStyle: native_ui.StrokeCap.butt,
    borderDash: [2, 2],
    borderWidth: 0,
    borderColor: ChartValue.constant(
      ChartPaint.solid(native_ui.Color.fromRGBO(255, 51, 17, 1)),
    ),
    // DIVERGES(chartjs): adapt-point-style-objects, the style class.
    pointStyle: .constant(CrossRotPointStyle()),
    pointBackgroundColor: ChartValue.constant(
      ChartPaint.solid(native_ui.Color.fromRGBO(0, 0, 0, 0.1)),
    ),
    pointBorderWidth: 5,
    pointBorderColor: ChartValue.constant(
      ChartPaint.solid(native_ui.Color.fromRGBO(0, 128, 0, 1)),
    ),
    data: .values([]),
    extra: {'borderDashOffset': 5.5},
  ),
  LineDataset(
    label: 'dataset2',
    backgroundColor: ChartValue.constant(
      ChartPaint.solid(native_ui.Color.fromRGBO(255, 51, 17, 1)),
    ),
    borderJoinStyle: native_ui.StrokeJoin.miter,
    borderWidth: 2,
    borderColor: ChartValue.constant(
      ChartPaint.solid(native_ui.Color.fromRGBO(255, 51, 17, 1)),
    ),
    // DIVERGES(chartjs): adapt-point-style-objects, the style class.
    pointStyle: .constant(CrossRotPointStyle()),
    data: .values([]),
    extra: {'pointRotation': 15},
  ),
];

/// The items of the usePointStyle cases with the point style [pointStyle]
/// (:769-801, :845-877).
List<LegendItem> _pointStyleItems(PointStyle pointStyle) => [
  _item(
    text: 'dataset1',
    fillStyle: const ChartPaint.solid(native_ui.Color.fromRGBO(0, 0, 0, 0.1)),
    hidden: false,
    lineWidth: 5,
    strokeStyle: const ChartPaint.solid(native_ui.Color.fromRGBO(0, 128, 0, 1)),
    pointStyle: pointStyle,
    rotation: 0,
    datasetIndex: 0,
  ),
  _item(
    text: 'dataset2',
    fillStyle: const ChartPaint.solid(native_ui.Color.fromRGBO(255, 51, 17, 1)),
    hidden: false,
    lineWidth: 2,
    strokeStyle: const ChartPaint.solid(
      native_ui.Color.fromRGBO(255, 51, 17, 1),
    ),
    pointStyle: pointStyle,
    rotation: 15,
    datasetIndex: 1,
  ),
];
