// Original code, not ported from Chart.js: the gallery demo of phase 6.

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
import 'package:flutter_chartjs/src/core/core.controller.dart';
import 'package:flutter_chartjs/src/core/core.scale.dart';
import 'package:flutter_chartjs/src/helpers/helpers.collection.dart'
    show notifyArrayListeners;
import 'package:flutter_chartjs/src/js/js_number.dart' show jsToNumber;
import 'package:flutter_chartjs/src/js/js_object.dart' show jsGet;
import 'package:flutter_chartjs/src/types/basic.dart';
import 'package:flutter_chartjs/src/types/index.dart' as types;

/// The scale types of the x axis of the Axes tab.
const List<String> axesDemoXTypes = [
  'linear',
  'logarithmic',
  'category',
  'time',
];

/// The scale types of the y axis of the Axes tab.
const List<String> axesDemoYTypes = ['linear', 'logarithmic'];

/// The point counts of each dataset.
const List<int> axesDemoCounts = [12, 100, 1000];

/// The values of the option `ticks.align`.
const List<String> axesDemoAligns = ['start', 'center', 'end'];

/// The values of the option `bounds`. `auto` writes no option: each scale
/// type keeps its default (`ticks` for linear, `data` for time).
const List<String> axesDemoBounds = ['auto', 'data', 'ticks'];

/// The values of the option `time.unit` of a time axis. `auto` writes no
/// option: the scale finds the unit.
const List<String> axesDemoTimeUnits = ['auto', 'day', 'week', 'month', 'year'];

/// The values of the chart option `locale`.
const List<String> axesDemoLocales = ['en-US', 'de-DE'];

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

/// The scales of phase 6 in a real chart: the chart of the Core tab with an
/// x axis and a y axis.
///
/// The chart is a `Chart` of `core.controller` on a `UiCanvasElement` of a
/// chart host. Its type is the gallery controller `StressPointController`,
/// on its scale path: each point gets the pixels of
/// `iScale.getPixelForValue` and `vScale.getPixelForValue`. The x axis is a
/// `LinearScale`, a `LogarithmicScale`, a `CategoryScale` or a `TimeScale`,
/// and the y axis is a `LinearScale` or a `LogarithmicScale`.
///
/// The ported code does the work:
/// - The datasets have `parsing: true`. Thus `parse` of the scale reads the
///   `x` of each data object: the label of a category point (`P4`), and the
///   ISO date of a time point (`2024-01-04`), through the default date
///   adapter (Chart.js ADR 0024).
/// - A control writes the user options, then calls `chart.update()`. A new
///   scale type gives a new scale (`buildOrUpdateScales`,
///   core.controller.js:354). The scales find their data limits, ticks,
///   label sizes, rotation and auto skip, and the layout fits them.
/// - The readout shows the state of each scale, the chart area, and the
///   pointer: its pixel through `getValueForPixel`, `getLabelForValue`, and
///   back through `getPixelForValue`. An inline plugin gets the pointer in
///   its `afterEvent` hook.
///
/// The controls of the ticks, the grid, the border, the title, `reverse`,
/// `beginAtZero` and `bounds` apply to both axes. The chart has no
/// animation: the Core tab shows the animations.
///
/// Each control has a `ValueKey` (`axes.x.type.time`, `axes.ticks.autoSkip`,
/// `axes.data.add`, ...).
class AxesDemo extends StatefulWidget {
  /// Creates the axes tab.
  const AxesDemo({super.key});

  @override
  State<AxesDemo> createState() => AxesDemoState();
}

/// The state of [AxesDemo]: the configuration, the data and the chart.
class AxesDemoState extends State<AxesDemo> {
  final math.Random _random = math.Random(6);
  Chart? _chart;

  /// Bumped when the readout changes, without a rebuild of the page.
  final ValueNotifier<int> _readout = ValueNotifier(0);

  /// The last position of the pointer in the chart, or Dart `null`.
  ({double x, double y})? _pointer;

