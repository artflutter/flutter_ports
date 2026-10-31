// Original code, not ported from Chart.js: the datasets of the typed API.

/// The datasets of the typed API (Chart.js ADR 0052, sections 1 and 3):
/// [Dataset], one dataset class for each chart type, and [DataPoint], the
/// object form of a data item.
///
/// A data List goes to the chart by reference: the chart reads the List of
/// the app. The chart does not write into a data List or into a
/// [DataPoint].
library;

import 'dart:ui' show Color;

import 'package:flutter/foundation.dart'
    show DiagnosticPropertiesBuilder, Diagnosticable, Key, immutable;
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
        RadarControllerDatasetOptionsScope;
import 'package:flutter_chartjs_port/src/typed/callbacks.dart' show ChartScript;
import 'package:flutter_chartjs_port/src/typed/config.dart'
    show ChartKind, IndexAxis;
import 'package:flutter_chartjs_port/src/typed/lower.dart';
import 'package:flutter_chartjs_port/src/typed/props.dart';
import 'package:flutter_chartjs_port/src/typed/values.dart'
    show ChartFill, ChartLength, ChartPointStyle;
import 'package:flutter_chartjs_port/src/types/data_item.dart'
    show TypedDataItem;
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
/// The background and the border colors have three forms. Give at most one
/// of the three:
/// - [backgroundColor]: one color for all data items;
/// - [backgroundColors]: one color for each data item, in data order;
/// - [backgroundColorFor]: a function of the context of each data item.
///
/// The List and the function forms make the chart resolve the options of
/// each data item, as the same Chart.js option does. Thus give the plain
/// form when one color is enough.
///
/// The keys that this class does not have go through [extra].
///
/// A dataset is immutable. `==` compares the parameters: a List of data
/// items by identity, a small List of style values by its items, and a
/// function with `==`. Use a method tear-off or a function in a field for
/// [backgroundColorFor] and [borderColorFor]: a new closure in each build
/// is a new value, and the chart then updates.
@immutable
abstract final class Dataset with Diagnosticable {
  /// The parameters of each dataset class.
  const Dataset({
    this.key,
    this.label,
    this.hidden,
    this.order,
    this.backgroundColor,
    this.backgroundColors,
    this.backgroundColorFor,
    this.borderColor,
    this.borderColors,
    this.borderColorFor,
    this.borderWidth,
    this.hoverBackgroundColor,
    this.hoverBorderColor,
    this.hoverBorderWidth,
    this.extra,
  }) : assert(
         backgroundColor == null ||
             (backgroundColors == null && backgroundColorFor == null),
         'Give at most one of backgroundColor, backgroundColors and '
         'backgroundColorFor.',
       ),
       assert(
         backgroundColors == null || backgroundColorFor == null,
         'Give at most one of backgroundColor, backgroundColors and '
         'backgroundColorFor.',
       ),
       assert(
         borderColor == null ||
             (borderColors == null && borderColorFor == null),
         'Give at most one of borderColor, borderColors and borderColorFor.',
       ),
       assert(
         borderColors == null || borderColorFor == null,
         'Give at most one of borderColor, borderColors and borderColorFor.',
       );

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

  /// The fill color of the data items: `backgroundColor`.
  final Color? backgroundColor;

  /// The fill color of each data item, in data order: `backgroundColor` as
  /// an array. The colors repeat when the dataset has more items.
  final List<Color>? backgroundColors;

  /// The fill color of each data item as a function of its context:
  /// `backgroundColor` as a scriptable option.
  final ChartScript<Color>? backgroundColorFor;

  /// The border color of the data items: `borderColor`.
  final Color? borderColor;

  /// The border color of each data item, in data order: `borderColor` as an
  /// array. The colors repeat when the dataset has more items.
  final List<Color>? borderColors;

  /// The border color of each data item as a function of its context:
  /// `borderColor` as a scriptable option.
  final ChartScript<Color>? borderColorFor;

  /// The border width in pixels: `borderWidth`.
  final double? borderWidth;

  /// The fill color of a data item under the pointer:
  /// `hoverBackgroundColor`.
  final Color? hoverBackgroundColor;

  /// The border color of a data item under the pointer: `hoverBorderColor`.
  final Color? hoverBorderColor;

