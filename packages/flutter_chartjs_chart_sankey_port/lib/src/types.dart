// Ported from chartjs-chart-sankey v0.19.1 src/types.ts (MIT, Jukka Kurkela).

/// The types of the sankey chart: the data point, the node, the option
/// values and the resolved options (Sankey ADRs 0002 and 0005).
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
/// - The options of a dataset and of a flow are objects of the host
///   resolver. [SankeyControllerDatasetOptions], [SankeyNodeLabelsOptions],
///   [SankeyParsingOptions], [FlowOptions] and [FlowLabelsOptions] are
///   immutable classes with a typed field for each option: their static
///   method `of` reads each key once by name, and converts its value (row
///   `adapt-sankey-resolved-options`, Sankey ADR 0005).
/// - `SankeyNodeOption<T>` (types.ts:27) is `T`, a `Map<String, T>` by node
///   key or a [SankeyNodeCallback]: a field of a node option is the
///   [SankeyNodeValue] of the typed dataset, and `resolveNodeOption` of
///   `labels.dart` gives its value for a node.
/// - The TypeScript-only declarations have no Dart form:
///   `SankeyScriptableContext` (:21, the `ScriptableContext` of the host with
///   a [SankeyDataPoint] as `raw`) and the `declare module` block
///   (:134-145).
library;

import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_chart_sankey_port/flutter_chartjs_chart_sankey_port.dart';
import 'package:flutter_chartjs_port/chartjs.dart';

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
  String toString() => 'SankeyDataPoint($from -> $to: $flow)';
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

// The reads of the resolved options (row `adapt-sankey-resolved-options`).
//
// The options of a sankey dataset and of a flow are objects of the host
// resolver. Their sankey keys are extras of the host scopes: the host has no
// typed read for them (seams S10 and S14 of host-seams.md). Each `of`
// factory below reads each key once by name with `jsGet`, and converts the
// value to the type of its field. No other code of the port reads these
// options by name.

/// The paint of the color option value [value]: a `ChartPaint`, or a
/// Flutter `Color` as its solid paint. Dart `null` for `undefined`, `null`
/// and a value of another type. CSS text is not a color: a debug build stops
/// on it.
ChartPaint? _paintOf(Object? value) {
  assert(
    value is! String,
    'A sankey color takes a ChartPaint or a Color, not the text "$value".',
  );
  return switch (value) {
    final ChartPaint paint => paint,
    final Color color => ChartPaint.solid(color),
    _ => null,
  };
}

/// `value = fallback` of a destructuring: [fallback] for `undefined`, else
/// the `ToNumber` of [value].
double _numberOr(Object? value, double fallback) =>
    value is Undefined ? fallback : jsToNumber(value);

/// The `ToNumber` of [value], or Dart `null` for `undefined`.
double? _definedNumber(Object? value) =>
    value is Undefined ? null : jsToNumber(value);

/// Whether [value] is a record: a Map, or the view of a Map that the
/// resolver of the host gives (a `Proxy` upstream). An `is Map` test is
/// false for the view (seam S10).
bool _isRecord(Object? value) => value is Map || value is JsObjectFace;

/// The entries of the record [record] by their key, each value through
/// [convert]. A value that [convert] maps to Dart `null` has no entry: its
/// read by the key is `undefined`, as the read of an absent key.
///
/// The keys are the own keys of a Map, or the keys of all the scopes of a
/// resolver view (its `ownKeys` trap): the keys for which `key in record` is
/// true upstream.
Map<String, T> _byKey<T extends Object>(
  Object? record,
  T? Function(Object? value) convert,
) => <String, T>{
  for (final key in jsOwnPropertyNames(record))
    if (convert(jsGet(record, key)) case final T value) key: value,
};

/// The number record [value] of the option `priority` or `column`: the
/// `ToNumber` of each entry. Dart `null` for a falsy value (core.ts:30,
/// :43). A truthy value that is not a record has no entry.
Map<String, double>? _numbersByKey(Object? value) =>
    jsTruthy(value) ? _byKey<double>(value, jsToNumber) : null;

