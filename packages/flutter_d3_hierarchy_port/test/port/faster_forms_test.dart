// Original code, not ported from d3-hierarchy: twin tests for faster forms.

import 'package:flutter_d3_hierarchy_port/d3_hierarchy.dart';
import 'package:test/test.dart';

import 'test_data.dart';

HierarchyNode<FlareCsvRow> _buildFlare() {
  final s = stratify<FlareCsvRow>(
    id: (d) => d.id,
    parentId: (d) {
      final i = d.id.lastIndexOf('.');
      return i >= 0 ? d.id.substring(0, i) : null;
    },
  );
  return s(flareCsvData);
}

List<HierarchyNode<T>> _refBfs<T>(HierarchyNode<T> root) {
  final result = <HierarchyNode<T>>[];
  var next = <HierarchyNode<T>>[root];
  while (next.isNotEmpty) {
    final current = next.reversed.toList();
    next = <HierarchyNode<T>>[];
    while (current.isNotEmpty) {
      final node = current.removeLast();
      result.add(node);
      final ch = node.children;
      if (ch != null) next.addAll(ch);
    }
  }
  return result;
}

List<HierarchyNode<T>> _refPreOrder<T>(HierarchyNode<T> root) {
  final out = <HierarchyNode<T>>[];
  void visit(HierarchyNode<T> n) {
    out.add(n);
    n.children?.forEach(visit);
  }

  visit(root);
  return out;
}

List<HierarchyNode<T>> _refPostOrder<T>(HierarchyNode<T> root) {
  final out = <HierarchyNode<T>>[];
  void visit(HierarchyNode<T> n) {
    n.children?.forEach(visit);
    out.add(n);
  }

  visit(root);
  return out;
}

void main() {
  test(
    'BFS, pre-order, post-order, leaves, ancestors, path match reference',
    () {
      final root = _buildFlare();

      final bfs = _refBfs(root);
      expect(root.descendants(), bfs);
      final eachOut = <HierarchyNode<FlareCsvRow>>[];
      root.each(eachOut.add);
      expect(eachOut, bfs);

      final pre = _refPreOrder(root);
      final beforeOut = <HierarchyNode<FlareCsvRow>>[];
      root.eachBefore(beforeOut.add);
      expect(beforeOut, pre);

      final post = _refPostOrder(root);
      final afterOut = <HierarchyNode<FlareCsvRow>>[];
      root.eachAfter(afterOut.add);
      expect(afterOut, post);

      expect(root.leaves(), [
        for (final n in pre)
          if (n.children == null) n,
      ]);

      final leafA = root.leaves().first;
      final leafB = root.leaves().last;
      final p = leafA.path(leafB);
      expect(p.first, leafA);
      expect(p.last, leafB);
      expect(p.contains(root), isTrue);
      expect(leafA.ancestors().last, root);
    },
  );

  test('sum and count match literal recursive post-order evaluation', () {
    final r1 = _buildFlare()..sum((d) => d.value);
    final r2 = _buildFlare();
    double sumRec(HierarchyNode<FlareCsvRow> n) {
      var s = n.data.value ?? 0.0;
      final ch = n.children;
      if (ch != null) {
        for (final c in ch) {
          s += sumRec(c);
        }
      }
      n.value = s;
      return s;
    }

    sumRec(r2);
    final d1 = r1.descendants();
    final d2 = r2.descendants();
    for (var i = 0; i < d1.length; ++i) {
      expect(d1[i].value, d2[i].value);
    }

    final c1 = _buildFlare()..count();
    expect(c1.value, c1.leaves().length.toDouble());
  });

  test('sort preserves ES2019 stability for n > 32 children', () {
    final items = List<({int key, int order})>.generate(
      100,
      (i) => (key: i % 5, order: i),
    );
    final root = HierarchyNode<({int key, int order})>(
      (key: -1, order: -1),
      children: [
        for (final item in items) HierarchyNode<({int key, int order})>(item),
      ],
    )..sort((a, b) => a.data.key - b.data.key);

    final sorted = root.children!;
    for (var i = 1; i < sorted.length; ++i) {
      final prev = sorted[i - 1].data;
      final curr = sorted[i].data;
      expect(prev.key, lessThanOrEqualTo(curr.key));
      if (prev.key == curr.key) {
        expect(prev.order, lessThan(curr.order));
      }
    }
  });

  test('in-place re-layout on typed layout nodes matches fresh layout', () {
    final base = _buildFlare()
      ..sum((d) => d.value)
      ..sort((a, b) => (b.value ?? 0) - (a.value ?? 0));

    final tm = treemap<FlareCsvRow>(size: (800, 400), paddingInnerConst: 2);
    final r1 = tm(base);
    final r2 = tm(r1);
    expect(identical(r1, r2), isTrue);
    final rFresh = tm(base.copy());
    final d1 = r2.descendants();
    final d2 = rFresh.descendants();
    for (var i = 0; i < d1.length; ++i) {
      expect(d1[i].x0, closeTo(d2[i].x0, 1e-12));
      expect(d1[i].y0, closeTo(d2[i].y0, 1e-12));
      expect(d1[i].x1, closeTo(d2[i].x1, 1e-12));
      expect(d1[i].y1, closeTo(d2[i].y1, 1e-12));
    }

    final pk = pack<FlareCsvRow>(size: (500, 500), paddingConst: 2);
    final p1 = pk(base);
    final p2 = pk(p1);
    expect(identical(p1, p2), isTrue);

    final tr = tree<FlareCsvRow>(size: (500, 400));
    final t1 = tr(base);
    final t2 = tr(t1);
    expect(identical(t1, t2), isTrue);
  });
}
