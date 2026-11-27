// Original code, not ported from d3-quadtree: twin tests for faster forms.

import 'dart:math' as math;

import 'package:flutter_d3_quadtree_port/d3_quadtree.dart';
import 'package:test/test.dart';

/// Literal recursive reference implementation of d3-quadtree for twin testing
/// faster native Dart forms against exact upstream semantics.
final class _RefLeaf<T>(final T data, [var _RefLeaf<T>? next]);

final class _RefBranch<T>() {
  final List<Object?> children = List<Object?>.filled(4, null);
}

final class _RefTree<T>(
  final double Function(T) xFn,
  final double Function(T) yFn,
) {
  double x0 = double.nan;
  double y0 = double.nan;
  double x1 = double.nan;
  double y1 = double.nan;
  Object? root;

  void cover(double x, double y) {
    if (x.isNaN || y.isNaN) return;
    var rx0 = x0;
    var ry0 = y0;
    var rx1 = x1;
    var ry1 = y1;
    if (rx0.isNaN) {
      rx0 = x.isFinite ? x.floorToDouble() : x;
      rx1 = rx0 + 1;
      ry0 = y.isFinite ? y.floorToDouble() : y;
      ry1 = ry0 + 1;
    } else {
      var z = rx1 - rx0;
      if (z == 0) z = 1;
      var node = root;
      while (rx0 > x || x >= rx1 || ry0 > y || y >= ry1) {
        final i = (y < ry0 ? 2 : 0) | (x < rx0 ? 1 : 0);
        final parent = _RefBranch<T>()..children[i] = node;
        node = parent;
        z *= 2;
        switch (i) {
          case 0:
            rx1 = rx0 + z;
            ry1 = ry0 + z;
          case 1:
            rx0 = rx1 - z;
            ry1 = ry0 + z;
          case 2:
            rx1 = rx0 + z;
            ry0 = ry1 - z;
          case 3:
            rx0 = rx1 - z;
            ry0 = ry1 - z;
        }
      }
      if (root is _RefBranch<T>) root = node;
    }
    x0 = rx0;
    y0 = ry0;
    x1 = rx1;
    y1 = ry1;
  }

  void _addPoint(double x, double y, T d) {
    if (x.isNaN || y.isNaN) return;
    _RefBranch<T>? parent;
    var node = root;
    final leaf = _RefLeaf<T>(d);
    var rx0 = x0;
    var ry0 = y0;
    var rx1 = x1;
    var ry1 = y1;
    var i = 0;
    if (node == null) {
      root = leaf;
      return;
    }
    while (node is _RefBranch<T>) {
      final xm = (rx0 + rx1) / 2;
      final right = x >= xm;
      if (right) {
        rx0 = xm;
      } else {
        rx1 = xm;
      }
      final ym = (ry0 + ry1) / 2;
      final bottom = y >= ym;
      if (bottom) {
        ry0 = ym;
      } else {
        ry1 = ym;
      }
      parent = node;
      i = (bottom ? 2 : 0) | (right ? 1 : 0);
      node = node.children[i];
      if (node == null) {
        parent.children[i] = leaf;
        return;
      }
    }
    final existing = node! as _RefLeaf<T>;
    final xp = xFn(existing.data);
    final yp = yFn(existing.data);
    if (x == xp && y == yp) {
      leaf.next = existing;
      if (parent != null) {
        parent.children[i] = leaf;
      } else {
        root = leaf;
      }
      return;
    }
    int j;
    do {
      final split = _RefBranch<T>();
      if (parent != null) {
        parent.children[i] = split;
      } else {
        root = split;
      }
      parent = split;
      final xm = (rx0 + rx1) / 2;
      final right = x >= xm;
      if (right) {
        rx0 = xm;
      } else {
        rx1 = xm;
      }
      final ym = (ry0 + ry1) / 2;
      final bottom = y >= ym;
      if (bottom) {
        ry0 = ym;
      } else {
        ry1 = ym;
      }
      i = (bottom ? 2 : 0) | (right ? 1 : 0);
      j = (yp >= ym ? 2 : 0) | (xp >= xm ? 1 : 0);
    } while (i == j);
    parent.children[j] = existing;
    parent.children[i] = leaf;
  }

  void addAll(List<T> items) {
    final n = items.length;
    final xz = List<double>.filled(n, double.nan);
    final yz = List<double>.filled(n, double.nan);
    var loX = double.infinity;
    var loY = double.infinity;
    var hiX = double.negativeInfinity;
    var hiY = double.negativeInfinity;
    for (var i = 0; i < n; ++i) {
      final x = xFn(items[i]);
      final y = yFn(items[i]);
      if (x.isNaN || y.isNaN) continue;
      xz[i] = x;
      yz[i] = y;
      if (x < loX) loX = x;
      if (x > hiX) hiX = x;
      if (y < loY) loY = y;
      if (y > hiY) hiY = y;
    }
    if (loX > hiX || loY > hiY) return;
    cover(loX, loY);
    cover(hiX, hiY);
    for (var i = 0; i < n; ++i) {
      _addPoint(xz[i], yz[i], items[i]);
    }
  }

  List<(double, double, double, double)> preVisit() {
    final out = <(double, double, double, double)>[];
    void rec(Object? node, double a, double b, double c, double d) {
      if (node == null) return;
      out.add((a, b, c, d));
      if (node is _RefBranch<T>) {
        final xm = (a + c) / 2;
        final ym = (b + d) / 2;
        rec(node.children[0], a, b, xm, ym);
        rec(node.children[1], xm, b, c, ym);
        rec(node.children[2], a, ym, xm, d);
        rec(node.children[3], xm, ym, c, d);
      }
    }

    rec(root, x0, y0, x1, y1);
    return out;
  }

  List<(double, double, double, double)> postVisit() {
    final out = <(double, double, double, double)>[];
    void rec(Object? node, double a, double b, double c, double d) {
      if (node == null) return;
      if (node is _RefBranch<T>) {
        final xm = (a + c) / 2;
        final ym = (b + d) / 2;
        rec(node.children[0], a, b, xm, ym);
        rec(node.children[1], xm, b, c, ym);
        rec(node.children[2], a, ym, xm, d);
        rec(node.children[3], xm, ym, c, d);
      }
      out.add((a, b, c, d));
    }

    rec(root, x0, y0, x1, y1);
    return out;
  }

  T? bruteFind(List<T> items, double qx, double qy, [double? radius]) {
    var bestD2 = radius == null ? double.infinity : radius * radius;
    T? best;
    for (final d in items) {
      final px = xFn(d);
      final py = yFn(d);
      if (px.isNaN || py.isNaN) continue;
      final dx = qx - px;
      final dy = qy - py;
      final d2 = dx * dx + dy * dy;
      if (d2 < bestD2) {
        bestD2 = d2;
        best = d;
      }
    }
    return best;
  }
}

