// Original code, not ported from Chart.js: the axes of the typed API.

/// The axes of the typed API (Chart.js ADR 0052, sections 1 and 7):
/// [ChartAxis], one axis class for each scale type of Chart.js, and the
/// axis parts [AxisTicks], [AxisGrid] and [AxisTitle].
///
/// An axis is an entry of the `scales` Map of `ChartConfig`: the key is the
/// axis id, for example `'x'`, `'y'` or `'r'`, and the axis class gives the
/// scale type (`docs/axes/index.md`).
library;

import 'package:flutter/foundation.dart'
    show DiagnosticPropertiesBuilder, Diagnosticable, immutable;
import 'package:flutter/painting.dart' show EdgeInsets, TextStyle;
import 'package:flutter_chartjs_port/src/core/core.adapters.dart' show TimeUnit;
import 'package:flutter_chartjs_port/src/core/core.scale.dart'
    show PointLabelCallback, TickCallback;
import 'package:flutter_chartjs_port/src/core/scale_option_enums.dart'
    show ScaleBounds, TickAlign, TickCrossAlign, TickSource;
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart'
    show OptionKey;
import 'package:flutter_chartjs_port/src/options/scopes.g.dart'
    show
        AngleLineOptionsScope,
        GridLineOptionsScope,
        PointLabelOptionsScope,
        ScaleOptionsScope,
        ScaleTitleOptionsScope,
        TickOptionsScope,
        TimeScaleTimeOptionsScope;
import 'package:flutter_chartjs_port/src/typed/lower.dart';
import 'package:flutter_chartjs_port/src/typed/props.dart';
import 'package:flutter_chartjs_port/src/types/align.dart' show ChartAlign;
import 'package:flutter_chartjs_port/src/types/axis_border.dart'
    show AxisBorder, RadialAxisBorder, ScaleBorder;
import 'package:flutter_chartjs_port/src/types/chart_paint.dart';
import 'package:flutter_chartjs_port/src/types/layout.dart' show ChartPosition;
import 'package:meta/meta.dart' show internal;

/// An axis of a chart: an entry of `options.scales` of a Chart.js config
/// (`docs/axes/index.md`).
///
/// Each scale type has its axis class: [CategoryAxis], [LinearAxis],
/// [LogarithmicAxis], [TimeAxis], [TimeSeriesAxis] and [RadialLinearAxis].
/// The class gives the `type` of the scale. A cartesian chart (bar, line,
/// scatter, bubble) has the axes `x` and `y`. A radial chart (polar area,
/// radar) has the axis `r`.
///
/// A parameter that is `null` is not set: the chart uses the default of
/// Chart.js. The keys that this class does not have go through [extra].
///
/// An axis is immutable. `==` compares the parameters: [CategoryAxis.labels]
/// by identity, and [AxisTicks.callback] with `==`.
@immutable
abstract final class const ChartAxis({
  /// Whether the chart shows the axis: `display`. The default is `true`.
  final bool? display,

  /// The side of the chart area of the axis: `position`.
  ///
  /// A cartesian axis takes [ChartPosition.top], [ChartPosition.left],
  /// [ChartPosition.bottom], [ChartPosition.right] and
  /// [ChartPosition.center]. The default is the bottom for an x axis and
  /// the left for a y axis. The position at a value of another axis goes
  /// through [extra]: `{'position': ScaleValuePosition('x', 0)}`.
  final ChartPosition? position,

  /// Whether the axis runs in the other direction: `reverse`.
  final bool? reverse,

  /// Whether the datasets of the axis stack: `stacked` as a boolean
  /// (`docs/charts/bar.md`, "Stacked Bar Chart"). The value `'single'` goes
  /// through [extra].
  final bool? stacked,

  /// The tick marks and the tick labels: `ticks`.
  final AxisTicks? ticks,

  /// The grid lines: `grid`.
  final AxisGrid? grid,

  /// The title of the axis: `title`.
  final AxisTitle? title,

  /// The Chart.js options of the axis that have no parameter, for example
  /// `{'grace': '5%'}`.
  ///
  /// The entries go into the axis Map last: an entry wins over a parameter
  /// with the same key. A Map value merges into the Map of the key, a List
  /// or another value replaces it. The chart gets a copy of each Map and the
  /// Lists of the app.
  final Map<String, Object?>? extra,
}) with Diagnosticable {
  /// The parameters of each axis class.
  this;

  /// The border of the axis: `border` (Chart.js ADR 0141). A cartesian axis
  /// takes an [AxisBorder], and [RadialLinearAxis] a [RadialAxisBorder].
  ScaleBorder? get border;

  /// A copy of this axis with the given parameters. A parameter that is
  /// `null` keeps its value.
  ChartAxis copyWith({
    bool? display,
    ChartPosition? position,
    bool? reverse,
    bool? stacked,
    AxisTicks? ticks,
    AxisGrid? grid,
    AxisTitle? title,
    Map<String, Object?>? extra,
  });

  /// The scale type: the id of the scale class.
  String get _type;

  /// Writes the keys of the axis class into [scope], after the keys of
  /// [ChartAxis] before [ticks].
  void _lowerOwn(ScaleOptionsScope scope);

  /// The properties of the axis, in parameter order.
  List<TypedProperty> get _props;

  /// The properties of [ChartAxis] before the parameters of the class.
  List<TypedProperty> get _headProps => [
    ('display', display),
    ('position', position),
    ('reverse', reverse),
    ('stacked', stacked),
  ];

  /// The properties of [ChartAxis] after the parameters of the class.
  List<TypedProperty> get _tailProps => [
    ('ticks', ticks),
    ('grid', grid),
    ('border', border),
    ('title', title),
    ('extra', byEntries(extra)),
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartAxis &&
          other.runtimeType == runtimeType &&
          propsEqual(_props, other._props);

  @override
  int get hashCode => Object.hash(runtimeType, propsHash(_props));

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    addProps(properties, _props);
  }
}

