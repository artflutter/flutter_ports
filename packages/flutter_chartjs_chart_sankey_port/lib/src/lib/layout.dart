// Ported from chartjs-chart-sankey v0.19.1 src/lib/layout.ts (MIT, Jukka Kurkela).

/// Port of `src/lib/layout.ts`: the columns and the positions of the nodes.
///
/// The positions are in flow units. A column is a number from 0. Each sort
/// is the stable `Array.prototype.sort` (`jsSort`): the order of two equal
/// nodes decides their positions.
library;

import 'dart:math' as math;

import 'package:flutter_chartjs_chart_sankey_port/src/lib/helpers.dart';
import 'package:flutter_chartjs_chart_sankey_port/src/types.dart';
import 'package:flutter_chartjs_port/js_semantics.dart' show jsSort;

const double _smallValue = 1e-6;

/// layout.ts:13 `SankeyMode = 'edge' | 'even'`.
typedef SankeyMode = SankeyModeX;

double _nodeX(SankeyNode node) => node.x ?? 0;

double _nodeY(SankeyNode node) => node.y ?? 0;

/// `value || 0` and the truthiness of a number: false for 0 and NaN.
bool _truthy(double value) => value != 0 && !value.isNaN;

/// layout.ts:26 `getAllKeysForward`.
///
/// Get all keys the input nodes flow to, including keys of the input nodes
List<String> getAllKeysForward(List<SankeyNode> nodes, [Set<String>? visited]) {
  final seen = visited ?? <String>{};
  final keys = <String>[];
  for (final node in nodes) {
    if (seen.contains(node.key)) continue;
    seen.add(node.key);
    keys
      ..add(node.key)
      ..addAll(getAllKeysForward([for (final to in node.to) to.node], seen));
  }

  return keys;
}

/// layout.ts:50 `startColumn`.
///
/// Find the nodes that should be placed leftmost on the chart.
/// NOTE: With circular flows, data order matters.
List<String> startColumn(List<SankeyDataPoint> data, List<SankeyNode> nodes) {
  // First check if there are nodes without any input. Start from those.
  final startNodes = [
    for (final node in nodes)
      if (node.from.isEmpty) node,
  ];
  final column = [for (final node in startNodes) node.key];

  final startRef = getAllKeysForward(startNodes);

  // If there are no nodes without any inputs, this is a fully circular chart.
  // Build the start column based on data order and references.
  final referencedNodes = startRef.toSet();

  for (final point in data) {
    if (!referencedNodes.contains(point.from) &&
        !referencedNodes.contains(point.to)) {
      column.add(point.from);
      referencedNodes.add(point.from);
    }
    referencedNodes.add(point.to);
  }
  return column;
}

/// layout.ts:77 `nextColumn`.
///
/// Figure out the next column from remainingKeys
/// @param dataWithoutDirectLoops - data filtered so it does not contain
/// direct loops (from === to)
/// @param remainingKeys - they keys that are not yet placed to the chart
/// @returns array of node keys to place in the next column
List<String> _nextColumn(
  List<SankeyDataPoint> dataWithoutDirectLoops,
  Set<String> remainingKeys,
) {
  final remainingTo = {
    for (final flow in dataWithoutDirectLoops)
      if (remainingKeys.contains(flow.from)) flow.to,
  };
  final remainingKeyArray = [...remainingKeys];
  final columnsNotInTo = [
    for (final key in remainingKeyArray)
      if (!remainingTo.contains(key)) key,
  ];

  return columnsNotInTo.isNotEmpty
      ? columnsNotInTo
      : remainingKeyArray.sublist(0, 1);
}

