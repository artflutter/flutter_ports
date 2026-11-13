// Ported from chartjs-chart-sankey v0.19.1 src/types.ts (MIT, Jukka Kurkela).

/// The types of the sankey chart: the data point, the node, the option
/// values and the option facades (Sankey ADR 0002).
///
/// - A union of string literals is an enum ([SankeyOrientation],
///   [SankeyLabelPosition], [SankeyColorMode], [SankeyModeX],
///   [SankeyNodePaddingMode], [SankeySize], row `adapt-sankey-option-enums`):
///   the name of each value is the upstream string. A raw config holds the
///   enum value too. A name is a foreign value: a debug build stops on it.
/// - An object that only the chart makes is a class with typed fields
///   ([SankeyNode], [FromToElement], [SankeyParsedCustom]). The node fields
///   `in` and `out` are [SankeyNode.inFlow] and [SankeyNode.outFlow]: `in` is
///   a reserved word of Dart (row `adapt-sankey-node-fields`).
/// - A data item is a [SankeyDataPoint], or a Map that the keys of the
///   option `parsing` read.
/// - The options of a dataset are a resolver of the host, read by name.
///   [SankeyControllerDatasetOptions] and its nested facades are extension
///   types over the raw value, with no cost: each getter reads one key with
///   `jsGet` at each use, as upstream reads the resolver.
/// - `SankeyNodeOption<T>` (types.ts:27) is `T`, a `Map<String, T>` by node
///   key or a [SankeyNodeCallback]. Dart has no such union: the option is
///   the raw value, and `resolveNodeOption` of `labels.dart` reads it.
/// - The TypeScript-only declarations have no Dart form:
///   `SankeyScriptableContext` (:21, the `ScriptableContext` of the host with
///   a [SankeyDataPoint] as `raw`), the `declare module` block (:134-145) and
///   `FlowOptions` (:157-175, the resolved options of a flow are the options
///   object of the host, read through [FlowOptionsFace]).
library;

import 'package:flutter/painting.dart' show TextStyle;
import 'package:flutter_chartjs_port/helpers.dart' show isNullOrUndef;
import 'package:flutter_chartjs_port/js_semantics.dart'
    show jsGet, jsNumberToString;

/// types.ts:15 `SankeyDataPoint`: one flow of the data, from the node
/// [from] to the node [to].
final class const SankeyDataPoint({
  /// The key of the source node.
  required final String from,

  /// The key of the target node.
  required final String to,

  /// The size of the flow.
  required final double flow,
}) {
  /// One flow of [flow] units from [from] to [to].
  this;

  @override
  String toString() =>
      'SankeyDataPoint($from -> $to: ${jsNumberToString(flow)})';
}

/// types.ts:25 `SankeyLabelPosition`: where a label goes at its node or
/// flow.
// DIVERGES(sankey): adapt-sankey-option-enums, an enum of the positions.
enum SankeyLabelPosition() {
  /// `'auto'`: the side toward the center of the chart area.
  auto,

  /// `'bottom'`.
  bottom,

  /// `'center'`.
  center,

  /// `'left'`.
  left,

  /// `'right'`.
  right,

  /// `'top'`.
  top;

  /// The value of [value], a `position` option, or Dart `null` for a value
  /// that is not a [SankeyLabelPosition]. An upstream name is not a value: a
  /// debug build stops on it.
  static SankeyLabelPosition? of(Object? value) {
    assert(
      value is! String,
      'A label position takes a SankeyLabelPosition, not the name "$value".',
    );
    return value is SankeyLabelPosition ? value : null;
  }
}

/// types.ts:26 `SankeyNodeLabelPosition = SankeyLabelPosition`.
typedef SankeyNodeLabelPosition = SankeyLabelPosition;

/// types.ts:27 `SankeyOrientation`: the direction of the flows.
// DIVERGES(sankey): adapt-sankey-option-enums, an enum of the directions.
enum SankeyOrientation() {
  /// `'horizontal'`: the flows go from left to right.
  horizontal,

  /// `'vertical'`: the flows go from top to bottom.
  vertical;

