// Original code, not ported from chartjs-chart-sankey: the layout node counts.
@TestOn('vm')
library;

import 'package:flutter_chartjs_chart_sankey_port/src/lib/core.dart';
import 'package:flutter_chartjs_chart_sankey_port/src/lib/layout.dart';
import 'package:flutter_chartjs_chart_sankey_port/src/types.dart';
import 'package:test/test.dart';

/// A graph with a cycle through a node with 34 flows.
///
/// The root `r` flows to `hub`, which has 34 flows to the nodes `c<i>`: the
/// largest one to `c0`, the smallest one to `c33`. The node `c<i>` has
/// `i % 5 + 1` flows to `d`. `c0` also flows back to `hub`. `c33` also flows
/// to `e`, which has 150 flows to `f`.
List<SankeyDataPoint> _cycleData() => [
  const SankeyDataPoint(from: 'r', to: 'hub', flow: 1000),
  for (var i = 0; i < 34; i++)
    SankeyDataPoint(
      from: 'hub',
      to: 'c$i',
      flow: i == 0
          ? 20
          : i == 33
          ? 5
          : 10.0 + i % 3,
    ),
  for (var i = 0; i < 34; i++)
    for (var k = 0; k <= i % 5; k++)
      SankeyDataPoint(from: 'c$i', to: 'd', flow: 1),
  const SankeyDataPoint(from: 'c0', to: 'hub', flow: 1),
  const SankeyDataPoint(from: 'c33', to: 'e', flow: 1),
  for (var k = 0; k < 150; k++)
    const SankeyDataPoint(from: 'e', to: 'f', flow: 1),
];

/// The column and the position of each node of [_cycleData] after `layout`
/// of `src/lib/layout.ts` at the pin, with the height 480, the gap 10 before
/// and after each node and the other options absent. The values come from
/// Node.js v24.22.1 on arm64, the reference engine of Chart.js ADR 0045:
/// `buildNodesFromData(data, {})`, then `layout(nodes, data, {priority:
/// false, height: 480, nodePadding})`, which gives `{maxX: 4, maxY:
/// 1721.25}`.
const Map<String, (double, double)> _cyclePositions = {
  'r': (0, 0),
  'hub': (1, 0),
  'c0': (2, 1701.25),
  'c1': (2, 260),
  'c2': (2, 419.25),
  'c3': (2, 777),
  'c4': (2, 906),
  'c5': (2, 0),
  'c6': (2, 356.75),
  'c7': (2, 519),
  'c8': (2, 646),
  'c9': (2, 970.5),
  'c10': (2, 66.5),
  'c11': (2, 193.5),
  'c12': (2, 583.5),
  'c13': (2, 712.5),
  'c14': (2, 839.5),
  'c15': (2, 131),
  'c16': (2, 292.25),
  'c17': (2, 452.5),
  'c18': (2, 808.25),
  'c19': (2, 938.25),
  'c20': (2, 33.25),
  'c21': (2, 388),
  'c22': (2, 551.25),
  'c23': (2, 679.25),
  'c24': (2, 1001.75),
  'c25': (2, 98.75),
  'c26': (2, 226.75),
  'c27': (2, 614.75),
  'c28': (2, 744.75),
  'c29': (2, 872.75),
  'c30': (2, 162.25),
  'c31': (2, 324.5),
  'c32': (2, 485.75),
  'c33': (2, 1033),
  'd': (4, 0),
  'e': (3, 1034.0000009999999),
  'f': (4, 1034.000002),
};

void main() {
  // Row adapt-sankey-node-count-memo of doc/differences.md.
  group('the node counts of one layout', () {
    test('a sort of 32 or more flows of a node of a cycle', () {
      // A JavaScript comparator reads each flow list as it is before the
      // sort. The Dart sort of 32 or more items moves the items of its list
      // between two comparisons. `c0` reaches `hub` again, so a count of
      // `c0` during the sort of the flows of `hub` reads that list. The
      // layout takes each count before the sort.
      final data = _cycleData();
      final nodes = buildNodesFromData(data);
      final result = layout(
        nodes,
        data,
        priority: false,
        height: 480,
        nodePadding: {
          for (final key in nodes.keys) key: (after: 10, before: 10),
        },
      );

      expect(result, (maxX: 4.0, maxY: 1721.25));
      expect(nodes.keys, _cyclePositions.keys);
      for (final node in nodes.values) {
        final (x, y) = _cyclePositions[node.key]!;
        expect(node.x, x, reason: 'x of ${node.key}');
        expect(node.y, closeTo(y, 1e-9), reason: 'y of ${node.key}');
      }
    });

    test('the count of a node does not change with the order of a list', () {
      final data = _cycleData();
      final nodes = buildNodesFromData(data);
      final hub = nodes['hub']!;
      final count = nodeCount(hub.to, FlowDirection.to);
      final reversed = hub.to.reversed.toList();

      expect(nodeCount(reversed, FlowDirection.to), count);
    });
  });
}