/// layout.ts:90 `calculateX`: gives each node its column and returns the
/// last column.
double calculateX(
  Map<String, SankeyNode> nodeMap,
  List<SankeyDataPoint> data,
  SankeyMode mode,
) {
  final dataWithoutDirectLoops = [
    for (final dp in data)
      if (dp.from != dp.to) dp,
  ];
  final allKeys = [...nodeMap.keys];
  final allNodes = [...nodeMap.values];
  final keysToPlace = allKeys.toSet();
  var x = 0.0;
  while (keysToPlace.isNotEmpty) {
    final column = x == 0
        ? startColumn(data, allNodes)
        : _nextColumn(dataWithoutDirectLoops, keysToPlace);

    if (column.isEmpty) {
      // In case thre is a bug in column determination, throw an error
      // instead of looping endlessly.
      throw StateError(
        'Fatal error: Unable to place nodes to columns. Please report this '
        'issue.',
      );
    }

    for (final key in column) {
      final node = nodeMap[key];
      if (node != null && !defined(node.x)) {
        node.x = x;
      }
      keysToPlace.remove(key);
    }
    if (keysToPlace.isNotEmpty) {
      x++;
    }
  }

  // Calculate the maxX from nodes in case some were placed by column option
  final maxX = allNodes.fold<double>(
    0,
    (max, node) => math.max(max, _nodeX(node)),
  );

  if (mode == SankeyMode.edge) {
    // Move nodes that have no output to the right edge of the flow
    final from = {for (final dataPoint in data) dataPoint.from};
    for (final key in allKeys) {
      if (from.contains(key)) continue;
      final node = nodeMap[key];
      // Only move the node to right edge, if it's column is not defined
      if (node != null && !node.column) {
        node.x = maxX;
      }
    }
  }

  return maxX;
}

/// layout.ts:141 `FlowDirection = 'from' | 'to'`: a flow list of a node.
enum FlowDirection() {
  /// `'from'`: [SankeyNode.from].
  from,

  /// `'to'`: [SankeyNode.to].
  to;

  /// `node[prop]`: the flow list of [node] in this direction.
  List<FromToElement> of(SankeyNode node) => switch (this) {
    from => node.from,
    to => node.to,
  };
}

/// layout.ts:143 `nodeCount`.
int nodeCount(
  List<FromToElement> list,
  FlowDirection prop, [
  Set<SankeyNode>? seen,
]) {
  final visited = seen ?? <SankeyNode>{};
  var count = 0;
  for (final elem in list) {
    if (visited.contains(elem.node)) {
      continue;
    }
    visited.add(elem.node);
    final flows = prop.of(elem.node);
    count += flows.length + nodeCount(flows, prop, visited);
  }
  return count;
}

/// layout.ts:159 `flowByNodeCount`.
num Function(FromToElement a, FromToElement b) _flowByNodeCount(
  FlowDirection prop,
) => (a, b) {
  final aFlows = prop.of(a.node);
  final bFlows = prop.of(b.node);
  final byCount = nodeCount(aFlows, prop) - nodeCount(bFlows, prop);
  return byCount != 0 ? byCount : aFlows.length - bFlows.length;
};

/// layout.ts:165 `processFrom`.
double _processFrom(SankeyNode node, double start) {
  var y = start;
  if (node.from.isEmpty) return y;

  jsSort(node.from, _flowByNodeCount(FlowDirection.from));
  for (final flow in node.from) {
    final n = flow.node;
    if (!defined(n.y)) {
      n.y = y;
      _processFrom(n, _truthy(y) ? y + _smallValue : 0);
    }
    y = math.max(n.y! + n.outFlow, y);
  }
  return _nodeY(node) + node.size;
}

/// layout.ts:180 `returnsToNearerColumn`.
bool returnsToNearerColumn(SankeyNode current, [SankeyNode? next]) =>
    next != null && _nodeX(next) < _nodeX(current);

/// layout.ts:183 `processTo`.
double _processTo(SankeyNode node, double start) {
  var y = start;
  if (node.to.isEmpty) return y;

  // Place less-connected branches first so terminal paths stay close to the
  // edge of their source flow and more complex branches can continue inward.
  jsSort(node.to, _flowByNodeCount(FlowDirection.to));
  for (var i = 0; i < node.to.length; i++) {
    final flow = node.to[i];
    final n = flow.node;
    if (!defined(n.y)) {
      // A node may already have been positioned through another branch. Only
      // recurse when this is the first path that reaches it.
      n.y = y;
      _processTo(n, _truthy(y) ? y + _smallValue : 0);
    }
    if (returnsToNearerColumn(
      n,
      i + 1 < node.to.length ? node.to[i + 1].node : null,
    )) {
      // When traversal returns from a farther column to a nearer sibling,
      // advance within the source node by this link only. Using the farther
      // node's total size would also count inputs arriving from other paths
      // and push the nearer sibling too far down.
      y += flow.flow;
    } else {
      // Within the same traversal direction, reserve the destination node's
      // full height so subsequently placed nodes cannot overlap it.
      y = math.max(n.y! + math.max<double>(n.inFlow, n.outFlow), y);
    }
  }
  return _nodeY(node) + node.size;
}

