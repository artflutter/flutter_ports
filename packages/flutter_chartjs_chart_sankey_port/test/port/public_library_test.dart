// Original code, not ported from chartjs-chart-sankey: the public library.
@TestOn('vm')
library;

// The public library next to the app library of the host and Material, as
// an app imports them. `Flow` is also a Flutter widget name: the sankey
// library has a prefix where the test names the element.
import 'package:flutter_chartjs_chart_sankey_port/flutter_chartjs_chart_sankey_port.dart'
    hide Flow;
import 'package:flutter_chartjs_chart_sankey_port/flutter_chartjs_chart_sankey_port.dart'
    as sankey
    show Flow;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('a ChartView draws a sankey chart of typed data points', (
    tester,
  ) async {
    // test/flutter_test_config.dart registers `sankeyRegisterables`.
    expect(sankeyRegisterables, [
      SankeyController.jsClass,
      sankey.Flow.jsClass,
    ]);

    final config = ChartConfig(
      datasets: [
        SankeyDataset(
          data: const [
            SankeyDataPoint(from: 'a', to: 'b', flow: 10),
            SankeyDataPoint(from: 'a', to: 'c', flow: 5),
            SankeyDataPoint(from: 'b', to: 'c', flow: 10),
          ],
          colorFrom: const SankeyColor.constant(
            ChartPaint.solid(Color(0xFF4E79A7)),
          ),
          colorTo: const SankeyColor.constant(
            ChartPaint.solid(Color(0xFFF28E2B)),
          ),
          orientation: SankeyOrientation.horizontal,
          nodeMinSize: SankeyNodeValue.byNode((node) => 4),
        ),
      ],
      animation: ChartAnimation.none,
      maintainAspectRatio: false,
    );
    Chart? chart;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 400,
            height: 300,
            child: ChartView(
              config: config,
              onChartCreated: (created) => chart = created,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final meta = chart!.getDatasetMeta(0);
    final controller = meta.controller! as SankeyController;
    expect(controller.nodes.keys, ['a', 'b', 'c']);
    expect(controller.nodes['a']!.outFlow, 15);
    expect(controller.nodes['c']!.inFlow, 15);

    final flows = meta.data.cast<sankey.Flow>();
    expect(flows, hasLength(3));
    for (final flow in flows) {
      expect(flow.x, lessThan(flow.x2));
      expect(flow.height, greaterThan(0));
      expect(flow.progress, 1);
    }
    expect(flows.first.from, same(controller.nodes['a']));
    expect(flows.first.to, same(controller.nodes['b']));
  });
}
