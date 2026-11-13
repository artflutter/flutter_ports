// Original code, not ported from Chart.js: the datasets of the typed API.

/// The datasets of the typed API (Chart.js ADR 0052, sections 1 and 3):
/// [Dataset], one dataset class for each chart type, and [DataPoint], the
/// object form of a data item.
///
/// A data List goes to the chart by reference: the chart reads the List of
/// the app. The chart does not write into a data List or into a
/// [DataPoint].
library;

import 'dart:ui' show Color, Offset, StrokeCap, StrokeJoin;

import 'package:flutter/foundation.dart'
    show
        DiagnosticPropertiesBuilder,
        Diagnosticable,
        DiagnosticsProperty,
        DoubleProperty,
        Key,
        immutable;
import 'package:flutter_chartjs_port/src/core/data_update.dart'
    show registerDataUpdateTypes;
import 'package:flutter_chartjs_port/src/helpers/cubic_interpolation_mode.dart'
    show CubicInterpolationMode;
import 'package:flutter_chartjs_port/src/helpers/helpers.curve.dart'
    show DefaultCubicInterpolationMode;
import 'package:flutter_chartjs_port/src/helpers/point_style.dart'
    show PointStyle;
import 'package:flutter_chartjs_port/src/helpers/radius_length.dart'
    show RadiusLength;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart' show undefined;
import 'package:flutter_chartjs_port/src/options/option_scope.dart'
    show OptionKey, OptionScope;
import 'package:flutter_chartjs_port/src/options/scopes.g.dart'
    show
        BarControllerDatasetOptionsScope,
        BubbleControllerDatasetOptionsScope,
        DoughnutControllerDatasetOptionsScope,
        GenericDatasetOptionsScope,
        LineControllerDatasetOptionsScope,
        PolarAreaControllerDatasetOptionsScope,
        RadarControllerDatasetOptionsScope,
        TooltipDatasetOptionsScope;
import 'package:flutter_chartjs_port/src/typed/chart_value.dart'
    show ChartValue;
import 'package:flutter_chartjs_port/src/typed/config.dart' show ChartKind;
import 'package:flutter_chartjs_port/src/typed/lower.dart';
import 'package:flutter_chartjs_port/src/typed/props.dart';
import 'package:flutter_chartjs_port/src/typed/values.dart' show ChartFill;
import 'package:flutter_chartjs_port/src/types/chart_axis.dart'
    show CartesianAxis;
import 'package:flutter_chartjs_port/src/types/chart_paint.dart';
import 'package:flutter_chartjs_port/src/types/data_item.dart'
    show TypedDataItem;
import 'package:flutter_chartjs_port/src/types/line_option_enums.dart'
    show SteppedLine;
import 'package:flutter_chartjs_port/src/types/tooltip_callbacks.dart';
import 'package:meta/meta.dart' show internal;

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
/// A dataset is immutable. `==` compares the parameters: a List of data
/// items by identity, a small List of style values by its items, and a
/// function with `==`. Use a method tear-off or a function in a field for
/// resolvers in [backgroundColor] and [borderColor]: a new closure
/// in each build is a new value, and the chart then updates.
@immutable
abstract final class Dataset with Diagnosticable {
  /// The parameters of each dataset class.
  const Dataset({
    this.key,
    this.label,
    this.hidden,
    this.order,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.hoverBackgroundColor,
    this.hoverBorderColor,
    this.hoverBorderWidth,
    this.shadow,
    this.tooltipCallbacks,
    this.extra,
  });

  /// The identity of the dataset when the app gives a new config.
  ///
  /// The chart keeps the state of a dataset, for example its hidden state
  /// and its animations, from one config to the next. Without a key, a
  /// dataset takes the state of the dataset of the same class at the same
  /// index. Give a key to each dataset when the app adds, removes or
  /// reorders datasets. The key is not a Chart.js option.
  final Key? key;

  /// The name of the dataset in the legend and in the tooltip: `label`.
  final String? label;

  /// Whether the dataset is hidden: `hidden`.
  final bool? hidden;

  /// The draw order of the dataset: `order`.
  ///
  /// The chart draws a dataset with a higher order first, so that a dataset
  /// with a lower order is on top of it. The order also sets the order of
  /// the stacks, of the tooltip items and of the legend items. The default
  /// is 0.
  final int? order;

  /// The data-item fill: a constant, indexed list or typed callback.
  /// A null parameter inherits the default. This lowers to `backgroundColor`.
  final ChartValue<ChartPaint>? backgroundColor;

  /// The data-item border: a constant, indexed list or typed callback.
  /// A null parameter inherits the default. This lowers to `borderColor`.
  final ChartValue<ChartPaint>? borderColor;

  /// The border width in pixels: `borderWidth`.
  final double? borderWidth;

  /// The fill color of a data item under the pointer:
  /// `hoverBackgroundColor`.
  final ChartValue<ChartPaint>? hoverBackgroundColor;

  /// The border color of a data item under the pointer: `hoverBorderColor`.
  final ChartValue<ChartPaint>? hoverBorderColor;

  /// The border width of a data item under the pointer, in pixels:
  /// `hoverBorderWidth`.
  final double? hoverBorderWidth;

  /// The shadow of the dataset (Chart.js ADR 0107). It is not a Chart.js
  /// option.
  ///
  /// The shadow falls under the lines, the points, the bars and the arcs of
  /// the dataset. The area fill of a line has no shadow. The keys
  /// `shadowColor`, `shadowBlur`, `shadowOffsetX` and `shadowOffsetY` of the
  /// dataset carry it, so a `ChartView.raw` dataset can set them too.
  final ChartShadow? shadow;

  /// Native per-item tooltip callback overrides for this dataset.
  final TooltipCallbacks? tooltipCallbacks;

  /// The Chart.js options of the dataset that have no parameter, for
  /// example `{'clip': 5}`.
  ///
  /// The entries go into the dataset Map last: an entry wins over a
  /// parameter with the same key. A Map value merges into the Map of the
  /// key, a List or another value replaces it. Thus [extra] also gives a
  /// CSS string, a gradient or the Chart.js `null` of a key. The chart gets
  /// a copy of each Map and the Lists of the app.
  final Map<String, Object?>? extra;

  /// A copy of this dataset with the given parameters.
  ///
  /// A null parameter keeps its value. A new [backgroundColor] or [borderColor]
  /// replaces that color's previous variant independently.
  Dataset copyWith({
    Key? key,
    String? label,
    bool? hidden,
    int? order,
    ChartValue<ChartPaint>? backgroundColor,
    ChartValue<ChartPaint>? borderColor,
    double? borderWidth,
    ChartValue<ChartPaint>? hoverBackgroundColor,
    ChartValue<ChartPaint>? hoverBorderColor,
    double? hoverBorderWidth,
    ChartShadow? shadow,
    TooltipCallbacks? tooltipCallbacks,
    Map<String, Object?>? extra,
  });

