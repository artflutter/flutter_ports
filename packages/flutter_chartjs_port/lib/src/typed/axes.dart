// Original code, not ported from Chart.js: the axes of the typed API.

/// The axes of the typed API (Chart.js ADR 0052, sections 1 and 7):
/// [ChartAxis], one axis class for each scale type of Chart.js, and the
/// axis parts [AxisTicks], [AxisGrid] and [AxisTitle].
///
/// An axis is an entry of the `scales` Map of `ChartConfig`: the key is the
/// axis id, for example `'x'`, `'y'` or `'r'`, and the axis class gives the
/// scale type (`docs/axes/index.md`).
library;

import 'dart:ui' show Color;

import 'package:flutter/foundation.dart'
    show DiagnosticPropertiesBuilder, Diagnosticable, immutable;
import 'package:flutter/painting.dart' show EdgeInsets, TextStyle;
import 'package:flutter_chartjs_port/src/core/core.adapters.dart' show TimeUnit;
import 'package:flutter_chartjs_port/src/core/core.scale.dart' show Scale;
import 'package:flutter_chartjs_port/src/js/js_function.dart' show JsFunction;
import 'package:flutter_chartjs_port/src/theme/css.dart' show fontSpecOf;
import 'package:flutter_chartjs_port/src/typed/callbacks.dart'
    show AxisTickInfo;
import 'package:flutter_chartjs_port/src/typed/lower.dart';
import 'package:flutter_chartjs_port/src/typed/props.dart';
import 'package:flutter_chartjs_port/src/typed/values.dart'
    show ChartAlign, ChartPosition;
import 'package:flutter_chartjs_port/src/types/index.dart' show Tick;
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
/// by identity, and [AxisTicks.format] with `==`.
@immutable
abstract final class ChartAxis with Diagnosticable {
  /// The parameters of each axis class.
  const ChartAxis({
    this.display,
    this.position,
    this.reverse,
    this.stacked,
    this.ticks,
    this.grid,
    this.title,
    this.extra,
  });

  /// Whether the chart shows the axis: `display`. The default is `true`.
  final bool? display;

  /// The side of the chart area of the axis: `position`.
  ///
  /// A cartesian axis takes [ChartPosition.top], [ChartPosition.left],
  /// [ChartPosition.bottom], [ChartPosition.right] and
  /// [ChartPosition.center]. The default is the bottom for an x axis and
  /// the left for a y axis. The position at a value of another axis
  /// (`{x: 0}`) goes through [extra].
  final ChartPosition? position;

  /// Whether the axis runs in the other direction: `reverse`.
  final bool? reverse;

  /// Whether the datasets of the axis stack: `stacked` as a boolean
  /// (`docs/charts/bar.md`, "Stacked Bar Chart"). The value `'single'` goes
  /// through [extra].
  final bool? stacked;

  /// The tick marks and the tick labels: `ticks`.
  final AxisTicks? ticks;

  /// The grid lines: `grid`.
  final AxisGrid? grid;

  /// The title of the axis: `title`.
  final AxisTitle? title;

  /// The Chart.js options of the axis that have no parameter, for example
  /// `{'grace': '5%'}`.
  ///
  /// The entries go into the axis Map last: an entry wins over a parameter
  /// with the same key. A Map value merges into the Map of the key, a List
  /// or another value replaces it. The chart gets a copy of each Map and the
  /// Lists of the app.
  final Map<String, Object?>? extra;

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

  /// Adds the keys of the axis class to [map], after the keys of
  /// [ChartAxis] before [ticks].
  void _lowerOwn(Map<String, Object?> map);

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

/// The axis Map of [axis] (Chart.js ADR 0052, section 2): `type` first,
/// then the keys in parameter order, and [ChartAxis.extra] last.
@internal
Map<String, Object?> lowerAxis(ChartAxis axis) {
  final map = <String, Object?>{
    'type': axis._type,
    'display': ?axis.display,
    'position': ?axis.position?.name,
    'reverse': ?axis.reverse,
    'stacked': ?axis.stacked,
  };
  axis._lowerOwn(map);
  map.addAll({
    'ticks': ?_lowerTicks(axis.ticks),
    'grid': ?_lowerGrid(axis.grid),
    'title': ?_lowerTitle(axis.title),
  });
  return mergeExtra(map, axis.extra);
}

/// A category axis: the scale type `category` (`docs/axes/cartesian/
/// category.md`). It shows the labels of the chart in order. It is the
/// default index axis of a bar and a line chart.
final class CategoryAxis extends ChartAxis {
  /// A category axis.
  const CategoryAxis({
    super.display,
    super.position,
    super.reverse,
    super.stacked,
    this.labels,
    this.min,
    this.max,
    super.ticks,
    super.grid,
    super.title,
    super.extra,
  });