/// The axis scope of [axis] (Chart.js ADR 0052, section 2; Chart.js ADR
/// 0054 §7): a new `ScaleOptionsScope` with `type` first, then the keys in
/// parameter order, and [ChartAxis.extra] last.
@internal
ScaleOptionsScope lowerAxis(ChartAxis axis) {
  final scope = ScaleOptionsScope()..type = axis._type;
  put(scope, OptionKey.display, axis.display);
  put(scope, OptionKey.position, axis.position);
  put(scope, OptionKey.reverse, axis.reverse);
  put(scope, OptionKey.stacked, axis.stacked);
  axis._lowerOwn(scope);
  if (_lowerTicks(axis.ticks) case final ticks?) scope.ticks = ticks;
  if (_lowerGrid(axis.grid) case final grid?) scope.grid = grid;
  // The object itself, with the typed setter (Chart.js ADR 0141).
  if (axis.border case final border?) scope.border = border;
  if (_lowerTitle(axis.title) case final title?) scope.title = title;
  return mergeExtra(scope, axis.extra);
}

/// A category axis: the scale type `category` (`docs/axes/cartesian/
/// category.md`). It shows the labels of the chart in order. It is the
/// default index axis of a bar and a line chart.
final class const CategoryAxis({
  super.display,
  super.position,
  super.reverse,
  super.stacked,

  /// The labels of this axis, in place of the labels of the chart:
  /// `labels`. The List goes to the chart by reference.
  final List<Object>? labels,

  /// The first label that the axis shows: `min`.
  final String? min,

  /// The last label that the axis shows: `max`.
  final String? max,

  /// {@template flutter_chartjs_port.typed.bounds}
  /// What the range of the axis keeps: `bounds`. [ScaleBounds.ticks] grows
  /// the range to the outer ticks, and [ScaleBounds.data] keeps the data.
  /// {@endtemplate}
  final ScaleBounds? bounds,
  super.ticks,
  super.grid,

  /// The axis line and the dash of the grid lines: `border` (Chart.js ADR
  /// 0141). A null field takes the default: a solid line of 1 pixel in the
  /// default `borderColor`.
  @override final AxisBorder? border,
  super.title,
  super.extra,
}) extends ChartAxis {
  /// A category axis.
  this;

  @override
  CategoryAxis copyWith({
    bool? display,
    ChartPosition? position,
    bool? reverse,
    bool? stacked,
    List<Object>? labels,
    String? min,
    String? max,
    ScaleBounds? bounds,
    AxisTicks? ticks,
    AxisGrid? grid,
    AxisBorder? border,
    AxisTitle? title,
    Map<String, Object?>? extra,
  }) => CategoryAxis(
    display: display ?? this.display,
    position: position ?? this.position,
    reverse: reverse ?? this.reverse,
    stacked: stacked ?? this.stacked,
    labels: labels ?? this.labels,
    min: min ?? this.min,
    max: max ?? this.max,
    bounds: bounds ?? this.bounds,
    ticks: ticks ?? this.ticks,
    grid: grid ?? this.grid,
    border: border ?? this.border,
    title: title ?? this.title,
    extra: extra ?? this.extra,
  );

  @override
  String get _type => 'category';

  @override
  void _lowerOwn(ScaleOptionsScope scope) {
    put(scope, OptionKey.labels, labels);
    put(scope, OptionKey.min, min);
    put(scope, OptionKey.max, max);
    put(scope, OptionKey.bounds, bounds);
  }

  @override
  List<TypedProperty> get _props => [
    ..._headProps,
    ('labels', labels),
    ('min', min),
    ('max', max),
    ('bounds', bounds),
    ..._tailProps,
  ];
}