  /// The controller id of the dataset class.
  ChartKind get _kind;

  /// The `data` option: the data List or the points List of the app.
  List<Object?>? get _data;

  /// Writes the keys of the dataset class into [scope], after the keys of
  /// [Dataset].
  void _lowerOwn(OptionScope scope);

  /// The properties of the dataset, in parameter order.
  List<TypedProperty> get _props;

  /// The properties of [Dataset] from [hidden] to [hoverBorderWidth].
  List<TypedProperty> get _styleProps => [
    ('hidden', hidden),
    ('order', order),
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
          propsEqual(_props, other._props);

  @override
  int get hashCode => Object.hash(runtimeType, propsHash(_props));

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    addProps(properties, _props);
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
@internal
OptionScope lowerDataset(
  Dataset dataset,
  ChartKind chartType, {
  TooltipCallbacks? Function()? currentTooltipCallbacks,
}) {
  if (!_dataUpdateTypesRegistered) {
    registerDataUpdateTypes(
      [
        <DataPoint>[].runtimeType,
        List<DataPoint>.empty().runtimeType,
        const <DataPoint>[].runtimeType,
      ],
      [DataPoint],
    );
    _dataUpdateTypesRegistered = true;
  }
  final kind = dataset._kind;
  final scope = _datasetScopeOf(kind);
  if (kind != chartType) put(scope, OptionKey.type, kind.name);
  put(scope, OptionKey.label, dataset.label);
  put(scope, OptionKey.data, dataset._data);
  put(scope, OptionKey.hidden, dataset.hidden);
  put(scope, OptionKey.order, dataset.order);
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
  dataset._lowerOwn(scope);
  if (dataset.shadow case final shadow?) {
    // Plain values keep the data-only path of Chart.js ADR 0100.
    mergeExtra(scope, {
      'shadowColor': shadow.color,
      'shadowBlur': shadow.blur,
      'shadowOffsetX': shadow.offset.dx,
      'shadowOffsetY': shadow.offset.dy,
    });
  }
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

/// The shadow of a dataset ([Dataset.shadow], Chart.js ADR 0107): the
/// canvas shadow around the draw of the dataset.
///
/// The values are those of the Canvas 2D shadow: [blur] is `shadowBlur`, so
/// the Gaussian sigma of the blur is `blur / 2`, and [offset] is in logical
/// pixels and does not follow the transform of the canvas.
@immutable
final class ChartShadow with Diagnosticable {
  /// A shadow of [color], blurred by [blur] and moved by [offset].
  const ChartShadow({
    required this.color,
    this.blur = 0,
    this.offset = Offset.zero,
  }) : assert(blur >= 0, 'The blur is not negative.');

  /// The color of the shadow: `shadowColor`. A transparent color draws no
  /// shadow.
  final Color color;

  /// The blur of the shadow: `shadowBlur`. 0 gives a sharp shadow.
  final double blur;

  /// The move of the shadow: `shadowOffsetX` and `shadowOffsetY`.
  final Offset offset;

  /// A copy of this shadow with the given values.
  ChartShadow copyWith({Color? color, double? blur, Offset? offset}) =>
      ChartShadow(
        color: color ?? this.color,
        blur: blur ?? this.blur,
        offset: offset ?? this.offset,
      );

  @override
  bool operator ==(Object other) =>
      other is ChartShadow &&
      other.color == color &&
      other.blur == blur &&
      other.offset == offset;

  @override
  int get hashCode => Object.hash(color, blur, offset);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Color>('color', color))
      ..add(DoubleProperty('blur', blur))
      ..add(DiagnosticsProperty<Offset>('offset', offset));
  }
}

bool _dataUpdateTypesRegistered = false;

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
/// Give the values in [data], one for each label of the chart, or the
/// items in [points]. A bar chart with `indexAxis: const YAxis()` has
/// horizontal bars.
final class BarDataset extends Dataset {
  /// A bar dataset.
  const BarDataset({
    super.key,
    super.label,
    this.data,
    this.points,
    super.hidden,
    super.order,
    super.backgroundColor,
    super.borderColor,
    super.borderWidth,
    super.hoverBackgroundColor,
    super.hoverBorderColor,
    super.hoverBorderWidth,
    super.shadow,
    super.tooltipCallbacks,
    this.xAxisID,
    this.yAxisID,
    this.stack,
    this.indexAxis,
    this.borderRadius,
    this.barPercentage,
    this.categoryPercentage,
    this.barThickness,
    this.maxBarThickness,
    this.minBarLength,
    this.grouped,
    super.extra,
  }) : assert(data == null || points == null, 'Give data or points.');

  /// {@template flutter_chartjs_port.typed.data}
  /// The values of the dataset, one for each label of the chart: `data`.
  /// A `null` value is a gap.
  ///
  /// The chart reads this List: it goes to the chart with no copy. For new
  /// values, give a new List in a new config. Or change this List and call
  /// `chart.update()`. Give [data] or [points], not both.
  /// {@endtemplate}
  final List<num?>? data;

  /// {@template flutter_chartjs_port.typed.points}
  /// The data items in the object form `{x, y}`: `data` with objects
  /// (`docs/general/data-structures.md`).
  ///
  /// The chart reads this List: it goes to the chart with no copy. Give
  /// [data] or [points], not both.
  /// {@endtemplate}
  final List<DataPoint>? points;

  /// {@template flutter_chartjs_port.typed.xAxisID}
  /// The id of the x axis of the dataset, a key of `scales`: `xAxisID`.
  /// The default is the first x axis.
  /// {@endtemplate}
  final String? xAxisID;

  /// {@template flutter_chartjs_port.typed.yAxisID}
  /// The id of the y axis of the dataset, a key of `scales`: `yAxisID`.
  /// The default is the first y axis.
  /// {@endtemplate}
  final String? yAxisID;

  /// {@template flutter_chartjs_port.typed.stack}
  /// The id of the stack of the dataset: `stack`. On a stacked axis, the
  /// datasets with the same stack id stack on each other.
  /// {@endtemplate}
  final String? stack;

  /// {@template flutter_chartjs_port.typed.indexAxis}
  /// The index axis of the dataset: `indexAxis`. The default is the index
  /// axis of the chart.
  /// {@endtemplate}
  final CartesianAxis? indexAxis;

  /// The radius of the bar corners in pixels: `borderRadius` as a number.
  ///
  /// The number rounds the corners that are not on the base of the bar, as
  /// in `docs/samples/bar/border-radius.md`. The object form goes through
  /// [extra].
  final double? borderRadius;

  /// The part of the category width that each bar takes, from 0 to 1:
  /// `barPercentage`. The default is 0.9.
  final double? barPercentage;

  /// The part of the sample width that each category takes, from 0 to 1:
  /// `categoryPercentage`. The default is 0.8.
  final double? categoryPercentage;

  /// The width of each bar in pixels: `barThickness`. The default fits the
  /// bars to the category width. The value `'flex'` goes through [extra].
  final double? barThickness;

