// Ported from chartjs-chart-sankey v0.19.1 src/lib/core.ts (MIT, Jukka Kurkela).

/// Port of `src/lib/core.ts`: the data points and the nodes of the data.
library;

import 'dart:math';

import 'package:flutter_chartjs_chart_sankey_port/flutter_chartjs_chart_sankey_port.dart';
import 'package:flutter_chartjs_port/js_semantics.dart';

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
    SankeySize.min => min(a, b),
    SankeySize.max => max(a, b),
  };
}

/// core.ts:18 `setSizes`.
void _setSizes(Map<String, SankeyNode> nodes, SankeySize? size) {
  final sizeMethod = validateSizeValue(size);

  for (final node in nodes.values) {
    jsSort(node.from, _flowSort);
    jsSort(node.to, _flowSort);
    node.size = nodeSizeOf(node, sizeMethod);
  }
}

/// core.ts:29 `setPriorities`. [priority] is the priority of a node by its
/// key, or Dart `null` for a falsy option (the resolved option
/// `SankeyControllerDatasetOptions.priority`).
void _setPriorities(
  Map<String, SankeyNode> nodes,
  Map<String, double>? priority,
) {
  if (priority == null) return;

  for (final node in nodes.values) {
    final value = priority[node.key];
    if (value != null) {
      node.priority = value;
    }
  }
}

/// core.ts:42 `setColumns`. [column] is the column of a node by its key, or
/// Dart `null` for a falsy option.
void _setColumns(Map<String, SankeyNode> nodes, Map<String, double>? column) {
  if (column == null) return;

  for (final node in nodes.values) {
    final value = column[node.key];
    if (value != null) {
      node
        ..column = true
        ..x = value;
    }
  }
}

/// core.ts:55 `getParsedData`: the data points of the data items [data].
///
/// An item is a [SankeyDataPoint], or an object that the keys of [parsing]
/// read. The node keys are strings and the flow is a number in the port:
/// another value takes its `ToString` or its `ToNumber`. Dart `null` for
/// [parsing] is the `null` or `undefined` option, whose destructuring throws
/// a [TypeError].
// DIVERGES(sankey): adapt-sankey-data-point, typed data points.
List<SankeyDataPoint> getParsedData(
  List<Object?> data,
  SankeyParsingOptions? parsing,
) {
  if (parsing == null) throw TypeError();
  final SankeyParsingOptions(from: fromKey, to: toKey, flow: flowKey) = parsing;

  return [
    for (final item in data)
      if (item is SankeyDataPoint)
        item
      else
        SankeyDataPoint(
          from: _nodeKey(jsGetKey(item, fromKey)),
          to: _nodeKey(jsGetKey(item, toKey)),
          flow: jsToNumber(jsGetKey(item, flowKey)),
        ),
  ];
}

/// The node key of [value].
String _nodeKey(Object? value) => value is String ? value : jsToString(value);

/// core.ts:66 `buildNodesFromData`: the nodes of [data] by their key, in
/// the order of their first flow.
///
/// [size], [priority] and [column] are the resolved options of the
/// dataset with these names (`SankeyControllerDatasetOptions`).
// DIVERGES(sankey): adapt-sankey-resolved-options, the resolved options.
Map<String, SankeyNode> buildNodesFromData(
  List<SankeyDataPoint> data, {
  SankeySize? size,
  Map<String, double>? priority,
  Map<String, double>? column,
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
