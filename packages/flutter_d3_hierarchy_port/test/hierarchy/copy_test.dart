// Ported from d3-hierarchy v3.1.2 test/hierarchy/copy-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_hierarchy_port/d3_hierarchy.dart';
import 'package:test/test.dart';

final class const _Node(
  final String id, [
  @override final List<_Node>? children,
]) implements HierarchyDatum<_Node>;

void main() {
  test('node.copy() copies values', () {
    final root = hierarchy(
      const _Node('root', [
        _Node('a'),
        _Node('b', [_Node('ba')]),
      ]),
    ).count();
    expect(root.copy().value, 2);
  });
}
