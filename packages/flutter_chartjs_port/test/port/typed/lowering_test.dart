// Original code, not ported from Chart.js: the lowering twins of the typed API.
@TestOn('vm')
library;

import 'dart:ui' show Color, FontWeight;

import 'package:flutter/foundation.dart' show ValueKey;
import 'package:flutter/painting.dart' show EdgeInsets, TextStyle;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show createContext;
import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs_port/src/js/js_function.dart'
    show JsFunction, jsCall;
import 'package:flutter_chartjs_port/src/js/js_object.dart' show jsGet;
import 'package:flutter_chartjs_port/src/typed/axes.dart' show lowerAxis;
import 'package:flutter_chartjs_port/src/typed/datasets.dart' show lowerDataset;
import 'package:flutter_chartjs_port/src/typed/lower.dart'
    show ChartConfigLowering;
import 'package:flutter_test/flutter_test.dart';

import 'twin.dart';

// Chart.js ADR 0052, sections 2 and 11: the lowering twins. For each typed
// field, a typed object with that field alone lowers to the Map of its raw
// twin, the form of the Chart.js docs, with the same keys in the same order
// (`jsObjectKeys`). A typed object with all its fields lowers to the twin
// with all keys, in parameter order. The chart reads only the Maps, so equal
// Maps give equal charts. The datasets, the axes, the option groups and the
// config each have a group. A callback lowers to a function; the chart
// cases of callbacks_test.dart call the functions.
//
// VM only: the typed files import dart:ui and the painting library.

const Color _red = Color(0xFFFF6384);
const Color _blue = Color(0xFF36A2EB);
const String _redValue = 'rgba(255, 99, 132, 1)';
const String _blueValue = 'rgba(54, 162, 235, 1)';

/// A scriptable color: blue at the data index 1, else red.
Color _colorFor(ChartContext context) => context.dataIndex == 1 ? _blue : _red;

/// The 8 dataset classes, each without a parameter, with the chart type of
/// its controller.
const Map<ChartKind, Dataset> _empty = {
  ChartKind.bar: BarDataset(),
  ChartKind.line: LineDataset(),
  ChartKind.scatter: ScatterDataset(),
  ChartKind.bubble: BubbleDataset(),
  ChartKind.pie: PieDataset(),
  ChartKind.doughnut: DoughnutDataset(),
  ChartKind.polarArea: PolarAreaDataset(),
  ChartKind.radar: RadarDataset(),
};

/// The dataset scope of [dataset] in a chart of its own type.
JsObjectFace _lower(Dataset dataset) => lowerDataset(
  dataset,
  _empty.entries
      .firstWhere((entry) => entry.value.runtimeType == dataset.runtimeType)
      .key,
);

/// The cases of the parameters of [Dataset]: a function that sets one
/// parameter with `copyWith`, and the raw twin.
final Map<String, (Dataset Function(Dataset), Map<String, Object?>)> _common = {
  'key': ((d) => d.copyWith(key: const ValueKey('a')), {}),
  'label': ((d) => d.copyWith(label: 'A'), {'label': 'A'}),
  'hidden': ((d) => d.copyWith(hidden: true), {'hidden': true}),
  'order': ((d) => d.copyWith(order: 2), {'order': 2}),
  'backgroundColor': (
    (d) => d.copyWith(backgroundColor: _red),
    {'backgroundColor': _redValue},
  ),
  'backgroundColors': (
    (d) => d.copyWith(backgroundColors: [_red, _blue]),
    {
      'backgroundColor': [_redValue, _blueValue],
    },
  ),
  'backgroundColorFor': (
    (d) => d.copyWith(backgroundColorFor: _colorFor),
    {'backgroundColor': (Object? context, Object? options) => _redValue},
  ),
  'borderColor': (
    (d) => d.copyWith(borderColor: _blue),
    {'borderColor': _blueValue},
  ),
  'borderColors': (
    (d) => d.copyWith(borderColors: [_blue, _red]),
    {
      'borderColor': [_blueValue, _redValue],
    },
  ),
  'borderColorFor': (
    (d) => d.copyWith(borderColorFor: _colorFor),
    {'borderColor': (Object? context, Object? options) => _redValue},
  ),
  'borderWidth': ((d) => d.copyWith(borderWidth: 2), {'borderWidth': 2}),
  'hoverBackgroundColor': (
    (d) => d.copyWith(hoverBackgroundColor: _blue),
    {'hoverBackgroundColor': _blueValue},
  ),
  'hoverBorderColor': (
    (d) => d.copyWith(hoverBorderColor: _red),
    {'hoverBorderColor': _redValue},
  ),
  'hoverBorderWidth': (
    (d) => d.copyWith(hoverBorderWidth: 3),
    {'hoverBorderWidth': 3},
  ),
  'extra': (
    (d) => d.copyWith(extra: {'clip': 5}),
    {'clip': 5},
  ),
};

/// A [LineDataset], a [ScatterDataset] and a [RadarDataset] with the same
/// line style parameters.
List<Dataset> _lineStyle({
  ChartFill? fill,
  double? tension,
  List<double>? borderDash,
  bool? spanGaps,
  bool? showLine,
  bool? stepped,
  double? pointRadius,
  double? pointHoverRadius,
  ChartPointStyle? pointStyle,
  Color? pointBackgroundColor,
  Color? pointBorderColor,
  double? pointBorderWidth,
  Color? pointHoverBackgroundColor,
  Color? pointHoverBorderColor,
}) => [
  LineDataset(
    fill: fill,
    tension: tension,
    borderDash: borderDash,
    spanGaps: spanGaps,
    showLine: showLine,
    stepped: stepped,
    pointRadius: pointRadius,
    pointHoverRadius: pointHoverRadius,
    pointStyle: pointStyle,
    pointBackgroundColor: pointBackgroundColor,
    pointBorderColor: pointBorderColor,
    pointBorderWidth: pointBorderWidth,
    pointHoverBackgroundColor: pointHoverBackgroundColor,
    pointHoverBorderColor: pointHoverBorderColor,
  ),
  ScatterDataset(
    fill: fill,
    tension: tension,
    borderDash: borderDash,
    spanGaps: spanGaps,
    showLine: showLine,
    stepped: stepped,
    pointRadius: pointRadius,
    pointHoverRadius: pointHoverRadius,
    pointStyle: pointStyle,
    pointBackgroundColor: pointBackgroundColor,
    pointBorderColor: pointBorderColor,
    pointBorderWidth: pointBorderWidth,
    pointHoverBackgroundColor: pointHoverBackgroundColor,
    pointHoverBorderColor: pointHoverBorderColor,
  ),
  RadarDataset(
    fill: fill,
    tension: tension,
    borderDash: borderDash,
    spanGaps: spanGaps,
    showLine: showLine,
    stepped: stepped,
    pointRadius: pointRadius,
    pointHoverRadius: pointHoverRadius,
    pointStyle: pointStyle,
    pointBackgroundColor: pointBackgroundColor,
    pointBorderColor: pointBorderColor,
    pointBorderWidth: pointBorderWidth,
    pointHoverBackgroundColor: pointHoverBackgroundColor,
    pointHoverBorderColor: pointHoverBorderColor,
  ),
];

/// A [PieDataset] and a [DoughnutDataset] with the same arc parameters,
/// and a [PolarAreaDataset] with the parameters that it has.
List<Dataset> _arcs({
  double? offset,
  double? hoverOffset,
  double? spacing,
  double? weight,
  double? circumference,
  double? rotation,
  ChartLength? cutout,
  ChartLength? radius,
}) => [
  PieDataset(
    offset: offset,
    hoverOffset: hoverOffset,
    spacing: spacing,
    weight: weight,
    circumference: circumference,
    rotation: rotation,
    cutout: cutout,
    radius: radius,
  ),
  DoughnutDataset(
    offset: offset,
    hoverOffset: hoverOffset,
    spacing: spacing,
    weight: weight,
    circumference: circumference,
    rotation: rotation,
    cutout: cutout,
    radius: radius,
  ),
  if (weight == null &&
      circumference == null &&
      rotation == null &&
      cutout == null &&
      radius == null)
    PolarAreaDataset(
      offset: offset,
      hoverOffset: hoverOffset,
      spacing: spacing,
    ),
];

