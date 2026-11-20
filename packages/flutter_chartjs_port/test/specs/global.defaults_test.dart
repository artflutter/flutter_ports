// Ported from Chart.js v4.6.1 test/specs/global.defaults.tests.js (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-dash-lists, the dash patterns are lists of doubles.
// DIVERGES(chartjs): adapt-direct-colors, native color test inputs.
@TestOn('vm')
library;

import 'dart:ui' as native_ui;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/drop_extra_args.dart';
import '../support/legend_item.dart';

// `Chart.overrides` is the static getter of core.controller.dart. `toEqual`
// of the legend items is a list of `legendItemEquals` of
// test/support/legend_item.dart, one native `LegendItem` for each expected
// object: a key that the expected object does not have is a null field
// (`textAlign: undefined` and the others). Each case builds a chart:
// it is a `testWidgets` case with the harness of Chart.js ADR 0022, section
// 2. `chart.legend` is the field of `Chart`, and the spec reads
// `legendItems` through `types.LegendElement` (Chart.js ADR 0038, section
// 6).
//
// `spyOn(chart, 'update').and.callThrough()` (:110, :186) is _spyOnUpdate:
// a native plugin (Chart.js ADR 0144) whose beforeUpdate records each update
// of the chart (Chart.js ADR 0041, section 11 item 2). `Chart.update` stays a
// method.
// `expect(chart.update).toHaveBeenCalled()` is `expect(calls, isNotEmpty)`.

/// spyOn(chart, 'update').and.callThrough() (global.defaults.tests.js:110,
/// :186): a plugin whose beforeUpdate (core.controller.js:490) records the
/// mode of each update of [chart]. It unregisters at the end of the test.
List<Object?> _spyOnUpdate(Chart chart) {
  final calls = <Object?>[];
  final plugin = Plugin<Object?>(
    id: r'$updateSpy',
    beforeUpdate: (c, args, _) {
      if (identical(c, chart)) calls.add(args.mode);
      return true;
    },
  );
  Chart.register([plugin]);
  addTearDown(() => Chart.unregister([plugin]));
  return calls;
}

/// `config.plugins.legend.onClick` of the override scope [config] of
/// `Chart.overrides` (:113, :118, :189, :194).
Object? _onClick(Object? config) =>
    jsGet(jsGet(jsGet(config, 'plugins'), 'legend'), 'onClick');

/// The config of the doughnut and polar area cases of [type] (:4-15, :98-109,
/// :125-136, :174-185).
ChartConfigurationScope _config(String type) => (ChartConfigurationScope()
  ..type = type
  ..data = (ChartDataScope()
    ..labels = <Object?>['label1', 'label2', 'label3']
    ..datasets = [
      mergeExtra(
        type == 'polarArea'
            ? PolarAreaControllerDatasetOptionsScope()
            : DoughnutControllerDatasetOptionsScope(),
        <String, Object?>{
          'data': <Object?>[10, 20, double.nan],
          'backgroundColor': <Object?>[
            const ChartPaint.solid(native_ui.Color.fromRGBO(255, 0, 0, 1)),
            const ChartPaint.solid(native_ui.Color.fromRGBO(0, 128, 0, 1)),
            const ChartPaint.solid(native_ui.Color.fromRGBO(0, 0, 255, 1)),
          ],
          'borderWidth': 2,
          'borderColor': const ChartPaint.solid(
            native_ui.Color.fromRGBO(0, 0, 0, 1),
          ),
        },
      ),
    ]));

/// The colors of the expected legend items.
const ChartPaint _red = ChartPaint.solid(
  native_ui.Color.fromRGBO(255, 0, 0, 1),
);
const ChartPaint _green = ChartPaint.solid(
  native_ui.Color.fromRGBO(0, 128, 0, 1),
);
const ChartPaint _blue = ChartPaint.solid(
  native_ui.Color.fromRGBO(0, 0, 255, 1),
);
const ChartPaint _gray = ChartPaint.solid(
  native_ui.Color.fromRGBO(102, 102, 102, 1),
);
const ChartPaint _black = ChartPaint.solid(
  native_ui.Color.fromRGBO(0, 0, 0, 1),
);

