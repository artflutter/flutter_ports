// Original code, not ported from Chart.js: the gallery demo of phase 6.

import 'dart:math' as math;

import 'package:chartjs_gallery/demo/demo_common.dart';
import 'package:chartjs_gallery/demo/demo_controls.dart';
import 'package:chartjs_gallery/demo/gallery_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

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

/// The values of the option `ticks.maxRotation`, in degrees.
const List<double> axesDemoMaxRotations = [0, 30, 50, 90];

/// The values of the option `ticks.minRotation`, in degrees.
const List<double> axesDemoMinRotations = [0, 30, 45, 90];

/// The values of the option `ticks.maxTicksLimit`. 0 writes no option: the
/// default of the scale type.
const List<double> axesDemoMaxTicksLimits = [0, 5, 10, 20];

/// The values of the option `ticks.font.size`, in px.
const List<double> axesDemoFontSizes = [8, 12, 16, 24];

/// The short text of a scale type segment.
const Map<String, String> _typeText = {
  'linear': 'lin',
  'logarithmic': 'log',
  'category': 'cat',
  'time': 'time',
};

/// The short text of a time unit segment, when the name of the unit is too
/// long for a segment on a phone. The tooltip gives the name. At 360 x 640 a
/// unit segment has 34.4 px for its text; `month` is 40.3 px wide in Roboto
/// `labelLarge`, `mon` 28.0 px.
const Map<String, String> _unitText = {'month': 'mon'};

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
/// The chart is the `ChartView` of the app library (Chart.js ADR 0049): a
/// `Chart` of `core.controller` on the canvas of the view. Its type is
/// `line`, the ported `LineController` (Chart.js ADR 0031, section 4): each
/// point gets the pixels of
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
/// - The plugins of `registerables` run with their defaults, as in a chart
///   of the Chart.js bundle (`src/index.umd.ts:28`). The legend box takes
///   its place in the layout with the scales, and the tooltip shows the
///   label and the value texts of the scales (`getLabelAndValue`,
///   core.datasetController.js:687-697). The tab has no plugin opt-out
///   (Chart.js ADR 0031, Open): the chart area of the readout is the area
///   of an upstream chart with these options.
///
/// The controls of the ticks, the grid, the border, the title, `reverse`,
/// `beginAtZero` and `bounds` apply to both axes. The chart has no
/// animation: the Core tab shows the animations.
///
/// Each parameter is a full-width segmented button (Chart.js ADR 0031,
/// section 10). The lines `x`, `y` and `N` are above the chart. The other
/// parameters come after the readout (section 10.7). Each segment has a
/// `ValueKey` (`axes.x.type.time`, `axes.ticks.autoSkip`,
/// `axes.ticks.maxRotation.50`, `axes.data.add`, ...).
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
  late final List<Map<String, Object?>> _datasets = [
    for (final style in _datasetStyles)
      <String, Object?>{
        'label': style.label,
        'data': <Map<String, Object?>>[],
        'parsing': true,
        'backgroundColor': style.background,
        'borderColor': style.border,
        'pointStyle': style.style,
      },
  ];

  /// The data of the chart: `labels` and `datasets`.
  late final Map<String, Object?> _data = {
    'labels': <Object?>[],
    'datasets': _datasets,
  };

  // The user options. A control writes into them, then calls update().
  late final Map<String, Object?> _options = {
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
  late final Map<String, Object?> _pointerPlugin = {
    'id': 'axesPointer',
    'afterEvent': (Object? chart, Object? args, Object? options) {
      // The hook arguments are a Map (core.controller.js:1164-1169).
      final event = (args! as Map<String, Object?>)['event']! as ChartEvent;
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
  List<Map<String, Object?>> dataOf(int index) =>
      (_datasets[index]['data']! as List<Object?>).cast<Map<String, Object?>>();

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
    registerGalleryComponents();
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

  Map<String, Object?> _item(int i, double fraction) => <String, Object?>{
    'x': _xValue(i),
    'y': _yValue(fraction),
  };

  /// New data arrays for the count and the scale types. The chart takes a
  /// new array as a new data array (`_dataCheck`).
  void _fillData() {
    for (var d = 0; d < _datasets.length; d++) {
      final fractions = _fractions[d];
      _datasets[d]['data'] = <Map<String, Object?>>[
        for (var i = 0; i < fractions.length; i++) _item(i, fractions[i]),
      ];
    }
    _data['labels'] = <Object?>[
      if (_xType == 'category')
        for (var i = 0; i < _fractions.first.length; i++) _label(i),
    ];
  }

  // Options.

  Map<String, Object?> _scales() => <String, Object?>{
    'x': _scale('x', _xType, _xPosition),
    'y': _scale('y', _yType, _yPosition),
  };

  Map<String, Object?> _scale(String axis, String type, String position) =>
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

  /// The config of the `ChartView`, made once: a rebuild of the tab gives
  /// the view the same Map, thus no update (Chart.js ADR 0049, section 4).
  /// A control writes into the user options and calls `update()`.
  late final Map<String, Object?> _config = <String, Object?>{
    'type': 'line',
    'data': _data,
    'options': _options,
    'plugins': <Object?>[_pointerPlugin],
  };

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
    // `labelRotation` holds a JS value: `undefined` before the first fit.
    final raw = scale.labelRotation;
    final rotation = raw is num ? raw.toDouble() : double.nan;
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

  /// The text of [value] in a key: the integer text of a number.
  static String _keyText(Object? value) =>
      value is double ? value.toInt().toString() : '$value';

  /// The line [label] of the option [name]: a segment for each value of
  /// [values], with the key `axes.<name>.<value>`. [data] gives new data
  /// arrays before the update.
  Widget _choice<T>(
    String name,
    String label,
    List<T> values,
    T value,
    ValueChanged<T> onSelected, {
    String Function(T value)? text,
    bool data = false,
  }) => SegmentChoice<T>(
    label: label,
    items: [
      for (final v in values)
        (
          key: 'axes.$name.${_keyText(v)}',
          text: text?.call(v) ?? _keyText(v),
          icon: null,
          tooltip: '$name ${_keyText(v)}',
          value: v,
        ),
    ],
    value: value,
    onChanged: (v) => _change(() => onSelected(v), data: data),
  );

  /// An on/off segment of the option of [key].
  SegmentToggleItem _toggle(
    String key,
    IconData icon,
    String tooltip,
    bool value,
    ValueChanged<bool> set,
  ) => (
    key: key,
    icon: icon,
    tooltip: tooltip,
    value: value,
    onChanged: (v) => _change(() => set(v)),
  );

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

  Widget _toggles() => SegmentToggles(
    items: [
      _toggle('axes.reverse', Icons.swap_horiz, 'reverse', _reverse, (v) {
        _reverse = v;
      }),
      _toggle(
        'axes.beginAtZero',
        Icons.exposure_zero,
        'beginAtZero',
        _beginAtZero,
        (v) => _beginAtZero = v,
      ),
      _toggle(
        'axes.ticks.autoSkip',
        Icons.skip_next,
        'ticks.autoSkip',
        _autoSkip,
        (v) => _autoSkip = v,
      ),
      _toggle(
        'axes.grid.display',
        Icons.grid_on,
        'grid.display',
        _gridDisplay,
        (
          v,
        ) {
          _gridDisplay = v;
        },
      ),
      _toggle(
        'axes.grid.offset',
        Icons.vertical_split,
        'grid.offset',
        _gridOffset,
        (v) => _gridOffset = v,
      ),
      _toggle(
        'axes.border.display',
        Icons.border_outer,
        'border.display',
        _borderDisplay,
        (v) => _borderDisplay = v,
      ),
      _toggle(
        'axes.title.display',
        Icons.title,
        'title.display',
        _titleDisplay,
        (v) => _titleDisplay = v,
      ),
      _command('axes.data.randomize', Icons.shuffle, 'randomize', _randomize),
      _command(
        'axes.data.add',
        Icons.add,
        'add a point',
        () => _resize(add: true),
      ),
      _command(
        'axes.data.remove',
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
              'ChartView · core.controller: buildOrUpdateScales, update() · '
              'scales: '
              'LinearScale, LogarithmicScale, CategoryScale, TimeScale · '
              'core.adapters: the default date adapter · LineController: '
              'getPixelForValue · options.scales[id]: type, position, '
              'bounds, reverse, beginAtZero, time.unit, ticks, grid, border, '
              'title · options.locale · parsing: true → scale.parse · '
              'plugins: legend, tooltip',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _choice(
                'x.type',
                'x',
                axesDemoXTypes,
                _xType,
                (v) => _xType = v,
                text: (v) => _typeText[v]!,
                data: true,
              ),
              gap,
              _choice(
                'y.type',
                'y',
                axesDemoYTypes,
                _yType,
                (v) => _yType = v,
                text: (v) => _typeText[v]!,
                data: true,
              ),
              gap,
              _choice(
                'count',
                'N',
                axesDemoCounts,
                _count,
                _setCount,
                data: true,
              ),
              const SizedBox(height: 12),
              // The options have `maintainAspectRatio: false`: the view
              // takes the height of the box (Chart.js ADR 0049, section 5).
              LayoutBuilder(
                builder: (context, constraints) => SizedBox(
                  key: const ValueKey('axes.host'),
                  height: constraints.maxWidth >= 560 ? 360 : 300,
                  child: ChartView.raw(
                    config: _config,
                    onChartCreated: _onChart,
                  ),
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
              // The split of Chart.js ADR 0031, section 10.7 (Open, for the
              // maintainer): the other 17 parameters do not fit above a
              // chart that is in view on a phone. They come after the
              // readout.
              const SizedBox(height: 12),
              _choice(
                'x.position',
                'x pos',
                const ['bottom', 'top'],
                _xPosition,
                (v) => _xPosition = v,
              ),
              gap,
              _choice(
                'y.position',
                'y pos',
                const ['left', 'right'],
                _yPosition,
                (v) => _yPosition = v,
              ),
              gap,
              _choice(
                'bounds',
                'bound',
                axesDemoBounds,
                _bounds,
                (v) => _bounds = v,
              ),
              gap,
              _choice(
                'time.unit',
                'unit',
                axesDemoTimeUnits,
                _timeUnit,
                (v) => _timeUnit = v,
                text: (v) => _unitText[v] ?? v,
              ),
              gap,
              _choice(
                'locale',
                'locale',
                axesDemoLocales,
                _locale,
                (v) => _locale = v,
              ),
              gap,
              _choice(
                'ticks.align',
                'align',
                axesDemoAligns,
                _align,
                (v) => _align = v,
              ),
              gap,
              _toggles(),
              gap,
              _choice(
                'ticks.maxRotation',
                'max°',
                axesDemoMaxRotations,
                _maxRotation,
                (v) => _maxRotation = v,
              ),
              gap,
              _choice(
                'ticks.minRotation',
                'min°',
                axesDemoMinRotations,
                _minRotation,
                (v) => _minRotation = v,
              ),
              gap,
              // 0 writes no option: the default of the scale type.
              _choice(
                'ticks.maxTicksLimit',
                'ticks',
                axesDemoMaxTicksLimits,
                _maxTicksLimit,
                (v) => _maxTicksLimit = v,
                text: (v) => v == 0 ? 'auto' : _keyText(v),
              ),
              gap,
              _choice(
                'ticks.font.size',
                'font',
                axesDemoFontSizes,
                _fontSize,
                (v) => _fontSize = v,
              ),
              const SizedBox(height: 8),
              Text(
                'A real line chart of the ported core with the ported '
                'scales. Move the mouse over the chart, or touch it: the '
                'readout maps the pointer to a value of each scale and back. '
                'The tooltip shows the label and the value texts of the '
                'scales. The scale options apply to both axes. The chart has '
                'no animation: the Core tab shows the animations.',
                key: const ValueKey('axes.help'),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
