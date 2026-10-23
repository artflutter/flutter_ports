// Original code, not ported from Chart.js: the gallery demo of phase 5.

// The package exports nothing from lib/src yet; the public API comes in
// phase 9. The demo imports the ported files directly.
// ignore_for_file: implementation_imports

import 'dart:math' as math;

import 'package:chartjs_gallery/demo/chart_canvas.dart';
import 'package:chartjs_gallery/demo/demo_common.dart';
import 'package:chartjs_gallery/demo/demo_controls.dart';
import 'package:chartjs_gallery/demo/gallery_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/core/core.animator.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.interaction.dart';
import 'package:flutter_chartjs_port/src/elements/element_options.dart'
    show PointOptions;
import 'package:flutter_chartjs_port/src/elements/index.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.collection.dart'
    show notifyArrayListeners;
import 'package:flutter_chartjs_port/src/js/js_object.dart'
    show jsGet, jsObjectIsFrozen;
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;

/// The interaction modes of the selector: the keys of `Interaction.modes`
/// (core.interaction.js:257), in their order.
final List<String> coreDemoModes = Interaction.modes.keys.toList();

/// The values of the `interaction.axis` option of the selector.
const List<String> coreDemoAxes = ['x', 'y', 'xy'];

/// The values of the line `hover`: the durations of the hover transition
/// (`transitions.active.animation.duration`), in ms.
const List<double> coreDemoHoverDurations = [0, 200, 400, 1000, 2000];

/// The values of the line `update`: the durations of an update
/// (`animation.duration`), in ms.
const List<double> coreDemoUpdateDurations = [0, 400, 1000, 2000, 3000];

/// The short text of a mode segment, when the name of the mode is too long
/// for a segment on a phone. The tooltip gives the name. At 360 x 640 a
/// mode segment has 26 px for its text; in Roboto `labelLarge` the texts
/// are at most 24.3 px wide (`index` 33.4, `point` 31.5, `near` 27.5).
const Map<String, String> _modeText = {
  'index': 'idx',
  'dataset': 'set',
  'point': 'pt',
  'nearest': 'nrst',
};

/// The point count of each dataset at the start.
const int _startCount = 12;

/// The datasets of the chart: the label, the colors and the point style.
const List<({String label, String background, String border, String style})>
_datasetStyles = [
  (
    label: 'A',
    background: 'rgba(54, 162, 235, 0.5)',
    border: '#36A2EB',
    style: 'circle',
  ),
  (
    label: 'B',
    background: 'rgba(255, 99, 132, 0.5)',
    border: '#FF6384',
    style: 'rectRot',
  ),
];

/// The core modules of phase 5 in a real chart: `new Chart(canvas, config)`.
///
/// The chart is a `Chart` of `core.controller` on a `UiCanvasElement` of a
/// chart host, with the `FlutterPlatform`. Its type is `line`, the ported
/// `LineController` (Chart.js ADR 0031, section 4). Two hidden linear
/// scales of the fractions 0 to 1 (`unitScales`) put each point at its `x`
/// and `y` as fractions of the chart area.
///
/// The ported code does the work:
/// - `core.config` resolves the options: the typed `PointOptions` of
///   Chart.js ADR 0021, shared by the points of a dataset.
/// - The events of the host go through `Chart.eventHandler` and the mode of
///   `Interaction.modes` that the selector gives. The hovered points get the
///   hover options through `setHoverStyle`.
/// - `core.animations` and `core.animator` animate the hover transition
///   (`transitions.active`, 400 ms by default), the data changes and the
///   `hide` and `show` transitions of a dataset.
/// - An inline plugin of `core.plugins` draws the value lines in its
///   `beforeDatasetsDraw` hook.
/// - The plugins of `registerables` run with their defaults, as in a chart
///   of the Chart.js bundle (`src/index.umd.ts:28`). The legend shows the
///   two datasets, and a click on a legend item hides or shows its dataset
///   (plugin.legend.js:645-655). The tooltip shows the points that the
///   interaction mode finds: its options fall back to `interaction`
///   (plugin.tooltip.js:1348-1349). The tab has no plugin opt-out
///   (Chart.js ADR 0031, Open). The inline plugin gets each event after the
///   legend in its `afterEvent` hook, and the dataset segments then read
///   the visibility again.
///
/// The controls are above the chart, one full-width segmented button on
/// each line (Chart.js ADR 0031, section 10): `mode`, `axis`, the toggles
/// and the commands, `hover` and `update`. The readout and the help text come
/// after the chart. Each segment has a `ValueKey` (`core.mode.index`,
/// `core.hover.duration.400`, `core.data.randomize`, ...).
class CoreDemo extends StatefulWidget {
  /// Creates the core tab.
  const CoreDemo({super.key});

