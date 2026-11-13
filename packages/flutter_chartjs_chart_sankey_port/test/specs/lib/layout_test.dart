// Ported from chartjs-chart-sankey v0.19.1 src/lib/layout.test.ts (MIT, Jukka Kurkela).
@TestOn('vm')
library;

import 'dart:math' as math;

import 'package:flutter_chartjs_chart_sankey_port/src/lib/core.dart';
import 'package:flutter_chartjs_chart_sankey_port/src/lib/layout.dart';
import 'package:flutter_chartjs_chart_sankey_port/src/types.dart';
import 'package:test/test.dart';

// layout.test.ts:13-31 `formatValue`, `formatDescription` and `each`: a
// table of cases, one test for each. Here each table is a list of records
// and a loop. The `%p` of a description is the first value of a case, the
// name of the case, in the quotes of `JSON.stringify`.

/// One case of a `calculateX` table: `[name, data, mode, expected, maxX]`.
typedef _ColumnCase = ({
  String name,
  List<SankeyDataPoint> data,
  SankeyModeX mode,
  List<({String key, double? x})> expected,
  double maxX,
});

/// The body of each `calculateX` table.
void _expectColumns(_ColumnCase testCase) {
  final (name: _, :data, :mode, :expected, :maxX) = testCase;
  final nodes = buildNodesFromData(data);
  expect(calculateX(nodes, data, mode), maxX);
  expect([
    for (final SankeyNode(:key, :x) in nodes.values) (key: key, x: x),
  ], expected);
}

SankeyNode _getNode(Map<String, SankeyNode> nodes, String key) {
  final node = nodes[key];
  if (node == null) {
    throw StateError('Test setup error: node "$key" not found');
  }
  return node;
}

/// The object literal `{ in, key, out, size, x, y }` of an `addPadding`
/// case, as a node.
SankeyNode _node({
  required double inFlow,
  required String key,
  required double outFlow,
  required double size,
  required double x,
  required double y,
}) => SankeyNode(key)
  ..inFlow = inFlow
  ..outFlow = outFlow
  ..size = size
  ..x = x
  ..y = y;

/// `{ ...node }`: a copy of a node that [_node] made.
SankeyNode _copy(SankeyNode node) => _node(
  inFlow: node.inFlow,
  key: node.key,
  outFlow: node.outFlow,
  size: node.size,
  x: node.x!,
  y: node.y!,
);

/// `toBeCloseTo(expected, numDigits)` of Vitest: a difference below
/// `10 ** -numDigits / 2`.
Matcher _toBeCloseTo(double expected, int numDigits) => predicate<double>(
  // js-ok: double operands, as Math.pow.
  (received) => (expected - received).abs() < math.pow(10.0, -numDigits) / 2,
  // js-ok: the text of a test failure.
  'a number close to $expected, to $numDigits digits',
);

