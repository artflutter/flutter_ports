// Ported from d3-delaunay v6.0.4 src/delaunay.js (ISC, Observable, Inc.).

/// Port of `src/delaunay.js` of d3-delaunay 6.0.4: [Delaunay] triangulation,
/// convex hull, neighbor iteration, nearest-neighbor lookup, radius search,
/// and rendering to [CanvasPath] or SVG.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_d3_delaunay_port/src/delaunator/index.dart';
import 'package:flutter_d3_delaunay_port/src/path.dart';
import 'package:flutter_d3_delaunay_port/src/voronoi.dart';
import 'package:flutter_d3_path_port/d3_path.dart';

const double _tau = 2 * math.pi;

// A triangulation is collinear if all its triangles have a near-zero area.
bool _collinear(Delaunator d) {
  final triangles = d.triangles;
  final coords = d.coords;
  for (var i = 0; i < triangles.length; i += 3) {
    final a = triangles[i] << 1;
    final b = triangles[i + 1] << 1;
    final c = triangles[i + 2] << 1;
    final cross =
        (coords[c] - coords[a]) * (coords[b | 1] - coords[a | 1]) -
        (coords[b] - coords[a]) * (coords[c | 1] - coords[a | 1]);
    if (cross > 1e-10) return false;
  }
  return true;
}

double _hypot(double a, double b) {
  final aa = a.abs();
  final bb = b.abs();
  if (aa == double.infinity || bb == double.infinity) return double.infinity;
  if (aa.isNaN || bb.isNaN) return double.nan;
  final hi = aa >= bb ? aa : bb;
  final lo = aa >= bb ? bb : aa;
  if (hi == 0) return 0;
  final ratio = lo / hi;
  return hi * math.sqrt(1 + ratio * ratio);
}

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:tryInline')
int _nextHalfedge(int e) {
  final next = e + 1;
  return (next ~/ 3) * 3 == next ? e - 2 : next;
}

/// Lightweight [Iterable] / [Iterator] for [Delaunay.neighbors] avoiding
/// `sync*` generator state-machine overhead.
final class _DelaunayNeighborsIterable(
  final Delaunay _delaunay,
  final int _point,
) extends Iterable<int> {
  @override
  Iterator<int> get iterator => _DelaunayNeighborsIterator(_delaunay, _point);
}

final class _DelaunayNeighborsIterator(final Delaunay _delaunay, final int _i)
    implements Iterator<int> {
  int _current = -1;
  int _state = 0; // 0: init, 1: walking, 2: collinear-second, 3: done
  int _e0 = -1;
  int _e = -1;
  int _colIdx = -1;
  int _p0 = -1;

  @override
  int get current => _current;

  @override
  bool moveNext() {
    final state = _state;
    if (state == 3) return false;

    if (state == 0) {
      final col = _delaunay.collinear;
      if (col != null) {
        final l = col.indexOf(_i);
        _colIdx = l;
        if (l > 0) {
          _current = col[l - 1];
          _state = l < col.length - 1 ? 2 : 3;
          return true;
        }
        if (l >= 0 && l < col.length - 1) {
          _current = col[l + 1];
          _state = 3;
          return true;
        }
        _state = 3;
        return false;
      }

      final e0 = _delaunay.inedges[_i];
      if (e0 == -1) {
        _state = 3;
        return false;
      }
      _e0 = e0;
      _e = e0;
      _state = 1;
      final p0 = _delaunay.triangles[e0];
      if (p0 < 0) {
        _state = 3;
        return false;
      }
      _p0 = p0;
      _current = p0;
      return true;
    }

    if (state == 2) {
      _current = _delaunay.collinear![_colIdx + 1];
      _state = 3;
      return true;
    }

    // state == 1: advance around point _i
    final triangles = _delaunay.triangles;
    var e = _nextHalfedge(_e);
    if (triangles[e] != _i) {
      _state = 3;
      return false;
    }
    e = _delaunay.halfedges[e];
    if (e == -1) {
      final hull = _delaunay.hull;
      var hi = _delaunay._hullIndex[_i] + 1;
      if (hi == hull.length) hi = 0;
      final p = hull[hi];
      _state = 3;
      if (p != _p0) {
        _current = p;
        return true;
      }
      return false;
    }
    if (e == _e0) {
      _state = 3;
      return false;
    }
    _e = e;
    final p0 = triangles[e];
    if (p0 < 0) {
      _state = 3;
      return false;
    }
    _p0 = p0;
    _current = p0;
    return true;
  }
}