/// The node option [option] (types.ts:27 `SankeyNodeOption<T>`) as a
/// [SankeyNodeValue], each value through [convert]: a function is a
/// [SankeyNodeValue.byNode], a record a [SankeyNodeValue.byKey] and another
/// value a [SankeyNodeValue.all]. Dart `null` for `undefined`, `null` and a
/// value that [convert] maps to Dart `null`: the caller takes its default.
///
/// A function is a [SankeyNodeCallback] of [C]: a function of another type
/// stops a debug build, and a release build takes the default. A gradient
/// or a pattern is not a record (labels.ts:35 `isPatternOrGradient`): it is
/// a `ChartPaint`, not a Map.
// DIVERGES(sankey): adapt-sankey-node-option, a typed union.
SankeyNodeValue<T>? _nodeValue<T extends Object, C extends Object>(
  Object? option,
  T? Function(Object? value) convert,
) {
  if (option is Function) {
    assert(
      option is SankeyNodeCallback<C>,
      'A node option function is a SankeyNodeCallback<$C>, not '
      '${option.runtimeType}.',
    );
    if (option is! SankeyNodeCallback<C>) return null;
    return SankeyNodeValue<T>.byNode((node) => convert(option(node)));
  }
  if (_isRecord(option)) {
    return SankeyNodeValue<T>.byKey(_byKey(option, convert));
  }
  final value = convert(option);
  return value == null ? null : SankeyNodeValue<T>.all(value);
}

/// The gap of the `nodePadding` value [value]: a number is the gap on both
/// sides. Dart `null` for `undefined` and `null`. A value of another type is
/// not a gap: a debug build stops on it (controller.ts:196-205).
SankeyNodeGap? _gapOf(Object? value) {
  if (value is num) {
    return SankeyNodeGap(after: value.toDouble(), before: value.toDouble());
  }
  if (value == null || value is Undefined) return null;
  assert(
    value is SankeyNodeGap,
    'A node gap is a number or a SankeyNodeGap, not ${value.runtimeType}.',
  );
  return value is SankeyNodeGap ? value : null;
}

/// types.ts:38 `SankeyControllerDatasetNodeLabelsOptions`: the resolved
/// option `nodeLabels` of a dataset.
///
/// A node option is a [SankeyNodeValue]: `resolveNodeOption` of
/// `labels.dart` gives its value for a node. A field of a number holds the
/// default of controller.ts:214-233 for `undefined`.
// DIVERGES(sankey): adapt-sankey-resolved-options, one read of each key.
final class const SankeyNodeLabelsOptions({
  /// `backgroundColor`: the fill behind a label, or Dart `null` for none.
  final SankeyNodeValue<ChartPaint>? backgroundColor,

  /// `borderRadius`: 0 for `undefined`.
  final double borderRadius = 0,

  /// `color`: the color of the text, or Dart `null` for the dataset color.
  final SankeyNodeValue<ChartPaint>? color,

  /// `display`, or Dart `null` for true.
  final SankeyNodeValue<bool>? display,

  /// `font`, or Dart `null` for the font of the dataset.
  final TextStyle? font,

  /// `padding`: 4 for `undefined`.
  final double padding = 4,

  /// `position`, or Dart `null` for [SankeyLabelPosition.auto].
  final SankeyNodeValue<SankeyLabelPosition>? position,
}) {
  /// The resolved node label options with the given values.
  this;

  /// The node label options of the resolved option value [options]: one
  /// read of each key. `undefined` and `null` give the defaults.
  // A static method, as the resolved options of the host: a factory makes
  // the lint ask for const literals.
  // ignore: prefer_constructors_over_static_methods
  static SankeyNodeLabelsOptions of(Object? options) {
    if (isNullOrUndef(options)) return const SankeyNodeLabelsOptions();
    final font = jsGet(options, 'font');
    return SankeyNodeLabelsOptions(
      backgroundColor: _nodeValue<ChartPaint, Object>(
        jsGet(options, 'backgroundColor'),
        _paintOf,
      ),
      borderRadius: _numberOr(jsGet(options, 'borderRadius'), 0),
      color: _nodeValue<ChartPaint, Object>(jsGet(options, 'color'), _paintOf),
      display: _nodeValue<bool, bool>(
        jsGet(options, 'display'),
        (value) => value is bool ? value : null,
      ),
      font: font is TextStyle ? font : null,
      padding: _numberOr(jsGet(options, 'padding'), 4),
      position: _nodeValue<SankeyLabelPosition, SankeyLabelPosition>(
        jsGet(options, 'position'),
        (value) => value is SankeyLabelPosition ? value : null,
      ),
    );
  }
}

