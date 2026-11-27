// Ported from delaunator v5.1.0 index.js (ISC, Mapbox).

/// Port of `index.js` of delaunator 5.1.0: fast sweep-hull 2D Delaunay
/// triangulation over flat [Float64List] coordinates.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_d3_delaunay_port/src/robust_predicates/orient2d.dart';

const double _epsilon = 2.220446049250313e-16; // 2^-52
final Uint32List _edgeStack = Uint32List(512);

/// `index.js:8` `Delaunator`: computes the 2D Delaunay triangulation of flat
/// coordinates `[x0, y0, x1, y1, ...]`.
// DIVERGES(d3-delaunay): adapt-delaunay-typed-api, typed-data arrays.
// DIVERGES(d3-delaunay): adapt-delaunay-fast-forms, modulo-free inner loops.
class Delaunator(
  /// Flat `[x0, y0, x1, y1, ...]` coordinate array.
  final Float64List coords,
) {
  /// `index.js:39` `constructor(coords)`: constructs a Delaunay triangulation
  /// over flat [coords] `[x0, y0, x1, y1, ...]`.
  this {
    final n = coords.length >> 1;

    final maxTriangles = math.max(2 * n - 5, 0);
    _triangles = Uint32List(maxTriangles * 3);
    _halfedges = Int32List(maxTriangles * 3);

    _hashSize = math.sqrt(n).ceil();
    _hullPrev = Uint32List(n);
    _hullNext = Uint32List(n);
    _hullTri = Uint32List(n);
    _hullHash = Int32List(_hashSize);

    _ids = Uint32List(n);
    _dists = Float64List(n);

    trianglesLen = 0;
    _hullStart = 0;

    hull = _triangles;
    triangles = _triangles;
    halfedges = _halfedges;

    update();
  }

  /// Constructs a triangulation from `(double, double)` coordinate pairs.
  factory fromCoords(List<(double, double)> points) {
    final n = points.length;
    final coords = Float64List(n * 2);
    for (var i = 0; i < n; i++) {
      final (x, y) = points[i];
      coords[i << 1] = x;
      coords[(i << 1) | 1] = y;
    }
    return Delaunator(coords);
  }

  /// `index.js:20` `Delaunator.from(points, getX, getY)`: constructs a
  /// triangulation from an iterable of custom typed points [T].
  static Delaunator from<T>(
    List<T> points, {
    required double Function(T) getX,
    required double Function(T) getY,
  }) {
    final n = points.length;
    final coords = Float64List(n * 2);
    for (var i = 0; i < n; i++) {
      final p = points[i];
      coords[i << 1] = getX(p);
      coords[(i << 1) | 1] = getY(p);
    }
    return Delaunator(coords);
  }

  late final Uint32List _triangles;
  late final Int32List _halfedges;

  late final int _hashSize;
  late final Uint32List _hullPrev;
  late final Uint32List _hullNext;
  late final Uint32List _hullTri;
  late final Int32List _hullHash;

  late final Uint32List _ids;
  late final Float64List _dists;

  /// Number of entries populated in [triangles] and [halfedges].
  late int trianglesLen;
  late int _hullStart;

  /// Counter-clockwise convex hull point indices.
  late Uint32List hull;

  /// Triangle vertex indices (triples in counter-clockwise order).
  late Uint32List triangles;

  /// Twin half-edge indices (`-1` for convex hull boundary edges).
  late Int32List halfedges;

  /// `index.js:85` `update()`: recomputes the triangulation in place after
  /// [coords] have been modified.
  void update() {
    final coords = this.coords;
    final hullPrev = _hullPrev;
    final hullNext = _hullNext;
    final hullTri = _hullTri;
    final hullHash = _hullHash;
    final ids = _ids;
    final dists = _dists;
    final hashSize = _hashSize;
    final n = coords.length >> 1;

    if (n == 0) {
      hull = Uint32List(0);
      triangles = Uint32List(0);
      halfedges = Int32List(0);
      trianglesLen = 0;
      return;
    }

    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = double.negativeInfinity;
    var maxY = double.negativeInfinity;

    for (var i = 0; i < n; i++) {
      final i2 = i << 1;
      final x = coords[i2];
      final y = coords[i2 | 1];
      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;
      ids[i] = i;
    }
    final cx = (minX + maxX) * 0.5;
    final cy = (minY + maxY) * 0.5;

    var i0 = 0;
    var i1 = 0;
    var i2 = 0;

    // pick a seed point close to the center
    var minDist = double.infinity;
    for (var i = 0; i < n; i++) {
      final k = i << 1;
      final dx = cx - coords[k];
      final dy = cy - coords[k | 1];
      final d = dx * dx + dy * dy;
      if (d < minDist) {
        i0 = i;
        minDist = d;
      }
    }
    final i0x = coords[i0 << 1];
    final i0y = coords[(i0 << 1) | 1];

    // find the point closest to the seed
    minDist = double.infinity;
    for (var i = 0; i < n; i++) {
      if (i == i0) continue;
      final k = i << 1;
      final dx = i0x - coords[k];
      final dy = i0y - coords[k | 1];
      final d = dx * dx + dy * dy;
      if (d < minDist && d > 0) {
        i1 = i;
        minDist = d;
      }
    }
    var i1x = coords[i1 << 1];
    var i1y = coords[(i1 << 1) | 1];

    var minRadius = double.infinity;

    // find the third point forming the smallest circumcircle with i0, i1
    final sdx = i1x - i0x;
    final sdy = i1y - i0y;
    final sbl = sdx * sdx + sdy * sdy;
    for (var i = 0; i < n; i++) {
      if (i == i0 || i == i1) continue;
      final k = i << 1;
      final ex = coords[k] - i0x;
      final ey = coords[k | 1] - i0y;
      final cl = ex * ex + ey * ey;
      final d = 0.5 / (sdx * ey - sdy * ex);
      final rx = (ey * sbl - sdy * cl) * d;
      final ry = (sdx * cl - ex * sbl) * d;
      final r = rx * rx + ry * ry;
      if (r < minRadius) {
        i2 = i;
        minRadius = r;
      }
    }
    var i2x = coords[i2 << 1];
    var i2y = coords[(i2 << 1) | 1];

    if (minRadius == double.infinity) {
      // order collinear points by dx (or dy if all x are identical)
      // and return the list as a hull
      final c0x = coords[0];
      final c0y = coords[1];
      for (var i = 0; i < n; i++) {
        final k = i << 1;
        final dx = coords[k] - c0x;
        dists[i] = dx != 0 ? dx : (coords[k | 1] - c0y);
      }
      _quicksort(ids, dists, 0, n - 1);
      final h = Uint32List(n);
      var j = 0;
      var d0 = double.negativeInfinity;
      for (var i = 0; i < n; i++) {
        final id = ids[i];
        final d = dists[id];
        if (d > d0) {
          h[j++] = id;
          d0 = d;
        }
      }
      hull = Uint32List.sublistView(h, 0, j);
      triangles = Uint32List(0);
      halfedges = Int32List(0);
      trianglesLen = 0;
      return;
    }

    // swap the order of the seed points for counter-clockwise orientation
    if (orient2d(i0x, i0y, i1x, i1y, i2x, i2y) < 0) {
      final i = i1;
      final x = i1x;
      final y = i1y;
      i1 = i2;
      i1x = i2x;
      i1y = i2y;
      i2 = i;
      i2x = x;
      i2y = y;
    }

    final (centerX, centerY) = _circumcenter(i0x, i0y, i1x, i1y, i2x, i2y);

    for (var i = 0; i < n; i++) {
      final k = i << 1;
      final dx = coords[k] - centerX;
      final dy = coords[k | 1] - centerY;
      dists[i] = dx * dx + dy * dy;
    }

    // sort the points by distance from the seed triangle circumcenter
    _quicksort(ids, dists, 0, n - 1);

    // set up the seed triangle as the starting hull
    _hullStart = i0;
    var hullSize = 3;

    hullNext[i0] = hullPrev[i2] = i1;
    hullNext[i1] = hullPrev[i0] = i2;
    hullNext[i2] = hullPrev[i1] = i0;

    hullTri[i0] = 0;
    hullTri[i1] = 1;
    hullTri[i2] = 2;

    hullHash.fillRange(0, hashSize, -1);
    hullHash[_hashKey(i0x, i0y, centerX, centerY, hashSize)] = i0;
    hullHash[_hashKey(i1x, i1y, centerX, centerY, hashSize)] = i1;
    hullHash[_hashKey(i2x, i2y, centerX, centerY, hashSize)] = i2;

    trianglesLen = 0;
    _addTriangle(i0, i1, i2, -1, -1, -1);

    var xp = 0.0;
    var yp = 0.0;
    for (var k = 0; k < n; k++) {
      final i = ids[k];
      final x = coords[i << 1];
      final y = coords[(i << 1) | 1];

      // skip near-duplicate points
      if (k > 0 && (x - xp).abs() <= _epsilon && (y - yp).abs() <= _epsilon) {
        continue;
      }
      xp = x;
      yp = y;

      // skip seed triangle points
      if (i == i0 || i == i1 || i == i2) continue;

      // find a visible edge on the convex hull using edge hash
      var start = 0;
      final key = _hashKey(x, y, centerX, centerY, hashSize);
      var hIdx = key;
      for (var j = 0; j < hashSize; j++) {
        start = hullHash[hIdx];
        if (start != -1 && start != hullNext[start]) break;
        if (++hIdx == hashSize) hIdx = 0;
      }

      start = hullPrev[start];
      var e = start;
      int q;
      while (true) {
        q = hullNext[e];
        if (orient2d(
              x,
              y,
              coords[e << 1],
              coords[(e << 1) | 1],
              coords[q << 1],
              coords[(q << 1) | 1],
            ) <
            0) {
          break;
        }
        e = q;
        if (e == start) {
          e = -1;
          break;
        }
      }
      if (e == -1) continue; // likely a near-duplicate point; skip it

      // add the first triangle from the point
      var t = _addTriangle(e, i, hullNext[e], -1, -1, hullTri[e]);

      // recursively flip triangles until they satisfy the Delaunay condition
      hullTri[i] = _legalize(t + 2);
      hullTri[e] = t; // keep track of boundary triangles on the hull
      hullSize++;

      // walk forward through the hull, adding triangles and flipping
      var next = hullNext[e];
      while (true) {
        q = hullNext[next];
        if (orient2d(
              x,
              y,
              coords[next << 1],
              coords[(next << 1) | 1],
              coords[q << 1],
              coords[(q << 1) | 1],
            ) >=
            0) {
          break;
        }
        t = _addTriangle(next, i, q, hullTri[i], -1, hullTri[next]);
        hullTri[i] = _legalize(t + 2);
        hullNext[next] = next; // mark as removed
        hullSize--;
        next = q;
      }

      // walk backward from the other side, adding more triangles and flipping
      if (e == start) {
        while (true) {
          q = hullPrev[e];
          if (orient2d(
                x,
                y,
                coords[q << 1],
                coords[(q << 1) | 1],
                coords[e << 1],
                coords[(e << 1) | 1],
              ) >=
              0) {
            break;
          }
          t = _addTriangle(q, i, e, -1, hullTri[e], hullTri[q]);
          _legalize(t + 2);
          hullTri[q] = t;
          hullNext[e] = e; // mark as removed
          hullSize--;
          e = q;
        }
      }

      // update the hull indices
      _hullStart = hullPrev[i] = e;
      hullNext[e] = hullPrev[next] = i;
      hullNext[i] = next;

      // save the two new edges in the hash table
      hullHash[key] = i;
      hullHash[_hashKey(
            coords[e << 1],
            coords[(e << 1) | 1],
            centerX,
            centerY,
            hashSize,
          )] =
          e;
    }

    final outHull = Uint32List(hullSize);
    var e = _hullStart;
    for (var i = 0; i < hullSize; i++) {
      outHull[i] = e;
      e = hullNext[e];
    }
    hull = outHull;

    // trim typed triangle mesh arrays
    triangles = Uint32List.sublistView(_triangles, 0, trianglesLen);
    halfedges = Int32List.sublistView(_halfedges, 0, trianglesLen);
  }

  int _legalize(int a) {
    final triangles = _triangles;
    final halfedges = _halfedges;
    final coords = this.coords;
    final stack = _edgeStack;

    var i = 0;
    var ar = 0;
    var cur = a;

    // recursion eliminated with a fixed-size stack
    while (true) {
      final b = halfedges[cur];

      final a0 = (cur ~/ 3) * 3;
      final aOff = cur - a0;
      ar = aOff == 0 ? a0 + 2 : cur - 1;

      if (b == -1) {
        // convex hull edge
        if (i == 0) break;
        cur = stack[--i];
        continue;
      }

      final b0 = (b ~/ 3) * 3;
      final bOff = b - b0;
      final al = aOff == 2 ? a0 : cur + 1;
      final bl = bOff == 0 ? b0 + 2 : b - 1;

      final p0 = triangles[ar];
      final pr = triangles[cur];
      final pl = triangles[al];
      final p1 = triangles[bl];

      final p02 = p0 << 1;
      final pr2 = pr << 1;
      final pl2 = pl << 1;
      final p12 = p1 << 1;

      final px = coords[p12];
      final py = coords[p12 | 1];
      final dx = coords[p02] - px;
      final dy = coords[p02 | 1] - py;
      final ex = coords[pr2] - px;
      final ey = coords[pr2 | 1] - py;
      final fx = coords[pl2] - px;
      final fy = coords[pl2 | 1] - py;

      final ap = dx * dx + dy * dy;
      final bp = ex * ex + ey * ey;
      final cp = fx * fx + fy * fy;

      if (dx * (ey * cp - bp * fy) -
              dy * (ex * cp - bp * fx) +
              ap * (ex * fy - ey * fx) <
          0) {
        triangles[cur] = p1;
        triangles[b] = p0;

        final hbl = halfedges[bl];

        // edge swapped on the other side of the hull (rare); fix reference
        if (hbl == -1) {
          var e = _hullStart;
          final hullTri = _hullTri;
          final hullPrev = _hullPrev;
          do {
            if (hullTri[e] == bl) {
              hullTri[e] = cur;
              break;
            }
            e = hullPrev[e];
          } while (e != _hullStart);
        }
        halfedges[cur] = hbl;
        if (hbl != -1) halfedges[hbl] = cur;
        final har = halfedges[ar];
        halfedges[b] = har;
        if (har != -1) halfedges[har] = b;
        halfedges[ar] = bl;
        halfedges[bl] = ar;

        final br = bOff == 2 ? b0 : b + 1;

        // cap can only be hit on extremely degenerate input
        if (i < 512) {
          stack[i++] = br;
        }
      } else {
        if (i == 0) break;
        cur = stack[--i];
      }
    }

    return ar;
  }

  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:tryInline')
  int _addTriangle(int i0, int i1, int i2, int a, int b, int c) {
    final t = trianglesLen;
    final tri = _triangles;
    final he = _halfedges;

    tri[t] = i0;
    tri[t + 1] = i1;
    tri[t + 2] = i2;

    he[t] = a;
    if (a != -1) he[a] = t;
    he[t + 1] = b;
    if (b != -1) he[b] = t + 1;
    he[t + 2] = c;
    if (c != -1) he[c] = t + 2;

    trianglesLen = t + 3;

    return t;
  }
}

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:tryInline')
int _hashKey(double x, double y, double cx, double cy, int hashSize) {
  final dx = x - cx;
  final dy = y - cy;
  final p = dx / (dx.abs() + dy.abs());
  final angle = (dy > 0 ? 3.0 - p : 1.0 + p) * 0.25;
  final h = (angle * hashSize).floor();
  return h >= hashSize ? h - hashSize : (h < 0 ? 0 : h);
}