/// A linear axis: the scale type `linear` (`docs/axes/cartesian/
/// linear.md`). It is the default value axis of a bar and a line chart.
final class const LinearAxis({
  super.display,
  super.position,
  super.reverse,
  super.stacked,

  /// {@template flutter_chartjs_port.typed.axisMin}
  /// The minimum of the axis: `min`. The data does not change it.
  /// {@endtemplate}
  final double? min,

  /// {@template flutter_chartjs_port.typed.axisMax}
  /// The maximum of the axis: `max`. The data does not change it.
  /// {@endtemplate}
  final double? max,

  /// {@template flutter_chartjs_port.typed.suggestedMin}
  /// A minimum that the data can make smaller: `suggestedMin`.
  /// {@endtemplate}
  final double? suggestedMin,

  /// {@template flutter_chartjs_port.typed.suggestedMax}
  /// A maximum that the data can make larger: `suggestedMax`.
  /// {@endtemplate}
  final double? suggestedMax,

  /// {@template flutter_chartjs_port.typed.beginAtZero}
  /// Whether the axis includes 0: `beginAtZero`. The default of the value
  /// axis of a bar chart is `true`.
  /// {@endtemplate}
  final bool? beginAtZero,

  /// {@macro flutter_chartjs_port.typed.bounds}
  final ScaleBounds? bounds,
  super.ticks,
  super.grid,

  /// The axis line and the dash of the grid lines: `border` (Chart.js ADR
  /// 0141). A null field takes the default: a solid line of 1 pixel in the
  /// default `borderColor`.
  @override final AxisBorder? border,
  super.title,
  super.extra,
}) extends ChartAxis {
  /// A linear axis.
  this;

  @override
  LinearAxis copyWith({
    bool? display,
    ChartPosition? position,
    bool? reverse,
    bool? stacked,
    double? min,
    double? max,
    double? suggestedMin,
    double? suggestedMax,
    bool? beginAtZero,
    ScaleBounds? bounds,
    AxisTicks? ticks,
    AxisGrid? grid,
    AxisBorder? border,
    AxisTitle? title,
    Map<String, Object?>? extra,
  }) => LinearAxis(
    display: display ?? this.display,
    position: position ?? this.position,
    reverse: reverse ?? this.reverse,
    stacked: stacked ?? this.stacked,
    min: min ?? this.min,
    max: max ?? this.max,
    suggestedMin: suggestedMin ?? this.suggestedMin,
    suggestedMax: suggestedMax ?? this.suggestedMax,
    beginAtZero: beginAtZero ?? this.beginAtZero,
    bounds: bounds ?? this.bounds,
    ticks: ticks ?? this.ticks,
    grid: grid ?? this.grid,
    border: border ?? this.border,
    title: title ?? this.title,
    extra: extra ?? this.extra,
  );

  @override
  String get _type => 'linear';

  @override
  void _lowerOwn(ScaleOptionsScope scope) {
    put(scope, OptionKey.min, min);
    put(scope, OptionKey.max, max);
    put(scope, OptionKey.suggestedMin, suggestedMin);
    put(scope, OptionKey.suggestedMax, suggestedMax);
    put(scope, OptionKey.beginAtZero, beginAtZero);
    put(scope, OptionKey.bounds, bounds);
  }

  @override
  List<TypedProperty> get _props => [
    ..._headProps,
    ('min', min),
    ('max', max),
    ('suggestedMin', suggestedMin),
    ('suggestedMax', suggestedMax),
    ('beginAtZero', beginAtZero),
    ('bounds', bounds),
    ..._tailProps,
  ];
}

/// A logarithmic axis: the scale type `logarithmic` (`docs/axes/cartesian/
/// logarithmic.md`). Its values are positive.
final class const LogarithmicAxis({
  super.display,
  super.position,
  super.reverse,
  super.stacked,

  /// {@macro flutter_chartjs_port.typed.axisMin}
  final double? min,

  /// {@macro flutter_chartjs_port.typed.axisMax}
  final double? max,

  /// {@macro flutter_chartjs_port.typed.suggestedMin}
  final double? suggestedMin,

  /// {@macro flutter_chartjs_port.typed.suggestedMax}
  final double? suggestedMax,

  /// {@macro flutter_chartjs_port.typed.bounds}
  final ScaleBounds? bounds,
  super.ticks,
  super.grid,

  /// The axis line and the dash of the grid lines: `border` (Chart.js ADR
  /// 0141). A null field takes the default: a solid line of 1 pixel in the
  /// default `borderColor`.
  @override final AxisBorder? border,
  super.title,
  super.extra,
}) extends ChartAxis {
  /// A logarithmic axis.
  this;

  @override
  LogarithmicAxis copyWith({
    bool? display,
    ChartPosition? position,
    bool? reverse,
    bool? stacked,
    double? min,
    double? max,
    double? suggestedMin,
    double? suggestedMax,
    ScaleBounds? bounds,
    AxisTicks? ticks,
    AxisGrid? grid,
    AxisBorder? border,
    AxisTitle? title,
    Map<String, Object?>? extra,
  }) => LogarithmicAxis(
    display: display ?? this.display,
    position: position ?? this.position,
    reverse: reverse ?? this.reverse,
    stacked: stacked ?? this.stacked,
    min: min ?? this.min,
    max: max ?? this.max,
    suggestedMin: suggestedMin ?? this.suggestedMin,
    suggestedMax: suggestedMax ?? this.suggestedMax,
    bounds: bounds ?? this.bounds,
    ticks: ticks ?? this.ticks,
    grid: grid ?? this.grid,
    border: border ?? this.border,
    title: title ?? this.title,
    extra: extra ?? this.extra,
  );

  @override
  String get _type => 'logarithmic';

  @override
  void _lowerOwn(ScaleOptionsScope scope) {
    put(scope, OptionKey.min, min);
    put(scope, OptionKey.max, max);
    put(scope, OptionKey.suggestedMin, suggestedMin);
    put(scope, OptionKey.suggestedMax, suggestedMax);
    put(scope, OptionKey.bounds, bounds);
  }

  @override
  List<TypedProperty> get _props => [
    ..._headProps,
    ('min', min),
    ('max', max),
    ('suggestedMin', suggestedMin),
    ('suggestedMax', suggestedMax),
    ('bounds', bounds),
    ..._tailProps,
  ];
}

