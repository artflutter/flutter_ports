// Ported from d3-quadtree v3.0.1 src/find.js (ISC, Mike Bostock).

part of 'quadtree.dart';

// DIVERGES(d3-quadtree): adapt-quadtree-fast-forms, zero-allocation iterative
// pooled-frame traversal outside try/finally, pre-push null and bounds pruning
// preserving exact upstream quadrant visit order, and unboxed (double, double)
// fast path.
T? _quadtreeFind<T>(Quadtree<T> tree, double x, double y, double? radius) {
  final root = tree._root;
  if (root == null) return null;

  var x0 = tree._x0;
  var y0 = tree._y0;
  var x3 = tree._x1;
  var y3 = tree._y1;

  // Fast path: root is a single leaf.
  if (root is QuadtreeLeafNode<T>) {
    final double px;
    final double py;
    if (tree._isDefaultPoint) {
      final p = root.data as (double, double);
      px = p.$1;
      py = p.$2;
    } else {
      px = tree._x(root.data);
      py = tree._y(root.data);
    }
    if (radius == null) return root.data;
    if (radius <= 0) return null;
    final dx = x - px;
    final dy = y - py;
    return dx * dx + dy * dy < radius * radius ? root.data : null;
  }

  final rootX0 = x0;
  final rootY0 = y0;
  final rootX1 = x3;
  final rootY1 = y3;

  double r2;
  if (radius == null) {
    r2 = double.infinity;
  } else {
    x0 = x - radius;
    y0 = y - radius;
    x3 = x + radius;
    y3 = y + radius;
    r2 = radius * radius;
  }

  if (rootX0 > x3 || rootY0 > y3 || rootX1 < x0 || rootY1 < y0) return null;

  final pool = tree._acquirePool();
  if (tree._isDefaultPoint) {
    // Default (double, double) accessors cannot throw; skip try/finally.
    final result = _findLoop<T>(
      pool,
      root,
      x,
      y,
      x0,
      y0,
      x3,
      y3,
      r2,
      rootX0,
      rootY0,
      rootX1,
      rootY1,
      true,
      tree._x,
      tree._y,
    );
    tree._releasePool(pool);
    return result;
  }

  try {
    return _findLoop<T>(
      pool,
      root,
      x,
      y,
      x0,
      y0,
      x3,
      y3,
      r2,
      rootX0,
      rootY0,
      rootX1,
      rootY1,
      false,
      tree._x,
      tree._y,
    );
  } finally {
    tree._releasePool(pool);
  }
}