  // The control values.
  String _xType = 'linear';
  String _yType = 'linear';
  int _count = axesDemoCounts.first;
  String _xPosition = 'bottom';
  String _yPosition = 'left';
  bool _autoSkip = true;
  double _maxRotation = 50;
  double _minRotation = 0;
  double _maxTicksLimit = 0;
  double _fontSize = 12;
  String _align = 'center';
  bool _gridDisplay = true;
  bool _gridOffset = false;
  bool _borderDisplay = true;
  bool _titleDisplay = false;
  bool _reverse = false;
  bool _beginAtZero = false;
  String _bounds = 'auto';
  String _timeUnit = 'auto';
  String _locale = 'en-US';

  /// The value of each point of each dataset, as a fraction from 0 to 1.
  late final List<List<double>> _fractions = [
    for (var d = 0; d < _datasetStyles.length; d++)
      [for (var i = 0; i < _count; i++) _random.nextDouble()],
  ];

  /// The datasets of the chart. [_fillData] gives them their data.
  late final List<AnyObject> _datasets = [
    for (final style in _datasetStyles)
      <String, Object?>{
        'label': style.label,
        'data': <AnyObject>[],
        'parsing': true,
        'backgroundColor': style.background,
        'borderColor': style.border,
        'pointStyle': style.style,
      },
  ];

  /// The data of the chart: `labels` and `datasets`.
  late final AnyObject _data = {
    'labels': <Object?>[],
    'datasets': _datasets,
  };

  // The user options. A control writes into them, then calls update().
  late final AnyObject _options = {
    'maintainAspectRatio': false,
    'animation': false,
    'locale': _locale,
    'layout': <String, Object?>{'padding': 8.0},
    'elements': <String, Object?>{
      'point': <String, Object?>{
        'radius': 4.0,
        'hoverRadius': 7.0,
        'borderWidth': 1.0,
      },
    },
    'scales': _scales(),
  };

  /// The inline plugin `axesPointer`: the position of each event in the
  /// canvas, also outside the chart area, from the hook `afterEvent`. The
  /// option `onHover` gets only the events in the chart area
  /// (core.controller.js:1213).
  late final AnyObject _pointerPlugin = {
    'id': 'axesPointer',
    'afterEvent': (Object? chart, Object? args, Object? options) {
      final event = jsGet(args, 'event')! as types.ChartEvent;
      final x = event.x;
      final y = event.y;
      _pointer = event.type == 'mouseout' || x == null || y == null
          ? null
          : (x: x, y: y);
      _readout.value++;
    },
  };

  /// The chart, once it exists.
  @visibleForTesting
  Chart? get chart => _chart;

  /// The data objects of the dataset [index].
  @visibleForTesting
  List<AnyObject> dataOf(int index) =>
      (_datasets[index]['data']! as List<Object?>).cast<AnyObject>();

  /// The rows of the readout: name and value.
  @visibleForTesting
  List<(String, String)> get readoutRows {
    final chart = _chart;
    final x = chart?.scales['x'];
    final y = chart?.scales['y'];
    final area = chart?.chartArea;
    final pointer = _pointer;
    String px(double v) => v.toStringAsFixed(1);
    return [
      ('x', _scaleText(x)),
      ('y', _scaleText(y)),
      (
        'chartArea',
        area == null
            ? '-'
            : 'left ${px(area.left)} · top ${px(area.top)} · '
                  'right ${px(area.right)} · bottom ${px(area.bottom)}',
      ),
      ('pointer x', _pointerText(x, pointer?.x)),
      ('pointer y', _pointerText(y, pointer?.y)),
    ];
  }

  @override
  void initState() {
    super.initState();
    _fillData();
  }

  @override
  void dispose() {
    _readout.dispose();
    super.dispose();
  }

  // Data.

  /// The category label of the point [i].
  static String _label(int i) => 'P${i + 1}';

  /// The ISO date of the point [i]: one day for each point from 2024-01-01.
  static String _day(int i) {
    final day = DateTime.utc(2024, 1, 1 + i);
    String two(int v) => v.toString().padLeft(2, '0');
    return '${day.year}-${two(day.month)}-${two(day.day)}';
  }

  /// The `x` of the point [i] for the x scale type.
  Object _xValue(int i) => switch (_xType) {
    'category' => _label(i),
    'time' => _day(i),
    _ => (i + 1).toDouble(),
  };