/// The parameters of [TimeAxis] and [TimeSeriesAxis], in parameter order.
///
/// A mixin of the library: each of the two classes declares the fields.
base mixin _TimeOptions on ChartAxis {
  DateTime? get min;
  DateTime? get max;
  TimeUnit? get unit;
  String? get tooltipFormat;

  void _lowerTime(ScaleOptionsScope scope) {
    final time = TimeScaleTimeOptionsScope();
    put(time, OptionKey.unit, unit);
    put(time, OptionKey.tooltipFormat, tooltipFormat);
    put(scope, OptionKey.min, min);
    put(scope, OptionKey.max, max);
    if (time.ownKeyCount != 0) scope.time = time;
  }

  List<TypedProperty> get _timeProps => [
    ('min', min),
    ('max', max),
    ('unit', unit),
    ('tooltipFormat', tooltipFormat),
  ];
}

/// A time axis: the scale type `time` (`docs/axes/cartesian/time.md`).
///
/// The axis places each data item at its time. The data has `DateTime`
/// values, for example `DataPoint.time` items, or numbers in milliseconds
/// since the epoch. The default date adapter formats the ticks.
final class const TimeAxis({
  super.display,
  super.position,
  super.reverse,
  super.stacked,

  /// {@template flutter_chartjs_port.typed.timeMin}
  /// The first time of the axis: `min`.
  /// {@endtemplate}
  @override final DateTime? min,

  /// {@template flutter_chartjs_port.typed.timeMax}
  /// The last time of the axis: `max`.
  /// {@endtemplate}
  @override final DateTime? max,

  /// {@template flutter_chartjs_port.typed.unit}
  /// The time unit of the ticks: `time.unit`, for example `'day'` or
  /// `'month'`. The default unit fits the range of the data.
  /// {@endtemplate}
  @override final TimeUnit? unit,

  /// {@template flutter_chartjs_port.typed.tooltipFormat}
  /// The date format of the times in the tooltip: `time.tooltipFormat`, an
  /// ICU pattern of the default date adapter, for example `'yyyy-MM-dd'`.
  /// {@endtemplate}
  @override final String? tooltipFormat,

  /// {@macro flutter_chartjs_port.typed.bounds}
  final ScaleBounds? bounds,
  super.ticks,
  super.grid,

  /// The axis line and the dash of the grid lines: `border` (Chart.js ADR
  /// 0141). A null field takes the default: a solid line of 1 pixel in the
  /// default `borderColor`.
  @override final AxisBorder? border,
  super.title,
  super.extra,
}) extends ChartAxis with _TimeOptions {
  /// A time axis.
  this;

  @override
  TimeAxis copyWith({
    bool? display,
    ChartPosition? position,
    bool? reverse,
    bool? stacked,
    DateTime? min,
    DateTime? max,
    TimeUnit? unit,
    String? tooltipFormat,
    ScaleBounds? bounds,
    AxisTicks? ticks,
    AxisGrid? grid,
    AxisBorder? border,
    AxisTitle? title,
    Map<String, Object?>? extra,
  }) => TimeAxis(
    display: display ?? this.display,
    position: position ?? this.position,
    reverse: reverse ?? this.reverse,
    stacked: stacked ?? this.stacked,
    min: min ?? this.min,
    max: max ?? this.max,
    unit: unit ?? this.unit,
    tooltipFormat: tooltipFormat ?? this.tooltipFormat,
    bounds: bounds ?? this.bounds,
    ticks: ticks ?? this.ticks,
    grid: grid ?? this.grid,
    border: border ?? this.border,
    title: title ?? this.title,
    extra: extra ?? this.extra,
  );

  @override
  String get _type => 'time';

  @override
  void _lowerOwn(ScaleOptionsScope scope) {
    _lowerTime(scope);
    put(scope, OptionKey.bounds, bounds);
  }

  @override
  List<TypedProperty> get _props => [
    ..._headProps,
    ..._timeProps,
    ('bounds', bounds),
    ..._tailProps,
  ];
}

