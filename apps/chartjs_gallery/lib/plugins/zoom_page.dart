// Original code, not ported from chartjs-plugin-zoom: the zoom gallery page.

import 'package:chartjs_gallery/demo/demo_common.dart';
import 'package:chartjs_gallery/demo/demo_controls.dart';
import 'package:chartjs_gallery/demo/gallery_components.dart';
import 'package:chartjs_gallery/docs/zoom/samples/basic.dart';
import 'package:chartjs_gallery/docs/zoom/samples/drag/linear.dart';
import 'package:chartjs_gallery/docs/zoom/samples/pan/toggle.dart';
import 'package:chartjs_gallery/docs/zoom/samples/wheel/category.dart';
import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

/// One variant of the page "Zoom and pan": a sample of the docs of
/// chartjs-plugin-zoom.
///
/// - `key`: the last part of the key of the variant segment,
///   `zoom.variant.<key>`.
/// - `text`: the short text of the segment.
/// - `source`: the docs file of the sample at the pin.
/// - `help`: how the chart of the sample zooms and pans.
/// - `sample`: makes the sample, with a new config, for each call.
typedef ZoomPageVariant = ({
  String key,
  String text,
  String source,
  String help,
  ZoomDocsSample Function(ZoomDocsLog log) sample,
});

/// The variants of the page: four samples of `docs/samples/` of
/// chartjs-plugin-zoom at the pin, one for each input of the plugin.
final List<ZoomPageVariant> zoomPageVariants = [
  (
    key: 'basic',
    text: 'basic',
    source: 'docs/samples/basic.md',
    help:
        'Turn the mouse wheel over the chart, or pinch with two fingers: the '
        'chart zooms. Drag with the mouse or one finger: the chart pans. The '
        'limits keep each axis in -200 to 200, and at least 50 wide. The '
        'segment zoom turns the wheel and the pinch on and off, and the '
        'segment pan turns the pan on and off. A click on the chart logs its '
        'event type in output.',
    sample: zoomBasicSample,
  ),
  (
    key: 'drag',
    text: 'drag',
    source: 'docs/samples/drag/linear.md',
    help:
        'Drag a box with the mouse: the chart zooms to the box. Escape '
        'cancels the box. Hold Ctrl and drag with the mouse: the chart pans. '
        'On a touch screen, a drag with one finger pans. The segment zoom '
        'turns the box on and off.',
    sample: zoomDragLinearSample,
  ),
  (
    key: 'wheel',
    text: 'wheel',
    source: 'docs/samples/wheel/category.md',
    help:
        'The x axis shows the months 5 to 11 (June to December) of 20 '
        'months. Turn the mouse wheel over the chart, or pinch with two '
        'fingers: the chart zooms. Drag with the mouse or one finger for '
        'more than 5 pixels: the chart pans.',
    sample: zoomWheelCategorySample,
  ),
  (
    key: 'pan',
    text: 'pan',
    source: 'docs/samples/pan/toggle.md',
    help:
        'Pinch with two fingers: the chart zooms. The wheel does not zoom. '
        'The pan is off first: the segment pan turns it on, and then a drag '
        'with the mouse or one finger pans the chart.',
    sample: zoomPanToggleSample,
  ),
];

/// The pinned upstream of the samples.
const String _zoomVersion = 'chartjs-plugin-zoom $chartjsPluginZoomVersion';

/// The segment of each action name of the samples: its key, its icon and
/// its short text.
const Map<String, ({String key, IconData icon, String text})> _actionSegments =
    {
      'Toggle zoom': (
        key: 'zoom.action.toggleZoom',
        icon: Icons.zoom_in,
        text: 'zoom',
      ),
      'Toggle pan': (
        key: 'zoom.action.togglePan',
        icon: Icons.pan_tool_alt,
        text: 'pan',
      ),
      'Reset zoom': (
        key: 'zoom.action.resetZoom',
        icon: Icons.zoom_out_map,
        text: 'reset',
      ),
    };

/// The page "Zoom and pan": the variant line, the action line, the chart,
/// the readout and the help text (the layout rule of Chart.js ADR 0031,
/// section 10).
///
/// Each variant is a sample of the docs of chartjs-plugin-zoom: its config
/// and its actions, with the changes that the sample file states. The
/// page registers the zoom plugin for all charts at its first build, as the
/// docs do (`registerZoomComponents`), and each sample gives its options in
/// `options.plugins.zoom`. The chart is a `ChartView.raw`: the typed
/// `ChartConfig` has no slot for the options of a plugin of another package
/// yet (`doc/host-seams.md` of the zoom port).
///
/// The page makes the sample once for each variant, so that a rebuild of
/// the page gives the `ChartView` the same Map: no update, and the zoom
/// range stays. An action changes the options of the sample and
/// updates the chart itself, as the docs do. The action line has one
/// segment for each action of the sample: a toggle shows the state of its
/// option, and `reset` (`Reset zoom`) puts back the first range.
///
/// The docs page also draws the versions of Chart.js and of the plugin in
/// the corner of each chart (the plugin `version` of
/// `docs/scripts/register.js:7-23`). The page has no such plugin: its help
/// text names the version.
class const ZoomPage({super.key}) extends StatefulWidget {
  /// Creates the page.
  this;

  @override
  State<ZoomPage> createState() => ZoomPageState();
}

/// The state of a [ZoomPage]: the selected variant, its sample and its
/// chart.
class ZoomPageState() extends State<ZoomPage> {
  /// A new state of [ZoomPage].
  this;