/// layout.ts:213 `setOrGetY`.
double _setOrGetY(SankeyNode node, double value) {
  final y = node.y;
  if (y != null) {
    return y;
  }
  node.y = value;

  return value;
}

/// layout.ts:222 `processRest`.
double _processRest(List<SankeyNode> nodeArray, double maxX) {
  final leftNodes = [
    for (final node in nodeArray)
      if (node.x == 0) node,
  ];
  final rightNodes = [
    for (final node in nodeArray)
      if (node.x == maxX) node,
  ];
  final leftToDo = [
    for (final node in leftNodes)
      if (!defined(node.y)) node,
  ];
  final rightToDo = [
    for (final node in rightNodes)
      if (!defined(node.y)) node,
  ];
  final centerToDo = [
    for (final node in nodeArray)
      if (_nodeX(node) > 0 && _nodeX(node) < maxX && !defined(node.y)) node,
  ];

  var leftY =
      leftNodes.fold<double>(0, (acc, cur) {
        final end = _nodeY(cur) + cur.outFlow;
        return math.max(acc, _truthy(end) ? end : 0);
      }) +
      _smallValue;
  var rightY =
      rightNodes.fold<double>(0, (acc, cur) {
        final end = _nodeY(cur) + cur.inFlow;
        return math.max(acc, _truthy(end) ? end : 0);
      }) +
      _smallValue;
  var centerY = 0.0;

  if (leftY >= rightY) {
    for (final node in leftToDo) {
      leftY = _setOrGetY(node, leftY);
      leftY = math.max(leftY + node.outFlow, _processTo(node, leftY));
    }

    for (final node in rightToDo) {
      rightY = _setOrGetY(node, rightY);
      rightY = math.max(rightY + node.inFlow, _processFrom(node, rightY));
    }
  } else {
    for (final node in leftToDo) {
      leftY = _setOrGetY(node, leftY);
    }

    for (final node in rightToDo) {
      rightY = _setOrGetY(node, rightY);
      rightY = math.max(rightY + node.inFlow, _processFrom(node, rightY));
    }
  }
  for (final node in centerToDo) {
    var y = nodeArray
        .where((n) => _nodeX(n) == _nodeX(node) && defined(n.y))
        .fold<double>(
          0,
          (acc, cur) => math.max(
            acc,
            _nodeY(cur) + math.max<double>(cur.inFlow, cur.outFlow),
          ),
        );
    y = _setOrGetY(node, y);
    y = math.max(y + node.inFlow, _processFrom(node, y));
    y = math.max(y + node.outFlow, _processTo(node, y));
    centerY = math.max(centerY, y);
  }

  return math.max(math.max(leftY, rightY), centerY);
}

/// layout.ts:270 `fixTop`.
double _fixTop(List<SankeyNode> nodeArray, double maxX) {
  var maxY = 0.0;
  for (var x = 0.0; x <= maxX; x++) {
    final nodes = jsSort([
      for (final n in nodeArray)
        if (_nodeX(n) == x) n,
    ], (a, b) => _nodeY(a) - _nodeY(b));
    var minY = 0.0;
    for (final node in nodes) {
      if (_nodeY(node) < minY) node.y = minY;
      minY = _nodeY(node) + node.size;
    }
    maxY = math.max(maxY, minY);
  }
  return maxY;
}

/// layout.ts:284 `findStartNode`.
SankeyNode _findStartNode(List<SankeyNode> nodeArray, double maxX) {
  final sorted = jsSort([...nodeArray], (a, b) => a.size - b.size);
  final largest = sorted[sorted.length - 1];
  final size = largest.size;
  final biggest = [
    for (final n in nodeArray)
      if (n.size == size) n,
  ];

  final first = biggest[0];
  if (biggest.length == 1) return first;

  jsSort(biggest, (a, b) => _nodeX(a) - _nodeX(b));

  // if there is a big node at left edge, use it as starting point
  if (_nodeX(first) == 0) return first;

  // same for right edge
  final last = biggest[biggest.length - 1];
  if (_nodeX(last) == maxX) return last;

  // else start from center
  final mid = biggest.length ~/ 2;
  return biggest[mid];
}

/// layout.ts:307 `calculateY`.
double calculateY(List<SankeyNode> nodeArray, double maxX) {
  if (nodeArray.isEmpty) return 0;

  final start = _findStartNode(nodeArray, maxX)..y = 0;
  _processFrom(start, 0);
  _processTo(start, 0);
  _processRest(nodeArray, maxX);
  return _fixTop(nodeArray, maxX);
}