  /// The labels of this axis, in place of the labels of the chart:
  /// `labels`. The List goes to the chart by reference.
  final List<Object>? labels;

  /// The first label that the axis shows: `min`.
  final String? min;

  /// The last label that the axis shows: `max`.
  final String? max;

  @override
  CategoryAxis copyWith({
    bool? display,
    ChartPosition? position,
    bool? reverse,
    bool? stacked,
    List<Object>? labels,
    String? min,
    String? max,
    AxisTicks? ticks,
    AxisGrid? grid,
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
    ticks: ticks ?? this.ticks,
    grid: grid ?? this.grid,
    title: title ?? this.title,
    extra: extra ?? this.extra,
  );

  @override
  String get _type => 'category';

  @override
  void _lowerOwn(Map<String, Object?> map) =>
      map.addAll({'labels': ?labels, 'min': ?min, 'max': ?max});

  @override
  List<TypedProperty> get _props => [
    ..._headProps,
    ('labels', labels),
    ('min', min),
    ('max', max),
    ..._tailProps,
  ];
}

/// A linear axis: the scale type `linear` (`docs/axes/cartesian/
/// linear.md`). It is the default value axis of a bar and a line chart.
final class LinearAxis extends ChartAxis {
  /// A linear axis.
  const LinearAxis({
    super.display,
    super.position,
    super.reverse,
    super.stacked,
    this.min,
    this.max,
    this.suggestedMin,
    this.suggestedMax,
    this.beginAtZero,
    super.ticks,
    super.grid,
    super.title,
    super.extra,
  });

  /// {@template flutter_chartjs_port.typed.axisMin}
  /// The minimum of the axis: `min`. The data does not change it.
  /// {@endtemplate}
  final double? min;

  /// {@template flutter_chartjs_port.typed.axisMax}
  /// The maximum of the axis: `max`. The data does not change it.
  /// {@endtemplate}
  final double? max;

  /// {@template flutter_chartjs_port.typed.suggestedMin}
  /// A minimum that the data can make smaller: `suggestedMin`.
  /// {@endtemplate}
  final double? suggestedMin;

  /// {@template flutter_chartjs_port.typed.suggestedMax}
  /// A maximum that the data can make larger: `suggestedMax`.
  /// {@endtemplate}
  final double? suggestedMax;

  /// {@template flutter_chartjs_port.typed.beginAtZero}
  /// Whether the axis includes 0: `beginAtZero`. The default of the value
  /// axis of a bar chart is `true`.
  /// {@endtemplate}
  final bool? beginAtZero;

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
    AxisTicks? ticks,
    AxisGrid? grid,
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
    ticks: ticks ?? this.ticks,
    grid: grid ?? this.grid,
    title: title ?? this.title,
    extra: extra ?? this.extra,
  );

  @override
  String get _type => 'linear';

  @override
  void _lowerOwn(Map<String, Object?> map) => map.addAll({
    'min': ?min,
    'max': ?max,
    'suggestedMin': ?suggestedMin,
    'suggestedMax': ?suggestedMax,
    'beginAtZero': ?beginAtZero,
  });

  @override
  List<TypedProperty> get _props => [
    ..._headProps,
    ('min', min),
    ('max', max),
    ('suggestedMin', suggestedMin),
    ('suggestedMax', suggestedMax),
    ('beginAtZero', beginAtZero),
    ..._tailProps,
  ];
}

/// A logarithmic axis: the scale type `logarithmic` (`docs/axes/cartesian/
/// logarithmic.md`). Its values are positive.
final class LogarithmicAxis extends ChartAxis {
  /// A logarithmic axis.
  const LogarithmicAxis({
    super.display,
    super.position,
    super.reverse,
    super.stacked,
    this.min,
    this.max,
    this.suggestedMin,
    this.suggestedMax,
    super.ticks,
    super.grid,
    super.title,
    super.extra,
  });

