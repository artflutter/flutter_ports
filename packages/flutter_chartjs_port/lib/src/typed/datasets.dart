// Original code, not ported from Chart.js: the datasets of the typed API.

/// The datasets of the typed API (Chart.js ADR 0052, sections 1 and 3):
/// [Dataset], one dataset class for each chart type, and [DataPoint], the
/// object form of a data item.
///
/// A data List goes to the chart by reference: the chart reads the List of
/// the app. The chart does not write into a data List or into a
/// [DataPoint].
library;

import 'dart:ui' show StrokeCap, StrokeJoin;

import 'package:flutter/foundation.dart'
    show DiagnosticPropertiesBuilder, Diagnosticable, Key, immutable, protected;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// A dataset of a chart: an item of `data.datasets` of a Chart.js config.
///
/// Each chart type has its dataset class: [BarDataset], [LineDataset],
/// [ScatterDataset], [BubbleDataset], [PieDataset], [DoughnutDataset],
/// [PolarAreaDataset] and [RadarDataset]. A mixed chart has datasets of two
/// or more classes, for example a [LineDataset] in a bar chart
/// (`docs/charts/mixed.md`). The class gives the controller of the dataset.
///
/// A parameter that is `null` is not set: the chart uses the default of
/// Chart.js. Each parameter names its Chart.js option in its doc.
///
/// [backgroundColor] and [borderColor] each accept one explicit [ChartValue]:
/// constant, indexed or resolved by a callback.
///
/// Indexed and callback values resolve per data item. Prefer a constant
/// value when the whole dataset uses one color.
///
/// The keys that this class does not have go through [extra].
///
/// A package can add the dataset class of its own chart type (Chart.js ADR
/// 0189): a `final` subclass that gives [kind], [chartData], [lowerOwn] and
/// [props]. The class takes the parameters of [Dataset] that its chart type
/// reads, with `super.<name>`.
///
/// ```dart
/// final class const SankeyDataset({
///   super.label,
///   final List<SankeyDataPoint>? data,
/// }) extends Dataset {
///   @override
///   ChartKind get kind => const ChartKind('sankey');
///   ...
/// }
/// ```
///
/// A dataset is immutable. `==` compares the parameters: a List of data
/// items by identity, a small List of style values by its items, and a
/// function with `==`. Use a method tear-off or a function in a field for
/// resolvers in [backgroundColor] and [borderColor]: a new closure
/// in each build is a new value, and the chart then updates.
@immutable
abstract base class const Dataset({
  /// The identity of the dataset when the app gives a new config.
  ///
  /// The chart keeps the state of a dataset, for example its hidden state
  /// and its animations, from one config to the next. Without a key, a
  /// dataset takes the state of the dataset of the same class at the same
  /// index. Give a key to each dataset when the app adds, removes or
  /// reorders datasets. The key is not a Chart.js option.
  final Key? key,

  /// The name of the dataset in the legend and in the tooltip: `label`.
  final String? label,

  /// Whether the dataset is hidden: `hidden`.
  final bool? hidden,

  /// The draw order of the dataset: `order`.
  ///
  /// The chart draws a dataset with a higher order first, so that a dataset
  /// with a lower order is on top of it. The order also sets the order of
  /// the stacks, of the tooltip items and of the legend items. The default
  /// is 0.
  final int? order,

  /// How the chart clips the drawing of the dataset: `clip`.
  ///
  /// [ChartClip.all] lets the drawing overflow the area of the dataset by its
  /// pixels on each side, or clips inside the area for a negative value.
  /// [ChartClip.none] draws with no clip area. The default lets the points at
  /// the edge of the area draw whole.
  final ChartClip? clip,

  /// The data-item fill: a constant, indexed list or typed callback.
  /// A null parameter inherits the default. This lowers to `backgroundColor`.
  final ChartValue<ChartPaint>? backgroundColor,

  /// The data-item border: a constant, indexed list or typed callback.
  /// A null parameter inherits the default. This lowers to `borderColor`.
  final ChartValue<ChartPaint>? borderColor,

  /// The border width in pixels: `borderWidth`.
  final double? borderWidth,

  /// The fill color of a data item under the pointer:
  /// `hoverBackgroundColor`.
  final ChartValue<ChartPaint>? hoverBackgroundColor,

  /// The border color of a data item under the pointer: `hoverBorderColor`.
  final ChartValue<ChartPaint>? hoverBorderColor,

  /// The border width of a data item under the pointer, in pixels:
  /// `hoverBorderWidth`.
  final double? hoverBorderWidth,

  /// The shadow of the dataset: `shadow` (Chart.js ADRs 0107 and 0139). It
  /// is not a Chart.js option.
  ///
  /// The shadow falls under the lines, the points, the bars and the arcs of
  /// the dataset. The area fill of a line has no shadow.
  final ChartShadow? shadow,

  /// Native per-item tooltip callback overrides for this dataset.
  final TooltipCallbacks? tooltipCallbacks,

  /// The Chart.js options of the dataset that have no parameter, for
  /// example `{'normalized': true}`.
  ///
  /// The entries go into the dataset Map last: an entry wins over a
  /// parameter with the same key. A Map value merges into the Map of the
  /// key, a List or another value replaces it. Thus [extra] also gives a
  /// CSS string, a gradient or the Chart.js `null` of a key. The chart gets
  /// a copy of each Map and the Lists of the app.
  final Map<String, Object?>? extra,
}) with Diagnosticable {
  /// The parameters of each dataset class.
  this;

  /// The controller id of the dataset class: the `type` of the dataset when
  /// it differs from the type of the chart.
  @protected
  ChartKind get kind;

  /// The `data` option: the data List or the points List of the app, by
  /// reference.
  @protected
  List<Object?>? get chartData;

  /// Writes the keys of the dataset class into [scope], after the keys of
  /// [Dataset] and before [extra]. A key with no [OptionKey] goes by its
  /// name: `scope['colorFrom'] = value`.
  @protected
  void lowerOwn(OptionScope scope);

  /// The properties of the dataset, in parameter order: `==`, `hashCode`
  /// and the diagnostics compare and show them. Include [styleProps] and
  /// each own parameter, with `byItems` or `byEntries` for a List or a Map
  /// of style values.
  @protected
  List<TypedProperty> get props;

  /// The properties of [Dataset] from [hidden] to [tooltipCallbacks].
  @protected
  List<TypedProperty> get styleProps => [
    ('hidden', hidden),
    ('order', order),
    ('clip', clip),
    ('backgroundColor', backgroundColor),
    ('borderColor', borderColor),
    ('borderWidth', borderWidth),
    ('hoverBackgroundColor', hoverBackgroundColor),
    ('hoverBorderColor', hoverBorderColor),
    ('hoverBorderWidth', hoverBorderWidth),
    ('shadow', shadow),
    ('tooltipCallbacks', tooltipCallbacksPresence(tooltipCallbacks)),
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Dataset &&
          other.runtimeType == runtimeType &&
          propsEqual(props, other.props);

  @override
  int get hashCode => Object.hash(runtimeType, propsHash(props));

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    addProps(properties, props);
  }
}

