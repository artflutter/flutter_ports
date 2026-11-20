// Original code, not ported from chartjs-chart-sankey: the typed dataset.

/// The typed dataset of a sankey chart (Sankey ADR 0004): [SankeyDataset]
/// for the typed `ChartConfig` of the host, with the option types
/// [SankeyColor], [SankeyNodeValue], [SankeyFlowValue], [SankeyNodeLabels]
/// and [SankeyFlowLabels].
///
/// The dataset lowers to the keys and the values of a raw sankey dataset Map
/// (`src/types.ts` `SankeyControllerDatasetOptions`): the chart reads both
/// forms with the same code.
library;

import 'dart:ui' show Color;

import 'package:flutter/foundation.dart' show Key, immutable;
import 'package:flutter/painting.dart' show TextStyle;
import 'package:flutter_chartjs_chart_sankey_port/flutter_chartjs_chart_sankey_port.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The data item of the context of a flow option: the [SankeyDataPoint] of
/// the flow.
SankeyDataPoint? _flowOf(Object? context) {
  final raw = context is ScriptableContext ? context.raw : null;
  assert(
    raw is SankeyDataPoint,
    'The data items of a SankeyDataset are SankeyDataPoint objects, not '
    '${raw.runtimeType}.',
  );
  return raw is SankeyDataPoint ? raw : null;
}

/// A color option of the flows: `colorFrom`, `colorTo`, `hoverColorFrom`,
/// `hoverColorTo`, `flowColor` and `hoverFlowColor` (`src/types.ts:69-79`).
///
/// ```dart
/// SankeyDataset(
///   colorFrom: .byNode(nodeColor), // Color Function(String node)
///   colorTo: .byNode(nodeColor),
///   flowColor: .byFlow((flow) => .solid(flow.flow > 5 ? red : blue)),
/// )
/// ```
///
/// The Array form of upstream has no class: the sankey controller declares
/// its dataset options not indexable (`src/controller.ts:242`).
@immutable
sealed class const SankeyColor._() {
  /// One paint for each flow.
  const factory constant(ChartPaint paint) = SankeyConstantColor;

  /// The color of a node of the flow, by the key of the node: the source
  /// node for `colorFrom`, `hoverColorFrom`, `flowColor` and
  /// `hoverFlowColor`, the target node for `colorTo` and `hoverColorTo`.
  const factory byNode(Color Function(String node) color) = SankeyNodeColor;

  /// The paint of each flow, from its data item.
  const factory byFlow(ChartPaint Function(SankeyDataPoint flow) paint) =
      SankeyFlowColor;

  /// The option value of the color: a `ChartPaint`, or a function of the
  /// flow context. [target] selects the node of [SankeyColor.byNode].
  Object _optionValue({required bool target});
}

/// The color of [SankeyColor.constant].
final class const SankeyConstantColor(
  /// The paint of each flow.
  final ChartPaint paint,
) extends SankeyColor {
  /// One paint for each flow.
  this : super._();

  @override
  Object _optionValue({required bool target}) => paint;

  @override
  bool operator ==(Object other) =>
      other is SankeyConstantColor && other.paint == paint;

  @override
  int get hashCode => Object.hash(SankeyConstantColor, paint);
}

/// The color of [SankeyColor.byNode].
final class const SankeyNodeColor(
  /// The color of a node by its key. Give a tear-off: `==` compares it.
  final Color Function(String node) color,
) extends SankeyColor {
  /// The color of a node of each flow.
  this : super._();

  @override
  Object _optionValue({required bool target}) => (Object? context) {
    final flow = _flowOf(context);
    if (flow == null) return null;
    return ChartPaint.solid(color(target ? flow.to : flow.from));
  };

  @override
  bool operator ==(Object other) =>
      other is SankeyNodeColor && other.color == color;

  @override
  int get hashCode => Object.hash(SankeyNodeColor, color);
}

/// The color of [SankeyColor.byFlow].
final class const SankeyFlowColor(
  /// The paint of a flow. Give a tear-off: `==` compares it.
  final ChartPaint Function(SankeyDataPoint flow) paint,
) extends SankeyColor {
  /// The paint of each flow from its data item.
  this : super._();

  @override
  Object _optionValue({required bool target}) => (Object? context) {
    final flow = _flowOf(context);
    return flow == null ? null : paint(flow);
  };

  @override
  bool operator ==(Object other) =>
      other is SankeyFlowColor && other.paint == paint;

  @override
  int get hashCode => Object.hash(SankeyFlowColor, paint);
}

