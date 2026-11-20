// Original code, not ported from chartjs-chart-sankey: the typed dataset.
@TestOn('vm')
library;

// The typed dataset of Sankey ADR 0004 against its raw twin: each case
// shows one chart as a typed `ChartView` and as a `ChartView.raw` with the
// Map of the same options, and compares the nodes, the flows and the draw
// calls, also of a hovered flow.

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

/// The raw data item of a flow context, as the raw configs read it.
SankeyDataPoint _raw(Object? context) =>
    (context! as ScriptableContext).raw! as SankeyDataPoint;

typedef _Case = ({String name, SankeyDataset typed, Map<String, Object?> raw});

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
    raw: {
      'label': 'Layout',
      'data': _flows,
      'colorFrom': (Object? c) => ChartPaint.solid(_nodeColor(_raw(c).from)),
      'colorTo': (Object? c) => ChartPaint.solid(_nodeColor(_raw(c).to)),
      'colorMode': SankeyColorMode.gradient,
      'alpha': 0.7,
      'borderColor': _grey,
      'borderWidth': 2.0,
      'nodeWidth': 14.0,
      'nodePadding': <String, Object?>{
        'B': const SankeyNodeGap(before: 20, after: 30),
      },
      'nodeMinSize': 6.0,
      'priority': <String, Object?>{'C': 0.0, 'B': 1.0},
      'labels': <String, Object?>{'A': 'Alpha'},
      'size': SankeySize.min,
      'modeX': SankeyModeX.even,
      'padding': 8.0,
      'color': _dark,
      'font': _font,
    },
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
    raw: {
      'label': 'Labels',
      'data': _flows,
      'colorFrom': _grey,
      'colorTo': _dark,
      'colorMode': SankeyColorMode.from,
      'flowColor': (Object? c) => _flowPaint(_raw(c)),
      'hoverFlowColor': _dark,
      'hoverColorFrom': _red,
      'hoverColorTo': (Object? c) => ChartPaint.solid(_nodeColor(_raw(c).to)),
      'orientation': SankeyOrientation.vertical,
      'nodePaddingMode': SankeyNodePaddingMode.even,
      'column': <String, Object?>{'E': 3},
      'nodeLabels': <String, Object?>{
        'position': <String, Object?>{'A': SankeyLabelPosition.right},
        'color': _labelColor,
        'backgroundColor': _grey,
        'display': _labelShown,
        'borderRadius': 4.0,
        'padding': 5.0,
        'font': _font,
      },
      'flowLabels': <String, Object?>{
        'display': true,
        'color': (Object? c) => _flowLabelColor(_raw(c)),
        'position': SankeyLabelPosition.center,
        'padding': 3.0,
      },
    },
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
    testWidgets('${c.name}: the typed dataset draws as its raw twin', (
      tester,
    ) async {
      final typed = _observe(
        await _pump(
          tester,
          (created) => ChartView(
            config: ChartConfig(
              type: const ChartKind(SankeyController.id),
              datasets: [c.typed],
              animation: ChartAnimation.none,
              maintainAspectRatio: false,
            ),
            onChartCreated: created,
          ),
        ),
      );
      await tester.pumpWidget(const SizedBox());
      final raw = _observe(
        await _pump(
          tester,
          (created) => ChartView.raw(
            config: <String, Object?>{
              'type': SankeyController.id,
              'data': <String, Object?>{
                'datasets': <Object?>[
                  <String, Object?>{...c.raw},
                ],
              },
              // The chart writes into its options: the Map is not const.
              // ignore: prefer_const_literals_to_create_immutables
              'options': <String, Object?>{
                'animation': false,
                'maintainAspectRatio': false,
              },
            },
            onChartCreated: created,
          ),
        ),
      );
      // Each chart draws, and the hover changes the draw.
      expect(raw[raw.length - 2], isNotEmpty);
      expect(raw.last, isNot(raw[raw.length - 2]));
      expect(typed, hasLength(raw.length));
      for (var i = 0; i < raw.length; i++) {
        expect(typed[i], raw[i], reason: 'item $i');
      }
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