/// The dataset scope of [dataset] in a chart of the type [chartType]
/// (Chart.js ADR 0052, section 2; Chart.js ADR 0054 §7): a new typed scope
/// of the dataset kind of the controller of the dataset
/// ([_datasetScopeOf]).
///
/// The keys come in parameter order. The key `type` comes first, and only
/// when the controller of the dataset is not the controller of the chart:
/// Chart.js reads `dataset.type || config.type` (`core.config.js:93-95`).
/// Thus a bar chart lowers to the docs form, and a [LineDataset] in a bar
/// chart lowers to the form of `docs/charts/mixed.md`. [Dataset.extra]
/// merges last. [Dataset.key] does not lower.
OptionScope lowerDataset(
  Dataset dataset,
  ChartKind chartType, {
  TooltipCallbacks? Function()? currentTooltipCallbacks,
}) {
  final kind = dataset.kind;
  final scope = _datasetScopeOf(kind);
  if (kind != chartType) put(scope, OptionKey.type, kind.name);
  put(scope, OptionKey.label, dataset.label);
  put(scope, OptionKey.data, dataset.chartData);
  put(scope, OptionKey.hidden, dataset.hidden);
  put(scope, OptionKey.order, dataset.order);
  put(scope, OptionKey.clip, dataset.clip);
  if (dataset.backgroundColor case final value?) {
    // Preserve the public variant directly, without raw value classification.
    scope.store(OptionKey.backgroundColor, value.toOptionCell());
  }
  if (dataset.borderColor case final value?) {
    scope.store(OptionKey.borderColor, value.toOptionCell());
  }
  put(scope, OptionKey.borderWidth, dataset.borderWidth);
  if (dataset.hoverBackgroundColor case final value?) {
    scope.store(OptionKey.hoverBackgroundColor, value.toOptionCell());
  }
  if (dataset.hoverBorderColor case final value?) {
    scope.store(OptionKey.hoverBorderColor, value.toOptionCell());
  }
  put(scope, OptionKey.hoverBorderWidth, dataset.hoverBorderWidth);
  dataset.lowerOwn(scope);
  put(scope, OptionKey.shadow, dataset.shadow);
  if (dataset.tooltipCallbacks case final callbacks?) {
    scope.store(
      OptionKey.tooltip,
      scope.classify(
        OptionKey.tooltip,
        TooltipDatasetOptionsScope()
          ..callbacks = currentTooltipCallbacks == null
              ? callbacks
              : tooltipCallbacksTrampoline(callbacks, currentTooltipCallbacks),
      ),
    );
  }
  return mergeExtra(scope, dataset.extra);
}

/// A new dataset scope of the controller [kind] (Chart.js ADR 0054 §3): the
/// dataset kind of `index.d.ts` of each controller (`line` and `scatter`
/// share `LineControllerDatasetOptions`, `pie` and `doughnut` share
/// `DoughnutControllerDatasetOptions`).
OptionScope _datasetScopeOf(ChartKind kind) => switch (kind) {
  ChartKind.bar => BarControllerDatasetOptionsScope(),
  ChartKind.line || ChartKind.scatter => LineControllerDatasetOptionsScope(),
  ChartKind.bubble => BubbleControllerDatasetOptionsScope(),
  ChartKind.pie ||
  ChartKind.doughnut => DoughnutControllerDatasetOptionsScope(),
  ChartKind.polarArea => PolarAreaControllerDatasetOptionsScope(),
  ChartKind.radar => RadarControllerDatasetOptionsScope(),
  _ => GenericDatasetOptionsScope(),
};

/// A dataset of a bar chart: the bar controller (`docs/charts/bar.md`).
///
/// Give the data in [data]: one value for each label of the chart with
/// [DatasetData.values], or items with their own x with
/// [DatasetData.points]. A bar chart with `indexAxis: const YAxis()` has
/// horizontal bars.
final class const BarDataset({
  super.key,
  super.label,

  /// {@template flutter_chartjs_port.typed.data}
  /// The data of the dataset: `data`. [DatasetData.values] gives one value
  /// for each label of the chart; a `null` value is a gap.
  /// [DatasetData.points] gives the items in the object form `{x, y}`
  /// (`docs/general/data-structures.md`).
  ///
  /// The chart reads the List: it goes to the chart with no copy. For new
  /// data, give a new List in a new config. Or change the List and call
  /// `chart.update()`.
  /// {@endtemplate}
  final DatasetData? data,
  super.hidden,
  super.order,
  super.clip,
  super.backgroundColor,
  super.borderColor,
  super.borderWidth,
  super.hoverBackgroundColor,
  super.hoverBorderColor,
  super.hoverBorderWidth,
  super.shadow,
  super.tooltipCallbacks,

  /// {@template flutter_chartjs_port.typed.xAxis}
  /// The x axis of the dataset: `xAxisID`. It is `==` to an axis of
  /// `ChartConfig.scales` (Chart.js ADR 0191). The default is the first x
  /// axis.
  /// {@endtemplate}
  final ChartAxis? xAxis,

  /// {@template flutter_chartjs_port.typed.yAxis}
  /// The y axis of the dataset: `yAxisID`. It is `==` to an axis of
  /// `ChartConfig.scales` (Chart.js ADR 0191). The default is the first y
  /// axis.
  /// {@endtemplate}
  final ChartAxis? yAxis,

  /// {@template flutter_chartjs_port.typed.stack}
  /// The id of the stack of the dataset: `stack`. On a stacked axis, the
  /// datasets with the same stack id stack on each other.
  /// {@endtemplate}
  final String? stack,

  /// {@template flutter_chartjs_port.typed.indexAxis}
  /// The index axis of the dataset: `indexAxis`. The default is the index
  /// axis of the chart.
  /// {@endtemplate}
  final CartesianAxis? indexAxis,

  /// The radius of the bar corners in pixels: `borderRadius` as a number.
  ///
  /// The number rounds the corners that are not on the base of the bar, as
  /// in `docs/samples/bar/border-radius.md`. The object form goes through
  /// [extra].
  final double? borderRadius,

  /// The part of the category width that each bar takes, from 0 to 1:
  /// `barPercentage`. The default is 0.9.
  final double? barPercentage,

  /// The part of the sample width that each category takes, from 0 to 1:
  /// `categoryPercentage`. The default is 0.8.
  final double? categoryPercentage,

  /// The width of each bar: `barThickness`, a [BarThickness]
  /// (`BarThickness.pixels(12)` or [BarThickness.flex], row
  /// `adapt-bar-thickness-class`). The default fits the bars to the category
  /// width.
  final BarThickness? barThickness,

  /// The maximum width of each bar in pixels: `maxBarThickness`.
  final double? maxBarThickness,

  /// The minimum length of each bar in pixels: `minBarLength`. A bar with a
  /// small value then stays visible.
  final double? minBarLength,

  /// Whether the bars of the datasets at one index stand next to each
  /// other: `grouped`. The default is `true`.
  final bool? grouped,

  /// The edges of each bar that draw no border: `borderSkipped`, a
  /// [BorderSkip]. The default is [BorderSkip.start], the edge at the base
  /// of the bar.
  final BorderSkip? borderSkipped,
  super.extra,
}) extends Dataset {
  /// A bar dataset.
  this;

  /// A copy of this dataset with the given parameters. A null parameter
  /// keeps its value.
  BarDataset copyWith({
    Key? key,
    String? label,
    DatasetData? data,
    bool? hidden,
    int? order,
    ChartClip? clip,
    ChartValue<ChartPaint>? backgroundColor,
    ChartValue<ChartPaint>? borderColor,
    double? borderWidth,
    ChartValue<ChartPaint>? hoverBackgroundColor,
    ChartValue<ChartPaint>? hoverBorderColor,
    double? hoverBorderWidth,
    ChartShadow? shadow,
    TooltipCallbacks? tooltipCallbacks,
    ChartAxis? xAxis,
    ChartAxis? yAxis,
    String? stack,
    CartesianAxis? indexAxis,
    double? borderRadius,
    double? barPercentage,
    double? categoryPercentage,
    BarThickness? barThickness,
    double? maxBarThickness,
    double? minBarLength,
    bool? grouped,
    BorderSkip? borderSkipped,
    Map<String, Object?>? extra,
  }) => BarDataset(
    key: key ?? this.key,
    label: label ?? this.label,
    data: data ?? this.data,
    hidden: hidden ?? this.hidden,
    order: order ?? this.order,
    clip: clip ?? this.clip,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    hoverBackgroundColor: hoverBackgroundColor ?? this.hoverBackgroundColor,
    hoverBorderColor: hoverBorderColor ?? this.hoverBorderColor,
    hoverBorderWidth: hoverBorderWidth ?? this.hoverBorderWidth,
    shadow: shadow ?? this.shadow,
    tooltipCallbacks: tooltipCallbacks ?? this.tooltipCallbacks,
    xAxis: xAxis ?? this.xAxis,
    yAxis: yAxis ?? this.yAxis,
    stack: stack ?? this.stack,
    indexAxis: indexAxis ?? this.indexAxis,
    borderRadius: borderRadius ?? this.borderRadius,
    barPercentage: barPercentage ?? this.barPercentage,
    categoryPercentage: categoryPercentage ?? this.categoryPercentage,
    barThickness: barThickness ?? this.barThickness,
    maxBarThickness: maxBarThickness ?? this.maxBarThickness,
    minBarLength: minBarLength ?? this.minBarLength,
    grouped: grouped ?? this.grouped,
    borderSkipped: borderSkipped ?? this.borderSkipped,
    extra: extra ?? this.extra,
  );

  @override
  ChartKind get kind => ChartKind.bar;

  @override
  List<Object?>? get chartData => switch (data) {
    DatasetValues(:final values) => values,
    DatasetPoints(:final points) => points,
    null => null,
  };

  @override
  void lowerOwn(OptionScope scope) {
    put(scope, OptionKey.xAxisID, scaleIdOfAxis(xAxis));
    put(scope, OptionKey.yAxisID, scaleIdOfAxis(yAxis));
    put(scope, OptionKey.stack, stack);
    put(scope, OptionKey.indexAxis, indexAxis);
    put(scope, OptionKey.borderRadius, borderRadius);
    put(scope, OptionKey.barPercentage, barPercentage);
    put(scope, OptionKey.categoryPercentage, categoryPercentage);
    put(scope, OptionKey.barThickness, barThickness);
    put(scope, OptionKey.maxBarThickness, maxBarThickness);
    put(scope, OptionKey.minBarLength, minBarLength);
    put(scope, OptionKey.grouped, grouped);
    put(scope, OptionKey.borderSkipped, borderSkippedOf(borderSkipped));
  }

  @override
  List<TypedProperty> get props => [
    ('key', key),
    ('label', label),
    ('data', data),
    ...styleProps,
    ('xAxis', xAxis),
    ('yAxis', yAxis),
    ('stack', stack),
    ('indexAxis', indexAxis),
    ('borderRadius', borderRadius),
    ('barPercentage', barPercentage),
    ('categoryPercentage', categoryPercentage),
    ('barThickness', barThickness),
    ('maxBarThickness', maxBarThickness),
    ('minBarLength', minBarLength),
    ('grouped', grouped),
    ('borderSkipped', borderSkipped),
    ('extra', byEntries(extra)),
  ];
}

