// Ported from chartjs-chart-sankey v0.19.1 test/specs/node-padding.spec.js (MIT, Jukka Kurkela).
// ignore_for_file: file_names
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_chart_sankey_port/flutter_chartjs_chart_sankey_port.dart';
import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_test/flutter_test.dart';

// Same energy data as resize.spec.js: column 0 has five nodes (Oil, Natural
// gas, Coal, Nuclear, Renewables), so nodePadding gaps actually show up.
List<SankeyDataPoint> _data() => [
  const SankeyDataPoint(flow: 15, from: 'Oil', to: 'Fossil fuels'),
  const SankeyDataPoint(flow: 20, from: 'Natural gas', to: 'Fossil fuels'),
  const SankeyDataPoint(flow: 25, from: 'Coal', to: 'Fossil fuels'),
  const SankeyDataPoint(flow: 60, from: 'Fossil fuels', to: 'Energy'),
  const SankeyDataPoint(flow: 10, from: 'Nuclear', to: 'Energy'),
  const SankeyDataPoint(flow: 30, from: 'Renewables', to: 'Energy'),
  const SankeyDataPoint(flow: 40, from: 'Energy', to: 'Electricity'),
  const SankeyDataPoint(flow: 35, from: 'Energy', to: 'Heat'),
  const SankeyDataPoint(flow: 25, from: 'Energy', to: 'Lost'),
];

Chart _buildSankey(double devicePixelRatio) => acquireChartRoot(
  lowerForTest(
    raw(
      ChartConfig(
        datasets: [
          raw(SankeyDataset(data: _data()), const {'nodePadding': 10}),
        ],
        animation: ChartAnimation.none,
        maintainAspectRatio: false,
      ),
      <String, Object?>{'devicePixelRatio': devicePixelRatio},
    ),
  ),
  const AcquireOptions(canvas: HarnessCanvas(width: 800, height: 400)),
);

Chart _buildSankeyWithPadding(Object? nodePadding) => acquireChartRoot(
  lowerForTest(
    ChartConfig(
      datasets: [
        raw(SankeyDataset(data: _data()), {'nodePadding': nodePadding}),
      ],
      animation: ChartAnimation.none,
      maintainAspectRatio: false,
    ),
  ),
  const AcquireOptions(canvas: HarnessCanvas(width: 800, height: 400)),
);

void main() {
  group('nodePadding', () {
    testWidgets('lays out flows identically regardless of devicePixelRatio '
        '(#CSS-pixels)', (tester) async {
      final chart1x = _buildSankey(1);
      final chart2x = _buildSankey(2);

      final flows1x = chart1x.getDatasetMeta(0).data.cast<Flow>();
      final flows2x = chart2x.getDatasetMeta(0).data.cast<Flow>();

      expect(flows1x.length, greaterThan(0));
      expect(flows1x.length, flows2x.length);

      for (var i = 0; i < flows1x.length; i++) {
        final flow1x = flows1x[i];
        final flow2x = flows2x[i];
        expect(flow2x.x, closeTo(flow1x.x, 0.005), reason: 'flow $i x');
        expect(flow2x.y, closeTo(flow1x.y, 0.005), reason: 'flow $i y');
        expect(flow2x.x2, closeTo(flow1x.x2, 0.005), reason: 'flow $i x2');
        expect(flow2x.y2, closeTo(flow1x.y2, 0.005), reason: 'flow $i y2');
        expect(
          flow2x.height,
          closeTo(flow1x.height, 0.005),
          reason: 'flow $i height',
        );
      }
    });

    testWidgets('calls a function-form nodePadding with a SankeyNode, not a '
        'Chart.js scriptable context (#265)', (tester) async {
      final seenNodes = <Object?>[];

      _buildSankeyWithPadding((Object? node) {
        seenNodes.add(node);
        return 10;
      });

      // The dataset-level `_scriptable: true` default would make Chart.js
      // call this itself with its own ScriptableContext (which has `chart`
      // and `dataIndex`) before the controller ever sees the raw option. The
      // sankey-specific `nodePadding` descriptor exception is what makes
      // `node` below a real SankeyNode instead.
      expect(seenNodes.length, greaterThan(0));
      for (final node in seenNodes) {
        // A SankeyNode is a class of the port: it has a `key` and no member
        // of a scriptable context.
        expect(node, isA<SankeyNode>());
      }
    });

    testWidgets('shifts only the node below the keyed one when using a Record '
        'of per-node gaps', (tester) async {
      // A, B, C are three unconnected sources stacked (in that order) in
      // column 0, all flowing into the single sink Z. Comparing the parsed
      // (pre-pixel, pre-axis-rescale) `y` of each source's flow isolates the
      // padding math from the y-axis's max (which shifts between the two
      // charts below, so pixel positions alone would not be comparable).
      List<SankeyDataPoint> columnData() => [
        const SankeyDataPoint(flow: 10, from: 'A', to: 'Z'),
        const SankeyDataPoint(flow: 10, from: 'B', to: 'Z'),
        const SankeyDataPoint(flow: 10, from: 'C', to: 'Z'),
      ];

      // A fixed CSS canvas height, matched by both charts below, makes the
      // nodePadding-in-CSS-pixels -> flow-units scale factor identical and
      // known: scale = maxY-before-padding / chart.height = 30 / 300 = 0.1,
      // so a 30 CSS pixel increase in the B -> C gap is exactly a 3 flow-unit
      // increase in C's parsed y.
      List<double> fromYs(Object? nodePadding) {
        final chart = acquireChartRoot(
          lowerForTest(
            ChartConfig(
              datasets: [
                raw(SankeyDataset(data: columnData()), {
                  'nodePadding': nodePadding,
                }),
              ],
              animation: ChartAnimation.none,
            ),
          ),
          const AcquireOptions(canvas: HarnessCanvas(width: 300, height: 300)),
        );
        final controller = chart.getDatasetMeta(0).controller!;
        return [
          for (var i = 0; i < 3; i++) jsToNumber(controller.getParsed(i)!.y),
        ];
      }

      final base = fromYs(10);
      final withGap = fromYs(<String, Object?>{
        'B': const SankeyNodeGap(after: 40),
      });

      // A is the topmost node in the column and never receives an offset.
      expect(base[0], closeTo(0, 5e-7));
      expect(withGap[0], closeTo(0, 5e-7));

      // B's own gap to A is untouched -- only B's `after` (the gap below B)
      // changed, which does not affect the gap above it.
      expect(withGap[1], closeTo(base[1], 5e-7));

      // C sits below B, so raising B's `after` from the default 10 to 40 CSS
      // pixels must push C down by exactly that 30 CSS pixel difference,
      // scaled to flow units.
      expect(withGap[2] - base[2], closeTo(3, 5e-7));
    });
  });
}