  /// The value of [value], an `orientation` option, or Dart `null` for a
  /// value that is not a [SankeyOrientation]. An upstream name is not a
  /// value: a debug build stops on it.
  static SankeyOrientation? of(Object? value) {
    assert(
      value is! String,
      'An orientation takes a SankeyOrientation, not the name "$value".',
    );
    return value is SankeyOrientation ? value : null;
  }
}

/// types.ts:74 `colorMode?: 'gradient' | 'from' | 'to'`: the fill of a
/// flow.
// DIVERGES(sankey): adapt-sankey-option-enums, an enum of the color modes.
enum SankeyColorMode() {
  /// `'gradient'`: a gradient from `colorFrom` to `colorTo`.
  gradient,

  /// `'from'`: `colorFrom`.
  from,

  /// `'to'`: `colorTo`.
  to;

  /// The value of [value], a `colorMode` option, or Dart `null` for a value
  /// that is not a [SankeyColorMode]. An upstream name is not a value: a
  /// debug build stops on it.
  static SankeyColorMode? of(Object? value) {
    assert(
      value is! String,
      'A color mode takes a SankeyColorMode, not the name "$value".',
    );
    return value is SankeyColorMode ? value : null;
  }
}

/// types.ts:84 `modeX?: 'edge' | 'even'`: the layout mode in the direction
/// of the flows.
// DIVERGES(sankey): adapt-sankey-option-enums, an enum of the layout modes.
enum SankeyModeX() {
  /// `'edge'`: a node without an output goes to the last column.
  edge,

  /// `'even'`: each node stays in the column after its inputs.
  even;

  /// The value of [value], a `modeX` option, or Dart `null` for a value that
  /// is not a [SankeyModeX]. An upstream name is not a value: a debug build
  /// stops on it.
  static SankeyModeX? of(Object? value) {
    assert(
      value is! String,
      'modeX takes a SankeyModeX, not the name "$value".',
    );
    return value is SankeyModeX ? value : null;
  }
}

/// types.ts:88 `nodePaddingMode?: 'auto' | 'even'`: how the gaps of
/// `nodePadding` go between the nodes of a column.
// DIVERGES(sankey): adapt-sankey-option-enums, an enum of the padding modes.
enum SankeyNodePaddingMode() {
  /// `'auto'`: a node also clears the nodes above it in the columns before
  /// its column.
  auto,

  /// `'even'`: equal gaps inside each column.
  even;

  /// The value of [value], a `nodePaddingMode` option, or Dart `null` for a
  /// value that is not a [SankeyNodePaddingMode]. An upstream name is not a
  /// value: a debug build stops on it.
  static SankeyNodePaddingMode? of(Object? value) {
    assert(
      value is! String,
      'nodePaddingMode takes a SankeyNodePaddingMode, not the name "$value".',
    );
    return value is SankeyNodePaddingMode ? value : null;
  }
}

/// types.ts:94 `size?: 'min' | 'max'`: the size of a node from its input
/// and its output.
// DIVERGES(sankey): adapt-sankey-option-enums, an enum of the size methods.
enum SankeySize() {
  /// `'min'`: the smaller of the input and the output.
  min,

  /// `'max'`: the larger of the input and the output.
  max,
}

/// The function form of types.ts:29 `SankeyNodeOption<T>`: the value of an
/// option for [node]. Dart `null` is the JavaScript `undefined`: the
/// default of the option applies.
typedef SankeyNodeCallback<T> = T? Function(SankeyNode node);

/// types.ts:33 `SankeyNodeGap`: the gap before and after a node, in pixels.
/// An absent side is 10.
final class const SankeyNodeGap({
  /// The gap after the node (below it, or at its right in the vertical
  /// orientation).
  final double? after,

  /// The gap before the node.
  final double? before,
}) {
  /// The gap [before] and [after] a node.
  this;
}

/// `Required<SankeyNodeGap>` (controller.ts:199, layout.ts:353): the gap of
/// a node with both sides.
typedef NodeGap = ({double after, double before});

/// types.ts:38 `SankeyControllerDatasetNodeLabelsOptions`: the option
/// `nodeLabels` of a dataset, read by name.
extension type const SankeyNodeLabelsOptions(Object? _raw) {
  /// `backgroundColor`: a `ChartPaint`, a Map by node key or a
  /// [SankeyNodeCallback], or `undefined`.
  Object? get backgroundColor => jsGet(_raw, 'backgroundColor');