/// The line style parameters of [LineDataset], [ScatterDataset] and
/// [RadarDataset], in parameter order.
///
/// A mixin of the library: each of the three classes declares the fields.
base mixin _LineStyle on Dataset {
  FillTarget? get fill;
  double? get tension;
  List<double>? get borderDash;
  StrokeCap? get borderCapStyle;
  StrokeJoin? get borderJoinStyle;
  bool? get spanGaps;
  bool? get showLine;
  SteppedLine? get stepped;
  CubicInterpolationMode? get cubicInterpolationMode;
  LineSegmentStyle? get segment;
  ChartValue<double>? get pointRadius;
  ChartValue<double>? get pointHoverRadius;
  ChartValue<PointStyle>? get pointStyle;
  ChartValue<ChartPaint>? get pointBackgroundColor;
  ChartValue<ChartPaint>? get pointBorderColor;
  double? get pointBorderWidth;
  ChartValue<ChartPaint>? get pointHoverBackgroundColor;
  ChartValue<ChartPaint>? get pointHoverBorderColor;

  /// Writes the keys of the line style into [scope].
  void _lowerLine(OptionScope scope) {
    put(scope, OptionKey.fill, fill);
    put(scope, OptionKey.tension, tension);
    put(scope, OptionKey.borderDash, numberList(borderDash));
    put(scope, OptionKey.borderCapStyle, borderCapStyle);
    put(scope, OptionKey.borderJoinStyle, borderJoinStyle);
    put(scope, OptionKey.spanGaps, spanGaps);
    put(scope, OptionKey.showLine, showLine);
    put(scope, OptionKey.stepped, stepped);
    put(scope, OptionKey.cubicInterpolationMode, cubicInterpolationMode);
    put(scope, OptionKey.segment, segment);
    if (pointRadius case final value?) {
      scope.store(OptionKey.pointRadius, value.toOptionCell());
    }
    if (pointHoverRadius case final value?) {
      scope.store(OptionKey.pointHoverRadius, value.toOptionCell());
    }
    if (pointStyle case final value?) {
      scope.store(OptionKey.pointStyle, value.toOptionCell());
    }
    if (pointBackgroundColor case final value?) {
      scope.store(OptionKey.pointBackgroundColor, value.toOptionCell());
    }
    if (pointBorderColor case final value?) {
      scope.store(OptionKey.pointBorderColor, value.toOptionCell());
    }
    put(scope, OptionKey.pointBorderWidth, pointBorderWidth);
    if (pointHoverBackgroundColor case final value?) {
      scope.store(OptionKey.pointHoverBackgroundColor, value.toOptionCell());
    }
    if (pointHoverBorderColor case final value?) {
      scope.store(OptionKey.pointHoverBorderColor, value.toOptionCell());
    }
  }

  /// The properties of the line style, in parameter order.
  List<TypedProperty> get _lineProps => [
    ('fill', fill),
    ('tension', tension),
    ('borderDash', byItems(borderDash)),
    ('borderCapStyle', borderCapStyle),
    ('borderJoinStyle', borderJoinStyle),
    ('spanGaps', spanGaps),
    ('showLine', showLine),
    ('stepped', stepped),
    ('cubicInterpolationMode', cubicInterpolationMode),
    ('segment', segment),
    ('pointRadius', pointRadius),
    ('pointHoverRadius', pointHoverRadius),
    ('pointStyle', pointStyle),
    ('pointBackgroundColor', pointBackgroundColor),
    ('pointBorderColor', pointBorderColor),
    ('pointBorderWidth', pointBorderWidth),
    ('pointHoverBackgroundColor', pointHoverBackgroundColor),
    ('pointHoverBorderColor', pointHoverBorderColor),
  ];
}

