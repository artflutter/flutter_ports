// Ported from d3-hierarchy v3.1.2 test/hierarchy/each-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_hierarchy_port/d3_hierarchy.dart';
import 'package:test/test.dart';

final class const _Node(
  final String id, [
  @override final List<_Node>? children,
]) implements HierarchyDatum<_Node>;

const _tree = _Node('root', [
  _Node('a', [_Node('ab')]),
  _Node('b', [_Node('ba')]),
]);

void main() {
  test('node.each() traverses a hierarchy in breadth-first order', () {
    final root = hierarchy(_tree);
    final a = <String>[];
    root.each((d) => a.add(d.data.id));
    expect(a, ['root', 'a', 'b', 'ab', 'ba']);
  });

  test('node.eachBefore() traverses a hierarchy in pre-order traversal', () {
    final root = hierarchy(_tree);
    final a = <String>[];
    root.eachBefore((d) => a.add(d.data.id));
    expect(a, ['root', 'a', 'ab', 'b', 'ba']);
  });

  test('node.eachAfter() traverses a hierarchy in post-order traversal', () {
    final root = hierarchy(_tree);
    final a = <String>[];
    root.eachAfter((d) => a.add(d.data.id));
    expect(a, ['ab', 'a', 'ba', 'b', 'root']);
  });

  test('a hierarchy is an iterable equivalent to *node*.each()', () {
    final root = hierarchy(_tree);
    final a = [for (final d in root) d.data.id];
    expect(a, ['root', 'a', 'b', 'ab', 'ba']);
  });
}