/// A node option: `SankeyNodeOption<T>` of `src/types.ts:28`, one value,
/// a value for each node key, or a function of the node.
///
/// ```dart
/// nodeMinSize: .all(4),
/// nodePadding: .byKey({'Grid': SankeyNodeGap(before: 30, after: 30)}),
/// nodeLabels: SankeyNodeLabels(color: .byNode(labelColor)),
/// ```
@immutable
sealed class const SankeyNodeValue<T extends Object>._() {
  /// One value for each node.
  const factory all(T value) = SankeyNodeAll<T>;

  /// A value for each node key. A node with no key takes the default.
  const factory byKey(Map<String, T> values) = SankeyNodeByKey<T>;

  /// A function of the node. A null result takes the default.
  const factory byNode(SankeyNodeCallback<T> value) = SankeyNodeFunction<T>;

  /// The option value: the value, a Map by node key or the function.
  Object _optionValue();
}

/// The value of [SankeyNodeValue.all].
final class const SankeyNodeAll<T extends Object>(
  /// The value of each node.
  final T value,
) extends SankeyNodeValue<T> {
  /// One value for each node.
  this : super._();

  @override
  Object _optionValue() => value;

  @override
  bool operator ==(Object other) =>
      other is SankeyNodeAll<T> && other.value == value;

  @override
  int get hashCode => Object.hash(SankeyNodeAll, value);
}

/// The value of [SankeyNodeValue.byKey].
final class const SankeyNodeByKey<T extends Object>(
  /// The value of each node by its key.
  final Map<String, T> values,
) extends SankeyNodeValue<T> {
  /// A value for each node key.
  this : super._();

  @override
  Object _optionValue() => <String, Object?>{...values};

  @override
  bool operator ==(Object other) =>
      other is SankeyNodeByKey<T> &&
      byEntries(other.values) == byEntries(values);

  @override
  int get hashCode => Object.hash(SankeyNodeByKey, byEntries(values));
}

/// The value of [SankeyNodeValue.byNode].
final class const SankeyNodeFunction<T extends Object>(
  /// The value of a node. Give a tear-off: `==` compares it.
  final SankeyNodeCallback<T> value,
) extends SankeyNodeValue<T> {
  /// A function of the node.
  this : super._();

  @override
  Object _optionValue() => value;

  @override
  bool operator ==(Object other) =>
      other is SankeyNodeFunction<T> && other.value == value;

  @override
  int get hashCode => Object.hash(SankeyNodeFunction, value);
}

/// An option of the flow labels: `Scriptable<T, SankeyScriptableContext>`
/// of `src/types.ts:48-56`, one value or a function of the flow.
@immutable
sealed class const SankeyFlowValue<T extends Object>._() {
  /// One value for each flow.
  const factory all(T value) = SankeyFlowAll<T>;

  /// A function of the data item of the flow.
  const factory byFlow(T Function(SankeyDataPoint flow) value) =
      SankeyFlowFunction<T>;

  /// The option value: the value, or a function of the flow context.
  Object _optionValue();
}

/// The value of [SankeyFlowValue.all].
final class const SankeyFlowAll<T extends Object>(
  /// The value of each flow.
  final T value,
) extends SankeyFlowValue<T> {
  /// One value for each flow.
  this : super._();

  @override
  Object _optionValue() => value;

  @override
  bool operator ==(Object other) =>
      other is SankeyFlowAll<T> && other.value == value;

  @override
  int get hashCode => Object.hash(SankeyFlowAll, value);
}

/// The value of [SankeyFlowValue.byFlow].
final class const SankeyFlowFunction<T extends Object>(
  /// The value of a flow. Give a tear-off: `==` compares it.
  final T Function(SankeyDataPoint flow) value,
) extends SankeyFlowValue<T> {
  /// A function of the flow.
  this : super._();

  @override
  Object _optionValue() => (Object? context) {
    final flow = _flowOf(context);
    return flow == null ? null : value(flow);
  };

  @override
  bool operator ==(Object other) =>
      other is SankeyFlowFunction<T> && other.value == value;

  @override
  int get hashCode => Object.hash(SankeyFlowFunction, value);
}