  /// {@macro flutter_chartjs_port.typed.axisMin}
  final double? min;

  /// {@macro flutter_chartjs_port.typed.axisMax}
  final double? max;

  /// {@macro flutter_chartjs_port.typed.suggestedMin}
  final double? suggestedMin;

  /// {@macro flutter_chartjs_port.typed.suggestedMax}
  final double? suggestedMax;

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
    AxisTicks? ticks,
    AxisGrid? grid,
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
    ticks: ticks ?? this.ticks,
    grid: grid ?? this.grid,
    title: title ?? this.title,
    extra: extra ?? this.extra,
  );

  @override
  String get _type => 'logarithmic';

  @override
  void _lowerOwn(Map<String, Object?> map) => map.addAll({
    'min': ?min,
    'max': ?max,
    'suggestedMin': ?suggestedMin,
    'suggestedMax': ?suggestedMax,
  });

  @override
  List<TypedProperty> get _props => [
    ..._headProps,
    ('min', min),
    ('max', max),
    ('suggestedMin', suggestedMin),
    ('suggestedMax', suggestedMax),
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

  void _lowerTime(Map<String, Object?> map) {
    final time = <String, Object?>{
      'unit': ?unit,
      'tooltipFormat': ?tooltipFormat,
    };
    map.addAll({'min': ?min, 'max': ?max, if (time.isNotEmpty) 'time': time});
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
final class TimeAxis extends ChartAxis with _TimeOptions {
  /// A time axis.
  const TimeAxis({
    super.display,
    super.position,
    super.reverse,
    super.stacked,
    this.min,
    this.max,
    this.unit,
    this.tooltipFormat,
    super.ticks,
    super.grid,
    super.title,
    super.extra,
  });

  /// {@template flutter_chartjs_port.typed.timeMin}
  /// The first time of the axis: `min`.
  /// {@endtemplate}
  @override
  final DateTime? min;

  /// {@template flutter_chartjs_port.typed.timeMax}
  /// The last time of the axis: `max`.
  /// {@endtemplate}
  @override
  final DateTime? max;

  /// {@template flutter_chartjs_port.typed.unit}
  /// The time unit of the ticks: `time.unit`, for example `'day'` or
  /// `'month'`. The default unit fits the range of the data.
  /// {@endtemplate}
  @override
  final TimeUnit? unit;

  /// {@template flutter_chartjs_port.typed.tooltipFormat}
  /// The date format of the times in the tooltip: `time.tooltipFormat`, an
  /// ICU pattern of the default date adapter, for example `'yyyy-MM-dd'`.
  /// {@endtemplate}
  @override
  final String? tooltipFormat;

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
    AxisTicks? ticks,
    AxisGrid? grid,
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
    ticks: ticks ?? this.ticks,
    grid: grid ?? this.grid,
    title: title ?? this.title,
    extra: extra ?? this.extra,
  );

  @override
  String get _type => 'time';

  @override
  void _lowerOwn(Map<String, Object?> map) => _lowerTime(map);

  @override
  List<TypedProperty> get _props => [
    ..._headProps,
    ..._timeProps,
    ..._tailProps,
  ];
}

/// A time series axis: the scale type `timeseries` (`docs/axes/cartesian/
/// timeseries.md`).
///
/// The axis places the data items at equal distances, in time order. The
/// data has `DateTime` values or numbers in milliseconds since the epoch.
final class TimeSeriesAxis extends ChartAxis with _TimeOptions {
  /// A time series axis.
  const TimeSeriesAxis({
    super.display,
    super.position,
    super.reverse,
    super.stacked,
    this.min,
    this.max,
    this.unit,
    this.tooltipFormat,
    super.ticks,
    super.grid,
    super.title,
    super.extra,
  });

  /// {@macro flutter_chartjs_port.typed.timeMin}
  @override
  final DateTime? min;

  /// {@macro flutter_chartjs_port.typed.timeMax}
  @override
  final DateTime? max;

  /// {@macro flutter_chartjs_port.typed.unit}
  @override
  final TimeUnit? unit;

  /// {@macro flutter_chartjs_port.typed.tooltipFormat}
  @override
  final String? tooltipFormat;

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
    AxisTicks? ticks,
    AxisGrid? grid,
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
    ticks: ticks ?? this.ticks,
    grid: grid ?? this.grid,
    title: title ?? this.title,
    extra: extra ?? this.extra,
  );

  @override
  String get _type => 'timeseries';

  @override
  void _lowerOwn(Map<String, Object?> map) => _lowerTime(map);

  @override
  List<TypedProperty> get _props => [
    ..._headProps,
    ..._timeProps,
    ..._tailProps,
  ];
}

/// A radial linear axis: the scale type `radialLinear` (`docs/axes/radial/
/// linear.md`), the axis `r` of a polar area and a radar chart.
///
/// The labels of the chart are the point labels around the axis. The angle
/// lines go from the center to the point labels.
final class RadialLinearAxis extends ChartAxis {
  /// A radial linear axis.
  const RadialLinearAxis({
    super.display,
    super.position,
    super.reverse,
    super.stacked,
    this.min,
    this.max,
    this.suggestedMin,
    this.suggestedMax,
    this.beginAtZero,
    this.startAngle,
    this.pointLabelsDisplay,
    this.pointLabelsColor,
    this.pointLabelsFont,
    this.pointLabelsPadding,
    this.angleLinesDisplay,
    this.angleLinesColor,
    this.angleLinesLineWidth,
    super.ticks,
    super.grid,
    super.title,
    super.extra,
  });