  /// The `y` of the value [fraction] for the y scale type: 10 to 100 on a
  /// linear axis, 1 to 10000 on a logarithmic axis.
  double _yValue(double fraction) => _yType == 'logarithmic'
      ? math.pow(10, fraction * 4).toDouble()
      : 10 + fraction * 90;

  AnyObject _item(int i, double fraction) => <String, Object?>{
    'x': _xValue(i),
    'y': _yValue(fraction),
  };

  /// New data arrays for the count and the scale types. The chart takes a
  /// new array as a new data array (`_dataCheck`).
  void _fillData() {
    for (var d = 0; d < _datasets.length; d++) {
      final fractions = _fractions[d];
      _datasets[d]['data'] = <AnyObject>[
        for (var i = 0; i < fractions.length; i++) _item(i, fractions[i]),
      ];
    }
    _data['labels'] = <Object?>[
      if (_xType == 'category')
        for (var i = 0; i < _fractions.first.length; i++) _label(i),
    ];
  }

  // Options.

  AnyObject _scales() => <String, Object?>{
    'x': _scale('x', _xType, _xPosition),
    'y': _scale('y', _yType, _yPosition),
  };

  AnyObject _scale(String axis, String type, String position) =>
      <String, Object?>{
        'type': type,
        'position': position,
        'reverse': _reverse,
        'beginAtZero': _beginAtZero,
        if (_bounds != 'auto') 'bounds': _bounds,
        if (type == 'time' && _timeUnit != 'auto')
          'time': <String, Object?>{'unit': _timeUnit},
        'ticks': <String, Object?>{
          'autoSkip': _autoSkip,
          'maxRotation': _maxRotation,
          'minRotation': _minRotation,
          if (_maxTicksLimit > 0) 'maxTicksLimit': _maxTicksLimit,
          'align': _align,
          'font': <String, Object?>{'size': _fontSize},
        },
        'grid': <String, Object?>{
          'display': _gridDisplay,
          'offset': _gridOffset,
        },
        'border': <String, Object?>{'display': _borderDisplay},
        'title': <String, Object?>{
          'display': _titleDisplay,
          'text': '$axis: $type',
        },
      };

  Chart _create(UiCanvasElement canvas) {
    registerGalleryComponents();
    return Chart(canvas, <String, Object?>{
      'type': StressPointController.id,
      'data': _data,
      'options': _options,
      'plugins': <Object?>[_pointerPlugin],
    });
  }

  void _onChart(Chart chart) {
    _chart = chart;
    _readout.value++;
  }

  /// Changes a control value. The chart reads the user options again in
  /// `update()`, as after `chart.options.scales.x.type = 'time'` upstream.
  /// [data] gives new data arrays first.
  void _change(VoidCallback change, {bool data = false}) {
    setState(change);
    if (data) _fillData();
    _options
      ..['locale'] = _locale
      ..['scales'] = _scales();
    _chart?.update();
    _readout.value++;
  }

  /// A new point count: the data keeps the values of the first points.
  void _setCount(int count) {
    _count = count;
    for (final fractions in _fractions) {
      if (fractions.length > count) {
        fractions.length = count;
      } else {
        while (fractions.length < count) {
          fractions.add(_random.nextDouble());
        }
      }
    }
  }

  /// New `y` values in place.
  void _randomize() {
    for (var d = 0; d < _datasets.length; d++) {
      final fractions = _fractions[d];
      final data = dataOf(d);
      for (var i = 0; i < data.length; i++) {
        data[i]['y'] = _yValue(fractions[i] = _random.nextDouble());
      }
    }
    _chart?.update();
    _readout.value++;
  }

  /// `data.push(item)`, or `data.pop()`, in each dataset, and the same
  /// change of the labels of a category axis. The data array listeners of
  /// the controller get the change (`notifyArrayListeners`, differences.md
  /// `platform-array-events`).
  void _resize({required bool add}) {
    final labels = _data['labels']! as List<Object?>;
    final length = _fractions.first.length;
    if (!add && length <= 1) return;
    setState(() => _count = add ? length + 1 : length - 1);
    for (var d = 0; d < _datasets.length; d++) {
      final fractions = _fractions[d];
      final data = dataOf(d);
      if (add) {
        final fraction = _random.nextDouble();
        fractions.add(fraction);
        final item = _item(length, fraction);
        data.add(item);
        notifyArrayListeners(data, 'push', [item]);
      } else {
        fractions.removeLast();
        data.removeLast();
        notifyArrayListeners(data, 'pop', const []);
      }
    }
    if (_xType == 'category') {
      if (add) {
        labels.add(_label(length));
      } else {
        labels.removeLast();
      }
    }
    _chart?.update();
    _readout.value++;
  }