/// A dataset of a line chart: the line controller (`docs/charts/line.md`).
///
/// Give the data in [data]: one value for each label of the chart with
/// [DatasetData.values], or items with their own x with
/// [DatasetData.points]. The line style parameters set the line, the fill and
/// the points.
final class const LineDataset({
  super.key,
  super.label,

  /// {@macro flutter_chartjs_port.typed.data}
  final DatasetData? data,
  super.hidden,
  super.order,
  super.clip,
  super.backgroundColor,
  super.borderColor,
  super.borderWidth,
  super.hoverBackgroundColor,
  super.hoverBorderColor,
  super.hoverBorderWidth,
  super.shadow,
  super.tooltipCallbacks,

  /// {@macro flutter_chartjs_port.typed.xAxis}
  final ChartAxis? xAxis,

  /// {@macro flutter_chartjs_port.typed.yAxis}
  final ChartAxis? yAxis,

  /// {@macro flutter_chartjs_port.typed.stack}
  final String? stack,

  /// {@macro flutter_chartjs_port.typed.indexAxis}
  final CartesianAxis? indexAxis,

  /// {@template flutter_chartjs_port.typed.fill}
  /// The fill of the area under or between the lines: `fill`
  /// (`docs/charts/area.md`). The default is no fill. The colors plugin of
  /// Chart.js and the filler plugin read it.
  /// {@endtemplate}
  @override final FillTarget? fill,

  /// {@template flutter_chartjs_port.typed.tension}
  /// The Bézier curve tension of the line, from 0 (straight lines) to 1:
  /// `tension`. The default is 0.
  /// {@endtemplate}
  @override final double? tension,

  /// {@template flutter_chartjs_port.typed.borderDash}
  /// The dash pattern of the line, lengths of dashes and gaps in pixels:
  /// `borderDash`. The default is a solid line.
  /// {@endtemplate}
  @override final List<double>? borderDash,

  /// {@template flutter_chartjs_port.typed.borderCapStyle}
  /// The shape of the ends of the line: `borderCapStyle`, a Flutter
  /// [StrokeCap]. The default is [StrokeCap.butt].
  /// {@endtemplate}
  @override final StrokeCap? borderCapStyle,

  /// {@template flutter_chartjs_port.typed.borderJoinStyle}
  /// The shape of the corners of the line: `borderJoinStyle`, a Flutter
  /// [StrokeJoin]. The default is [StrokeJoin.miter].
  /// {@endtemplate}
  @override final StrokeJoin? borderJoinStyle,

  /// {@template flutter_chartjs_port.typed.spanGaps}
  /// Whether the line spans the gaps of `null` values: `spanGaps` as a
  /// boolean. The default is `false`. The number form goes through `extra`.
  /// {@endtemplate}
  @override final bool? spanGaps,

  /// {@template flutter_chartjs_port.typed.showLine}
  /// Whether the chart draws the line: `showLine`. Without the line, the
  /// chart draws the points only.
  /// {@endtemplate}
  @override final bool? showLine,

  /// {@template flutter_chartjs_port.typed.stepped}
  /// The form of a stepped line: `stepped`, a [SteppedLine] (row
  /// `adapt-stepped-line-enum`). Dart `null`, the default, draws no steps.
  /// {@endtemplate}
  @override final SteppedLine? stepped,

  /// {@template flutter_chartjs_port.typed.cubicInterpolationMode}
  /// The mode of the control points of a curved line:
  /// `cubicInterpolationMode`, a [CubicInterpolationMode] (row
  /// `adapt-cubic-interpolation-mode-objects`). Dart `null` keeps the
  /// default, [DefaultCubicInterpolationMode].
  /// {@endtemplate}
  @override final CubicInterpolationMode? cubicInterpolationMode,

  /// {@template flutter_chartjs_port.typed.segment}
  /// The style functions of the parts of the line: `segment`, a
  /// [LineSegmentStyle] (Chart.js ADR 0142). A function that gives null
  /// keeps the line style for that part.
  /// {@endtemplate}
  @override final LineSegmentStyle? segment,

  /// {@template flutter_chartjs_port.typed.pointRadius}
  /// The radius of the points in pixels: `pointRadius`. 0 draws no points.
  /// A [ChartValue]: one radius (`.constant(3)`), one for each point
  /// (`.indexed([0, 4, 0])`) or a function of the data context.
  /// {@endtemplate}
  @override final ChartValue<double>? pointRadius,

  /// {@template flutter_chartjs_port.typed.pointHoverRadius}
  /// The radius of a point under the pointer, in pixels:
  /// `pointHoverRadius`. A [ChartValue], as `pointRadius`.
  /// {@endtemplate}
  @override final ChartValue<double>? pointHoverRadius,

  /// {@template flutter_chartjs_port.typed.pointStyle}
  /// The style of the points: `pointStyle`, a [ChartValue] of [PointStyle]
  /// (row `adapt-point-style-objects`): one style
  /// (`.constant(RectPointStyle())`), one for each point or a function of
  /// the data context. `false`, no point, goes through `extra`.
  /// {@endtemplate}
  @override final ChartValue<PointStyle>? pointStyle,

  /// {@template flutter_chartjs_port.typed.pointBackgroundColor}
  /// The fill color of the points: `pointBackgroundColor`.
  /// {@endtemplate}
  @override final ChartValue<ChartPaint>? pointBackgroundColor,

  /// {@template flutter_chartjs_port.typed.pointBorderColor}
  /// The border color of the points: `pointBorderColor`.
  /// {@endtemplate}
  @override final ChartValue<ChartPaint>? pointBorderColor,

  /// {@template flutter_chartjs_port.typed.pointBorderWidth}
  /// The border width of the points in pixels: `pointBorderWidth`.
  /// {@endtemplate}
  @override final double? pointBorderWidth,

  /// {@template flutter_chartjs_port.typed.pointHoverBackgroundColor}
  /// The fill color of a point under the pointer:
  /// `pointHoverBackgroundColor`.
  /// {@endtemplate}
  @override final ChartValue<ChartPaint>? pointHoverBackgroundColor,

  /// {@template flutter_chartjs_port.typed.pointHoverBorderColor}
  /// The border color of a point under the pointer: `pointHoverBorderColor`.
  /// {@endtemplate}
  @override final ChartValue<ChartPaint>? pointHoverBorderColor,
  super.extra,
}) extends Dataset with _LineStyle {
  /// A line dataset.
  this;

  /// A copy of this dataset with the given parameters. A null parameter
  /// keeps its value.
  LineDataset copyWith({
    Key? key,
    String? label,
    DatasetData? data,
    bool? hidden,
    int? order,
    ChartClip? clip,
    ChartValue<ChartPaint>? backgroundColor,
    ChartValue<ChartPaint>? borderColor,
    double? borderWidth,
    ChartValue<ChartPaint>? hoverBackgroundColor,
    ChartValue<ChartPaint>? hoverBorderColor,
    double? hoverBorderWidth,
    ChartShadow? shadow,
    TooltipCallbacks? tooltipCallbacks,
    ChartAxis? xAxis,
    ChartAxis? yAxis,
    String? stack,
    CartesianAxis? indexAxis,
    FillTarget? fill,
    double? tension,
    List<double>? borderDash,
    StrokeCap? borderCapStyle,
    StrokeJoin? borderJoinStyle,
    bool? spanGaps,
    bool? showLine,
    SteppedLine? stepped,
    CubicInterpolationMode? cubicInterpolationMode,
    LineSegmentStyle? segment,
    ChartValue<double>? pointRadius,
    ChartValue<double>? pointHoverRadius,
    ChartValue<PointStyle>? pointStyle,
    ChartValue<ChartPaint>? pointBackgroundColor,
    ChartValue<ChartPaint>? pointBorderColor,
    double? pointBorderWidth,
    ChartValue<ChartPaint>? pointHoverBackgroundColor,
    ChartValue<ChartPaint>? pointHoverBorderColor,
    Map<String, Object?>? extra,
  }) => LineDataset(
    key: key ?? this.key,
    label: label ?? this.label,
    data: data ?? this.data,
    hidden: hidden ?? this.hidden,
    order: order ?? this.order,
    clip: clip ?? this.clip,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    hoverBackgroundColor: hoverBackgroundColor ?? this.hoverBackgroundColor,
    hoverBorderColor: hoverBorderColor ?? this.hoverBorderColor,
    hoverBorderWidth: hoverBorderWidth ?? this.hoverBorderWidth,
    shadow: shadow ?? this.shadow,
    tooltipCallbacks: tooltipCallbacks ?? this.tooltipCallbacks,
    xAxis: xAxis ?? this.xAxis,
    yAxis: yAxis ?? this.yAxis,
    stack: stack ?? this.stack,
    indexAxis: indexAxis ?? this.indexAxis,
    fill: fill ?? this.fill,
    tension: tension ?? this.tension,
    borderDash: borderDash ?? this.borderDash,
    borderCapStyle: borderCapStyle ?? this.borderCapStyle,
    borderJoinStyle: borderJoinStyle ?? this.borderJoinStyle,
    spanGaps: spanGaps ?? this.spanGaps,
    showLine: showLine ?? this.showLine,
    stepped: stepped ?? this.stepped,
    cubicInterpolationMode:
        cubicInterpolationMode ?? this.cubicInterpolationMode,
    segment: segment ?? this.segment,
    pointRadius: pointRadius ?? this.pointRadius,
    pointHoverRadius: pointHoverRadius ?? this.pointHoverRadius,
    pointStyle: pointStyle ?? this.pointStyle,
    pointBackgroundColor: pointBackgroundColor ?? this.pointBackgroundColor,
    pointBorderColor: pointBorderColor ?? this.pointBorderColor,
    pointBorderWidth: pointBorderWidth ?? this.pointBorderWidth,
    pointHoverBackgroundColor:
        pointHoverBackgroundColor ?? this.pointHoverBackgroundColor,
    pointHoverBorderColor: pointHoverBorderColor ?? this.pointHoverBorderColor,
    extra: extra ?? this.extra,
  );

  @override
  ChartKind get kind => ChartKind.line;

  @override
  List<Object?>? get chartData => switch (data) {
    DatasetValues(:final values) => values,
    DatasetPoints(:final points) => points,
    null => null,
  };

  @override
  void lowerOwn(OptionScope scope) {
    put(scope, OptionKey.xAxisID, scaleIdOfAxis(xAxis));
    put(scope, OptionKey.yAxisID, scaleIdOfAxis(yAxis));
    put(scope, OptionKey.stack, stack);
    put(scope, OptionKey.indexAxis, indexAxis);
    _lowerLine(scope);
  }

  @override
  List<TypedProperty> get props => [
    ('key', key),
    ('label', label),
    ('data', data),
    ...styleProps,
    ('xAxis', xAxis),
    ('yAxis', yAxis),
    ('stack', stack),
    ('indexAxis', indexAxis),
    ..._lineProps,
    ('extra', byEntries(extra)),
  ];
}