/// `delaunay.js:34` `Delaunay`: 2D Delaunay triangulation with convex hull,
/// neighbor traversal, nearest-point queries, Voronoi dual, and [CanvasPath] /
/// SVG rendering.
// DIVERGES(d3-delaunay): adapt-delaunay-typed-api, typed Dart APIs & findAll.
// DIVERGES(d3-delaunay): adapt-delaunay-fast-forms, unrolled init & flat find.
class Delaunay(
  /// Flat `[x0, y0, x1, y1, ...]` coordinate buffer.
  final Float64List points,
) {
  /// `delaunay.js:40` `constructor(points)`: computes the Delaunay
  /// triangulation over flat [points] `[x0, y0, x1, y1, ...]`.
  ///
  /// The [Float64List] is retained directly so callers can mutate [points] in
  /// place and call [update].
  this {
    _init();
  }

  /// Constructs a [Delaunay] triangulation from `(double, double)` coordinates
  /// without closure dispatch.
  factory fromCoords(Iterable<(double, double)> points) {
    if (points is List<(double, double)>) {
      final n = points.length;
      final array = Float64List(n * 2);
      for (var i = 0; i < n; ++i) {
        final (px, py) = points[i];
        array[i << 1] = px;
        array[(i << 1) | 1] = py;
      }
      return Delaunay(array);
    }
    final buf = <double>[];
    for (final (px, py) in points) {
      buf
        ..add(px)
        ..add(py);
    }
    return Delaunay(Float64List.fromList(buf));
  }

  /// Constructs a [Delaunay] triangulation for [length] points generated by
  /// index functions [x] and [y].
  factory fromLength(
    int length,
    double Function(int) x,
    double Function(int) y,
  ) {
    final array = Float64List(length * 2);
    for (var i = 0; i < length; ++i) {
      array[i << 1] = x(i);
      array[(i << 1) | 1] = y(i);
    }
    return Delaunay(array);
  }

  /// `delaunay.js:35` `Delaunay.from(points, fx, fy)`: constructs a [Delaunay]
  /// triangulation from an [Iterable] of typed points [T].
  ///
  /// When [points] is `Iterable<(double, double)>`, [x] and [y] may be omitted
  /// and default to `$1` and `$2`. For any other type [T], both [x] and [y]
  /// must be provided.
  static Delaunay from<T>(
    Iterable<T> points, {
    double Function(T)? x,
    double Function(T)? y,
  }) {
    if (x == null && y == null) {
      if (points case final Iterable<(double, double)> coords) {
        return Delaunay.fromCoords(coords);
      }
      throw ArgumentError(
        'x and y accessors are required when T is not (double, double)',
      );
    }
    if (x == null || y == null) {
      if (points case final Iterable<(double, double)> coords) {
        final fx = x as double Function((double, double))? ?? (p) => p.$1;
        final fy = y as double Function((double, double))? ?? (p) => p.$2;
        return from<(double, double)>(coords, x: fx, y: fy);
      }
      throw ArgumentError(
        'Both x and y accessors are required when T is not (double, double)',
      );
    }
    if (points is List<T>) {
      final n = points.length;
      final array = Float64List(n * 2);
      for (var i = 0; i < n; ++i) {
        final p = points[i];
        array[i << 1] = x(p);
        array[(i << 1) | 1] = y(p);
      }
      return Delaunay(array);
    }
    final buf = <double>[];
    for (final p in points) {
      buf
        ..add(x(p))
        ..add(y(p));
    }
    return Delaunay(Float64List.fromList(buf));
  }

  /// Constructs a [Delaunay] triangulation from an [Iterable] of [T] with
  /// index-aware coordinate accessors `(datum, index)`.
  static Delaunay fromIndexed<T>(
    Iterable<T> points, {
    required double Function(T, int) x,
    required double Function(T, int) y,
  }) {
    if (points is List<T>) {
      final n = points.length;
      final array = Float64List(n * 2);
      for (var i = 0; i < n; ++i) {
        final p = points[i];
        array[i << 1] = x(p, i);
        array[(i << 1) | 1] = y(p, i);
      }
      return Delaunay(array);
    }
    final buf = <double>[];
    var i = 0;
    for (final p in points) {
      buf
        ..add(x(p, i))
        ..add(y(p, i));
      ++i;
    }
    return Delaunay(Float64List.fromList(buf));
  }

  Delaunator _delaunator = Delaunator(points);

  /// Incoming half-edge index for each point (`-1` for coincident points).
  final Int32List inedges = Int32List(points.length >> 1);

  final Int32List _hullIndex = Int32List(points.length >> 1);

  /// Counter-clockwise convex hull point indices.
  late Uint32List hull;

  /// Triangle vertex indices (triples in counter-clockwise order).
  ///
  /// Uses a zero-copy [Int32List] view over `Delaunator.triangles` in normal
  /// triangulations and a 3-element [Int32List] with `-1` sentinels in the
  /// 1-point degenerate case.
  late Int32List triangles;

  /// Twin half-edge indices (`-1` on the convex hull).
  late Int32List halfedges;

  /// Sorted point indices when all points are collinear, or `null` otherwise.
  Int32List? collinear;

  bool _hasCoincident = false;

  /// `delaunay.js:47` `update()`: recomputes the triangulation after [points]
  /// have been modified in place and returns `this`.
  Delaunay update() {
    _delaunator.update();
    _init();
    // Upstream update() returns `this` for fluent chaining.
    // ignore: avoid_returning_this
    return this;
  }

  void _init() {
    var d = _delaunator;
    final pts = points;

    // check for collinear
    if (d.hull.length > 2 && _collinear(d)) {
      final n = pts.length >> 1;
      final sorted = List<int>.generate(n, (i) => i, growable: false)
        ..sort((i, j) {
          final dx = pts[i << 1] - pts[j << 1];
          if (dx != 0) return dx < 0 ? -1 : 1;
          final dy = pts[(i << 1) | 1] - pts[(j << 1) | 1];
          return dy < 0 ? -1 : (dy > 0 ? 1 : 0);
        });
      final col = Int32List.fromList(sorted);
      collinear = col;
      final e = col[0];
      final f = col[col.length - 1];
      final r =
          1e-8 *
          _hypot(
            pts[(f << 1) | 1] - pts[(e << 1) | 1],
            pts[f << 1] - pts[e << 1],
          );
      for (var i = 0; i < n; ++i) {
        final k = i << 1;
        final px = pts[k];
        final py = pts[k | 1];
        pts[k] = px + math.sin(px + py) * r;
        pts[k | 1] = py + math.cos(px - py) * r;
      }
      d = _delaunator = Delaunator(pts);
    } else {
      collinear = null;
    }

    final halfedges = this.halfedges = d.halfedges;
    final hull = this.hull = d.hull;
    final dt = d.triangles;
    final triangles = this.triangles = Int32List.view(
      dt.buffer,
      dt.offsetInBytes,
      dt.length,
    );
    final inedges = this.inedges;
    final numPts = inedges.length;
    inedges.fillRange(0, numPts, -1);
    final hullIndex = _hullIndex..fillRange(0, numPts, -1);

    // Unrolled by 3: eliminates `% 3` on every halfedge and tracks coincident
    // points in the same pass.
    var filled = 0;
    for (var e = 0, n = halfedges.length; e < n; e += 3) {
      final p0 = triangles[e + 1];
      if (inedges[p0] == -1) {
        inedges[p0] = e;
        ++filled;
      } else if (halfedges[e] == -1) {
        inedges[p0] = e;
      }

      final e1 = e + 1;
      final p1 = triangles[e + 2];
      if (inedges[p1] == -1) {
        inedges[p1] = e1;
        ++filled;
      } else if (halfedges[e1] == -1) {
        inedges[p1] = e1;
      }

      final e2 = e + 2;
      final p2 = triangles[e];
      if (inedges[p2] == -1) {
        inedges[p2] = e2;
        ++filled;
      } else if (halfedges[e2] == -1) {
        inedges[p2] = e2;
      }
    }
    for (var i = 0, n = hull.length; i < n; ++i) {
      hullIndex[hull[i]] = i;
    }

    // degenerate case: 1 or 2 (distinct) points
    if (hull.length <= 2 && hull.isNotEmpty) {
      final degTri = Int32List(3)..fillRange(0, 3, -1);
      final degHalf = Int32List(3)..fillRange(0, 3, -1);
      degTri[0] = hull[0];
      if (inedges[hull[0]] == -1) ++filled;
      inedges[hull[0]] = 1;
      if (hull.length == 2) {
        if (inedges[hull[1]] == -1) ++filled;
        inedges[hull[1]] = 0;
        degTri[1] = hull[1];
        degTri[2] = hull[1];
      }
      this.triangles = degTri;
      this.halfedges = degHalf;
    }

    _hasCoincident = filled < numPts;
  }

  /// `delaunay.js:102` `voronoi(bounds)`: returns the [Voronoi] diagram for
  /// this triangulation clipped to [bounds] (`(xmin, ymin, xmax, ymax)`),
  /// defaulting to `(0, 0, 960, 500)`.
  Voronoi voronoi([
    (double, double, double, double) bounds = (0, 0, 960, 500),
  ]) => Voronoi(this, bounds);

  /// `delaunay.js:105` `neighbors(i)`: yields the indices of the Delaunay
  /// neighbors of point [i].
  Iterable<int> neighbors(int i) => _DelaunayNeighborsIterable(this, i);

  /// `delaunay.js:131` `find(x, y, i = 0)`: returns the index of the input
  /// point closest to `(x, y)`, starting the search at point index [i].
  /// Returns `-1` when [x] or [y] is `NaN` or there are no points.
  int find(double x, double y, [int i = 0]) {
    if (x.isNaN || y.isNaN || points.isEmpty) return -1;
    final inedges = this.inedges;
    final hull = this.hull;
    final hullLen = hull.length;
    final hullIndex = _hullIndex;
    final halfedges = this.halfedges;
    final triangles = this.triangles;
    final pts = points;
    final numPts = pts.length >> 1;

    final i0 = i;
    var cur = i;
    int c;
    while (true) {
      final e0 = inedges[cur];
      if (e0 == -1) {
        c = cur + 1;
        if (c == numPts) c = 0;
      } else {
        c = cur;
        final c2 = cur << 1;
        var dx = x - pts[c2];
        var dy = y - pts[c2 + 1];
        var dc = dx * dx + dy * dy;
        var e = e0;
        do {
          final t = triangles[e];
          if (t >= 0) {
            final t2 = t << 1;
            dx = x - pts[t2];
            dy = y - pts[t2 + 1];
            final dt = dx * dx + dy * dy;
            if (dt < dc) {
              dc = dt;
              c = t;
            }
          }
          final next = e + 1;
          e = (next ~/ 3) * 3 == next ? e - 2 : next;
          if (triangles[e] != cur) break;
          e = halfedges[e];
          if (e == -1) {
            var hi = hullIndex[cur] + 1;
            if (hi == hullLen) hi = 0;
            final he = hull[hi];
            if (he != t) {
              final he2 = he << 1;
              dx = x - pts[he2];
              dy = y - pts[he2 + 1];
              if (dx * dx + dy * dy < dc) {
                c = he;
              }
            }
            break;
          }
        } while (e != e0);
      }
      if (c < 0 || c == cur || c == i0) return c;
      cur = c;
    }
  }

  /// Returns the indices of all input points within Euclidean [radius] of
  /// `(x, y)` (inclusive).
  Iterable<int> findAll(double x, double y, double radius) sync* {
    if (x.isNaN || y.isNaN || radius.isNaN || radius < 0 || points.isEmpty) {
      return;
    }
    final seed = find(x, y);
    if (seed < 0) return;

    final r2 = radius * radius;
    final pts = points;
    var dx = x - pts[seed << 1];
    var dy = y - pts[(seed << 1) | 1];
    if (dx * dx + dy * dy > r2) return;

    final n = pts.length >> 1;
    final visited = Uint8List(n);
    final queue = <int>[seed];
    visited[seed] = 1;
    var head = 0;
    while (head < queue.length) {
      final u = queue[head++];
      yield u;
      for (final v in neighbors(u)) {
        if (visited[v] != 0) continue;
        visited[v] = 1;
        dx = x - pts[v << 1];
        dy = y - pts[(v << 1) | 1];
        if (dx * dx + dy * dy <= r2) {
          queue.add(v);
        }
      }
    }

    if (_hasCoincident) {
      for (var k = 0; k < n; ++k) {
        if (visited[k] != 0 || inedges[k] != -1) continue;
        dx = x - pts[k << 1];
        dy = y - pts[(k << 1) | 1];
        if (dx * dx + dy * dy <= r2) {
          yield k;
        }
      }
    }
  }

  /// Internal one-step greedy walk toward `(x, y)` from point [i].
  /// Also used by [Voronoi.contains].
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:tryInline')
  int step(int i, double x, double y) {
    final inedges = this.inedges;
    final hull = this.hull;
    final hullIndex = _hullIndex;
    final halfedges = this.halfedges;
    final triangles = this.triangles;
    final pts = points;
    if (pts.isEmpty) return -1;
    final e0 = inedges[i];
    if (e0 == -1) {
      final next = i + 1;
      return next == (pts.length >> 1) ? 0 : next;
    }
    var c = i;
    var dx = x - pts[i << 1];
    var dy = y - pts[(i << 1) | 1];
    var dc = dx * dx + dy * dy;
    var e = e0;
    do {
      final t = triangles[e];
      if (t >= 0) {
        dx = x - pts[t << 1];
        dy = y - pts[(t << 1) | 1];
        final dt = dx * dx + dy * dy;
        if (dt < dc) {
          dc = dt;
          c = t;
        }
      }
      e = _nextHalfedge(e);
      if (triangles[e] != i) break; // bad triangulation
      e = halfedges[e];
      if (e == -1) {
        var hi = hullIndex[i] + 1;
        if (hi == hull.length) hi = 0;
        final he = hull[hi];
        if (he != t) {
          dx = x - pts[he << 1];
          dy = y - pts[(he << 1) | 1];
          if (dx * dx + dy * dy < dc) return he;
        }
        break;
      }
    } while (e != e0);
    return c;
  }

  /// `delaunay.js:162` `render(context)`: renders all edges of the Delaunay
  /// triangulation into [context].
  void render(CanvasPath context) {
    final pts = points;
    final he = halfedges;
    final tri = triangles;
    for (var i = 0, n = he.length; i < n; ++i) {
      final j = he[i];
      if (j < i) continue;
      final ti = tri[i] << 1;
      final tj = tri[j] << 1;
      context
        ..moveTo(pts[ti], pts[ti | 1])
        ..lineTo(pts[tj], pts[tj | 1]);
    }
    renderHull(context);
  }

  /// Renders all edges of the Delaunay triangulation as an SVG path string, or
  /// `null` if empty.
  String? renderToSvg() {
    final buffer = Path();
    render(buffer);
    final s = buffer.toString();
    return s.isEmpty ? null : s;
  }

  /// `delaunay.js:176` `renderPoints(context, r = 2)`: renders each input point
  /// as a circle of radius [r] into [context].
  void renderPoints(CanvasPath context, [double r = 2]) {
    final pts = points;
    for (var i = 0, n = pts.length; i < n; i += 2) {
      final x = pts[i];
      final y = pts[i | 1];
      context
        ..moveTo(x + r, y)
        ..arc(x, y, r, 0, _tau);
    }
  }

  /// Renders each input point as a circle of radius [r] as an SVG path string,
  /// or `null` if there are no points.
  String? renderPointsToSvg([double r = 2]) {
    final buffer = DelaunayPath();
    renderPoints(buffer, r);
    return buffer.value();
  }

  /// `delaunay.js:188` `renderHull(context)`: renders the closed convex hull
  /// into [context].
  void renderHull(CanvasPath context) {
    final h = hull;
    final n = h.length;
    if (n == 0) return;
    final pts = points;
    final h0 = h[0] << 1;
    context.moveTo(pts[h0], pts[h0 | 1]);
    for (var i = 1; i < n; ++i) {
      final hi = h[i] << 1;
      context.lineTo(pts[hi], pts[hi | 1]);
    }
    context.closePath();
  }

  /// Renders the closed convex hull as an SVG path string, or `null` if empty.
  String? renderHullToSvg() {
    final buffer = Path();
    renderHull(buffer);
    final s = buffer.toString();
    return s.isEmpty ? null : s;
  }

  /// `delaunay.js:200` `hullPolygon()`: returns the closed convex hull polygon
  /// (empty when there are no points).
  List<(double, double)> hullPolygon() {
    final h = hull;
    final n = h.length;
    if (n == 0) return <(double, double)>[];
    final pts = points;
    final out = List<(double, double)>.filled(n + 1, (0, 0));
    for (var i = 0; i < n; ++i) {
      final hi = h[i] << 1;
      out[i] = (pts[hi], pts[hi | 1]);
    }
    out[n] = out[0];
    return out;
  }

  /// `delaunay.js:205` `renderTriangle(i, context)`: renders triangle [i] into
  /// [context].
  void renderTriangle(int i, CanvasPath context) {
    final pts = points;
    final tri = triangles;
    final base = i * 3;
    final i0 = tri[base];
    final i1 = tri[base + 1];
    final i2 = tri[base + 2];
    if (i0 < 0 || i1 < 0 || i2 < 0) return;
    final t0 = i0 << 1;
    final t1 = i1 << 1;
    final t2 = i2 << 1;
    context
      ..moveTo(pts[t0], pts[t0 | 1])
      ..lineTo(pts[t1], pts[t1 | 1])
      ..lineTo(pts[t2], pts[t2 | 1])
      ..closePath();
  }

  /// Renders triangle [i] as an SVG path string, or `null` if degenerate.
  String? renderTriangleToSvg(int i) {
    final buffer = Path();
    renderTriangle(i, buffer);
    final s = buffer.toString();
    return s.isEmpty ? null : s;
  }

  /// `delaunay.js:217` `trianglePolygons()`: yields the closed polygon for each
  /// triangle in the triangulation.
  Iterable<List<(double, double)>> trianglePolygons() sync* {
    final n = triangles.length ~/ 3;
    for (var i = 0; i < n; ++i) {
      yield trianglePolygon(i);
    }
  }

  /// `delaunay.js:223` `trianglePolygon(i)`: returns the closed polygon for
  /// triangle [i].
  List<(double, double)> trianglePolygon(int i) {
    final pts = points;
    final tri = triangles;
    final base = i * 3;
    final i0 = tri[base];
    final i1 = tri[base + 1];
    final i2 = tri[base + 2];
    if (i0 < 0 || i1 < 0 || i2 < 0) return <(double, double)>[];
    final t0 = i0 << 1;
    final t1 = i1 << 1;
    final t2 = i2 << 1;
    final p0 = (pts[t0], pts[t0 | 1]);
    return <(double, double)>[
      p0,
      (pts[t1], pts[t1 | 1]),
      (pts[t2], pts[t2 | 1]),
      p0,
    ];
  }
}