void main() {
  test('default-accessor fast path matches custom-accessor '
      'and literal reference', () {
    final rng = math.Random(12345);
    final pts = <(double, double)>[
      for (var i = 0; i < 600; ++i)
        (rng.nextDouble() * 1000 - 400, rng.nextDouble() * 1000 - 400),
      (double.nan, 10),
      (20, double.nan),
      (0, 0),
      (0, 0),
      (-400, -400),
      (600, 600),
    ];

    final fastTree = quadtree(pts);
    final customTree = quadtreeBy<(double, double)>(
      x: (p) => p.$1,
      y: (p) => p.$2,
      data: pts,
    );
    final refTree = _RefTree<(double, double)>((p) => p.$1, (p) => p.$2)
      ..addAll(pts);

    expect(fastTree.extent, customTree.extent);
    expect(fastTree.extent, (
      (refTree.x0, refTree.y0),
      (refTree.x1, refTree.y1),
    ));
    expect(fastTree.size(), customTree.size());
    expect(fastTree.size(), 604);
    expect(fastTree.data(), customTree.data());

    final fastPre = <(double, double, double, double)>[];
    fastTree.visit((_, x0, y0, x1, y1) {
      fastPre.add((x0, y0, x1, y1));
      return false;
    });
    expect(fastPre, refTree.preVisit());

    final fastPost = <(double, double, double, double)>[];
    fastTree.visitAfter((_, x0, y0, x1, y1) {
      fastPost.add((x0, y0, x1, y1));
    });
    expect(fastPost, refTree.postVisit());

    // Nearest-neighbor parity across 100 random queries (unbounded + bounded).
    for (var i = 0; i < 100; ++i) {
      final qx = rng.nextDouble() * 1200 - 500;
      final qy = rng.nextDouble() * 1200 - 500;
      final r = 5.0 + rng.nextDouble() * 150.0;
      final f1 = fastTree.find(qx, qy);
      final c1 = customTree.find(qx, qy);
      final b1 = refTree.bruteFind(pts, qx, qy);
      expect(f1, c1);
      expect(f1, b1);

      final f2 = fastTree.find(qx, qy, r);
      final c2 = customTree.find(qx, qy, r);
      final b2 = refTree.bruteFind(pts, qx, qy, r);
      expect(f2, c2);
      expect(f2, b2);
    }

    // Mutate via remove & re-add and verify default vs custom match.
    for (var i = 0; i < 200; ++i) {
      final p = pts[i * 2];
      fastTree.remove(p);
      customTree.remove(p);
    }
    expect(fastTree.size(), customTree.size());
    expect(fastTree.data(), customTree.data());

    for (var i = 0; i < 50; ++i) {
      final p = (
        rng.nextDouble() * 2000 - 1000,
        rng.nextDouble() * 2000 - 1000,
      );
      fastTree.add(p);
      customTree.add(p);
    }
    expect(fastTree.extent, customTree.extent);
    expect(fastTree.size(), customTree.size());
    expect(fastTree.data(), customTree.data());
  });

  test('exact distance ties in find match upstream quadrant swap order', () {
    // Symmetric points equidistant from (50, 50) in all 4 quadrants.
    const pts = <(double, double)>[(40, 40), (60, 40), (40, 60), (60, 60)];
    final q = quadtree(pts);
    // Midpoint of extent [[40, 40], [72, 72]] is (56, 56).
    // Querying at (50, 50) visits quadrant 0 (nw) first -> (40, 40).
    expect(q.find(50, 50), (40.0, 40.0));
  });
}
