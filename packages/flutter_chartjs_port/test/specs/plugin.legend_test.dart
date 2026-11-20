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
// The spec builds charts of flutter_chartjs_port, which does not export lib/src
// yet.
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/index.dart' as fixture;
import '../support/legend_item.dart';

// `Chart` is the class of core.controller.dart, with the static members
// `Chart.registry` and `Chart.defaults`. `window.Chart.helpers.color` is
// `color` of helpers.color.dart. `toEqual` of the legend items is
// [_itemsEqual]: `legendItemEquals` of test/support/legend_item.dart for
// each item. `toEqual` of the defaults reads the own keys and the cells of
// the typed scopes, and `jasmine.any(Function)` is `isA<Function>()`.
// `toEqualOptions` is the matcher of chartjs_test_utils.
//
// Each chart case is a `testWidgets` case with the harness of Chart.js ADR
// 0022, section 2. `chart.legend` is the field of `Chart`: Dart `null`
// stands for JS `undefined`. The spec reads `legendItems` through
// `types.LegendElement` and `legendHitBoxes` through a cast to `Legend`
// (Chart.js ADR 0038, section 6). Hit boxes expose native typed fields. A
// write into `chart.options` is the write through `operator []=`
// of the option resolver, the `set` trap of upstream.
// `jasmine.triggerMouseEvent` is triggerMouseEvent of chartjs_test_utils
// (Chart.js ADR 0022, section 6).

/// `chart.legend.legendHitBoxes`.
List<LegendHitBox> _hitBoxes(Chart chart) =>
    (chart.legend! as Legend).legendHitBoxes;

/// `chart.options.plugins`, the option resolver of the plugins.
JsObjectFace _pluginOptions(Chart chart) =>
    jsGet(chart.options, 'plugins')! as JsObjectFace;

/// `chart.options.plugins.legend`, the option resolver of the legend.
JsObjectFace _legendOptions(Chart chart) =>
    jsGet(_pluginOptions(chart), 'legend')! as JsObjectFace;