  @override
  State<CoreDemo> createState() => CoreDemoState();
}

/// The state of [CoreDemo]: the configuration, the data and the chart.
class CoreDemoState extends State<CoreDemo> {
  final math.Random _random = math.Random(5);
  Chart? _chart;

  /// Bumped when the readout changes, without a rebuild of the page.
  final ValueNotifier<int> _readout = ValueNotifier(0);
  String _event = '-';

  // The control values.
  String _mode = 'nearest';
  bool _intersect = true;
  String _axis = 'xy';
  double _hoverDuration = 400;
  double _duration = 1000;
  bool _animation = true;

  /// The data of each dataset: the objects `{x, y}` of the controller.
  late final List<List<AnyObject>> _data = [
    for (var d = 0; d < _datasetStyles.length; d++)
      [
        for (var i = 0; i < _startCount; i++)
          <String, Object?>{'x': _spread(i, _startCount), 'y': _value()},
      ],
  ];

  // The user options. A control writes into them, then calls update().
  late final AnyObject _interaction = {
    'mode': _mode,
    'intersect': _intersect,
    'axis': _axis,
  };
  late final AnyObject _animationOptions = {
    'duration': _duration,
    'onProgress': (Object? context) => _readout.value++,
    'onComplete': (Object? context) => _readout.value++,
  };
  late final AnyObject _activeAnimation = {'duration': _hoverDuration};
  late final AnyObject _options = {
    'maintainAspectRatio': false,
    'layout': <String, Object?>{'padding': 20.0},
    'scales': unitScales(),
    'interaction': _interaction,
    'animation': _animationOptions,
    'transitions': <String, Object?>{
      'active': <String, Object?>{'animation': _activeAnimation},
    },
    'elements': <String, Object?>{
      'point': <String, Object?>{
        'radius': 6.0,
        'hoverRadius': 12.0,
        'borderWidth': 1.0,
        'hoverBorderWidth': 3.0,
      },
    },
    'onHover': (Object? event, Object? active, Object? chart) {
      _event = (event! as types.ChartEvent).type;
      _readout.value++;
    },
  };

  /// The chart, once it exists.
  @visibleForTesting
  Chart? get chart => _chart;

  /// The data of the dataset [index].
  @visibleForTesting
  List<AnyObject> dataOf(int index) => _data[index];

  /// The active elements, as `d<dataset>#<index>`, or `none`.
  @visibleForTesting
  String get activeLabel {
    final active = _chart?.getActiveElements() ?? const [];
    if (active.isEmpty) return 'none';
    return [
      for (final item in active)
        'd${item.datasetIndex.toInt()}#${item.index.toInt()}',
    ].join(' ');
  }

  @override
  void dispose() {
    _readout.dispose();
    super.dispose();
  }

  /// The `x` of the point [i] of [count]: the points spread over the width.
  static double _spread(int i, int count) => (i + 0.5) / count;

  /// A random `y` in the upper 80 % of the chart area.
  double _value() => 0.1 + _random.nextDouble() * 0.8;

  Chart _create(UiCanvasElement canvas) {
    registerGalleryComponents();
    return Chart(canvas, <String, Object?>{
      'type': 'line',
      'data': <String, Object?>{
        'datasets': <Object?>[
          for (var d = 0; d < _datasetStyles.length; d++)
            <String, Object?>{
              'label': _datasetStyles[d].label,
              'data': _data[d],
              'backgroundColor': _datasetStyles[d].background,
              'borderColor': _datasetStyles[d].border,
              'pointStyle': _datasetStyles[d].style,
            },
        ],
      },
      'options': _options,
      'plugins': <Object?>[
        <String, Object?>{
          'id': 'galleryValueLines',
          'beforeDatasetsDraw': (Object? chart, Object? args, Object? options) {
            _drawValueLines(chart! as Chart);
          },
          // The registered plugins come before the inline plugins
          // (core.plugins.js:125-144). Thus the legend has handled a click
          // when this hook runs. A replayed event of `update` is not new
          // input (core.controller.js:528-534).
          'afterEvent': (Object? chart, Object? args, Object? options) {
            if (jsGet(args, 'replay') != true) _readout.value++;
          },
        },
      ],
    });
  }