  /// The maximum width of each bar in pixels: `maxBarThickness`.
  final double? maxBarThickness;

  /// The minimum length of each bar in pixels: `minBarLength`. A bar with a
  /// small value then stays visible.
  final double? minBarLength;

  /// Whether the bars of the datasets at one index stand next to each
  /// other: `grouped`. The default is `true`.
  final bool? grouped;

  @override
  BarDataset copyWith({
    Key? key,
    String? label,
    List<num?>? data,
    List<DataPoint>? points,
    bool? hidden,
    int? order,
    ChartValue<ChartPaint>? backgroundColor,
    ChartValue<ChartPaint>? borderColor,
    double? borderWidth,
    ChartValue<ChartPaint>? hoverBackgroundColor,
    ChartValue<ChartPaint>? hoverBorderColor,
    double? hoverBorderWidth,
    ChartShadow? shadow,
    TooltipCallbacks? tooltipCallbacks,
    String? xAxisID,
    String? yAxisID,
    String? stack,
    CartesianAxis? indexAxis,
    double? borderRadius,
    double? barPercentage,
    double? categoryPercentage,
    double? barThickness,
    double? maxBarThickness,
    double? minBarLength,
    bool? grouped,
    Map<String, Object?>? extra,
  }) => BarDataset(
    key: key ?? this.key,
    label: label ?? this.label,
    data: data ?? this.data,
    points: points ?? this.points,
    hidden: hidden ?? this.hidden,
    order: order ?? this.order,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    hoverBackgroundColor: hoverBackgroundColor ?? this.hoverBackgroundColor,
    hoverBorderColor: hoverBorderColor ?? this.hoverBorderColor,
    hoverBorderWidth: hoverBorderWidth ?? this.hoverBorderWidth,
    shadow: shadow ?? this.shadow,
    tooltipCallbacks: tooltipCallbacks ?? this.tooltipCallbacks,
    xAxisID: xAxisID ?? this.xAxisID,
    yAxisID: yAxisID ?? this.yAxisID,
    stack: stack ?? this.stack,
    indexAxis: indexAxis ?? this.indexAxis,
    borderRadius: borderRadius ?? this.borderRadius,
    barPercentage: barPercentage ?? this.barPercentage,
    categoryPercentage: categoryPercentage ?? this.categoryPercentage,
    barThickness: barThickness ?? this.barThickness,
    maxBarThickness: maxBarThickness ?? this.maxBarThickness,
    minBarLength: minBarLength ?? this.minBarLength,
    grouped: grouped ?? this.grouped,
    extra: extra ?? this.extra,
  );

  @override
  ChartKind get _kind => ChartKind.bar;

  @override
  List<Object?>? get _data => data ?? points;

  @override
  void _lowerOwn(OptionScope scope) {
    put(scope, OptionKey.xAxisID, xAxisID);
    put(scope, OptionKey.yAxisID, yAxisID);
    put(scope, OptionKey.stack, stack);
    put(scope, OptionKey.indexAxis, indexAxis);
    put(scope, OptionKey.borderRadius, borderRadius);
    put(scope, OptionKey.barPercentage, barPercentage);
    put(scope, OptionKey.categoryPercentage, categoryPercentage);
    put(scope, OptionKey.barThickness, barThickness);
    put(scope, OptionKey.maxBarThickness, maxBarThickness);
    put(scope, OptionKey.minBarLength, minBarLength);
    put(scope, OptionKey.grouped, grouped);
  }