/// `Chart.defaults.plugins.legend`.
LegendOptionsScope _legendDefaults() =>
    (Chart.defaults.pluginsCell!.raw! as PluginOptionsByTypeScope)
            .legendCell!
            .raw!
        as LegendOptionsScope;

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
    data: [],
    extra: {
      'borderCapStyle': native_ui.StrokeCap.butt,
      'borderDash': <double>[2, 2],
      'borderDashOffset': 5.5,
    },
  ),
  BarDataset(
    label: 'dataset2',
    hidden: true,
    data: const [],
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
    data: const [],
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
    data: [],
    extra: {'borderDashOffset': 5.5},
  ),
  LineDataset(
    label: 'dataset2',
    hidden: true,
    borderJoinStyle: native_ui.StrokeJoin.round,
    data: [],
  ),
  LineDataset(
    label: 'dataset3',
    borderWidth: 10,
    borderColor: ChartValue.constant(
      ChartPaint.solid(native_ui.Color.fromRGBO(0, 128, 0, 1)),
    ),
    // DIVERGES(chartjs): adapt-point-style-objects, the style class.
    pointStyle: CrossRotPointStyle(),
    fill: FillTarget.none,
    data: [],
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
// A Map config: the config update cases write the raw options of the chart
// by name, and the typed API has no form for a legend set to `false`.
AnyObject _lineChart([Object? legendOptions]) => <String, Object?>{
  'type': 'line',
  'data': <String, Object?>{
    'labels': <Object?>['A', 'B', 'C', 'D'],
    'datasets': <Object?>[
      <String, Object?>{
        'data': <Object?>[10, 20, 30, 100],
      },
    ],
  },
  if (legendOptions != null)
    'options': <String, Object?>{
      'plugins': <String, Object?>{'legend': legendOptions},
    },
};

/// A line chart of four labels and one dataset with the legend [legend]
/// (the callbacks cases).
Chart _line(ChartLegend legend) => _acquire(
  ChartConfig(
    type: ChartKind.line,
    labels: const ['A', 'B', 'C', 'D'],
    datasets: const [
      LineDataset(data: [10, 20, 30, 100]),
    ],
    legend: legend,
  ),
);

void main() {
  // Test the rectangle element
  group('Legend block tests', () {
    group('auto', fixture.specs('plugin.legend'));

    test('should have the correct default config', () {
      final actual = _legendDefaults();
      // `toEqual`: the own keys of each object and the value of each key.
      expect(
        actual.ownKeys,
        unorderedEquals(<Object>[
          OptionKey.display,
          OptionKey.position,
          OptionKey.align,
          OptionKey.fullSize,
          OptionKey.reverse,
          OptionKey.weight,
          OptionKey.onClick,
          OptionKey.onHover,
          OptionKey.onLeave,
          OptionKey.labels,
          OptionKey.title,
        ]),
      );
      expect(actual.displayCell?.raw, true);
      expect(actual.positionCell?.raw, ChartPosition.top);
      expect(actual.alignCell?.raw, ChartAlign.center);
      expect(actual.fullSizeCell?.raw, true);
      expect(actual.reverseCell?.raw, false);
      expect(actual.weightCell?.raw, 1000);

      // a callback that will handle
      // jasmine.any(Function): each function value of the expected object.
      expect(actual.onClickCell?.raw, isA<Function>());
      expect(actual.onHoverCell?.raw, isNull);
      expect(actual.onLeaveCell?.raw, isNull);

      final labels = actual.labelsCell!.raw! as LegendLabelOptionsScope;
      expect(
        labels.ownKeys,
        unorderedEquals(<Object>[
          OptionKey.color,
          OptionKey.boxWidth,
          OptionKey.padding,
          OptionKey.generateLabels,
        ]),
      );
      expect(labels.colorCell?.raw, isA<Function>());
      expect(labels.boxWidthCell?.raw, 40);
      expect(labels.paddingCell?.raw, 10);
      expect(labels.generateLabelsCell?.raw, isA<Function>());

      final title = actual.titleCell!.raw! as LegendTitleOptionsScope;
      expect(
        title.ownKeys,
        unorderedEquals(<Object>[
          OptionKey.color,
          OptionKey.display,
          OptionKey.position,
          OptionKey.text,
        ]),
      );
      expect(title.colorCell?.raw, isA<Function>());
      expect(title.displayCell?.raw, false);
      expect(title.positionCell?.raw, ChartAlign.center);
      expect(title.textCell?.raw, ['']);
    });

    testWidgets('should update bar chart correctly', (tester) async {
      final chart = _acquire(
        ChartConfig(
          type: ChartKind.bar,
          datasets: _barDatasets(),
          labels: const [],
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
        const ChartConfig(
          type: ChartKind.line,
          datasets: _lineDatasets,
          labels: [],
        ),
      );

      expect(
        chart.legend!.legendItems,
        _itemsEqual([_lineItem1(), _lineItem2(), _lineItem3()]),
      );
    });

    testWidgets('should reverse correctly', (tester) async {
      final chart = _acquire(
        const ChartConfig(
          type: ChartKind.line,
          datasets: _lineDatasets,
          labels: [],
          legend: ChartLegend(reverse: true),
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
          type: ChartKind.bar,
          datasets: _barDatasets(legendHidden: true, borderRadius: 10),
          labels: const [],
          legend: ChartLegend(
            extra: {
              'labels': {
                'filter': (LegendItem legendItem, Object? data) {
                  final dataset = jsGetIndex(
                    jsGet(data, 'datasets'),
                    legendItem.datasetIndex!.toDouble(),
                  );
                  return !jsTruthy(jsGet(dataset, 'legendHidden'));
                },
              },
            },
          ),
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
          type: ChartKind.line,
          datasets: _lineDatasets,
          labels: const [],
          legend: ChartLegend(
            extra: {
              'labels': {
                'sort': (LegendItem a, LegendItem b, Object? data) =>
                    b.datasetIndex! > a.datasetIndex! ? 1 : -1,
              },
            },
          ),
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
      void makeChart() {
        // A Map config: the typed API has no form for `labels: false`, a
        // value outside the type of the key.
        acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
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
            ],
            'labels': <Object?>[],
          },
          'options': <String, Object?>{
            'plugins': <String, Object?>{
              'legend': <String, Object?>{'labels': false},
            },
          },
        });
      }

      expect(makeChart, returnsNormally);
    });

    testWidgets('should not draw legend items outside of the chart bounds', (
      tester,
    ) async {
      final chart = _acquire(
        ChartConfig(
          type: ChartKind.line,
          datasets: [
            for (final n in [1, 2, 3])
              LineDataset(label: 'dataset$n', data: const []),
          ],
          labels: const [],
          legend: const ChartLegend(position: ChartPosition.right),
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
          type: ChartKind.doughnut,
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
          legend: ChartLegend(
            usePointStyle: true,
            position: ChartPosition.right,
            align: ChartAlign.center,
            extra: {
              // DIVERGES(chartjs): adapt-point-style-objects, the style
              // class.
              'labels': {'pointStyle': RectPointStyle()},
              'maxWidth': 860,
            },
          ),
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
          type: ChartKind.line,
          datasets: [LineDataset(label: 'dataset1', data: [])],
          labels: [],
          legend: ChartLegend(position: ChartPosition.right, boxHeight: 40),
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
          type: ChartKind.bar,
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
              data: [],
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
          type: ChartKind.bar,
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
              data: [],
              // The typed borderWidth is one number: an array goes through
              // `extra`.
              extra: {
                'borderWidth': <Object?>[5, 10, 15],
              },
            ),
          ],
          labels: [],
          legend: ChartLegend(
            extra: {
              'labels': {'useBorderRadius': true},
            },
          ),
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
            type: ChartKind.bar,
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
                data: const [5, 10, 15, 20],
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
          type: ChartKind.line,
          datasets: _pointStyleDatasets,
          labels: [],
          legend: ChartLegend(usePointStyle: true),
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
            type: ChartKind.line,
            datasets: _pointStyleDatasets,
            labels: [],
            legend: ChartLegend(
              usePointStyle: true,
              extra: {
                // DIVERGES(chartjs): adapt-point-style-objects, the style
                // class.
                'labels': {'pointStyle': StarPointStyle()},
              },
            ),
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
          type: ChartKind.doughnut,
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
          type: ChartKind.bar,
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
              data: [120, 23, 24, 45, 51],
            ),
          ],
          responsive: true,
          onClick: (_, _, _) {},
          legend: const ChartLegend(display: true),
        ),
      );
      expect(
        (chart.legend! as Legend).options.onClick,
        same(_legendDefaults().onClickCell?.raw),
      );
    });

    testWidgets('should read labels.color from chart options', (tester) async {
      final chart = _acquire(
        const ChartConfig(
          type: ChartKind.bar,
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
              data: [120, 23, 24, 45, 51],
            ),
          ],
          responsive: true,
          legend: ChartLegend(display: true),
          // The chart option `color` has no typed field.
          extra: {
            'color': ChartPaint.solid(native_ui.Color.fromRGBO(0, 128, 0, 1)),
          },
        ),
      );
      expect(
        (chart.legend! as Legend).options.labels.color,
        const ChartPaint.solid(native_ui.Color.fromRGBO(0, 128, 0, 1)),
      );
      expect(
        (chart.legend! as Legend).options.title.color,
        const ChartPaint.solid(native_ui.Color.fromRGBO(0, 128, 0, 1)),
      );
    });

    group('config update', () {
      testWidgets('should update the options', (tester) async {
        final chart = acquireChart(
          _lineChart(<String, Object?>{'display': true}),
        );
        expect((chart.legend! as Legend).options.display, true);

        _legendOptions(chart)['display'] = false;
        chart.update();
        expect((chart.legend! as Legend).options.display, false);
      });

      testWidgets('should update the associated layout item', (tester) async {
        // A Map config: the spec writes the raw options of the chart by name.
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{},
          'options': <String, Object?>{
            'plugins': <String, Object?>{
              'legend': <String, Object?>{
                'fullSize': true,
                'position': ChartPosition.top,
                'weight': 150,
              },
            },
          },
        });

        // `chart.legend` as a layout box, read at each assertion, as
        // upstream does.
        Legend legend() => chart.legend! as Legend;
        expect(legend().fullSize, true);
        expect(legend().position, ChartPosition.top);
        expect(legend().weight, 150);

        _legendOptions(chart)
          ..['fullSize'] = false
          ..['position'] = ChartPosition.left
          ..['weight'] = 42;
        chart.update();

        expect(legend().fullSize, false);
        expect(legend().position, ChartPosition.left);
        expect(legend().weight, 42);
      });

      testWidgets('should remove the legend if the new options are false', (
        tester,
      ) async {
        final chart = acquireChart(_lineChart());
        expect(chart.legend, isNotNull);

        _pluginOptions(chart)['legend'] = false;
        chart.update();
        expect(chart.legend, isNull);
      });

      testWidgets(
        'should create the legend if the legend options are changed to exist',
        (tester) async {
          final chart = acquireChart(_lineChart(false));
          expect(chart.legend, isNull);

          _pluginOptions(chart)['legend'] = <String, Object?>{};
          chart.update();
          expect(chart.legend, isNotNull);
          // `toEqualOptions` read the own keys of the defaults, and the
          // resolved colors of the scriptable label and title colors. The
          // legend keeps the resolved `LegendOptions` (Chart.js ADR 0182).
          final expected = LegendOptions.of(_legendDefaults());
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
          expect(actual.labels.color, Chart.defaults.colorCell?.raw);
          expect(actual.title.color, Chart.defaults.colorCell?.raw);
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
            ChartLegend(
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
          ChartLegend(
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
            type: ChartKind.line,
            labels: const ['A', 'B', 'C', 'D'],
            datasets: const [
              LineDataset(data: [10, 20, 30, 100], label: 'dataset 1'),
              LineDataset(data: [10, 20, 30, 100], label: 'dataset 2'),
            ],
            legend: ChartLegend(
              onClick: (_, item, _) {
                clickItem = item;
              },
            ),
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
    pointStyle: CrossRotPointStyle(),
    pointBackgroundColor: ChartValue.constant(
      ChartPaint.solid(native_ui.Color.fromRGBO(0, 0, 0, 0.1)),
    ),
    pointBorderWidth: 5,
    pointBorderColor: ChartValue.constant(
      ChartPaint.solid(native_ui.Color.fromRGBO(0, 128, 0, 1)),
    ),
    data: [],
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
    pointStyle: CrossRotPointStyle(),
    data: [],
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