  /// Five value lines over the chart area, with no scale.
  static void _drawValueLines(Chart chart) {
    final ctx = chart.ctx;
    final area = chart.chartArea;
    if (ctx == null || area == null) return;
    ctx
      ..save()
      ..strokeStyle = 'rgba(0, 0, 0, 0.1)'
      ..lineWidth = 1
      ..beginPath();
    for (var i = 0; i <= 4; i++) {
      final y = (area.bottom - area.height * i / 4).roundToDouble() + 0.5;
      ctx
        ..moveTo(area.left, y)
        ..lineTo(area.right, y);
    }
    ctx
      ..stroke()
      ..restore();
  }

  void _onChart(Chart chart) {
    _chart = chart;
    _readout.value++;
  }

  /// Changes a control value. The chart reads the user options again in
  /// `update()`, as after `chart.options.interaction.mode = 'x'` upstream.
  void _change(VoidCallback change) {
    setState(change);
    _interaction
      ..['mode'] = _mode
      ..['intersect'] = _intersect
      ..['axis'] = _axis;
    _activeAnimation['duration'] = _hoverDuration;
    _animationOptions['duration'] = _duration;
    _options['animation'] = _animation ? _animationOptions : false;
    _chart?.update();
    _readout.value++;
  }

  /// New `y` values in place: `update()` animates the points to them.
  void _randomize() {
    for (final data in _data) {
      for (final item in data) {
        item['y'] = _value();
      }
    }
    _chart?.update();
  }

  /// `data.push(item)`, or `data.pop()`, in each dataset. The data array
  /// listeners of the controller get the change (`notifyArrayListeners`,
  /// differences.md `platform-array-events`). The points spread again over
  /// the width.
  void _resize({required bool add}) {
    for (final data in _data) {
      if (add) {
        final item = <String, Object?>{'x': 1.0, 'y': _value()};
        data.add(item);
        notifyArrayListeners(data, 'push', [item]);
      } else if (data.length > 1) {
        data.removeLast();
        notifyArrayListeners(data, 'pop', const []);
      }
      for (var i = 0; i < data.length; i++) {
        data[i]['x'] = _spread(i, data.length);
      }
    }
    _chart?.update();
    _readout.value++;
  }

  /// `chart.hide(i)` or `chart.show(i)`: the `hide` and `show` transitions.
  void _toggleDataset(int index) {
    final chart = _chart;
    if (chart == null) return;
    final i = index.toDouble();
    setState(() {
      if (chart.isDatasetVisible(i)) {
        chart.hide(i);
      } else {
        chart.show(i);
      }
    });
  }

  // Readout.

  /// The options of the first active element, or `null`.
  AnyObject? get _activeOptions {
    final active = _chart?.getActiveElements() ?? const [];
    if (active.isEmpty) return null;
    return (active.first.element as PointElement?)?.options;
  }

  Widget _buildReadout() {
    final chart = _chart;
    final options = _activeOptions;
    final radius = options?['radius'];
    return ReadoutTable(
      key: const ValueKey('core.readout'),
      rows: [
        ('event', _event),
        ('active', activeLabel),
        ('radius', radius is double ? radius.toStringAsFixed(2) : '-'),
        (
          'backgroundColor',
          options == null ? '-' : showJs(options['backgroundColor']),
        ),
        (
          'options',
          options == null
              ? '-'
              // A web release build minifies runtimeType.
              : '${options is PointOptions ? 'PointOptions' : 'Map'}, '
                    '\$shared ${showJs(options[r'$shared'])}, '
                    '${jsObjectIsFrozen(options) ? 'frozen' : 'not frozen'}',
        ),
        (
          'animator',
          chart == null
              ? '-'
              : animator.running(chart)
              ? 'running'
              : 'idle',
        ),
      ],
    );
  }

  // Controls.