/// A dataset of a scatter chart: the scatter controller
/// (`docs/charts/scatter.md`).
///
/// Give the items in [data] with [DatasetData.points], each with a number
/// `x`. A scatter chart draws the
/// points with no line. Set [showLine] for a line.
final class const ScatterDataset({
  super.key,
  super.label,

  /// {@macro flutter_chartjs_port.typed.data}
  final DatasetData? data,
  super.hidden,
  super.order,
  super.clip,
  super.backgroundColor,
  super.borderColor,
  super.borderWidth,
  super.hoverBackgroundColor,
  super.hoverBorderColor,
  super.hoverBorderWidth,
  super.shadow,
  super.tooltipCallbacks,

  /// {@macro flutter_chartjs_port.typed.xAxis}
  final ChartAxis? xAxis,

  /// {@macro flutter_chartjs_port.typed.yAxis}
  final ChartAxis? yAxis,

  /// {@macro flutter_chartjs_port.typed.stack}
  final String? stack,

  /// {@macro flutter_chartjs_port.typed.fill}
  @override final FillTarget? fill,

  /// {@macro flutter_chartjs_port.typed.tension}
  @override final double? tension,

  /// {@macro flutter_chartjs_port.typed.borderDash}
  @override final List<double>? borderDash,

  /// {@macro flutter_chartjs_port.typed.borderCapStyle}
  @override final StrokeCap? borderCapStyle,

  /// {@macro flutter_chartjs_port.typed.borderJoinStyle}
  @override final StrokeJoin? borderJoinStyle,

  /// {@macro flutter_chartjs_port.typed.spanGaps}
  @override final bool? spanGaps,

  /// {@macro flutter_chartjs_port.typed.showLine}
  ///
  /// The default of a scatter dataset is `false`.
  @override final bool? showLine,

  /// {@macro flutter_chartjs_port.typed.stepped}
  @override final SteppedLine? stepped,

  /// {@macro flutter_chartjs_port.typed.cubicInterpolationMode}
  @override final CubicInterpolationMode? cubicInterpolationMode,

  /// {@macro flutter_chartjs_port.typed.segment}
  @override final LineSegmentStyle? segment,

  /// {@macro flutter_chartjs_port.typed.pointRadius}
  @override final ChartValue<double>? pointRadius,

  /// {@macro flutter_chartjs_port.typed.pointHoverRadius}
  @override final ChartValue<double>? pointHoverRadius,

  /// {@macro flutter_chartjs_port.typed.pointStyle}
  @override final ChartValue<PointStyle>? pointStyle,

  /// {@macro flutter_chartjs_port.typed.pointBackgroundColor}
  @override final ChartValue<ChartPaint>? pointBackgroundColor,

  /// {@macro flutter_chartjs_port.typed.pointBorderColor}
  @override final ChartValue<ChartPaint>? pointBorderColor,

  /// {@macro flutter_chartjs_port.typed.pointBorderWidth}
  @override final double? pointBorderWidth,

  /// {@macro flutter_chartjs_port.typed.pointHoverBackgroundColor}
  @override final ChartValue<ChartPaint>? pointHoverBackgroundColor,

  /// {@macro flutter_chartjs_port.typed.pointHoverBorderColor}
  @override final ChartValue<ChartPaint>? pointHoverBorderColor,
  super.extra,
}) extends Dataset with _LineStyle {
  /// A scatter dataset.
  this;

  /// A copy of this dataset with the given parameters. A null parameter
  /// keeps its value.
  ScatterDataset copyWith({
    Key? key,
    String? label,
    DatasetData? data,
    bool? hidden,
    int? order,
    ChartClip? clip,
    ChartValue<ChartPaint>? backgroundColor,
    ChartValue<ChartPaint>? borderColor,
    double? borderWidth,
    ChartValue<ChartPaint>? hoverBackgroundColor,
    ChartValue<ChartPaint>? hoverBorderColor,
    double? hoverBorderWidth,
    ChartShadow? shadow,
    TooltipCallbacks? tooltipCallbacks,
    ChartAxis? xAxis,
    ChartAxis? yAxis,
    String? stack,
    FillTarget? fill,
    double? tension,
    List<double>? borderDash,
    StrokeCap? borderCapStyle,
    StrokeJoin? borderJoinStyle,
    bool? spanGaps,
    bool? showLine,
    SteppedLine? stepped,
    CubicInterpolationMode? cubicInterpolationMode,
    LineSegmentStyle? segment,
    ChartValue<double>? pointRadius,
    ChartValue<double>? pointHoverRadius,
    ChartValue<PointStyle>? pointStyle,
    ChartValue<ChartPaint>? pointBackgroundColor,
    ChartValue<ChartPaint>? pointBorderColor,
    double? pointBorderWidth,
    ChartValue<ChartPaint>? pointHoverBackgroundColor,
    ChartValue<ChartPaint>? pointHoverBorderColor,
    Map<String, Object?>? extra,
  }) => ScatterDataset(
    key: key ?? this.key,
    label: label ?? this.label,
    data: data ?? this.data,
    hidden: hidden ?? this.hidden,
    order: order ?? this.order,
    clip: clip ?? this.clip,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    hoverBackgroundColor: hoverBackgroundColor ?? this.hoverBackgroundColor,
    hoverBorderColor: hoverBorderColor ?? this.hoverBorderColor,
    hoverBorderWidth: hoverBorderWidth ?? this.hoverBorderWidth,
    shadow: shadow ?? this.shadow,
    tooltipCallbacks: tooltipCallbacks ?? this.tooltipCallbacks,
    xAxis: xAxis ?? this.xAxis,
    yAxis: yAxis ?? this.yAxis,
    stack: stack ?? this.stack,
    fill: fill ?? this.fill,
    tension: tension ?? this.tension,
    borderDash: borderDash ?? this.borderDash,
    borderCapStyle: borderCapStyle ?? this.borderCapStyle,
    borderJoinStyle: borderJoinStyle ?? this.borderJoinStyle,
    spanGaps: spanGaps ?? this.spanGaps,
    showLine: showLine ?? this.showLine,
    stepped: stepped ?? this.stepped,
    cubicInterpolationMode:
        cubicInterpolationMode ?? this.cubicInterpolationMode,
    segment: segment ?? this.segment,
    pointRadius: pointRadius ?? this.pointRadius,
    pointHoverRadius: pointHoverRadius ?? this.pointHoverRadius,
    pointStyle: pointStyle ?? this.pointStyle,
    pointBackgroundColor: pointBackgroundColor ?? this.pointBackgroundColor,
    pointBorderColor: pointBorderColor ?? this.pointBorderColor,
    pointBorderWidth: pointBorderWidth ?? this.pointBorderWidth,
    pointHoverBackgroundColor:
        pointHoverBackgroundColor ?? this.pointHoverBackgroundColor,
    pointHoverBorderColor: pointHoverBorderColor ?? this.pointHoverBorderColor,
    extra: extra ?? this.extra,
  );

  @override
  ChartKind get kind => ChartKind.scatter;

  @override
  List<Object?>? get chartData => switch (data) {
    DatasetValues(:final values) => values,
    DatasetPoints(:final points) => points,
    null => null,
  };

  @override
  void lowerOwn(OptionScope scope) {
    put(scope, OptionKey.xAxisID, scaleIdOfAxis(xAxis));
    put(scope, OptionKey.yAxisID, scaleIdOfAxis(yAxis));
    put(scope, OptionKey.stack, stack);
    _lowerLine(scope);
  }

  @override
  List<TypedProperty> get props => [
    ('key', key),
    ('label', label),
    ('data', data),
    ...styleProps,
    ('xAxis', xAxis),
    ('yAxis', yAxis),
    ('stack', stack),
    ..._lineProps,
    ('extra', byEntries(extra)),
  ];
}