/// A time series axis: the scale type `timeseries` (`docs/axes/cartesian/
/// timeseries.md`).
///
/// The axis places the data items at equal distances, in time order. The
/// data has `DateTime` values or numbers in milliseconds since the epoch.
final class const TimeSeriesAxis({
  super.display,
  super.position,
  super.reverse,
  super.stacked,

  /// {@macro flutter_chartjs_port.typed.timeMin}
  @override final DateTime? min,

  /// {@macro flutter_chartjs_port.typed.timeMax}
  @override final DateTime? max,

  /// {@macro flutter_chartjs_port.typed.unit}
  @override final TimeUnit? unit,

  /// {@macro flutter_chartjs_port.typed.tooltipFormat}
  @override final String? tooltipFormat,

  /// {@macro flutter_chartjs_port.typed.bounds}
  final ScaleBounds? bounds,
  super.ticks,
  super.grid,

  /// The axis line and the dash of the grid lines: `border` (Chart.js ADR
  /// 0141). A null field takes the default: a solid line of 1 pixel in the
  /// default `borderColor`.
  @override final AxisBorder? border,
  super.title,
  super.extra,
}) extends ChartAxis with _TimeOptions {
  /// A time series axis.
  this;

  @override
  TimeSeriesAxis copyWith({
    bool? display,
    ChartPosition? position,
    bool? reverse,
    bool? stacked,
    DateTime? min,
    DateTime? max,
    TimeUnit? unit,
    String? tooltipFormat,
    ScaleBounds? bounds,
    AxisTicks? ticks,
    AxisGrid? grid,
    AxisBorder? border,
    AxisTitle? title,
    Map<String, Object?>? extra,
  }) => TimeSeriesAxis(
    display: display ?? this.display,
    position: position ?? this.position,
    reverse: reverse ?? this.reverse,
    stacked: stacked ?? this.stacked,
    min: min ?? this.min,
    max: max ?? this.max,
    unit: unit ?? this.unit,
    tooltipFormat: tooltipFormat ?? this.tooltipFormat,
    bounds: bounds ?? this.bounds,
    ticks: ticks ?? this.ticks,
    grid: grid ?? this.grid,
    border: border ?? this.border,
    title: title ?? this.title,
    extra: extra ?? this.extra,
  );

  @override
  String get _type => 'timeseries';

  @override
  void _lowerOwn(ScaleOptionsScope scope) {
    _lowerTime(scope);
    put(scope, OptionKey.bounds, bounds);
  }

  @override
  List<TypedProperty> get _props => [
    ..._headProps,
    ..._timeProps,
    ('bounds', bounds),
    ..._tailProps,
  ];
}

