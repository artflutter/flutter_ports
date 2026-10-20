// Original code, not ported from Chart.js: the gallery demo of phase 5.

// The package exports nothing from lib/src yet; the public API comes in
// phase 9. The demo imports the ported files directly.
// ignore_for_file: implementation_imports

import 'dart:math' as math;

import 'package:chartjs_gallery/demo/chart_canvas.dart';
import 'package:chartjs_gallery/demo/demo_common.dart';
import 'package:chartjs_gallery/demo/demo_controls.dart';
import 'package:chartjs_gallery/demo/stress_point_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chartjs/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs/src/core/core.animator.dart';
import 'package:flutter_chartjs/src/core/core.controller.dart';
import 'package:flutter_chartjs/src/core/core.interaction.dart';
import 'package:flutter_chartjs/src/elements/element_options.dart'
    show PointOptions;
import 'package:flutter_chartjs/src/elements/index.dart';
import 'package:flutter_chartjs/src/helpers/helpers.collection.dart'
    show notifyArrayListeners;
import 'package:flutter_chartjs/src/js/js_object.dart' show jsObjectIsFrozen;
import 'package:flutter_chartjs/src/types/basic.dart';
import 'package:flutter_chartjs/src/types/index.dart' as types;

/// The interaction modes of the selector: the keys of `Interaction.modes`
/// (core.interaction.js:257), in their order.
final List<String> coreDemoModes = Interaction.modes.keys.toList();

/// The values of the `interaction.axis` option of the selector.
const List<String> coreDemoAxes = ['x', 'y', 'xy'];

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
/// chart host, with the `FlutterPlatform`. Its type is the gallery
/// controller `StressPointController`, a subclass of the ported
/// `DatasetController`, registered through its class value. The chart has
/// no scales: they come in phase 6. The controller puts each point at its
/// `x` and `y` as fractions of the chart area.
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
///
/// Each control has a `ValueKey` (`core.mode.index`, `core.hover.duration`,
/// `core.data.randomize`, ...).
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
      'type': StressPointController.id,
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

  Widget _choices(
    String name,
    List<String> values,
    String value,
    ValueChanged<String> onSelected,
  ) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(width: 92, child: Text(name)),
        for (final v in values)
          ChoiceChip(
            key: ValueKey('core.$name.$v'),
            label: Text(v),
            selected: v == value,
            onSelected: (_) => _change(() => onSelected(v)),
          ),
      ],
    );
  }

  Widget _slider(
    String key,
    String label,
    double value,
    double max,
    ValueChanged<double> onChanged,
  ) => SliderControl(
    label: label,
    sliderKey: ValueKey(key),
    value: value,
    min: 0,
    max: max,
    divisions: max ~/ 100,
    onChanged: (v) => _change(() => onChanged(v)),
  );

  Widget _button(String key, String label, VoidCallback onPressed) =>
      OutlinedButton(
        key: ValueKey(key),
        onPressed: onPressed,
        child: Text(label),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chart = _chart;
    return DemoPageBody(
      children: [
        DemoCard(
          title: 'Chart',
          source:
              'core.controller: new Chart(canvas, config) · '
              'core.datasetController: StressPointController · '
              'core.interaction: Interaction.modes · core.animations · '
              'core.animator · core.plugins: an inline plugin',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'A real Chart of the ported core, with points and no scales. '
                'Move the mouse over a point, or touch it: the interaction '
                'mode finds the points, and their hover options animate.',
                style: theme.textTheme.bodySmall,
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
            ],
          ),
        ),
        DemoCard(
          title: 'Interaction',
          source: 'options.interaction: {mode, intersect, axis} → hover',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _choices('mode', coreDemoModes, _mode, (v) => _mode = v),
              const SizedBox(height: 8),
              _choices('axis', coreDemoAxes, _axis, (v) => _axis = v),
              const SizedBox(height: 8),
              ToggleChips(
                toggles: [
                  (
                    key: 'core.intersect',
                    label: 'intersect',
                    value: _intersect,
                    onChanged: (v) => _change(() => _intersect = v),
                  ),
                ],
              ),
            ],
          ),
        ),
        DemoCard(
          title: 'Animations',
          source:
              'options.transitions.active.animation.duration · '
              'options.animation · chart.update() · chart.hide(i) · '
              'chart.show(i)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DemoControlGrid(
                children: [
                  _slider(
                    'core.hover.duration',
                    'hover ms',
                    _hoverDuration,
                    2000,
                    (v) => _hoverDuration = v,
                  ),
                  _slider(
                    'core.animation.duration',
                    'update ms',
                    _duration,
                    3000,
                    (v) => _duration = v,
                  ),
                ],
              ),
              ToggleChips(
                toggles: [
                  (
                    key: 'core.animation',
                    label: 'animation',
                    value: _animation,
                    onChanged: (v) => _change(() => _animation = v),
                  ),
                  for (var d = 0; d < _datasetStyles.length; d++)
                    (
                      key: 'core.dataset.$d',
                      label: 'dataset ${_datasetStyles[d].label}',
                      value: chart == null || chart.isDatasetVisible(d * 1.0),
                      onChanged: (_) => _toggleDataset(d),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _button('core.data.randomize', 'randomize', _randomize),
                  _button(
                    'core.data.add',
                    'add point',
                    () => _resize(add: true),
                  ),
                  _button(
                    'core.data.remove',
                    'remove point',
                    () => _resize(add: false),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