(double, double) _circumcenter(
  double ax,
  double ay,
  double bx,
  double by,
  double cx,
  double cy,
) {
  final dx = bx - ax;
  final dy = by - ay;
  final ex = cx - ax;
  final ey = cy - ay;

  final bl = dx * dx + dy * dy;
  final cl = ex * ex + ey * ey;
  final d = 0.5 / (dx * ey - dy * ex);

  final x = ax + (ey * bl - dy * cl) * d;
  final y = ay + (dx * cl - ex * bl) * d;

  return (x, y);
}

void _quicksort(Uint32List ids, Float64List dists, int left, int right) {
  if (right - left <= 20) {
    for (var i = left + 1; i <= right; i++) {
      final temp = ids[i];
      final tempDist = dists[temp];
      var j = i - 1;
      while (j >= left && dists[ids[j]] > tempDist) {
        ids[j + 1] = ids[j--];
      }
      ids[j + 1] = temp;
    }
  } else {
    final median = (left + right) >> 1;
    var i = left + 1;
    var j = right;
    var tmp = ids[median];
    ids[median] = ids[i];
    ids[i] = tmp;
    if (dists[ids[left]] > dists[ids[right]]) {
      tmp = ids[left];
      ids[left] = ids[right];
      ids[right] = tmp;
    }
    if (dists[ids[i]] > dists[ids[right]]) {
      tmp = ids[i];
      ids[i] = ids[right];
      ids[right] = tmp;
    }
    if (dists[ids[left]] > dists[ids[i]]) {
      tmp = ids[left];
      ids[left] = ids[i];
      ids[i] = tmp;
    }

    final temp = ids[i];
    final tempDist = dists[temp];
    while (true) {
      do {
        i++;
      } while (dists[ids[i]] < tempDist);
      do {
        j--;
      } while (dists[ids[j]] > tempDist);
      if (j < i) break;
      tmp = ids[i];
      ids[i] = ids[j];
      ids[j] = tmp;
    }
    ids[left + 1] = ids[j];
    ids[j] = temp;

    if (right - i + 1 >= j - left) {
      _quicksort(ids, dists, i, right);
      _quicksort(ids, dists, left, j - 1);
    } else {
      _quicksort(ids, dists, left, j - 1);
      _quicksort(ids, dists, i, right);
    }
  }
}