  /// {@macro flutter_chartjs_port.typed.axisMin}
  final double? min;

  /// {@macro flutter_chartjs_port.typed.axisMax}
  final double? max;

  /// {@macro flutter_chartjs_port.typed.suggestedMin}
  final double? suggestedMin;

  /// {@macro flutter_chartjs_port.typed.suggestedMax}
  final double? suggestedMax;

  /// {@macro flutter_chartjs_port.typed.beginAtZero}
  final bool? beginAtZero;

  /// The angle of the first point label in degrees, from the top,
  /// clockwise: `startAngle`. The default is 0.
  final double? startAngle;

  /// Whether the chart shows the point labels: `pointLabels.display`.
  final bool? pointLabelsDisplay;

  /// The color of the point labels: `pointLabels.color`.
  final Color? pointLabelsColor;

  /// The font of the point labels: `pointLabels.font`. The color of the
  /// font is not read: set [pointLabelsColor].
  final TextStyle? pointLabelsFont;

  /// The space between the chart area and the point labels, in pixels:
  /// `pointLabels.padding`. The default is 5.
  final double? pointLabelsPadding;

  /// Whether the chart shows the lines from the center to the point labels:
  /// `angleLines.display`.
  final bool? angleLinesDisplay;

  /// The color of the lines from the center to the point labels:
  /// `angleLines.color`.
  final Color? angleLinesColor;

  /// The width of the lines from the center to the point labels, in pixels:
  /// `angleLines.lineWidth`. The default is 1.
  final double? angleLinesLineWidth;

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
    Color? pointLabelsColor,
    TextStyle? pointLabelsFont,
    double? pointLabelsPadding,
    bool? angleLinesDisplay,
    Color? angleLinesColor,
    double? angleLinesLineWidth,
    AxisTicks? ticks,
    AxisGrid? grid,
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
    angleLinesDisplay: angleLinesDisplay ?? this.angleLinesDisplay,
    angleLinesColor: angleLinesColor ?? this.angleLinesColor,
    angleLinesLineWidth: angleLinesLineWidth ?? this.angleLinesLineWidth,
    ticks: ticks ?? this.ticks,
    grid: grid ?? this.grid,
    title: title ?? this.title,
    extra: extra ?? this.extra,
  );

  @override
  String get _type => 'radialLinear';

