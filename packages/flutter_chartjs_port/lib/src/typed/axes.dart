// Original code, not ported from Chart.js: the axes of the typed API.

/// The axes of the typed API (Chart.js ADR 0052, sections 1 and 7):
/// [ChartAxis], one axis class for each scale type of Chart.js, and the
/// axis parts [AxisTicks], [AxisGrid], [AxisTitle] and
/// [TimeDisplayFormats].
///
/// An axis is an item of the `scales` List of `ChartConfig`. The axis class
/// gives the scale type (`docs/axes/index.md`), and a cartesian axis takes its
/// direction first: `LinearAxis(.y)`. The lowering gives each axis its scale
/// id (Chart.js ADR 0191).
library;

import 'package:flutter/foundation.dart'
    show DiagnosticPropertiesBuilder, Diagnosticable, immutable;
import 'package:flutter/painting.dart' show EdgeInsets, TextStyle;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:intl/intl.dart' show NumberFormat;

/// An axis of a chart: an entry of `options.scales` of a Chart.js config
/// (`docs/axes/index.md`).
///
/// Each scale type has its axis class: [CategoryAxis], [LinearAxis],
/// [LogarithmicAxis], [TimeAxis], [TimeSeriesAxis] and [RadialLinearAxis].
/// The class gives the `type` of the scale. A cartesian chart (bar, line,
/// scatter, bubble) has x and y axes: `CategoryAxis(.x)`, `LinearAxis(.y)`.
/// A radial chart (polar area, radar) has one [RadialLinearAxis].
///
/// A parameter that is `null` is not set: the chart uses the default of
/// Chart.js. The keys that this class does not have go through [extra].
///
/// An axis is immutable. `==` compares the parameters: [CategoryAxis.labels]
/// by identity, and [AxisTicks.callback] with `==`.
@immutable
abstract final class const ChartAxis({
  /// Whether the chart shows the axis: `display`. The default is
  /// [ScaleDisplay.on]. [ScaleDisplay.auto] shows the axis when one of its
  /// datasets is visible (row `adapt-scale-display-enum`).
  final ScaleDisplay? display,

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

  /// Whether the datasets of the axis stack: `stacked`
  /// (`docs/charts/bar.md`, "Stacked Bar Chart"). Null stacks the datasets
  /// that have a `stack` (row `adapt-stacked-option-enum`).
  final StackMode? stacked,

  /// Whether the scale aligns its pixel values to the device pixels:
  /// `alignToPixels`.
  final bool? alignToPixels,

  /// The color of the area of the axis: `backgroundColor`.
  final ChartPaint? backgroundColor,

  /// Whether the chart clips the datasets of the axis to the chart area:
  /// `clip`. The default is `true`.
  final bool? clip,

  /// The order of the axis among the axes of one side: `weight`. A larger
  /// weight is farther from the chart area.
  final double? weight,

  /// A function that the scale calls before it updates: `beforeUpdate`
  /// (`docs/axes/index.md`, "Callbacks").
  final ScaleHook? beforeUpdate,

  /// A function that the scale calls before it sets its size:
  /// `beforeSetDimensions` (`docs/axes/index.md`, "Callbacks").
  final ScaleHook? beforeSetDimensions,

  /// A function that the scale calls after it sets its size:
  /// `afterSetDimensions` (`docs/axes/index.md`, "Callbacks").
  final ScaleHook? afterSetDimensions,

  /// A function that the scale calls before it computes its data range:
  /// `beforeDataLimits` (`docs/axes/index.md`, "Callbacks").
  final ScaleHook? beforeDataLimits,

  /// A function that the scale calls after it computes its data range:
  /// `afterDataLimits` (`docs/axes/index.md`, "Callbacks").
  final ScaleHook? afterDataLimits,

  /// A function that the scale calls before it makes its ticks:
  /// `beforeBuildTicks` (`docs/axes/index.md`, "Callbacks").
  final ScaleHook? beforeBuildTicks,

  /// A function that the scale calls after it makes its ticks:
  /// `afterBuildTicks` (`docs/axes/index.md`, "Callbacks").
  final ScaleHook? afterBuildTicks,

  /// A function that the scale calls before it makes the tick labels:
  /// `beforeTickToLabelConversion` (`docs/axes/index.md`, "Callbacks").
  final ScaleHook? beforeTickToLabelConversion,

  /// A function that the scale calls after it makes the tick labels:
  /// `afterTickToLabelConversion` (`docs/axes/index.md`, "Callbacks").
  final ScaleHook? afterTickToLabelConversion,

  /// A function that the scale calls before it computes the label rotation:
  /// `beforeCalculateLabelRotation` (`docs/axes/index.md`, "Callbacks").
  final ScaleHook? beforeCalculateLabelRotation,

  /// A function that the scale calls after it computes the label rotation:
  /// `afterCalculateLabelRotation` (`docs/axes/index.md`, "Callbacks").
  final ScaleHook? afterCalculateLabelRotation,

  /// A function that the scale calls before it fits its size: `beforeFit`
  /// (`docs/axes/index.md`, "Callbacks").
  final ScaleHook? beforeFit,

  /// A function that the scale calls after it fits its size: `afterFit`
  /// (`docs/axes/index.md`, "Callbacks").
  final ScaleHook? afterFit,

  /// A function that the scale calls after it updates: `afterUpdate`
  /// (`docs/axes/index.md`, "Callbacks").
  final ScaleHook? afterUpdate,

  /// The tick marks and the tick labels: `ticks`.
  final AxisTicks? ticks,

  /// The grid lines: `grid`.
  final AxisGrid? grid,

  /// The title of the axis: `title`.
  final AxisTitle? title,

  /// The Chart.js options of the axis that have no parameter, for example
  /// `{'time': {'round': TimeUnit.day}}`.
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

  /// The direction of the axis: [XAxis] or [YAxis] for a cartesian axis,
  /// [RAxis] for [RadialLinearAxis] (Chart.js ADR 0191). The lowering gives
  /// the first axis of a direction the scale id `x`, `y` or `r`.
  ScaleAxis get axis;

  /// A copy of this axis with the given parameters. A parameter that is
  /// `null` keeps its value.
  ChartAxis copyWith({
    ScaleDisplay? display,
    ChartPosition? position,
    bool? reverse,
    StackMode? stacked,
    bool? alignToPixels,
    ChartPaint? backgroundColor,
    bool? clip,
    double? weight,
    ScaleHook? beforeUpdate,
    ScaleHook? beforeSetDimensions,
    ScaleHook? afterSetDimensions,
    ScaleHook? beforeDataLimits,
    ScaleHook? afterDataLimits,
    ScaleHook? beforeBuildTicks,
    ScaleHook? afterBuildTicks,
    ScaleHook? beforeTickToLabelConversion,
    ScaleHook? afterTickToLabelConversion,
    ScaleHook? beforeCalculateLabelRotation,
    ScaleHook? afterCalculateLabelRotation,
    ScaleHook? beforeFit,
    ScaleHook? afterFit,
    ScaleHook? afterUpdate,
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
    ('axis', axis),
    ('display', display),
    ('position', position),
    ('reverse', reverse),
    ('stacked', stacked),
  ];

  /// The properties of [ChartAxis] after the parameters of the class.
  List<TypedProperty> get _tailProps => [
    ('alignToPixels', alignToPixels),
    ('backgroundColor', backgroundColor),
    ('clip', clip),
    ('weight', weight),
    ('beforeUpdate', beforeUpdate),
    ('beforeSetDimensions', beforeSetDimensions),
    ('afterSetDimensions', afterSetDimensions),
    ('beforeDataLimits', beforeDataLimits),
    ('afterDataLimits', afterDataLimits),
    ('beforeBuildTicks', beforeBuildTicks),
    ('afterBuildTicks', afterBuildTicks),
    ('beforeTickToLabelConversion', beforeTickToLabelConversion),
    ('afterTickToLabelConversion', afterTickToLabelConversion),
    ('beforeCalculateLabelRotation', beforeCalculateLabelRotation),
    ('afterCalculateLabelRotation', afterCalculateLabelRotation),
    ('beforeFit', beforeFit),
    ('afterFit', afterFit),
    ('afterUpdate', afterUpdate),
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
/// parameter order, and [ChartAxis.extra] last. With [writeAxis], the
/// option `axis` follows `type`: the id of the axis does not name its
/// direction (Chart.js ADR 0191, item 3).
ScaleOptionsScope lowerAxis(ChartAxis axis, {bool writeAxis = false}) {
  final scope = ScaleOptionsScope()..type = axis._type;
  if (writeAxis) put(scope, OptionKey.axis, axis.axis);
  put(scope, OptionKey.display, axis.display);
  put(scope, OptionKey.position, axis.position);
  put(scope, OptionKey.reverse, axis.reverse);
  put(scope, OptionKey.stacked, axis.stacked);
  axis._lowerOwn(scope);
  put(scope, OptionKey.alignToPixels, axis.alignToPixels);
  put(scope, OptionKey.backgroundColor, axis.backgroundColor);
  put(scope, OptionKey.clip, axis.clip);
  put(scope, OptionKey.weight, axis.weight);
  put(scope, OptionKey.beforeUpdate, axis.beforeUpdate);
  put(scope, OptionKey.beforeSetDimensions, axis.beforeSetDimensions);
  put(scope, OptionKey.afterSetDimensions, axis.afterSetDimensions);
  put(scope, OptionKey.beforeDataLimits, axis.beforeDataLimits);
  put(scope, OptionKey.afterDataLimits, axis.afterDataLimits);
  put(scope, OptionKey.beforeBuildTicks, axis.beforeBuildTicks);
  put(scope, OptionKey.afterBuildTicks, axis.afterBuildTicks);
  put(
    scope,
    OptionKey.beforeTickToLabelConversion,
    axis.beforeTickToLabelConversion,
  );
  put(
    scope,
    OptionKey.afterTickToLabelConversion,
    axis.afterTickToLabelConversion,
  );
  put(
    scope,
    OptionKey.beforeCalculateLabelRotation,
    axis.beforeCalculateLabelRotation,
  );
  put(
    scope,
    OptionKey.afterCalculateLabelRotation,
    axis.afterCalculateLabelRotation,
  );
  put(scope, OptionKey.beforeFit, axis.beforeFit);
  put(scope, OptionKey.afterFit, axis.afterFit);
  put(scope, OptionKey.afterUpdate, axis.afterUpdate);
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
final class const CategoryAxis(
  /// {@template flutter_chartjs_port.typed.axisDirection}
  /// The direction of the axis: [CartesianAxis.x] (`.x`) or
  /// [CartesianAxis.y] (`.y`). The first axis of a direction has the
  /// scale id `x` or `y` (Chart.js ADR 0191).
  /// {@endtemplate}
  @override final CartesianAxis axis, {
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

  /// Whether the axis adds half a category of space at each end: `offset`. The
  /// default of the index axis of a bar chart is `true`.
  final bool? offset,

  /// The group of the axis: `stack`. The axes of one side with the same group
  /// share its length (`docs/axes/cartesian/index.md`, "Common options").
  final String? stack,

  /// The share of the axis in its [stack] group: `stackWeight`. The default is
  /// 1.
  final double? stackWeight,

  super.alignToPixels,
  super.backgroundColor,
  super.clip,
  super.weight,
  super.beforeUpdate,
  super.beforeSetDimensions,
  super.afterSetDimensions,
  super.beforeDataLimits,
  super.afterDataLimits,
  super.beforeBuildTicks,
  super.afterBuildTicks,
  super.beforeTickToLabelConversion,
  super.afterTickToLabelConversion,
  super.beforeCalculateLabelRotation,
  super.afterCalculateLabelRotation,
  super.beforeFit,
  super.afterFit,
  super.afterUpdate,
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
    CartesianAxis? axis,
    ScaleDisplay? display,
    ChartPosition? position,
    bool? reverse,
    StackMode? stacked,
    List<Object>? labels,
    String? min,
    String? max,
    ScaleBounds? bounds,
    bool? offset,
    String? stack,
    double? stackWeight,
    bool? alignToPixels,
    ChartPaint? backgroundColor,
    bool? clip,
    double? weight,
    ScaleHook? beforeUpdate,
    ScaleHook? beforeSetDimensions,
    ScaleHook? afterSetDimensions,
    ScaleHook? beforeDataLimits,
    ScaleHook? afterDataLimits,
    ScaleHook? beforeBuildTicks,
    ScaleHook? afterBuildTicks,
    ScaleHook? beforeTickToLabelConversion,
    ScaleHook? afterTickToLabelConversion,
    ScaleHook? beforeCalculateLabelRotation,
    ScaleHook? afterCalculateLabelRotation,
    ScaleHook? beforeFit,
    ScaleHook? afterFit,
    ScaleHook? afterUpdate,
    AxisTicks? ticks,
    AxisGrid? grid,
    AxisBorder? border,
    AxisTitle? title,
    Map<String, Object?>? extra,
  }) => CategoryAxis(
    axis ?? this.axis,
    display: display ?? this.display,
    position: position ?? this.position,
    reverse: reverse ?? this.reverse,
    stacked: stacked ?? this.stacked,
    labels: labels ?? this.labels,
    min: min ?? this.min,
    max: max ?? this.max,
    bounds: bounds ?? this.bounds,
    offset: offset ?? this.offset,
    stack: stack ?? this.stack,
    stackWeight: stackWeight ?? this.stackWeight,
    alignToPixels: alignToPixels ?? this.alignToPixels,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    clip: clip ?? this.clip,
    weight: weight ?? this.weight,
    beforeUpdate: beforeUpdate ?? this.beforeUpdate,
    beforeSetDimensions: beforeSetDimensions ?? this.beforeSetDimensions,
    afterSetDimensions: afterSetDimensions ?? this.afterSetDimensions,
    beforeDataLimits: beforeDataLimits ?? this.beforeDataLimits,
    afterDataLimits: afterDataLimits ?? this.afterDataLimits,
    beforeBuildTicks: beforeBuildTicks ?? this.beforeBuildTicks,
    afterBuildTicks: afterBuildTicks ?? this.afterBuildTicks,
    beforeTickToLabelConversion:
        beforeTickToLabelConversion ?? this.beforeTickToLabelConversion,
    afterTickToLabelConversion:
        afterTickToLabelConversion ?? this.afterTickToLabelConversion,
    beforeCalculateLabelRotation:
        beforeCalculateLabelRotation ?? this.beforeCalculateLabelRotation,
    afterCalculateLabelRotation:
        afterCalculateLabelRotation ?? this.afterCalculateLabelRotation,
    beforeFit: beforeFit ?? this.beforeFit,
    afterFit: afterFit ?? this.afterFit,
    afterUpdate: afterUpdate ?? this.afterUpdate,
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
    put(scope, OptionKey.offset, offset);
    put(scope, OptionKey.stack, stack);
    put(scope, OptionKey.stackWeight, stackWeight);
  }

  @override
  List<TypedProperty> get _props => [
    ..._headProps,
    ('labels', labels),
    ('min', min),
    ('max', max),
    ('bounds', bounds),
    ('offset', offset),
    ('stack', stack),
    ('stackWeight', stackWeight),
    ..._tailProps,
  ];
}

/// A linear axis: the scale type `linear` (`docs/axes/cartesian/
/// linear.md`). It is the default value axis of a bar and a line chart.
final class const LinearAxis(
  /// {@macro flutter_chartjs_port.typed.axisDirection}
  @override final CartesianAxis axis, {
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

  /// Whether the axis adds half a category of space at each end: `offset`. The
  /// default of the index axis of a bar chart is `true`.
  final bool? offset,

  /// The group of the axis: `stack`. The axes of one side with the same group
  /// share its length (`docs/axes/cartesian/index.md`, "Common options").
  final String? stack,

  /// The share of the axis in its [stack] group: `stackWeight`. The default is
  /// 1.
  final double? stackWeight,

  /// The space above the data range and below it: `grace`, for example
  /// `PercentGrace(5)` (row `adapt-length-objects`).
  final GraceLength? grace,

  super.alignToPixels,
  super.backgroundColor,
  super.clip,
  super.weight,
  super.beforeUpdate,
  super.beforeSetDimensions,
  super.afterSetDimensions,
  super.beforeDataLimits,
  super.afterDataLimits,
  super.beforeBuildTicks,
  super.afterBuildTicks,
  super.beforeTickToLabelConversion,
  super.afterTickToLabelConversion,
  super.beforeCalculateLabelRotation,
  super.afterCalculateLabelRotation,
  super.beforeFit,
  super.afterFit,
  super.afterUpdate,
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
    CartesianAxis? axis,
    ScaleDisplay? display,
    ChartPosition? position,
    bool? reverse,
    StackMode? stacked,
    double? min,
    double? max,
    double? suggestedMin,
    double? suggestedMax,
    bool? beginAtZero,
    ScaleBounds? bounds,
    bool? offset,
    String? stack,
    double? stackWeight,
    GraceLength? grace,
    bool? alignToPixels,
    ChartPaint? backgroundColor,
    bool? clip,
    double? weight,
    ScaleHook? beforeUpdate,
    ScaleHook? beforeSetDimensions,
    ScaleHook? afterSetDimensions,
    ScaleHook? beforeDataLimits,
    ScaleHook? afterDataLimits,
    ScaleHook? beforeBuildTicks,
    ScaleHook? afterBuildTicks,
    ScaleHook? beforeTickToLabelConversion,
    ScaleHook? afterTickToLabelConversion,
    ScaleHook? beforeCalculateLabelRotation,
    ScaleHook? afterCalculateLabelRotation,
    ScaleHook? beforeFit,
    ScaleHook? afterFit,
    ScaleHook? afterUpdate,
    AxisTicks? ticks,
    AxisGrid? grid,
    AxisBorder? border,
    AxisTitle? title,
    Map<String, Object?>? extra,
  }) => LinearAxis(
    axis ?? this.axis,
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
    offset: offset ?? this.offset,
    stack: stack ?? this.stack,
    stackWeight: stackWeight ?? this.stackWeight,
    grace: grace ?? this.grace,
    alignToPixels: alignToPixels ?? this.alignToPixels,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    clip: clip ?? this.clip,
    weight: weight ?? this.weight,
    beforeUpdate: beforeUpdate ?? this.beforeUpdate,
    beforeSetDimensions: beforeSetDimensions ?? this.beforeSetDimensions,
    afterSetDimensions: afterSetDimensions ?? this.afterSetDimensions,
    beforeDataLimits: beforeDataLimits ?? this.beforeDataLimits,
    afterDataLimits: afterDataLimits ?? this.afterDataLimits,
    beforeBuildTicks: beforeBuildTicks ?? this.beforeBuildTicks,
    afterBuildTicks: afterBuildTicks ?? this.afterBuildTicks,
    beforeTickToLabelConversion:
        beforeTickToLabelConversion ?? this.beforeTickToLabelConversion,
    afterTickToLabelConversion:
        afterTickToLabelConversion ?? this.afterTickToLabelConversion,
    beforeCalculateLabelRotation:
        beforeCalculateLabelRotation ?? this.beforeCalculateLabelRotation,
    afterCalculateLabelRotation:
        afterCalculateLabelRotation ?? this.afterCalculateLabelRotation,
    beforeFit: beforeFit ?? this.beforeFit,
    afterFit: afterFit ?? this.afterFit,
    afterUpdate: afterUpdate ?? this.afterUpdate,
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
    put(scope, OptionKey.offset, offset);
    put(scope, OptionKey.stack, stack);
    put(scope, OptionKey.stackWeight, stackWeight);
    put(scope, OptionKey.grace, grace);
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
    ('offset', offset),
    ('stack', stack),
    ('stackWeight', stackWeight),
    ('grace', grace),
    ..._tailProps,
  ];
}

/// A logarithmic axis: the scale type `logarithmic` (`docs/axes/cartesian/
/// logarithmic.md`). Its values are positive.
final class const LogarithmicAxis(
  /// {@macro flutter_chartjs_port.typed.axisDirection}
  @override final CartesianAxis axis, {
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

  /// Whether the axis adds half a category of space at each end: `offset`. The
  /// default of the index axis of a bar chart is `true`.
  final bool? offset,

  /// The group of the axis: `stack`. The axes of one side with the same group
  /// share its length (`docs/axes/cartesian/index.md`, "Common options").
  final String? stack,

  /// The share of the axis in its [stack] group: `stackWeight`. The default is
  /// 1.
  final double? stackWeight,

  super.alignToPixels,
  super.backgroundColor,
  super.clip,
  super.weight,
  super.beforeUpdate,
  super.beforeSetDimensions,
  super.afterSetDimensions,
  super.beforeDataLimits,
  super.afterDataLimits,
  super.beforeBuildTicks,
  super.afterBuildTicks,
  super.beforeTickToLabelConversion,
  super.afterTickToLabelConversion,
  super.beforeCalculateLabelRotation,
  super.afterCalculateLabelRotation,
  super.beforeFit,
  super.afterFit,
  super.afterUpdate,
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
    CartesianAxis? axis,
    ScaleDisplay? display,
    ChartPosition? position,
    bool? reverse,
    StackMode? stacked,
    double? min,
    double? max,
    double? suggestedMin,
    double? suggestedMax,
    ScaleBounds? bounds,
    bool? offset,
    String? stack,
    double? stackWeight,
    bool? alignToPixels,
    ChartPaint? backgroundColor,
    bool? clip,
    double? weight,
    ScaleHook? beforeUpdate,
    ScaleHook? beforeSetDimensions,
    ScaleHook? afterSetDimensions,
    ScaleHook? beforeDataLimits,
    ScaleHook? afterDataLimits,
    ScaleHook? beforeBuildTicks,
    ScaleHook? afterBuildTicks,
    ScaleHook? beforeTickToLabelConversion,
    ScaleHook? afterTickToLabelConversion,
    ScaleHook? beforeCalculateLabelRotation,
    ScaleHook? afterCalculateLabelRotation,
    ScaleHook? beforeFit,
    ScaleHook? afterFit,
    ScaleHook? afterUpdate,
    AxisTicks? ticks,
    AxisGrid? grid,
    AxisBorder? border,
    AxisTitle? title,
    Map<String, Object?>? extra,
  }) => LogarithmicAxis(
    axis ?? this.axis,
    display: display ?? this.display,
    position: position ?? this.position,
    reverse: reverse ?? this.reverse,
    stacked: stacked ?? this.stacked,
    min: min ?? this.min,
    max: max ?? this.max,
    suggestedMin: suggestedMin ?? this.suggestedMin,
    suggestedMax: suggestedMax ?? this.suggestedMax,
    bounds: bounds ?? this.bounds,
    offset: offset ?? this.offset,
    stack: stack ?? this.stack,
    stackWeight: stackWeight ?? this.stackWeight,
    alignToPixels: alignToPixels ?? this.alignToPixels,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    clip: clip ?? this.clip,
    weight: weight ?? this.weight,
    beforeUpdate: beforeUpdate ?? this.beforeUpdate,
    beforeSetDimensions: beforeSetDimensions ?? this.beforeSetDimensions,
    afterSetDimensions: afterSetDimensions ?? this.afterSetDimensions,
    beforeDataLimits: beforeDataLimits ?? this.beforeDataLimits,
    afterDataLimits: afterDataLimits ?? this.afterDataLimits,
    beforeBuildTicks: beforeBuildTicks ?? this.beforeBuildTicks,
    afterBuildTicks: afterBuildTicks ?? this.afterBuildTicks,
    beforeTickToLabelConversion:
        beforeTickToLabelConversion ?? this.beforeTickToLabelConversion,
    afterTickToLabelConversion:
        afterTickToLabelConversion ?? this.afterTickToLabelConversion,
    beforeCalculateLabelRotation:
        beforeCalculateLabelRotation ?? this.beforeCalculateLabelRotation,
    afterCalculateLabelRotation:
        afterCalculateLabelRotation ?? this.afterCalculateLabelRotation,
    beforeFit: beforeFit ?? this.beforeFit,
    afterFit: afterFit ?? this.afterFit,
    afterUpdate: afterUpdate ?? this.afterUpdate,
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
    put(scope, OptionKey.offset, offset);
    put(scope, OptionKey.stack, stack);
    put(scope, OptionKey.stackWeight, stackWeight);
  }

  @override
  List<TypedProperty> get _props => [
    ..._headProps,
    ('min', min),
    ('max', max),
    ('suggestedMin', suggestedMin),
    ('suggestedMax', suggestedMax),
    ('bounds', bounds),
    ('offset', offset),
    ('stack', stack),
    ('stackWeight', stackWeight),
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
  TimeDisplayFormats? get displayFormats;
  bool? get offsetAfterAutoskip;
  String? get parser;
  TimeParser? get parserFunction;
  TimeUnit? get round;
  TimeUnit? get minUnit;
  int? get isoWeekday;

  void _lowerTime(ScaleOptionsScope scope) {
    assert(
      parser == null || parserFunction == null,
      'Give parser or parserFunction, not both.',
    );
    final time = TimeScaleTimeOptionsScope();
    put(time, OptionKey.parser, parser ?? parserFunction);
    put(time, OptionKey.round, round);
    put(time, OptionKey.isoWeekday, isoWeekday);
    put(time, OptionKey.unit, unit);
    put(time, OptionKey.minUnit, minUnit);
    put(time, OptionKey.tooltipFormat, tooltipFormat);
    if (_lowerDisplayFormats(displayFormats) case final formats?) {
      time.displayFormats = formats;
    }
    put(scope, OptionKey.min, min);
    put(scope, OptionKey.max, max);
    put(scope, OptionKey.offsetAfterAutoskip, offsetAfterAutoskip);
    if (time.ownKeyCount != 0) scope.time = time;
  }

  List<TypedProperty> get _timeProps => [
    ('min', min),
    ('max', max),
    ('unit', unit),
    ('tooltipFormat', tooltipFormat),
    ('displayFormats', displayFormats),
    ('offsetAfterAutoskip', offsetAfterAutoskip),
    ('parser', parser),
    ('parserFunction', parserFunction),
    ('round', round),
    ('minUnit', minUnit),
    ('isoWeekday', isoWeekday),
  ];
}

/// A time axis: the scale type `time` (`docs/axes/cartesian/time.md`).
///
/// The axis places each data item at its time. The data has `DateTime`
/// values, for example `DataPoint.time` items, or numbers in milliseconds
/// since the epoch. The default date adapter formats the ticks.
final class const TimeAxis(
  /// {@macro flutter_chartjs_port.typed.axisDirection}
  @override final CartesianAxis axis, {
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

  /// {@template flutter_chartjs_port.typed.displayFormats}
  /// The date format of the tick labels of each time unit:
  /// `time.displayFormats`, for example `TimeDisplayFormats(day: 'dd MMM')`.
  /// A unit with no format takes the format of the date adapter.
  /// {@endtemplate}
  @override final TimeDisplayFormats? displayFormats,

  /// {@template flutter_chartjs_port.typed.offsetAfterAutoskip}
  /// Whether the axis computes its offsets again from the ticks that the
  /// auto skip keeps: `offsetAfterAutoskip`
  /// (`docs/axes/cartesian/time.md`), for the bars of a bar chart. The
  /// default is `false`.
  /// {@endtemplate}
  @override final bool? offsetAfterAutoskip,

  /// The date format of the data texts: `time.parser`, an ICU pattern of
  /// the default date adapter, for example `'yyyy-MM-dd'`. Give this or
  /// [parserFunction].
  @override final String? parser,

  /// A function that converts each data value to a time: the function form
  /// of `time.parser`. Give this or [parser].
  @override final TimeParser? parserFunction,

  /// The unit that each time rounds down to: `time.round`. Null keeps the
  /// times.
  @override final TimeUnit? round,

  /// The smallest unit of the ticks: `time.minUnit`. The default is
  /// [TimeUnit.millisecond].
  @override final TimeUnit? minUnit,

  /// The first day of a week of [round] `TimeUnit.week`: `time.isoWeekday`,
  /// 1 for Monday to 7 for Sunday. The upstream `true` is 1.
  @override final int? isoWeekday,

  /// {@macro flutter_chartjs_port.typed.bounds}
  final ScaleBounds? bounds,

  /// Whether the axis adds half a category of space at each end: `offset`. The
  /// default of the index axis of a bar chart is `true`.
  final bool? offset,

  /// The group of the axis: `stack`. The axes of one side with the same group
  /// share its length (`docs/axes/cartesian/index.md`, "Common options").
  final String? stack,

  /// The share of the axis in its [stack] group: `stackWeight`. The default is
  /// 1.
  final double? stackWeight,

  super.alignToPixels,
  super.backgroundColor,
  super.clip,
  super.weight,
  super.beforeUpdate,
  super.beforeSetDimensions,
  super.afterSetDimensions,
  super.beforeDataLimits,
  super.afterDataLimits,
  super.beforeBuildTicks,
  super.afterBuildTicks,
  super.beforeTickToLabelConversion,
  super.afterTickToLabelConversion,
  super.beforeCalculateLabelRotation,
  super.afterCalculateLabelRotation,
  super.beforeFit,
  super.afterFit,
  super.afterUpdate,
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
    CartesianAxis? axis,
    ScaleDisplay? display,
    ChartPosition? position,
    bool? reverse,
    StackMode? stacked,
    DateTime? min,
    DateTime? max,
    TimeUnit? unit,
    String? tooltipFormat,
    TimeDisplayFormats? displayFormats,
    bool? offsetAfterAutoskip,
    String? parser,
    TimeParser? parserFunction,
    TimeUnit? round,
    TimeUnit? minUnit,
    int? isoWeekday,
    ScaleBounds? bounds,
    bool? offset,
    String? stack,
    double? stackWeight,
    bool? alignToPixels,
    ChartPaint? backgroundColor,
    bool? clip,
    double? weight,
    ScaleHook? beforeUpdate,
    ScaleHook? beforeSetDimensions,
    ScaleHook? afterSetDimensions,
    ScaleHook? beforeDataLimits,
    ScaleHook? afterDataLimits,
    ScaleHook? beforeBuildTicks,
    ScaleHook? afterBuildTicks,
    ScaleHook? beforeTickToLabelConversion,
    ScaleHook? afterTickToLabelConversion,
    ScaleHook? beforeCalculateLabelRotation,
    ScaleHook? afterCalculateLabelRotation,
    ScaleHook? beforeFit,
    ScaleHook? afterFit,
    ScaleHook? afterUpdate,
    AxisTicks? ticks,
    AxisGrid? grid,
    AxisBorder? border,
    AxisTitle? title,
    Map<String, Object?>? extra,
  }) => TimeAxis(
    axis ?? this.axis,
    display: display ?? this.display,
    position: position ?? this.position,
    reverse: reverse ?? this.reverse,
    stacked: stacked ?? this.stacked,
    min: min ?? this.min,
    max: max ?? this.max,
    unit: unit ?? this.unit,
    tooltipFormat: tooltipFormat ?? this.tooltipFormat,
    displayFormats: displayFormats ?? this.displayFormats,
    offsetAfterAutoskip: offsetAfterAutoskip ?? this.offsetAfterAutoskip,
    parser: parser ?? this.parser,
    parserFunction: parserFunction ?? this.parserFunction,
    round: round ?? this.round,
    minUnit: minUnit ?? this.minUnit,
    isoWeekday: isoWeekday ?? this.isoWeekday,
    bounds: bounds ?? this.bounds,
    offset: offset ?? this.offset,
    stack: stack ?? this.stack,
    stackWeight: stackWeight ?? this.stackWeight,
    alignToPixels: alignToPixels ?? this.alignToPixels,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    clip: clip ?? this.clip,
    weight: weight ?? this.weight,
    beforeUpdate: beforeUpdate ?? this.beforeUpdate,
    beforeSetDimensions: beforeSetDimensions ?? this.beforeSetDimensions,
    afterSetDimensions: afterSetDimensions ?? this.afterSetDimensions,
    beforeDataLimits: beforeDataLimits ?? this.beforeDataLimits,
    afterDataLimits: afterDataLimits ?? this.afterDataLimits,
    beforeBuildTicks: beforeBuildTicks ?? this.beforeBuildTicks,
    afterBuildTicks: afterBuildTicks ?? this.afterBuildTicks,
    beforeTickToLabelConversion:
        beforeTickToLabelConversion ?? this.beforeTickToLabelConversion,
    afterTickToLabelConversion:
        afterTickToLabelConversion ?? this.afterTickToLabelConversion,
    beforeCalculateLabelRotation:
        beforeCalculateLabelRotation ?? this.beforeCalculateLabelRotation,
    afterCalculateLabelRotation:
        afterCalculateLabelRotation ?? this.afterCalculateLabelRotation,
    beforeFit: beforeFit ?? this.beforeFit,
    afterFit: afterFit ?? this.afterFit,
    afterUpdate: afterUpdate ?? this.afterUpdate,
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
    put(scope, OptionKey.offset, offset);
    put(scope, OptionKey.stack, stack);
    put(scope, OptionKey.stackWeight, stackWeight);
  }

  @override
  List<TypedProperty> get _props => [
    ..._headProps,
    ..._timeProps,
    ('bounds', bounds),
    ('offset', offset),
    ('stack', stack),
    ('stackWeight', stackWeight),
    ..._tailProps,
  ];
}

/// A time series axis: the scale type `timeseries` (`docs/axes/cartesian/
/// timeseries.md`).
///
/// The axis places the data items at equal distances, in time order. The
/// data has `DateTime` values or numbers in milliseconds since the epoch.
final class const TimeSeriesAxis(
  /// {@macro flutter_chartjs_port.typed.axisDirection}
  @override final CartesianAxis axis, {
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

  /// {@macro flutter_chartjs_port.typed.displayFormats}
  @override final TimeDisplayFormats? displayFormats,

  /// {@macro flutter_chartjs_port.typed.offsetAfterAutoskip}
  @override final bool? offsetAfterAutoskip,

  /// The date format of the data texts: `time.parser`, an ICU pattern of
  /// the default date adapter, for example `'yyyy-MM-dd'`. Give this or
  /// [parserFunction].
  @override final String? parser,

  /// A function that converts each data value to a time: the function form
  /// of `time.parser`. Give this or [parser].
  @override final TimeParser? parserFunction,

  /// The unit that each time rounds down to: `time.round`. Null keeps the
  /// times.
  @override final TimeUnit? round,

  /// The smallest unit of the ticks: `time.minUnit`. The default is
  /// [TimeUnit.millisecond].
  @override final TimeUnit? minUnit,

  /// The first day of a week of [round] `TimeUnit.week`: `time.isoWeekday`,
  /// 1 for Monday to 7 for Sunday. The upstream `true` is 1.
  @override final int? isoWeekday,

  /// {@macro flutter_chartjs_port.typed.bounds}
  final ScaleBounds? bounds,

  /// Whether the axis adds half a category of space at each end: `offset`. The
  /// default of the index axis of a bar chart is `true`.
  final bool? offset,

  /// The group of the axis: `stack`. The axes of one side with the same group
  /// share its length (`docs/axes/cartesian/index.md`, "Common options").
  final String? stack,

  /// The share of the axis in its [stack] group: `stackWeight`. The default is
  /// 1.
  final double? stackWeight,

  super.alignToPixels,
  super.backgroundColor,
  super.clip,
  super.weight,
  super.beforeUpdate,
  super.beforeSetDimensions,
  super.afterSetDimensions,
  super.beforeDataLimits,
  super.afterDataLimits,
  super.beforeBuildTicks,
  super.afterBuildTicks,
  super.beforeTickToLabelConversion,
  super.afterTickToLabelConversion,
  super.beforeCalculateLabelRotation,
  super.afterCalculateLabelRotation,
  super.beforeFit,
  super.afterFit,
  super.afterUpdate,
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
    CartesianAxis? axis,
    ScaleDisplay? display,
    ChartPosition? position,
    bool? reverse,
    StackMode? stacked,
    DateTime? min,
    DateTime? max,
    TimeUnit? unit,
    String? tooltipFormat,
    TimeDisplayFormats? displayFormats,
    bool? offsetAfterAutoskip,
    String? parser,
    TimeParser? parserFunction,
    TimeUnit? round,
    TimeUnit? minUnit,
    int? isoWeekday,
    ScaleBounds? bounds,
    bool? offset,
    String? stack,
    double? stackWeight,
    bool? alignToPixels,
    ChartPaint? backgroundColor,
    bool? clip,
    double? weight,
    ScaleHook? beforeUpdate,
    ScaleHook? beforeSetDimensions,
    ScaleHook? afterSetDimensions,
    ScaleHook? beforeDataLimits,
    ScaleHook? afterDataLimits,
    ScaleHook? beforeBuildTicks,
    ScaleHook? afterBuildTicks,
    ScaleHook? beforeTickToLabelConversion,
    ScaleHook? afterTickToLabelConversion,
    ScaleHook? beforeCalculateLabelRotation,
    ScaleHook? afterCalculateLabelRotation,
    ScaleHook? beforeFit,
    ScaleHook? afterFit,
    ScaleHook? afterUpdate,
    AxisTicks? ticks,
    AxisGrid? grid,
    AxisBorder? border,
    AxisTitle? title,
    Map<String, Object?>? extra,
  }) => TimeSeriesAxis(
    axis ?? this.axis,
    display: display ?? this.display,
    position: position ?? this.position,
    reverse: reverse ?? this.reverse,
    stacked: stacked ?? this.stacked,
    min: min ?? this.min,
    max: max ?? this.max,
    unit: unit ?? this.unit,
    tooltipFormat: tooltipFormat ?? this.tooltipFormat,
    displayFormats: displayFormats ?? this.displayFormats,
    offsetAfterAutoskip: offsetAfterAutoskip ?? this.offsetAfterAutoskip,
    parser: parser ?? this.parser,
    parserFunction: parserFunction ?? this.parserFunction,
    round: round ?? this.round,
    minUnit: minUnit ?? this.minUnit,
    isoWeekday: isoWeekday ?? this.isoWeekday,
    bounds: bounds ?? this.bounds,
    offset: offset ?? this.offset,
    stack: stack ?? this.stack,
    stackWeight: stackWeight ?? this.stackWeight,
    alignToPixels: alignToPixels ?? this.alignToPixels,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    clip: clip ?? this.clip,
    weight: weight ?? this.weight,
    beforeUpdate: beforeUpdate ?? this.beforeUpdate,
    beforeSetDimensions: beforeSetDimensions ?? this.beforeSetDimensions,
    afterSetDimensions: afterSetDimensions ?? this.afterSetDimensions,
    beforeDataLimits: beforeDataLimits ?? this.beforeDataLimits,
    afterDataLimits: afterDataLimits ?? this.afterDataLimits,
    beforeBuildTicks: beforeBuildTicks ?? this.beforeBuildTicks,
    afterBuildTicks: afterBuildTicks ?? this.afterBuildTicks,
    beforeTickToLabelConversion:
        beforeTickToLabelConversion ?? this.beforeTickToLabelConversion,
    afterTickToLabelConversion:
        afterTickToLabelConversion ?? this.afterTickToLabelConversion,
    beforeCalculateLabelRotation:
        beforeCalculateLabelRotation ?? this.beforeCalculateLabelRotation,
    afterCalculateLabelRotation:
        afterCalculateLabelRotation ?? this.afterCalculateLabelRotation,
    beforeFit: beforeFit ?? this.beforeFit,
    afterFit: afterFit ?? this.afterFit,
    afterUpdate: afterUpdate ?? this.afterUpdate,
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
    put(scope, OptionKey.offset, offset);
    put(scope, OptionKey.stack, stack);
    put(scope, OptionKey.stackWeight, stackWeight);
  }

  @override
  List<TypedProperty> get _props => [
    ..._headProps,
    ..._timeProps,
    ('bounds', bounds),
    ('offset', offset),
    ('stack', stack),
    ('stackWeight', stackWeight),
    ..._tailProps,
  ];
}

/// The date formats of the tick labels of a time axis, one for each time
/// unit: `time.displayFormats` (`docs/axes/cartesian/time.md`, "Display
/// Formats").
///
/// Each format is an ICU pattern of the default date adapter. A null field
/// is not set: the chart takes the format of the adapter for that unit.
@immutable
final class const TimeDisplayFormats({
  /// The format of a full date and time: `datetime`. The default of the
  /// date adapter is `'MMM d, yyyy, h:mm:ss a'`.
  final String? datetime,

  /// The format of the unit [TimeUnit.millisecond]: `millisecond`. The
  /// default of the date adapter is `'h:mm:ss.SSS a'`.
  final String? millisecond,

  /// The format of the unit [TimeUnit.second]: `second`. The default of
  /// the date adapter is `'h:mm:ss a'`.
  final String? second,

  /// The format of the unit [TimeUnit.minute]: `minute`. The default of
  /// the date adapter is `'h:mm a'`.
  final String? minute,

  /// The format of the unit [TimeUnit.hour]: `hour`, for example `'HH:mm'`.
  /// The default of the date adapter is `'ha'`.
  final String? hour,

  /// The format of the unit [TimeUnit.day]: `day`, for example `'dd MMM'`.
  /// The default of the date adapter is `'MMM d'`.
  final String? day,

  /// The format of the unit [TimeUnit.week]: `week`. The default of the
  /// date adapter is `'MMM d, yyyy'`.
  final String? week,

  /// The format of the unit [TimeUnit.month]: `month`. The default of the
  /// date adapter is `'MMM yyyy'`.
  final String? month,

  /// The format of the unit [TimeUnit.quarter]: `quarter`. The default of
  /// the date adapter is `"'Q'Q - yyyy"`.
  final String? quarter,

  /// The format of the unit [TimeUnit.year]: `year`. The default of the
  /// date adapter is `'yyyy'`.
  final String? year,
}) with Diagnosticable {
  /// The date formats of a time axis.
  this;

  /// A copy of these formats with the given parameters. A parameter that is
  /// `null` keeps its value.
  TimeDisplayFormats copyWith({
    String? datetime,
    String? millisecond,
    String? second,
    String? minute,
    String? hour,
    String? day,
    String? week,
    String? month,
    String? quarter,
    String? year,
  }) => TimeDisplayFormats(
    datetime: datetime ?? this.datetime,
    millisecond: millisecond ?? this.millisecond,
    second: second ?? this.second,
    minute: minute ?? this.minute,
    hour: hour ?? this.hour,
    day: day ?? this.day,
    week: week ?? this.week,
    month: month ?? this.month,
    quarter: quarter ?? this.quarter,
    year: year ?? this.year,
  );

  List<TypedProperty> get _props => [
    ('datetime', datetime),
    ('millisecond', millisecond),
    ('second', second),
    ('minute', minute),
    ('hour', hour),
    ('day', day),
    ('week', week),
    ('month', month),
    ('quarter', quarter),
    ('year', year),
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeDisplayFormats && propsEqual(_props, other._props);

  @override
  int get hashCode => propsHash(_props);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    addProps(properties, _props);
  }
}

/// The `displayFormats` scope of [formats], or Dart `null`: each format
/// that is set, with the typed setter of its key.
DisplayFormatsScope? _lowerDisplayFormats(TimeDisplayFormats? formats) {
  if (formats == null) return null;
  final scope = DisplayFormatsScope();
  if (formats.datetime case final value?) scope.datetime = value;
  if (formats.millisecond case final value?) scope.millisecond = value;
  if (formats.second case final value?) scope.second = value;
  if (formats.minute case final value?) scope.minute = value;
  if (formats.hour case final value?) scope.hour = value;
  if (formats.day case final value?) scope.day = value;
  if (formats.week case final value?) scope.week = value;
  if (formats.month case final value?) scope.month = value;
  if (formats.quarter case final value?) scope.quarter = value;
  if (formats.year case final value?) scope.year = value;
  return scope;
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

  /// Whether the chart shows the point labels: `pointLabels.display`. The
  /// default is [ScaleDisplay.on]. [ScaleDisplay.auto] hides a label that
  /// overlaps another label (row `adapt-scale-display-enum`).
  final ScaleDisplay? pointLabelsDisplay,

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

  /// The space above the data range and below it: `grace`, for example
  /// `PercentGrace(5)` (row `adapt-length-objects`).
  final GraceLength? grace,

  super.alignToPixels,
  super.backgroundColor,
  super.clip,
  super.weight,
  super.beforeUpdate,
  super.beforeSetDimensions,
  super.afterSetDimensions,
  super.beforeDataLimits,
  super.afterDataLimits,
  super.beforeBuildTicks,
  super.afterBuildTicks,
  super.beforeTickToLabelConversion,
  super.afterTickToLabelConversion,
  super.beforeCalculateLabelRotation,
  super.afterCalculateLabelRotation,
  super.beforeFit,
  super.afterFit,
  super.afterUpdate,
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
    ScaleDisplay? display,
    ChartPosition? position,
    bool? reverse,
    StackMode? stacked,
    double? min,
    double? max,
    double? suggestedMin,
    double? suggestedMax,
    bool? beginAtZero,
    double? startAngle,
    ScaleDisplay? pointLabelsDisplay,
    ChartPaint? pointLabelsColor,
    TextStyle? pointLabelsFont,
    double? pointLabelsPadding,
    PointLabelCallback? pointLabelsCallback,
    bool? angleLinesDisplay,
    ChartPaint? angleLinesColor,
    double? angleLinesLineWidth,
    GraceLength? grace,
    bool? alignToPixels,
    ChartPaint? backgroundColor,
    bool? clip,
    double? weight,
    ScaleHook? beforeUpdate,
    ScaleHook? beforeSetDimensions,
    ScaleHook? afterSetDimensions,
    ScaleHook? beforeDataLimits,
    ScaleHook? afterDataLimits,
    ScaleHook? beforeBuildTicks,
    ScaleHook? afterBuildTicks,
    ScaleHook? beforeTickToLabelConversion,
    ScaleHook? afterTickToLabelConversion,
    ScaleHook? beforeCalculateLabelRotation,
    ScaleHook? afterCalculateLabelRotation,
    ScaleHook? beforeFit,
    ScaleHook? afterFit,
    ScaleHook? afterUpdate,
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
    grace: grace ?? this.grace,
    alignToPixels: alignToPixels ?? this.alignToPixels,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    clip: clip ?? this.clip,
    weight: weight ?? this.weight,
    beforeUpdate: beforeUpdate ?? this.beforeUpdate,
    beforeSetDimensions: beforeSetDimensions ?? this.beforeSetDimensions,
    afterSetDimensions: afterSetDimensions ?? this.afterSetDimensions,
    beforeDataLimits: beforeDataLimits ?? this.beforeDataLimits,
    afterDataLimits: afterDataLimits ?? this.afterDataLimits,
    beforeBuildTicks: beforeBuildTicks ?? this.beforeBuildTicks,
    afterBuildTicks: afterBuildTicks ?? this.afterBuildTicks,
    beforeTickToLabelConversion:
        beforeTickToLabelConversion ?? this.beforeTickToLabelConversion,
    afterTickToLabelConversion:
        afterTickToLabelConversion ?? this.afterTickToLabelConversion,
    beforeCalculateLabelRotation:
        beforeCalculateLabelRotation ?? this.beforeCalculateLabelRotation,
    afterCalculateLabelRotation:
        afterCalculateLabelRotation ?? this.afterCalculateLabelRotation,
    beforeFit: beforeFit ?? this.beforeFit,
    afterFit: afterFit ?? this.afterFit,
    afterUpdate: afterUpdate ?? this.afterUpdate,
    ticks: ticks ?? this.ticks,
    grid: grid ?? this.grid,
    border: border ?? this.border,
    title: title ?? this.title,
    extra: extra ?? this.extra,
  );

  @override
  String get _type => 'radialLinear';

  @override
  RAxis get axis => const RAxis();

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
    put(scope, OptionKey.grace, grace);
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
    ('grace', grace),
    ..._tailProps,
  ];
}

