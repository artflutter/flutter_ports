// Ported from chartjs-chart-sankey v0.19.1 src/lib/core.test.ts (MIT, Jukka Kurkela).
@TestOn('vm')
library;

import 'package:flutter_chartjs_chart_sankey_port/src/lib/core.dart';
import 'package:flutter_chartjs_chart_sankey_port/src/types.dart';
import 'package:test/test.dart';

/// The fields of [node] that the upstream object literal of a node has,
/// with the upstream names `in` and `out`.
Map<String, Object?> _nodeObject(SankeyNode node) => {
  'from': [for (final flow in node.from) _flowObject(flow)],
  'in': node.inFlow,
  'key': node.key,
  'out': node.outFlow,
  'size': node.size,
  'to': [for (final flow in node.to) _flowObject(flow)],
};

/// The fields of [flow], an item of the `from` or `to` of a node.
Map<String, Object?> _flowObject(FromToElement flow) => {
  'addY': flow.addY,
  'flow': flow.flow,
  'index': flow.index,
  'key': flow.key,
  'node': flow.node,
};

/// The fields of [node] that `toEqual` requires to be `undefined`: the
/// upstream expectation does not list them.
({bool column, double? priority, double? x, double? y}) _otherFields(
  SankeyNode node,
) => (column: node.column, priority: node.priority, x: node.x, y: node.y);

const ({bool column, double? priority, double? x, double? y}) _allUndefined = (
  column: false,
  priority: null,
  x: null,
  y: null,
);

/// `expect.objectContaining({ in, out })`.
({double inFlow, double outFlow}) _inOut(SankeyNode? node) =>
    (inFlow: node!.inFlow, outFlow: node.outFlow);

void main() {
  group('lib/core', () {
    group('buildNodesFromData', () {
      test('it should build nodes from simple flows', () {
        const data = [SankeyDataPoint(flow: 1, from: 'a', to: 'b')];

        final nodes = buildNodesFromData(data);

        expect(nodes.length, 2);
        expect([...nodes.keys], ['a', 'b']);
        expect(_nodeObject(nodes['a']!), {
          'from': <Object?>[],
          'in': 0.0,
          'key': 'a',
          'out': 1.0,
          'size': 1.0,
          'to': [
            {
              'addY': 0.0,
              'flow': 1.0,
              'index': 0,
              'key': 'b',
              'node': isA<SankeyNode>(), // circular
            },
          ],
        });
        expect(_otherFields(nodes['a']!), _allUndefined);
        expect(_nodeObject(nodes['b']!), {
          'from': [
            {
              'addY': 0.0,
              'flow': 1.0,
              'index': 0,
              'key': 'a',
              'node': isA<SankeyNode>(), // circular
            },
          ],
          'in': 1.0,
          'key': 'b',
          'out': 0.0,
          'size': 1.0,
          'to': <Object?>[],
        });
        expect(_otherFields(nodes['b']!), _allUndefined);
      });

      test('should build nodes from comples flows', () {
        const data = [
          SankeyDataPoint(flow: 11.606, from: 'Coal imports', to: 'Coal'),
          SankeyDataPoint(flow: 63.965, from: 'Coal reserves', to: 'Coal'),
          SankeyDataPoint(flow: 75.571, from: 'Coal', to: 'Solid'),
          SankeyDataPoint(flow: 280.322, from: 'Bio-conversion', to: 'Solid'),
          SankeyDataPoint(flow: 35, from: 'Biomass imports', to: 'Solid'),
          SankeyDataPoint(flow: 56.587, from: 'Other waste', to: 'Solid'),
          SankeyDataPoint(flow: 0.882, from: 'Solid', to: 'Agriculture'),
        ];

        final nodes = buildNodesFromData(data);

        expect(nodes.length, 8);

        expect(_inOut(nodes['Coal imports']), (inFlow: 0.0, outFlow: 11.606));
        expect(_inOut(nodes['Coal reserves']), (inFlow: 0.0, outFlow: 63.965));
        expect(_inOut(nodes['Coal']), (inFlow: 75.571, outFlow: 75.571));
        expect(_inOut(nodes['Bio-conversion']), (
          inFlow: 0.0,
          outFlow: 280.322,
        ));
        expect(_inOut(nodes['Biomass imports']), (inFlow: 0.0, outFlow: 35.0));
        expect(_inOut(nodes['Other waste']), (inFlow: 0.0, outFlow: 56.587));
        expect(_inOut(nodes['Solid']), (inFlow: 447.48, outFlow: 0.882));
        expect(_inOut(nodes['Agriculture']), (inFlow: 0.882, outFlow: 0.0));
      });

      test('it should support circular flows', () {
        const data = [SankeyDataPoint(flow: 123.5, from: 'abba', to: 'abba')];

        final nodes = buildNodesFromData(data);

        expect(nodes.length, 1);
        expect(_nodeObject(nodes['abba']!), {
          'from': [isA<Map<String, Object?>>()], // circular
          'in': 123.5,
          'key': 'abba',
          'out': 123.5,
          'size': 123.5,
          'to': [isA<Map<String, Object?>>()], // circular
        });
      });

      test('it should include data with no flow', () {
        const data = [
          SankeyDataPoint(flow: 0, from: 'one', to: 'other'),
          SankeyDataPoint(flow: 2, from: 'one', to: 'third'),
        ];

        final nodes = buildNodesFromData(data);

        expect(nodes.length, 3);
        expect([...nodes.keys], ['one', 'other', 'third']);
      });

      test('it should sort flows', () {
        const data = [
          SankeyDataPoint(flow: 2, from: 'a1', to: 'b'),
          SankeyDataPoint(flow: 3, from: 'a2', to: 'b'),
          SankeyDataPoint(flow: 1, from: 'a3', to: 'b'),
          SankeyDataPoint(flow: 1, from: 'a4', to: 'b'),
          SankeyDataPoint(flow: 3, from: 'b', to: 'c1'),
          SankeyDataPoint(flow: 1, from: 'b', to: 'c2'),
          SankeyDataPoint(flow: 2, from: 'b', to: 'c3'),
          SankeyDataPoint(flow: 3, from: 'b', to: 'c4'),
        ];

        final nodes = buildNodesFromData(data);

        expect(nodes.length, 9);

        final b = nodes['b'];
        if (b == null) {
          throw StateError('Expected node "b" to exist');
        }

        expect(
          [
            for (final FromToElement(:flow, :index, :key) in b.from)
              (flow: flow, index: index, key: key),
          ],
          [
            (flow: 3.0, index: 1, key: 'a2'),
            (flow: 2.0, index: 0, key: 'a1'),
            (flow: 1.0, index: 2, key: 'a3'),
            (flow: 1.0, index: 3, key: 'a4'),
          ],
        );

        expect(
          [
            for (final FromToElement(:flow, :index, :key) in b.to)
              (flow: flow, index: index, key: key),
          ],
          [
            (flow: 3.0, index: 4, key: 'c1'),
            (flow: 3.0, index: 7, key: 'c4'),
            (flow: 2.0, index: 6, key: 'c3'),
            (flow: 1.0, index: 5, key: 'c2'),
          ],
        );
      });
    });
  });
}
