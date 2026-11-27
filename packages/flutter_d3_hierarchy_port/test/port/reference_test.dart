// Original code, not ported from d3-hierarchy: Node.js reference parity tests.

import 'dart:math' as math;

import 'package:flutter_d3_hierarchy_port/d3_hierarchy.dart';
import 'package:test/test.dart';

import 'd3_hierarchy_reference.dart';
import 'test_data.dart';

HierarchyNode<FlareCsvRow> _buildFlare() {
  final s = stratify<FlareCsvRow>(
    id: (d) => d.id,
    parentId: (d) {
      final i = d.id.lastIndexOf('.');
      return i >= 0 ? d.id.substring(0, i) : null;
    },
  );
  return s(flareCsvData)
    ..sum((d) => d.value)
    ..sort((a, b) {
      final dv = (b.value ?? 0) - (a.value ?? 0);
      return dv != 0 ? dv : a.data.id.compareTo(b.data.id);
    });
}

void _expectXY(
  HierarchyPointNode<FlareCsvRow> root,
  List<(double, double)> expected,
) {
  final nodes = root.descendants();
  expect(nodes.length, expected.length);
  for (var i = 0; i < expected.length; ++i) {
    expect(nodes[i].x, closeTo(expected[i].$1, 1e-11), reason: 'x[$i]');
    expect(nodes[i].y, closeTo(expected[i].$2, 1e-11), reason: 'y[$i]');
  }
}

void _expectRect(
  HierarchyRectangularNode<FlareCsvRow> root,
  List<(double, double, double, double)> expected,
) {
  final nodes = root.descendants();
  expect(nodes.length, expected.length);
  for (var i = 0; i < expected.length; ++i) {
    expect(nodes[i].x0, closeTo(expected[i].$1, 1e-11), reason: 'x0[$i]');
    expect(nodes[i].y0, closeTo(expected[i].$2, 1e-11), reason: 'y0[$i]');
    expect(nodes[i].x1, closeTo(expected[i].$3, 1e-11), reason: 'x1[$i]');
    expect(nodes[i].y1, closeTo(expected[i].$4, 1e-11), reason: 'y1[$i]');
  }
}

void _expectCirc(
  HierarchyCircularNode<FlareCsvRow> root,
  List<(double, double, double)> expected,
) {
  final nodes = root.descendants();
  expect(nodes.length, expected.length);
  for (var i = 0; i < expected.length; ++i) {
    expect(nodes[i].x, closeTo(expected[i].$1, 1e-9), reason: 'x[$i]');
    expect(nodes[i].y, closeTo(expected[i].$2, 1e-9), reason: 'y[$i]');
    expect(nodes[i].r, closeTo(expected[i].$3, 1e-9), reason: 'r[$i]');
  }
}

void main() {
  test('tree (size and nodeSize) matches Node.js upstream d3-hierarchy', () {
    _expectXY(tree<FlareCsvRow>(size: (960, 500))(_buildFlare()), refTreeSize);
    _expectXY(
      tree<FlareCsvRow>(nodeSize: (20, 40))(_buildFlare()),
      refTreeNodeSize,
    );
  });

  test('cluster (size and nodeSize) matches Node.js upstream d3-hierarchy', () {
    _expectXY(
      cluster<FlareCsvRow>(size: (960, 500))(_buildFlare()),
      refClusterSize,
    );
    _expectXY(
      cluster<FlareCsvRow>(nodeSize: (15, 30))(_buildFlare()),
      refClusterNodeSize,
    );
  });

  test('partition (raw and rounded) matches Node.js upstream d3-hierarchy', () {
    _expectRect(
      partition<FlareCsvRow>(size: (960, 500), padding: 1)(_buildFlare()),
      refPartition,
    );
    _expectRect(
      partition<FlareCsvRow>(size: (960, 500), padding: 1, round: true)(
        _buildFlare(),
      ),
      refPartitionRound,
    );
  });

  test('treemap (binary, sliceDice, resquarify) matches Node.js upstream', () {
    _expectRect(
      treemap<FlareCsvRow>(
        tile: treemapBinary,
        size: (960, 500),
        paddingInnerConst: 2,
        paddingOuterConst: 4,
      )(_buildFlare()),
      refTreemapBinary,
    );
    _expectRect(
      treemap<FlareCsvRow>(tile: treemapSliceDice, size: (960, 500))(
        _buildFlare(),
      ),
      refTreemapSliceDice,
    );
    final tm = treemap<FlareCsvRow>(
      tile: treemapResquarify.call,
      size: (960, 500),
    );
    final first = tm(_buildFlare());
    tm.size = (500, 960);
    final second = tm(first);
    _expectRect(second, refTreemapResquarify);
  });

  test('pack (padded and custom radius), packSiblings, and packEnclose match '
      'Node.js upstream', () {
    _expectCirc(
      pack<FlareCsvRow>(size: (960, 960), paddingConst: 3)(_buildFlare()),
      refPackPad,
    );
    _expectCirc(
      pack<FlareCsvRow>(
        size: (960, 960),
        radius: (d) => math.sqrt(d.value ?? 0) * 0.5,
        paddingConst: 2,
      )(_buildFlare()),
      refPackCustomR,
    );
    final sibs = packSiblings([
      for (final r in refSiblingRadii) PackCircle(r: r),
    ]);
    expect(sibs.length, refSiblings.length);
    for (var i = 0; i < refSiblings.length; ++i) {
      expect(sibs[i].x, closeTo(refSiblings[i].$1, 1e-11));
      expect(sibs[i].y, closeTo(refSiblings[i].$2, 1e-11));
      expect(sibs[i].r, closeTo(refSiblings[i].$3, 1e-11));
    }
    final enc = packEnclose(sibs)!;
    expect(enc.x, closeTo(refEnclose.$1, 1e-11));
    expect(enc.y, closeTo(refEnclose.$2, 1e-11));
    expect(enc.r, closeTo(refEnclose.$3, 1e-11));
  });
}