/// A dataset of a bubble chart: the bubble controller
/// (`docs/charts/bubble.md`).
///
/// Give the items in [data], each a [DataPoint.bubble] with its radius.
final class const BubbleDataset({
  super.key,
  super.label,

  /// The bubbles in the object form `{x, y, r}`: `data` with objects. Each
  /// item is a [DataPoint.bubble].
  ///
  /// The chart reads this List: it goes to the chart with no copy.
  final List<DataPoint>? data,
  super.hidden,
  super.order,
  super.clip,
  super.backgroundColor,
  super.borderColor,
  super.borderWidth,
  super.hoverBackgroundColor,
  super.hoverBorderColor,
  super.hoverBorderWidth,
  super.shadow,
  super.tooltipCallbacks,

  /// {@macro flutter_chartjs_port.typed.xAxis}
  final ChartAxis? xAxis,

  /// {@macro flutter_chartjs_port.typed.yAxis}
  final ChartAxis? yAxis,

  /// The radius of a bubble without an `r` value, in pixels: `radius`.
  final double? radius,

  /// The radius that a bubble under the pointer adds, in pixels:
  /// `hoverRadius`.
  final double? hoverRadius,

  /// The style of the bubbles: `pointStyle`, a [PointStyle] (row
  /// `adapt-point-style-objects`).
  final PointStyle? pointStyle,
  super.extra,
}) extends Dataset {
  /// A bubble dataset.
  this;

  /// A copy of this dataset with the given parameters. A null parameter
  /// keeps its value.
  BubbleDataset copyWith({
    Key? key,
    String? label,
    List<DataPoint>? data,
    bool? hidden,
    int? order,
    ChartClip? clip,
    ChartValue<ChartPaint>? backgroundColor,
    ChartValue<ChartPaint>? borderColor,
    double? borderWidth,
    ChartValue<ChartPaint>? hoverBackgroundColor,
    ChartValue<ChartPaint>? hoverBorderColor,
    double? hoverBorderWidth,
    ChartShadow? shadow,
    TooltipCallbacks? tooltipCallbacks,
    ChartAxis? xAxis,
    ChartAxis? yAxis,
    double? radius,
    double? hoverRadius,
    PointStyle? pointStyle,
    Map<String, Object?>? extra,
  }) => BubbleDataset(
    key: key ?? this.key,
    label: label ?? this.label,
    data: data ?? this.data,
    hidden: hidden ?? this.hidden,
    order: order ?? this.order,
    clip: clip ?? this.clip,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    hoverBackgroundColor: hoverBackgroundColor ?? this.hoverBackgroundColor,
    hoverBorderColor: hoverBorderColor ?? this.hoverBorderColor,
    hoverBorderWidth: hoverBorderWidth ?? this.hoverBorderWidth,
    shadow: shadow ?? this.shadow,
    tooltipCallbacks: tooltipCallbacks ?? this.tooltipCallbacks,
    xAxis: xAxis ?? this.xAxis,
    yAxis: yAxis ?? this.yAxis,
    radius: radius ?? this.radius,
    hoverRadius: hoverRadius ?? this.hoverRadius,
    pointStyle: pointStyle ?? this.pointStyle,
    extra: extra ?? this.extra,
  );

  @override
  ChartKind get kind => ChartKind.bubble;

  @override
  List<Object?>? get chartData => data;

  @override
  void lowerOwn(OptionScope scope) {
    put(scope, OptionKey.xAxisID, scaleIdOfAxis(xAxis));
    put(scope, OptionKey.yAxisID, scaleIdOfAxis(yAxis));
    put(scope, OptionKey.radius, radius);
    put(scope, OptionKey.hoverRadius, hoverRadius);
    put(scope, OptionKey.pointStyle, pointStyle);
  }

  @override
  List<TypedProperty> get props => [
    ('key', key),
    ('label', label),
    ('data', data),
    ...styleProps,
    ('xAxis', xAxis),
    ('yAxis', yAxis),
    ('radius', radius),
    ('hoverRadius', hoverRadius),
    ('pointStyle', pointStyle),
    ('extra', byEntries(extra)),
  ];
}

/// The arc parameters of [PieDataset] and [DoughnutDataset], in parameter
/// order.
///
/// A mixin of the library: each of the two classes declares the fields.
base mixin _ArcStyle on Dataset {
  double? get offset;
  double? get hoverOffset;
  double? get spacing;
  double? get weight;
  double? get circumference;
  double? get rotation;
  RadiusLength? get cutout;
  RadiusLength? get radius;

  /// Writes the keys of the arcs into [scope].
  void _lowerArc(OptionScope scope) {
    put(scope, OptionKey.offset, offset);
    put(scope, OptionKey.hoverOffset, hoverOffset);
    put(scope, OptionKey.spacing, spacing);
    put(scope, OptionKey.weight, weight);
    put(scope, OptionKey.circumference, circumference);
    put(scope, OptionKey.rotation, rotation);
    put(scope, OptionKey.cutout, cutout);
    put(scope, OptionKey.radius, radius);
  }

  /// The properties of the arcs, in parameter order.
  List<TypedProperty> get _arcProps => [
    ('offset', offset),
    ('hoverOffset', hoverOffset),
    ('spacing', spacing),
    ('weight', weight),
    ('circumference', circumference),
    ('rotation', rotation),
    ('cutout', cutout),
    ('radius', radius),
  ];
}

/// A dataset of a pie chart: the pie controller (`docs/charts/doughnut.md`).
///
/// A pie has no cutout. A [DoughnutDataset] in a pie chart is a doughnut
/// with the doughnut cutout.
final class const PieDataset({
  super.key,
  super.label,

  /// {@template flutter_chartjs_port.typed.arcData}
  /// The values of the dataset, one for each label of the chart: `data`.
  ///
  /// The chart reads this List: it goes to the chart with no copy. For new
  /// values, give a new List in a new config. Or change this List and call
  /// `chart.update()`.
  /// {@endtemplate}
  final List<num?>? data,
  super.hidden,
  super.order,
  super.clip,
  super.backgroundColor,
  super.borderColor,
  super.borderWidth,
  super.hoverBackgroundColor,
  super.hoverBorderColor,
  super.hoverBorderWidth,
  super.shadow,
  super.tooltipCallbacks,

  /// {@template flutter_chartjs_port.typed.offset}
  /// The offset of each arc from the center, in pixels: `offset`.
  /// {@endtemplate}
  @override final double? offset,

  /// {@template flutter_chartjs_port.typed.hoverOffset}
  /// The offset of an arc under the pointer, in pixels: `hoverOffset`.
  /// {@endtemplate}
  @override final double? hoverOffset,

  /// {@template flutter_chartjs_port.typed.spacing}
  /// The space between the arcs, in pixels: `spacing`.
  /// {@endtemplate}
  @override final double? spacing,

  /// {@template flutter_chartjs_port.typed.weight}
  /// The weight of the dataset ring: `weight`. The rings of the datasets
  /// share the radius in the proportion of their weights. The default is
  /// 1.
  /// {@endtemplate}
  @override final double? weight,

  /// {@template flutter_chartjs_port.typed.circumference}
  /// The sweep of the arcs in degrees: `circumference`. The default is
  /// 360.
  /// {@endtemplate}
  @override final double? circumference,

  /// {@template flutter_chartjs_port.typed.rotation}
  /// The start angle of the arcs in degrees, from the top, clockwise:
  /// `rotation`. The default is 0.
  /// {@endtemplate}
  @override final double? rotation,

  /// {@template flutter_chartjs_port.typed.cutout}
  /// The radius of the hole in the center: `cutout`, a [RadiusLength] (row
  /// `adapt-length-objects`): `PercentRadius(50)` is a part of the outer
  /// radius, `PixelRadius(40)` pixels.
  /// {@endtemplate}
  ///
  /// The default of a pie is 0, no hole.
  @override final RadiusLength? cutout,

  /// {@template flutter_chartjs_port.typed.radius}
  /// The outer radius: `radius`, a [RadiusLength]: `PercentRadius(100)`, the
  /// default, is a part of the largest radius that fits the chart area,
  /// `PixelRadius(150)` pixels.
  /// {@endtemplate}
  @override final RadiusLength? radius,
  super.extra,
}) extends Dataset with _ArcStyle {
  /// A pie dataset.
  this;

  /// A copy of this dataset with the given parameters. A null parameter
  /// keeps its value.
  PieDataset copyWith({
    Key? key,
    String? label,
    List<num?>? data,
    bool? hidden,
    int? order,
    ChartClip? clip,
    ChartValue<ChartPaint>? backgroundColor,
    ChartValue<ChartPaint>? borderColor,
    double? borderWidth,
    ChartValue<ChartPaint>? hoverBackgroundColor,
    ChartValue<ChartPaint>? hoverBorderColor,
    double? hoverBorderWidth,
    ChartShadow? shadow,
    TooltipCallbacks? tooltipCallbacks,
    double? offset,
    double? hoverOffset,
    double? spacing,
    double? weight,
    double? circumference,
    double? rotation,
    RadiusLength? cutout,
    RadiusLength? radius,
    Map<String, Object?>? extra,
  }) => PieDataset(
    key: key ?? this.key,
    label: label ?? this.label,
    data: data ?? this.data,
    hidden: hidden ?? this.hidden,
    order: order ?? this.order,
    clip: clip ?? this.clip,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    hoverBackgroundColor: hoverBackgroundColor ?? this.hoverBackgroundColor,
    hoverBorderColor: hoverBorderColor ?? this.hoverBorderColor,
    hoverBorderWidth: hoverBorderWidth ?? this.hoverBorderWidth,
    shadow: shadow ?? this.shadow,
    tooltipCallbacks: tooltipCallbacks ?? this.tooltipCallbacks,
    offset: offset ?? this.offset,
    hoverOffset: hoverOffset ?? this.hoverOffset,
    spacing: spacing ?? this.spacing,
    weight: weight ?? this.weight,
    circumference: circumference ?? this.circumference,
    rotation: rotation ?? this.rotation,
    cutout: cutout ?? this.cutout,
    radius: radius ?? this.radius,
    extra: extra ?? this.extra,
  );

  @override
  ChartKind get kind => ChartKind.pie;

  @override
  List<Object?>? get chartData => data;

  @override
  void lowerOwn(OptionScope scope) => _lowerArc(scope);

  @override
  List<TypedProperty> get props => [
    ('key', key),
    ('label', label),
    ('data', data),
    ...styleProps,
    ..._arcProps,
    ('extra', byEntries(extra)),
  ];
}