  int _variant = 0;
  Chart? _chart;
  String? _output;
  bool _readoutScheduled = false;
  final ValueNotifier<int> _readout = ValueNotifier(0);

  /// The sample of the variant.
  late ZoomDocsSample _sample = _makeSample();

  /// The chart, once it exists. For the tests.
  @visibleForTesting
  Chart? get chart => _chart;

  /// The sample of the selected variant. For the tests.
  @visibleForTesting
  ZoomDocsSample get sample => _sample;

  /// The last line that the sample logged, or the first text of its output
  /// pane. For the tests.
  @visibleForTesting
  String? get output => _output;

  ZoomPageVariant get _current => zoomPageVariants[_variant];

  /// The sample of the current variant, with the inline plugin of the
  /// readout. The components are registered first.
  ZoomDocsSample _makeSample() {
    registerZoomComponents();
    final sample = _current.sample(_log);
    sample.config['plugins'] = <Object?>[_readoutPlugin];
    _output = sample.output;
    return sample;
  }

  /// The console of the sample: the readout shows the last line.
  void _log(String line) {
    _output = line;
    _scheduleReadout();
  }

  /// The inline plugin `zoomReadout`: each update of the chart, also the
  /// updates of a zoom and a pan, rebuilds the readout and the actions after
  /// the frame. An update can run in a layout (the first update of the
  /// chart), where no widget can rebuild.
  late final Map<String, Object?> _readoutPlugin = {
    'id': 'zoomReadout',
    'afterUpdate': (Object? chart, Object? args, Object? options) =>
        _scheduleReadout(),
  };

  void _scheduleReadout() {
    if (_readoutScheduled) return;
    _readoutScheduled = true;
    WidgetsBinding.instance
      ..addPostFrameCallback((_) {
        _readoutScheduled = false;
        if (mounted) _readout.value++;
      })
      ..ensureVisualUpdate();
  }

  void _onChart(Chart chart) {
    _chart = chart;
    _readout.value++;
  }

  void _select(int variant) {
    if (variant == _variant) return;
    setState(() {
      _variant = variant;
      _sample = _makeSample();
      // The old view unmounts and destroys its chart. The new view starts
      // the chart of the variant in its first layout.
      _chart = null;
    });
    _readout.value++;
  }

  void _run(ZoomDocsAction action) {
    final chart = _chart;
    if (chart == null) return;
    action.handler(chart);
    _readout.value++;
  }

  @override
  void dispose() {
    _readout.dispose();
    super.dispose();
  }

  /// The action line: one segment for each action of the sample.
  Widget _actions() {
    final chart = _chart;
    return SegmentToggles(
      labels: {
        for (final action in _sample.actions)
          _actionSegments[action.name]!.key: _actionSegments[action.name]!.text,
      },
      items: [
        for (final action in _sample.actions)
          (
            key: _actionSegments[action.name]!.key,
            icon: _actionSegments[action.name]!.icon,
            tooltip: action.name,
            value: chart != null && (action.isOn?.call(chart) ?? false),
            onChanged: (_) => _run(action),
          ),
      ],
    );
  }

  /// The readout: the zoom level, the range of each scale, whether a scale
  /// has another range than its first range, and the output pane of a
  /// sample that has one.
  List<(String, String)> _rows() {
    final chart = _chart;
    return [
      ('zoom', chart == null ? '-' : '${_number(chart.getZoomLevel())}x'),
      for (final id in const ['x', 'y']) (id, _range(chart?.scales[id])),
      (
        'zoomed',
        chart == null ? '-' : (chart.isZoomedOrPanned() ? 'yes' : 'no'),
      ),
      if (_sample.output != null) ('output', _output ?? ''),
    ];
  }

  static String _range(Scale? scale) =>
      scale == null ? '-' : '${_number(scale.min)} to ${_number(scale.max)}';

  /// [value] with at most two decimals, for the readout.
  static String _number(double value) {
    if (!value.isFinite) return '$value';
    final text = value.toStringAsFixed(2);
    return text.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = _current;
    return Scaffold(
      appBar: AppBar(title: const Text('Zoom and pan')),
      body: DemoPageBody(
        maxWidth: 600,
        children: [
          SegmentChoice<int>(
            label: 'docs',
            items: [
              for (var i = 0; i < zoomPageVariants.length; i++)
                (
                  key: 'zoom.variant.${zoomPageVariants[i].key}',
                  text: zoomPageVariants[i].text,
                  icon: null,
                  tooltip: zoomPageVariants[i].source,
                  value: i,
                ),
            ],
            value: _variant,
            onChanged: _select,
          ),
          // A zoom, a pan and an action rebuild the segments with the
          // readout: a toggle shows the state of its option.
          ValueListenableBuilder<int>(
            valueListenable: _readout,
            builder: (context, _, _) => _actions(),
          ),
          KeyedSubtree(
            key: ValueKey(_variant),
            child: ChartView.raw(
              key: const ValueKey('zoom.host'),
              config: _sample.config,
              onChartCreated: _onChart,
              semanticLabel: 'Zoom and pan chart: ${current.text}',
            ),
          ),
          ValueListenableBuilder<int>(
            valueListenable: _readout,
            builder: (context, _, _) => ReadoutTable(
              key: const ValueKey('zoom.readout'),
              rows: _rows(),
            ),
          ),
          Text(
            [
              'Source: ${current.source}, $_zoomVersion.',
              current.help,
              'The segment reset puts back the first range of each axis.',
            ].join('\n'),
            key: const ValueKey('zoom.help'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