/// layout.ts:318 `calculateYUsingPriority`.
double calculateYUsingPriority(List<SankeyNode> nodeArray, double maxX) {
  var maxY = 0.0;
  var nextYStart = 0.0;
  for (var x = 0.0; x <= maxX; x++) {
    var y = nextYStart;
    final nodes = jsSort([
      for (final node in nodeArray)
        if (_nodeX(node) == x) node,
    ], (a, b) => (a.priority ?? 0) - (b.priority ?? 0));
    if (nodes.isNotEmpty) {
      final nextX = nodeArray.fold<double>(
        double.infinity,
        (next, node) => _nodeX(node) > x ? math.min(next, _nodeX(node)) : next,
      );
      final sum = nodes[0].to
          .where((to) => _nodeX(to.node) > nextX)
          .fold<double>(0, (acc, cur) => acc + cur.flow);
      nextYStart = _truthy(sum) ? sum : 0;
    }
    for (final node in nodes) {
      node.y = y;
      y += math.max<double>(node.outFlow, node.inFlow);
    }
    maxY = math.max(y, maxY);
  }
  return maxY;
}

/// layout.ts:346 `nodeByXYSize`.
double _nodeByXYSize(SankeyNode a, SankeyNode b) {
  if (_nodeX(a) != _nodeX(b)) return _nodeX(a) - _nodeX(b);
  if (_nodeY(a) == _nodeY(b)) return a.size - b.size;
  return _nodeY(a) - _nodeY(b);
}

/// layout.ts:369 `ColumnGapState`.
///
/// Per-column bookkeeping used while walking nodes top-to-bottom.
///
/// `yHistory` mirrors the original (pre-per-node-gap) algorithm's `column`
/// array: it holds the un-padded y of every "padding level" seen in this
/// column, including virtual duplicates added to satisfy a cross-column
/// requirement. It only exists to reproduce the exact same level count (see
/// `countCrossColumnPaddings`), regardless of which gaps are in play.
///
/// `realCount`/`realCumOffset`/`lastAfter` track the *real* nodes seen in
/// this column so far, so the actual vertical gap between two adjacent real
/// nodes (`max(prev.after, next.before)`) can be summed independently of any
/// cross-column padding inflation.
final class _ColumnGapState() {
  double lastAfter = 0;

  /// Half of the previous real node's `nodeMinSize` stretch (see
  /// `extraHalfFor`), carried so the transition to the next real node in
  /// this column can reserve room for both nodes' stretch, not just the
  /// requested gap.
  double lastExtraHalf = 0;
  int realCount = 0;
  double realCumOffset = 0;
  final List<double> yHistory = [];
}

/// layout.ts:395 `extraHalfFor`.
///
/// Half of how much a node's drawn bar is stretched beyond its natural
/// (flow-space) `size` to satisfy `nodeMinSize`, in the same flow units as
/// `size`. The stretch is applied symmetrically around the node's real
/// position (see `getNodeRect` in controller.ts), so only half of it eats
/// into the gap above/below the node -- the other half eats into the gap on
/// the other side.
double _extraHalfFor(
  SankeyNode node,
  Map<String, double> minSizes,
  double scale,
) {
  final minSizeUnits = (minSizes[node.key] ?? 0) * scale;
  return math.max<double>(0, minSizeUnits - node.size) / 2;
}

/// layout.ts:408 `stretchedSize`.
///
/// The flow-unit height of a node's drawn bar after stretching for
/// `nodeMinSize` (or its natural `size`, if that already meets the minimum).
double _stretchedSize(
  SankeyNode node,
  Map<String, double> minSizes,
  double scale,
) {
  final minSizeUnits = (minSizes[node.key] ?? 0) * scale;
  return math.max(node.size, minSizeUnits);
}

/// layout.ts:419 `countCrossColumnPaddings`.
// Count how many padding levels this node needs, based on how many nodes are
// above it in columns to the left (its inputs must clear all of them).
int _countCrossColumnPaddings(
  List<_ColumnGapState> grid,
  int colIdx,
  double y,
  int ownPaddings,
) {
  var paddings = ownPaddings;
  for (var col = 0; col < colIdx; col++) {
    final otherHistory = grid[col].yHistory;
    for (var row = 0; row < otherHistory.length; row++) {
      if (otherHistory[row] > y) break;
      if (row + 1 > paddings) paddings = row + 1;
    }
  }
  return paddings;
}