/// A dataset of a doughnut chart: the doughnut controller
/// (`docs/charts/doughnut.md`).
///
/// A doughnut has a hole in the center: the default [cutout] is 50
/// percent. A doughnut dataset in a pie chart keeps the doughnut cutout.
final class const DoughnutDataset({
  super.key,
  super.label,

  /// {@macro flutter_chartjs_port.typed.arcData}
  final List<num?>? data,
  super.hidden,
  super.order,
  super.clip,
  super.backgroundColor,
  super.borderColor,
  super.borderWidth,
  super.hoverBackgroundColor,
  super.hoverBorderColor,
  super.hoverBorderWidth,
  super.shadow,
  super.tooltipCallbacks,

  /// {@macro flutter_chartjs_port.typed.offset}
  @override final double? offset,

  /// {@macro flutter_chartjs_port.typed.hoverOffset}
  @override final double? hoverOffset,

  /// {@macro flutter_chartjs_port.typed.spacing}
  @override final double? spacing,

  /// {@macro flutter_chartjs_port.typed.weight}
  @override final double? weight,

  /// {@macro flutter_chartjs_port.typed.circumference}
  @override final double? circumference,

  /// {@macro flutter_chartjs_port.typed.rotation}
  @override final double? rotation,

  /// {@macro flutter_chartjs_port.typed.cutout}
  ///
  /// The default of a doughnut is 50 percent.
  @override final RadiusLength? cutout,

  /// {@macro flutter_chartjs_port.typed.radius}
  @override final RadiusLength? radius,
  super.extra,
}) extends Dataset with _ArcStyle {
  /// A doughnut dataset.
  this;

  /// A copy of this dataset with the given parameters. A null parameter
  /// keeps its value.
  DoughnutDataset copyWith({
    Key? key,
    String? label,
    List<num?>? data,
    bool? hidden,
    int? order,
    ChartClip? clip,
    ChartValue<ChartPaint>? backgroundColor,
    ChartValue<ChartPaint>? borderColor,
    double? borderWidth,
    ChartValue<ChartPaint>? hoverBackgroundColor,
    ChartValue<ChartPaint>? hoverBorderColor,
    double? hoverBorderWidth,
    ChartShadow? shadow,
    TooltipCallbacks? tooltipCallbacks,
    double? offset,
    double? hoverOffset,
    double? spacing,
    double? weight,
    double? circumference,
    double? rotation,
    RadiusLength? cutout,
    RadiusLength? radius,
    Map<String, Object?>? extra,
  }) => DoughnutDataset(
    key: key ?? this.key,
    label: label ?? this.label,
    data: data ?? this.data,
    hidden: hidden ?? this.hidden,
    order: order ?? this.order,
    clip: clip ?? this.clip,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    hoverBackgroundColor: hoverBackgroundColor ?? this.hoverBackgroundColor,
    hoverBorderColor: hoverBorderColor ?? this.hoverBorderColor,
    hoverBorderWidth: hoverBorderWidth ?? this.hoverBorderWidth,
    shadow: shadow ?? this.shadow,
    tooltipCallbacks: tooltipCallbacks ?? this.tooltipCallbacks,
    offset: offset ?? this.offset,
    hoverOffset: hoverOffset ?? this.hoverOffset,
    spacing: spacing ?? this.spacing,
    weight: weight ?? this.weight,
    circumference: circumference ?? this.circumference,
    rotation: rotation ?? this.rotation,
    cutout: cutout ?? this.cutout,
    radius: radius ?? this.radius,
    extra: extra ?? this.extra,
  );

  @override
  ChartKind get kind => ChartKind.doughnut;

  @override
  List<Object?>? get chartData => data;

  @override
  void lowerOwn(OptionScope scope) => _lowerArc(scope);

  @override
  List<TypedProperty> get props => [
    ('key', key),
    ('label', label),
    ('data', data),
    ...styleProps,
    ..._arcProps,
    ('extra', byEntries(extra)),
  ];
}

/// A dataset of a polar area chart: the polar area controller
/// (`docs/charts/polar.md`).
///
/// Each data item is an arc with the same angle and a radius of its value
/// on the radial axis `r`.
final class const PolarAreaDataset({
  super.key,
  super.label,

  /// {@macro flutter_chartjs_port.typed.arcData}
  final List<num?>? data,
  super.hidden,
  super.order,
  super.clip,
  super.backgroundColor,
  super.borderColor,
  super.borderWidth,
  super.hoverBackgroundColor,
  super.hoverBorderColor,
  super.hoverBorderWidth,
  super.shadow,
  super.tooltipCallbacks,

  /// {@macro flutter_chartjs_port.typed.offset}
  final double? offset,

  /// {@macro flutter_chartjs_port.typed.hoverOffset}
  final double? hoverOffset,

  /// {@macro flutter_chartjs_port.typed.spacing}
  final double? spacing,
  super.extra,
}) extends Dataset {
  /// A polar area dataset.
  this;

  /// A copy of this dataset with the given parameters. A null parameter
  /// keeps its value.
  PolarAreaDataset copyWith({
    Key? key,
    String? label,
    List<num?>? data,
    bool? hidden,
    int? order,
    ChartClip? clip,
    ChartValue<ChartPaint>? backgroundColor,
    ChartValue<ChartPaint>? borderColor,
    double? borderWidth,
    ChartValue<ChartPaint>? hoverBackgroundColor,
    ChartValue<ChartPaint>? hoverBorderColor,
    double? hoverBorderWidth,
    ChartShadow? shadow,
    TooltipCallbacks? tooltipCallbacks,
    double? offset,
    double? hoverOffset,
    double? spacing,
    Map<String, Object?>? extra,
  }) => PolarAreaDataset(
    key: key ?? this.key,
    label: label ?? this.label,
    data: data ?? this.data,
    hidden: hidden ?? this.hidden,
    order: order ?? this.order,
    clip: clip ?? this.clip,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    hoverBackgroundColor: hoverBackgroundColor ?? this.hoverBackgroundColor,
    hoverBorderColor: hoverBorderColor ?? this.hoverBorderColor,
    hoverBorderWidth: hoverBorderWidth ?? this.hoverBorderWidth,
    shadow: shadow ?? this.shadow,
    tooltipCallbacks: tooltipCallbacks ?? this.tooltipCallbacks,
    offset: offset ?? this.offset,
    hoverOffset: hoverOffset ?? this.hoverOffset,
    spacing: spacing ?? this.spacing,
    extra: extra ?? this.extra,
  );

  @override
  ChartKind get kind => ChartKind.polarArea;

  @override
  List<Object?>? get chartData => data;

  @override
  void lowerOwn(OptionScope scope) {
    put(scope, OptionKey.offset, offset);
    put(scope, OptionKey.hoverOffset, hoverOffset);
    put(scope, OptionKey.spacing, spacing);
  }

  @override
  List<TypedProperty> get props => [
    ('key', key),
    ('label', label),
    ('data', data),
    ...styleProps,
    ('offset', offset),
    ('hoverOffset', hoverOffset),
    ('spacing', spacing),
    ('extra', byEntries(extra)),
  ];
}