/// The cases of the parameters of the dataset classes, without `data` and
/// `points`: the typed datasets with one parameter and the raw twin.
final Map<String, (List<Dataset>, Map<String, Object?>)> _own = {
  'xAxisID': (
    const [
      BarDataset(xAxisID: 'x2'),
      LineDataset(xAxisID: 'x2'),
      ScatterDataset(xAxisID: 'x2'),
      BubbleDataset(xAxisID: 'x2'),
    ],
    {'xAxisID': 'x2'},
  ),
  'yAxisID': (
    const [
      BarDataset(yAxisID: 'y2'),
      LineDataset(yAxisID: 'y2'),
      ScatterDataset(yAxisID: 'y2'),
      BubbleDataset(yAxisID: 'y2'),
    ],
    {'yAxisID': 'y2'},
  ),
  'stack': (
    const [
      BarDataset(stack: 's'),
      LineDataset(stack: 's'),
      ScatterDataset(stack: 's'),
    ],
    {'stack': 's'},
  ),
  'indexAxis': (
    const [BarDataset(indexAxis: .y), LineDataset(indexAxis: .y)],
    {'indexAxis': 'y'},
  ),
  'borderRadius, a number': (
    const [BarDataset(borderRadius: 4)],
    {'borderRadius': 4},
  ),
  'barPercentage': (
    const [BarDataset(barPercentage: 0.5)],
    {'barPercentage': 0.5},
  ),
  'categoryPercentage': (
    const [BarDataset(categoryPercentage: 0.6)],
    {'categoryPercentage': 0.6},
  ),
  'barThickness': (
    const [BarDataset(barThickness: 10)],
    {'barThickness': 10},
  ),
  'maxBarThickness': (
    const [BarDataset(maxBarThickness: 12)],
    {'maxBarThickness': 12},
  ),
  'minBarLength': (
    const [BarDataset(minBarLength: 2)],
    {'minBarLength': 2},
  ),
  'grouped': (
    const [BarDataset(grouped: false)],
    {'grouped': false},
  ),
  'fill, a name': (_lineStyle(fill: .origin), {'fill': 'origin'}),
  'fill, none': (_lineStyle(fill: .none), {'fill': false}),
  'fill, a dataset index': (_lineStyle(fill: const .dataset(1)), {'fill': 1}),
  'fill, a relative index': (
    _lineStyle(fill: const .relative(-1)),
    {'fill': '-1'},
  ),
  'fill, a value': (
    _lineStyle(fill: const .value(25)),
    {
      'fill': {'value': 25},
    },
  ),
  'tension': (_lineStyle(tension: 0.4), {'tension': 0.4}),
  'borderDash': (
    _lineStyle(borderDash: [5, 5]),
    {
      'borderDash': [5, 5],
    },
  ),
  'spanGaps': (_lineStyle(spanGaps: true), {'spanGaps': true}),
  'showLine': (_lineStyle(showLine: false), {'showLine': false}),
  'stepped': (_lineStyle(stepped: true), {'stepped': true}),
  'pointRadius': (_lineStyle(pointRadius: 0), {'pointRadius': 0}),
  'pointHoverRadius': (
    _lineStyle(pointHoverRadius: 6),
    {'pointHoverRadius': 6},
  ),
  'pointStyle': (
    [
      ..._lineStyle(pointStyle: .rectRot),
      const BubbleDataset(pointStyle: .rectRot),
    ],
    {'pointStyle': 'rectRot'},
  ),
  'pointStyle, none': (
    [..._lineStyle(pointStyle: .none), const BubbleDataset(pointStyle: .none)],
    {'pointStyle': false},
  ),
  'pointBackgroundColor': (
    _lineStyle(pointBackgroundColor: _red),
    {'pointBackgroundColor': _redValue},
  ),
  'pointBorderColor': (
    _lineStyle(pointBorderColor: _blue),
    {'pointBorderColor': _blueValue},
  ),
  'pointBorderWidth': (
    _lineStyle(pointBorderWidth: 2),
    {'pointBorderWidth': 2},
  ),
  'pointHoverBackgroundColor': (
    _lineStyle(pointHoverBackgroundColor: _red),
    {'pointHoverBackgroundColor': _redValue},
  ),
  'pointHoverBorderColor': (
    _lineStyle(pointHoverBorderColor: _blue),
    {'pointHoverBorderColor': _blueValue},
  ),
  'radius of a bubble': (const [BubbleDataset(radius: 7)], {'radius': 7}),
  'hoverRadius': (const [BubbleDataset(hoverRadius: 2)], {'hoverRadius': 2}),
  'offset': (_arcs(offset: 4), {'offset': 4}),
  'hoverOffset': (_arcs(hoverOffset: 4), {'hoverOffset': 4}),
  'spacing': (_arcs(spacing: 2), {'spacing': 2}),
  'weight': (_arcs(weight: 2), {'weight': 2}),
  'circumference': (_arcs(circumference: 180), {'circumference': 180}),
  'rotation': (_arcs(rotation: -90), {'rotation': -90}),
  'cutout, a percent': (_arcs(cutout: const .percent(50)), {'cutout': '50%'}),
  'cutout, pixels': (_arcs(cutout: const .pixels(20)), {'cutout': 20}),
  'radius, a percent': (_arcs(radius: const .percent(90)), {'radius': '90%'}),
  'radius, pixels': (_arcs(radius: const .pixels(100)), {'radius': 100}),
};

/// A font and its `FontSpec` Map.
const TextStyle _font = TextStyle(
  fontFamily: 'Arial',
  fontSize: 14,
  fontWeight: FontWeight.w700,
);
const Map<String, Object?> _fontValue = {
  'family': "'Arial'",
  'size': 14,
  'weight': 700,
};

/// The times of the time axes.
final DateTime _start = DateTime.utc(2020);
final DateTime _end = DateTime.utc(2021);

/// The function of a twin: the lowered value is a function too.
Object? _function([Object? a, Object? b, Object? c]) => null;

/// A tick format.
String? _format(AxisTickInfo tick) => '${tick.value}';

/// A legend handler.
void _onLegend(ChartLegendEventDetails details) {}

/// A tooltip text of the items.
String? _title2(List<ChartTooltipItem> items) => 'T';

/// A tooltip text of one item.
String? _label(ChartTooltipItem item) => 'L';

/// An animation callback.
void _onAnimation(ChartAnimationDetails details) {}

/// A chart callback.
void _onEvent(ChartEventDetails details) {}

/// The options scope of the root scope of [config].
JsObjectFace _options(ChartConfig config) =>
    ChartConfigLowering(config).lower()['options']! as JsObjectFace;

/// The 6 axis classes, each without a parameter, with its scale type.
const List<(ChartAxis, String)> _axes = [
  (CategoryAxis(), 'category'),
  (LinearAxis(), 'linear'),
  (LogarithmicAxis(), 'logarithmic'),
  (TimeAxis(), 'time'),
  (TimeSeriesAxis(), 'timeseries'),
  (RadialLinearAxis(), 'radialLinear'),
];

/// The cases of the parameters of [ChartAxis]: a function that sets one
/// parameter with `copyWith`, and the raw twin without its `type`.
final Map<String, (ChartAxis Function(ChartAxis), Map<String, Object?>)>
_axisCommon = {
  'display': ((a) => a.copyWith(display: false), {'display': false}),
  'position': ((a) => a.copyWith(position: .left), {'position': 'left'}),
  'position, center': (
    (a) => a.copyWith(position: .center),
    {'position': 'center'},
  ),
  'reverse': ((a) => a.copyWith(reverse: true), {'reverse': true}),
  'stacked': ((a) => a.copyWith(stacked: true), {'stacked': true}),
  'ticks': (
    (a) => a.copyWith(ticks: const AxisTicks(display: false)),
    {
      'ticks': {'display': false},
    },
  ),
  'grid': (
    (a) => a.copyWith(grid: const AxisGrid(display: false)),
    {
      'grid': {'display': false},
    },
  ),
  'title': (
    (a) => a.copyWith(title: const AxisTitle(text: 'T')),
    {
      'title': {'text': 'T'},
    },
  ),
  'extra': ((a) => a.copyWith(extra: {'grace': '5%'}), {'grace': '5%'}),
};