  // Readout.

  /// A value of `getLabelForValue` as text.
  static String _labelText(Object? label) =>
      label is String ? label : showJs(label);

  /// A scale value as text: a timestamp without decimals.
  static String _valueText(double value) =>
      value.toStringAsFixed(value.abs() >= 1e6 ? 0 : 2);

  /// The type, the range, the tick count and the label rotation of [scale].
  static String _scaleText(Scale? scale) {
    if (scale == null) return '-';
    final ticks = scale.ticks?.length ?? 0;
    final rotation = jsToNumber(scale.labelRotation);
    return '${scale.type} · '
        '${_labelText(scale.getLabelForValue(scale.min))} to '
        '${_labelText(scale.getLabelForValue(scale.max))} · '
        '$ticks ticks · rotation '
        '${rotation.isNaN ? '-' : rotation.toStringAsFixed(1)}';
  }

  /// The pixel [pixel] of the pointer on [scale]: its value, the label of
  /// the value, and the pixel of the value less [pixel].
  static String _pointerText(Scale? scale, double? pixel) {
    if (scale == null || pixel == null) return '-';
    final value = scale.getValueForPixel(pixel);
    if (value == null) return '${pixel.toStringAsFixed(1)} px → -';
    final back = scale.getPixelForValue(value) - pixel;
    return '${pixel.toStringAsFixed(1)} px → ${_valueText(value)} → '
        '${_labelText(scale.getLabelForValue(value))} '
        '(round trip ${back.toStringAsFixed(2)} px)';
  }

  // Controls.