  @override
  void _lowerOwn(Map<String, Object?> map) {
    final pointLabels = <String, Object?>{
      'display': ?pointLabelsDisplay,
      'color': ?colorValue(pointLabelsColor),
      'font': ?fontSpecOf(pointLabelsFont),
      'padding': ?pointLabelsPadding,
    };
    final angleLines = <String, Object?>{
      'display': ?angleLinesDisplay,
      'color': ?colorValue(angleLinesColor),
      'lineWidth': ?angleLinesLineWidth,
    };
    map.addAll({
      'min': ?min,
      'max': ?max,
      'suggestedMin': ?suggestedMin,
      'suggestedMax': ?suggestedMax,
      'beginAtZero': ?beginAtZero,
      'startAngle': ?startAngle,
      if (pointLabels.isNotEmpty) 'pointLabels': pointLabels,
      if (angleLines.isNotEmpty) 'angleLines': angleLines,
    });
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
    ('angleLinesDisplay', angleLinesDisplay),
    ('angleLinesColor', angleLinesColor),
    ('angleLinesLineWidth', angleLinesLineWidth),
    ..._tailProps,
  ];
}

/// The tick marks and the tick labels of an axis: `ticks`
/// (`docs/axes/_common_ticks.md`, `docs/axes/styling.md`).
@immutable
final class AxisTicks with Diagnosticable {
  /// The tick options of an axis.
  const AxisTicks({
    this.display,
    this.color,
    this.font,
    this.padding,
    this.stepSize,
    this.maxRotation,
    this.autoSkip,
    this.format,
    this.extra,
  });

  /// Whether the chart shows the tick labels: `display`.
  final bool? display;

  /// The color of the tick labels: `color`.
  final Color? color;

  /// The font of the tick labels: `font`. The color of the font is not
  /// read: set [color].
  final TextStyle? font;

  /// The space between the tick labels and the axis, in pixels: `padding`.
  final double? padding;

  /// The step between two ticks of a linear axis: `stepSize`.
  final double? stepSize;

  /// The maximum rotation of the tick labels in degrees, to make them fit:
  /// `maxRotation`. The default is 50.
  final double? maxRotation;

  /// Whether the axis skips labels that do not fit: `autoSkip`. The
  /// default is `true`.
  final bool? autoSkip;

  /// The label of each tick: `callback` (`docs/axes/labelling.md`,
  /// "Creating Custom Tick Formats").
  ///
  /// It gets the tick, its index, all ticks and the scale, and gives the
  /// label. `null` hides the label. For a category axis, the value is the
  /// index of the label: `tick.scale.getLabelForValue(tick.value)` gives
  /// the label. Use a method tear-off or a function in a field: a new
  /// closure in each build is a new value, and the chart then updates.
  final String? Function(AxisTickInfo tick)? format;

  /// The Chart.js tick options that have no parameter, for example
  /// `{'precision': 0}`. The rules of [ChartAxis.extra] apply.
  final Map<String, Object?>? extra;