void main() {
  group('lib/layout', () {
    group('returnsToNearerColumn', () {
      SankeyNode nodeAt(double x) => SankeyNode('node')..x = x;

      test('returns false without a following node', () {
        expect(returnsToNearerColumn(nodeAt(2)), false);
      });

      test('returns false for a node in the same column', () {
        expect(returnsToNearerColumn(nodeAt(2), nodeAt(2)), false);
      });

      test('returns false for a node in a farther column', () {
        expect(returnsToNearerColumn(nodeAt(2), nodeAt(3)), false);
      });

      test('returns true for a node in a nearer column', () {
        expect(returnsToNearerColumn(nodeAt(2), nodeAt(1)), true);
      });
    });

    test('does not offset an intermediate node by unrelated inputs of a '
        'direct target', () {
      const data = [
        SankeyDataPoint(flow: 80, from: 'Visits', to: 'Product views'),
        SankeyDataPoint(flow: 20, from: 'Visits', to: 'Exit'),
        SankeyDataPoint(flow: 32, from: 'Product views', to: 'Cart'),
        SankeyDataPoint(flow: 48, from: 'Product views', to: 'Exit'),
        SankeyDataPoint(flow: 18, from: 'Cart', to: 'Purchase'),
        SankeyDataPoint(flow: 14, from: 'Cart', to: 'Abandoned'),
      ];
      final nodes = buildNodesFromData(data);
      final nodePadding = <String, NodeGap>{
        for (final key in nodes.keys) key: (after: 0, before: 0),
      };

      layout(
        nodes,
        data,
        height: 100,
        modeX: SankeyModeX.edge,
        nodePadding: nodePadding,
        nodePaddingMode: SankeyNodePaddingMode.auto,
        priority: false,
      );

      expect(nodes['Product views']?.y, 20);
    });

    test('keeps the priority layout offset through empty columns', () {
      const data = [
        SankeyDataPoint(flow: 25, from: 'Coal', to: 'Generation'),
        SankeyDataPoint(flow: 18, from: 'Wind', to: 'Generation'),
        SankeyDataPoint(flow: 12, from: 'Solar', to: 'Generation'),
        SankeyDataPoint(flow: 20, from: 'Generation', to: 'Homes'),
        SankeyDataPoint(flow: 28, from: 'Generation', to: 'Industry'),
        SankeyDataPoint(flow: 7, from: 'Generation', to: 'Storage'),
      ];
      final nodes = buildNodesFromData(
        data,
        column: <String, double>{'Homes': 4, 'Storage': 3},
        priority: <String, double>{},
      );

      calculateX(nodes, data, SankeyModeX.edge);
      calculateYUsingPriority([...nodes.values], 4);

      expect(nodes['Storage']?.y, 48);
    });

    group('calculateX', () {
      test('should work with empty chart', () {
        expect(calculateX({}, [], SankeyModeX.edge), 0);
        expect(calculateX({}, [], SankeyModeX.even), 0);
      });
      const columnCases = <_ColumnCase>[
        (
          name: '1x2',
          data: [SankeyDataPoint(flow: 1, from: 'a', to: 'b')],
          mode: SankeyModeX.edge,
          expected: [(key: 'a', x: 0), (key: 'b', x: 1)],
          maxX: 1,
        ),
        (
          name: '1x3',
          data: [
            SankeyDataPoint(flow: 2, from: 'a', to: 'b'),
            SankeyDataPoint(flow: 1, from: 'b', to: 'c'),
          ],
          mode: SankeyModeX.edge,
          expected: [(key: 'a', x: 0), (key: 'b', x: 1), (key: 'c', x: 2)],
          maxX: 2,
        ),
        (
          name: '2x2',
          data: [
            SankeyDataPoint(flow: 1, from: 'a', to: 'b'),
            SankeyDataPoint(flow: 1, from: 'c', to: 'd'),
          ],
          mode: SankeyModeX.edge,
          expected: [
            (key: 'a', x: 0),
            (key: 'b', x: 1),
            (key: 'c', x: 0),
            (key: 'd', x: 1),
          ],
          maxX: 1,
        ),
        (
          name: '2x3 edge',
          data: [
            SankeyDataPoint(flow: 1, from: 'a', to: 'b'),
            SankeyDataPoint(flow: 1, from: 'c', to: 'd'),
            SankeyDataPoint(flow: 1, from: 'd', to: 'e'),
          ],
          mode: SankeyModeX.edge,
          expected: [
            (key: 'a', x: 0),
            (key: 'b', x: 2),
            (key: 'c', x: 0),
            (key: 'd', x: 1),
            (key: 'e', x: 2),
          ],
          maxX: 2,
        ),
        (
          name: '2x3 even',
          data: [
            SankeyDataPoint(flow: 1, from: 'a', to: 'b'),
            SankeyDataPoint(flow: 1, from: 'c', to: 'd'),
            SankeyDataPoint(flow: 1, from: 'd', to: 'e'),
          ],
          mode: SankeyModeX.even,
          expected: [
            (key: 'a', x: 0),
            (key: 'b', x: 1),
            (key: 'c', x: 0),
            (key: 'd', x: 1),
            (key: 'e', x: 2),
          ],
          maxX: 2,
        ),
      ];
      for (final testCase in columnCases) {
        test('should map nodes to columns: "${testCase.name}"', () {
          _expectColumns(testCase);
        });
      }

      const simpleCircularCases = <_ColumnCase>[
        (
          name: '1x1 circular',
          data: [SankeyDataPoint(flow: 1, from: 'a', to: 'a')],
          mode: SankeyModeX.even,
          expected: [(key: 'a', x: 0)],
          maxX: 0,
        ),
        (
          name: '2x1 circular',
          data: [
            SankeyDataPoint(flow: 1, from: 'a', to: 'a'),
            SankeyDataPoint(flow: 1, from: 'b', to: 'b'),
          ],
          mode: SankeyModeX.even,
          expected: [(key: 'a', x: 0), (key: 'b', x: 0)],
          maxX: 0,
        ),
        (
          name: '1x2 circular',
          data: [
            SankeyDataPoint(flow: 1, from: 'a', to: 'b'),
            SankeyDataPoint(flow: 1, from: 'b', to: 'b'),
          ],
          mode: SankeyModeX.even,
          expected: [(key: 'a', x: 0), (key: 'b', x: 1)],
          maxX: 1,
        ),

        (
          name: '2x2 circular',
          data: [
            SankeyDataPoint(flow: 1, from: 'a', to: 'b'),
            SankeyDataPoint(flow: 1, from: 'c', to: 'd'),
            SankeyDataPoint(flow: 1, from: 'd', to: 'd'),
          ],
          mode: SankeyModeX.even,
          expected: [
            (key: 'a', x: 0),
            (key: 'b', x: 1),
            (key: 'c', x: 0),
            (key: 'd', x: 1),
          ],
          maxX: 1,
        ),
      ];
      for (final testCase in simpleCircularCases) {
        test('should map nodes with simple circular flows to columns: '
            '"${testCase.name}"', () {
          _expectColumns(testCase);
        });
      }

      const circularCases = <_ColumnCase>[
        (
          name: '1x2 circular variant',
          data: [
            SankeyDataPoint(flow: 1, from: 'a', to: 'b'),
            SankeyDataPoint(flow: 1, from: 'b', to: 'a'),
          ],
          mode: SankeyModeX.even,
          expected: [(key: 'a', x: 0), (key: 'b', x: 1)],
          maxX: 1,
        ),
        (
          name: '1x3 circular variant',
          data: [
            SankeyDataPoint(flow: 1, from: 'a', to: 'b'),
            SankeyDataPoint(flow: 1, from: 'b', to: 'c'),
            SankeyDataPoint(flow: 1, from: 'c', to: 'a'),
          ],
          mode: SankeyModeX.even,
          expected: [(key: 'a', x: 0), (key: 'b', x: 1), (key: 'c', x: 2)],
          maxX: 2,
        ),
        (
          name: '3x1,2x1 circular',
          data: [
            SankeyDataPoint(flow: 1, from: 'a', to: 'b'),
            SankeyDataPoint(flow: 1, from: 'b', to: 'c'),
            SankeyDataPoint(flow: 1, from: 'd', to: 'b'),
            SankeyDataPoint(flow: 1, from: 'd', to: 'e'),
            SankeyDataPoint(flow: 1, from: 'e', to: 'c'),
          ],
          mode: SankeyModeX.even,
          expected: [
            (key: 'a', x: 0),
            (key: 'b', x: 1),
            (key: 'c', x: 2),
            (key: 'd', x: 0),
            (key: 'e', x: 1),
          ],
          maxX: 2,
        ),
        (
          name: '3x1,2x1 circular variant',
          data: [
            SankeyDataPoint(flow: 1, from: 'a', to: 'b'),
            SankeyDataPoint(flow: 1, from: 'b', to: 'c'),
            SankeyDataPoint(flow: 1, from: 'd', to: 'b'),
            SankeyDataPoint(flow: 1, from: 'e', to: 'c'),
            SankeyDataPoint(flow: 1, from: 'd', to: 'e'),
          ],
          mode: SankeyModeX.even,
          expected: [
            (key: 'a', x: 0),
            (key: 'b', x: 1),
            (key: 'c', x: 2),
            (key: 'd', x: 0),
            (key: 'e', x: 1),
          ],
          maxX: 2,
        ),
        (
          name: 'complex circular',
          data: [
            SankeyDataPoint(flow: 1, from: 'a', to: 'b'),
            SankeyDataPoint(flow: 1, from: 'b', to: 'b'),
            SankeyDataPoint(flow: 1, from: 'b', to: 'c'),
            SankeyDataPoint(flow: 1, from: 'b', to: 'd'),
            SankeyDataPoint(flow: 1, from: 'c', to: 'c'),
            SankeyDataPoint(flow: 1, from: 'd', to: 'e'),
            SankeyDataPoint(flow: 1, from: 'e', to: 'b'),
          ],
          mode: SankeyModeX.edge,
          expected: [
            (key: 'a', x: 0),
            (key: 'b', x: 1),
            (key: 'c', x: 2),
            (key: 'd', x: 2),
            (key: 'e', x: 3),
          ],
          maxX: 3,
        ),
        (
          name: 'complex circular 2',
          data: [
            SankeyDataPoint(flow: 1, from: 'a', to: 'b'),
            SankeyDataPoint(flow: 1, from: 'b', to: 'c'),
            SankeyDataPoint(flow: 1, from: 'b', to: 'd'),
            SankeyDataPoint(flow: 1, from: 'c', to: 'd'),
            SankeyDataPoint(flow: 1, from: 'd', to: 'e'),
            SankeyDataPoint(flow: 1, from: 'f', to: 'c'),
          ],
          mode: SankeyModeX.edge,
          expected: [
            (key: 'a', x: 0),
            (key: 'b', x: 1),
            (key: 'c', x: 2),
            (key: 'd', x: 3),
            (key: 'e', x: 4),
            (key: 'f', x: 0),
          ],
          maxX: 4,
        ),
      ];
      for (final testCase in circularCases) {
        test('should map nodes with circular flows to columns: '
            '"${testCase.name}"', () {
          _expectColumns(testCase);
        });
      }

      const multipleEntryCases = <_ColumnCase>[
        (
          name: '2x2 circular variant',
          data: [
            SankeyDataPoint(flow: 1, from: 'a', to: 'b'),
            SankeyDataPoint(flow: 1, from: 'c', to: 'd'),
            SankeyDataPoint(flow: 1, from: 'd', to: 'c'),
          ],
          mode: SankeyModeX.even,
          expected: [
            (key: 'a', x: 0),
            (key: 'b', x: 1),
            (key: 'c', x: 0),
            (key: 'd', x: 1),
          ],
          maxX: 1,
        ),
      ];
      for (final testCase in multipleEntryCases) {
        test('should map nodes with multiple entries and circular flows to '
            'columns: "${testCase.name}"', () {
          _expectColumns(testCase);
        });
      }
    });
    group('nodeCount', () {
      // Diamond (A -> B, A -> C, B -> D, C -> D) with a cycle back into the
      // diamond (D -> E, E -> B). B and C both flow into D, and D eventually
      // flows back to B, so a naive traversal must dedupe nodes to terminate
      // and to avoid double counting.
      const diamondWithCycle = [
        SankeyDataPoint(flow: 1, from: 'A', to: 'B'),
        SankeyDataPoint(flow: 1, from: 'A', to: 'C'),
        SankeyDataPoint(flow: 1, from: 'B', to: 'D'),
        SankeyDataPoint(flow: 1, from: 'C', to: 'D'),
        SankeyDataPoint(flow: 1, from: 'D', to: 'E'),
        SankeyDataPoint(flow: 1, from: 'E', to: 'B'),
      ];

      test('counts unique downstream nodes across a diamond and a cycle', () {
        final nodes = buildNodesFromData(diamondWithCycle);

        // A -> B -> D -> E -> (B, already counted) and A -> C -> (D, already
        // counted)
        // Unique downstream nodes of A via 'to': B, C, D, E => edges counted:
        // B.to(1) + D.to(1) + E.to(1) + C.to(1) = 4
        expect(nodeCount(_getNode(nodes, 'A').to, FlowDirection.to), 4);
        // B -> D -> E -> (B, already counted): edges counted: D.to(1) + E.to(1)
        // + B.to(1) = 3
        expect(nodeCount(_getNode(nodes, 'B').to, FlowDirection.to), 3);
        // C -> D -> E -> B -> (D, already counted): edges counted: D.to(1) +
        // E.to(1) + B.to(1) = 3
        expect(nodeCount(_getNode(nodes, 'C').to, FlowDirection.to), 3);
      });

      test('returns the same result for the same list no matter how many '
          'unrelated nodeCount calls ran in between', () {
        // Regression test for a counter that used to be shared across all
        // nodeCount calls (module-level, wrapping at 101) to mark visited
        // nodes. In a real layout, sorting a node's `from`/`to` list calls
        // nodeCount twice per comparison, so a chart with a few dozen nodes
        // easily produces more than 101 calls in a single layout pass. When the
        // counter wrapped back to a value still stamped on a node from an
        // earlier, unrelated call, that node was wrongly treated as "already
        // visited" and dropped from the count.
        final nodes = buildNodesFromData([
          ...diamondWithCycle,
          // Unrelated filler edges that share no nodes with the diamond/cycle
          // above. Calling nodeCount on these between the assertions below
          // advances the old module-level counter without ever touching B, C, D
          // or E.
          for (var i = 0; i < 40; i++)
            SankeyDataPoint(flow: 1, from: 'F$i', to: 'G$i'),
        ]);
        final b = _getNode(nodes, 'B');
        final c = _getNode(nodes, 'C');
        final fillers = [for (var i = 0; i < 40; i++) _getNode(nodes, 'F$i')];

        void runFillers(int count) {
          for (var i = 0; i < count; i++) {
            // js-ok: both operands are not negative.
            nodeCount(fillers[i % fillers.length].to, FlowDirection.to);
          }
        }

        final bResults = <int>[];
        final cResults = <int>[];
        // Two full rounds of 100 unrelated calls around each probe: comfortably
        // more than 200 nodeCount invocations in total, guaranteed to wrap the
        // old 101-value counter at least once between probes of the same list.
        for (var round = 0; round < 2; round++) {
          bResults.add(nodeCount(b.to, FlowDirection.to));
          runFillers(100);
          cResults.add(nodeCount(c.to, FlowDirection.to));
          runFillers(100);
        }

        expect(bResults, [3, 3]);
        expect(cResults, [3, 3]);
      });
    });

    group('addPadding', () {
      // Builds a gaps map that reproduces the old single-number `padding`
      // behavior: before === after === p for every node, so adjacent gaps
      // collapse to exactly p (max(p, p) === p), matching the pre-per-node-gap
      // algorithm byte for byte.
      Map<String, NodeGap> uniformGaps(List<String> keys, double p) => {
        for (final key in keys) key: (after: p, before: p),
      };

      test('when there is a single row of nodes, it should not add any '
          'paddings', () {
        final nodes = [
          _node(inFlow: 0, key: 'a', outFlow: 8, size: 8, x: 0, y: 0),
          _node(inFlow: 8, key: 'b', outFlow: 10, size: 10, x: 1, y: 0),
          _node(inFlow: 10, key: 'c', outFlow: 0, size: 10, x: 2, y: 0),
        ];

        // maxY equals max flow
        expect(addPadding(nodes, uniformGaps(['a', 'b', 'c'], 5)), 10);

        // no changes
        expect([for (final node in nodes) node.y], [0, 0, 0]);
      });

      test('when there are multiple rows of nodes, it should add paddings '
          '(uniform gaps match the pre-per-node-gap result)', () {
        final nodes = [
          _node(inFlow: 0, key: 'a', outFlow: 8, size: 8, x: 0, y: 0),
          _node(inFlow: 0, key: 'b', outFlow: 5, size: 5, x: 0, y: 8),
          _node(inFlow: 0, key: 'c', outFlow: 5, size: 5, x: 0, y: 13),
          _node(inFlow: 13, key: 'd', outFlow: 0, size: 13, x: 1, y: 0),
          _node(inFlow: 5, key: 'e', outFlow: 0, size: 5, x: 1, y: 13),
        ];

        // 18 + 2x padding, same as when addPadding took a single `padding: 1`
        // number
        expect(
          addPadding(nodes, uniformGaps(['a', 'b', 'c', 'd', 'e'], 1)),
          20,
        );

        // padding added to 2 nodes @x=0 and 1 node @x=1 -- identical y series
        // to the pre-per-node-gap implementation
        expect([for (final node in nodes) node.y], [0, 9, 15, 0, 15]);
      });

      test('it should consider previous columns, when node has input '
          '(uniform gaps match the pre-per-node-gap result)', () {
        final nodes = [
          _node(inFlow: 0, key: 'a0', outFlow: 1, size: 1, x: 0, y: 0),
          _node(inFlow: 0, key: 'a1', outFlow: 1, size: 1, x: 0, y: 1),
          _node(inFlow: 0, key: 'a2', outFlow: 1, size: 1, x: 0, y: 2),
          _node(inFlow: 0, key: 'a3', outFlow: 1, size: 1, x: 0, y: 3),

          _node(inFlow: 0, key: 'b0', outFlow: 1, size: 1, x: 1, y: 4),

          _node(inFlow: 3, key: 'c0', outFlow: 3, size: 3, x: 2, y: 0),
          _node(inFlow: 2, key: 'c1', outFlow: 2, size: 2, x: 2, y: 2),

          _node(inFlow: 1, key: 'd0', outFlow: 0, size: 1, x: 3, y: 0),
          _node(inFlow: 1, key: 'd1', outFlow: 0, size: 1, x: 3, y: 1),
          _node(inFlow: 1, key: 'd2', outFlow: 0, size: 1, x: 3, y: 2),
          _node(inFlow: 1, key: 'd3', outFlow: 0, size: 1, x: 3, y: 3),
          _node(inFlow: 1, key: 'd4', outFlow: 0, size: 1, x: 3, y: 4),
        ];
        final keys = [for (final node in nodes) node.key];

        // 5 + 4x padding, same as when addPadding took a single `padding: 1`
        // number
        expect(addPadding(nodes, uniformGaps(keys, 1)), 9);

        // identical y series to the pre-per-node-gap implementation
        expect(
          [
            for (final node in nodes)
              if (node.x == 0) node.y,
          ],
          [0, 2, 4, 6],
        );
        expect(
          [
            for (final node in nodes)
              if (node.x == 1) node.y,
          ],
          [5],
        );
        expect(
          [
            for (final node in nodes)
              if (node.x == 2) node.y,
          ],
          [0, 4],
        );
        expect(
          [
            for (final node in nodes)
              if (node.x == 3) node.y,
          ],
          [0, 2, 4, 6, 8],
        );
      });

      test('collapses adjacent gaps like CSS margins, using the larger of '
          'prev.after and next.before', () {
        final nodes = [
          _node(inFlow: 0, key: 'top', outFlow: 1, size: 1, x: 0, y: 0),
          _node(inFlow: 0, key: 'bottom', outFlow: 1, size: 1, x: 0, y: 5),
        ];
        const gaps = <String, NodeGap>{
          'top': (after: 20, before: 0),
          'bottom': (after: 0, before: 6),
        };

        addPadding(nodes, gaps);

        // max(20, 6) === 20, not 20 + 6 === 26
        expect(nodes[1].y, 25);
      });

      test('uses a node’s own before value for virtual cross-column levels '
          'it does not share a real neighbor for', () {
        // Same shape as the "previous columns" case above, but c1's own column
        // has only 1 real node above it (c0) while its inputs (column x=0)
        // demand 2 levels of padding. The extra (virtual) level must be valued
        // using c1's own `before`, not a value borrowed from c0 or from column
        // x=0.
        final nodes = [
          _node(inFlow: 0, key: 'a0', outFlow: 1, size: 1, x: 0, y: 0),
          _node(inFlow: 0, key: 'a1', outFlow: 1, size: 1, x: 0, y: 1),
          _node(inFlow: 0, key: 'a2', outFlow: 1, size: 1, x: 0, y: 2),
          _node(inFlow: 0, key: 'a3', outFlow: 1, size: 1, x: 0, y: 3),

          _node(inFlow: 3, key: 'c0', outFlow: 3, size: 3, x: 2, y: 0),
          _node(inFlow: 2, key: 'c1', outFlow: 2, size: 2, x: 2, y: 2),
        ];
        const gaps = <String, NodeGap>{
          'a0': (after: 1, before: 1),
          'a1': (after: 1, before: 1),
          'a2': (after: 1, before: 1),
          'a3': (after: 1, before: 1),
          'c0': (after: 1, before: 1),
          // c1 has no real neighbor in its own column (only c0 sits above it,
          // and the transition into it is m=1). Its 1 virtual level (k=2, m=1)
          // must use c1's own before, here deliberately different from 1.
          'c1': (after: 1, before: 100),
        };

        addPadding(nodes, gaps);

        // real part: max(c0.after=1, c1.before=100) = 100; virtual part: 1*100
        expect(nodes.firstWhere((node) => node.key == 'c1').y, 2 + 100 + 100);
      });

      group('even mode', () {
        test('gives every gap in a column the exact requested size, '
            'regardless of node size', () {
          // Three differently sized nodes stacked in the same column. In
          // 'even' mode the gap between adjacent nodes never depends on
          // either node's size -- only on the requested gap itself.
          final nodes = [
            _node(inFlow: 0, key: 'a', outFlow: 5, size: 5, x: 0, y: 0),
            _node(inFlow: 0, key: 'b', outFlow: 3, size: 3, x: 0, y: 1),
            _node(inFlow: 0, key: 'c', outFlow: 8, size: 8, x: 0, y: 2),
          ];

          addPadding(
            nodes,
            uniformGaps(['a', 'b', 'c'], 4),
            1,
            SankeyNodePaddingMode.even,
          );

          // topmost node keeps its y; each of the following nodes sits
          // exactly size(prev) + gap below the previous one
          expect([for (final node in nodes) node.y], [0, 9, 16]);
          expect(nodes[1].y! - (nodes[0].y! + nodes[0].size), 4);
          expect(nodes[2].y! - (nodes[1].y! + nodes[1].size), 4);
        });

        test('uses max(prev.after, next.before) for each gap, same '
            'collapsing rule as auto mode', () {
          final nodes = [
            _node(inFlow: 0, key: 'a', outFlow: 4, size: 4, x: 0, y: 0),
            _node(inFlow: 0, key: 'b', outFlow: 2, size: 2, x: 0, y: 1),
            _node(inFlow: 0, key: 'c', outFlow: 1, size: 1, x: 0, y: 2),
          ];
          const gaps = <String, NodeGap>{
            'a': (after: 2, before: 0),
            'b': (after: 6, before: 10),
            'c': (after: 0, before: 3),
          };

          addPadding(nodes, gaps, 1, SankeyNodePaddingMode.even);

          expect(nodes[0].y, 0);
          // 0 + a.size(4) + max(a.after=2, b.before=10) = 14
          expect(nodes[1].y, 14);
          // 14 + b.size(2) + max(b.after=6, c.before=3) = 22
          expect(nodes[2].y, 22);
        });

        test('gives a node exactly one gap, where auto inflates it with '
            'virtual cross-column levels', () {
          // Same shape as the cross-column test above: c1's own column has
          // only c0 as a real neighbor, but its inputs (column x=0) demand 2
          // padding levels. 'auto' honors that cross-column requirement and
          // adds a second, virtual gap; 'even' ignores cross-column levels
          // entirely and gives c1 a single real gap below c0.
          final nodes = [
            _node(inFlow: 0, key: 'a0', outFlow: 1, size: 1, x: 0, y: 0),
            _node(inFlow: 0, key: 'a1', outFlow: 1, size: 1, x: 0, y: 1),
            _node(inFlow: 0, key: 'a2', outFlow: 1, size: 1, x: 0, y: 2),
            _node(inFlow: 0, key: 'a3', outFlow: 1, size: 1, x: 0, y: 3),

            _node(inFlow: 3, key: 'c0', outFlow: 3, size: 3, x: 2, y: 0),
            _node(inFlow: 2, key: 'c1', outFlow: 2, size: 2, x: 2, y: 2),
          ];
          const gaps = <String, NodeGap>{
            'a0': (after: 1, before: 1),
            'a1': (after: 1, before: 1),
            'a2': (after: 1, before: 1),
            'a3': (after: 1, before: 1),
            'c0': (after: 1, before: 1),
            'c1': (after: 1, before: 100),
          };

          final autoNodes = [for (final node in nodes) _copy(node)];
          addPadding(autoNodes, gaps);
          expect(autoNodes.firstWhere((node) => node.key == 'c1').y, 202);

          final evenNodes = [for (final node in nodes) _copy(node)];
          addPadding(evenNodes, gaps, 1, SankeyNodePaddingMode.even);
          // c0.y(0) + c0.size(3) + max(c0.after=1, c1.before=100) = 103 -- a
          // single gap, not the two levels 'auto' adds above.
          expect(evenNodes.firstWhere((node) => node.key == 'c1').y, 103);
        });
      });

      group('nodeMinSize', () {
        // The drawn bar is stretched (see getNodeRect in controller.ts) to
        // max(node.size, nodeMinSize * scale), symmetrically around the node's
        // real position -- half the stretch above/left, half below/right.
        // These helpers recompute that visual span from the same inputs
        // addPadding takes, so a test can assert on it without duplicating
        // production code.
        double visualBottom(SankeyNode node, Map<String, double> minSizes) {
          final minSizeUnits = minSizes[node.key] ?? 0;
          final height = math.max(node.size, minSizeUnits);
          return (node.y ?? 0) + (node.size + height) / 2;
        }

        double visualTop(SankeyNode node, Map<String, double> minSizes) {
          final minSizeUnits = minSizes[node.key] ?? 0;
          final height = math.max(node.size, minSizeUnits);
          return (node.y ?? 0) + (node.size - height) / 2;
        }

        test('auto mode: reserves enough room that a minSize far larger '
            'than either node keeps the requested gap between the stretched '
            'bars', () {
          final nodes = [
            _node(inFlow: 0, key: 'a', outFlow: 2, size: 2, x: 0, y: 0),
            _node(inFlow: 0, key: 'b', outFlow: 3, size: 3, x: 0, y: 2),
          ];
          // Both minimums are far bigger than either node's natural size (2, 3)
          // or their sum (5).
          const minSizes = <String, double>{'a': 20, 'b': 20};

          addPadding(
            nodes,
            uniformGaps(['a', 'b'], 4),
            1,
            SankeyNodePaddingMode.auto,
            minSizes,
          );

          final gapBetweenBars =
              visualTop(nodes[1], minSizes) - visualBottom(nodes[0], minSizes);
          expect(gapBetweenBars, greaterThanOrEqualTo(4));
          // The stretch is accounted for exactly, not just conservatively.
          expect(gapBetweenBars, _toBeCloseTo(4, 9));
        });

        test('auto mode: grows maxY to cover the stretched bar', () {
          final withoutMinSize = [
            _node(inFlow: 0, key: 'a', outFlow: 5, size: 5, x: 0, y: 0),
          ];
          final withMinSize = [
            _node(inFlow: 0, key: 'a', outFlow: 5, size: 5, x: 0, y: 0),
          ];

          final baseMaxY = addPadding(withoutMinSize, uniformGaps(['a'], 0));
          final stretchedMaxY = addPadding(
            withMinSize,
            uniformGaps(['a'], 0),
            1,
            SankeyNodePaddingMode.auto,
            {'a': 50},
          );

          expect(baseMaxY, 5);
          // Visual bottom of the stretched bar: y + (size + minSize) / 2
          expect(stretchedMaxY, _toBeCloseTo(27.5, 9));
          expect(stretchedMaxY, greaterThan(baseMaxY));
        });

        test('minSize: 0 (the default, an empty map) changes nothing', () {
          final withDefault = [
            _node(inFlow: 0, key: 'a', outFlow: 8, size: 8, x: 0, y: 0),
            _node(inFlow: 0, key: 'b', outFlow: 5, size: 5, x: 0, y: 8),
          ];
          final withExplicitZero = [
            for (final node in withDefault) _copy(node),
          ];

          final maxYDefault = addPadding(
            withDefault,
            uniformGaps(['a', 'b'], 5),
          );
          final maxYZero = addPadding(
            withExplicitZero,
            uniformGaps(['a', 'b'], 5),
            1,
            SankeyNodePaddingMode.auto,
            {'a': 0, 'b': 0},
          );

          expect(maxYZero, maxYDefault);
          expect(
            [for (final node in withExplicitZero) node.y],
            [for (final node in withDefault) node.y],
          );
        });

        test('even mode: keeps the requested gap between stretched bars the '
            'same way auto mode does', () {
          final nodes = [
            _node(inFlow: 0, key: 'a', outFlow: 5, size: 5, x: 0, y: 0),
            _node(inFlow: 0, key: 'b', outFlow: 3, size: 3, x: 0, y: 1),
          ];
          const minSizes = <String, double>{'a': 20, 'b': 20};

          final maxY = addPadding(
            nodes,
            uniformGaps(['a', 'b'], 4),
            1,
            SankeyNodePaddingMode.even,
            minSizes,
          );

          final gapBetweenBars =
              visualTop(nodes[1], minSizes) - visualBottom(nodes[0], minSizes);
          expect(gapBetweenBars, _toBeCloseTo(4, 9));

          // maxY covers b's stretched bar, not just its natural in/out.
          expect(maxY, _toBeCloseTo(visualBottom(nodes[1], minSizes), 9));
          expect(
            maxY,
            greaterThan(
              nodes[1].y! + math.max<double>(nodes[1].inFlow, nodes[1].outFlow),
            ),
          );
        });
      });
    });
  });
}