/// A dataset of a radar chart: the radar controller (`docs/charts/radar.md`).
///
/// Give the values in [data], one for each label of the chart. The values
/// go on the radial axis `r`. The line style parameters set the line, the
/// fill and the points.
final class const RadarDataset({
  super.key,
  super.label,

  /// {@macro flutter_chartjs_port.typed.arcData}
  final List<num?>? data,
  super.hidden,
  super.order,
  super.clip,
  super.backgroundColor,
  super.borderColor,
  super.borderWidth,
  super.hoverBackgroundColor,
  super.hoverBorderColor,
  super.hoverBorderWidth,
  super.shadow,
  super.tooltipCallbacks,

  /// {@macro flutter_chartjs_port.typed.fill}
  @override final FillTarget? fill,

  /// {@macro flutter_chartjs_port.typed.tension}
  @override final double? tension,

  /// {@macro flutter_chartjs_port.typed.borderDash}
  @override final List<double>? borderDash,

  /// {@macro flutter_chartjs_port.typed.borderCapStyle}
  @override final StrokeCap? borderCapStyle,

  /// {@macro flutter_chartjs_port.typed.borderJoinStyle}
  @override final StrokeJoin? borderJoinStyle,

  /// {@macro flutter_chartjs_port.typed.spanGaps}
  @override final bool? spanGaps,

  /// {@macro flutter_chartjs_port.typed.showLine}
  @override final bool? showLine,

  /// {@macro flutter_chartjs_port.typed.stepped}
  @override final SteppedLine? stepped,

  /// {@macro flutter_chartjs_port.typed.cubicInterpolationMode}
  @override final CubicInterpolationMode? cubicInterpolationMode,

  /// {@macro flutter_chartjs_port.typed.segment}
  @override final LineSegmentStyle? segment,

  /// {@macro flutter_chartjs_port.typed.pointRadius}
  @override final ChartValue<double>? pointRadius,

  /// {@macro flutter_chartjs_port.typed.pointHoverRadius}
  @override final ChartValue<double>? pointHoverRadius,

  /// {@macro flutter_chartjs_port.typed.pointStyle}
  @override final ChartValue<PointStyle>? pointStyle,

  /// {@macro flutter_chartjs_port.typed.pointBackgroundColor}
  @override final ChartValue<ChartPaint>? pointBackgroundColor,

  /// {@macro flutter_chartjs_port.typed.pointBorderColor}
  @override final ChartValue<ChartPaint>? pointBorderColor,

  /// {@macro flutter_chartjs_port.typed.pointBorderWidth}
  @override final double? pointBorderWidth,

  /// {@macro flutter_chartjs_port.typed.pointHoverBackgroundColor}
  @override final ChartValue<ChartPaint>? pointHoverBackgroundColor,

  /// {@macro flutter_chartjs_port.typed.pointHoverBorderColor}
  @override final ChartValue<ChartPaint>? pointHoverBorderColor,
  super.extra,
}) extends Dataset with _LineStyle {
  /// A radar dataset.
  this;

  /// A copy of this dataset with the given parameters. A null parameter
  /// keeps its value.
  RadarDataset copyWith({
    Key? key,
    String? label,
    List<num?>? data,
    bool? hidden,
    int? order,
    ChartClip? clip,
    ChartValue<ChartPaint>? backgroundColor,
    ChartValue<ChartPaint>? borderColor,
    double? borderWidth,
    ChartValue<ChartPaint>? hoverBackgroundColor,
    ChartValue<ChartPaint>? hoverBorderColor,
    double? hoverBorderWidth,
    ChartShadow? shadow,
    TooltipCallbacks? tooltipCallbacks,
    FillTarget? fill,
    double? tension,
    List<double>? borderDash,
    StrokeCap? borderCapStyle,
    StrokeJoin? borderJoinStyle,
    bool? spanGaps,
    bool? showLine,
    SteppedLine? stepped,
    CubicInterpolationMode? cubicInterpolationMode,
    LineSegmentStyle? segment,
    ChartValue<double>? pointRadius,
    ChartValue<double>? pointHoverRadius,
    ChartValue<PointStyle>? pointStyle,
    ChartValue<ChartPaint>? pointBackgroundColor,
    ChartValue<ChartPaint>? pointBorderColor,
    double? pointBorderWidth,
    ChartValue<ChartPaint>? pointHoverBackgroundColor,
    ChartValue<ChartPaint>? pointHoverBorderColor,
    Map<String, Object?>? extra,
  }) => RadarDataset(
    key: key ?? this.key,
    label: label ?? this.label,
    data: data ?? this.data,
    hidden: hidden ?? this.hidden,
    order: order ?? this.order,
    clip: clip ?? this.clip,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    hoverBackgroundColor: hoverBackgroundColor ?? this.hoverBackgroundColor,
    hoverBorderColor: hoverBorderColor ?? this.hoverBorderColor,
    hoverBorderWidth: hoverBorderWidth ?? this.hoverBorderWidth,
    shadow: shadow ?? this.shadow,
    tooltipCallbacks: tooltipCallbacks ?? this.tooltipCallbacks,
    fill: fill ?? this.fill,
    tension: tension ?? this.tension,
    borderDash: borderDash ?? this.borderDash,
    borderCapStyle: borderCapStyle ?? this.borderCapStyle,
    borderJoinStyle: borderJoinStyle ?? this.borderJoinStyle,
    spanGaps: spanGaps ?? this.spanGaps,
    showLine: showLine ?? this.showLine,
    stepped: stepped ?? this.stepped,
    cubicInterpolationMode:
        cubicInterpolationMode ?? this.cubicInterpolationMode,
    segment: segment ?? this.segment,
    pointRadius: pointRadius ?? this.pointRadius,
    pointHoverRadius: pointHoverRadius ?? this.pointHoverRadius,
    pointStyle: pointStyle ?? this.pointStyle,
    pointBackgroundColor: pointBackgroundColor ?? this.pointBackgroundColor,
    pointBorderColor: pointBorderColor ?? this.pointBorderColor,
    pointBorderWidth: pointBorderWidth ?? this.pointBorderWidth,
    pointHoverBackgroundColor:
        pointHoverBackgroundColor ?? this.pointHoverBackgroundColor,
    pointHoverBorderColor: pointHoverBorderColor ?? this.pointHoverBorderColor,
    extra: extra ?? this.extra,
  );

  @override
  ChartKind get kind => ChartKind.radar;

  @override
  List<Object?>? get chartData => data;

  @override
  void lowerOwn(OptionScope scope) => _lowerLine(scope);

  @override
  List<TypedProperty> get props => [
    ('key', key),
    ('label', label),
    ('data', data),
    ...styleProps,
    ..._lineProps,
    ('extra', byEntries(extra)),
  ];
}