  Widget _choices<T>(
    String name,
    String label,
    List<T> values,
    T value,
    ValueChanged<T> onSelected, {
    bool data = false,
  }) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(width: 92, child: Text(label)),
        for (final v in values)
          ChoiceChip(
            key: ValueKey('axes.$name.$v'),
            label: Text('$v'),
            selected: v == value,
            onSelected: (_) => _change(() => onSelected(v), data: data),
          ),
      ],
    );
  }

  Widget _slider(
    String key,
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged, {
    String Function(double value)? format,
  }) => SliderControl(
    label: label,
    sliderKey: ValueKey(key),
    value: value,
    min: min,
    max: max,
    divisions: (max - min).round(),
    format: format,
    onChanged: (v) => _change(() => onChanged(v)),
  );

  ({String key, String label, bool value, ValueChanged<bool> onChanged})
  _toggle(String key, String label, bool value, ValueChanged<bool> set) => (
    key: key,
    label: label,
    value: value,
    onChanged: (v) => _change(() => set(v)),
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
    return DemoPageBody(
      children: [
        DemoCard(
          title: 'Chart',
          source:
              'core.controller: buildOrUpdateScales · scales: LinearScale, '
              'LogarithmicScale, CategoryScale, TimeScale · core.adapters: '
              'the default date adapter · StressPointController: '
              'getPixelForValue',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'A real Chart of the ported core with the ported scales. '
                'Move the mouse over the chart, or touch it: the readout '
                'maps the pointer to a value of each scale and back.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) => ChartCanvas(
                  key: const ValueKey('axes.host'),
                  height: constraints.maxWidth >= 560 ? 360 : 300,
                  create: _create,
                  onChart: _onChart,
                ),
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<int>(
                valueListenable: _readout,
                builder: (context, _, _) => ReadoutTable(
                  key: const ValueKey('axes.readout'),
                  rows: readoutRows,
                ),
              ),
            ],
          ),
        ),
        DemoCard(
          title: 'Scales',
          source:
              'options.scales.x.type · options.scales.y.type · position · '
              'bounds · time.unit · options.locale → chart.update()',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _choices(
                'x.type',
                'x type',
                axesDemoXTypes,
                _xType,
                (v) => _xType = v,
                data: true,
              ),
              const SizedBox(height: 8),
              _choices(
                'y.type',
                'y type',
                axesDemoYTypes,
                _yType,
                (v) => _yType = v,
                data: true,
              ),
              const SizedBox(height: 8),
              _choices(
                'x.position',
                'x position',
                const ['bottom', 'top'],
                _xPosition,
                (v) => _xPosition = v,
              ),
              const SizedBox(height: 8),
              _choices(
                'y.position',
                'y position',
                const ['left', 'right'],
                _yPosition,
                (v) => _yPosition = v,
              ),
              const SizedBox(height: 8),
              _choices(
                'bounds',
                'bounds',
                axesDemoBounds,
                _bounds,
                (v) => _bounds = v,
              ),
              const SizedBox(height: 8),
              _choices(
                'time.unit',
                'time unit',
                axesDemoTimeUnits,
                _timeUnit,
                (v) => _timeUnit = v,
              ),
              const SizedBox(height: 8),
              _choices(
                'locale',
                'locale',
                axesDemoLocales,
                _locale,
                (v) => _locale = v,
              ),
              const SizedBox(height: 8),
              ToggleChips(
                toggles: [
                  _toggle('axes.reverse', 'reverse', _reverse, (v) {
                    _reverse = v;
                  }),
                  _toggle('axes.beginAtZero', 'beginAtZero', _beginAtZero, (
                    v,
                  ) {
                    _beginAtZero = v;
                  }),
                ],
              ),
            ],
          ),
        ),
        DemoCard(
          title: 'Ticks',
          source:
              'options.scales[id].ticks: autoSkip, maxRotation, minRotation, '
              'maxTicksLimit, font.size, align',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ToggleChips(
                toggles: [
                  _toggle('axes.ticks.autoSkip', 'autoSkip', _autoSkip, (v) {
                    _autoSkip = v;
                  }),
                ],
              ),
              DemoControlGrid(
                children: [
                  _slider(
                    'axes.ticks.maxRotation',
                    'maxRotation',
                    _maxRotation,
                    0,
                    90,
                    (v) => _maxRotation = v,
                  ),
                  _slider(
                    'axes.ticks.minRotation',
                    'minRotation',
                    _minRotation,
                    0,
                    90,
                    (v) => _minRotation = v,
                  ),
                  // 0 writes no option: the default of the scale type.
                  _slider(
                    'axes.ticks.maxTicksLimit',
                    'maxTicksLimit',
                    _maxTicksLimit,
                    0,
                    30,
                    (v) => _maxTicksLimit = v,
                    format: (v) => v == 0 ? 'auto' : v.toStringAsFixed(0),
                  ),
                  _slider(
                    'axes.ticks.font.size',
                    'font size',
                    _fontSize,
                    8,
                    24,
                    (v) => _fontSize = v,
                  ),
                ],
              ),
              _choices(
                'ticks.align',
                'align',
                axesDemoAligns,
                _align,
                (v) => _align = v,
              ),
            ],
          ),
        ),
        DemoCard(
          title: 'Grid, border and title',
          source:
              'options.scales[id].grid.display · grid.offset · '
              'border.display · title.display',
          child: ToggleChips(
            toggles: [
              _toggle('axes.grid.display', 'grid', _gridDisplay, (v) {
                _gridDisplay = v;
              }),
              _toggle('axes.grid.offset', 'grid offset', _gridOffset, (v) {
                _gridOffset = v;
              }),
              _toggle('axes.border.display', 'border', _borderDisplay, (v) {
                _borderDisplay = v;
              }),
              _toggle('axes.title.display', 'title', _titleDisplay, (v) {
                _titleDisplay = v;
              }),
            ],
          ),
        ),
        DemoCard(
          title: 'Data',
          source:
              'data.labels · data.datasets[i].data · parsing: true → '
              'scale.parse',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _choices(
                'count',
                'points',
                axesDemoCounts,
                _count,
                _setCount,
                data: true,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _button('axes.data.randomize', 'randomize', _randomize),
                  _button(
                    'axes.data.add',
                    'add point',
                    () => _resize(add: true),
                  ),
                  _button(
                    'axes.data.remove',
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
