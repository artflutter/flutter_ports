// Original code, not ported from d3-hierarchy: runnable package example.

// The example prints its results.
// ignore_for_file: avoid_print

import 'package:flutter_d3_hierarchy_port/flutter_d3_hierarchy_port.dart';

final class const _Node(
  final String name, {
  final double? size,
  @override final List<_Node>? children,
}) implements HierarchyDatum<_Node>;

void main() {
  const data = _Node(
    'root',
    children: [
      _Node(
        'analytics',
        children: [_Node('cluster', size: 3938), _Node('graph', size: 3812)],
      ),
      _Node(
        'vis',
        children: [_Node('layout', size: 6714), _Node('scale', size: 4200)],
      ),
    ],
  );

  // 1. Squarified Treemap
  final tm =
      treemap<_Node>(size: (400, 200), paddingInnerConst: 2, round: true)(
        hierarchy(data)
          ..sum((d) => d.size)
          ..sort((a, b) => (b.value ?? 0) - (a.value ?? 0)),
      );
  for (final leaf in tm.leaves()) {
    print(
      'treemap ${leaf.data.name}: '
      '[${leaf.x0}, ${leaf.y0}, ${leaf.x1}, ${leaf.y1}]',
    );
  }

  // 2. Circle Packing
  final packed = pack<_Node>(size: (200, 200), paddingConst: 3)(
    hierarchy(data)..sum((d) => d.size),
  );
  print('pack root radius: ${packed.r.toStringAsFixed(1)}');

  // 3. Reingold-Tilford Tidy Tree
  final laidOut = tree<_Node>(size: (200, 100))(hierarchy(data));
  print('tree links: ${laidOut.links().length}');
}
