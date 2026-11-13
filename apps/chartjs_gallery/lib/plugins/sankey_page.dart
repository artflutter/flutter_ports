// Original code, not ported from chartjs-chart-sankey: the sankey gallery page.

import 'package:chartjs_gallery/demo/demo_common.dart';
import 'package:chartjs_gallery/demo/demo_controls.dart';
import 'package:chartjs_gallery/demo/gallery_components.dart';
import 'package:chartjs_gallery/docs/sankey/samples/basic.dart';
import 'package:chartjs_gallery/docs/sankey/samples/flow_colors.dart';
import 'package:chartjs_gallery/docs/sankey/samples/node_labels.dart';
import 'package:chartjs_gallery/docs/sankey/samples/vertical.dart';
import 'package:flutter_chartjs_chart_sankey_port/flutter_chartjs_chart_sankey_port.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

/// One variant of the page: a sample of the docs of chartjs-chart-sankey.
typedef SankeyPageVariant = ({
  String key,
  String text,
  String source,
  String help,
  Map<String, Object?> Function() sample,
});

/// The variants of the page, in the order of the segment line.
final List<SankeyPageVariant> sankeyPageVariants = [
  (
    key: 'basic',
    text: 'basic',
    source: 'samples/basic.md',
    help:
        'Five flows between five nodes. Each flow has a gradient from the '
        'color of its source node to the color of its target node.',
    sample: sankeyBasicSample,
  ),
  (
    key: 'vertical',
    text: 'vertical',
    source: 'samples/vertical.md',
    help: 'The orientation vertical: the flows go from top to bottom.',
    sample: sankeyVerticalSample,
  ),
  (
    key: 'flowColors',
    text: 'flow colors',
    source: 'samples/flow-colors.md',
    help:
        'The option flowColor gives each flow its own color: green into '
        'Converted and red into Dropped.',
    sample: sankeyFlowColorsSample,
  ),
  (
    key: 'nodeLabels',
    text: 'node labels',
    source: 'samples/node-labels.md',
    help:
        'The option nodeLabels: a position by node key, a color from a '
        'function of the node and a background for the node Grid.',
    sample: sankeyNodeLabelsSample,
  ),
];

const String _sankeyVersion = 'chartjs-chart-sankey $chartjsChartSankeyVersion';

/// The page "Sankey": the sankey chart type of chartjs-chart-sankey, a
/// controller and an element of another package on the chart of the host.
class const SankeyPage({super.key}) extends StatefulWidget {
  /// Creates the page.
  this;

  @override
  State<SankeyPage> createState() => SankeyPageState();
}

/// The state of [SankeyPage].
class SankeyPageState() extends State<SankeyPage> {
  /// Creates the state.
  this;

  int _variant = 0;
  Chart? _chart;
  final ValueNotifier<int> _readout = ValueNotifier(0);

  late Map<String, Object?> _config = _makeConfig();

  /// The chart of the current variant, or null before its first layout.
  @visibleForTesting
  Chart? get chart => _chart;

  SankeyPageVariant get _current => sankeyPageVariants[_variant];

  Map<String, Object?> _makeConfig() {
    registerSankeyComponents();
    final config = _current.sample();
    config['options'] = <String, Object?>{
      'onHover': (ChartEvent event, List<ActiveElement> elements, Chart chart) {
        _readout.value++;
      },
    };
    return config;
  }

  void _onChart(Chart chart) {
    _chart = chart;
    _readout.value++;
  }

  void _select(int variant) {
    if (variant == _variant) return;
    setState(() {
      _variant = variant;
      _config = _makeConfig();
      // The old view unmounts and destroys its chart. The new view starts
      // the chart of the variant in its first layout.
      _chart = null;
    });
    _readout.value++;
  }

  @override
  void dispose() {
    _readout.dispose();
    super.dispose();
  }

  List<(String, String)> _rows() {
    final chart = _chart;
    if (chart == null) return const [('nodes', '-'), ('flows', '-')];
    final meta = chart.getDatasetMeta(0);
    final controller = meta.controller! as SankeyController;
    final active = chart.getActiveElements();
    return [
      ('nodes', controller.nodes.keys.join(', ')),
      ('flows', '${meta.data.length}'),
      ('hover', active.isEmpty ? '-' : _flowText(controller, active.first)),
    ];
  }

  /// The text of the flow of [active]: its two nodes and its size.
  static String _flowText(SankeyController controller, ActiveElement active) {
    final parsed = controller.getParsed(active.index)! as ParsedItem;
    final custom = parsed.custom! as SankeyParsedCustom;
    return '${custom.from.key} -> ${custom.to.key}: '
        '${jsNumberText(custom.flow)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = _current;
    return Scaffold(
      appBar: AppBar(title: const Text('Sankey')),
      body: DemoPageBody(
        maxWidth: 600,
        children: [
          SegmentChoice<int>(
            label: 'docs',
            items: [
              for (var i = 0; i < sankeyPageVariants.length; i++)
                (
                  key: 'sankey.variant.${sankeyPageVariants[i].key}',
                  text: sankeyPageVariants[i].text,
                  icon: null,
                  tooltip: sankeyPageVariants[i].source,
                  value: i,
                ),
            ],
            value: _variant,
            onChanged: _select,
          ),
          KeyedSubtree(
            key: ValueKey(_variant),
            child: ChartView.raw(
              key: const ValueKey('sankey.host'),
              config: _config,
              onChartCreated: _onChart,
              semanticLabel: 'Sankey chart: ${current.text}',
            ),
          ),
          ValueListenableBuilder<int>(
            valueListenable: _readout,
            builder: (context, _, _) => ReadoutTable(
              key: const ValueKey('sankey.readout'),
              rows: _rows(),
            ),
          ),
          Text(
            [
              'Source: ${current.source}, $_sankeyVersion.',
              current.help,
              'A hover or a tap on a flow shows its tooltip.',
            ].join('\n'),
            key: const ValueKey('sankey.help'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
