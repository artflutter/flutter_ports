// Ported from d3-quadtree v3.0.1 src/add.js (ISC, Mike Bostock).

part of 'quadtree.dart';

// DIVERGES(d3-quadtree): adapt-quadtree-fast-forms, unboxed (double, double)
// default-accessor fast paths, zero-copy default addAll batching, Float64List
// custom addAll batching, and direct 4-field quadrant navigation.
Quadtree<T> _quadtreeAdd<T>(Quadtree<T> tree, T d) {
  final double x;
  final double y;
  if (tree._isDefaultPoint) {
    final p = d as (double, double);
    x = p.$1;
    y = p.$2;
  } else {
    x = tree._x(d);
    y = tree._y(d);
  }
  if (x.isNaN || y.isNaN) return tree;
  tree.cover(x, y);
  _addValidPoint(tree, x, y, d, tree._x0, tree._y0, tree._x1, tree._y1);
  return tree;
}

@pragma('vm:prefer-inline')
void _setChild<T>(
  QuadtreeInternalNode<T> parent,
  int i,
  QuadtreeNode<T> child,
) {
  switch (i) {
    case 0:
      parent.nw = child;
    case 1:
      parent.ne = child;
    case 2:
      parent.sw = child;
    default:
      parent.se = child;
  }
}

void _addValidPoint<T>(
  Quadtree<T> tree,
  double x,
  double y,
  T d,
  double initX0,
  double initY0,
  double initX1,
  double initY1,
) {
  QuadtreeInternalNode<T>? parent;
  var node = tree._root;
  final leaf = QuadtreeLeafNode<T>(d);
  var x0 = initX0;
  var y0 = initY0;
  var x1 = initX1;
  var y1 = initY1;
  var i = 0;

  // If the tree is empty, initialize the root as a leaf.
  if (node == null) {
    tree._root = leaf;
    return;
  }

  // Find the existing leaf for the new point, or add it.
  while (node is QuadtreeInternalNode<T>) {
    final xm = (x0 + x1) * 0.5;
    final ym = (y0 + y1) * 0.5;
    parent = node;
    if (y >= ym) {
      y0 = ym;
      if (x >= xm) {
        x0 = xm;
        node = parent.se;
        if (node == null) {
          parent.se = leaf;
          return;
        }
        i = 3;
      } else {
        x1 = xm;
        node = parent.sw;
        if (node == null) {
          parent.sw = leaf;
          return;
        }
        i = 2;
      }
    } else {
      y1 = ym;
      if (x >= xm) {
        x0 = xm;
        node = parent.ne;
        if (node == null) {
          parent.ne = leaf;
          return;
        }
        i = 1;
      } else {
        x1 = xm;
        node = parent.nw;
        if (node == null) {
          parent.nw = leaf;
          return;
        }
        i = 0;
      }
    }
  }

  // Is the new point exactly coincident with the existing point?
  final existingLeaf = node! as QuadtreeLeafNode<T>;
  final double xp;
  final double yp;
  if (tree._isDefaultPoint) {
    final ep = existingLeaf.data as (double, double);
    xp = ep.$1;
    yp = ep.$2;
  } else {
    xp = tree._x(existingLeaf.data);
    yp = tree._y(existingLeaf.data);
  }
  if (x == xp && y == yp) {
    leaf.next = existingLeaf;
    if (parent != null) {
      _setChild(parent, i, leaf);
    } else {
      tree._root = leaf;
    }
    return;
  }

  // Otherwise, split the leaf node until the old and new point are separated.
  int j;
  do {
    final split = QuadtreeInternalNode<T>();
    if (parent != null) {
      _setChild(parent, i, split);
    } else {
      tree._root = split;
    }
    parent = split;
    final xm = (x0 + x1) * 0.5;
    final right = x >= xm;
    if (right) {
      x0 = xm;
    } else {
      x1 = xm;
    }
    final ym = (y0 + y1) * 0.5;
    final bottom = y >= ym;
    if (bottom) {
      y0 = ym;
    } else {
      y1 = ym;
    }
    i = (bottom ? 2 : 0) | (right ? 1 : 0);
    j = (yp >= ym ? 2 : 0) | (xp >= xm ? 1 : 0);
  } while (i == j);
  _setChild(parent, j, existingLeaf);
  _setChild(parent, i, leaf);
}

