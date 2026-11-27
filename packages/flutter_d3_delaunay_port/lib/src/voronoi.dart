// Ported from d3-delaunay v6.0.4 src/voronoi.js (ISC, Observable, Inc.).

/// Port of `src/voronoi.js` of d3-delaunay 6.0.4: [Voronoi] diagram clipped to
/// a bounding rectangle, with circumcenters, exterior rays, cell polygons,
/// hit testing, clipped neighbors, and [CanvasPath] / SVG rendering.
library;

import 'dart:typed_data';

import 'package:flutter_d3_delaunay_port/src/delaunay.dart';
import 'package:flutter_d3_path_port/d3_path.dart';

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:tryInline')
int _nextHalfedge(int e) {
  final next = e + 1;
  return (next ~/ 3) * 3 == next ? e - 2 : next;
}

/// `voronoi.js:4` `Voronoi`: Voronoi diagram dual to a [Delaunay]
/// triangulation, clipped to `[xmin, ymin, xmax, ymax]`.
// DIVERGES(d3-delaunay): adapt-delaunay-typed-api, typed bounds/polygons/SVG.
// DIVERGES(d3-delaunay): adapt-delaunay-fast-forms, reusable Float64List clip.
class Voronoi(
  /// The underlying [Delaunay] triangulation.
  final Delaunay delaunay, [
  (double, double, double, double) bounds = (0, 0, 960, 500),
]) {
  /// `voronoi.js:5` `constructor(delaunay, [xmin, ymin, xmax, ymax])`: creates
  /// a [Voronoi] diagram for [delaunay] clipped to [bounds] (default
  /// `(0, 0, 960, 500)`).
  ///
  /// Throws an [ArgumentError] if `xmax < xmin`, `ymax < ymin`, or any bound
  /// is `NaN`.
  this {
    if (!(xmax >= xmin) || !(ymax >= ymin)) {
      throw ArgumentError('invalid bounds');
    }
    _init();
  }

  /// Left bound of the clipping viewport.
  final double xmin = bounds.$1;

  /// Top bound of the clipping viewport.
  final double ymin = bounds.$2;

  /// Right bound of the clipping viewport.
  final double xmax = bounds.$3;

  /// Bottom bound of the clipping viewport.
  final double ymax = bounds.$4;

  final Float64List _circumcenters = Float64List(delaunay.points.length * 2);

  /// Triangle circumcenters `[x0, y0, x1, y1, ...]`.
  late Float64List circumcenters;

  /// Exterior ray direction vectors for convex-hull cells (4 doubles per site).
  final Float64List vectors = Float64List(delaunay.points.length * 2);

  // Reusable scratch buffers for zero-allocation clipping & ray projection.
  Float64List _cellBuf = Float64List(64);
  Float64List _workBuf = Float64List(64);
  Float64List _clipBuf = Float64List(64);
  double _sx0 = 0;
  double _sy0 = 0;
  double _sx1 = 0;
  double _sy1 = 0;
  double _px = 0;
  double _py = 0;

  /// `voronoi.js:14` `update()`: updates [delaunay] and recomputes
  /// [circumcenters] and [vectors] in place, returning `this`.
  Voronoi update() {
    delaunay.update();
    _init();
    // Upstream update() returns `this` for fluent chaining.
    // ignore: avoid_returning_this
    return this;
  }

  void _init() {
    final points = delaunay.points;
    final hull = delaunay.hull;
    final triangles = delaunay.triangles;
    final vectors = this.vectors;
    var hasBarycenter = false;
    var bx = 0.0;
    var by = 0.0; // lazily computed barycenter of the hull

    // Compute circumcenters.
    final cc = circumcenters = Float64List.sublistView(
      _circumcenters,
      0,
      (triangles.length ~/ 3) * 2,
    );
    for (var i = 0, j = 0, n = triangles.length; i < n; i += 3, j += 2) {
      final i1 = triangles[i];
      final i2 = triangles[i + 1];
      final i3 = triangles[i + 2];
      if (i1 < 0 || i2 < 0 || i3 < 0) {
        cc[j] = double.nan;
        cc[j | 1] = double.nan;
        continue;
      }
      final t1 = i1 << 1;
      final t2 = i2 << 1;
      final t3 = i3 << 1;
      final x1 = points[t1];
      final y1 = points[t1 | 1];
      final x2 = points[t2];
      final y2 = points[t2 | 1];
      final x3 = points[t3];
      final y3 = points[t3 | 1];

      final dx = x2 - x1;
      final dy = y2 - y1;
      final ex = x3 - x1;
      final ey = y3 - y1;
      final ab = (dx * ey - dy * ex) * 2;

      double x;
      double y;
      if (ab.abs() < 1e-9) {
        if (!hasBarycenter) {
          var sx = 0.0;
          var sy = 0.0;
          for (var k = 0; k < hull.length; ++k) {
            final hi = hull[k] << 1;
            sx += points[hi];
            sy += points[hi | 1];
          }
          bx = sx / hull.length;
          by = sy / hull.length;
          hasBarycenter = true;
        }
        final a = 1e9 * ((bx - x1) * ey - (by - y1) * ex).sign;
        x = (x1 + x3) * 0.5 - a * ey;
        y = (y1 + y3) * 0.5 + a * ex;
      } else {
        final d = 1.0 / ab;
        final bl = dx * dx + dy * dy;
        final cl = ex * ex + ey * ey;
        x = x1 + (ey * bl - dy * cl) * d;
        y = y1 + (dx * cl - ex * bl) * d;
      }
      cc[j] = x;
      cc[j | 1] = y;
    }

    // Compute exterior cell rays.
    vectors.fillRange(0, vectors.length, 0);
    final hullLen = hull.length;
    if (hullLen == 0) return;
    var h = hull[hullLen - 1];
    int p0;
    var p1 = h << 2;
    double x0;
    var x1 = points[h << 1];
    double y0;
    var y1 = points[(h << 1) | 1];
    for (var i = 0; i < hullLen; ++i) {
      h = hull[i];
      p0 = p1;
      x0 = x1;
      y0 = y1;
      p1 = h << 2;
      x1 = points[h << 1];
      y1 = points[(h << 1) | 1];
      vectors[p0 + 2] = vectors[p1] = y0 - y1;
      vectors[p0 + 3] = vectors[p1 + 1] = x1 - x0;
    }
  }

  /// `voronoi.js:79` `render(context)`: renders the mesh of Voronoi cell edges
  /// clipped to the viewport into [context].
  void render(CanvasPath context) {
    final halfedges = delaunay.halfedges;
    final inedges = delaunay.inedges;
    final hull = delaunay.hull;
    final hullLen = hull.length;
    if (hullLen <= 1) return;
    final cc = circumcenters;
    final vec = vectors;
    for (var i = 0, n = halfedges.length; i < n; ++i) {
      final j = halfedges[i];
      if (j < i) continue;
      final ti = (i ~/ 3) << 1;
      final tj = (j ~/ 3) << 1;
      _renderSegment(cc[ti], cc[ti | 1], cc[tj], cc[tj | 1], context);
    }
    int h0;
    var h1 = hull[hullLen - 1];
    for (var i = 0; i < hullLen; ++i) {
      h0 = h1;
      h1 = hull[i];
      final t = (inedges[h1] ~/ 3) << 1;
      final x = cc[t];
      final y = cc[t | 1];
      final v = h0 << 2;
      if (_projectInto(x, y, vec[v + 2], vec[v + 3])) {
        _renderSegment(x, y, _px, _py, context);
      }
    }
  }

  /// Renders the Voronoi mesh as an SVG path string, or `null` if empty.
  String? renderToSvg() {
    if (delaunay.hull.length <= 1) return null;
    final buffer = Path();
    render(buffer);
    final s = buffer.toString();
    return s.isEmpty ? null : s;
  }

  /// `voronoi.js:106` `renderBounds(context)`: renders the viewport bounds
  /// rectangle into [context].
  void renderBounds(CanvasPath context) {
    context.rect(xmin, ymin, xmax - xmin, ymax - ymin);
  }

  /// Renders the viewport bounds rectangle as an SVG path string.
  String? renderBoundsToSvg() {
    final buffer = Path();
    renderBounds(buffer);
    final s = buffer.toString();
    return s.isEmpty ? null : s;
  }

  /// `voronoi.js:111` `renderCell(i, context)`: renders the clipped Voronoi
  /// cell for point [i] into [context]. Does nothing if point [i] has no
  /// visible cell (e.g. coincident or outside bounds).
  void renderCell(int i, CanvasPath context) {
    final len = _clipInto(i);
    if (len <= 0) return;
    final pts = _clipBuf;
    final x0 = pts[0];
    final y0 = pts[1];
    context.moveTo(x0, y0);
    var n = len;
    while (n > 1 && x0 == pts[n - 2] && y0 == pts[n - 1]) {
      n -= 2;
    }
    for (var k = 2; k < n; k += 2) {
      if (pts[k] != pts[k - 2] || pts[k + 1] != pts[k - 1]) {
        context.lineTo(pts[k], pts[k + 1]);
      }
    }
    context.closePath();
  }

  /// Renders the clipped Voronoi cell for point [i] as an SVG path string, or
  /// `null` if point [i] has no visible cell.
  String? renderCellToSvg(int i) {
    final buffer = Path();
    renderCell(i, buffer);
    final s = buffer.toString();
    return s.isEmpty ? null : s;
  }

  /// `voronoi.js:125` `cellPolygons()`: yields the non-empty closed polygon
  /// for each visible Voronoi cell.
  Iterable<List<(double, double)>> cellPolygons() sync* {
    final n = delaunay.points.length >> 1;
    for (var i = 0; i < n; ++i) {
      final cell = cellPolygon(i);
      if (cell != null) yield cell;
    }
  }

  /// Yields `(index, polygon)` records for each visible Voronoi cell (typed
  /// replacement for upstream JS `cell.index = i`).
  Iterable<({int index, List<(double, double)> polygon})>
  cellPolygonsIndexed() sync* {
    final n = delaunay.points.length >> 1;
    for (var i = 0; i < n; ++i) {
      final cell = cellPolygon(i);
      if (cell != null) yield (index: i, polygon: cell);
    }
  }

  /// `voronoi.js:132` `cellPolygon(i)`: returns the closed clipped polygon for
  /// point [i], or `null` if point [i] has no visible cell.
  List<(double, double)>? cellPolygon(int i) {
    final len = _clipInto(i);
    if (len <= 0) return null;
    final pts = _clipBuf;
    final x0 = pts[0];
    final y0 = pts[1];
    var n = len;
    while (n > 1 && x0 == pts[n - 2] && y0 == pts[n - 1]) {
      n -= 2;
    }
    // Count distinct consecutive points so we allocate exact fixed length.
    var count = 1;
    for (var k = 2; k < n; k += 2) {
      if (pts[k] != pts[k - 2] || pts[k + 1] != pts[k - 1]) {
        ++count;
      }
    }
    final first = (x0, y0);
    final out = List<(double, double)>.filled(count + 1, first);
    var outIdx = 1;
    for (var k = 2; k < n; k += 2) {
      if (pts[k] != pts[k - 2] || pts[k + 1] != pts[k - 1]) {
        out[outIdx++] = (pts[k], pts[k + 1]);
      }
    }
    out[outIdx] = first;
    return out;
  }

  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:tryInline')
  void _renderSegment(
    double x0,
    double y0,
    double x1,
    double y1,
    CanvasPath context,
  ) {
    final c0 = _regioncode(x0, y0);
    final c1 = _regioncode(x1, y1);
    if (c0 == 0 && c1 == 0) {
      context
        ..moveTo(x0, y0)
        ..lineTo(x1, y1);
    } else if (_clipSegmentInto(x0, y0, x1, y1, c0, c1)) {
      context
        ..moveTo(_sx0, _sy0)
        ..lineTo(_sx1, _sy1);
    }
  }

  /// `voronoi.js:149` `contains(i, x, y)`: returns `true` if the Voronoi cell
  /// with index [i] contains `(x, y)`.
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:tryInline')
  bool contains(int i, double x, double y) {
    if (x.isNaN || y.isNaN) return false;
    return delaunay.step(i, x, y) == i;
  }

  /// `voronoi.js:153` `neighbors(i)`: yields the indices of Voronoi cells that
  /// share a clipped edge with cell [i].
  Iterable<int> neighbors(int i) sync* {
    final li = _clipInto(i);
    if (li <= 0) return;
    // Copy cell i's clipped vertices because _clipInto(j) reuses _clipBuf.
    final ci = Float64List(li)..setRange(0, li, _clipBuf);
    for (final j in delaunay.neighbors(i)) {
      final lj = _clipInto(j);
      if (lj <= 0) continue;
      final cj = _clipBuf;
      var found = false;
      for (var ai = 0; ai < li && !found; ai += 2) {
        final ai2 = ai + 2 == li ? 0 : ai + 2;
        final cix0 = ci[ai];
        final ciy0 = ci[ai + 1];
        final cix1 = ci[ai2];
        final ciy1 = ci[ai2 + 1];
        for (var aj = 0; aj < lj; aj += 2) {
          if (cix0 == cj[aj] && ciy0 == cj[aj + 1]) {
            final ajPrev = aj == 0 ? lj - 2 : aj - 2;
            if (cix1 == cj[ajPrev] && ciy1 == cj[ajPrev + 1]) {
              yield j;
              found = true;
              break;
            }
          }
        }
      }
    }
  }

  int _cellInto(int i) {
    final cc = circumcenters;
    final inedges = delaunay.inedges;
    final halfedges = delaunay.halfedges;
    final triangles = delaunay.triangles;
    final e0 = inedges[i];
    if (e0 == -1) return -1; // coincident point
    var buf = _cellBuf;
    var len = 0;
    var e = e0;
    do {
      final t = (e ~/ 3) << 1;
      if (len + 2 > buf.length) {
        final next = Float64List(buf.length << 1)..setRange(0, len, buf);
        buf = _cellBuf = next;
      }
      buf[len++] = cc[t];
      buf[len++] = cc[t | 1];
      e = _nextHalfedge(e);
      if (triangles[e] != i) break; // bad triangulation
      e = halfedges[e];
    } while (e != e0 && e != -1);
    return len;
  }

  void _ensureClipCapacity(int needed) {
    if (needed <= _clipBuf.length) return;
    var cap = _clipBuf.length;
    while (cap < needed) {
      cap <<= 1;
    }
    _clipBuf = Float64List(cap)..setRange(0, _clipBuf.length, _clipBuf);
  }

  /// Clips cell [i] into `_clipBuf`, returning the number of doubles (`<= 0`
  /// when the cell is empty / coincident).
  int _clipInto(int i) {
    // degenerate case (1 valid point: return the box)
    if (i == 0 && delaunay.hull.length == 1) {
      final buf = _clipBuf;
      buf[0] = xmax;
      buf[1] = ymin;
      buf[2] = xmax;
      buf[3] = ymax;
      buf[4] = xmin;
      buf[5] = ymax;
      buf[6] = xmin;
      buf[7] = ymin;
      return 8;
    }
    final cellLen = _cellInto(i);
    if (cellLen <= 0) return -1;
    final vec = vectors;
    final v = i << 2;
    final len = vec[v] != 0 || vec[v + 1] != 0
        ? _clipInfiniteInto(
            i,
            _cellBuf,
            cellLen,
            vec[v],
            vec[v + 1],
            vec[v + 2],
            vec[v + 3],
          )
        : _clipFiniteInto(i, _cellBuf, cellLen);
    return _simplifyInPlace(len);
  }

  int _clipFiniteInto(int i, Float64List points, int n) {
    var len = 0;
    var x1 = points[n - 2];
    var y1 = points[n - 1];
    var c1 = _regioncode(x1, y1);
    var e1 = 0;
    for (var j = 0; j < n; j += 2) {
      final x0 = x1;
      final y0 = y1;
      x1 = points[j];
      y1 = points[j + 1];
      final c0 = c1;
      c1 = _regioncode(x1, y1);
      if (c0 == 0 && c1 == 0) {
        e1 = 0;
        _ensureClipCapacity(len + 2);
        _clipBuf[len++] = x1;
        _clipBuf[len++] = y1;
      } else {
        double sx0;
        double sy0;
        double sx1;
        double sy1;
        if (c0 == 0) {
          if (!_clipSegmentInto(x0, y0, x1, y1, c0, c1)) continue;
          sx0 = _sx0;
          sy0 = _sy0;
          sx1 = _sx1;
          sy1 = _sy1;
        } else {
          if (!_clipSegmentInto(x1, y1, x0, y0, c1, c0)) continue;
          sx1 = _sx0;
          sy1 = _sy0;
          sx0 = _sx1;
          sy0 = _sy1;
          final e0 = e1;
          e1 = _edgecode(sx0, sy0);
          if (e0 != 0 && e1 != 0 && len > 0) {
            len = _edgeAppend(i, e0, e1, len);
          }
          _ensureClipCapacity(len + 2);
          _clipBuf[len++] = sx0;
          _clipBuf[len++] = sy0;
        }
        final e0 = e1;
        e1 = _edgecode(sx1, sy1);
        if (e0 != 0 && e1 != 0 && len > 0) {
          len = _edgeAppend(i, e0, e1, len);
        }
        _ensureClipCapacity(len + 2);
        _clipBuf[len++] = sx1;
        _clipBuf[len++] = sy1;
      }
    }
    if (len > 0) {
      final e0 = e1;
      e1 = _edgecode(_clipBuf[0], _clipBuf[1]);
      if (e0 != 0 && e1 != 0) len = _edgeAppend(i, e0, e1, len);
      return len;
    } else if (contains(i, (xmin + xmax) * 0.5, (ymin + ymax) * 0.5)) {
      final buf = _clipBuf;
      buf[0] = xmax;
      buf[1] = ymin;
      buf[2] = xmax;
      buf[3] = ymax;
      buf[4] = xmin;
      buf[5] = ymax;
      buf[6] = xmin;
      buf[7] = ymin;
      return 8;
    }
    return -1;
  }

  bool _clipSegmentInto(
    double x0,
    double y0,
    double x1,
    double y1,
    int c0,
    int c1,
  ) {
    final flip = c0 < c1;
    var ax = x0;
    var ay = y0;
    var bx = x1;
    var by = y1;
    var ca = c0;
    var cb = c1;
    if (flip) {
      ax = x1;
      ay = y1;
      bx = x0;
      by = y0;
      ca = c1;
      cb = c0;
    }
    while (true) {
      if (ca == 0 && cb == 0) {
        if (flip) {
          _sx0 = bx;
          _sy0 = by;
          _sx1 = ax;
          _sy1 = ay;
        } else {
          _sx0 = ax;
          _sy0 = ay;
          _sx1 = bx;
          _sy1 = by;
        }
        return true;
      }
      if ((ca & cb) != 0) return false;
      double x;
      double y;
      final c = ca != 0 ? ca : cb;
      if ((c & 0x8) != 0) {
        x = ax + (bx - ax) * (ymax - ay) / (by - ay);
        y = ymax;
      } else if ((c & 0x4) != 0) {
        x = ax + (bx - ax) * (ymin - ay) / (by - ay);
        y = ymin;
      } else if ((c & 0x2) != 0) {
        y = ay + (by - ay) * (xmax - ax) / (bx - ax);
        x = xmax;
      } else {
        y = ay + (by - ay) * (xmin - ax) / (bx - ax);
        x = xmin;
      }
      if (ca != 0) {
        ax = x;
        ay = y;
        ca = _regioncode(ax, ay);
      } else {
        bx = x;
        by = y;
        cb = _regioncode(bx, by);
      }
    }
  }

  int _clipInfiniteInto(
    int i,
    Float64List points,
    int n,
    double vx0,
    double vy0,
    double vxn,
    double vyn,
  ) {
    final needed = n + 4;
    if (needed > _workBuf.length) {
      var cap = _workBuf.length;
      while (cap < needed) {
        cap <<= 1;
      }
      _workBuf = Float64List(cap);
    }
    final work = _workBuf;
    var wLen = 0;
    if (_projectInto(points[0], points[1], vx0, vy0)) {
      work[wLen++] = _px;
      work[wLen++] = _py;
    }
    work.setRange(wLen, wLen + n, points);
    wLen += n;
    if (_projectInto(work[wLen - 2], work[wLen - 1], vxn, vyn)) {
      work[wLen++] = _px;
      work[wLen++] = _py;
    }

    var len = _clipFiniteInto(i, work, wLen);
    if (len > 0) {
      var c1 = _edgecode(_clipBuf[len - 2], _clipBuf[len - 1]);
      for (var j = 0; j < len; j += 2) {
        final c0 = c1;
        c1 = _edgecode(_clipBuf[j], _clipBuf[j + 1]);
        if (c0 != 0 && c1 != 0) {
          final inserted = _edgeInsert(i, c0, c1, j, len);
          j += inserted;
          len += inserted;
        }
      }
    } else if (contains(i, (xmin + xmax) * 0.5, (ymin + ymax) * 0.5)) {
      final buf = _clipBuf;
      buf[0] = xmin;
      buf[1] = ymin;
      buf[2] = xmax;
      buf[3] = ymin;
      buf[4] = xmax;
      buf[5] = ymax;
      buf[6] = xmin;
      buf[7] = ymax;
      len = 8;
    }
    return len;
  }

  /// Appends corner vertices along bounds edges at the end of `_clipBuf`.
  int _edgeAppend(int i, int e0, int e1, int len) {
    var cur = e0;
    var outLen = len;
    while (cur != e1) {
      double x;
      double y;
      switch (cur) {
        case 0x5:
          cur = 0x4;
          continue;
        case 0x4:
          cur = 0x6;
          x = xmax;
          y = ymin;
        case 0x6:
          cur = 0x2;
          continue;
        case 0x2:
          cur = 0xA;
          x = xmax;
          y = ymax;
        case 0xA:
          cur = 0x8;
          continue;
        case 0x8:
          cur = 0x9;
          x = xmin;
          y = ymax;
        case 0x9:
          cur = 0x1;
          continue;
        case 0x1:
          cur = 0x5;
          x = xmin;
          y = ymin;
        default:
          return outLen;
      }
      if (contains(i, x, y)) {
        _ensureClipCapacity(outLen + 2);
        _clipBuf[outLen++] = x;
        _clipBuf[outLen++] = y;
      }
    }
    return outLen;
  }

  /// Inserts corner vertices into `_clipBuf` at [j], returning the count of
  /// doubles inserted (`2 * corners`).
  int _edgeInsert(int i, int e0, int e1, int j, int len) {
    var cur = e0;
    var idx = j;
    var curLen = len;
    while (cur != e1) {
      double x;
      double y;
      switch (cur) {
        case 0x5:
          cur = 0x4;
          continue;
        case 0x4:
          cur = 0x6;
          x = xmax;
          y = ymin;
        case 0x6:
          cur = 0x2;
          continue;
        case 0x2:
          cur = 0xA;
          x = xmax;
          y = ymax;
        case 0xA:
          cur = 0x8;
          continue;
        case 0x8:
          cur = 0x9;
          x = xmin;
          y = ymax;
        case 0x9:
          cur = 0x1;
          continue;
        case 0x1:
          cur = 0x5;
          x = xmin;
          y = ymin;
        default:
          return curLen - len;
      }
      if ((idx >= curLen || _clipBuf[idx] != x || _clipBuf[idx + 1] != y) &&
          contains(i, x, y)) {
        _ensureClipCapacity(curLen + 2);
        final buf = _clipBuf;
        for (var m = curLen - 1; m >= idx; --m) {
          buf[m + 2] = buf[m];
        }
        buf[idx] = x;
        buf[idx + 1] = y;
        idx += 2;
        curLen += 2;
      }
    }
    return curLen - len;
  }

  bool _projectInto(double x0, double y0, double vx, double vy) {
    var t = double.infinity;
    double c;
    var x = double.nan;
    var y = double.nan;
    if (vy < 0) {
      // top
      if (y0 <= ymin) return false;
      if ((c = (ymin - y0) / vy) < t) {
        y = ymin;
        t = c;
        x = x0 + t * vx;
      }
    } else if (vy > 0) {
      // bottom
      if (y0 >= ymax) return false;
      if ((c = (ymax - y0) / vy) < t) {
        y = ymax;
        t = c;
        x = x0 + t * vx;
      }
    }
    if (vx > 0) {
      // right
      if (x0 >= xmax) return false;
      if ((c = (xmax - x0) / vx) < t) {
        x = xmax;
        t = c;
        y = y0 + t * vy;
      }
    } else if (vx < 0) {
      // left
      if (x0 <= xmin) return false;
      if ((c = (xmin - x0) / vx) < t) {
        x = xmin;
        t = c;
        y = y0 + t * vy;
      }
    }
    _px = x;
    _py = y;
    return true;
  }

  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:tryInline')
  int _edgecode(double x, double y) =>
      (x == xmin
          ? 0x1
          : x == xmax
          ? 0x2
          : 0x0) |
      (y == ymin
          ? 0x4
          : y == ymax
          ? 0x8
          : 0x0);

  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:tryInline')
  int _regioncode(double x, double y) =>
      (x < xmin
          ? 0x1
          : x > xmax
          ? 0x2
          : 0x0) |
      (y < ymin
          ? 0x4
          : y > ymax
          ? 0x8
          : 0x0);

  int _simplifyInPlace(int len) {
    if (len > 4) {
      final p = _clipBuf;
      var curLen = len;
      for (var i = 0; i < curLen; i += 2) {
        final j = i + 2 < curLen ? i + 2 : 0;
        final k = j + 2 < curLen ? j + 2 : 0;
        if (p[i] == p[j] && p[j] == p[k] ||
            p[i + 1] == p[j + 1] && p[j + 1] == p[k + 1]) {
          for (var m = j; m < curLen - 2; ++m) {
            p[m] = p[m + 2];
          }
          curLen -= 2;
          i -= 2;
          if (curLen <= 0) return -1;
        }
      }
      return curLen;
    }
    return len;
  }
}
