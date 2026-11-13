// Ported from chartjs-chart-sankey v0.19.1 src/lib/core.ts (MIT, Jukka Kurkela).

/// Port of `src/lib/core.ts`: the data points and the nodes of the data.
library;

import 'dart:math' as math;

import 'package:flutter_chartjs_chart_sankey_port/src/lib/helpers.dart';
import 'package:flutter_chartjs_chart_sankey_port/src/types.dart';
import 'package:flutter_chartjs_port/js_semantics.dart'
    show
        JsObjectFace,
        JsProxyObject,
        jsGet,
        jsSort,
        jsToNumber,
        jsToString,
        jsTruthy;

/// core.ts:11 `flowSort`: the larger flow first.
double _flowSort(FromToElement a, FromToElement b) {
  // In case the flows are equal, keep original order
  if (b.flow == a.flow) return (a.index - b.index).toDouble();

  return b.flow - a.flow;
}

/// `a || b` of two numbers: [a] unless it is 0 or NaN.
double _or(double a, double b) => a != 0 && !a.isNaN ? a : b;

/// `Math[size](node.in || node.out, node.out || node.in)` (core.ts:26,
/// controller.ts:31, :563): the size of [node] by the size method [size].
double nodeSizeOf(SankeyNode node, SankeySize size) {
  // Fallbacks with || are for zero values and min method to avoid zero size.
  final a = _or(node.inFlow, node.outFlow);
  final b = _or(node.outFlow, node.inFlow);
  return switch (size) {
    SankeySize.min => math.min(a, b),
    SankeySize.max => math.max(a, b),
  };
}

/// core.ts:18 `setSizes`.
void _setSizes(Map<String, SankeyNode> nodes, Object? size) {
  final sizeMethod = validateSizeValue(size);

  for (final node in nodes.values) {
    jsSort(node.from, _flowSort);
    jsSort(node.to, _flowSort);
    node.size = nodeSizeOf(node, sizeMethod);
  }
}

/// `key in object` for a Map of a config, or the view of a Map that the
/// resolver of the host gives (a `Proxy` upstream).
bool _hasKey(Object? object, String key) => switch (object) {
  final Map<Object?, Object?> map => map.containsKey(key),
  final JsProxyObject proxy => proxy.hasProperty(key),
  final JsObjectFace face => face.jsHas(key),
  _ => false,
};

/// core.ts:29 `setPriorities`. [priority] is a Map from a node key to a
/// number, or a falsy value.
void _setPriorities(Map<String, SankeyNode> nodes, Object? priority) {
  if (!jsTruthy(priority)) return;

  for (final node in nodes.values) {
    if (_hasKey(priority, node.key)) {
      node.priority = jsToNumber(jsGet(priority, node.key));
    }
  }
}

/// core.ts:42 `setColumns`. [column] is a Map from a node key to a column,
/// or a falsy value.
void _setColumns(Map<String, SankeyNode> nodes, Object? column) {
  if (!jsTruthy(column)) return;

  for (final node in nodes.values) {
    if (_hasKey(column, node.key)) {
      node
        ..column = true
        ..x = jsToNumber(jsGet(column, node.key));
    }
  }
}

/// core.ts:55 `getParsedData`: the data points of the data items [data].
///
/// An item is a [SankeyDataPoint], or an object that the keys of [parsing]
/// read. A key of [parsing] defaults to `'from'`, `'to'` or `'flow'`. The
/// node keys are strings and the flow is a number in the port: another value
/// takes its `ToString` or its `ToNumber`.
// DIVERGES(sankey): adapt-sankey-data-point, typed data points.
List<SankeyDataPoint> getParsedData(
  List<Object?> data,
  SankeyParsingOptions parsing,
) {
  final fromKey = _keyOr(parsing.from, 'from');
  final toKey = _keyOr(parsing.to, 'to');
  final flowKey = _keyOr(parsing.flow, 'flow');

  return [
    for (final item in data)
      if (item is SankeyDataPoint)
        item
      else
        SankeyDataPoint(
          from: _nodeKey(jsGet(item, fromKey)),
          to: _nodeKey(jsGet(item, toKey)),
          flow: jsToNumber(jsGet(item, flowKey)),
        ),
  ];
}

/// The parsing key [value], or [fallback] for a value that is not a string
/// (the destructuring default applies to `undefined`).
String _keyOr(Object? value, String fallback) =>
    value is String ? value : fallback;

/// The node key of [value].
String _nodeKey(Object? value) => value is String ? value : jsToString(value);

/// core.ts:66 `buildNodesFromData`: the nodes of [data] by their key, in
/// the order of their first flow.
///
/// [size], [priority] and [column] are the options of the dataset with
/// these names.
Map<String, SankeyNode> buildNodesFromData(
  List<SankeyDataPoint> data, {
  Object? size,
  Object? priority,
  Object? column,
}) {
  final nodes = <String, SankeyNode>{};
  for (var i = 0; i < data.length; i++) {
    final SankeyDataPoint(:from, :to, :flow) = data[i];

    final fromNode = nodes[from] ?? SankeyNode(from);

    final toNode = (from == to ? fromNode : nodes[to]) ?? SankeyNode(to);

    fromNode
      ..outFlow += flow
      ..to.add(
        FromToElement(addY: 0, flow: flow, index: i, key: to, node: toNode),
      );
    if (fromNode.to.length == 1) {
      nodes[from] = fromNode;
    }

    toNode
      ..inFlow += flow
      ..from.add(
        FromToElement(addY: 0, flow: flow, index: i, key: from, node: fromNode),
      );
    if (toNode.from.length == 1) {
      nodes[to] = toNode;
    }
  }

  _setSizes(nodes, size);
  _setPriorities(nodes, priority);
  _setColumns(nodes, column);

  return nodes;
}