void main() {
  group('Default Configs', () {
    group('Doughnut Chart', () {
      testWidgets('should return correct legend label objects', (tester) async {
        final chart = acquireChartRoot(_config('doughnut'));

        LegendItem item(String text, ChartPaint fillStyle, int index) =>
            LegendItem(
              text: [text],
              fillStyle: fillStyle,
              index: index,
              fontColor: _gray,
              strokeStyle: _black,
              lineWidth: 2,
              lineDash: [],
              lineDashOffset: 0,
            );

        expect(chart.legend!.legendItems, [
          legendItemEquals(item('label1', _red, 0)),
          legendItemEquals(item('label2', _green, 1)),
          legendItemEquals(item('label3', _blue, 2)),
        ]);
      });

      testWidgets(
        'should return correct legend label objects with border radius',
        (tester) async {
          final chart = acquireChartRoot(
            ChartConfigurationScope()
              ..type = 'doughnut'
              ..data = (ChartDataScope()
                ..labels = <Object?>['label1']
                ..datasets = [
                  mergeExtra(
                    DoughnutControllerDatasetOptionsScope(),
                    <String, Object?>{
                      'data': <Object?>[10],
                      'backgroundColor': <Object?>[
                        const ChartPaint.solid(
                          native_ui.Color.fromRGBO(255, 0, 0, 1),
                        ),
                      ],
                      'borderWidth': 2,
                      'borderColor': const ChartPaint.solid(
                        native_ui.Color.fromRGBO(0, 0, 0, 1),
                      ),
                      'borderDash': <double>[1, 2, 3],
                      'borderDashOffset': 1,
                      'borderJoinStyle': native_ui.StrokeJoin.miter,
                      'borderRadius': 3,
                    },
                  ),
                ])
              ..options = mergeExtra((ChartOptionsScope()), {
                'plugins': <String, Object?>{
                  'legend': <String, Object?>{
                    'labels': <String, Object?>{
                      'useBorderRadius': true,
                      'borderRadius': 5,
                      'textAlign': TextAlign.left,
                    },
                  },
                },
              }),
          );

          expect(chart.legend!.legendItems, [
            legendItemEquals(
              LegendItem(
                text: ['label1'],
                fillStyle: _red,
                index: 0,
                fontColor: _gray,
                strokeStyle: _black,
                textAlign: TextAlign.left,
                lineWidth: 2,
                lineDash: [1, 2, 3],
                lineDashOffset: 1,
                lineJoin: native_ui.StrokeJoin.miter,
                borderRadius: const BorderRadius.all(Radius.circular(5)),
              ),
            ),
          ]);
        },
      );

      testWidgets('should hide the correct arc when a legend item is clicked', (
        tester,
      ) async {
        final config = jsGet(Chart.overrides, 'doughnut');
        final chart = acquireChartRoot(_config('doughnut'));
        final calls = _spyOnUpdate(chart);

        final legendItem = chart.legend!.legendItems![0];
        callDroppingExtraArgs(_onClick(config), [
          null,
          legendItem,
          chart.legend,
        ]);

        expect(chart.getDataVisibility(0), false);
        expect(calls, isNotEmpty);

        callDroppingExtraArgs(_onClick(config), [
          null,
          legendItem,
          chart.legend,
        ]);
        expect(chart.getDataVisibility(0), true);
      });
    });

    group('Polar Area Chart', () {
      testWidgets('should return correct legend label objects', (tester) async {
        final chart = acquireChartRoot(_config('polarArea'));

        LegendItem item(String text, ChartPaint fillStyle, int index) =>
            LegendItem(
              text: [text],
              fillStyle: fillStyle,
              fontColor: _gray,
              index: index,
              strokeStyle: _black,
              lineWidth: 2,
            );

        expect(chart.legend!.legendItems, [
          legendItemEquals(item('label1', _red, 0)),
          legendItemEquals(item('label2', _green, 1)),
          legendItemEquals(item('label3', _blue, 2)),
        ]);
      });

      testWidgets('should hide the correct arc when a legend item is clicked', (
        tester,
      ) async {
        final config = jsGet(Chart.overrides, 'polarArea');
        final chart = acquireChartRoot(_config('polarArea'));
        final calls = _spyOnUpdate(chart);

        final legendItem = chart.legend!.legendItems![0];
        callDroppingExtraArgs(_onClick(config), [
          null,
          legendItem,
          chart.legend,
        ]);

        expect(chart.getDataVisibility(0), false);
        expect(calls, isNotEmpty);

        callDroppingExtraArgs(_onClick(config), [
          null,
          legendItem,
          chart.legend,
        ]);
        expect(chart.getDataVisibility(0), true);
      });
    });
  });
}
