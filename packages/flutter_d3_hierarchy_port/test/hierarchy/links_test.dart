// Ported from d3-hierarchy v3.1.2 test/hierarchy/links-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_hierarchy_port/d3_hierarchy.dart';
import 'package:test/test.dart';

final class const _Node(
  final String id, [
  @override final List<_Node>? children,
]) implements HierarchyDatum<_Node>;

void main() {
  test('node.links() returns an array of {source, target}', () {
    final root = hierarchy(
      const _Node('root', [
        _Node('a'),
        _Node('b', [_Node('ba')]),
      ]),
    );
    final a = root.children![0];
    final b = root.children![1];
    final ba = root.children![1].children![0];
    expect(root.links(), [
      (source: root, target: a),
      (source: root, target: b),
      (source: b, target: ba),
    ]);
  });
}