  /// The segments of the values [values]: the key `core.<name>.<value>`,
  /// with the integer text of a duration.
  static List<SegmentChoiceItem<T>> _items<T>(
    String name,
    List<T> values, {
    String Function(T value)? text,
  }) => [
    for (final v in values)
      (
        key: 'core.$name.${_keyText(v)}',
        text: text?.call(v) ?? _keyText(v),
        icon: null,
        tooltip: '$name ${_keyText(v)}',
        value: v,
      ),
  ];

  /// The text of [value] in a key: the integer text of a duration.
  static String _keyText(Object? value) =>
      value is double ? value.toInt().toString() : '$value';

  /// A command segment: it is never on, and a tap runs [command].
  static SegmentToggleItem _command(
    String key,
    IconData icon,
    String tooltip,
    VoidCallback command,
  ) => (
    key: key,
    icon: icon,
    tooltip: tooltip,
    value: false,
    onChanged: (_) => command(),
  );

  Widget _toggles(Chart? chart) => SegmentToggles(
    items: [
      (
        key: 'core.intersect',
        icon: Icons.ads_click,
        tooltip: 'interaction.intersect',
        value: _intersect,
        onChanged: (v) => _change(() => _intersect = v),
      ),
      (
        key: 'core.animation',
        icon: Icons.animation,
        tooltip: 'animation',
        value: _animation,
        onChanged: (v) => _change(() => _animation = v),
      ),
      for (var d = 0; d < _datasetStyles.length; d++)
        (
          key: 'core.dataset.$d',
          icon: d == 0 ? Icons.looks_one : Icons.looks_two,
          tooltip: 'dataset ${_datasetStyles[d].label}',
          value: chart == null || chart.isDatasetVisible(d * 1.0),
          onChanged: (_) => _toggleDataset(d),
        ),
      _command('core.data.randomize', Icons.shuffle, 'randomize', _randomize),
      _command(
        'core.data.add',
        Icons.add,
        'add a point',
        () => _resize(add: true),
      ),
      _command(
        'core.data.remove',
        Icons.remove,
        'remove a point',
        () => _resize(add: false),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const gap = SizedBox(height: 6);
    return DemoPageBody(
      children: [
        DemoCard(
          title: 'Chart',
          source:
              'core.controller: new Chart(canvas, config), update(), '
              'hide(i), show(i) · LineController · core.interaction: '
              'Interaction.modes · options: interaction, '
              'transitions.active.animation, animation · core.animations · '
              'core.animator · core.plugins: an inline plugin · '
              'plugins: legend, tooltip',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentChoice<String>(
                label: 'mode',
                items: _items(
                  'mode',
                  coreDemoModes,
                  text: (mode) => _modeText[mode] ?? mode,
                ),
                value: _mode,
                onChanged: (v) => _change(() => _mode = v),
              ),
              gap,
              SegmentChoice<String>(
                label: 'axis',
                items: _items('axis', coreDemoAxes),
                value: _axis,
                onChanged: (v) => _change(() => _axis = v),
              ),
              gap,
              // A legend click hides or shows a dataset without a rebuild
              // of the page: the segments rebuild with the readout.
              ValueListenableBuilder<int>(
                valueListenable: _readout,
                builder: (context, _, _) => _toggles(_chart),
              ),
              gap,
              SegmentChoice<double>(
                label: 'hover',
                items: _items('hover.duration', coreDemoHoverDurations),
                value: _hoverDuration,
                onChanged: (v) => _change(() => _hoverDuration = v),
              ),
              gap,
              SegmentChoice<double>(
                label: 'update',
                items: _items('animation.duration', coreDemoUpdateDurations),
                value: _duration,
                onChanged: (v) => _change(() => _duration = v),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) => ChartCanvas(
                  key: const ValueKey('core.host'),
                  height: constraints.maxWidth >= 560 ? 320 : 280,
                  create: _create,
                  onChart: _onChart,
                ),
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<int>(
                valueListenable: _readout,
                builder: (context, _, _) => _buildReadout(),
              ),
              const SizedBox(height: 8),
              Text(
                'A real line chart of the ported core, on two hidden linear '
                'scales. Move the mouse over a point, or touch it: the '
                'interaction mode finds the points, and their hover options '
                'animate, and the tooltip shows them. The dataset segments '
                'and the legend items hide and show a dataset. The shuffle, '
                '+ and - segments change the data.',
                key: const ValueKey('core.help'),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