/// The labels of the nodes: `nodeLabels`
/// (`src/types.ts:38` `SankeyControllerDatasetNodeLabelsOptions`).
@immutable
final class const SankeyNodeLabels({
  /// The fill behind a label: `backgroundColor`. The default is none.
  final SankeyNodeValue<ChartPaint>? backgroundColor,

  /// The corner radius of the fill, in pixels: `borderRadius`.
  final double? borderRadius,

  /// The color of the text: `color`. The default is the dataset `color`.
  final SankeyNodeValue<ChartPaint>? color,

  /// Whether a label shows: `display`. The default is true.
  final SankeyNodeValue<bool>? display,

  /// The font: `font`.
  final TextStyle? font,

  /// The space around the text, in pixels: `padding`. The default is 4.
  final double? padding,

  /// The place of a label: `position`. The default is
  /// [SankeyLabelPosition.auto].
  final SankeyNodeValue<SankeyLabelPosition>? position,
}) {
  /// The options of the node labels.
  this;

  Map<String, Object?> _lower() => {
    'backgroundColor': ?backgroundColor?._optionValue(),
    'borderRadius': ?borderRadius,
    'color': ?color?._optionValue(),
    'display': ?display?._optionValue(),
    'font': ?font,
    'padding': ?padding,
    'position': ?position?._optionValue(),
  };

  List<Object?> get _props => [
    backgroundColor,
    borderRadius,
    color,
    display,
    font,
    padding,
    position,
  ];

  @override
  bool operator ==(Object other) =>
      other is SankeyNodeLabels && _listEquals(other._props, _props);

  @override
  int get hashCode => Object.hashAll(_props);
}

/// The labels of the flows: `flowLabels`
/// (`src/types.ts:48` `SankeyControllerDatasetFlowLabelsOptions`).
@immutable
final class const SankeyFlowLabels({
  /// The fill behind a label: `backgroundColor`.
  final SankeyFlowValue<ChartPaint>? backgroundColor,

  /// The corner radius of the fill, in pixels: `borderRadius`.
  final SankeyFlowValue<double>? borderRadius,

  /// The color of the text: `color`.
  final SankeyFlowValue<ChartPaint>? color,

  /// Whether a label shows: `display`. The default is false.
  final SankeyFlowValue<bool>? display,

  /// The font: `font`.
  final SankeyFlowValue<TextStyle>? font,

  /// The space around the text, in pixels: `padding`.
  final SankeyFlowValue<double>? padding,

  /// The place of a label: `position`. The default is
  /// [SankeyLabelPosition.center].
  final SankeyFlowValue<SankeyLabelPosition>? position,
}) {
  /// The options of the flow labels.
  this;

  Map<String, Object?> _lower() => {
    'backgroundColor': ?backgroundColor?._optionValue(),
    'borderRadius': ?borderRadius?._optionValue(),
    'color': ?color?._optionValue(),
    'display': ?display?._optionValue(),
    'font': ?font?._optionValue(),
    'padding': ?padding?._optionValue(),
    'position': ?position?._optionValue(),
  };

  List<Object?> get _props => [
    backgroundColor,
    borderRadius,
    color,
    display,
    font,
    padding,
    position,
  ];

  @override
  bool operator ==(Object other) =>
      other is SankeyFlowLabels && _listEquals(other._props, _props);

  @override
  int get hashCode => Object.hashAll(_props);
}