/// The tick marks and the tick labels of an axis: `ticks`
/// (`docs/axes/_common_ticks.md`, `docs/axes/styling.md`).
@immutable
final class const AxisTicks({
  /// Whether the chart shows the tick labels: `display`.
  final bool? display,

  /// The color of the tick labels: `color`, a [ScaleValue], for example
  /// `.constant(.solid(Colors.grey))` or `.resolver(colorOfTick)`.
  final ScaleValue<ChartPaint>? color,

  /// The font of the tick labels: `font`, a [ScaleValue]. The color of the
  /// font is not read: set [color].
  final ScaleValue<TextStyle>? font,

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

  /// The color of the box behind a tick label: `backdropColor`. The box shows
  /// when [showLabelBackdrop] is `true`.
  final ScaleValue<ChartPaint>? backdropColor,

  /// The space between a tick label and its box: `backdropPadding`.
  final EdgeInsets? backdropPadding,

  /// Whether a box shows behind each tick label: `showLabelBackdrop`. The
  /// default is `true` for a radial axis.
  final bool? showLabelBackdrop,

  /// The color of the outline of the tick labels: `textStrokeColor`.
  final ScaleValue<ChartPaint>? textStrokeColor,

  /// The width of the outline of the tick labels in pixels: `textStrokeWidth`.
  final double? textStrokeWidth,

  /// The drawing order of the tick labels: `z`. A value above 0 draws the
  /// labels over the chart area.
  final double? z,

  /// The number of ticks that the axis measures to fit the labels:
  /// `sampleSize`. The default is all ticks.
  final double? sampleSize,

  /// The space between two labels that [autoSkip] keeps, in pixels:
  /// `autoSkipPadding`.
  final double? autoSkipPadding,

  /// Whether the axis gives ticks at its minimum and its maximum:
  /// `includeBounds`. The default is `true`.
  final bool? includeBounds,

  /// The distance of a tick label from its tick along the axis, in pixels:
  /// `labelOffset`.
  final double? labelOffset,

  /// The minimum rotation of the tick labels in degrees: `minRotation`.
  final double? minRotation,

  /// Whether the tick labels go inside the chart area: `mirror`.
  final bool? mirror,

  /// The maximum number of ticks and grid lines: `maxTicksLimit`. The default
  /// is 11.
  final double? maxTicksLimit,

  /// The number format of the tick labels of a linear or logarithmic axis:
  /// `format` (Chart.js ADR 0119).
  final NumberFormat? format,

  /// The number of decimal places of a computed step size of a linear axis:
  /// `precision`.
  final double? precision,

  /// The number of ticks of a linear axis: `count`. The axis computes the step
  /// size.
  final double? count,

  /// The Chart.js tick options that have no parameter, for example
  /// `{'major': {'enabled': true}}`. The rules of [ChartAxis.extra] apply.
  final Map<String, Object?>? extra,
}) with Diagnosticable {
  /// The tick options of an axis.
  this;

  /// A copy of these tick options with the given parameters. A parameter
  /// that is `null` keeps its value.
  AxisTicks copyWith({
    bool? display,
    ScaleValue<ChartPaint>? color,
    ScaleValue<TextStyle>? font,
    double? padding,
    double? stepSize,
    double? maxRotation,
    bool? autoSkip,
    TickAlign? align,
    TickCrossAlign? crossAlign,
    TickSource? source,
    TickCallback? callback,
    ScaleValue<ChartPaint>? backdropColor,
    EdgeInsets? backdropPadding,
    bool? showLabelBackdrop,
    ScaleValue<ChartPaint>? textStrokeColor,
    double? textStrokeWidth,
    double? z,
    double? sampleSize,
    double? autoSkipPadding,
    bool? includeBounds,
    double? labelOffset,
    double? minRotation,
    bool? mirror,
    double? maxTicksLimit,
    NumberFormat? format,
    double? precision,
    double? count,
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
    backdropColor: backdropColor ?? this.backdropColor,
    backdropPadding: backdropPadding ?? this.backdropPadding,
    showLabelBackdrop: showLabelBackdrop ?? this.showLabelBackdrop,
    textStrokeColor: textStrokeColor ?? this.textStrokeColor,
    textStrokeWidth: textStrokeWidth ?? this.textStrokeWidth,
    z: z ?? this.z,
    sampleSize: sampleSize ?? this.sampleSize,
    autoSkipPadding: autoSkipPadding ?? this.autoSkipPadding,
    includeBounds: includeBounds ?? this.includeBounds,
    labelOffset: labelOffset ?? this.labelOffset,
    minRotation: minRotation ?? this.minRotation,
    mirror: mirror ?? this.mirror,
    maxTicksLimit: maxTicksLimit ?? this.maxTicksLimit,
    format: format ?? this.format,
    precision: precision ?? this.precision,
    count: count ?? this.count,
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
    ('backdropColor', backdropColor),
    ('backdropPadding', backdropPadding),
    ('showLabelBackdrop', showLabelBackdrop),
    ('textStrokeColor', textStrokeColor),
    ('textStrokeWidth', textStrokeWidth),
    ('z', z),
    ('sampleSize', sampleSize),
    ('autoSkipPadding', autoSkipPadding),
    ('includeBounds', includeBounds),
    ('labelOffset', labelOffset),
    ('minRotation', minRotation),
    ('mirror', mirror),
    ('maxTicksLimit', maxTicksLimit),
    ('format', format),
    ('precision', precision),
    ('count', count),
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
  if (ticks.color case final value?) {
    scope.store(OptionKey.color, value.toOptionCell());
  }
  if (ticks.font case final value?) {
    scope.store(OptionKey.font, value.toOptionCell());
  }
  put(scope, OptionKey.padding, ticks.padding);
  put(scope, OptionKey.stepSize, ticks.stepSize);
  put(scope, OptionKey.maxRotation, ticks.maxRotation);
  put(scope, OptionKey.autoSkip, ticks.autoSkip);
  put(scope, OptionKey.align, ticks.align);
  put(scope, OptionKey.crossAlign, ticks.crossAlign);
  put(scope, OptionKey.source, ticks.source);
  put(scope, OptionKey.callback, ticks.callback);
  if (ticks.backdropColor case final value?) {
    scope.store(OptionKey.backdropColor, value.toOptionCell());
  }
  put(scope, OptionKey.backdropPadding, ticks.backdropPadding);
  put(scope, OptionKey.showLabelBackdrop, ticks.showLabelBackdrop);
  if (ticks.textStrokeColor case final value?) {
    scope.store(OptionKey.textStrokeColor, value.toOptionCell());
  }
  put(scope, OptionKey.textStrokeWidth, ticks.textStrokeWidth);
  put(scope, OptionKey.z, ticks.z);
  put(scope, OptionKey.sampleSize, ticks.sampleSize);
  put(scope, OptionKey.autoSkipPadding, ticks.autoSkipPadding);
  put(scope, OptionKey.includeBounds, ticks.includeBounds);
  put(scope, OptionKey.labelOffset, ticks.labelOffset);
  put(scope, OptionKey.minRotation, ticks.minRotation);
  put(scope, OptionKey.mirror, ticks.mirror);
  put(scope, OptionKey.maxTicksLimit, ticks.maxTicksLimit);
  put(scope, OptionKey.format, ticks.format);
  put(scope, OptionKey.precision, ticks.precision);
  put(scope, OptionKey.count, ticks.count);
  return mergeExtra(scope, ticks.extra);
}

/// The grid lines of an axis: `grid` (`docs/axes/styling.md`, "Grid Line
/// Configuration").
@immutable
final class const AxisGrid({
  /// Whether the chart draws the grid lines: `display`.
  final bool? display,

  /// The color of the grid lines: `color`, a [ScaleValue], for example
  /// `.constant(.solid(Colors.grey))` or `.resolver(colorOfTick)`.
  final ScaleValue<ChartPaint>? color,

  /// The width of the grid lines in pixels: `lineWidth`, a [ScaleValue].
  final ScaleValue<double>? lineWidth,

  /// Whether the grid lines go across the chart area: `drawOnChartArea`.
  /// With `false`, the chart draws only the tick marks.
  final bool? drawOnChartArea,

  /// Whether the chart draws the tick marks next to the tick labels:
  /// `drawTicks`.
  final bool? drawTicks,

  /// Whether the grid lines are between the labels, not at them: `offset`.
  /// The default of the index axis of a bar chart is `true`.
  final bool? offset,

  /// The length in pixels that the grid lines draw into the axis area, the
  /// tick marks: `tickLength`. The default is 8.
  final double? tickLength,

  /// Whether the grid lines of a radial axis are circles, not polygons:
  /// `circular`.
  final bool? circular,

  /// The dash pattern of the tick marks: `tickBorderDash`, for example `[4,
  /// 2]`.
  final List<double>? tickBorderDash,

  /// The offset of the dash pattern of the tick marks: `tickBorderDashOffset`.
  final double? tickBorderDashOffset,

  /// The color of the tick marks: `tickColor`. The default is [color].
  final ScaleValue<ChartPaint>? tickColor,

  /// The width of the tick marks in pixels: `tickWidth`. The default is
  /// [lineWidth].
  final ScaleValue<double>? tickWidth,

  /// The drawing order of the grid lines: `z`. A value above 0 draws the lines
  /// over the datasets.
  final double? z,

  /// The Chart.js grid options that have no parameter, for example a
  /// function for `color`. The rules of [ChartAxis.extra] apply.
  final Map<String, Object?>? extra,
}) with Diagnosticable {
  /// The grid options of an axis.
  this;

  /// A copy of these grid options with the given parameters. A parameter
  /// that is `null` keeps its value.
  AxisGrid copyWith({
    bool? display,
    ScaleValue<ChartPaint>? color,
    ScaleValue<double>? lineWidth,
    bool? drawOnChartArea,
    bool? drawTicks,
    bool? offset,
    double? tickLength,
    bool? circular,
    List<double>? tickBorderDash,
    double? tickBorderDashOffset,
    ScaleValue<ChartPaint>? tickColor,
    ScaleValue<double>? tickWidth,
    double? z,
    Map<String, Object?>? extra,
  }) => AxisGrid(
    display: display ?? this.display,
    color: color ?? this.color,
    lineWidth: lineWidth ?? this.lineWidth,
    drawOnChartArea: drawOnChartArea ?? this.drawOnChartArea,
    drawTicks: drawTicks ?? this.drawTicks,
    offset: offset ?? this.offset,
    tickLength: tickLength ?? this.tickLength,
    circular: circular ?? this.circular,
    tickBorderDash: tickBorderDash ?? this.tickBorderDash,
    tickBorderDashOffset: tickBorderDashOffset ?? this.tickBorderDashOffset,
    tickColor: tickColor ?? this.tickColor,
    tickWidth: tickWidth ?? this.tickWidth,
    z: z ?? this.z,
    extra: extra ?? this.extra,
  );

  List<TypedProperty> get _props => [
    ('display', display),
    ('color', color),
    ('lineWidth', lineWidth),
    ('drawOnChartArea', drawOnChartArea),
    ('drawTicks', drawTicks),
    ('offset', offset),
    ('tickLength', tickLength),
    ('circular', circular),
    ('tickBorderDash', byItems(tickBorderDash)),
    ('tickBorderDashOffset', tickBorderDashOffset),
    ('tickColor', tickColor),
    ('tickWidth', tickWidth),
    ('z', z),
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
  if (grid.color case final value?) {
    scope.store(OptionKey.color, value.toOptionCell());
  }
  if (grid.lineWidth case final value?) {
    scope.store(OptionKey.lineWidth, value.toOptionCell());
  }
  put(scope, OptionKey.drawOnChartArea, grid.drawOnChartArea);
  put(scope, OptionKey.drawTicks, grid.drawTicks);
  put(scope, OptionKey.offset, grid.offset);
  put(scope, OptionKey.tickLength, grid.tickLength);
  put(scope, OptionKey.circular, grid.circular);
  put(scope, OptionKey.tickBorderDash, grid.tickBorderDash);
  put(scope, OptionKey.tickBorderDashOffset, grid.tickBorderDashOffset);
  if (grid.tickColor case final value?) {
    scope.store(OptionKey.tickColor, value.toOptionCell());
  }
  if (grid.tickWidth case final value?) {
    scope.store(OptionKey.tickWidth, value.toOptionCell());
  }
  put(scope, OptionKey.z, grid.z);
  return mergeExtra(scope, grid.extra);
}

/// The title of an axis: `title` (`docs/axes/labelling.md`, "Scale
/// Title Configuration").
@immutable
final class const AxisTitle({
  /// Whether the chart shows the title: `display`. The default is `false`.
  final bool? display,

  /// The lines of the title: `text` (row `adapt-title-text-lines`), for
  /// example `['Revenue']`.
  final List<String>? text,

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

  /// The color of the outline of the title: `strokeColor`.
  final ChartPaint? strokeColor,

  /// The width of the outline of the title in pixels: `strokeWidth`.
  final double? strokeWidth,

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
    List<String>? text,
    ChartPaint? color,
    TextStyle? font,
    ChartAlign? align,
    EdgeInsets? padding,
    ChartPaint? strokeColor,
    double? strokeWidth,
    Map<String, Object?>? extra,
  }) => AxisTitle(
    display: display ?? this.display,
    text: text ?? this.text,
    color: color ?? this.color,
    font: font ?? this.font,
    align: align ?? this.align,
    padding: padding ?? this.padding,
    strokeColor: strokeColor ?? this.strokeColor,
    strokeWidth: strokeWidth ?? this.strokeWidth,
    extra: extra ?? this.extra,
  );

  List<TypedProperty> get _props => [
    ('display', display),
    ('text', byItems(text)),
    ('color', color),
    ('font', font),
    ('align', align),
    ('padding', padding),
    ('strokeColor', strokeColor),
    ('strokeWidth', strokeWidth),
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
  put(scope, OptionKey.strokeColor, title.strokeColor);
  put(scope, OptionKey.strokeWidth, title.strokeWidth);
  return mergeExtra(scope, title.extra);
}