void _addDefaultPoints(
  Quadtree<(double, double)> tree,
  List<(double, double)> pts,
) {
  final n = pts.length;
  var x0 = double.infinity;
  var y0 = double.infinity;
  var x1 = double.negativeInfinity;
  var y1 = double.negativeInfinity;
  var hasInvalid = false;

  for (var i = 0; i < n; ++i) {
    final (x, y) = pts[i];
    if (x.isNaN || y.isNaN) {
      hasInvalid = true;
      continue;
    }
    if (x < x0) x0 = x;
    if (x > x1) x1 = x;
    if (y < y0) y0 = y;
    if (y > y1) y1 = y;
  }

  if (x0 > x1 || y0 > y1) return;

  tree.cover(x0, y0).cover(x1, y1);
  final tx0 = tree._x0;
  final ty0 = tree._y0;
  final tx1 = tree._x1;
  final ty1 = tree._y1;

  for (var k = 0; k < n; ++k) {
    final p = pts[k];
    final x = p.$1;
    final y = p.$2;
    if (hasInvalid && (x.isNaN || y.isNaN)) continue;

    final leaf = QuadtreeLeafNode<(double, double)>(p);
    var node = tree._root;
    if (node == null) {
      tree._root = leaf;
      continue;
    }

    QuadtreeInternalNode<(double, double)>? parent;
    var rx0 = tx0;
    var ry0 = ty0;
    var rx1 = tx1;
    var ry1 = ty1;
    var i = 0;
    var inserted = false;

    while (node is QuadtreeInternalNode<(double, double)>) {
      final xm = (rx0 + rx1) * 0.5;
      final ym = (ry0 + ry1) * 0.5;
      parent = node;
      if (y >= ym) {
        ry0 = ym;
        if (x >= xm) {
          rx0 = xm;
          node = parent.se;
          if (node == null) {
            parent.se = leaf;
            inserted = true;
            break;
          }
          i = 3;
        } else {
          rx1 = xm;
          node = parent.sw;
          if (node == null) {
            parent.sw = leaf;
            inserted = true;
            break;
          }
          i = 2;
        }
      } else {
        ry1 = ym;
        if (x >= xm) {
          rx0 = xm;
          node = parent.ne;
          if (node == null) {
            parent.ne = leaf;
            inserted = true;
            break;
          }
          i = 1;
        } else {
          rx1 = xm;
          node = parent.nw;
          if (node == null) {
            parent.nw = leaf;
            inserted = true;
            break;
          }
          i = 0;
        }
      }
    }
    if (inserted) continue;

    final existingLeaf = node! as QuadtreeLeafNode<(double, double)>;
    final ep = existingLeaf.data;
    final xp = ep.$1;
    final yp = ep.$2;
    if (x == xp && y == yp) {
      leaf.next = existingLeaf;
      if (parent != null) {
        _setChild(parent, i, leaf);
      } else {
        tree._root = leaf;
      }
      continue;
    }

    int j;
    do {
      final split = QuadtreeInternalNode<(double, double)>();
      if (parent != null) {
        _setChild(parent, i, split);
      } else {
        tree._root = split;
      }
      parent = split;
      final xm = (rx0 + rx1) * 0.5;
      final right = x >= xm;
      if (right) {
        rx0 = xm;
      } else {
        rx1 = xm;
      }
      final ym = (ry0 + ry1) * 0.5;
      final bottom = y >= ym;
      if (bottom) {
        ry0 = ym;
      } else {
        ry1 = ym;
      }
      i = (bottom ? 2 : 0) | (right ? 1 : 0);
      j = (yp >= ym ? 2 : 0) | (xp >= xm ? 1 : 0);
    } while (i == j);
    _setChild(parent, j, existingLeaf);
    _setChild(parent, i, leaf);
  }
}

Quadtree<T> _quadtreeAddAll<T>(Quadtree<T> tree, Iterable<T> data) {
  final list = data is List<T> ? data : data.toList(growable: false);
  final n = list.length;
  if (n == 0) return tree;

  if (tree._isDefaultPoint &&
      tree is Quadtree<(double, double)> &&
      list is List<(double, double)>) {
    _addDefaultPoints(
      tree as Quadtree<(double, double)>,
      list as List<(double, double)>,
    );
    return tree;
  }

  final xz = Float64List(n);
  final yz = Float64List(n);
  var x0 = double.infinity;
  var y0 = double.infinity;
  var x1 = double.negativeInfinity;
  var y1 = double.negativeInfinity;
  var hasInvalid = false;

  final xFn = tree._x;
  final yFn = tree._y;
  for (var i = 0; i < n; ++i) {
    final d = list[i];
    final x = xFn(d);
    if (x.isNaN) {
      xz[i] = double.nan;
      hasInvalid = true;
      continue;
    }
    final y = yFn(d);
    if (y.isNaN) {
      xz[i] = double.nan;
      hasInvalid = true;
      continue;
    }
    xz[i] = x;
    yz[i] = y;
    if (x < x0) x0 = x;
    if (x > x1) x1 = x;
    if (y < y0) y0 = y;
    if (y > y1) y1 = y;
  }

  // If there were no (valid) points, abort.
  if (x0 > x1 || y0 > y1) return tree;

  // Expand the tree to cover the new points.
  tree.cover(x0, y0).cover(x1, y1);
  final tx0 = tree._x0;
  final ty0 = tree._y0;
  final tx1 = tree._x1;
  final ty1 = tree._y1;

  // Add the new points.
  if (hasInvalid) {
    for (var i = 0; i < n; ++i) {
      final x = xz[i];
      if (!x.isNaN) _addValidPoint(tree, x, yz[i], list[i], tx0, ty0, tx1, ty1);
    }
  } else {
    for (var i = 0; i < n; ++i) {
      _addValidPoint(tree, xz[i], yz[i], list[i], tx0, ty0, tx1, ty1);
    }
  }

  return tree;
}