  /// `borderRadius`.
  Object? get borderRadius => jsGet(_raw, 'borderRadius');

  /// `color`: a `ChartPaint`, a Map by node key or a [SankeyNodeCallback].
  Object? get color => jsGet(_raw, 'color');

  /// `display`: a `bool`, a Map by node key or a [SankeyNodeCallback].
  Object? get display => jsGet(_raw, 'display');

  /// `font`: a `TextStyle`.
  Object? get font => jsGet(_raw, 'font');

  /// `padding`.
  Object? get padding => jsGet(_raw, 'padding');

  /// `position`: a [SankeyLabelPosition], a Map by node key or a
  /// [SankeyNodeCallback].
  Object? get position => jsGet(_raw, 'position');
}

/// types.ts:58 `SankeyParsingOptions`: the keys of a data item that is a
/// Map.
extension type const SankeyParsingOptions(Object? _raw) {
  /// `from`: the key of the source node key. The default is `'from'`.
  Object? get from => jsGet(_raw, 'from');

  /// `to`: the key of the target node key. The default is `'to'`.
  Object? get to => jsGet(_raw, 'to');

  /// `flow`: the key of the flow size. The default is `'flow'`.
  Object? get flow => jsGet(_raw, 'flow');
}

/// types.ts:64 `SankeyControllerDatasetOptions`: the options of a sankey
/// dataset, read by name from the resolver of the controller.
///
/// A getter gives the raw value, and `undefined` for an absent key. The
/// typed getters ([orientation], [modeX], [nodePaddingMode]) give Dart
/// `null` for a value of another type.
extension type const SankeyControllerDatasetOptions(Object? _raw) {
  /// `borderColor`: the stroke of a node.
  Object? get borderColor => jsGet(_raw, 'borderColor');

  /// `borderWidth`: the stroke width of a node.
  Object? get borderWidth => jsGet(_raw, 'borderWidth');

  /// `color`: the color of the node labels.
  Object? get color => jsGet(_raw, 'color');

  /// `column`: a Map from a node key to the column of the node.
  Object? get column => jsGet(_raw, 'column');

  /// `font`: the font of the node labels.
  Object? get font => jsGet(_raw, 'font');

  /// `labels`: a Map from a node key to the label of the node.
  Object? get labels => jsGet(_raw, 'labels');

  /// `modeX`.
  SankeyModeX? get modeX => SankeyModeX.of(jsGet(_raw, 'modeX'));

  /// `nodeLabels`.
  SankeyNodeLabelsOptions? get nodeLabels {
    final value = jsGet(_raw, 'nodeLabels');
    return isNullOrUndef(value) ? null : SankeyNodeLabelsOptions(value);
  }

  /// `nodeMinSize`: a number, a Map by node key or a [SankeyNodeCallback].
  Object? get nodeMinSize => jsGet(_raw, 'nodeMinSize');

  /// `nodePadding`: a number, a [SankeyNodeGap], a Map by node key or a
  /// [SankeyNodeCallback].
  Object? get nodePadding => jsGet(_raw, 'nodePadding');

  /// `nodePaddingMode`.
  SankeyNodePaddingMode? get nodePaddingMode =>
      SankeyNodePaddingMode.of(jsGet(_raw, 'nodePaddingMode'));

  /// `nodeWidth`.
  Object? get nodeWidth => jsGet(_raw, 'nodeWidth');

  /// `orientation`.
  SankeyOrientation? get orientation =>
      SankeyOrientation.of(jsGet(_raw, 'orientation'));

  /// `padding`: the offset of the first line of a label of several lines.
  Object? get padding => jsGet(_raw, 'padding');

  /// `parsing`.
  SankeyParsingOptions get parsing =>
      SankeyParsingOptions(jsGet(_raw, 'parsing'));

  /// `priority`: a Map from a node key to the priority of the node.
  Object? get priority => jsGet(_raw, 'priority');

  /// `size`.
  Object? get size => jsGet(_raw, 'size');
}