T? _findLoop<T>(
  _FramePool<T> pool,
  QuadtreeNode<T> root,
  double x,
  double y,
  double initX0,
  double initY0,
  double initX3,
  double initY3,
  double initR2,
  double rootX0,
  double rootY0,
  double rootX1,
  double rootY1,
  bool isDefault,
  QuadtreeAccessor<T> xFn,
  QuadtreeAccessor<T> yFn,
) {
  var x0 = initX0;
  var y0 = initY0;
  var x3 = initX3;
  var y3 = initY3;
  var r2 = initR2;
  T? data;
  final frames = pool.frames;
  var cap = frames.length;
  frames[0]
    ..node = root
    ..x0 = rootX0
    ..y0 = rootY0
    ..x1 = rootX1
    ..y1 = rootY1;
  var sp = 1;
  var maxSp = 1;

  while (sp > 0) {
    final f = frames[--sp];
    final x1 = f.x0;
    final y1 = f.y0;
    final x2 = f.x1;
    final y2 = f.y1;

    // Stop searching if this quadrant can't contain a closer node.
    if (x1 > x3 || y1 > y3 || x2 < x0 || y2 < y0) continue;

    switch (f.node!) {
      case final QuadtreeInternalNode<T> branch:
        if (sp + 4 > cap) {
          pool.ensureCapacity(sp + 4);
          cap = frames.length;
        }
        final xm = (x1 + x2) * 0.5;
        final ym = (y1 + y2) * 0.5;

        final c0 = branch.nw;
        final c1 = branch.ne;
        final c2 = branch.sw;
        final c3 = branch.se;

        // Preserve exact upstream push + swap order while skipping null and
        // already-pruned quadrants:
        //   i == 0 (nw): push 3, 2, 1, 0
        //   i == 1 (ne): push 3, 2, 0, 1
        //   i == 2 (sw): push 3, 0, 1, 2
        //   i == 3 (se): push 0, 2, 1, 3
        final right = x >= xm;
        final bottom = y >= ym;
        if (bottom) {
          if (right) {
            if (c0 != null && x1 <= x3 && y1 <= y3 && xm >= x0 && ym >= y0) {
              frames[sp++]
                ..node = c0
                ..x0 = x1
                ..y0 = y1
                ..x1 = xm
                ..y1 = ym;
            }
            if (c2 != null && x1 <= x3 && ym <= y3 && xm >= x0 && y2 >= y0) {
              frames[sp++]
                ..node = c2
                ..x0 = x1
                ..y0 = ym
                ..x1 = xm
                ..y1 = y2;
            }
            if (c1 != null && xm <= x3 && y1 <= y3 && x2 >= x0 && ym >= y0) {
              frames[sp++]
                ..node = c1
                ..x0 = xm
                ..y0 = y1
                ..x1 = x2
                ..y1 = ym;
            }
            if (c3 != null && xm <= x3 && ym <= y3 && x2 >= x0 && y2 >= y0) {
              frames[sp++]
                ..node = c3
                ..x0 = xm
                ..y0 = ym
                ..x1 = x2
                ..y1 = y2;
            }
          } else {
            if (c3 != null && xm <= x3 && ym <= y3 && x2 >= x0 && y2 >= y0) {
              frames[sp++]
                ..node = c3
                ..x0 = xm
                ..y0 = ym
                ..x1 = x2
                ..y1 = y2;
            }
            if (c0 != null && x1 <= x3 && y1 <= y3 && xm >= x0 && ym >= y0) {
              frames[sp++]
                ..node = c0
                ..x0 = x1
                ..y0 = y1
                ..x1 = xm
                ..y1 = ym;
            }
            if (c1 != null && xm <= x3 && y1 <= y3 && x2 >= x0 && ym >= y0) {
              frames[sp++]
                ..node = c1
                ..x0 = xm
                ..y0 = y1
                ..x1 = x2
                ..y1 = ym;
            }
            if (c2 != null && x1 <= x3 && ym <= y3 && xm >= x0 && y2 >= y0) {
              frames[sp++]
                ..node = c2
                ..x0 = x1
                ..y0 = ym
                ..x1 = xm
                ..y1 = y2;
            }
          }
        } else {
          if (right) {
            if (c3 != null && xm <= x3 && ym <= y3 && x2 >= x0 && y2 >= y0) {
              frames[sp++]
                ..node = c3
                ..x0 = xm
                ..y0 = ym
                ..x1 = x2
                ..y1 = y2;
            }
            if (c2 != null && x1 <= x3 && ym <= y3 && xm >= x0 && y2 >= y0) {
              frames[sp++]
                ..node = c2
                ..x0 = x1
                ..y0 = ym
                ..x1 = xm
                ..y1 = y2;
            }
            if (c0 != null && x1 <= x3 && y1 <= y3 && xm >= x0 && ym >= y0) {
              frames[sp++]
                ..node = c0
                ..x0 = x1
                ..y0 = y1
                ..x1 = xm
                ..y1 = ym;
            }
            if (c1 != null && xm <= x3 && y1 <= y3 && x2 >= x0 && ym >= y0) {
              frames[sp++]
                ..node = c1
                ..x0 = xm
                ..y0 = y1
                ..x1 = x2
                ..y1 = ym;
            }
          } else {
            if (c3 != null && xm <= x3 && ym <= y3 && x2 >= x0 && y2 >= y0) {
              frames[sp++]
                ..node = c3
                ..x0 = xm
                ..y0 = ym
                ..x1 = x2
                ..y1 = y2;
            }
            if (c2 != null && x1 <= x3 && ym <= y3 && xm >= x0 && y2 >= y0) {
              frames[sp++]
                ..node = c2
                ..x0 = x1
                ..y0 = ym
                ..x1 = xm
                ..y1 = y2;
            }
            if (c1 != null && xm <= x3 && y1 <= y3 && x2 >= x0 && ym >= y0) {
              frames[sp++]
                ..node = c1
                ..x0 = xm
                ..y0 = y1
                ..x1 = x2
                ..y1 = ym;
            }
            if (c0 != null && x1 <= x3 && y1 <= y3 && xm >= x0 && ym >= y0) {
              frames[sp++]
                ..node = c0
                ..x0 = x1
                ..y0 = y1
                ..x1 = xm
                ..y1 = ym;
            }
          }
        }
        if (sp > maxSp) maxSp = sp;

      case final QuadtreeLeafNode<T> leaf:
        // Visit this point. (Visiting coincident points isn't necessary!)
        final dVal = leaf.data;
        final double dx;
        final double dy;
        if (isDefault) {
          final p = dVal as (double, double);
          dx = x - p.$1;
          dy = y - p.$2;
        } else {
          dx = x - xFn(dVal);
          dy = y - yFn(dVal);
        }
        final d2 = dx * dx + dy * dy;
        if (d2 < r2) {
          r2 = d2;
          final d = math.sqrt(d2);
          x0 = x - d;
          y0 = y - d;
          x3 = x + d;
          y3 = y + d;
          data = dVal;
        }
    }
  }

  pool.lastMaxSp = maxSp;
  return data;
}
