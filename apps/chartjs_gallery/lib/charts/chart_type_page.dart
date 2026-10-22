// Original code, not ported from Chart.js: the page of one chart type.

// The package exports nothing from lib/src yet; the public API comes in
// phase 9. The gallery imports the ported files directly.
// ignore_for_file: implementation_imports

import 'package:chartjs_gallery/charts/chart_types.dart';
import 'package:chartjs_gallery/demo/chart_canvas.dart';
import 'package:chartjs_gallery/demo/demo_common.dart';
import 'package:chartjs_gallery/demo/demo_controls.dart';
import 'package:chartjs_gallery/demo/gallery_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart'
    show chartJsVersion;
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart' show jsGet;
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;

/// The page of one chart type: the variant line, the chart, the readout
/// and the help text (Chart.js ADR 0031 sections 1 and 10).
///
/// The chart is a `Chart` of `core.controller` with the config of a docs
/// block. The host has no height: it gets an unbounded height in the
/// scroll view, and the platform gives the height from the width and the
/// aspect ratio of the type (Chart.js ADR 0014). Thus the chart has the
/// aspect of the docs: 2, or 1 for doughnut, pie, polar area and radar.
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
  static const String _phase8 =
      'No legend, title, tooltip or fill: these plugins come in phase 8.';

  int _variant = 0;
  Chart? _chart;
  final ValueNotifier<int> _readout = ValueNotifier(0);

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
        _datasetLabel(chart.getDatasetMeta(i.toDouble())),
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
    // Display text: the text of the tooltip of phase 8.
    return 'd${datasetIndex.toInt()}#${index.toInt()} $label: $value';
  }

  ChartTypeVariant get _current => widget.entry.variants[_variant];

  Chart _create(UiCanvasElement canvas) {
    registerGalleryComponents();
    final config = _current.config();
    final options = (config['options'] ??= <String, Object?>{}) as AnyObject;
    options['onHover'] = (event, active, chart) => _readout.value++;
    config['plugins'] = <Object?>[_mouseoutPlugin];
    return Chart(canvas, config);
  }

  /// The inline plugin `typeReadout`: it rebuilds the readout after a
  /// `mouseout` event. The option `onHover` gets only the events in the
  /// chart area (core.controller.js:1217-1223). A `mouseout` event is not
  /// in the chart area, but it clears the active elements
  /// (core.controller.js:1250-1252). The tooltip of phase 8 also clears on
  /// a `mouseout` event, in its hook `afterEvent`
  /// (plugin.tooltip.js:1186-1188).
  late final AnyObject _mouseoutPlugin = {
    'id': 'typeReadout',
    'afterEvent': (Object? chart, Object? args, Object? options) {
      final event = jsGet(args, 'event')! as types.ChartEvent;
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
      // The old host unmounts and destroys its chart. The new host makes
      // the chart of the variant after its first frame.
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
            child: ChartCanvas(
              key: ValueKey('type.$stem.host'),
              create: _create,
              onChart: _onChart,
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
              _phase8,
              ?entry.note,
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