  /// The border width of a data item under the pointer, in pixels:
  /// `hoverBorderWidth`.
  final double? hoverBorderWidth;

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
  /// A parameter that is `null` keeps its value. A copy that sets a second
  /// form of a color fails the assert of the constructor.
  Dataset copyWith({
    Key? key,
    String? label,
    bool? hidden,
    int? order,
    Color? backgroundColor,
    List<Color>? backgroundColors,
    ChartScript<Color>? backgroundColorFor,
    Color? borderColor,
    List<Color>? borderColors,
    ChartScript<Color>? borderColorFor,
    double? borderWidth,
    Color? hoverBackgroundColor,
    Color? hoverBorderColor,
    double? hoverBorderWidth,
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
    ('backgroundColors', byItems(backgroundColors)),
    ('backgroundColorFor', backgroundColorFor),
    ('borderColor', borderColor),
    ('borderColors', byItems(borderColors)),
    ('borderColorFor', borderColorFor),
    ('borderWidth', borderWidth),
    ('hoverBackgroundColor', hoverBackgroundColor),
    ('hoverBorderColor', hoverBorderColor),
    ('hoverBorderWidth', hoverBorderWidth),
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
OptionScope lowerDataset(Dataset dataset, ChartKind chartType) {
  final kind = dataset._kind;
  final scope = _datasetScopeOf(kind);
  if (kind != chartType) put(scope, OptionKey.type, kind.name);
  put(scope, OptionKey.label, dataset.label);
  put(scope, OptionKey.data, dataset._data);
  put(scope, OptionKey.hidden, dataset.hidden);
  put(scope, OptionKey.order, dataset.order);
  put(
    scope,
    OptionKey.backgroundColor,
    colorOption(
      dataset.backgroundColor,
      dataset.backgroundColors,
      dataset.backgroundColorFor,
    ),
  );
  put(
    scope,
    OptionKey.borderColor,
    colorOption(
      dataset.borderColor,
      dataset.borderColors,
      dataset.borderColorFor,
    ),
  );
  put(scope, OptionKey.borderWidth, dataset.borderWidth);
  put(
    scope,
    OptionKey.hoverBackgroundColor,
    colorValue(dataset.hoverBackgroundColor),
  );
  put(scope, OptionKey.hoverBorderColor, colorValue(dataset.hoverBorderColor));
  put(scope, OptionKey.hoverBorderWidth, dataset.hoverBorderWidth);
  dataset._lowerOwn(scope);
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
/// Give the values in [data], one for each label of the chart, or the
/// items in [points]. A bar chart with `indexAxis: IndexAxis.y` has
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
    super.backgroundColors,
    super.backgroundColorFor,
    super.borderColor,
    super.borderColors,
    super.borderColorFor,
    super.borderWidth,
    super.hoverBackgroundColor,
    super.hoverBorderColor,
    super.hoverBorderWidth,
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
  final IndexAxis? indexAxis;

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
    Color? backgroundColor,
    List<Color>? backgroundColors,
    ChartScript<Color>? backgroundColorFor,
    Color? borderColor,
    List<Color>? borderColors,
    ChartScript<Color>? borderColorFor,
    double? borderWidth,
    Color? hoverBackgroundColor,
    Color? hoverBorderColor,
    double? hoverBorderWidth,
    String? xAxisID,
    String? yAxisID,
    String? stack,
    IndexAxis? indexAxis,
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
    backgroundColors: backgroundColors ?? this.backgroundColors,
    backgroundColorFor: backgroundColorFor ?? this.backgroundColorFor,
    borderColor: borderColor ?? this.borderColor,
    borderColors: borderColors ?? this.borderColors,
    borderColorFor: borderColorFor ?? this.borderColorFor,
    borderWidth: borderWidth ?? this.borderWidth,
    hoverBackgroundColor: hoverBackgroundColor ?? this.hoverBackgroundColor,
    hoverBorderColor: hoverBorderColor ?? this.hoverBorderColor,
    hoverBorderWidth: hoverBorderWidth ?? this.hoverBorderWidth,
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
    put(scope, OptionKey.indexAxis, indexAxis?.name);
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
  bool? get spanGaps;
  bool? get showLine;
  bool? get stepped;
  double? get pointRadius;
  double? get pointHoverRadius;
  ChartPointStyle? get pointStyle;
  Color? get pointBackgroundColor;
  Color? get pointBorderColor;
  double? get pointBorderWidth;
  Color? get pointHoverBackgroundColor;
  Color? get pointHoverBorderColor;

  /// Writes the keys of the line style into [scope].
  void _lowerLine(OptionScope scope) {
    put(scope, OptionKey.fill, fill?.optionValue);
    put(scope, OptionKey.tension, tension);
    put(scope, OptionKey.borderDash, numberList(borderDash));
    put(scope, OptionKey.spanGaps, spanGaps);
    put(scope, OptionKey.showLine, showLine);
    put(scope, OptionKey.stepped, stepped);
    put(scope, OptionKey.pointRadius, pointRadius);
    put(scope, OptionKey.pointHoverRadius, pointHoverRadius);
    put(scope, OptionKey.pointStyle, pointStyle?.optionValue);
    put(
      scope,
      OptionKey.pointBackgroundColor,
      colorValue(pointBackgroundColor),
    );
    put(scope, OptionKey.pointBorderColor, colorValue(pointBorderColor));
    put(scope, OptionKey.pointBorderWidth, pointBorderWidth);
    put(
      scope,
      OptionKey.pointHoverBackgroundColor,
      colorValue(pointHoverBackgroundColor),
    );
    put(
      scope,
      OptionKey.pointHoverBorderColor,
      colorValue(pointHoverBorderColor),
    );
  }

  /// The properties of the line style, in parameter order.
  List<TypedProperty> get _lineProps => [
    ('fill', fill),
    ('tension', tension),
    ('borderDash', byItems(borderDash)),
    ('spanGaps', spanGaps),
    ('showLine', showLine),
    ('stepped', stepped),
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
    super.backgroundColors,
    super.backgroundColorFor,
    super.borderColor,
    super.borderColors,
    super.borderColorFor,
    super.borderWidth,
    super.hoverBackgroundColor,
    super.hoverBorderColor,
    super.hoverBorderWidth,
    this.xAxisID,
    this.yAxisID,
    this.stack,
    this.indexAxis,
    this.fill,
    this.tension,
    this.borderDash,
    this.spanGaps,
    this.showLine,
    this.stepped,
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
  final IndexAxis? indexAxis;

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
  /// Whether the line is a stepped line: `stepped` as a boolean. The other
  /// forms (`'before'`, `'after'`, `'middle'`) go through `extra`.
  /// {@endtemplate}
  @override
  final bool? stepped;

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
  /// The style of the points: `pointStyle`.
  /// {@endtemplate}
  @override
  final ChartPointStyle? pointStyle;

  /// {@template flutter_chartjs_port.typed.pointBackgroundColor}
  /// The fill color of the points: `pointBackgroundColor`.
  /// {@endtemplate}
  @override
  final Color? pointBackgroundColor;

  /// {@template flutter_chartjs_port.typed.pointBorderColor}
  /// The border color of the points: `pointBorderColor`.
  /// {@endtemplate}
  @override
  final Color? pointBorderColor;

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
  final Color? pointHoverBackgroundColor;

  /// {@template flutter_chartjs_port.typed.pointHoverBorderColor}
  /// The border color of a point under the pointer: `pointHoverBorderColor`.
  /// {@endtemplate}
  @override
  final Color? pointHoverBorderColor;

  @override
  LineDataset copyWith({
    Key? key,
    String? label,
    List<num?>? data,
    List<DataPoint>? points,
    bool? hidden,
    int? order,
    Color? backgroundColor,
    List<Color>? backgroundColors,
    ChartScript<Color>? backgroundColorFor,
    Color? borderColor,
    List<Color>? borderColors,
    ChartScript<Color>? borderColorFor,
    double? borderWidth,
    Color? hoverBackgroundColor,
    Color? hoverBorderColor,
    double? hoverBorderWidth,
    String? xAxisID,
    String? yAxisID,
    String? stack,
    IndexAxis? indexAxis,
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
    Map<String, Object?>? extra,
  }) => LineDataset(
    key: key ?? this.key,
    label: label ?? this.label,
    data: data ?? this.data,
    points: points ?? this.points,
    hidden: hidden ?? this.hidden,
    order: order ?? this.order,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    backgroundColors: backgroundColors ?? this.backgroundColors,
    backgroundColorFor: backgroundColorFor ?? this.backgroundColorFor,
    borderColor: borderColor ?? this.borderColor,
    borderColors: borderColors ?? this.borderColors,
    borderColorFor: borderColorFor ?? this.borderColorFor,
    borderWidth: borderWidth ?? this.borderWidth,
    hoverBackgroundColor: hoverBackgroundColor ?? this.hoverBackgroundColor,
    hoverBorderColor: hoverBorderColor ?? this.hoverBorderColor,
    hoverBorderWidth: hoverBorderWidth ?? this.hoverBorderWidth,
    xAxisID: xAxisID ?? this.xAxisID,
    yAxisID: yAxisID ?? this.yAxisID,
    stack: stack ?? this.stack,
    indexAxis: indexAxis ?? this.indexAxis,
    fill: fill ?? this.fill,
    tension: tension ?? this.tension,
    borderDash: borderDash ?? this.borderDash,
    spanGaps: spanGaps ?? this.spanGaps,
    showLine: showLine ?? this.showLine,
    stepped: stepped ?? this.stepped,
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
    put(scope, OptionKey.indexAxis, indexAxis?.name);
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
    super.backgroundColors,
    super.backgroundColorFor,
    super.borderColor,
    super.borderColors,
    super.borderColorFor,
    super.borderWidth,
    super.hoverBackgroundColor,
    super.hoverBorderColor,
    super.hoverBorderWidth,
    this.xAxisID,
    this.yAxisID,
    this.stack,
    this.fill,
    this.tension,
    this.borderDash,
    this.spanGaps,
    this.showLine,
    this.stepped,
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
  final bool? stepped;

  /// {@macro flutter_chartjs_port.typed.pointRadius}
  @override
  final double? pointRadius;

  /// {@macro flutter_chartjs_port.typed.pointHoverRadius}
  @override
  final double? pointHoverRadius;

  /// {@macro flutter_chartjs_port.typed.pointStyle}
  @override
  final ChartPointStyle? pointStyle;

  /// {@macro flutter_chartjs_port.typed.pointBackgroundColor}
  @override
  final Color? pointBackgroundColor;

  /// {@macro flutter_chartjs_port.typed.pointBorderColor}
  @override
  final Color? pointBorderColor;

  /// {@macro flutter_chartjs_port.typed.pointBorderWidth}
  @override
  final double? pointBorderWidth;

  /// {@macro flutter_chartjs_port.typed.pointHoverBackgroundColor}
  @override
  final Color? pointHoverBackgroundColor;

  /// {@macro flutter_chartjs_port.typed.pointHoverBorderColor}
  @override
  final Color? pointHoverBorderColor;

  @override
  ScatterDataset copyWith({
    Key? key,
    String? label,
    List<num?>? data,
    List<DataPoint>? points,
    bool? hidden,
    int? order,
    Color? backgroundColor,
    List<Color>? backgroundColors,
    ChartScript<Color>? backgroundColorFor,
    Color? borderColor,
    List<Color>? borderColors,
    ChartScript<Color>? borderColorFor,
    double? borderWidth,
    Color? hoverBackgroundColor,
    Color? hoverBorderColor,
    double? hoverBorderWidth,
    String? xAxisID,
    String? yAxisID,
    String? stack,
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
    Map<String, Object?>? extra,
  }) => ScatterDataset(
    key: key ?? this.key,
    label: label ?? this.label,
    data: data ?? this.data,
    points: points ?? this.points,
    hidden: hidden ?? this.hidden,
    order: order ?? this.order,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    backgroundColors: backgroundColors ?? this.backgroundColors,
    backgroundColorFor: backgroundColorFor ?? this.backgroundColorFor,
    borderColor: borderColor ?? this.borderColor,
    borderColors: borderColors ?? this.borderColors,
    borderColorFor: borderColorFor ?? this.borderColorFor,
    borderWidth: borderWidth ?? this.borderWidth,
    hoverBackgroundColor: hoverBackgroundColor ?? this.hoverBackgroundColor,
    hoverBorderColor: hoverBorderColor ?? this.hoverBorderColor,
    hoverBorderWidth: hoverBorderWidth ?? this.hoverBorderWidth,
    xAxisID: xAxisID ?? this.xAxisID,
    yAxisID: yAxisID ?? this.yAxisID,
    stack: stack ?? this.stack,
    fill: fill ?? this.fill,
    tension: tension ?? this.tension,
    borderDash: borderDash ?? this.borderDash,
    spanGaps: spanGaps ?? this.spanGaps,
    showLine: showLine ?? this.showLine,
    stepped: stepped ?? this.stepped,
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
    super.backgroundColors,
    super.backgroundColorFor,
    super.borderColor,
    super.borderColors,
    super.borderColorFor,
    super.borderWidth,
    super.hoverBackgroundColor,
    super.hoverBorderColor,
    super.hoverBorderWidth,
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

  /// The style of the bubbles: `pointStyle`.
  final ChartPointStyle? pointStyle;

  @override
  BubbleDataset copyWith({
    Key? key,
    String? label,
    List<DataPoint>? points,
    bool? hidden,
    int? order,
    Color? backgroundColor,
    List<Color>? backgroundColors,
    ChartScript<Color>? backgroundColorFor,
    Color? borderColor,
    List<Color>? borderColors,
    ChartScript<Color>? borderColorFor,
    double? borderWidth,
    Color? hoverBackgroundColor,
    Color? hoverBorderColor,
    double? hoverBorderWidth,
    String? xAxisID,
    String? yAxisID,
    double? radius,
    double? hoverRadius,
    ChartPointStyle? pointStyle,
    Map<String, Object?>? extra,
  }) => BubbleDataset(
    key: key ?? this.key,
    label: label ?? this.label,
    points: points ?? this.points,
    hidden: hidden ?? this.hidden,
    order: order ?? this.order,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    backgroundColors: backgroundColors ?? this.backgroundColors,
    backgroundColorFor: backgroundColorFor ?? this.backgroundColorFor,
    borderColor: borderColor ?? this.borderColor,
    borderColors: borderColors ?? this.borderColors,
    borderColorFor: borderColorFor ?? this.borderColorFor,
    borderWidth: borderWidth ?? this.borderWidth,
    hoverBackgroundColor: hoverBackgroundColor ?? this.hoverBackgroundColor,
    hoverBorderColor: hoverBorderColor ?? this.hoverBorderColor,
    hoverBorderWidth: hoverBorderWidth ?? this.hoverBorderWidth,
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
    put(scope, OptionKey.pointStyle, pointStyle?.optionValue);
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
  ChartLength? get cutout;
  ChartLength? get radius;

  /// Writes the keys of the arcs into [scope].
  void _lowerArc(OptionScope scope) {
    put(scope, OptionKey.offset, offset);
    put(scope, OptionKey.hoverOffset, hoverOffset);
    put(scope, OptionKey.spacing, spacing);
    put(scope, OptionKey.weight, weight);
    put(scope, OptionKey.circumference, circumference);
    put(scope, OptionKey.rotation, rotation);
    put(scope, OptionKey.cutout, cutout?.optionValue);
    put(scope, OptionKey.radius, radius?.optionValue);
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
    super.backgroundColors,
    super.backgroundColorFor,
    super.borderColor,
    super.borderColors,
    super.borderColorFor,
    super.borderWidth,
    super.hoverBackgroundColor,
    super.hoverBorderColor,
    super.hoverBorderWidth,
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
  /// The radius of the hole in the center: `cutout`. A percent is a part of
  /// the outer radius.
  /// {@endtemplate}
  ///
  /// The default of a pie is 0, no hole.
  @override
  final ChartLength? cutout;

  /// {@template flutter_chartjs_port.typed.radius}
  /// The outer radius: `radius`. A percent is a part of the largest radius
  /// that fits the chart area. The default is 100 percent.
  /// {@endtemplate}
  @override
  final ChartLength? radius;

  @override
  PieDataset copyWith({
    Key? key,
    String? label,
    List<num?>? data,
    bool? hidden,
    int? order,
    Color? backgroundColor,
    List<Color>? backgroundColors,
    ChartScript<Color>? backgroundColorFor,
    Color? borderColor,
    List<Color>? borderColors,
    ChartScript<Color>? borderColorFor,
    double? borderWidth,
    Color? hoverBackgroundColor,
    Color? hoverBorderColor,
    double? hoverBorderWidth,
    double? offset,
    double? hoverOffset,
    double? spacing,
    double? weight,
    double? circumference,
    double? rotation,
    ChartLength? cutout,
    ChartLength? radius,
    Map<String, Object?>? extra,
  }) => PieDataset(
    key: key ?? this.key,
    label: label ?? this.label,
    data: data ?? this.data,
    hidden: hidden ?? this.hidden,
    order: order ?? this.order,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    backgroundColors: backgroundColors ?? this.backgroundColors,
    backgroundColorFor: backgroundColorFor ?? this.backgroundColorFor,
    borderColor: borderColor ?? this.borderColor,
    borderColors: borderColors ?? this.borderColors,
    borderColorFor: borderColorFor ?? this.borderColorFor,
    borderWidth: borderWidth ?? this.borderWidth,
    hoverBackgroundColor: hoverBackgroundColor ?? this.hoverBackgroundColor,
    hoverBorderColor: hoverBorderColor ?? this.hoverBorderColor,
    hoverBorderWidth: hoverBorderWidth ?? this.hoverBorderWidth,
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
    super.backgroundColors,
    super.backgroundColorFor,
    super.borderColor,
    super.borderColors,
    super.borderColorFor,
    super.borderWidth,
    super.hoverBackgroundColor,
    super.hoverBorderColor,
    super.hoverBorderWidth,
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
  final ChartLength? cutout;

  /// {@macro flutter_chartjs_port.typed.radius}
  @override
  final ChartLength? radius;

  @override
  DoughnutDataset copyWith({
    Key? key,
    String? label,
    List<num?>? data,
    bool? hidden,
    int? order,
    Color? backgroundColor,
    List<Color>? backgroundColors,
    ChartScript<Color>? backgroundColorFor,
    Color? borderColor,
    List<Color>? borderColors,
    ChartScript<Color>? borderColorFor,
    double? borderWidth,
    Color? hoverBackgroundColor,
    Color? hoverBorderColor,
    double? hoverBorderWidth,
    double? offset,
    double? hoverOffset,
    double? spacing,
    double? weight,
    double? circumference,
    double? rotation,
    ChartLength? cutout,
    ChartLength? radius,
    Map<String, Object?>? extra,
  }) => DoughnutDataset(
    key: key ?? this.key,
    label: label ?? this.label,
    data: data ?? this.data,
    hidden: hidden ?? this.hidden,
    order: order ?? this.order,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    backgroundColors: backgroundColors ?? this.backgroundColors,
    backgroundColorFor: backgroundColorFor ?? this.backgroundColorFor,
    borderColor: borderColor ?? this.borderColor,
    borderColors: borderColors ?? this.borderColors,
    borderColorFor: borderColorFor ?? this.borderColorFor,
    borderWidth: borderWidth ?? this.borderWidth,
    hoverBackgroundColor: hoverBackgroundColor ?? this.hoverBackgroundColor,
    hoverBorderColor: hoverBorderColor ?? this.hoverBorderColor,
    hoverBorderWidth: hoverBorderWidth ?? this.hoverBorderWidth,
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
    super.backgroundColors,
    super.backgroundColorFor,
    super.borderColor,
    super.borderColors,
    super.borderColorFor,
    super.borderWidth,
    super.hoverBackgroundColor,
    super.hoverBorderColor,
    super.hoverBorderWidth,
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
    Color? backgroundColor,
    List<Color>? backgroundColors,
    ChartScript<Color>? backgroundColorFor,
    Color? borderColor,
    List<Color>? borderColors,
    ChartScript<Color>? borderColorFor,
    double? borderWidth,
    Color? hoverBackgroundColor,
    Color? hoverBorderColor,
    double? hoverBorderWidth,
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
    backgroundColors: backgroundColors ?? this.backgroundColors,
    backgroundColorFor: backgroundColorFor ?? this.backgroundColorFor,
    borderColor: borderColor ?? this.borderColor,
    borderColors: borderColors ?? this.borderColors,
    borderColorFor: borderColorFor ?? this.borderColorFor,
    borderWidth: borderWidth ?? this.borderWidth,
    hoverBackgroundColor: hoverBackgroundColor ?? this.hoverBackgroundColor,
    hoverBorderColor: hoverBorderColor ?? this.hoverBorderColor,
    hoverBorderWidth: hoverBorderWidth ?? this.hoverBorderWidth,
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
    super.backgroundColors,
    super.backgroundColorFor,
    super.borderColor,
    super.borderColors,
    super.borderColorFor,
    super.borderWidth,
    super.hoverBackgroundColor,
    super.hoverBorderColor,
    super.hoverBorderWidth,
    this.fill,
    this.tension,
    this.borderDash,
    this.spanGaps,
    this.showLine,
    this.stepped,
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

  /// {@macro flutter_chartjs_port.typed.spanGaps}
  @override
  final bool? spanGaps;

  /// {@macro flutter_chartjs_port.typed.showLine}
  @override
  final bool? showLine;

  /// {@macro flutter_chartjs_port.typed.stepped}
  @override
  final bool? stepped;

  /// {@macro flutter_chartjs_port.typed.pointRadius}
  @override
  final double? pointRadius;

  /// {@macro flutter_chartjs_port.typed.pointHoverRadius}
  @override
  final double? pointHoverRadius;

  /// {@macro flutter_chartjs_port.typed.pointStyle}
  @override
  final ChartPointStyle? pointStyle;

  /// {@macro flutter_chartjs_port.typed.pointBackgroundColor}
  @override
  final Color? pointBackgroundColor;

  /// {@macro flutter_chartjs_port.typed.pointBorderColor}
  @override
  final Color? pointBorderColor;

  /// {@macro flutter_chartjs_port.typed.pointBorderWidth}
  @override
  final double? pointBorderWidth;

  /// {@macro flutter_chartjs_port.typed.pointHoverBackgroundColor}
  @override
  final Color? pointHoverBackgroundColor;

  /// {@macro flutter_chartjs_port.typed.pointHoverBorderColor}
  @override
  final Color? pointHoverBorderColor;

  @override
  RadarDataset copyWith({
    Key? key,
    String? label,
    List<num?>? data,
    bool? hidden,
    int? order,
    Color? backgroundColor,
    List<Color>? backgroundColors,
    ChartScript<Color>? backgroundColorFor,
    Color? borderColor,
    List<Color>? borderColors,
    ChartScript<Color>? borderColorFor,
    double? borderWidth,
    Color? hoverBackgroundColor,
    Color? hoverBorderColor,
    double? hoverBorderWidth,
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
    Map<String, Object?>? extra,
  }) => RadarDataset(
    key: key ?? this.key,
    label: label ?? this.label,
    data: data ?? this.data,
    hidden: hidden ?? this.hidden,
    order: order ?? this.order,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    backgroundColors: backgroundColors ?? this.backgroundColors,
    backgroundColorFor: backgroundColorFor ?? this.backgroundColorFor,
    borderColor: borderColor ?? this.borderColor,
    borderColors: borderColors ?? this.borderColors,
    borderColorFor: borderColorFor ?? this.borderColorFor,
    borderWidth: borderWidth ?? this.borderWidth,
    hoverBackgroundColor: hoverBackgroundColor ?? this.hoverBackgroundColor,
    hoverBorderColor: hoverBorderColor ?? this.hoverBorderColor,
    hoverBorderWidth: hoverBorderWidth ?? this.hoverBorderWidth,
    fill: fill ?? this.fill,
    tension: tension ?? this.tension,
    borderDash: borderDash ?? this.borderDash,
    spanGaps: spanGaps ?? this.spanGaps,
    showLine: showLine ?? this.showLine,
    stepped: stepped ?? this.stepped,
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
  DataPoint(num x, num? y) : x = x.toDouble(), y = y?.toDouble(), r = null;

  /// `{x, y}` with a time [x], for a time or a time series x axis.
  DataPoint.time(DateTime this.x, num? y) : y = y?.toDouble(), r = null;

  /// `{x, y}` with a label [x], for a category x axis. A label that is not
  /// in the labels of the chart becomes a new label: the category scale adds
  /// it to `data.labels`.
  DataPoint.label(String this.x, num? y) : y = y?.toDouble(), r = null;

  /// `{x, y, r}`: a bubble at ([x], [y]) with the radius [r] in pixels.
  DataPoint.bubble(num x, num y, num r)
    : x = x.toDouble(),
      y = y.toDouble(),
      r = r.toDouble();

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