/// The cases of the parameters of the axis classes: the typed axes with
/// one parameter and the raw twin without its `type`.
final Map<String, (List<(ChartAxis, String)>, Map<String, Object?>)> _axisOwn =
    {
      'min of a category axis': (
        const [(CategoryAxis(min: 'b'), 'category')],
        {'min': 'b'},
      ),
      'max of a category axis': (
        const [(CategoryAxis(max: 'c'), 'category')],
        {'max': 'c'},
      ),
      'min': (
        const [
          (LinearAxis(min: -1), 'linear'),
          (LogarithmicAxis(min: -1), 'logarithmic'),
          (RadialLinearAxis(min: -1), 'radialLinear'),
        ],
        {'min': -1},
      ),
      'max': (
        const [
          (LinearAxis(max: 9), 'linear'),
          (LogarithmicAxis(max: 9), 'logarithmic'),
          (RadialLinearAxis(max: 9), 'radialLinear'),
        ],
        {'max': 9},
      ),
      'suggestedMin': (
        const [
          (LinearAxis(suggestedMin: 2), 'linear'),
          (LogarithmicAxis(suggestedMin: 2), 'logarithmic'),
          (RadialLinearAxis(suggestedMin: 2), 'radialLinear'),
        ],
        {'suggestedMin': 2},
      ),
      'suggestedMax': (
        const [
          (LinearAxis(suggestedMax: 8), 'linear'),
          (LogarithmicAxis(suggestedMax: 8), 'logarithmic'),
          (RadialLinearAxis(suggestedMax: 8), 'radialLinear'),
        ],
        {'suggestedMax': 8},
      ),
      'beginAtZero': (
        const [
          (LinearAxis(beginAtZero: true), 'linear'),
          (RadialLinearAxis(beginAtZero: true), 'radialLinear'),
        ],
        {'beginAtZero': true},
      ),
      'min of a time axis': (
        [
          (TimeAxis(min: _start), 'time'),
          (TimeSeriesAxis(min: _start), 'timeseries'),
        ],
        {'min': _start},
      ),
      'max of a time axis': (
        [
          (TimeAxis(max: _end), 'time'),
          (TimeSeriesAxis(max: _end), 'timeseries'),
        ],
        {'max': _end},
      ),
      'unit': (
        const [
          (TimeAxis(unit: .day), 'time'),
          (TimeSeriesAxis(unit: .day), 'timeseries'),
        ],
        {
          'time': {'unit': 'day'},
        },
      ),
      'unit, a custom name': (
        const [
          (TimeAxis(unit: TimeUnit('fortnight')), 'time'),
          (TimeSeriesAxis(unit: TimeUnit('fortnight')), 'timeseries'),
        ],
        {
          'time': {'unit': 'fortnight'},
        },
      ),
      'tooltipFormat': (
        const [
          (TimeAxis(tooltipFormat: 'yyyy'), 'time'),
          (TimeSeriesAxis(tooltipFormat: 'yyyy'), 'timeseries'),
        ],
        {
          'time': {'tooltipFormat': 'yyyy'},
        },
      ),
      'startAngle': (
        const [(RadialLinearAxis(startAngle: 45), 'radialLinear')],
        {'startAngle': 45},
      ),
      'pointLabelsDisplay': (
        const [(RadialLinearAxis(pointLabelsDisplay: false), 'radialLinear')],
        {
          'pointLabels': {'display': false},
        },
      ),
      'pointLabelsFont': (
        const [(RadialLinearAxis(pointLabelsFont: _font), 'radialLinear')],
        {
          'pointLabels': {'font': _fontValue},
        },
      ),
      'pointLabelsColor': (
        const [(RadialLinearAxis(pointLabelsColor: _blue), 'radialLinear')],
        {
          'pointLabels': {'color': _blueValue},
        },
      ),
      'pointLabelsPadding': (
        const [(RadialLinearAxis(pointLabelsPadding: 8), 'radialLinear')],
        {
          'pointLabels': {'padding': 8},
        },
      ),
      'angleLinesDisplay': (
        const [(RadialLinearAxis(angleLinesDisplay: false), 'radialLinear')],
        {
          'angleLines': {'display': false},
        },
      ),
      'angleLinesColor': (
        const [(RadialLinearAxis(angleLinesColor: _red), 'radialLinear')],
        {
          'angleLines': {'color': _redValue},
        },
      ),
      'angleLinesLineWidth': (
        const [(RadialLinearAxis(angleLinesLineWidth: 2), 'radialLinear')],
        {
          'angleLines': {'lineWidth': 2},
        },
      ),
    };

/// The cases of the parameters of [AxisTicks] and the twin `ticks` Map.
const Map<String, (AxisTicks, Map<String, Object?>)> _ticks = {
  'display': (AxisTicks(display: false), {'display': false}),
  'color': (AxisTicks(color: _red), {'color': _redValue}),
  'font': (AxisTicks(font: _font), {'font': _fontValue}),
  'padding': (AxisTicks(padding: 6), {'padding': 6}),
  'stepSize': (AxisTicks(stepSize: 5), {'stepSize': 5}),
  'maxRotation': (AxisTicks(maxRotation: 0), {'maxRotation': 0}),
  'autoSkip': (AxisTicks(autoSkip: false), {'autoSkip': false}),
  'extra': (AxisTicks(extra: {'precision': 0}), {'precision': 0}),
};

/// The cases of the parameters of [AxisGrid] and the twin `grid` Map.
const Map<String, (AxisGrid, Map<String, Object?>)> _grid = {
  'display': (AxisGrid(display: false), {'display': false}),
  'color': (AxisGrid(color: _blue), {'color': _blueValue}),
  'lineWidth': (AxisGrid(lineWidth: 2), {'lineWidth': 2}),
  'drawOnChartArea': (
    AxisGrid(drawOnChartArea: false),
    {'drawOnChartArea': false},
  ),
  'drawTicks': (AxisGrid(drawTicks: false), {'drawTicks': false}),
  'offset': (AxisGrid(offset: true), {'offset': true}),
  'extra': (AxisGrid(extra: {'tickLength': 4}), {'tickLength': 4}),
};

/// The cases of the parameters of [AxisTitle] and the twin `title` Map.
const Map<String, (AxisTitle, Map<String, Object?>)> _axisTitle = {
  'display': (AxisTitle(display: true), {'display': true}),
  'text': (AxisTitle(text: 'Month'), {'text': 'Month'}),
  'color': (AxisTitle(color: _red), {'color': _redValue}),
  'font': (AxisTitle(font: _font), {'font': _fontValue}),
  'align': (AxisTitle(align: .end), {'align': 'end'}),
  'padding': (
    AxisTitle(padding: EdgeInsets.symmetric(vertical: 4)),
    {
      'padding': {'top': 4, 'right': 0, 'bottom': 4, 'left': 0},
    },
  ),
  'extra': (AxisTitle(extra: {'strokeWidth': 1}), {'strokeWidth': 1}),
};

/// The cases of the parameters of [ChartFiller] and the twin `filler` Map.
const Map<String, (ChartFiller, Map<String, Object?>)> _filler = {
  'propagate': (ChartFiller(propagate: false), {'propagate': false}),
  'extra': (
    ChartFiller(extra: {'drawTime': 'beforeDraw'}),
    {'drawTime': 'beforeDraw'},
  ),
};

/// The cases of the parameters of [ChartElements] and of the element
/// styles, with the twin `elements` Map.
const Map<String, (ChartElements, Map<String, Object?>)> _elements = {
  'point.radius': (
    ChartElements(point: PointElementStyle(radius: 0)),
    {
      'point': {'radius': 0},
    },
  ),
  'point.pointStyle': (
    ChartElements(point: PointElementStyle(pointStyle: .rect)),
    {
      'point': {'pointStyle': 'rect'},
    },
  ),
  'point.backgroundColor': (
    ChartElements(point: PointElementStyle(backgroundColor: _red)),
    {
      'point': {'backgroundColor': _redValue},
    },
  ),
  'point.borderColor': (
    ChartElements(point: PointElementStyle(borderColor: _blue)),
    {
      'point': {'borderColor': _blueValue},
    },
  ),
  'point.borderWidth': (
    ChartElements(point: PointElementStyle(borderWidth: 2)),
    {
      'point': {'borderWidth': 2},
    },
  ),
  'point.hitRadius': (
    ChartElements(point: PointElementStyle(hitRadius: 5)),
    {
      'point': {'hitRadius': 5},
    },
  ),
  'point.hoverRadius': (
    ChartElements(point: PointElementStyle(hoverRadius: 6)),
    {
      'point': {'hoverRadius': 6},
    },
  ),
  'point.extra': (
    ChartElements(point: PointElementStyle(extra: {'rotation': 45})),
    {
      'point': {'rotation': 45},
    },
  ),
  'line.tension': (
    ChartElements(line: LineElementStyle(tension: 0.4)),
    {
      'line': {'tension': 0.4},
    },
  ),
  'line.backgroundColor': (
    ChartElements(line: LineElementStyle(backgroundColor: _red)),
    {
      'line': {'backgroundColor': _redValue},
    },
  ),
  'line.borderColor': (
    ChartElements(line: LineElementStyle(borderColor: _blue)),
    {
      'line': {'borderColor': _blueValue},
    },
  ),
  'line.borderWidth, the radar docs': (
    ChartElements(line: LineElementStyle(borderWidth: 3)),
    {
      'line': {'borderWidth': 3},
    },
  ),
  'line.borderDash': (
    ChartElements(line: LineElementStyle(borderDash: [4, 2])),
    {
      'line': {
        'borderDash': [4, 2],
      },
    },
  ),
  'line.fill': (
    ChartElements(line: LineElementStyle(fill: .origin)),
    {
      'line': {'fill': 'origin'},
    },
  ),
  'line.stepped': (
    ChartElements(line: LineElementStyle(stepped: true)),
    {
      'line': {'stepped': true},
    },
  ),
  'line.extra': (
    ChartElements(
      line: LineElementStyle(extra: {'cubicInterpolationMode': 'monotone'}),
    ),
    {
      'line': {'cubicInterpolationMode': 'monotone'},
    },
  ),
  'bar.backgroundColor': (
    ChartElements(bar: BarElementStyle(backgroundColor: _red)),
    {
      'bar': {'backgroundColor': _redValue},
    },
  ),
  'bar.borderColor': (
    ChartElements(bar: BarElementStyle(borderColor: _blue)),
    {
      'bar': {'borderColor': _blueValue},
    },
  ),
  'bar.borderWidth': (
    ChartElements(bar: BarElementStyle(borderWidth: 2)),
    {
      'bar': {'borderWidth': 2},
    },
  ),
  'bar.borderRadius': (
    ChartElements(bar: BarElementStyle(borderRadius: 4)),
    {
      'bar': {'borderRadius': 4},
    },
  ),
  'bar.extra': (
    ChartElements(bar: BarElementStyle(extra: {'borderSkipped': false})),
    {
      'bar': {'borderSkipped': false},
    },
  ),
  'arc.backgroundColor': (
    ChartElements(arc: ArcElementStyle(backgroundColor: _red)),
    {
      'arc': {'backgroundColor': _redValue},
    },
  ),
  'arc.borderColor': (
    ChartElements(arc: ArcElementStyle(borderColor: _blue)),
    {
      'arc': {'borderColor': _blueValue},
    },
  ),
  'arc.borderWidth': (
    ChartElements(arc: ArcElementStyle(borderWidth: 0)),
    {
      'arc': {'borderWidth': 0},
    },
  ),
  'arc.offset': (
    ChartElements(arc: ArcElementStyle(offset: 4)),
    {
      'arc': {'offset': 4},
    },
  ),
  'arc.spacing': (
    ChartElements(arc: ArcElementStyle(spacing: 2)),
    {
      'arc': {'spacing': 2},
    },
  ),
  'arc.extra': (
    ChartElements(arc: ArcElementStyle(extra: {'borderAlign': 'inner'})),
    {
      'arc': {'borderAlign': 'inner'},
    },
  ),
  'extra': (
    ChartElements(
      extra: {
        'line': {'borderWidth': 1},
      },
    ),
    {
      'line': {'borderWidth': 1},
    },
  ),
  'the four styles, in parameter order': (
    ChartElements(
      arc: ArcElementStyle(offset: 1),
      bar: BarElementStyle(borderWidth: 1),
      line: LineElementStyle(tension: 1),
      point: PointElementStyle(radius: 1),
    ),
    {
      'point': {'radius': 1},
      'line': {'tension': 1},
      'bar': {'borderWidth': 1},
      'arc': {'offset': 1},
    },
  ),
};