bool _listEquals(List<Object?> a, List<Object?> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// A dataset of a sankey chart: the sankey controller
/// (`src/types.ts:64` `SankeyControllerDatasetOptions`).
///
/// ```dart
/// ChartView(
///   config: ChartConfig(
///     type: const ChartKind(SankeyController.id),
///     datasets: [
///       SankeyDataset(
///         label: 'Energy',
///         data: const [SankeyDataPoint(from: 'Solar', to: 'Grid', flow: 12)],
///         colorFrom: const .byNode(nodeColor),
///         colorTo: const .byNode(nodeColor),
///       ),
///     ],
///   ),
/// )
/// ```
///
/// The chart needs `Chart.register(sankeyRegisterables)`. A parameter that
/// is `null` is not set: the chart uses the default of chartjs-chart-sankey.
/// The options with no parameter, for example `parsing`, go through
/// [extra].
final class const SankeyDataset({
  super.key,
  super.label,

  /// The flows: `data`, by reference.
  final List<SankeyDataPoint>? data,
  super.hidden,
  super.order,
  super.clip,

  /// The border of the nodes: `borderColor`, one paint for the dataset.
  super.borderColor,

  /// The border width of the nodes, in pixels: `borderWidth`.
  super.borderWidth,
  super.tooltipCallbacks,

  /// The opacity of the flows, from 0 to 1: `alpha`. The default is 0.5.
  final double? alpha,

  /// The color of the node labels: `color`. The default is black.
  final ChartPaint? color,

  /// The color at the source end of each flow, also the color of the source
  /// node: `colorFrom`.
  final SankeyColor? colorFrom,

  /// The color at the target end of each flow, also the color of the target
  /// node: `colorTo`.
  final SankeyColor? colorTo,

  /// How a flow takes its colors: `colorMode`. The default is
  /// [SankeyColorMode.gradient].
  final SankeyColorMode? colorMode,

  /// The column of a node by its key, from 0: `column`.
  final Map<String, int>? column,

  /// The font of the node labels: `font`.
  final TextStyle? font,

  /// The labels of the flows: `flowLabels`.
  final SankeyFlowLabels? flowLabels,

  /// The color of the source end of a flow under the pointer:
  /// `hoverColorFrom`. The default is [colorFrom] with more opacity.
  final SankeyColor? hoverColorFrom,

  /// The color of the target end of a flow under the pointer:
  /// `hoverColorTo`.
  final SankeyColor? hoverColorTo,

  /// The fill of a flow under the pointer: `hoverFlowColor`.
  final SankeyColor? hoverFlowColor,

  /// The text of a node label by the node key: `labels`. The default is
  /// the key.
  final Map<String, String>? labels,

  /// The fill of each flow: `flowColor`. It replaces [colorMode].
  final SankeyColor? flowColor,

  /// How the columns spread: `modeX`. The default is [SankeyModeX.edge].
  final SankeyModeX? modeX,

  /// The labels of the nodes: `nodeLabels`.
  final SankeyNodeLabels? nodeLabels,

  /// The smallest size of a node, in pixels: `nodeMinSize`.
  final SankeyNodeValue<double>? nodeMinSize,

  /// The gap around a node, in pixels: `nodePadding`. The default is 10 on
  /// each side.
  final SankeyNodeValue<SankeyNodeGap>? nodePadding,

  /// How the gaps of a column grow: `nodePaddingMode`.
  final SankeyNodePaddingMode? nodePaddingMode,

  /// The width of a node, in pixels: `nodeWidth`. The default is 10.
  final double? nodeWidth,

  /// The direction of the flows: `orientation`. The default is
  /// [SankeyOrientation.horizontal].
  final SankeyOrientation? orientation,

  /// The space between a node and its label, in pixels: `padding`.
  final double? padding,

  /// The order of the nodes in a column by the node key: `priority`. A
  /// lower number goes first.
  final Map<String, double>? priority,

  /// The size of a node from its flows in and out: `size`. The default is
  /// [SankeySize.max].
  final SankeySize? size,
  super.extra,
}) extends Dataset {
  /// A sankey dataset.
  this;

  /// A copy of this dataset with the given parameters. A null parameter
  /// keeps its value.
  SankeyDataset copyWith({
    Key? key,
    String? label,
    List<SankeyDataPoint>? data,
    bool? hidden,
    int? order,
    ChartClip? clip,
    ChartValue<ChartPaint>? borderColor,
    double? borderWidth,
    TooltipCallbacks? tooltipCallbacks,
    double? alpha,
    ChartPaint? color,
    SankeyColor? colorFrom,
    SankeyColor? colorTo,
    SankeyColorMode? colorMode,
    Map<String, int>? column,
    TextStyle? font,
    SankeyFlowLabels? flowLabels,
    SankeyColor? hoverColorFrom,
    SankeyColor? hoverColorTo,
    SankeyColor? hoverFlowColor,
    Map<String, String>? labels,
    SankeyColor? flowColor,
    SankeyModeX? modeX,
    SankeyNodeLabels? nodeLabels,
    SankeyNodeValue<double>? nodeMinSize,
    SankeyNodeValue<SankeyNodeGap>? nodePadding,
    SankeyNodePaddingMode? nodePaddingMode,
    double? nodeWidth,
    SankeyOrientation? orientation,
    double? padding,
    Map<String, double>? priority,
    SankeySize? size,
    Map<String, Object?>? extra,
  }) => SankeyDataset(
    key: key ?? this.key,
    label: label ?? this.label,
    data: data ?? this.data,
    hidden: hidden ?? this.hidden,
    order: order ?? this.order,
    clip: clip ?? this.clip,
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    tooltipCallbacks: tooltipCallbacks ?? this.tooltipCallbacks,
    alpha: alpha ?? this.alpha,
    color: color ?? this.color,
    colorFrom: colorFrom ?? this.colorFrom,
    colorTo: colorTo ?? this.colorTo,
    colorMode: colorMode ?? this.colorMode,
    column: column ?? this.column,
    font: font ?? this.font,
    flowLabels: flowLabels ?? this.flowLabels,
    hoverColorFrom: hoverColorFrom ?? this.hoverColorFrom,
    hoverColorTo: hoverColorTo ?? this.hoverColorTo,
    hoverFlowColor: hoverFlowColor ?? this.hoverFlowColor,
    labels: labels ?? this.labels,
    flowColor: flowColor ?? this.flowColor,
    modeX: modeX ?? this.modeX,
    nodeLabels: nodeLabels ?? this.nodeLabels,
    nodeMinSize: nodeMinSize ?? this.nodeMinSize,
    nodePadding: nodePadding ?? this.nodePadding,
    nodePaddingMode: nodePaddingMode ?? this.nodePaddingMode,
    nodeWidth: nodeWidth ?? this.nodeWidth,
    orientation: orientation ?? this.orientation,
    padding: padding ?? this.padding,
    priority: priority ?? this.priority,
    size: size ?? this.size,
    extra: extra ?? this.extra,
  );

  @override
  ChartKind get kind => const ChartKind(SankeyController.id);

  @override
  List<Object?>? get chartData => data;

  /// Writes the keys in the order of `src/types.ts:64-94`.
  @override
  void lowerOwn(OptionScope scope) {
    void write(String name, Object? value) {
      if (value != null) scope[name] = value;
    }

    write('alpha', alpha);
    write('color', color);
    write('colorFrom', colorFrom?._optionValue(target: false));
    write('colorMode', colorMode);
    write('colorTo', colorTo?._optionValue(target: true));
    write('column', column == null ? null : <String, Object?>{...?column});
    write('font', font);
    write('flowLabels', flowLabels?._lower());
    write('hoverColorFrom', hoverColorFrom?._optionValue(target: false));
    write('hoverColorTo', hoverColorTo?._optionValue(target: true));
    write('hoverFlowColor', hoverFlowColor?._optionValue(target: false));
    write('labels', labels == null ? null : <String, Object?>{...?labels});
    write('flowColor', flowColor?._optionValue(target: false));
    write('modeX', modeX);
    write('nodeLabels', nodeLabels?._lower());
    write('nodeMinSize', nodeMinSize?._optionValue());
    write('nodePadding', nodePadding?._optionValue());
    write('nodePaddingMode', nodePaddingMode);
    write('nodeWidth', nodeWidth);
    write('orientation', orientation);
    write('padding', padding);
    write(
      'priority',
      priority == null ? null : <String, Object?>{...?priority},
    );
    write('size', size);
  }

  @override
  List<TypedProperty> get props => [
    ('key', key),
    ('label', label),
    ('data', data),
    ...styleProps,
    ('alpha', alpha),
    ('color', color),
    ('colorFrom', colorFrom),
    ('colorMode', colorMode),
    ('colorTo', colorTo),
    ('column', byEntries(column)),
    ('font', font),
    ('flowLabels', flowLabels),
    ('hoverColorFrom', hoverColorFrom),
    ('hoverColorTo', hoverColorTo),
    ('hoverFlowColor', hoverFlowColor),
    ('labels', byEntries(labels)),
    ('flowColor', flowColor),
    ('modeX', modeX),
    ('nodeLabels', nodeLabels),
    ('nodeMinSize', nodeMinSize),
    ('nodePadding', nodePadding),
    ('nodePaddingMode', nodePaddingMode),
    ('nodeWidth', nodeWidth),
    ('orientation', orientation),
    ('padding', padding),
    ('priority', byEntries(priority)),
    ('size', size),
    ('extra', byEntries(extra)),
  ];
}
