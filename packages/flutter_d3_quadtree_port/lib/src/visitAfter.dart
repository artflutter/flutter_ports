// Ported from d3-quadtree v3.0.1 src/visitAfter.js (ISC, Mike Bostock).

part of 'quadtree.dart';

// DIVERGES(d3-quadtree): adapt-quadtree-fast-forms, single-stack iterative
// post-order traversal using a pooled frame stack outside try/finally with
// O(depth) space and zero per-node heap allocations.
Quadtree<T> _quadtreeVisitAfter<T>(
  Quadtree<T> tree,
  QuadtreeVisitAfterCallback<T> callback,
) {
  final root = tree._root;
  if (root == null) return tree;

  if (root is QuadtreeLeafNode<T>) {
    callback(root, tree._x0, tree._y0, tree._x1, tree._y1);
    return tree;
  }

  final pool = tree._acquirePool();
  try {
    _visitAfterLoop<T>(
      pool,
      root,
      tree._x0,
      tree._y0,
      tree._x1,
      tree._y1,
      callback,
    );
  } finally {
    tree._releasePool(pool);
  }
  return tree;
}

void _visitAfterLoop<T>(
  _FramePool<T> pool,
  QuadtreeNode<T> root,
  double rx0,
  double ry0,
  double rx1,
  double ry1,
  QuadtreeVisitAfterCallback<T> callback,
) {
  final frames = pool.frames;
  var cap = frames.length;
  frames[0]
    ..node = root
    ..x0 = rx0
    ..y0 = ry0
    ..x1 = rx1
    ..y1 = ry1
    ..expanded = false;
  var sp = 1;
  var maxSp = 1;

  while (sp > 0) {
    final f = frames[sp - 1];
    final node = f.node!;
    final x0 = f.x0;
    final y0 = f.y0;
    final x1 = f.x1;
    final y1 = f.y1;

    if (!f.expanded && node is QuadtreeInternalNode<T>) {
      f.expanded = true;
      if (sp + 4 > cap) {
        pool.ensureCapacity(sp + 4);
        cap = frames.length;
      }
      final xm = (x0 + x1) * 0.5;
      final ym = (y0 + y1) * 0.5;
      final c3 = node.se;
      if (c3 != null) {
        frames[sp++]
          ..node = c3
          ..x0 = xm
          ..y0 = ym
          ..x1 = x1
          ..y1 = y1
          ..expanded = false;
      }
      final c2 = node.sw;
      if (c2 != null) {
        frames[sp++]
          ..node = c2
          ..x0 = x0
          ..y0 = ym
          ..x1 = xm
          ..y1 = y1
          ..expanded = false;
      }
      final c1 = node.ne;
      if (c1 != null) {
        frames[sp++]
          ..node = c1
          ..x0 = xm
          ..y0 = y0
          ..x1 = x1
          ..y1 = ym
          ..expanded = false;
      }
      final c0 = node.nw;
      if (c0 != null) {
        frames[sp++]
          ..node = c0
          ..x0 = x0
          ..y0 = y0
          ..x1 = xm
          ..y1 = ym
          ..expanded = false;
      }
      if (sp > maxSp) maxSp = sp;
    } else {
      --sp;
      callback(node, x0, y0, x1, y1);
    }
  }
  pool.lastMaxSp = maxSp;
}