/// The cases of the parameters of [ChartLegend] and the twin `legend` Map.
const Map<String, (ChartLegend, Map<String, Object?>)> _legend = {
  'display': (ChartLegend(display: false), {'display': false}),
  'position': (ChartLegend(position: .chartArea), {'position': 'chartArea'}),
  'align': (ChartLegend(align: .start), {'align': 'start'}),
  'reverse': (ChartLegend(reverse: true), {'reverse': true}),
  'labelColor': (
    ChartLegend(labelColor: _red),
    {
      'labels': {'color': _redValue},
    },
  ),
  'labelFont': (
    ChartLegend(labelFont: _font),
    {
      'labels': {'font': _fontValue},
    },
  ),
  'boxWidth': (
    ChartLegend(boxWidth: 12),
    {
      'labels': {'boxWidth': 12},
    },
  ),
  'boxHeight': (
    ChartLegend(boxHeight: 6),
    {
      'labels': {'boxHeight': 6},
    },
  ),
  'labelPadding': (
    ChartLegend(labelPadding: 3),
    {
      'labels': {'padding': 3},
    },
  ),
  'usePointStyle': (
    ChartLegend(usePointStyle: true),
    {
      'labels': {'usePointStyle': true},
    },
  ),
  'onClick': (ChartLegend(onClick: _onLegend), {'onClick': _function}),
  'onHover': (ChartLegend(onHover: _onLegend), {'onHover': _function}),
  'onLeave': (ChartLegend(onLeave: _onLegend), {'onLeave': _function}),
  'extra': (ChartLegend(extra: {'maxHeight': 50}), {'maxHeight': 50}),
};

/// The cases of the parameters of [ChartTitle] and the twin Map.
const Map<String, (ChartTitle, Map<String, Object?>)> _title = {
  'display': (ChartTitle(display: true), {'display': true}),
  'text': (ChartTitle(text: 'Votes'), {'text': 'Votes'}),
  'color': (ChartTitle(color: _blue), {'color': _blueValue}),
  'font': (ChartTitle(font: _font), {'font': _fontValue}),
  'align': (ChartTitle(align: .start), {'align': 'start'}),
  'position': (ChartTitle(position: .bottom), {'position': 'bottom'}),
  'padding': (
    ChartTitle(padding: EdgeInsets.only(top: 10, bottom: 30)),
    {
      'padding': {'top': 10, 'right': 0, 'bottom': 30, 'left': 0},
    },
  ),
  'fullSize': (ChartTitle(fullSize: false), {'fullSize': false}),
  'extra': (
    ChartTitle(
      extra: {
        'text': ['A', 'B'],
      },
    ),
    {
      'text': ['A', 'B'],
    },
  ),
};

/// The cases of the parameters of [ChartTooltip] and the twin Map.
const Map<String, (ChartTooltip, Map<String, Object?>)> _tooltip = {
  'enabled': (ChartTooltip(enabled: false), {'enabled': false}),
  'mode': (ChartTooltip(mode: .index), {'mode': 'index'}),
  'intersect': (ChartTooltip(intersect: false), {'intersect': false}),
  'backgroundColor': (
    ChartTooltip(backgroundColor: _red),
    {'backgroundColor': _redValue},
  ),
  'titleColor': (ChartTooltip(titleColor: _red), {'titleColor': _redValue}),
  'titleFont': (ChartTooltip(titleFont: _font), {'titleFont': _fontValue}),
  'bodyColor': (ChartTooltip(bodyColor: _blue), {'bodyColor': _blueValue}),
  'bodyFont': (ChartTooltip(bodyFont: _font), {'bodyFont': _fontValue}),
  'footerColor': (
    ChartTooltip(footerColor: _blue),
    {'footerColor': _blueValue},
  ),
  'footerFont': (ChartTooltip(footerFont: _font), {'footerFont': _fontValue}),
  'padding': (
    ChartTooltip(padding: EdgeInsets.all(10)),
    {
      'padding': {'top': 10, 'right': 10, 'bottom': 10, 'left': 10},
    },
  ),
  'cornerRadius': (ChartTooltip(cornerRadius: 0), {'cornerRadius': 0}),
  'displayColors': (
    ChartTooltip(displayColors: false),
    {'displayColors': false},
  ),
  'titleText': (
    ChartTooltip(titleText: _title2),
    {
      'callbacks': {'title': _function},
    },
  ),
  'labelText': (
    ChartTooltip(labelText: _label),
    {
      'callbacks': {'label': _function},
    },
  ),
  'footerText': (
    ChartTooltip(footerText: _title2),
    {
      'callbacks': {'footer': _function},
    },
  ),
  'extra': (
    ChartTooltip(extra: {'position': 'nearest'}),
    {'position': 'nearest'},
  ),
};

/// The cases of the parameters of [ChartInteraction] and the twin Map.
const Map<String, (ChartInteraction, Map<String, Object?>)> _interaction = {
  'mode': (ChartInteraction(mode: .x), {'mode': 'x'}),
  'mode, a custom mode': (
    ChartInteraction(mode: ChartInteractionMode('myMode')),
    {'mode': 'myMode'},
  ),
  'intersect': (ChartInteraction(intersect: false), {'intersect': false}),
  'includeInvisible': (
    ChartInteraction(includeInvisible: true),
    {'includeInvisible': true},
  ),
  'extra': (ChartInteraction(extra: {'axis': 'xy'}), {'axis': 'xy'}),
};

/// The cases of the parameters of [ChartAnimation] and the twin value.
const Map<String, (ChartAnimation, Object)> _animation = {
  'none': (ChartAnimation.none, false),
  'duration': (
    ChartAnimation(duration: Duration(milliseconds: 400)),
    {'duration': 400},
  ),
  'duration, a fraction of a millisecond': (
    ChartAnimation(duration: Duration(microseconds: 1500)),
    {'duration': 1.5},
  ),
  'delay': (ChartAnimation(delay: Duration(seconds: 1)), {'delay': 1000}),
  'easing': (
    ChartAnimation(easing: .easeInOutBack),
    {'easing': 'easeInOutBack'},
  ),
  'loop': (ChartAnimation(loop: true), {'loop': true}),
  'onProgress': (
    ChartAnimation(onProgress: _onAnimation),
    {'onProgress': _function},
  ),
  'onComplete': (
    ChartAnimation(onComplete: _onAnimation),
    {'onComplete': _function},
  ),
  'extra': (
    ChartAnimation(extra: {'animateScale': true}),
    {'animateScale': true},
  ),
};