  /// A copy of these tick options with the given parameters. A parameter
  /// that is `null` keeps its value.
  AxisTicks copyWith({
    bool? display,
    Color? color,
    TextStyle? font,
    double? padding,
    double? stepSize,
    double? maxRotation,
    bool? autoSkip,
    String? Function(AxisTickInfo tick)? format,
    Map<String, Object?>? extra,
  }) => AxisTicks(
    display: display ?? this.display,
    color: color ?? this.color,
    font: font ?? this.font,
    padding: padding ?? this.padding,
    stepSize: stepSize ?? this.stepSize,
    maxRotation: maxRotation ?? this.maxRotation,
    autoSkip: autoSkip ?? this.autoSkip,
    format: format ?? this.format,
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
    ('format', format),
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

/// The `ticks` Map of [ticks], or Dart `null`.
Map<String, Object?>? _lowerTicks(AxisTicks? ticks) {
  if (ticks == null) return null;
  final format = ticks.format;
  return mergeExtra(<String, Object?>{
    'display': ?ticks.display,
    'color': ?colorValue(ticks.color),
    'font': ?fontSpecOf(ticks.font),
    'padding': ?ticks.padding,
    'stepSize': ?ticks.stepSize,
    'maxRotation': ?ticks.maxRotation,
    'autoSkip': ?ticks.autoSkip,
    'callback': ?(format == null ? null : _tickCallback(format)),
  }, ticks.extra);
}

/// The tick `callback` of [format]: a [JsFunction], so that the scale is
/// the `this` of the call (`core.scale.js:574`). The arguments are the
/// value, the index as a number and the ticks.
JsFunction _tickCallback(String? Function(AxisTickInfo tick) format) =>
    JsFunction(
      (Object? scale, Object? value, Object? index, Object? ticks) => format(
        AxisTickInfo(
          value: (value! as num).toDouble(),
          index: (index! as num).toInt(),
          ticks: ticks! as List<Tick>,
          scale: scale! as Scale,
        ),
      ),
    );

/// The grid lines of an axis: `grid` (`docs/axes/styling.md`, "Grid Line
/// Configuration").
@immutable
final class AxisGrid with Diagnosticable {
  /// The grid options of an axis.
  const AxisGrid({
    this.display,
    this.color,
    this.lineWidth,
    this.drawOnChartArea,
    this.drawTicks,
    this.offset,
    this.extra,
  });

  /// Whether the chart draws the grid lines: `display`.
  final bool? display;

  /// The color of the grid lines: `color`.
  final Color? color;

  /// The width of the grid lines in pixels: `lineWidth`.
  final double? lineWidth;

  /// Whether the grid lines go across the chart area: `drawOnChartArea`.
  /// With `false`, the chart draws only the tick marks.
  final bool? drawOnChartArea;

  /// Whether the chart draws the tick marks next to the tick labels:
  /// `drawTicks`.
  final bool? drawTicks;

  /// Whether the grid lines are between the labels, not at them: `offset`.
  /// The default of the index axis of a bar chart is `true`.
  final bool? offset;

  /// The Chart.js grid options that have no parameter, for example
  /// `{'tickLength': 4}`. The rules of [ChartAxis.extra] apply.
  final Map<String, Object?>? extra;

  /// A copy of these grid options with the given parameters. A parameter
  /// that is `null` keeps its value.
  AxisGrid copyWith({
    bool? display,
    Color? color,
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

/// The `grid` Map of [grid], or Dart `null`.
Map<String, Object?>? _lowerGrid(AxisGrid? grid) => grid == null
    ? null
    : mergeExtra(<String, Object?>{
        'display': ?grid.display,
        'color': ?colorValue(grid.color),
        'lineWidth': ?grid.lineWidth,
        'drawOnChartArea': ?grid.drawOnChartArea,
        'drawTicks': ?grid.drawTicks,
        'offset': ?grid.offset,
      }, grid.extra);

/// The title of an axis: `title` (`docs/axes/labelling.md`, "Scale
/// Title Configuration").
@immutable
final class AxisTitle with Diagnosticable {
  /// The title options of an axis.
  const AxisTitle({
    this.display,
    this.text,
    this.color,
    this.font,
    this.align,
    this.padding,
    this.extra,
  });

  /// Whether the chart shows the title: `display`. The default is `false`.
  final bool? display;

  /// The text of the title: `text`.
  final String? text;

  /// The color of the title: `color`.
  final Color? color;

  /// The font of the title: `font`. The color of the font is not read: set
  /// [color].
  final TextStyle? font;

  /// The alignment of the title along the axis: `align`.
  final ChartAlign? align;

  /// The space around the title: `padding`. Chart.js reads the top and the
  /// bottom.
  final EdgeInsets? padding;

  /// The Chart.js title options that have no parameter. The rules of
  /// [ChartAxis.extra] apply.
  final Map<String, Object?>? extra;

  /// A copy of these title options with the given parameters. A parameter
  /// that is `null` keeps its value.
  AxisTitle copyWith({
    bool? display,
    String? text,
    Color? color,
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

/// The `title` Map of [title], or Dart `null`.
Map<String, Object?>? _lowerTitle(AxisTitle? title) => title == null
    ? null
    : mergeExtra(<String, Object?>{
        'display': ?title.display,
        'text': ?title.text,
        'color': ?colorValue(title.color),
        'font': ?fontSpecOf(title.font),
        'align': ?title.align?.name,
        'padding': ?paddingValue(title.padding),
      }, title.extra);
