// Original code, not ported from Chart.js: the page of one chart type.

import 'package:chartjs_gallery/charts/chart_types.dart';
import 'package:chartjs_gallery/demo/demo_common.dart';
import 'package:chartjs_gallery/demo/demo_controls.dart';
import 'package:chartjs_gallery/demo/gallery_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The page of one chart type: the variant line, the chart, the readout
/// and the help text (Chart.js ADR 0031 sections 1 and 10).
///
/// The chart is the `ChartView` of the app library with the config of a
/// docs block (Chart.js ADRs 0048 and 0049). The view has no height: it
/// gets an unbounded height in the scroll view, and the platform gives the
/// height from the width and the aspect ratio of the type (Chart.js ADR
/// 0049, section 5). Thus the chart has the aspect of the docs: 2, or 1 for
/// doughnut, pie, polar area and radar.
///
/// The gallery registers `registerables`, with the seven plugins, as the
/// docs do (`docs/scripts/register.js:6`). The docs blocks set no plugin
/// options. Thus each chart has the defaults of the plugins: the legend
/// shows (plugin.legend.js:637), the tooltip shows on a hover or a tap
/// (plugin.tooltip.js:1276), and the title does not show
/// (plugin.title.js:147). The filler fills the area of each line dataset
/// whose `fill` option is not false: the Radar chart and the Area variants
/// `origin`, `start` and `end`. A tap on a legend item hides or shows its
/// data, and a tap outside the chart hides the tooltip (Chart.js ADR 0037,
/// section 15).
///
/// The chart is one focus stop (Chart.js ADR 0051): the arrow keys move
/// over the legend items and the elements, Enter or Space clicks, and
/// Escape clears the hover. Its semantics label is
/// `<title> chart: <variant>`, for example `Bar chart: vertical`. The
/// [ChartTheme] of the app themes the chart (Chart.js ADR 0050).
class ChartTypePage extends StatefulWidget {
  /// Creates the page of [entry].
  const ChartTypePage({required this.entry, super.key});

  /// The chart type of the page.
  final ChartTypeEntry entry;

  @override
  State<ChartTypePage> createState() => ChartTypePageState();
}

/// The state of a [ChartTypePage]: the selected variant and its chart.
class ChartTypePageState extends State<ChartTypePage> {
  static const String _input =
      'Hover or tap an element: the tooltip shows its label and value. '
      'Tap outside the chart: the tooltip hides. '
      'Tap a legend item: its data hides or shows.';

  /// The keys of the chart (Chart.js ADR 0051, section 3).
  static const String _keys =
      'Keys: the arrows move over the legend items and the elements, Enter '
      'or Space clicks, Escape clears.';

  int _variant = 0;
  Chart? _chart;
  final ValueNotifier<int> _readout = ValueNotifier(0);

  /// The config of the variant. The page makes it once for each variant,
  /// so that a rebuild of the page gives the `ChartView` the same Map: no
  /// update (Chart.js ADR 0049, section 4).
  late Map<String, Object?> _config = _makeConfig();

  /// The chart, once it exists. For the tests.
  @visibleForTesting
  Chart? get chart => _chart;

  /// The datasets: `<meta.type> <element count>` of each dataset, joined
  /// with `, `.
  @visibleForTesting
  String get datasetsLabel {
    final chart = _chart;
    if (chart == null) return 'none';
    final datasets = chart.data['datasets']! as List<Object?>;
    return [
      for (var i = 0; i < datasets.length; i++)
        _datasetLabel(chart.getDatasetMeta(i)),
    ].join(', ');
  }

  static String _datasetLabel(ChartMeta meta) =>
      '${meta.type} ${meta.data.length}';

  /// The active elements: `d<dataset>#<index> <label>: <value>` of each,
  /// from `controller.getLabelAndValue(index)`, joined with `; `, or
  /// `none`.
  @visibleForTesting
  String get hoverLabel {
    final chart = _chart;
    if (chart == null) return 'none';
    final active = chart.getActiveElements();
    if (active.isEmpty) return 'none';
    return [
      for (final item in active)
        _hoverItem(chart, item.datasetIndex, item.index),
    ].join('; ');
  }

  static String _hoverItem(Chart chart, double datasetIndex, double index) {
    final controller = chart.getDatasetMeta(datasetIndex).controller!;
    final (:label, :value) = controller.getLabelAndValue(index);
    // Display text: the label and the value that the tooltip item gets
    // (plugin.tooltip.js:127-137).
    return 'd${datasetIndex.toInt()}#${index.toInt()} $label: $value';
  }

  ChartTypeVariant get _current => widget.entry.variants[_variant];

  /// The config of the current variant, with the option `onHover` and the
  /// inline plugin of the readout. The components are registered first.
  Map<String, Object?> _makeConfig() {
    registerGalleryComponents();
    final config = _current.config();
    final options =
        (config['options'] ??= <String, Object?>{}) as Map<String, Object?>;
    options['onHover'] = (event, active, chart) => _readout.value++;
    config['plugins'] = <Object?>[_mouseoutPlugin];
    return config;
  }

  /// The inline plugin `typeReadout`: it rebuilds the readout after a
  /// `mouseout` event. The option `onHover` gets only the events in the
  /// chart area (core.controller.js:1217-1223). A `mouseout` event is not
  /// in the chart area, but it clears the active elements
  /// (core.controller.js:1250-1252). The tooltip also clears on a
  /// `mouseout` event, in its hook `afterEvent`
  /// (plugin.tooltip.js:1186-1188).
  late final Map<String, Object?> _mouseoutPlugin = {
    'id': 'typeReadout',
    'afterEvent': (Object? chart, Object? args, Object? options) {
      // The hook arguments are a Map (core.controller.js:1164-1169).
      final event = (args! as Map<String, Object?>)['event']! as ChartEvent;
      if (event.type == 'mouseout') _readout.value++;
    },
  };

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

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final stem = entry.stem;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(entry.title)),
      body: DemoPageBody(
        maxWidth: 600,
        children: [
          if (entry.variants.length > 1)
            SegmentChoice<int>(
              label: 'docs',
              items: [
                for (var i = 0; i < entry.variants.length; i++)
                  (
                    key: 'type.$stem.variant.${entry.variants[i].key}',
                    text: entry.variants[i].text,
                    icon: null,
                    tooltip: entry.variants[i].source,
                    value: i,
                  ),
              ],
              value: _variant,
              onChanged: _select,
            ),
          KeyedSubtree(
            key: ValueKey(_variant),
            child: ChartView.raw(
              key: ValueKey('type.$stem.host'),
              config: _config,
              onChartCreated: _onChart,
              semanticLabel: '${entry.title} chart: ${_current.text}',
            ),
          ),
          ValueListenableBuilder<int>(
            valueListenable: _readout,
            builder: (context, _, _) => ReadoutTable(
              key: ValueKey('type.$stem.readout'),
              rows: [('datasets', datasetsLabel), ('hover', hoverLabel)],
            ),
          ),
          Text(
            [
              'Source: ${_current.source}, Chart.js $chartJsVersion.',
              _input,
              _keys,
            ].join('\n'),
            key: ValueKey('type.$stem.help'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