/// types.ts:58 `SankeyParsingOptions`: the keys of a data item that is a
/// Map.
// DIVERGES(sankey): adapt-sankey-resolved-options, one read of each key.
final class const SankeyParsingOptions({
  /// `from`: the key of the source node key.
  final String from = 'from',

  /// `to`: the key of the target node key.
  final String to = 'to',

  /// `flow`: the key of the flow size.
  final String flow = 'flow',
}) {
  /// The parsing keys with the given values.
  this;

  /// The parsing keys of the resolved option value [options]: one read of
  /// each key. A key that is not a string takes its default (the default of
  /// the destructuring of core.ts:56 applies to `undefined`).
  // ignore: prefer_constructors_over_static_methods
  static SankeyParsingOptions of(Object? options) {
    String keyOr(String name) => switch (jsGet(options, name)) {
      final String key => key,
      _ => name,
    };
    return SankeyParsingOptions(
      flow: keyOr('flow'),
      from: keyOr('from'),
      to: keyOr('to'),
    );
  }
}

/// types.ts:64 `SankeyControllerDatasetOptions`: the resolved options of a
/// sankey dataset.
///
/// [SankeyControllerDatasetOptions.of] reads each key of the resolver of the
/// controller once. The controller reads them again after each `configure`,
/// which makes a new resolver: upstream reads the same resolver at each use,
/// and the resolver caches each value at its first read. A field of a
/// number holds the default of its use for `undefined`, or Dart `null` where
/// the uses have other defaults.
// DIVERGES(sankey): adapt-sankey-resolved-options, one read of each key.
final class const SankeyControllerDatasetOptions({
  /// `borderColor`: the stroke of a node, or Dart `null` for a falsy value.
  final ChartPaint? borderColor,

  /// `borderWidth`: the stroke width of a node, or Dart `null` for
  /// `undefined`.
  final double? borderWidth,

  /// `color`: the color of the node labels, or Dart `null` for `null` and
  /// `undefined`.
  final ChartPaint? color,

  /// `column`: the column of a node by its key, or Dart `null` for a falsy
  /// value.
  final Map<String, double>? column,

  /// `font`: the font of the node labels, or Dart `null` for the font of
  /// the chart.
  final TextStyle? font,

  /// `labels`: the label of a node by its key, or Dart `null` for `null` and
  /// `undefined`. A label is a string, a number or a List of them.
  final Map<String, Object>? labels,

  /// `modeX`, or Dart `null` for [SankeyModeX.edge].
  final SankeyModeX? modeX,

  /// `nodeLabels`.
  final SankeyNodeLabelsOptions nodeLabels = const SankeyNodeLabelsOptions(),

  /// `nodeMinSize`, or Dart `null` for 0.
  final SankeyNodeValue<double>? nodeMinSize,

  /// `nodePadding`: the gap of a node, or Dart `null` for 10. A number is
  /// the gap on both sides.
  final SankeyNodeValue<SankeyNodeGap>? nodePadding,

  /// `nodePaddingMode`, or Dart `null` for [SankeyNodePaddingMode.auto].
  final SankeyNodePaddingMode? nodePaddingMode,

  /// `nodeWidth`: 10 for `undefined`.
  final double nodeWidth = 10,

  /// `orientation`: [SankeyOrientation.horizontal] for a value that is not
  /// a [SankeyOrientation].
  final SankeyOrientation orientation = SankeyOrientation.horizontal,

  /// `padding`: the offset of the first line of a label of several lines,
  /// or Dart `null` for `undefined`.
  final double? padding,

  /// `parsing`, or Dart `null` for `null` and `undefined`: the destructuring
  /// of core.ts:56 throws a `TypeError` for them.
  final SankeyParsingOptions? parsing = const SankeyParsingOptions(),

  /// `priority`: the priority of a node by its key, or Dart `null` for a
  /// falsy value.
  final Map<String, double>? priority,

  /// `size` (helpers.ts:25 `validateSizeValue`).
  final SankeySize size = SankeySize.max,
}) {
  /// The resolved dataset options with the given values.
  this;

  /// The dataset options of the resolver [options]: one read of each key,
  /// in the key order of types.ts:64.
  // ignore: prefer_constructors_over_static_methods
  static SankeyControllerDatasetOptions of(Object? options) {
    final borderColor = jsGet(options, 'borderColor');
    final font = jsGet(options, 'font');
    final labels = jsGet(options, 'labels');
    final parsing = jsGet(options, 'parsing');
    return SankeyControllerDatasetOptions(
      borderColor: jsTruthy(borderColor) ? _paintOf(borderColor) : null,
      borderWidth: _definedNumber(jsGet(options, 'borderWidth')),
      color: _paintOf(jsGet(options, 'color')),
      column: _numbersByKey(jsGet(options, 'column')),
      font: font is TextStyle ? font : null,
      labels: isNullOrUndef(labels)
          ? null
          : _byKey<Object>(
              labels,
              (value) => isNullOrUndef(value) ? null : value,
            ),
      modeX: SankeyModeX.of(jsGet(options, 'modeX')),
      nodeLabels: SankeyNodeLabelsOptions.of(jsGet(options, 'nodeLabels')),
      nodeMinSize: _nodeValue<double, num>(
        jsGet(options, 'nodeMinSize'),
        (value) => value is num ? value.toDouble() : null,
      ),
      nodePadding: _nodeValue<SankeyNodeGap, Object>(
        jsGet(options, 'nodePadding'),
        _gapOf,
      ),
      nodePaddingMode: SankeyNodePaddingMode.of(
        jsGet(options, 'nodePaddingMode'),
      ),
      nodeWidth: _numberOr(jsGet(options, 'nodeWidth'), 10),
      orientation:
          SankeyOrientation.of(jsGet(options, 'orientation')) ??
          SankeyOrientation.horizontal,
      padding: _definedNumber(jsGet(options, 'padding')),
      parsing: isNullOrUndef(parsing) ? null : SankeyParsingOptions.of(parsing),
      priority: _numbersByKey(jsGet(options, 'priority')),
      size: validateSizeValue(jsGet(options, 'size')),
    );
  }
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

  /// The fill of the node, or Dart `null` for black.
  ChartPaint? color;

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

/// types.ts:157 `FlowOptions`: the resolved options of a flow element.
///
/// [FlowOptions.of] reads each key of the options object of the element
/// once. `Flow.flowOptions` keeps the result for options that the host
/// froze: they do not change. Other options (the options of one flow, which
/// an update or an animation writes) give a new read at each use.
// DIVERGES(sankey): adapt-sankey-resolved-options, one read of each key.
final class const FlowOptions({
  /// `alpha`: the opacity of the flow fill, the `ToNumber` of the value.
  required final double alpha,

  /// `colorFrom`: the color of the source node, or Dart `null` for
  /// `undefined`.
  final ChartPaint? colorFrom,

  /// `colorMode`, or Dart `null` for [SankeyColorMode.gradient].
  final SankeyColorMode? colorMode,

  /// `colorTo`: the color of the target node, or Dart `null` for
  /// `undefined`.
  final ChartPaint? colorTo,

  /// `flowColor`: the fill of the flow. Dart `null` is the JavaScript
  /// `null` of the default: the color mode gives the fill. An `undefined`
  /// value is [UnchangedChartPaint]: the flow sets no new fill (flow.ts:56).
  final ChartPaint? flowColor,

  /// `flowLabels`, or Dart `null` when its `display` is falsy: upstream
  /// reads no other key of a hidden label (flow.ts:197).
  final FlowLabelsOptions? flowLabels,

  /// `orientation`: [SankeyOrientation.horizontal] for a value that is not
  /// a [SankeyOrientation].
  final SankeyOrientation orientation = SankeyOrientation.horizontal,
}) {
  /// The resolved flow options with the given values.
  this;

  /// The flow options of the options object [options]: one read of each
  /// key. The keys `hoverColorFrom` and `hoverColorTo` have no field: no
  /// code reads them by these names (row `adapt-sankey-hover-color-keys`).
  // ignore: prefer_constructors_over_static_methods
  static FlowOptions of(Object? options) {
    final flowColor = jsGet(options, 'flowColor');
    return FlowOptions(
      alpha: jsToNumber(jsGet(options, 'alpha')),
      colorFrom: _paintOf(jsGet(options, 'colorFrom')),
      colorMode: SankeyColorMode.of(jsGet(options, 'colorMode')),
      colorTo: _paintOf(jsGet(options, 'colorTo')),
      flowColor: switch (flowColor) {
        null => null,
        Undefined() => const ChartPaint.unchanged(),
        _ => _paintOf(flowColor),
      },
      flowLabels: FlowLabelsOptions.of(jsGet(options, 'flowLabels')),
      orientation:
          SankeyOrientation.of(jsGet(options, 'orientation')) ??
          SankeyOrientation.horizontal,
    );
  }
}

/// types.ts:166 the resolved `flowLabels` of a flow that shows its label.
// DIVERGES(sankey): adapt-sankey-resolved-options, one read of each key.
final class const FlowLabelsOptions({
  /// `backgroundColor`: the fill behind the label, or Dart `null` for none.
  final ChartPaint? backgroundColor,

  /// `borderRadius`: the `ToNumber` of the value (NaN for `undefined`, no
  /// rounded corner).
  final double borderRadius = 0,

  /// `color`: the fill of the text, or Dart `null` for `undefined` (no new
  /// fill).
  final ChartPaint? color,

  /// `font`, or Dart `null` for the default font.
  final TextStyle? font,

  /// `padding`: the `ToNumber` of the value.
  final double padding = 4,

  /// `position`: [SankeyLabelPosition.center] for a value that is not a
  /// [SankeyLabelPosition].
  final SankeyLabelPosition position = SankeyLabelPosition.center,
}) {
  /// The resolved flow label options with the given values.
  this;

  /// The flow label options of the resolved option value [options], or
  /// Dart `null` when its `display` is falsy. Upstream reads the other keys
  /// only for a label that shows.
  static FlowLabelsOptions? of(Object? options) {
    if (!jsTruthy(jsGet(options, 'display'))) return null;
    final font = jsGet(options, 'font');
    return FlowLabelsOptions(
      backgroundColor: _paintOf(jsGet(options, 'backgroundColor')),
      borderRadius: jsToNumber(jsGet(options, 'borderRadius')),
      color: _paintOf(jsGet(options, 'color')),
      font: font is TextStyle ? font : null,
      padding: jsToNumber(jsGet(options, 'padding')),
      position:
          SankeyLabelPosition.of(jsGet(options, 'position')) ??
          SankeyLabelPosition.center,
    );
  }
}
