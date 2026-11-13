import 'package:chart_benchmark_lab/benchmark/config.dart';
import 'package:chart_benchmark_lab/benchmark/controller.dart'
    show chartJsDataOnlyUpdates;
import 'package:chart_benchmark_lab/benchmark/data.dart';
import 'package:chart_benchmark_lab/charts/chart_adapter.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart' as cj;
// The test reads the chart of the widget, as the tests of the package do.
import 'package:flutter_chartjs_port/src/platform/chart_host.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// The presets of `tool/perf_matrix.dart`.
BenchmarkConfig _preset(ChartType type, {required bool full}) => full
    ? BenchmarkConfig(
        type: type,
        count: 24,
        markers: true,
        fill: true,
        curved: true,
        axes: true,
        grid: true,
        alternateColors: true,
      )
    : BenchmarkConfig(type: type, count: 24);

/// Each cell qualifies for the data-only path of Chart.js ADR 0098: the
/// alternating colors of the full preset are a native indexed style (Chart.js
/// ADR 0100). A change here is a change of the measurement.
///
/// A sankey chart takes the raw config of the Chart.js port, which has no
/// data-only path: each tick is a full update, with one layout.
void main() {
  setUpAll(() => cj.Chart.register(cj.registerables));

  for (final type in ChartType.values) {
    for (final full in [false, true]) {
      testWidgets('chartjs ${type.name} ${full ? 'full' : 'plain'}: the path '
          'of a tick of new data', (tester) async {
        var layouts = 0;
        final spy = <String, Object?>{
          'id': r'$dataOnlyCells',
          'supportsDataUpdates': true,
          'beforeLayout': (Object? chart, Object? args, Object? options) {
            layouts++;
          },
        };
        cj.Chart.register([spy]);
        addTearDown(() => cj.Chart.unregister([spy]));

        final generator = DatasetGenerator(24, 7);
        final config = _preset(type, full: full);
        Widget scene(int step) => MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 600,
                height: 350,
                child: BenchmarkChart(
                  library: ChartLibrary.chartjs,
                  config: config,
                  frame: generator.frame(step),
                  size: const Size(600, 350),
                ),
              ),
            ),
          ),
        );
        await tester.pumpWidget(scene(0));
        await tester.pump();
        // The first resize notification ends the plan of the first update.
        await tester.pumpWidget(scene(1));

        final chart = cj.Chart.getChart(
          tester.renderObject<RenderChartHost>(find.byType(ChartHost)).canvas,
        )!;
        final expectedLayouts = !chartJsDataOnlyUpdates
            ? 1
            // The radius of a bubble comes from the data, so the overflow and
            // the layout change with the largest item. The sankey chart has
            // no data-only path.
            : type == ChartType.bubble || type == ChartType.sankey
            ? 1
            : 0;
        for (var step = 2; step < 6; step++) {
          layouts = 0;
          await tester.pumpWidget(scene(step));
          expect(layouts, expectedLayouts, reason: 'step $step');
        }
        expect(chart.updateData(), type != ChartType.sankey);
      });
    }
  }
}