/// A radial linear axis: the scale type `radialLinear` (`docs/axes/radial/
/// linear.md`), the axis `r` of a polar area and a radar chart.
///
/// The labels of the chart are the point labels around the axis. The angle
/// lines go from the center to the point labels.
final class const RadialLinearAxis({
  super.display,
  super.position,
  super.reverse,
  super.stacked,

  /// {@macro flutter_chartjs_port.typed.axisMin}
  final double? min,

  /// {@macro flutter_chartjs_port.typed.axisMax}
  final double? max,

  /// {@macro flutter_chartjs_port.typed.suggestedMin}
  final double? suggestedMin,

  /// {@macro flutter_chartjs_port.typed.suggestedMax}
  final double? suggestedMax,

  /// {@macro flutter_chartjs_port.typed.beginAtZero}
  final bool? beginAtZero,

  /// The angle of the first point label in degrees, from the top,
  /// clockwise: `startAngle`. The default is 0.
  final double? startAngle,

  /// Whether the chart shows the point labels: `pointLabels.display`.
  final bool? pointLabelsDisplay,

  /// The color of the point labels: `pointLabels.color`.
  final ChartPaint? pointLabelsColor,

  /// The font of the point labels: `pointLabels.font`. The color of the
  /// font is not read: set [pointLabelsColor].
  final TextStyle? pointLabelsFont,

  /// The space between the chart area and the point labels, in pixels:
  /// `pointLabels.padding`. The default is 5.
  final double? pointLabelsPadding,

  /// The lines of each point label: `pointLabels.callback`. It gets the lines
  /// of the item of `labels` and its index (Chart.js ADR 0131).
  final PointLabelCallback? pointLabelsCallback,

  /// Whether the chart shows the lines from the center to the point labels:
  /// `angleLines.display`.
  final bool? angleLinesDisplay,

  /// The color of the lines from the center to the point labels:
  /// `angleLines.color`.
  final ChartPaint? angleLinesColor,

  /// The width of the lines from the center to the point labels, in pixels:
  /// `angleLines.lineWidth`. The default is 1.
  final double? angleLinesLineWidth,
  super.ticks,
  super.grid,

  /// The dash of the grid lines: `border` (Chart.js ADR 0141). The radial
  /// axis has no axis line. The default is a solid line.
  @override final RadialAxisBorder? border,
  super.title,
  super.extra,
}) extends ChartAxis {
  /// A radial linear axis.
  this;

  @override
  RadialLinearAxis copyWith({
    bool? display,
    ChartPosition? position,
    bool? reverse,
    bool? stacked,
    double? min,
    double? max,
    double? suggestedMin,
    double? suggestedMax,
    bool? beginAtZero,
    double? startAngle,
    bool? pointLabelsDisplay,
    ChartPaint? pointLabelsColor,
    TextStyle? pointLabelsFont,
    double? pointLabelsPadding,
    PointLabelCallback? pointLabelsCallback,
    bool? angleLinesDisplay,
    ChartPaint? angleLinesColor,
    double? angleLinesLineWidth,
    AxisTicks? ticks,
    AxisGrid? grid,
    RadialAxisBorder? border,
    AxisTitle? title,
    Map<String, Object?>? extra,
  }) => RadialLinearAxis(
    display: display ?? this.display,
    position: position ?? this.position,
    reverse: reverse ?? this.reverse,
    stacked: stacked ?? this.stacked,
    min: min ?? this.min,
    max: max ?? this.max,
    suggestedMin: suggestedMin ?? this.suggestedMin,
    suggestedMax: suggestedMax ?? this.suggestedMax,
    beginAtZero: beginAtZero ?? this.beginAtZero,
    startAngle: startAngle ?? this.startAngle,
    pointLabelsDisplay: pointLabelsDisplay ?? this.pointLabelsDisplay,
    pointLabelsColor: pointLabelsColor ?? this.pointLabelsColor,
    pointLabelsFont: pointLabelsFont ?? this.pointLabelsFont,
    pointLabelsPadding: pointLabelsPadding ?? this.pointLabelsPadding,
    pointLabelsCallback: pointLabelsCallback ?? this.pointLabelsCallback,
    angleLinesDisplay: angleLinesDisplay ?? this.angleLinesDisplay,
    angleLinesColor: angleLinesColor ?? this.angleLinesColor,
    angleLinesLineWidth: angleLinesLineWidth ?? this.angleLinesLineWidth,
    ticks: ticks ?? this.ticks,
    grid: grid ?? this.grid,
    border: border ?? this.border,
    title: title ?? this.title,
    extra: extra ?? this.extra,
  );

  @override
  String get _type => 'radialLinear';

  @override
  void _lowerOwn(ScaleOptionsScope scope) {
    final pointLabels = PointLabelOptionsScope();
    put(pointLabels, OptionKey.display, pointLabelsDisplay);
    put(pointLabels, OptionKey.color, pointLabelsColor);
    put(pointLabels, OptionKey.font, pointLabelsFont);
    put(pointLabels, OptionKey.padding, pointLabelsPadding);
    put(pointLabels, OptionKey.callback, pointLabelsCallback);
    final angleLines = AngleLineOptionsScope();
    put(angleLines, OptionKey.display, angleLinesDisplay);
    put(angleLines, OptionKey.color, angleLinesColor);
    put(angleLines, OptionKey.lineWidth, angleLinesLineWidth);
    put(scope, OptionKey.min, min);
    put(scope, OptionKey.max, max);
    put(scope, OptionKey.suggestedMin, suggestedMin);
    put(scope, OptionKey.suggestedMax, suggestedMax);
    put(scope, OptionKey.beginAtZero, beginAtZero);
    put(scope, OptionKey.startAngle, startAngle);
    if (pointLabels.ownKeyCount != 0) scope.pointLabels = pointLabels;
    if (angleLines.ownKeyCount != 0) scope.angleLines = angleLines;
  }

  @override
  List<TypedProperty> get _props => [
    ..._headProps,
    ('min', min),
    ('max', max),
    ('suggestedMin', suggestedMin),
    ('suggestedMax', suggestedMax),
    ('beginAtZero', beginAtZero),
    ('startAngle', startAngle),
    ('pointLabelsDisplay', pointLabelsDisplay),
    ('pointLabelsColor', pointLabelsColor),
    ('pointLabelsFont', pointLabelsFont),
    ('pointLabelsPadding', pointLabelsPadding),
    ('pointLabelsCallback', pointLabelsCallback),
    ('angleLinesDisplay', angleLinesDisplay),
    ('angleLinesColor', angleLinesColor),
    ('angleLinesLineWidth', angleLinesLineWidth),
    ..._tailProps,
  ];
}