/// layout.ts:447 `offsetForNode`.
// Offset for a node with `paddings` total levels, of which `state.realCount`
// are backed by a real predecessor in the same column (summed using the
// collapsing `max(prev.after, next.before)` rule) and the rest are virtual
// levels demanded by a column to the left, valued at this node's own
// `before` (there is no other node to collapse against).
// `extraHalf` is this node's own `nodeMinSize` stretch (see `extraHalfFor`).
// Only the real (non-virtual) transition gains it, and only combined with the
// previous real node's `lastExtraHalf`: together the two halves reserve
// exactly enough room for both nodes' stretched bars not to overlap. Virtual
// cross-column levels are left untouched -- there is no concrete neighbor
// above to stretch away from.
double _offsetForNode(
  _ColumnGapState state,
  NodeGap gap,
  int paddings,
  double scale,
  double extraHalf,
) {
  final realNodesAbove = state.realCount;
  final before = gap.before * scale;
  final after = gap.after * scale;
  final transitionGap = realNodesAbove > 0
      ? math.max(state.lastAfter, before) + state.lastExtraHalf + extraHalf
      : 0.0;
  final realCumOffset = state.realCumOffset + transitionGap;
  final virtualLevels = paddings - realNodesAbove;

  state
    ..realCount = realNodesAbove + 1
    ..realCumOffset = realCumOffset
    ..lastAfter = after
    ..lastExtraHalf = extraHalf;

  return realCumOffset + virtualLevels * before;
}

/// layout.ts:470 `NodePaddingMode = 'auto' | 'even'`.
typedef NodePaddingMode = SankeyNodePaddingMode;

const NodeGap _noGap = (after: 0, before: 0);

/// layout.ts:485 `addEvenPadding`.
///
/// `'even'` mode for addPadding(): lay out each column's nodes back-to-back,
/// using the *drawn* `size` of the previous node (not its `in`/`out` flow
/// total, which may be larger for a `size: 'min'` node) so the visible gaps
/// within a column come out equal. The topmost node of a column keeps its
/// existing `y` -- this is what keeps a short column anchored to the sources
/// that feed it instead of floating it to the top of the chart. Cross-column
/// padding levels (see `countCrossColumnPaddings`) do not apply here: every
/// gap in this mode is exactly `max(prev.after, next.before)`, nothing more
/// -- plus, when `nodeMinSize` stretches a bar beyond its natural `size`,
/// half of each of the two nodes' stretch (see `extraHalfFor`), so the
/// stretched bars still clear each other by the requested gap.
double _addEvenPadding(
  List<SankeyNode> nodeArray,
  Map<String, NodeGap> gaps,
  double scale,
  Map<String, double> minSizes,
) {
  var maxY = 0.0;
  double? columnX;
  SankeyNode? prev;
  NodeGap? prevGap;
  var prevExtraHalf = 0.0;

  for (final node in nodeArray) {
    final x = _nodeX(node);
    final gap = gaps[node.key] ?? _noGap;
    final extraHalf = _extraHalfFor(node, minSizes, scale);

    if (x != columnX) {
      columnX = x;
    } else if (prev != null && prevGap != null) {
      node.y =
          _nodeY(prev) +
          prev.size +
          math.max(prevGap.after, gap.before) * scale +
          prevExtraHalf +
          extraHalf;
    }

    prev = node;
    prevGap = gap;
    prevExtraHalf = extraHalf;
    final h = _stretchedSize(node, minSizes, scale);
    maxY = math.max(
      math.max(
        maxY,
        _nodeY(node) + math.max<double>(node.inFlow, node.outFlow),
      ),
      _nodeY(node) + (node.size + h) / 2,
    );
  }

  return maxY;
}