  @override
  List<TypedProperty> get _props => [
    ('key', key),
    ('label', label),
    ('data', data),
    ('points', points),
    ..._styleProps,
    ('xAxisID', xAxisID),
    ('yAxisID', yAxisID),
    ('stack', stack),
    ('indexAxis', indexAxis),
    ('borderRadius', borderRadius),
    ('barPercentage', barPercentage),
    ('categoryPercentage', categoryPercentage),
    ('barThickness', barThickness),
    ('maxBarThickness', maxBarThickness),
    ('minBarLength', minBarLength),
    ('grouped', grouped),
    ('extra', byEntries(extra)),
  ];
}

/// The line style parameters of [LineDataset], [ScatterDataset] and
/// [RadarDataset], in parameter order.
///
/// A mixin of the library: each of the three classes declares the fields.
base mixin _LineStyle on Dataset {
  ChartFill? get fill;
  double? get tension;
  List<double>? get borderDash;
  StrokeCap? get borderCapStyle;
  StrokeJoin? get borderJoinStyle;
  bool? get spanGaps;
  bool? get showLine;
  SteppedLine? get stepped;
  CubicInterpolationMode? get cubicInterpolationMode;
  double? get pointRadius;
  double? get pointHoverRadius;
  PointStyle? get pointStyle;
  ChartValue<ChartPaint>? get pointBackgroundColor;
  ChartValue<ChartPaint>? get pointBorderColor;
  double? get pointBorderWidth;
  ChartValue<ChartPaint>? get pointHoverBackgroundColor;
  ChartValue<ChartPaint>? get pointHoverBorderColor;

  /// Writes the keys of the line style into [scope].
  void _lowerLine(OptionScope scope) {
    put(scope, OptionKey.fill, fill?.optionValue);
    put(scope, OptionKey.tension, tension);
    put(scope, OptionKey.borderDash, numberList(borderDash));
    put(scope, OptionKey.borderCapStyle, borderCapStyle);
    put(scope, OptionKey.borderJoinStyle, borderJoinStyle);
    put(scope, OptionKey.spanGaps, spanGaps);
    put(scope, OptionKey.showLine, showLine);
    put(scope, OptionKey.stepped, stepped);
    put(scope, OptionKey.cubicInterpolationMode, cubicInterpolationMode);
    put(scope, OptionKey.pointRadius, pointRadius);
    put(scope, OptionKey.pointHoverRadius, pointHoverRadius);
    put(scope, OptionKey.pointStyle, pointStyle);
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
/// Give the values in [data], one for each label of the chart, or the
/// items in [points]. The line style parameters set the line, the fill and
/// the points.
final class LineDataset extends Dataset with _LineStyle {
  /// A line dataset.
  const LineDataset({
    super.key,
    super.label,
    this.data,
    this.points,
    super.hidden,
    super.order,
    super.backgroundColor,
    super.borderColor,
    super.borderWidth,
    super.hoverBackgroundColor,
    super.hoverBorderColor,
    super.hoverBorderWidth,
    super.shadow,
    super.tooltipCallbacks,
    this.xAxisID,
    this.yAxisID,
    this.stack,
    this.indexAxis,
    this.fill,
    this.tension,
    this.borderDash,
    this.borderCapStyle,
    this.borderJoinStyle,
    this.spanGaps,
    this.showLine,
    this.stepped,
    this.cubicInterpolationMode,
    this.pointRadius,
    this.pointHoverRadius,
    this.pointStyle,
    this.pointBackgroundColor,
    this.pointBorderColor,
    this.pointBorderWidth,
    this.pointHoverBackgroundColor,
    this.pointHoverBorderColor,
    super.extra,
  }) : assert(data == null || points == null, 'Give data or points.');

  /// {@macro flutter_chartjs_port.typed.data}
  final List<num?>? data;

  /// {@macro flutter_chartjs_port.typed.points}
  final List<DataPoint>? points;

  /// {@macro flutter_chartjs_port.typed.xAxisID}
  final String? xAxisID;

  /// {@macro flutter_chartjs_port.typed.yAxisID}
  final String? yAxisID;

  /// {@macro flutter_chartjs_port.typed.stack}
  final String? stack;

  /// {@macro flutter_chartjs_port.typed.indexAxis}
  final CartesianAxis? indexAxis;

  /// {@template flutter_chartjs_port.typed.fill}
  /// The fill of the area under or between the lines: `fill`
  /// (`docs/charts/area.md`). The default is no fill. The colors plugin of
  /// Chart.js and the filler plugin read it.
  /// {@endtemplate}
  @override
  final ChartFill? fill;

  /// {@template flutter_chartjs_port.typed.tension}
  /// The Bézier curve tension of the line, from 0 (straight lines) to 1:
  /// `tension`. The default is 0.
  /// {@endtemplate}
  @override
  final double? tension;

  /// {@template flutter_chartjs_port.typed.borderDash}
  /// The dash pattern of the line, lengths of dashes and gaps in pixels:
  /// `borderDash`. The default is a solid line.
  /// {@endtemplate}
  @override
  final List<double>? borderDash;

  /// {@template flutter_chartjs_port.typed.borderCapStyle}
  /// The shape of the ends of the line: `borderCapStyle`, a Flutter
  /// [StrokeCap]. The default is [StrokeCap.butt].
  /// {@endtemplate}
  @override
  final StrokeCap? borderCapStyle;

  /// {@template flutter_chartjs_port.typed.borderJoinStyle}
  /// The shape of the corners of the line: `borderJoinStyle`, a Flutter
  /// [StrokeJoin]. The default is [StrokeJoin.miter].
  /// {@endtemplate}
  @override
  final StrokeJoin? borderJoinStyle;

  /// {@template flutter_chartjs_port.typed.spanGaps}
  /// Whether the line spans the gaps of `null` values: `spanGaps` as a
  /// boolean. The default is `false`. The number form goes through `extra`.
  /// {@endtemplate}
  @override
  final bool? spanGaps;

  /// {@template flutter_chartjs_port.typed.showLine}
  /// Whether the chart draws the line: `showLine`. Without the line, the
  /// chart draws the points only.
  /// {@endtemplate}
  @override
  final bool? showLine;

  /// {@template flutter_chartjs_port.typed.stepped}
  /// The form of a stepped line: `stepped`, a [SteppedLine] (row
  /// `adapt-stepped-line-enum`). Dart `null`, the default, draws no steps.
  /// {@endtemplate}
  @override
  final SteppedLine? stepped;

  /// {@template flutter_chartjs_port.typed.cubicInterpolationMode}
  /// The mode of the control points of a curved line:
  /// `cubicInterpolationMode`, a [CubicInterpolationMode] (row
  /// `adapt-cubic-interpolation-mode-objects`). Dart `null` keeps the
  /// default, [DefaultCubicInterpolationMode].
  /// {@endtemplate}
  @override
  final CubicInterpolationMode? cubicInterpolationMode;

  /// {@template flutter_chartjs_port.typed.pointRadius}
  /// The radius of the points in pixels: `pointRadius`. 0 draws no points.
  /// {@endtemplate}
  @override
  final double? pointRadius;

  /// {@template flutter_chartjs_port.typed.pointHoverRadius}
  /// The radius of a point under the pointer, in pixels:
  /// `pointHoverRadius`.
  /// {@endtemplate}
  @override
  final double? pointHoverRadius;

  /// {@template flutter_chartjs_port.typed.pointStyle}
  /// The style of the points: `pointStyle`, a [PointStyle] (row
  /// `adapt-point-style-objects`). `false`, no point, goes through `extra`.
  /// {@endtemplate}
  @override
  final PointStyle? pointStyle;

  /// {@template flutter_chartjs_port.typed.pointBackgroundColor}
  /// The fill color of the points: `pointBackgroundColor`.
  /// {@endtemplate}
  @override
  final ChartValue<ChartPaint>? pointBackgroundColor;

  /// {@template flutter_chartjs_port.typed.pointBorderColor}
  /// The border color of the points: `pointBorderColor`.
  /// {@endtemplate}
  @override
  final ChartValue<ChartPaint>? pointBorderColor;

  /// {@template flutter_chartjs_port.typed.pointBorderWidth}
  /// The border width of the points in pixels: `pointBorderWidth`.
  /// {@endtemplate}
  @override
  final double? pointBorderWidth;

  /// {@template flutter_chartjs_port.typed.pointHoverBackgroundColor}
  /// The fill color of a point under the pointer:
  /// `pointHoverBackgroundColor`.
  /// {@endtemplate}
  @override
  final ChartValue<ChartPaint>? pointHoverBackgroundColor;

  /// {@template flutter_chartjs_port.typed.pointHoverBorderColor}
  /// The border color of a point under the pointer: `pointHoverBorderColor`.
  /// {@endtemplate}
  @override
  final ChartValue<ChartPaint>? pointHoverBorderColor;

  @override
  LineDataset copyWith({
    Key? key,
    String? label,
    List<num?>? data,
    List<DataPoint>? points,
    bool? hidden,
    int? order,
    ChartValue<ChartPaint>? backgroundColor,
    ChartValue<ChartPaint>? borderColor,
    double? borderWidth,
    ChartValue<ChartPaint>? hoverBackgroundColor,
    ChartValue<ChartPaint>? hoverBorderColor,
    double? hoverBorderWidth,
    ChartShadow? shadow,
    TooltipCallbacks? tooltipCallbacks,
    String? xAxisID,
    String? yAxisID,
    String? stack,
    CartesianAxis? indexAxis,
    ChartFill? fill,
    double? tension,
    List<double>? borderDash,
    StrokeCap? borderCapStyle,
    StrokeJoin? borderJoinStyle,
    bool? spanGaps,
    bool? showLine,
    SteppedLine? stepped,
    CubicInterpolationMode? cubicInterpolationMode,
    double? pointRadius,
    double? pointHoverRadius,
    PointStyle? pointStyle,
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
    points: points ?? this.points,
    hidden: hidden ?? this.hidden,
    order: order ?? this.order,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    hoverBackgroundColor: hoverBackgroundColor ?? this.hoverBackgroundColor,
    hoverBorderColor: hoverBorderColor ?? this.hoverBorderColor,
    hoverBorderWidth: hoverBorderWidth ?? this.hoverBorderWidth,
    shadow: shadow ?? this.shadow,
    tooltipCallbacks: tooltipCallbacks ?? this.tooltipCallbacks,
    xAxisID: xAxisID ?? this.xAxisID,
    yAxisID: yAxisID ?? this.yAxisID,
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
  ChartKind get _kind => ChartKind.line;

  @override
  List<Object?>? get _data => data ?? points;

  @override
  void _lowerOwn(OptionScope scope) {
    put(scope, OptionKey.xAxisID, xAxisID);
    put(scope, OptionKey.yAxisID, yAxisID);
    put(scope, OptionKey.stack, stack);
    put(scope, OptionKey.indexAxis, indexAxis);
    _lowerLine(scope);
  }

  @override
  List<TypedProperty> get _props => [
    ('key', key),
    ('label', label),
    ('data', data),
    ('points', points),
    ..._styleProps,
    ('xAxisID', xAxisID),
    ('yAxisID', yAxisID),
    ('stack', stack),
    ('indexAxis', indexAxis),
    ..._lineProps,
    ('extra', byEntries(extra)),
  ];
}

/// A dataset of a scatter chart: the scatter controller
/// (`docs/charts/scatter.md`).
///
/// Give the items in [points], with a number `x`. A scatter chart draws the
/// points with no line. Set [showLine] for a line.
final class ScatterDataset extends Dataset with _LineStyle {
  /// A scatter dataset.
  const ScatterDataset({
    super.key,
    super.label,
    this.data,
    this.points,
    super.hidden,
    super.order,
    super.backgroundColor,
    super.borderColor,
    super.borderWidth,
    super.hoverBackgroundColor,
    super.hoverBorderColor,
    super.hoverBorderWidth,
    super.shadow,
    super.tooltipCallbacks,
    this.xAxisID,
    this.yAxisID,
    this.stack,
    this.fill,
    this.tension,
    this.borderDash,
    this.borderCapStyle,
    this.borderJoinStyle,
    this.spanGaps,
    this.showLine,
    this.stepped,
    this.cubicInterpolationMode,
    this.pointRadius,
    this.pointHoverRadius,
    this.pointStyle,
    this.pointBackgroundColor,
    this.pointBorderColor,
    this.pointBorderWidth,
    this.pointHoverBackgroundColor,
    this.pointHoverBorderColor,
    super.extra,
  }) : assert(data == null || points == null, 'Give data or points.');

  /// {@macro flutter_chartjs_port.typed.data}
  final List<num?>? data;

  /// {@macro flutter_chartjs_port.typed.points}
  final List<DataPoint>? points;

  /// {@macro flutter_chartjs_port.typed.xAxisID}
  final String? xAxisID;

  /// {@macro flutter_chartjs_port.typed.yAxisID}
  final String? yAxisID;

  /// {@macro flutter_chartjs_port.typed.stack}
  final String? stack;

  /// {@macro flutter_chartjs_port.typed.fill}
  @override
  final ChartFill? fill;

  /// {@macro flutter_chartjs_port.typed.tension}
  @override
  final double? tension;

  /// {@macro flutter_chartjs_port.typed.borderDash}
  @override
  final List<double>? borderDash;

  /// {@macro flutter_chartjs_port.typed.borderCapStyle}
  @override
  final StrokeCap? borderCapStyle;

  /// {@macro flutter_chartjs_port.typed.borderJoinStyle}
  @override
  final StrokeJoin? borderJoinStyle;

  /// {@macro flutter_chartjs_port.typed.spanGaps}
  @override
  final bool? spanGaps;

  /// {@macro flutter_chartjs_port.typed.showLine}
  ///
  /// The default of a scatter dataset is `false`.
  @override
  final bool? showLine;

  /// {@macro flutter_chartjs_port.typed.stepped}
  @override
  final SteppedLine? stepped;

  /// {@macro flutter_chartjs_port.typed.cubicInterpolationMode}
  @override
  final CubicInterpolationMode? cubicInterpolationMode;

  /// {@macro flutter_chartjs_port.typed.pointRadius}
  @override
  final double? pointRadius;

  /// {@macro flutter_chartjs_port.typed.pointHoverRadius}
  @override
  final double? pointHoverRadius;

  /// {@macro flutter_chartjs_port.typed.pointStyle}
  @override
  final PointStyle? pointStyle;

  /// {@macro flutter_chartjs_port.typed.pointBackgroundColor}
  @override
  final ChartValue<ChartPaint>? pointBackgroundColor;

  /// {@macro flutter_chartjs_port.typed.pointBorderColor}
  @override
  final ChartValue<ChartPaint>? pointBorderColor;

  /// {@macro flutter_chartjs_port.typed.pointBorderWidth}
  @override
  final double? pointBorderWidth;

  /// {@macro flutter_chartjs_port.typed.pointHoverBackgroundColor}
  @override
  final ChartValue<ChartPaint>? pointHoverBackgroundColor;

  /// {@macro flutter_chartjs_port.typed.pointHoverBorderColor}
  @override
  final ChartValue<ChartPaint>? pointHoverBorderColor;

  @override
  ScatterDataset copyWith({
    Key? key,
    String? label,
    List<num?>? data,
    List<DataPoint>? points,
    bool? hidden,
    int? order,
    ChartValue<ChartPaint>? backgroundColor,
    ChartValue<ChartPaint>? borderColor,
    double? borderWidth,
    ChartValue<ChartPaint>? hoverBackgroundColor,
    ChartValue<ChartPaint>? hoverBorderColor,
    double? hoverBorderWidth,
    ChartShadow? shadow,
    TooltipCallbacks? tooltipCallbacks,
    String? xAxisID,
    String? yAxisID,
    String? stack,
    ChartFill? fill,
    double? tension,
    List<double>? borderDash,
    StrokeCap? borderCapStyle,
    StrokeJoin? borderJoinStyle,
    bool? spanGaps,
    bool? showLine,
    SteppedLine? stepped,
    CubicInterpolationMode? cubicInterpolationMode,
    double? pointRadius,
    double? pointHoverRadius,
    PointStyle? pointStyle,
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
    points: points ?? this.points,
    hidden: hidden ?? this.hidden,
    order: order ?? this.order,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    hoverBackgroundColor: hoverBackgroundColor ?? this.hoverBackgroundColor,
    hoverBorderColor: hoverBorderColor ?? this.hoverBorderColor,
    hoverBorderWidth: hoverBorderWidth ?? this.hoverBorderWidth,
    shadow: shadow ?? this.shadow,
    tooltipCallbacks: tooltipCallbacks ?? this.tooltipCallbacks,
    xAxisID: xAxisID ?? this.xAxisID,
    yAxisID: yAxisID ?? this.yAxisID,
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
  ChartKind get _kind => ChartKind.scatter;

  @override
  List<Object?>? get _data => data ?? points;

  @override
  void _lowerOwn(OptionScope scope) {
    put(scope, OptionKey.xAxisID, xAxisID);
    put(scope, OptionKey.yAxisID, yAxisID);
    put(scope, OptionKey.stack, stack);
    _lowerLine(scope);
  }

  @override
  List<TypedProperty> get _props => [
    ('key', key),
    ('label', label),
    ('data', data),
    ('points', points),
    ..._styleProps,
    ('xAxisID', xAxisID),
    ('yAxisID', yAxisID),
    ('stack', stack),
    ..._lineProps,
    ('extra', byEntries(extra)),
  ];
}

/// A dataset of a bubble chart: the bubble controller
/// (`docs/charts/bubble.md`).
///
/// Give the items in [points], each a [DataPoint.bubble] with its radius.
final class BubbleDataset extends Dataset {
  /// A bubble dataset.
  const BubbleDataset({
    super.key,
    super.label,
    this.points,
    super.hidden,
    super.order,
    super.backgroundColor,
    super.borderColor,
    super.borderWidth,
    super.hoverBackgroundColor,
    super.hoverBorderColor,
    super.hoverBorderWidth,
    super.shadow,
    super.tooltipCallbacks,
    this.xAxisID,
    this.yAxisID,
    this.radius,
    this.hoverRadius,
    this.pointStyle,
    super.extra,
  });

  /// The bubbles in the object form `{x, y, r}`: `data` with objects. Each
  /// item is a [DataPoint.bubble].
  ///
  /// The chart reads this List: it goes to the chart with no copy.
  final List<DataPoint>? points;

  /// {@macro flutter_chartjs_port.typed.xAxisID}
  final String? xAxisID;

  /// {@macro flutter_chartjs_port.typed.yAxisID}
  final String? yAxisID;

  /// The radius of a bubble without an `r` value, in pixels: `radius`.
  final double? radius;

  /// The radius that a bubble under the pointer adds, in pixels:
  /// `hoverRadius`.
  final double? hoverRadius;

  /// The style of the bubbles: `pointStyle`, a [PointStyle] (row
  /// `adapt-point-style-objects`).
  final PointStyle? pointStyle;

  @override
  BubbleDataset copyWith({
    Key? key,
    String? label,
    List<DataPoint>? points,
    bool? hidden,
    int? order,
    ChartValue<ChartPaint>? backgroundColor,
    ChartValue<ChartPaint>? borderColor,
    double? borderWidth,
    ChartValue<ChartPaint>? hoverBackgroundColor,
    ChartValue<ChartPaint>? hoverBorderColor,
    double? hoverBorderWidth,
    ChartShadow? shadow,
    TooltipCallbacks? tooltipCallbacks,
    String? xAxisID,
    String? yAxisID,
    double? radius,
    double? hoverRadius,
    PointStyle? pointStyle,
    Map<String, Object?>? extra,
  }) => BubbleDataset(
    key: key ?? this.key,
    label: label ?? this.label,
    points: points ?? this.points,
    hidden: hidden ?? this.hidden,
    order: order ?? this.order,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    hoverBackgroundColor: hoverBackgroundColor ?? this.hoverBackgroundColor,
    hoverBorderColor: hoverBorderColor ?? this.hoverBorderColor,
    hoverBorderWidth: hoverBorderWidth ?? this.hoverBorderWidth,
    shadow: shadow ?? this.shadow,
    tooltipCallbacks: tooltipCallbacks ?? this.tooltipCallbacks,
    xAxisID: xAxisID ?? this.xAxisID,
    yAxisID: yAxisID ?? this.yAxisID,
    radius: radius ?? this.radius,
    hoverRadius: hoverRadius ?? this.hoverRadius,
    pointStyle: pointStyle ?? this.pointStyle,
    extra: extra ?? this.extra,
  );

  @override
  ChartKind get _kind => ChartKind.bubble;

  @override
  List<Object?>? get _data => points;

  @override
  void _lowerOwn(OptionScope scope) {
    put(scope, OptionKey.xAxisID, xAxisID);
    put(scope, OptionKey.yAxisID, yAxisID);
    put(scope, OptionKey.radius, radius);
    put(scope, OptionKey.hoverRadius, hoverRadius);
    put(scope, OptionKey.pointStyle, pointStyle);
  }

  @override
  List<TypedProperty> get _props => [
    ('key', key),
    ('label', label),
    ('points', points),
    ..._styleProps,
    ('xAxisID', xAxisID),
    ('yAxisID', yAxisID),
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
final class PieDataset extends Dataset with _ArcStyle {
  /// A pie dataset.
  const PieDataset({
    super.key,
    super.label,
    this.data,
    super.hidden,
    super.order,
    super.backgroundColor,
    super.borderColor,
    super.borderWidth,
    super.hoverBackgroundColor,
    super.hoverBorderColor,
    super.hoverBorderWidth,
    super.shadow,
    super.tooltipCallbacks,
    this.offset,
    this.hoverOffset,
    this.spacing,
    this.weight,
    this.circumference,
    this.rotation,
    this.cutout,
    this.radius,
    super.extra,
  });

  /// {@template flutter_chartjs_port.typed.arcData}
  /// The values of the dataset, one for each label of the chart: `data`.
  ///
  /// The chart reads this List: it goes to the chart with no copy. For new
  /// values, give a new List in a new config. Or change this List and call
  /// `chart.update()`.
  /// {@endtemplate}
  final List<num?>? data;

  /// {@template flutter_chartjs_port.typed.offset}
  /// The offset of each arc from the center, in pixels: `offset`.
  /// {@endtemplate}
  @override
  final double? offset;

  /// {@template flutter_chartjs_port.typed.hoverOffset}
  /// The offset of an arc under the pointer, in pixels: `hoverOffset`.
  /// {@endtemplate}
  @override
  final double? hoverOffset;

  /// {@template flutter_chartjs_port.typed.spacing}
  /// The space between the arcs, in pixels: `spacing`.
  /// {@endtemplate}
  @override
  final double? spacing;

  /// {@template flutter_chartjs_port.typed.weight}
  /// The weight of the dataset ring: `weight`. The rings of the datasets
  /// share the radius in the proportion of their weights. The default is
  /// 1.
  /// {@endtemplate}
  @override
  final double? weight;

  /// {@template flutter_chartjs_port.typed.circumference}
  /// The sweep of the arcs in degrees: `circumference`. The default is
  /// 360.
  /// {@endtemplate}
  @override
  final double? circumference;

  /// {@template flutter_chartjs_port.typed.rotation}
  /// The start angle of the arcs in degrees, from the top, clockwise:
  /// `rotation`. The default is 0.
  /// {@endtemplate}
  @override
  final double? rotation;

  /// {@template flutter_chartjs_port.typed.cutout}
  /// The radius of the hole in the center: `cutout`, a [RadiusLength] (row
  /// `adapt-length-objects`): `PercentRadius(50)` is a part of the outer
  /// radius, `PixelRadius(40)` pixels.
  /// {@endtemplate}
  ///
  /// The default of a pie is 0, no hole.
  @override
  final RadiusLength? cutout;

  /// {@template flutter_chartjs_port.typed.radius}
  /// The outer radius: `radius`, a [RadiusLength]: `PercentRadius(100)`, the
  /// default, is a part of the largest radius that fits the chart area,
  /// `PixelRadius(150)` pixels.
  /// {@endtemplate}
  @override
  final RadiusLength? radius;

  @override
  PieDataset copyWith({
    Key? key,
    String? label,
    List<num?>? data,
    bool? hidden,
    int? order,
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
  ChartKind get _kind => ChartKind.pie;

  @override
  List<Object?>? get _data => data;

  @override
  void _lowerOwn(OptionScope scope) => _lowerArc(scope);

  @override
  List<TypedProperty> get _props => [
    ('key', key),
    ('label', label),
    ('data', data),
    ..._styleProps,
    ..._arcProps,
    ('extra', byEntries(extra)),
  ];
}

/// A dataset of a doughnut chart: the doughnut controller
/// (`docs/charts/doughnut.md`).
///
/// A doughnut has a hole in the center: the default [cutout] is 50
/// percent. A doughnut dataset in a pie chart keeps the doughnut cutout.
final class DoughnutDataset extends Dataset with _ArcStyle {
  /// A doughnut dataset.
  const DoughnutDataset({
    super.key,
    super.label,
    this.data,
    super.hidden,
    super.order,
    super.backgroundColor,
    super.borderColor,
    super.borderWidth,
    super.hoverBackgroundColor,
    super.hoverBorderColor,
    super.hoverBorderWidth,
    super.shadow,
    super.tooltipCallbacks,
    this.offset,
    this.hoverOffset,
    this.spacing,
    this.weight,
    this.circumference,
    this.rotation,
    this.cutout,
    this.radius,
    super.extra,
  });

  /// {@macro flutter_chartjs_port.typed.arcData}
  final List<num?>? data;

  /// {@macro flutter_chartjs_port.typed.offset}
  @override
  final double? offset;

  /// {@macro flutter_chartjs_port.typed.hoverOffset}
  @override
  final double? hoverOffset;

  /// {@macro flutter_chartjs_port.typed.spacing}
  @override
  final double? spacing;

  /// {@macro flutter_chartjs_port.typed.weight}
  @override
  final double? weight;

  /// {@macro flutter_chartjs_port.typed.circumference}
  @override
  final double? circumference;

  /// {@macro flutter_chartjs_port.typed.rotation}
  @override
  final double? rotation;

  /// {@macro flutter_chartjs_port.typed.cutout}
  ///
  /// The default of a doughnut is 50 percent.
  @override
  final RadiusLength? cutout;

  /// {@macro flutter_chartjs_port.typed.radius}
  @override
  final RadiusLength? radius;

  @override
  DoughnutDataset copyWith({
    Key? key,
    String? label,
    List<num?>? data,
    bool? hidden,
    int? order,
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
  ChartKind get _kind => ChartKind.doughnut;

  @override
  List<Object?>? get _data => data;

  @override
  void _lowerOwn(OptionScope scope) => _lowerArc(scope);

  @override
  List<TypedProperty> get _props => [
    ('key', key),
    ('label', label),
    ('data', data),
    ..._styleProps,
    ..._arcProps,
    ('extra', byEntries(extra)),
  ];
}

/// A dataset of a polar area chart: the polar area controller
/// (`docs/charts/polar.md`).
///
/// Each data item is an arc with the same angle and a radius of its value
/// on the radial axis `r`.
final class PolarAreaDataset extends Dataset {
  /// A polar area dataset.
  const PolarAreaDataset({
    super.key,
    super.label,
    this.data,
    super.hidden,
    super.order,
    super.backgroundColor,
    super.borderColor,
    super.borderWidth,
    super.hoverBackgroundColor,
    super.hoverBorderColor,
    super.hoverBorderWidth,
    super.shadow,
    super.tooltipCallbacks,
    this.offset,
    this.hoverOffset,
    this.spacing,
    super.extra,
  });

  /// {@macro flutter_chartjs_port.typed.arcData}
  final List<num?>? data;

  /// {@macro flutter_chartjs_port.typed.offset}
  final double? offset;

  /// {@macro flutter_chartjs_port.typed.hoverOffset}
  final double? hoverOffset;

  /// {@macro flutter_chartjs_port.typed.spacing}
  final double? spacing;

  @override
  PolarAreaDataset copyWith({
    Key? key,
    String? label,
    List<num?>? data,
    bool? hidden,
    int? order,
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
  ChartKind get _kind => ChartKind.polarArea;

  @override
  List<Object?>? get _data => data;

  @override
  void _lowerOwn(OptionScope scope) {
    put(scope, OptionKey.offset, offset);
    put(scope, OptionKey.hoverOffset, hoverOffset);
    put(scope, OptionKey.spacing, spacing);
  }

  @override
  List<TypedProperty> get _props => [
    ('key', key),
    ('label', label),
    ('data', data),
    ..._styleProps,
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
final class RadarDataset extends Dataset with _LineStyle {
  /// A radar dataset.
  const RadarDataset({
    super.key,
    super.label,
    this.data,
    super.hidden,
    super.order,
    super.backgroundColor,
    super.borderColor,
    super.borderWidth,
    super.hoverBackgroundColor,
    super.hoverBorderColor,
    super.hoverBorderWidth,
    super.shadow,
    super.tooltipCallbacks,
    this.fill,
    this.tension,
    this.borderDash,
    this.borderCapStyle,
    this.borderJoinStyle,
    this.spanGaps,
    this.showLine,
    this.stepped,
    this.cubicInterpolationMode,
    this.pointRadius,
    this.pointHoverRadius,
    this.pointStyle,
    this.pointBackgroundColor,
    this.pointBorderColor,
    this.pointBorderWidth,
    this.pointHoverBackgroundColor,
    this.pointHoverBorderColor,
    super.extra,
  });

  /// {@macro flutter_chartjs_port.typed.arcData}
  final List<num?>? data;

  /// {@macro flutter_chartjs_port.typed.fill}
  @override
  final ChartFill? fill;

  /// {@macro flutter_chartjs_port.typed.tension}
  @override
  final double? tension;

  /// {@macro flutter_chartjs_port.typed.borderDash}
  @override
  final List<double>? borderDash;

  /// {@macro flutter_chartjs_port.typed.borderCapStyle}
  @override
  final StrokeCap? borderCapStyle;

  /// {@macro flutter_chartjs_port.typed.borderJoinStyle}
  @override
  final StrokeJoin? borderJoinStyle;

  /// {@macro flutter_chartjs_port.typed.spanGaps}
  @override
  final bool? spanGaps;

  /// {@macro flutter_chartjs_port.typed.showLine}
  @override
  final bool? showLine;

  /// {@macro flutter_chartjs_port.typed.stepped}
  @override
  final SteppedLine? stepped;

  /// {@macro flutter_chartjs_port.typed.cubicInterpolationMode}
  @override
  final CubicInterpolationMode? cubicInterpolationMode;

  /// {@macro flutter_chartjs_port.typed.pointRadius}
  @override
  final double? pointRadius;

  /// {@macro flutter_chartjs_port.typed.pointHoverRadius}
  @override
  final double? pointHoverRadius;

  /// {@macro flutter_chartjs_port.typed.pointStyle}
  @override
  final PointStyle? pointStyle;

  /// {@macro flutter_chartjs_port.typed.pointBackgroundColor}
  @override
  final ChartValue<ChartPaint>? pointBackgroundColor;

  /// {@macro flutter_chartjs_port.typed.pointBorderColor}
  @override
  final ChartValue<ChartPaint>? pointBorderColor;

  /// {@macro flutter_chartjs_port.typed.pointBorderWidth}
  @override
  final double? pointBorderWidth;

  /// {@macro flutter_chartjs_port.typed.pointHoverBackgroundColor}
  @override
  final ChartValue<ChartPaint>? pointHoverBackgroundColor;

  /// {@macro flutter_chartjs_port.typed.pointHoverBorderColor}
  @override
  final ChartValue<ChartPaint>? pointHoverBorderColor;

  @override
  RadarDataset copyWith({
    Key? key,
    String? label,
    List<num?>? data,
    bool? hidden,
    int? order,
    ChartValue<ChartPaint>? backgroundColor,
    ChartValue<ChartPaint>? borderColor,
    double? borderWidth,
    ChartValue<ChartPaint>? hoverBackgroundColor,
    ChartValue<ChartPaint>? hoverBorderColor,
    double? hoverBorderWidth,
    ChartShadow? shadow,
    TooltipCallbacks? tooltipCallbacks,
    ChartFill? fill,
    double? tension,
    List<double>? borderDash,
    StrokeCap? borderCapStyle,
    StrokeJoin? borderJoinStyle,
    bool? spanGaps,
    bool? showLine,
    SteppedLine? stepped,
    CubicInterpolationMode? cubicInterpolationMode,
    double? pointRadius,
    double? pointHoverRadius,
    PointStyle? pointStyle,
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
  ChartKind get _kind => ChartKind.radar;

  @override
  List<Object?>? get _data => data;

  @override
  void _lowerOwn(OptionScope scope) => _lowerLine(scope);

  @override
  List<TypedProperty> get _props => [
    ('key', key),
    ('label', label),
    ('data', data),
    ..._styleProps,
    ..._lineProps,
    ('extra', byEntries(extra)),
  ];
}

/// `value.toDouble()` in another form: a `double` stays, and an `int` is
/// multiplied by 1.0.
///
/// In an AOT build `num.toDouble()` is a call, and for an `int` from 2^30 on
/// Android it is a runtime call (dart-lang/sdk issue 64209). The product of
/// a static `int` and 1.0 is an inline conversion. dart2js emits the same
/// code for both forms.
@pragma('vm:prefer-inline')
@pragma('dart2js:prefer-inline')
@pragma('wasm:prefer-inline')
double _toDouble(num value) => value is double ? value : (value as int) * 1.0;

/// A data item in the object form `{x, y}` or `{x, y, r}`
/// (`docs/general/data-structures.md`, "Object[]").
///
/// A data point is a typed data item (Chart.js ADR 0054 §7): the chart
/// reads its fields [x], [y] and [r] where Chart.js reads the keys of the
/// object `{x, y}`. Thus a `List<DataPoint>` goes to the chart with no
/// copy. A data point does not implement `Map`.
///
/// A number is a `double`, as each number of Chart.js. A `null` [y] is a
/// gap in the line.
///
/// A data point is immutable: the chart does not write into it. Code that
/// writes a key into it by name gets the `TypeError` of a write into a
/// frozen object (`Object.freeze`).
@immutable
final class DataPoint implements TypedDataItem {
  /// `{x, y}` with a number [x]: a value of a linear or a logarithmic x
  /// axis, or an index of a category x axis.
  DataPoint(num x, num? y)
    : x = _toDouble(x),
      y = y == null ? null : _toDouble(y),
      r = null;

  /// `{x, y}` with a time [x], for a time or a time series x axis.
  DataPoint.time(DateTime this.x, num? y)
    : y = y == null ? null : _toDouble(y),
      r = null;

  /// `{x, y}` with a label [x], for a category x axis. A label that is not
  /// in the labels of the chart becomes a new label: the category scale adds
  /// it to `data.labels`.
  DataPoint.label(String this.x, num? y)
    : y = y == null ? null : _toDouble(y),
      r = null;

  /// `{x, y, r}`: a bubble at ([x], [y]) with the radius [r] in pixels.
  DataPoint.bubble(num x, num y, num r)
    : x = _toDouble(x),
      y = _toDouble(y),
      r = _toDouble(r);

  /// The x value: a `double`, a `DateTime` or a `String`.
  @override
  final Object x;

  /// The y value. `null` is a gap.
  @override
  final double? y;

  /// The bubble radius in pixels, or `null` for a data point that is not a
  /// bubble.
  @override
  final double? r;

  // The face of Chart.js ADR 0054 §5: the object `{x, y}` or `{x, y, r}`.

  /// `point[name]`: [x], [y] (Dart `null` is JS `null`), [r] when the point
  /// has it, else `undefined`.
  @internal
  @override
  Object? jsRead(String name) => switch (name) {
    'x' => x,
    'y' => y,
    'r' when r != null => r,
    _ => undefined,
  };

  /// `point[name] = value`: a data point is frozen. A `TypeError`, as a
  /// write into a frozen object in strict mode.
  @internal
  @override
  void jsWrite(String name, Object? value) => throw TypeError();

  /// `point[name]`: [jsRead].
  @internal
  @override
  Object? operator [](String name) => jsRead(name);

  /// `point[name] = value`: [jsWrite], a `TypeError`.
  @internal
  @override
  void operator []=(String name, Object? value) => jsWrite(name, value);

  /// `Object.keys(point)`: `x`, `y` and, for a bubble, `r`.
  @internal
  @override
  List<String> jsKeys() => r == null ? const ['x', 'y'] : const ['x', 'y', 'r'];

  /// Whether the point has the key [name].
  @internal
  @override
  bool jsHas(String name) =>
      name == 'x' || name == 'y' || (name == 'r' && r != null);

  /// `delete point[name]`: a data point is frozen. A `TypeError` for an own
  /// key, as a delete of a key of a frozen object in strict mode.
  @internal
  @override
  bool jsDelete(String name) {
    if (jsHas(name)) throw TypeError();
    return true;
  }

  @override
  String toString() =>
      r == null ? 'DataPoint($x, $y)' : 'DataPoint($x, $y, $r)';
}