/// types.ts:98 `FromToElement`: one flow of a node, in the list
/// [SankeyNode.from] or [SankeyNode.to].
final class FromToElement({
  /// The offset of the flow from the start of its node.
  required var double addY,

  /// The size of the flow.
  required final double flow,

  /// The key of the node at the other end.
  required final String key,

  /// The node at the other end.
  required final SankeyNode node,

  /// The index of the flow in the data.
  required final int index,
}) {
  /// One flow of a node.
  this;
}

/// types.ts:106 `SankeyNode`: a node of the chart.
// DIVERGES(sankey): adapt-sankey-node-fields, `in` is a reserved word.
final class SankeyNode(
  /// The key of the node: the `from` or `to` of its flows.
  final String key,
) {
  /// A node without flows.
  this;

  /// `in`: the sum of the flows into the node.
  double inFlow = 0;

  /// `out`: the sum of the flows out of the node.
  double outFlow = 0;

  /// The size of the node: the larger, or with the size method `min` the
  /// smaller, of [inFlow] and [outFlow].
  double size = 0;

  /// The flows into the node.
  final List<FromToElement> from = [];

  /// The flows out of the node.
  final List<FromToElement> to = [];

  /// Whether the option `column` gives the column of the node. Dart false
  /// is the JavaScript `undefined`.
  bool column = false;

  /// The priority of the node from the option `priority`, or Dart `null`.
  double? priority;

  /// The position along the flow axis, in flow units, or Dart `null` before
  /// the layout.
  double? y;

  /// The column, or Dart `null` before the layout.
  double? x;

  /// The fill of the node: a `ChartPaint` or a `Color`, or Dart `null` for
  /// black.
  Object? color;

  @override
  String toString() => 'SankeyNode($key)';
}

/// The `_custom` of types.ts:120 `SankeyParsedData`: the target end of a
/// parsed flow. The parsed item is a `ParsedItem` of the host with `x`, `y`
/// and this object as its `custom`.
final class const SankeyParsedCustom({
  /// The source node.
  required final SankeyNode from,

  /// The target node.
  required final SankeyNode to,

  /// The parsed x of the target end.
  required final double x,

  /// The parsed y of the target end.
  required final double y,

  /// The parsed size of the flow.
  required final double height,

  /// The size of the flow.
  required final double flow,
}) {
  /// The target end of a parsed flow.
  this;
}

/// The resolved options of a flow (types.ts:157 `FlowOptions`), read by
/// name from the options object of the element.
extension type const FlowOptionsFace(Object? _raw) {
  /// `alpha`: the opacity of the flow fill.
  Object? get alpha => jsGet(_raw, 'alpha');

  /// `colorMode`.
  SankeyColorMode? get colorMode =>
      SankeyColorMode.of(jsGet(_raw, 'colorMode'));

  /// `colorFrom`: the color of the source node.
  Object? get colorFrom => jsGet(_raw, 'colorFrom');

  /// `colorTo`: the color of the target node.
  Object? get colorTo => jsGet(_raw, 'colorTo');

  /// `flowColor`: the fill of the flow, or JS `null` for the color mode.
  Object? get flowColor => jsGet(_raw, 'flowColor');

  /// `orientation`.
  SankeyOrientation? get orientation =>
      SankeyOrientation.of(jsGet(_raw, 'orientation'));

  /// `flowLabels`.
  FlowLabelsOptions get flowLabels =>
      FlowLabelsOptions(jsGet(_raw, 'flowLabels'));
}

/// The resolved `flowLabels` of types.ts:166.
extension type const FlowLabelsOptions(Object? _raw) {
  /// `backgroundColor`.
  Object? get backgroundColor => jsGet(_raw, 'backgroundColor');

  /// `borderRadius`.
  Object? get borderRadius => jsGet(_raw, 'borderRadius');

  /// `color`.
  Object? get color => jsGet(_raw, 'color');

  /// `display`.
  Object? get display => jsGet(_raw, 'display');

  /// `font`.
  TextStyle? get font => switch (jsGet(_raw, 'font')) {
    final TextStyle font => font,
    _ => null,
  };

  /// `padding`.
  Object? get padding => jsGet(_raw, 'padding');

  /// `position`.
  SankeyLabelPosition? get position =>
      SankeyLabelPosition.of(jsGet(_raw, 'position'));
}
