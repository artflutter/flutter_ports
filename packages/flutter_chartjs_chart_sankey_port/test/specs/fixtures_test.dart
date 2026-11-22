// Ported from chartjs-chart-sankey v0.19.1 test/specs/fixtures.spec.js (MIT, Jukka Kurkela).
@TestOn('vm')
library;

import 'dart:math';

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_chart_sankey_port/flutter_chartjs_chart_sankey_port.dart';
import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/index.dart';

void main() {
  group('fixtures', specs());

  group('index', () {
    test('should register controller and element', () {
      expect(Chart.registry.getController('sankey'), isNotNull);
      expect(Chart.registry.getElement('flow'), isNotNull);
    });

    testWidgets('should create a sankey chart without data', (tester) async {
      final chart = acquireChartRoot(
        ChartConfigurationScope()
          ..type = 'sankey'
          ..data = ChartDataScope()
          ..options = mergeExtra(ChartOptionsScope(), {
            'plugins': {
              'legend': {'display': false},
              'title': {
                'display': true,
                'text': ['OD pairs on hexagon level'],
              },
            },
          }),
      );

      expect(chart.config.type, 'sankey');
      expect(jsGet(chart.data, 'datasets'), isEmpty);
    });

    testWidgets('should lay out a vertical sankey from top to bottom', (
      tester,
    ) async {
      final chart = acquireChartRoot(
        ChartConfigLowering(
          const ChartConfig(
            datasets: [
              SankeyDataset(
                data: [
                  SankeyDataPoint(flow: 10, from: 'A', to: 'B'),
                  SankeyDataPoint(flow: 4, from: 'A', to: 'C'),
                ],
                // DIVERGES(sankey): adapt-sankey-option-enums, the enum value.
                orientation: SankeyOrientation.vertical,
              ),
            ],
            animation: ChartAnimation.none,
          ),
        ).lower(),
      );

      final flow = chart.getDatasetMeta(0).data[0] as Flow;
      expect(jsGet(flow.options, 'orientation'), SankeyOrientation.vertical);
      expect(flow.y, lessThan(flow.y2));
      expect(flow.width, greaterThan(0));
      expect(flow.height, 0);
    });

    testWidgets('should reserve space for custom node widths', (tester) async {
      final chart = acquireChartRoot(
        ChartConfigLowering(
          const ChartConfig(
            datasets: [
              SankeyDataset(
                data: [
                  SankeyDataPoint(flow: 10, from: 'A', to: 'B'),
                  SankeyDataPoint(flow: 4, from: 'A', to: 'C'),
                ],
                nodeWidth: 18,
              ),
            ],
            animation: ChartAnimation.none,
          ),
        ).lower(),
      );
      // Vitest's spyOn calls through by default, unlike Jasmine's.
      //
      // The spy is a recording context in `chart.ctx`: the controller draws
      // its nodes on the context of the chart (controller.ts:540). It
      // records each call and draws nothing.
      final target = chart.ctx!;
      final spy = RecordingContext(target);
      chart.ctx = spy;
      addTearDown(() => chart.ctx = target);

      chart.draw();

      final rightEdges = [
        for (final call in spy.getCalls())
          if (call case {
            'name': 'fillRect',
            'args': [final double x, _, final double width, ...],
          })
            x + width,
      ];
      expect(rightEdges, isNotEmpty);
      expect(rightEdges.reduce(max), closeTo(chart.width - 3, 0.000005));
    });
  });
}
