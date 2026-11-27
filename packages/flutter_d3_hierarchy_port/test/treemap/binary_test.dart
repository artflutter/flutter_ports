// Ported from d3-hierarchy v3.1.2 test/treemap/binary-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_hierarchy_port/d3_hierarchy.dart';
import 'package:test/test.dart';

import 'round.dart';

final class const _Node({
  final double? value,
  @override final List<_Node>? children,
}) implements HierarchyDatum<_Node>;

void main() {
  test(
    'treemapBinary(parent, x0, y0, x1, y1) generates a binary treemap layout',
    () {
      final root = HierarchyRectangularNode<int>(
        0,
        value: 24,
        children: [
          for (final v in [6, 6, 4, 3, 2, 2, 1])
            HierarchyRectangularNode<int>(v, value: v.toDouble()),
        ],
      );
      treemapBinary(root, 0, 0, 6, 4);
      expect(root.children!.map(roundRect).toList(), [
        (x0: 0.00, y0: 0.00, x1: 3.00, y1: 2.00),
        (x0: 0.00, y0: 2.00, x1: 3.00, y1: 4.00),
        (x0: 3.00, y0: 0.00, x1: 4.71, y1: 2.33),
        (x0: 4.71, y0: 0.00, x1: 6.00, y1: 2.33),
        (x0: 3.00, y0: 2.33, x1: 4.20, y1: 4.00),
        (x0: 4.20, y0: 2.33, x1: 5.40, y1: 4.00),
        (x0: 5.40, y0: 2.33, x1: 6.00, y1: 4.00),
      ]);
    },
  );

  test('treemapBinary does not break on 0-sized inputs', () {
    const data = _Node(
      children: [_Node(value: 0), _Node(value: 0), _Node(value: 1)],
    );
    final root = hierarchy(data).sum((d) => d.value);
    final treemapper = treemap<_Node>(tile: treemapBinary);
    final laid = treemapper(root);
    final a = laid.leaves().map((d) => [d.x0, d.x1, d.y0, d.y1]).toList();
    expect(a, [
      [0.0, 1.0, 0.0, 0.0],
      [1.0, 1.0, 0.0, 0.0],
      [0.0, 1.0, 0.0, 1.0],
    ]);
  });
}