/// The cases of the option parameters of [ChartConfig] and the twin
/// options Map.
const Map<String, (ChartConfig, Map<String, Object?>)> _config = {
  'scales': (
    ChartConfig(
      type: .bar,
      datasets: [],
      scales: {'y': LinearAxis(beginAtZero: true)},
    ),
    {
      'scales': {
        'y': {'type': 'linear', 'beginAtZero': true},
      },
    },
  ),
  'indexAxis': (
    ChartConfig(type: .bar, datasets: [], indexAxis: .y),
    {'indexAxis': 'y'},
  ),
  'responsive': (
    ChartConfig(type: .bar, datasets: [], responsive: false),
    {'responsive': false},
  ),
  'maintainAspectRatio': (
    ChartConfig(type: .bar, datasets: [], maintainAspectRatio: false),
    {'maintainAspectRatio': false},
  ),
  'aspectRatio': (
    ChartConfig(type: .bar, datasets: [], aspectRatio: 1.5),
    {'aspectRatio': 1.5},
  ),
  'padding': (
    ChartConfig(type: .bar, datasets: [], padding: EdgeInsets.all(20)),
    {
      'layout': {
        'padding': {'top': 20, 'right': 20, 'bottom': 20, 'left': 20},
      },
    },
  ),
  'legend': (
    ChartConfig(type: .bar, datasets: [], legend: ChartLegend()),
    {
      'plugins': {'legend': <String, Object?>{}},
    },
  ),
  'title': (
    ChartConfig(type: .bar, datasets: [], title: ChartTitle()),
    {
      'plugins': {'title': <String, Object?>{}},
    },
  ),
  'subtitle': (
    ChartConfig(type: .bar, datasets: [], subtitle: ChartTitle()),
    {
      'plugins': {'subtitle': <String, Object?>{}},
    },
  ),
  'tooltip': (
    ChartConfig(type: .bar, datasets: [], tooltip: ChartTooltip()),
    {
      'plugins': {'tooltip': <String, Object?>{}},
    },
  ),
  'filler': (
    ChartConfig(type: .bar, datasets: [], filler: ChartFiller()),
    {
      'plugins': {'filler': <String, Object?>{}},
    },
  ),
  'interaction': (
    ChartConfig(type: .bar, datasets: [], interaction: ChartInteraction()),
    {'interaction': <String, Object?>{}},
  ),
  'animation': (
    ChartConfig(type: .bar, datasets: [], animation: ChartAnimation()),
    {'animation': <String, Object?>{}},
  ),
  'elements': (
    ChartConfig(type: .bar, datasets: [], elements: ChartElements()),
    {'elements': <String, Object?>{}},
  ),
  'onClick': (
    ChartConfig(type: .bar, datasets: [], onClick: _onEvent),
    {'onClick': _function},
  ),
  'onHover': (
    ChartConfig(type: .bar, datasets: [], onHover: _onEvent),
    {'onHover': _function},
  ),
  'extra': (
    ChartConfig(type: .bar, datasets: [], extra: {'locale': 'de-DE'}),
    {'locale': 'de-DE'},
  ),
  'all options, in parameter order': (
    ChartConfig(
      type: .bar,
      datasets: [],
      scales: {'x': CategoryAxis()},
      indexAxis: .x,
      responsive: true,
      maintainAspectRatio: true,
      aspectRatio: 2,
      padding: EdgeInsets.all(1),
      legend: ChartLegend(display: true),
      title: ChartTitle(display: true),
      subtitle: ChartTitle(display: false),
      tooltip: ChartTooltip(enabled: true),
      interaction: ChartInteraction(intersect: true),
      animation: ChartAnimation.none,
      onClick: _onEvent,
      onHover: _onEvent,
      extra: {'locale': 'en-US'},
    ),
    {
      'scales': {
        'x': {'type': 'category'},
      },
      'indexAxis': 'x',
      'responsive': true,
      'maintainAspectRatio': true,
      'aspectRatio': 2,
      'layout': {
        'padding': {'top': 1, 'right': 1, 'bottom': 1, 'left': 1},
      },
      'plugins': {
        'legend': {'display': true},
        'title': {'display': true},
        'subtitle': {'display': false},
        'tooltip': {'enabled': true},
      },
      'interaction': {'intersect': true},
      'animation': false,
      'onClick': _function,
      'onHover': _function,
      'locale': 'en-US',
    },
  ),
};