/// The tick marks and the tick labels of an axis: `ticks`
/// (`docs/axes/_common_ticks.md`, `docs/axes/styling.md`).
@immutable
final class const AxisTicks({
  /// Whether the chart shows the tick labels: `display`.
  final bool? display,

  /// The color of the tick labels: `color`.
  final ChartPaint? color,

  /// The font of the tick labels: `font`. The color of the font is not
  /// read: set [color].
  final TextStyle? font,

  /// The space between the tick labels and the axis, in pixels: `padding`.
  final double? padding,

  /// The step between two ticks of a linear axis: `stepSize`.
  final double? stepSize,

  /// The maximum rotation of the tick labels in degrees, to make them fit:
  /// `maxRotation`. The default is 50.
  final double? maxRotation,

  /// Whether the axis skips labels that do not fit: `autoSkip`. The
  /// default is `true`.
  final bool? autoSkip,

  /// The place of a tick label along the axis: `align`. The default is
  /// [TickAlign.center].
  final TickAlign? align,

  /// The place of a tick label across the axis: `crossAlign`. The default
  /// is [TickCrossAlign.near].
  final TickCrossAlign? crossAlign,

  /// Where the ticks of a time axis come from: `source`. The default is
  /// [TickSource.auto].
  final TickSource? source,

  /// The label of each tick: `callback` (`docs/axes/labelling.md`,
  /// "Creating Custom Tick Formats").
  ///
  /// It gets the scale, the value of the tick, its index and all ticks, and
  /// gives the lines of the label. `null` removes the tick, and an empty
  /// List keeps the tick with no label. For a category axis, the value is
  /// the index of the label: `scale.getLabelForValue(value)` gives the
  /// label. Use a method tear-off or a function in a field: a new closure
  /// in each build is a new value, and the chart then updates.
  final TickCallback? callback,

  /// The Chart.js tick options that have no parameter, for example
  /// `{'precision': 0}`. The rules of [ChartAxis.extra] apply.
  final Map<String, Object?>? extra,
}) with Diagnosticable {
  /// The tick options of an axis.
  this;

  /// A copy of these tick options with the given parameters. A parameter
  /// that is `null` keeps its value.
  AxisTicks copyWith({
    bool? display,
    ChartPaint? color,
    TextStyle? font,
    double? padding,
    double? stepSize,
    double? maxRotation,
    bool? autoSkip,
    TickAlign? align,
    TickCrossAlign? crossAlign,
    TickSource? source,
    TickCallback? callback,
    Map<String, Object?>? extra,
  }) => AxisTicks(
    display: display ?? this.display,
    color: color ?? this.color,
    font: font ?? this.font,
    padding: padding ?? this.padding,
    stepSize: stepSize ?? this.stepSize,
    maxRotation: maxRotation ?? this.maxRotation,
    autoSkip: autoSkip ?? this.autoSkip,
    align: align ?? this.align,
    crossAlign: crossAlign ?? this.crossAlign,
    source: source ?? this.source,
    callback: callback ?? this.callback,
    extra: extra ?? this.extra,
  );

  List<TypedProperty> get _props => [
    ('display', display),
    ('color', color),
    ('font', font),
    ('padding', padding),
    ('stepSize', stepSize),
    ('maxRotation', maxRotation),
    ('autoSkip', autoSkip),
    ('align', align),
    ('crossAlign', crossAlign),
    ('source', source),
    ('callback', callback),
    ('extra', byEntries(extra)),
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AxisTicks && propsEqual(_props, other._props);

  @override
  int get hashCode => propsHash(_props);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    addProps(properties, _props);
  }
}

/// The `ticks` scope of [ticks], or Dart `null`.
TickOptionsScope? _lowerTicks(AxisTicks? ticks) {
  if (ticks == null) return null;
  final scope = TickOptionsScope();
  put(scope, OptionKey.display, ticks.display);
  put(scope, OptionKey.color, ticks.color);
  put(scope, OptionKey.font, ticks.font);
  put(scope, OptionKey.padding, ticks.padding);
  put(scope, OptionKey.stepSize, ticks.stepSize);
  put(scope, OptionKey.maxRotation, ticks.maxRotation);
  put(scope, OptionKey.autoSkip, ticks.autoSkip);
  put(scope, OptionKey.align, ticks.align);
  put(scope, OptionKey.crossAlign, ticks.crossAlign);
  put(scope, OptionKey.source, ticks.source);
  put(scope, OptionKey.callback, ticks.callback);
  return mergeExtra(scope, ticks.extra);
}

