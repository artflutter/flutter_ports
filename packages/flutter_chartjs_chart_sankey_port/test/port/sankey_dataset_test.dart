// Original code, not ported from chartjs-chart-sankey: the typed dataset.
@TestOn('vm')
library;

// The typed dataset of Sankey ADR 0004: each case shows one chart as a
// typed `ChartView` with the options of the dataset, and checks that it
// draws and that a hovered flow changes the draw.

import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_chart_sankey_port/flutter_chartjs_chart_sankey_port.dart'
    hide Flow;
import 'package:flutter_chartjs_chart_sankey_port/flutter_chartjs_chart_sankey_port.dart'
    as sankey
    show Flow;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const List<SankeyDataPoint> _flows = [
  SankeyDataPoint(from: 'A', to: 'B', flow: 10),
  SankeyDataPoint(from: 'A', to: 'C', flow: 5),
  SankeyDataPoint(from: 'B', to: 'D', flow: 6),
  SankeyDataPoint(from: 'C', to: 'D', flow: 4),
  SankeyDataPoint(from: 'C', to: 'E', flow: 1),
];

const _palette = <String, Color>{
  'A': Color(0xFF4F8FBA),
  'B': Color(0xFFF28E2B),
  'C': Color(0xFF59A14F),
  'D': Color(0xFFE15759),
  'E': Color(0xFFB07AA1),
};

const ChartPaint _grey = .solid(Color(0xFF555555));
const ChartPaint _green = .solid(Color(0x8C2EA043));
const ChartPaint _red = .solid(Color(0x8CDA3633));
const ChartPaint _white = .solid(Color(0xFFFFFFFF));
const ChartPaint _dark = .solid(Color(0xFF222222));
const TextStyle _font = TextStyle(fontSize: 13);

Color _nodeColor(String node) => _palette[node]!;

ChartPaint _flowPaint(SankeyDataPoint flow) => flow.to == 'D' ? _green : _red;

ChartPaint _flowLabelColor(SankeyDataPoint flow) =>
    flow.flow > 5 ? _white : _dark;

ChartPaint? _labelColor(SankeyNode node) => node.key == 'B' ? _white : null;

bool? _labelShown(SankeyNode node) => node.key != 'E';

typedef _Case = ({String name, SankeyDataset typed});

final List<_Case> _cases = [
  (
    name: 'colors by node and the layout options',
    typed: const SankeyDataset(
      label: 'Layout',
      data: _flows,
      colorFrom: .byNode(_nodeColor),
      colorTo: .byNode(_nodeColor),
      colorMode: .gradient,
      alpha: 0.7,
      borderColor: .constant(_grey),
      borderWidth: 2,
      nodeWidth: 14,
      nodePadding: .byKey({'B': SankeyNodeGap(before: 20, after: 30)}),
      nodeMinSize: .all(6),
      priority: {'C': 0, 'B': 1},
      labels: {'A': 'Alpha'},
      size: .min,
      modeX: .even,
      padding: 8,
      color: _dark,
      font: _font,
    ),
  ),
  (
    name: 'flow colors, hover colors and labels',
    typed: const SankeyDataset(
      label: 'Labels',
      data: _flows,
      colorFrom: .constant(_grey),
      colorTo: .constant(_dark),
      colorMode: .from,
      flowColor: .byFlow(_flowPaint),
      hoverFlowColor: .constant(_dark),
      hoverColorFrom: .constant(_red),
      hoverColorTo: .byNode(_nodeColor),
      orientation: .vertical,
      nodePaddingMode: .even,
      column: {'E': 3},
      nodeLabels: SankeyNodeLabels(
        position: .byKey({'A': SankeyLabelPosition.right}),
        color: .byNode(_labelColor),
        backgroundColor: .all(_grey),
        display: .byNode(_labelShown),
        borderRadius: 4,
        padding: 5,
        font: _font,
      ),
      flowLabels: SankeyFlowLabels(
        display: .all(true),
        color: .byFlow(_flowLabelColor),
        position: .all(SankeyLabelPosition.center),
        padding: .all(3),
      ),
    ),
  ),
];

/// The chart of [view], after its first frame.
Future<Chart> _pump(
  WidgetTester tester,
  Widget Function(void Function(Chart)) view,
) async {
  Chart? chart;
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: SizedBox(
          width: 600,
          height: 400,
          child: view((created) => chart = created),
        ),
      ),
    ),
  );
  await tester.pump();
  return chart!;
}

/// The nodes, the flows and the draw calls of [chart], then the draw calls
/// with flow 1 under the pointer.
List<Object?> _observe(Chart chart) {
  final meta = chart.getDatasetMeta(0);
  final controller = meta.controller! as SankeyController;
  List<ContextCall> draw() {
    final target = chart.ctx!;
    final recording = RecordingContext(target);
    chart
      ..ctx = recording
      ..draw()
      ..ctx = target;
    return recording.getCalls();
  }

  final observed = <Object?>[
    for (final node in controller.nodes.values)
      [node.key, node.x, node.y, node.size, node.color],
    for (final flow in meta.data.cast<sankey.Flow>())
      [flow.x, flow.y, flow.x2, flow.y2, flow.height],
    draw(),
  ];
  chart
    ..setActiveElements([const ActiveElement(datasetIndex: 0, index: 1)])
    ..update();
  return observed..add(draw());
}

void main() {
  for (final c in _cases) {
    testWidgets('${c.name}: the typed dataset draws, and a hover changes '
        'the draw', (tester) async {
      final observed = _observe(
        await _pump(
          tester,
          (created) => ChartView(
            config: ChartConfig(
              datasets: [c.typed],
              animation: ChartAnimation.none,
              maintainAspectRatio: false,
            ),
            onChartCreated: created,
          ),
        ),
      );
      expect(observed[observed.length - 2], isNotEmpty);
      expect(observed.last, isNot(observed[observed.length - 2]));
    });
  }

  test('lowerOwn writes the keys in the order of src/types.ts', () {
    final scope = lowerDataset(_cases.first.typed, const ChartKind('sankey'));
    expect(scope.jsKeys(), [
      'label',
      'data',
      'borderColor',
      'borderWidth',
      'alpha',
      'color',
      'colorFrom',
      'colorMode',
      'colorTo',
      'font',
      'labels',
      'modeX',
      'nodeMinSize',
      'nodePadding',
      'nodeWidth',
      'padding',
      'priority',
      'size',
    ]);
  });

  test('== compares the options, and a tear-off is a stable value', () {
    const a = SankeyDataset(data: _flows, colorFrom: .byNode(_nodeColor));
    const b = SankeyDataset(data: _flows, colorFrom: .byNode(_nodeColor));
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(a.copyWith(colorFrom: const .constant(_grey))));
    expect(a.copyWith(), a);
    expect(
      const SankeyNodeLabels(position: .byKey({'A': SankeyLabelPosition.left})),
      const SankeyNodeLabels(position: .byKey({'A': SankeyLabelPosition.left})),
    );
    expect(
      const SankeyFlowLabels(color: .byFlow(_flowLabelColor)),
      isNot(const SankeyFlowLabels(color: .all(_dark))),
    );
  });
}