void main() {
  group('the datasets', () {
    group('each parameter of Dataset, in each dataset class', () {
      for (final MapEntry(key: name, value: (set, twin)) in _common.entries) {
        test(name, () {
          for (final dataset in _empty.values) {
            expectTwin(_lower(set(dataset)), twin);
          }
        });
      }
    });

    test('a scriptable color gives the rgba() string of each context', () {
      for (final dataset in _empty.values) {
        final lowered = _lower(
          dataset.copyWith(
            backgroundColorFor: _colorFor,
            borderColorFor: _colorFor,
          ),
        );
        for (final key in ['backgroundColor', 'borderColor']) {
          final script = lowered[key];
          // The 2 arguments of a scriptable option: the context and the
          // options resolver. The context is a typed data context of
          // `createContext`, as the chart gives (Chart.js ADR 0054 §11).
          expect(script, isA<Object? Function(Object?, Object?)>());
          final values = [
            for (final index in [0.0, 1.0, 2.0])
              jsCall(script, [
                createContext(null, <String, Object?>{
                  'type': 'data',
                  'dataIndex': index,
                }),
                undefined,
              ]),
          ];
          expect(values, [_redValue, _blueValue, _redValue], reason: key);
        }
      }
    });

    group('each parameter of the dataset classes', () {
      for (final MapEntry(key: name, value: (datasets, twin)) in _own.entries) {
        test(name, () {
          for (final dataset in datasets) {
            expectTwin(_lower(dataset), twin);
          }
        });
      }
    });

    test('data goes by reference', () {
      final data = <num?>[1, null, 3];
      final datasets = <Dataset>[
        BarDataset(data: data),
        LineDataset(data: data),
        ScatterDataset(data: data),
        PieDataset(data: data),
        DoughnutDataset(data: data),
        PolarAreaDataset(data: data),
        RadarDataset(data: data),
      ];
      for (final dataset in datasets) {
        final lowered = _lower(dataset);
        expectTwin(lowered, {'data': data});
        expect(lowered['data'], same(data));
      }
    });

    test('points go by reference, under the key data', () {
      final points = [DataPoint(1, 2), DataPoint.bubble(3, 4, 5)];
      final datasets = <Dataset>[
        BarDataset(points: points),
        LineDataset(points: points),
        ScatterDataset(points: points),
        BubbleDataset(points: points),
      ];
      for (final dataset in datasets) {
        final lowered = _lower(dataset);
        expect(lowered.jsKeys(), ['data']);
        expect(lowered['data'], same(points));
      }
    });

    test('a style List lowers to a new List', () {
      final dash = [4.0, 2.0];
      final colors = [_red];
      final lowered = _lower(
        LineDataset(borderDash: dash, backgroundColors: colors),
      );
      expect(lowered['borderDash'], isNot(same(dash)));
      expect(lowered['borderDash'], isA<List<Object?>>());
      (lowered['borderDash']! as List<Object?>).add('x');
      expect(dash, [4, 2]);
      expect(lowered['backgroundColor'], [_redValue]);
    });

    group('the dataset type', () {
      for (final MapEntry(key: kind, value: dataset) in _empty.entries) {
        test('${kind.name}: no type in a chart of its type, the type first '
            'in another chart', () {
          final labeled = dataset.copyWith(label: 'A');
          expectTwin(lowerDataset(labeled, kind), {'label': 'A'});
          final other = kind == ChartKind.bar ? ChartKind.line : ChartKind.bar;
          expectTwin(lowerDataset(labeled, other), {
            'type': kind.name,
            'label': 'A',
          });
          expectTwin(lowerDataset(labeled, const ChartKind('custom')), {
            'type': kind.name,
            'label': 'A',
          });
        });
      }

      test('a doughnut dataset in a pie chart keeps its type', () {
        expectTwin(lowerDataset(const DoughnutDataset(), .pie), {
          'type': 'doughnut',
        });
        expectTwin(lowerDataset(const PieDataset(), .doughnut), {
          'type': 'pie',
        });
      });
    });

    group('extra', () {
      test('a key of a nested Map that is not a String fails the debug '
          'assert with the key', () {
        expect(
          () => _lower(
            const BarDataset(
              extra: {
                'datalabels': {1: 'one'},
              },
            ),
          ),
          throwsA(
            isA<AssertionError>().having(
              (error) => '${error.message}',
              'message',
              allOf(
                contains('The key 1 of an extra Map is a int, not a String.'),
                contains("write the key as '1'"),
              ),
            ),
          ),
        );
      });

      test('an entry wins over a parameter, in the place of the key', () {
        expectTwin(
          _lower(
            const BarDataset(
              label: 'A',
              borderWidth: 2,
              extra: {'borderWidth': 3, 'clip': 5},
            ),
          ),
          {'label': 'A', 'borderWidth': 3, 'clip': 5},
        );
      });

      test('a CSS string wins over a color', () {
        expectTwin(
          _lower(
            const LineDataset(
              backgroundColor: _red,
              extra: {'backgroundColor': 'red'},
            ),
          ),
          {'backgroundColor': 'red'},
        );
      });

      test('a Map merges into the Map of the key', () {
        expectTwin(
          _lower(
            const LineDataset(
              fill: .value(25),
              extra: {
                'fill': {'above': 'red'},
              },
            ),
          ),
          {
            'fill': {'value': 25, 'above': 'red'},
          },
        );
      });

      test('a Map replaces a value that is not a Map', () {
        expectTwin(
          _lower(
            const BarDataset(
              borderRadius: 4,
              extra: {
                'borderRadius': {'topLeft': 8},
              },
            ),
          ),
          {
            'borderRadius': {'topLeft': 8},
          },
        );
      });

      test('a const Map lowers to new Maps', () {
        const options = {
          'datalabels': {
            'font': {'size': 9},
          },
        };
        final lowered = _lower(const BarDataset(extra: options));
        expectTwin(lowered, {
          'datalabels': {
            'font': {'size': 9},
          },
        });
        expect(lowered['datalabels'], isNot(same(options['datalabels'])));
      });

      test('a List and a function go by reference', () {
        final segment = <String, Object?>{'borderColor': (Object? c) => 'red'};
        final list = <Object?>[1, 2];
        final lowered = _lower(
          LineDataset(extra: {'segment': segment, 'tags': list}),
        );
        expect(lowered['tags'], same(list));
        final copy = lowered['segment']!;
        expect(copy, isNot(same(segment)));
        expect(jsGet(copy, 'borderColor'), same(segment['borderColor']));
      });

      test('an entry with the value null gives the JS null', () {
        expectTwin(_lower(const LineDataset(extra: {'clip': null})), {
          'clip': null,
        });
      });
    });

    group('all parameters, in parameter order', () {
      final data = <num?>[1, 2];
      final points = [DataPoint(1, 2)];

      test('BarDataset', () {
        final lowered = _lower(
          BarDataset(
            key: const ValueKey('a'),
            label: 'A',
            data: data,
            hidden: false,
            order: 1,
            backgroundColor: _red,
            borderColor: _blue,
            borderWidth: 2,
            hoverBackgroundColor: _blue,
            hoverBorderColor: _red,
            hoverBorderWidth: 3,
            xAxisID: 'x2',
            yAxisID: 'y2',
            stack: 's',
            indexAxis: .y,
            borderRadius: 4,
            barPercentage: 0.5,
            categoryPercentage: 0.6,
            barThickness: 10,
            maxBarThickness: 12,
            minBarLength: 2,
            grouped: false,
            extra: const {'clip': 5},
          ),
        );
        expectTwin(lowered, {
          'label': 'A',
          'data': data,
          'hidden': false,
          'order': 1,
          'backgroundColor': _redValue,
          'borderColor': _blueValue,
          'borderWidth': 2,
          'hoverBackgroundColor': _blueValue,
          'hoverBorderColor': _redValue,
          'hoverBorderWidth': 3,
          'xAxisID': 'x2',
          'yAxisID': 'y2',
          'stack': 's',
          'indexAxis': 'y',
          'borderRadius': 4,
          'barPercentage': 0.5,
          'categoryPercentage': 0.6,
          'barThickness': 10,
          'maxBarThickness': 12,
          'minBarLength': 2,
          'grouped': false,
          'clip': 5,
        });
      });

      /// The twin keys of the line style parameters of the cases below.
      const lineStyleTwin = <String, Object?>{
        'fill': 'origin',
        'tension': 0.4,
        'borderDash': [5, 5],
        'spanGaps': true,
        'showLine': true,
        'stepped': false,
        'pointRadius': 3,
        'pointHoverRadius': 6,
        'pointStyle': 'star',
        'pointBackgroundColor': _redValue,
        'pointBorderColor': _blueValue,
        'pointBorderWidth': 1,
        'pointHoverBackgroundColor': _blueValue,
        'pointHoverBorderColor': _redValue,
      };

      test('LineDataset', () {
        final lowered = _lower(
          LineDataset(
            label: 'A',
            points: points,
            hidden: true,
            order: 2,
            backgroundColors: const [_red],
            borderColorFor: _colorFor,
            borderWidth: 2,
            hoverBackgroundColor: _blue,
            hoverBorderColor: _red,
            hoverBorderWidth: 3,
            xAxisID: 'x2',
            yAxisID: 'y2',
            stack: 's',
            indexAxis: .x,
            fill: .origin,
            tension: 0.4,
            borderDash: const [5, 5],
            spanGaps: true,
            showLine: true,
            stepped: false,
            pointRadius: 3,
            pointHoverRadius: 6,
            pointStyle: .star,
            pointBackgroundColor: _red,
            pointBorderColor: _blue,
            pointBorderWidth: 1,
            pointHoverBackgroundColor: _blue,
            pointHoverBorderColor: _red,
            extra: const {'clip': 5},
          ),
        );
        expectTwin(lowered, {
          'label': 'A',
          'data': points,
          'hidden': true,
          'order': 2,
          'backgroundColor': [_redValue],
          'borderColor': (Object? context, Object? options) => _redValue,
          'borderWidth': 2,
          'hoverBackgroundColor': _blueValue,
          'hoverBorderColor': _redValue,
          'hoverBorderWidth': 3,
          'xAxisID': 'x2',
          'yAxisID': 'y2',
          'stack': 's',
          'indexAxis': 'x',
          ...lineStyleTwin,
          'clip': 5,
        });
      });

      test('ScatterDataset', () {
        final lowered = _lower(
          ScatterDataset(
            label: 'A',
            points: points,
            hidden: true,
            order: 2,
            backgroundColor: _red,
            borderColor: _blue,
            borderWidth: 2,
            hoverBackgroundColor: _blue,
            hoverBorderColor: _red,
            hoverBorderWidth: 3,
            xAxisID: 'x2',
            yAxisID: 'y2',
            stack: 's',
            fill: .origin,
            tension: 0.4,
            borderDash: const [5, 5],
            spanGaps: true,
            showLine: true,
            stepped: false,
            pointRadius: 3,
            pointHoverRadius: 6,
            pointStyle: .star,
            pointBackgroundColor: _red,
            pointBorderColor: _blue,
            pointBorderWidth: 1,
            pointHoverBackgroundColor: _blue,
            pointHoverBorderColor: _red,
            extra: const {'clip': 5},
          ),
        );
        expectTwin(lowered, {
          'label': 'A',
          'data': points,
          'hidden': true,
          'order': 2,
          'backgroundColor': _redValue,
          'borderColor': _blueValue,
          'borderWidth': 2,
          'hoverBackgroundColor': _blueValue,
          'hoverBorderColor': _redValue,
          'hoverBorderWidth': 3,
          'xAxisID': 'x2',
          'yAxisID': 'y2',
          'stack': 's',
          ...lineStyleTwin,
          'clip': 5,
        });
      });

      test('BubbleDataset', () {
        final bubbles = [DataPoint.bubble(1, 2, 3)];
        final lowered = _lower(
          BubbleDataset(
            label: 'A',
            points: bubbles,
            hidden: false,
            order: 1,
            backgroundColor: _red,
            borderColor: _blue,
            borderWidth: 2,
            hoverBackgroundColor: _blue,
            hoverBorderColor: _red,
            hoverBorderWidth: 3,
            xAxisID: 'x2',
            yAxisID: 'y2',
            radius: 7,
            hoverRadius: 2,
            pointStyle: .triangle,
            extra: const {'clip': 5},
          ),
        );
        expectTwin(lowered, {
          'label': 'A',
          'data': bubbles,
          'hidden': false,
          'order': 1,
          'backgroundColor': _redValue,
          'borderColor': _blueValue,
          'borderWidth': 2,
          'hoverBackgroundColor': _blueValue,
          'hoverBorderColor': _redValue,
          'hoverBorderWidth': 3,
          'xAxisID': 'x2',
          'yAxisID': 'y2',
          'radius': 7,
          'hoverRadius': 2,
          'pointStyle': 'triangle',
          'clip': 5,
        });
      });

      final arcTwin = <String, Object?>{
        'label': 'A',
        'data': data,
        'hidden': false,
        'order': 1,
        'backgroundColor': [_redValue, _blueValue],
        'borderColor': _blueValue,
        'borderWidth': 2,
        'hoverBackgroundColor': _blueValue,
        'hoverBorderColor': _redValue,
        'hoverBorderWidth': 3,
        'offset': 4,
        'hoverOffset': 8,
        'spacing': 2,
        'weight': 2,
        'circumference': 180,
        'rotation': -90,
        'cutout': '60%',
        'radius': 120,
        'clip': 5,
      };

      test('PieDataset', () {
        final lowered = _lower(
          PieDataset(
            label: 'A',
            data: data,
            hidden: false,
            order: 1,
            backgroundColors: const [_red, _blue],
            borderColor: _blue,
            borderWidth: 2,
            hoverBackgroundColor: _blue,
            hoverBorderColor: _red,
            hoverBorderWidth: 3,
            offset: 4,
            hoverOffset: 8,
            spacing: 2,
            weight: 2,
            circumference: 180,
            rotation: -90,
            cutout: const .percent(60),
            radius: const .pixels(120),
            extra: const {'clip': 5},
          ),
        );
        expectTwin(lowered, arcTwin);
      });

      test('DoughnutDataset', () {
        final lowered = _lower(
          DoughnutDataset(
            label: 'A',
            data: data,
            hidden: false,
            order: 1,
            backgroundColors: const [_red, _blue],
            borderColor: _blue,
            borderWidth: 2,
            hoverBackgroundColor: _blue,
            hoverBorderColor: _red,
            hoverBorderWidth: 3,
            offset: 4,
            hoverOffset: 8,
            spacing: 2,
            weight: 2,
            circumference: 180,
            rotation: -90,
            cutout: const .percent(60),
            radius: const .pixels(120),
            extra: const {'clip': 5},
          ),
        );
        expectTwin(lowered, arcTwin);
      });

      test('PolarAreaDataset', () {
        final lowered = _lower(
          PolarAreaDataset(
            label: 'A',
            data: data,
            hidden: false,
            order: 1,
            backgroundColor: _red,
            borderColor: _blue,
            borderWidth: 2,
            hoverBackgroundColor: _blue,
            hoverBorderColor: _red,
            hoverBorderWidth: 3,
            offset: 4,
            hoverOffset: 8,
            spacing: 2,
            extra: const {'clip': 5},
          ),
        );
        expectTwin(lowered, {
          'label': 'A',
          'data': data,
          'hidden': false,
          'order': 1,
          'backgroundColor': _redValue,
          'borderColor': _blueValue,
          'borderWidth': 2,
          'hoverBackgroundColor': _blueValue,
          'hoverBorderColor': _redValue,
          'hoverBorderWidth': 3,
          'offset': 4,
          'hoverOffset': 8,
          'spacing': 2,
          'clip': 5,
        });
      });

      test('RadarDataset', () {
        final lowered = _lower(
          RadarDataset(
            label: 'A',
            data: data,
            hidden: true,
            order: 2,
            backgroundColor: _red,
            borderColor: _blue,
            borderWidth: 2,
            hoverBackgroundColor: _blue,
            hoverBorderColor: _red,
            hoverBorderWidth: 3,
            fill: .origin,
            tension: 0.4,
            borderDash: const [5, 5],
            spanGaps: true,
            showLine: true,
            stepped: false,
            pointRadius: 3,
            pointHoverRadius: 6,
            pointStyle: .star,
            pointBackgroundColor: _red,
            pointBorderColor: _blue,
            pointBorderWidth: 1,
            pointHoverBackgroundColor: _blue,
            pointHoverBorderColor: _red,
            extra: const {'clip': 5},
          ),
        );
        expectTwin(lowered, {
          'label': 'A',
          'data': data,
          'hidden': true,
          'order': 2,
          'backgroundColor': _redValue,
          'borderColor': _blueValue,
          'borderWidth': 2,
          'hoverBackgroundColor': _blueValue,
          'hoverBorderColor': _redValue,
          'hoverBorderWidth': 3,
          ...lineStyleTwin,
          'clip': 5,
        });
      });
    });
  });

  group('the axes', () {
    group('each parameter of ChartAxis, in each axis class', () {
      for (final MapEntry(key: name, value: (set, twin))
          in _axisCommon.entries) {
        test(name, () {
          for (final (axis, type) in _axes) {
            expectTwin(lowerAxis(set(axis)), {'type': type, ...twin});
          }
        });
      }
    });

    group('each parameter of the axis classes', () {
      for (final MapEntry(key: name, value: (axes, twin)) in _axisOwn.entries) {
        test(name, () {
          for (final (axis, type) in axes) {
            expectTwin(lowerAxis(axis), {'type': type, ...twin});
          }
        });
      }
    });

    test('the labels of a category axis go by reference', () {
      final labels = <Object>['a', 'b'];
      final lowered = lowerAxis(CategoryAxis(labels: labels));
      expectTwin(lowered, {'type': 'category', 'labels': labels});
      expect(lowered['labels'], same(labels));
    });

    group('each parameter of AxisTicks', () {
      for (final MapEntry(key: name, value: (ticks, twin)) in _ticks.entries) {
        test(name, () {
          expectTwin(lowerAxis(LinearAxis(ticks: ticks)), {
            'type': 'linear',
            'ticks': twin,
          });
        });
      }

      test('format, a JsFunction', () {
        final lowered = lowerAxis(
          const LinearAxis(ticks: AxisTicks(format: _format)),
        );
        final ticks = lowered['ticks']!;
        expect(jsObjectKeys(ticks), ['callback']);
        expect(jsGet(ticks, 'callback'), isA<JsFunction>());
      });
    });

    group('each parameter of AxisGrid', () {
      for (final MapEntry(key: name, value: (grid, twin)) in _grid.entries) {
        test(name, () {
          expectTwin(lowerAxis(LinearAxis(grid: grid)), {
            'type': 'linear',
            'grid': twin,
          });
        });
      }
    });

    group('each parameter of AxisTitle', () {
      for (final MapEntry(key: name, value: (title, twin))
          in _axisTitle.entries) {
        test(name, () {
          expectTwin(lowerAxis(LinearAxis(title: title)), {
            'type': 'linear',
            'title': twin,
          });
        });
      }
    });

    test('extra merges into the Map of a part', () {
      expectTwin(
        lowerAxis(
          const LinearAxis(
            grid: AxisGrid(color: _red),
            extra: {
              'grid': {'tickLength': 4},
              'grace': '5%',
            },
          ),
        ),
        {
          'type': 'linear',
          'grid': {'color': _redValue, 'tickLength': 4},
          'grace': '5%',
        },
      );
    });

    test('each axis class with all its parameters, in parameter order', () {
      const ticks = AxisTicks(display: true, color: _red);
      const grid = AxisGrid(display: false);
      const title = AxisTitle(display: true, text: 'T');
      const tail = <String, Object?>{
        'ticks': {'display': true, 'color': _redValue},
        'grid': {'display': false},
        'title': {'display': true, 'text': 'T'},
        'grace': 1,
      };
      const head = <String, Object?>{
        'display': true,
        'position': 'right',
        'reverse': true,
        'stacked': true,
      };
      final labels = <Object>['a'];
      final cases = <(ChartAxis, Map<String, Object?>)>[
        (
          CategoryAxis(
            display: true,
            position: .right,
            reverse: true,
            stacked: true,
            labels: labels,
            min: 'a',
            max: 'b',
            ticks: ticks,
            grid: grid,
            title: title,
            extra: const {'grace': 1},
          ),
          {
            'type': 'category',
            ...head,
            'labels': labels,
            'min': 'a',
            'max': 'b',
            ...tail,
          },
        ),
        (
          const LinearAxis(
            display: true,
            position: .right,
            reverse: true,
            stacked: true,
            min: 0,
            max: 10,
            suggestedMin: 1,
            suggestedMax: 9,
            beginAtZero: true,
            ticks: ticks,
            grid: grid,
            title: title,
            extra: {'grace': 1},
          ),
          {
            'type': 'linear',
            ...head,
            'min': 0,
            'max': 10,
            'suggestedMin': 1,
            'suggestedMax': 9,
            'beginAtZero': true,
            ...tail,
          },
        ),
        (
          const LogarithmicAxis(
            display: true,
            position: .right,
            reverse: true,
            stacked: true,
            min: 1,
            max: 1000,
            suggestedMin: 10,
            suggestedMax: 100,
            ticks: ticks,
            grid: grid,
            title: title,
            extra: {'grace': 1},
          ),
          {
            'type': 'logarithmic',
            ...head,
            'min': 1,
            'max': 1000,
            'suggestedMin': 10,
            'suggestedMax': 100,
            ...tail,
          },
        ),
        for (final (axis, type) in [
          (
            TimeAxis(
              display: true,
              position: .right,
              reverse: true,
              stacked: true,
              min: _start,
              max: _end,
              unit: .month,
              tooltipFormat: 'yyyy-MM',
              ticks: ticks,
              grid: grid,
              title: title,
              extra: const {'grace': 1},
            ),
            'time',
          ),
          (
            TimeSeriesAxis(
              display: true,
              position: .right,
              reverse: true,
              stacked: true,
              min: _start,
              max: _end,
              unit: .month,
              tooltipFormat: 'yyyy-MM',
              ticks: ticks,
              grid: grid,
              title: title,
              extra: const {'grace': 1},
            ),
            'timeseries',
          ),
        ])
          (
            axis,
            {
              'type': type,
              ...head,
              'min': _start,
              'max': _end,
              'time': {'unit': 'month', 'tooltipFormat': 'yyyy-MM'},
              ...tail,
            },
          ),
        (
          const RadialLinearAxis(
            display: true,
            position: .right,
            reverse: true,
            stacked: true,
            min: 0,
            max: 10,
            suggestedMin: 1,
            suggestedMax: 9,
            beginAtZero: true,
            startAngle: 90,
            pointLabelsDisplay: true,
            pointLabelsColor: _red,
            pointLabelsFont: _font,
            pointLabelsPadding: 4,
            angleLinesDisplay: true,
            angleLinesColor: _blue,
            angleLinesLineWidth: 2,
            ticks: ticks,
            grid: grid,
            title: title,
            extra: {'grace': 1},
          ),
          {
            'type': 'radialLinear',
            ...head,
            'min': 0,
            'max': 10,
            'suggestedMin': 1,
            'suggestedMax': 9,
            'beginAtZero': true,
            'startAngle': 90,
            'pointLabels': {
              'display': true,
              'color': _redValue,
              'font': _fontValue,
              'padding': 4,
            },
            'angleLines': {
              'display': true,
              'color': _blueValue,
              'lineWidth': 2,
            },
            ...tail,
          },
        ),
      ];
      for (final (axis, twin) in cases) {
        expectTwin(lowerAxis(axis), twin);
      }
    });
  });

  group('the option groups', () {
    group('each parameter of ChartLegend', () {
      for (final MapEntry(key: name, value: (legend, twin))
          in _legend.entries) {
        test(name, () {
          expectTwin(
            _options(
              ChartConfig(type: .bar, datasets: const [], legend: legend),
            ),
            {
              'plugins': {'legend': twin},
            },
          );
        });
      }
    });

    group('each parameter of ChartTitle, as the title and the subtitle', () {
      for (final MapEntry(key: name, value: (title, twin)) in _title.entries) {
        test(name, () {
          expectTwin(
            _options(
              ChartConfig(
                type: .bar,
                datasets: const [],
                title: title,
                subtitle: title,
              ),
            ),
            {
              'plugins': {'title': twin, 'subtitle': twin},
            },
          );
        });
      }
    });

    group('each parameter of ChartTooltip', () {
      for (final MapEntry(key: name, value: (tooltip, twin))
          in _tooltip.entries) {
        test(name, () {
          expectTwin(
            _options(
              ChartConfig(type: .bar, datasets: const [], tooltip: tooltip),
            ),
            {
              'plugins': {'tooltip': twin},
            },
          );
        });
      }
    });

    group('each parameter of ChartInteraction', () {
      for (final MapEntry(key: name, value: (interaction, twin))
          in _interaction.entries) {
        test(name, () {
          expectTwin(
            _options(
              ChartConfig(
                type: .bar,
                datasets: const [],
                interaction: interaction,
              ),
            ),
            {'interaction': twin},
          );
        });
      }
    });

    group('each parameter of ChartFiller', () {
      for (final MapEntry(key: name, value: (filler, twin))
          in _filler.entries) {
        test(name, () {
          expectTwin(
            _options(
              ChartConfig(type: .line, datasets: const [], filler: filler),
            ),
            {
              'plugins': {'filler': twin},
            },
          );
        });
      }
    });

    group('each parameter of ChartElements and of the element styles', () {
      for (final MapEntry(key: name, value: (elements, twin))
          in _elements.entries) {
        test(name, () {
          expectTwin(
            _options(
              ChartConfig(type: .line, datasets: const [], elements: elements),
            ),
            {'elements': twin},
          );
        });
      }
    });

    group('each parameter of ChartAnimation', () {
      for (final MapEntry(key: name, value: (animation, twin))
          in _animation.entries) {
        test(name, () {
          expectTwin(
            _options(
              ChartConfig(type: .bar, datasets: const [], animation: animation),
            ),
            {'animation': twin},
          );
        });
      }
    });

    test('each group with all its parameters, in parameter order', () {
      final options = _options(
        const ChartConfig(
          type: .bar,
          datasets: [],
          legend: ChartLegend(
            display: true,
            position: .bottom,
            align: .start,
            reverse: true,
            labelColor: _red,
            labelFont: _font,
            boxWidth: 20,
            boxHeight: 10,
            labelPadding: 4,
            usePointStyle: true,
            onClick: _onLegend,
            onHover: _onLegend,
            onLeave: _onLegend,
            extra: {'fullSize': false},
          ),
          title: ChartTitle(
            display: true,
            text: 'T',
            color: _red,
            font: _font,
            align: .end,
            position: .left,
            padding: EdgeInsets.fromLTRB(1, 2, 3, 4),
            fullSize: false,
            extra: {'weight': 1},
          ),
          tooltip: ChartTooltip(
            enabled: true,
            mode: .index,
            intersect: false,
            backgroundColor: _red,
            titleColor: _blue,
            titleFont: _font,
            bodyColor: _red,
            bodyFont: _font,
            footerColor: _blue,
            footerFont: _font,
            padding: EdgeInsets.all(8),
            cornerRadius: 3,
            displayColors: false,
            titleText: _title2,
            labelText: _label,
            footerText: _title2,
            extra: {'position': 'nearest'},
          ),
          interaction: ChartInteraction(
            mode: .nearest,
            intersect: false,
            includeInvisible: true,
            extra: {'axis': 'x'},
          ),
          animation: ChartAnimation(
            duration: Duration(milliseconds: 500),
            delay: Duration(milliseconds: 20),
            easing: .linear,
            loop: false,
            onProgress: _onAnimation,
            onComplete: _onAnimation,
            extra: {'animateRotate': false},
          ),
        ),
      );
      expectTwin(options, {
        'plugins': {
          'legend': {
            'display': true,
            'position': 'bottom',
            'align': 'start',
            'reverse': true,
            'labels': {
              'color': _redValue,
              'font': _fontValue,
              'boxWidth': 20,
              'boxHeight': 10,
              'padding': 4,
              'usePointStyle': true,
            },
            'onClick': _function,
            'onHover': _function,
            'onLeave': _function,
            'fullSize': false,
          },
          'title': {
            'display': true,
            'text': 'T',
            'color': _redValue,
            'font': _fontValue,
            'align': 'end',
            'position': 'left',
            'padding': {'top': 2, 'right': 3, 'bottom': 4, 'left': 1},
            'fullSize': false,
            'weight': 1,
          },
          'tooltip': {
            'enabled': true,
            'mode': 'index',
            'intersect': false,
            'backgroundColor': _redValue,
            'titleColor': _blueValue,
            'titleFont': _fontValue,
            'bodyColor': _redValue,
            'bodyFont': _fontValue,
            'footerColor': _blueValue,
            'footerFont': _fontValue,
            'padding': {'top': 8, 'right': 8, 'bottom': 8, 'left': 8},
            'cornerRadius': 3,
            'displayColors': false,
            'callbacks': {
              'title': _function,
              'label': _function,
              'footer': _function,
            },
            'position': 'nearest',
          },
        },
        'interaction': {
          'mode': 'nearest',
          'intersect': false,
          'includeInvisible': true,
          'axis': 'x',
        },
        'animation': {
          'duration': 500,
          'delay': 20,
          'easing': 'linear',
          'loop': false,
          'onProgress': _function,
          'onComplete': _function,
          'animateRotate': false,
        },
      });
    });
  });

  group('the config', () {
    test('a config with the required parameters', () {
      expectTwin(
        ChartConfigLowering(const ChartConfig(type: .bar, datasets: []))
            .lower(),
        {
          'type': 'bar',
          'data': {'datasets': <Object?>[]},
          'options': <String, Object?>{},
        },
      );
    });

    group('each parameter of ChartConfig', () {
      for (final MapEntry(key: name, value: (config, twin))
          in _config.entries) {
        test(name, () {
          expectTwin(_options(config), twin);
        });
      }
    });

    test('the datasets lower with the type of the chart', () {
      final data = <num?>[1, 2];
      final labels = <Object>['a', 'b'];
      final lowered = ChartConfigLowering(
        ChartConfig(
          type: .bar,
          labels: labels,
          datasets: [
            BarDataset(label: 'A', data: data),
            LineDataset(label: 'B', data: data),
          ],
        ),
      ).lower();
      expectTwin(lowered, {
        'type': 'bar',
        'data': {
          'labels': labels,
          'datasets': [
            {'label': 'A', 'data': data},
            {'type': 'line', 'label': 'B', 'data': data},
          ],
        },
        'options': <String, Object?>{},
      });
      expect(jsGet(lowered['data'], 'labels'), same(labels));
    });

    test('the inline plugins go by reference', () {
      final plugin = <String, Object?>{'id': 'p'};
      final plugins = [plugin];
      final lowered = ChartConfigLowering(
        ChartConfig(type: .line, datasets: const [], plugins: plugins),
      ).lower();
      expect(lowered.jsKeys(), ['type', 'data', 'options', 'plugins']);
      expect(lowered['plugins'], same(plugins));
    });

    test('the order of the scales is the order of the Map', () {
      final options = _options(
        const ChartConfig(
          type: .line,
          datasets: [],
          scales: {
            'y2': LinearAxis(position: .right),
            'x': CategoryAxis(),
            'y': LinearAxis(),
          },
        ),
      );
      expect(jsObjectKeys(options['scales']), [
        'y2',
        'x',
        'y',
      ]);
    });

    test('extra merges into options, into a group and wins', () {
      expectTwin(
        _options(
          const ChartConfig(
            type: .bar,
            datasets: [],
            responsive: true,
            legend: ChartLegend(display: true),
            extra: {
              'responsive': false,
              'plugins': {
                'legend': {
                  'display': false,
                  'title': {'display': true},
                },
                'decimation': {'enabled': true},
              },
              'locale': 'de-DE',
            },
          ),
        ),
        {
          'responsive': false,
          'plugins': {
            'legend': {
              'display': false,
              'title': {'display': true},
            },
            'decimation': {'enabled': true},
          },
          'locale': 'de-DE',
        },
      );
    });

    test('a const config lowers to new Maps at each call', () {
      const config = ChartConfig(
        type: .bar,
        datasets: [
          BarDataset(data: [1]),
        ],
        legend: ChartLegend(display: false),
      );
      final a = ChartConfigLowering(config).lower();
      final b = ChartConfigLowering(config).lower();
      expect(a, isNot(same(b)));
      expect(a['options'], isNot(same(b['options'])));
      expectTwin(a, b);
    });

    test('a trampoline calls the callback of the newest config', () {
      final calls = <String>[];
      final lowering = ChartConfigLowering(
        ChartConfig(
          type: .bar,
          datasets: const [],
          tooltip: ChartTooltip(
            labelText: (item) {
              calls.add('first');
              return 'first';
            },
          ),
        ),
      );
      final options = lowering.lower()['options'];
      final label = jsGet(
        jsGet(jsGet(options, 'plugins'), 'tooltip'),
        'callbacks',
      );
      final item = <String, Object?>{'label': 'a'};
      expect(jsCall(jsGet(label, 'label'), [item]), 'first');
      lowering.config = ChartConfig(
        type: .bar,
        datasets: const [],
        tooltip: ChartTooltip(
          labelText: (item) {
            calls.add('second');
            return null;
          },
        ),
      );
      expect(
        identical(jsCall(jsGet(label, 'label'), [item]), undefined),
        isTrue,
      );
      lowering.config = const ChartConfig(type: .bar, datasets: []);
      expect(
        identical(jsCall(jsGet(label, 'label'), [item]), undefined),
        isTrue,
      );
      expect(calls, ['first', 'second']);
    });
  });
}