/// The grid lines of an axis: `grid` (`docs/axes/styling.md`, "Grid Line
/// Configuration").
@immutable
final class const AxisGrid({
  /// Whether the chart draws the grid lines: `display`.
  final bool? display,

  /// The color of the grid lines: `color`.
  final ChartPaint? color,

  /// The width of the grid lines in pixels: `lineWidth`.
  final double? lineWidth,

  /// Whether the grid lines go across the chart area: `drawOnChartArea`.
  /// With `false`, the chart draws only the tick marks.
  final bool? drawOnChartArea,

  /// Whether the chart draws the tick marks next to the tick labels:
  /// `drawTicks`.
  final bool? drawTicks,

  /// Whether the grid lines are between the labels, not at them: `offset`.
  /// The default of the index axis of a bar chart is `true`.
  final bool? offset,

  /// The Chart.js grid options that have no parameter, for example
  /// `{'tickLength': 4}`. The rules of [ChartAxis.extra] apply.
  final Map<String, Object?>? extra,
}) with Diagnosticable {
  /// The grid options of an axis.
  this;

  /// A copy of these grid options with the given parameters. A parameter
  /// that is `null` keeps its value.
  AxisGrid copyWith({
    bool? display,
    ChartPaint? color,
    double? lineWidth,
    bool? drawOnChartArea,
    bool? drawTicks,
    bool? offset,
    Map<String, Object?>? extra,
  }) => AxisGrid(
    display: display ?? this.display,
    color: color ?? this.color,
    lineWidth: lineWidth ?? this.lineWidth,
    drawOnChartArea: drawOnChartArea ?? this.drawOnChartArea,
    drawTicks: drawTicks ?? this.drawTicks,
    offset: offset ?? this.offset,
    extra: extra ?? this.extra,
  );

  List<TypedProperty> get _props => [
    ('display', display),
    ('color', color),
    ('lineWidth', lineWidth),
    ('drawOnChartArea', drawOnChartArea),
    ('drawTicks', drawTicks),
    ('offset', offset),
    ('extra', byEntries(extra)),
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AxisGrid && propsEqual(_props, other._props);

  @override
  int get hashCode => propsHash(_props);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    addProps(properties, _props);
  }
}

/// The `grid` scope of [grid], or Dart `null`.
GridLineOptionsScope? _lowerGrid(AxisGrid? grid) {
  if (grid == null) return null;
  final scope = GridLineOptionsScope();
  put(scope, OptionKey.display, grid.display);
  put(scope, OptionKey.color, grid.color);
  put(scope, OptionKey.lineWidth, grid.lineWidth);
  put(scope, OptionKey.drawOnChartArea, grid.drawOnChartArea);
  put(scope, OptionKey.drawTicks, grid.drawTicks);
  put(scope, OptionKey.offset, grid.offset);
  return mergeExtra(scope, grid.extra);
}

/// The title of an axis: `title` (`docs/axes/labelling.md`, "Scale
/// Title Configuration").
@immutable
final class const AxisTitle({
  /// Whether the chart shows the title: `display`. The default is `false`.
  final bool? display,

  /// The text of the title: `text`.
  final String? text,

  /// The color of the title: `color`.
  final ChartPaint? color,

  /// The font of the title: `font`. The color of the font is not read: set
  /// [color].
  final TextStyle? font,

  /// The alignment of the title along the axis: `align`.
  final ChartAlign? align,

  /// The space around the title: `padding`. Chart.js reads the top and the
  /// bottom.
  final EdgeInsets? padding,

  /// The Chart.js title options that have no parameter. The rules of
  /// [ChartAxis.extra] apply.
  final Map<String, Object?>? extra,
}) with Diagnosticable {
  /// The title options of an axis.
  this;

  /// A copy of these title options with the given parameters. A parameter
  /// that is `null` keeps its value.
  AxisTitle copyWith({
    bool? display,
    String? text,
    ChartPaint? color,
    TextStyle? font,
    ChartAlign? align,
    EdgeInsets? padding,
    Map<String, Object?>? extra,
  }) => AxisTitle(
    display: display ?? this.display,
    text: text ?? this.text,
    color: color ?? this.color,
    font: font ?? this.font,
    align: align ?? this.align,
    padding: padding ?? this.padding,
    extra: extra ?? this.extra,
  );

  List<TypedProperty> get _props => [
    ('display', display),
    ('text', text),
    ('color', color),
    ('font', font),
    ('align', align),
    ('padding', padding),
    ('extra', byEntries(extra)),
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AxisTitle && propsEqual(_props, other._props);

  @override
  int get hashCode => propsHash(_props);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    addProps(properties, _props);
  }
}

/// The `title` scope of [title], or Dart `null`.
ScaleTitleOptionsScope? _lowerTitle(AxisTitle? title) {
  if (title == null) return null;
  final scope = ScaleTitleOptionsScope();
  put(scope, OptionKey.display, title.display);
  put(scope, OptionKey.text, title.text);
  put(scope, OptionKey.color, title.color);
  put(scope, OptionKey.font, title.font);
  put(scope, OptionKey.align, title.align);
  put(scope, OptionKey.padding, title.padding);
  return mergeExtra(scope, title.extra);
}