/// layout.ts:530 `addPadding`.
///
/// @return {number} maxY
double addPadding(
  List<SankeyNode> nodeArray,
  Map<String, NodeGap> gaps, [
  double scale = 1,
  NodePaddingMode mode = NodePaddingMode.auto,
  Map<String, double> minSizes = const {},
]) {
  // sort nodes by x/y, so we can iterate them by rows
  jsSort(nodeArray, _nodeByXYSize);

  if (mode == NodePaddingMode.even) {
    return _addEvenPadding(nodeArray, gaps, scale, minSizes);
  }

  var maxY = 0.0;
  final columnXs = <double, int>{};
  final grid = <_ColumnGapState>[];

  int getColIndex(double x) {
    final known = columnXs[x];
    if (known == null) {
      final index = grid.length;
      columnXs[x] = index;
      grid.add(_ColumnGapState());
      return index;
    }
    return known;
  }

  for (final node in nodeArray) {
    final colIdx = getColIndex(_nodeX(node));
    final state = grid[colIdx];
    final gap = gaps[node.key] ?? _noGap;
    final y = _nodeY(node);
    final extraHalf = _extraHalfFor(node, minSizes, scale);

    if (_truthy(y)) {
      state.yHistory.add(y);
      var paddings = state.yHistory.length;

      if (_truthy(node.inFlow)) {
        paddings = _countCrossColumnPaddings(grid, colIdx, y, paddings);
        while (state.yHistory.length < paddings) {
          state.yHistory.add(y);
        }
      }

      node.y = y + _offsetForNode(state, gap, paddings, scale, extraHalf);
    } else {
      // The topmost node in a column never receives an offset, but it still
      // needs to be recorded so the first real gap below it can collapse
      // against its `after` value (and, now, its own `nodeMinSize` stretch).
      state
        ..realCount += 1
        ..lastAfter = gap.after * scale
        ..lastExtraHalf = extraHalf;
    }

    final h = _stretchedSize(node, minSizes, scale);
    maxY = math.max(
      math.max(
        maxY,
        _nodeY(node) + math.max<double>(node.inFlow, node.outFlow),
      ),
      _nodeY(node) + (node.size + h) / 2,
    );
  }

  return maxY;
}

/// layout.ts:595 `sortFlows`.
void sortFlows(List<SankeyNode> nodeArray) {
  for (final node in nodeArray) {
    final nodeSize = node.size;
    final overlapFrom = nodeSize < node.inFlow;
    final overlapTo = nodeSize < node.outFlow;
    var addY = 0.0;
    var len = node.from.length;
    jsSort(
      node.from,
      (a, b) =>
          _nodeY(a.node) +
          a.node.outFlow / 2 -
          (_nodeY(b.node) + b.node.outFlow / 2),
    );
    for (var idx = 0; idx < node.from.length; idx++) {
      final flow = node.from[idx];
      if (overlapFrom) {
        flow.addY = (idx * (nodeSize - flow.flow)) / (len - 1);
      } else {
        flow.addY = addY;
        addY += flow.flow;
      }
    }
    addY = 0;
    len = node.to.length;
    jsSort(
      node.to,
      (a, b) =>
          _nodeY(a.node) +
          a.node.inFlow / 2 -
          (_nodeY(b.node) + b.node.inFlow / 2),
    );
    for (var idx = 0; idx < node.to.length; idx++) {
      final flow = node.to[idx];
      if (overlapTo) {
        flow.addY = (idx * (nodeSize - flow.flow)) / (len - 1);
      } else {
        flow.addY = addY;
        addY += flow.flow;
      }
    }
  }
}

/// layout.ts:642 `layout`: gives each node of [nodes] its column and its
/// position, and returns the last column and the largest position.
///
/// The named parameters are the `LayoutOptions` of layout.ts:627:
///
/// - [priority]: use node priority when sorting nodes vertically.
/// - [height]: chart height in CSS pixels.
/// - [nodePadding]: vertical before/after gap per node, in CSS pixels.
/// - [nodePaddingMode]: how nodePadding gaps are distributed within a
///   column, defaults to 'auto'.
/// - [nodeMinSize]: minimum drawn node size per node, in CSS pixels.
/// - [modeX]: layout mode in x-direction.
({double maxX, double maxY}) layout(
  Map<String, SankeyNode> nodes,
  List<SankeyDataPoint> data, {
  required bool priority,
  required double height,
  required Map<String, NodeGap> nodePadding,
  NodePaddingMode? nodePaddingMode,
  Map<String, double>? nodeMinSize,
  SankeyMode? modeX,
}) {
  final nodeArray = [...nodes.values];
  final maxX = calculateX(nodes, data, modeX ?? SankeyMode.edge);
  final maxY = priority
      ? calculateYUsingPriority(nodeArray, maxX)
      : calculateY(nodeArray, maxX);
  final scale = maxY / height;
  final maxYWithPadding = addPadding(
    nodeArray,
    nodePadding,
    scale,
    nodePaddingMode ?? NodePaddingMode.auto,
    nodeMinSize ?? const {},
  );

  sortFlows(nodeArray);

  return (maxX: maxX, maxY: maxYWithPadding);
}
