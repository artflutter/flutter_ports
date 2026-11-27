// Ported from d3-contour v4.0.2 src/contours.js (ISC, Mike Bostock).

/// Port of `src/contours.js` of d3-contour 4.0.2: [contours], [Contours], and
/// [ContourMultiPolygon].
library;

import 'dart:typed_data';

import 'package:flutter_d3_array_port/d3_array.dart'
    show nice, thresholdSturges, ticks;
import 'package:flutter_d3_contour_port/src/array.dart';
import 'package:flutter_d3_contour_port/src/ascending.dart';
import 'package:flutter_d3_contour_port/src/contains.dart';

/// A 2D planar vertex `(x, y)` in a contour ring.
typedef ContourPoint = (double, double);

/// A closed contour ring of 2D planar vertices.
typedef ContourRing = List<(double, double)>;

/// A polygon consisting of an exterior ring followed by zero or more hole
/// rings.
typedef ContourPolygon = List<List<(double, double)>>;

/// Callback computing an approximate threshold count from grid values.
typedef ContourThresholdsCount = int Function(List<double> values);

/// Callback computing explicit threshold values from grid values.
typedef ContourThresholdsValues = List<double> Function(List<double> values);

/// A typed GeoJSON `MultiPolygon` contour geometry for a scalar [value].
// DIVERGES(d3-contour): adapt-contour-typed-api, typed ContourMultiPolygon
// class with `(double, double)` vertex records and `toGeoJson()` helper instead
// of untyped JS object `{type, value, coordinates}`.
final class ContourMultiPolygon({
  /// The threshold value represented by this contour geometry.
  required final double value,

  /// MultiPolygon coordinates: polygons → rings (exterior then holes) → points.
  required final List<List<List<(double, double)>>> coordinates,
}) {
  /// Creates a [ContourMultiPolygon] for threshold [value] and [coordinates].
  this;

  /// The GeoJSON geometry type (`'MultiPolygon'`).
  String get type => 'MultiPolygon';

  /// Converts this contour to a GeoJSON-compatible `Map<String, Object>`.
  Map<String, Object> toGeoJson() => <String, Object>{
    'type': type,
    'value': value,
    'coordinates': <List<List<List<double>>>>[
      for (final polygon in coordinates)
        <List<List<double>>>[
          for (final ring in polygon)
            <List<double>>[
              for (final (x, y) in ring) <double>[x, y],
            ],
        ],
    ],
  };

  @override
  String toString() =>
      'ContourMultiPolygon(value: $value, polygons: ${coordinates.length})';
}

int _defaultThresholdsCount(List<double> values) => thresholdSturges(values);

@pragma('vm:prefer-inline')
double _valid(double v) => v.isNaN ? double.negativeInfinity : v;

@pragma('vm:prefer-inline')
double _smooth1(double x, double v0, double v1, double value) {
  final a = value - v0;
  final b = v1 - v0;
  final d = a.isFinite || b.isFinite ? a / b : a.sign / b.sign;
  return d.isNaN ? x : x + d - 0.5;
}

/// Computes the finite `(min, max)` extent of [values] without allocating a
/// lazy `MappedIterable` or boxing nullable doubles.
(double, double)? _finiteExtent(List<double> values) {
  final n = values.length;
  var lo = double.infinity;
  var hi = double.negativeInfinity;
  var found = false;
  if (values is Float64List) {
    for (var i = 0; i < n; ++i) {
      final v = values[i];
      if (v.isFinite) {
        if (!found) {
          lo = hi = v;
          found = true;
        } else {
          if (v < lo) lo = v;
          if (v > hi) hi = v;
        }
      }
    }
  } else {
    for (var i = 0; i < n; ++i) {
      final v = values[i];
      if (v.isFinite) {
        if (!found) {
          lo = hi = v;
          found = true;
        } else {
          if (v < lo) lo = v;
          if (v > hi) hi = v;
        }
      }
    }
  }
  return found ? (lo, hi) : null;
}

/// Reusable flat-array workspace for marching-squares fragment stitching and
/// polygon hole assignment.
///
/// Stores open fragments on the active 2-row horizontal + 2-slot vertical
/// frontier in `Int32List`s of length `2 * (dx + 1) + 2`, and stores fragment
/// chains in growable pooled `Int32List`s (`nodeHx`, `nodeHy`, `nodeNext`),
/// eliminating all `HashMap`, per-segment list/record, `insert(0)`, and
/// `concat` allocations during marching squares.
// DIVERGES(d3-contour): adapt-contour-fast-forms, flat Int32List frontier +
// pooled linked-list fragment stitcher with fused smoothLinear, affine
// transform, signed area, and bounding-box hole pre-rejection.
final class _StitchWorkspace(int dx) {
  final int _dx = dx;
  final int _stride = dx + 1;
  final Int32List _slotStart = Int32List((dx + 1) * 2 + 2)
    ..fillRange(0, (dx + 1) * 2 + 2, -1);
  final Int32List _slotEnd = Int32List((dx + 1) * 2 + 2)
    ..fillRange(0, (dx + 1) * 2 + 2, -1);

  Int32List _fragHead = Int32List(64);
  Int32List _fragTail = Int32List(64);
  Int32List _fragLen = Int32List(64);
  Int32List _fragEndSlot = Int32List(64);
  int _fragCount = 0;

  Int32List _nodeHx = Int32List(256);
  Int32List _nodeHy = Int32List(256);
  Int32List _nodeNext = Int32List(256);
  int _nodeCount = 0;

  // Current threshold pass state (avoids 19-parameter calls per cell).
  List<double> _values = const <double>[];
  Float64List? _f64Values;
  int _dy = 0;
  double _value = 0;
  bool _smooth = true;
  double _scale = 1;
  double _offset = 0;
  bool _applyTransform = false;
  List<ContourPolygon> _polygons = <ContourPolygon>[];
  List<double> _polyBbox = <double>[];
  List<ContourRing> _holes = <ContourRing>[];
  List<double> _holeBbox = <double>[];

  void _reset() {
    _fragCount = 0;
    _nodeCount = 0;
  }

  void _growFrags() {
    final nextCap = _fragHead.length << 1;
    _fragHead = Int32List(nextCap)..setRange(0, _fragCount, _fragHead);
    _fragTail = Int32List(nextCap)..setRange(0, _fragCount, _fragTail);
    _fragLen = Int32List(nextCap)..setRange(0, _fragCount, _fragLen);
    _fragEndSlot = Int32List(nextCap)..setRange(0, _fragCount, _fragEndSlot);
  }

  void _growNodes() {
    final nextCap = _nodeHx.length << 1;
    _nodeHx = Int32List(nextCap)..setRange(0, _nodeCount, _nodeHx);
    _nodeHy = Int32List(nextCap)..setRange(0, _nodeCount, _nodeHy);
    _nodeNext = Int32List(nextCap)..setRange(0, _nodeCount, _nodeNext);
  }

  @pragma('vm:prefer-inline')
  int _allocNode(int hx, int hy, int next) {
    var id = _nodeCount;
    if (id == _nodeHx.length) {
      _growNodes();
      id = _nodeCount;
    }
    _nodeCount = id + 1;
    _nodeHx[id] = hx;
    _nodeHy[id] = hy;
    _nodeNext[id] = next;
    return id;
  }

  @pragma('vm:prefer-inline')
  int _allocFrag(int head, int tail, int len, int endSlot) {
    var id = _fragCount;
    if (id == _fragHead.length) {
      _growFrags();
      id = _fragCount;
    }
    _fragCount = id + 1;
    _fragHead[id] = head;
    _fragTail[id] = tail;
    _fragLen[id] = len;
    _fragEndSlot[id] = endSlot;
    return id;
  }

  @pragma('vm:prefer-inline')
  int _stitch(
    int startSlot,
    int endSlot,
    int startHx,
    int startHy,
    int endHx,
    int endHy,
  ) {
    final slotStart = _slotStart;
    final slotEnd = _slotEnd;
    final f = slotEnd[startSlot];
    if (f != -1) {
      final g = slotStart[endSlot];
      if (g != -1) {
        slotEnd[startSlot] = -1;
        slotStart[endSlot] = -1;
        if (f == g) {
          return f;
        }
        _nodeNext[_fragTail[f]] = _fragHead[g];
        _fragTail[f] = _fragTail[g];
        _fragLen[f] += _fragLen[g];
        final gEndSlot = _fragEndSlot[g];
        _fragEndSlot[f] = gEndSlot;
        slotEnd[gEndSlot] = f;
        return -1;
      }
      slotEnd[startSlot] = -1;
      final nId = _allocNode(endHx, endHy, -1);
      _nodeNext[_fragTail[f]] = nId;
      _fragTail[f] = nId;
      _fragLen[f] += 1;
      _fragEndSlot[f] = endSlot;
      slotEnd[endSlot] = f;
      return -1;
    }
    final g = slotStart[endSlot];
    if (g != -1) {
      slotStart[endSlot] = -1;
      final nId = _allocNode(startHx, startHy, _fragHead[g]);
      _fragHead[g] = nId;
      _fragLen[g] += 1;
      slotStart[startSlot] = g;
      return -1;
    }
    final n1 = _allocNode(endHx, endHy, -1);
    final n0 = _allocNode(startHx, startHy, n1);
    final frag = _allocFrag(n0, n1, 2, endSlot);
    slotStart[startSlot] = frag;
    slotEnd[endSlot] = frag;
    return -1;
  }

  void _emitRing(int frag) {
    final len = _fragLen[frag];
    final ring = List<ContourPoint>.filled(len + 1, const (0.0, 0.0));
    final nodeHx = _nodeHx;
    final nodeHy = _nodeHy;
    final nodeNext = _nodeNext;
    final dx = _dx;
    final dy = _dy;
    final value = _value;
    final scale = _scale;
    final offset = _offset;
    final applyTransform = _applyTransform;

    var cur = _fragHead[frag];
    var i = 0;
    var firstX = 0.0;
    var firstY = 0.0;
    var prevX = 0.0;
    var prevY = 0.0;
    var area = 0.0;
    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = double.negativeInfinity;
    var maxY = double.negativeInfinity;

    if (_smooth) {
      final f64Values = _f64Values;
      if (f64Values != null) {
        while (cur != -1) {
          final hx = nodeHx[cur];
          final hy = nodeHy[cur];
          double px;
          double py;
          if ((hx & 1) == 0) {
            final xt = hx >> 1;
            py = hy * 0.5;
            if (xt > 0 && xt < dx) {
              final idx = (hy >> 1) * dx + xt;
              final v1 = _valid(f64Values[idx]);
              px = _smooth1(
                xt.toDouble(),
                _valid(f64Values[idx - 1]),
                v1,
                value,
              );
            } else {
              px = xt.toDouble();
            }
          } else {
            px = hx * 0.5;
            final yt = hy >> 1;
            if ((hy & 1) == 0 && yt > 0 && yt < dy) {
              final idx = yt * dx + (hx >> 1);
              final v1 = _valid(f64Values[idx]);
              py = _smooth1(
                yt.toDouble(),
                _valid(f64Values[idx - dx]),
                v1,
                value,
              );
            } else {
              py = hy * 0.5;
            }
          }
          if (applyTransform) {
            px = px * scale - offset;
            py = py * scale - offset;
          }
          ring[i] = (px, py);
          if (i == 0) {
            firstX = px;
            firstY = py;
            minX = maxX = px;
            minY = maxY = py;
          } else {
            area += prevY * px - prevX * py;
            if (px < minX) minX = px;
            if (px > maxX) maxX = px;
            if (py < minY) minY = py;
            if (py > maxY) maxY = py;
          }
          prevX = px;
          prevY = py;
          ++i;
          cur = nodeNext[cur];
        }
      } else {
        final values = _values;
        while (cur != -1) {
          final hx = nodeHx[cur];
          final hy = nodeHy[cur];
          double px;
          double py;
          if ((hx & 1) == 0) {
            final xt = hx >> 1;
            py = hy * 0.5;
            if (xt > 0 && xt < dx) {
              final idx = (hy >> 1) * dx + xt;
              final v1 = _valid(values[idx]);
              px = _smooth1(xt.toDouble(), _valid(values[idx - 1]), v1, value);
            } else {
              px = xt.toDouble();
            }
          } else {
            px = hx * 0.5;
            final yt = hy >> 1;
            if ((hy & 1) == 0 && yt > 0 && yt < dy) {
              final idx = yt * dx + (hx >> 1);
              final v1 = _valid(values[idx]);
              py = _smooth1(yt.toDouble(), _valid(values[idx - dx]), v1, value);
            } else {
              py = hy * 0.5;
            }
          }
          if (applyTransform) {
            px = px * scale - offset;
            py = py * scale - offset;
          }
          ring[i] = (px, py);
          if (i == 0) {
            firstX = px;
            firstY = py;
            minX = maxX = px;
            minY = maxY = py;
          } else {
            area += prevY * px - prevX * py;
            if (px < minX) minX = px;
            if (px > maxX) maxX = px;
            if (py < minY) minY = py;
            if (py > maxY) maxY = py;
          }
          prevX = px;
          prevY = py;
          ++i;
          cur = nodeNext[cur];
        }
      }
    } else {
      while (cur != -1) {
        var px = nodeHx[cur] * 0.5;
        var py = nodeHy[cur] * 0.5;
        if (applyTransform) {
          px = px * scale - offset;
          py = py * scale - offset;
        }
        ring[i] = (px, py);
        if (i == 0) {
          firstX = px;
          firstY = py;
          minX = maxX = px;
          minY = maxY = py;
        } else {
          area += prevY * px - prevX * py;
          if (px < minX) minX = px;
          if (px > maxX) maxX = px;
          if (py < minY) minY = py;
          if (py > maxY) maxY = py;
        }
        prevX = px;
        prevY = py;
        ++i;
        cur = nodeNext[cur];
      }
    }

    ring[len] = (firstX, firstY);
    area += prevY * firstX - prevX * firstY;

    if (area > 0) {
      _polygons.add(<ContourRing>[ring]);
      _polyBbox
        ..add(minX)
        ..add(minY)
        ..add(maxX)
        ..add(maxY);
    } else {
      _holes.add(ring);
      _holeBbox
        ..add(minX)
        ..add(minY)
        ..add(maxX)
        ..add(maxY);
    }
  }

  @pragma('vm:prefer-inline')
  void _emitCell(
    int mask,
    int x,
    int y,
    int topBase,
    int botBase,
    int vertBase,
  ) {
    final col = x + 1;
    final topSlot = topBase + col;
    final botSlot = botBase + col;
    final leftSlot = vertBase + (x & 1);
    final rightSlot = vertBase + ((x + 1) & 1);
    final hx2 = x << 1;
    final hy2 = y << 1;

    int closed;
    switch (mask) {
      case 1:
        closed = _stitch(botSlot, leftSlot, hx2 + 2, hy2 + 3, hx2 + 1, hy2 + 2);
      case 2:
        closed = _stitch(
          rightSlot,
          botSlot,
          hx2 + 3,
          hy2 + 2,
          hx2 + 2,
          hy2 + 3,
        );
      case 3:
        closed = _stitch(
          rightSlot,
          leftSlot,
          hx2 + 3,
          hy2 + 2,
          hx2 + 1,
          hy2 + 2,
        );
      case 4:
        closed = _stitch(
          topSlot,
          rightSlot,
          hx2 + 2,
          hy2 + 1,
          hx2 + 3,
          hy2 + 2,
        );
      case 5:
        final c1 = _stitch(
          botSlot,
          leftSlot,
          hx2 + 2,
          hy2 + 3,
          hx2 + 1,
          hy2 + 2,
        );
        if (c1 != -1) _emitRing(c1);
        closed = _stitch(
          topSlot,
          rightSlot,
          hx2 + 2,
          hy2 + 1,
          hx2 + 3,
          hy2 + 2,
        );
      case 6:
        closed = _stitch(topSlot, botSlot, hx2 + 2, hy2 + 1, hx2 + 2, hy2 + 3);
      case 7:
        closed = _stitch(topSlot, leftSlot, hx2 + 2, hy2 + 1, hx2 + 1, hy2 + 2);
      case 8:
        closed = _stitch(leftSlot, topSlot, hx2 + 1, hy2 + 2, hx2 + 2, hy2 + 1);
      case 9:
        closed = _stitch(botSlot, topSlot, hx2 + 2, hy2 + 3, hx2 + 2, hy2 + 1);
      case 10:
        final c1 = _stitch(
          leftSlot,
          topSlot,
          hx2 + 1,
          hy2 + 2,
          hx2 + 2,
          hy2 + 1,
        );
        if (c1 != -1) _emitRing(c1);
        closed = _stitch(
          rightSlot,
          botSlot,
          hx2 + 3,
          hy2 + 2,
          hx2 + 2,
          hy2 + 3,
        );
      case 11:
        closed = _stitch(
          rightSlot,
          topSlot,
          hx2 + 3,
          hy2 + 2,
          hx2 + 2,
          hy2 + 1,
        );
      case 12:
        closed = _stitch(
          leftSlot,
          rightSlot,
          hx2 + 1,
          hy2 + 2,
          hx2 + 3,
          hy2 + 2,
        );
      case 13:
        closed = _stitch(
          botSlot,
          rightSlot,
          hx2 + 2,
          hy2 + 3,
          hx2 + 3,
          hy2 + 2,
        );
      case 14:
        closed = _stitch(leftSlot, botSlot, hx2 + 1, hy2 + 2, hx2 + 2, hy2 + 3);
      default:
        return;
    }
    if (closed != -1) _emitRing(closed);
  }

  /// Runs marching squares and hole assignment for a single threshold [value].
  ContourMultiPolygon buildContour({
    required List<double> values,
    required int dy,
    required double value,
    required double outputValue,
    required bool smooth,
    double scale = 1,
    double offset = 0,
    bool applyTransform = false,
  }) {
    final polygons = <ContourPolygon>[];
    final polyBbox = <double>[];
    final holes = <ContourRing>[];
    final holeBbox = <double>[];

    final dx = _dx;
    if (dx > 0 && dy > 0 && values.isNotEmpty) {
      _reset();
      _values = values;
      _f64Values = values is Float64List ? values : null;
      _dy = dy;
      _value = value;
      _smooth = smooth;
      _scale = scale;
      _offset = offset;
      _applyTransform = applyTransform;
      _polygons = polygons;
      _polyBbox = polyBbox;
      _holes = holes;
      _holeBbox = holeBbox;

      final stride = _stride;
      final vertBase = stride << 1;
      final dxMinus1 = dx - 1;
      final dyMinus1 = dy - 1;

      if (values is Float64List) {
        final f64 = values;
        var topBase = stride;
        var botBase = 0;
        var t1 = f64[0] >= value ? 1 : 0;
        var mask = t1 << 1;
        if (mask != 0) _emitCell(mask, -1, -1, topBase, botBase, vertBase);
        for (var x = 0; x < dxMinus1; ++x) {
          final t0 = t1;
          t1 = f64[x + 1] >= value ? 1 : 0;
          mask = t0 | (t1 << 1);
          if (mask != 0) _emitCell(mask, x, -1, topBase, botBase, vertBase);
        }
        if (t1 != 0) _emitCell(t1, dxMinus1, -1, topBase, botBase, vertBase);

        for (var y = 0; y < dyMinus1; ++y) {
          topBase = (y & 1) * stride;
          botBase = ((y + 1) & 1) * stride;
          final rowCurr = y * dx;
          final rowNext = rowCurr + dx;
          t1 = f64[rowNext] >= value ? 1 : 0;
          var t2 = f64[rowCurr] >= value ? 1 : 0;
          mask = (t1 << 1) | (t2 << 2);
          if (mask != 0) _emitCell(mask, -1, y, topBase, botBase, vertBase);
          for (var x = 0; x < dxMinus1; ++x) {
            final t0 = t1;
            t1 = f64[rowNext + x + 1] >= value ? 1 : 0;
            final t3 = t2;
            t2 = f64[rowCurr + x + 1] >= value ? 1 : 0;
            mask = t0 | (t1 << 1) | (t2 << 2) | (t3 << 3);
            if (mask != 0 && mask != 15) {
              _emitCell(mask, x, y, topBase, botBase, vertBase);
            }
          }
          mask = t1 | (t2 << 3);
          if (mask != 0) {
            _emitCell(mask, dxMinus1, y, topBase, botBase, vertBase);
          }
        }

        final lastY = dyMinus1;
        topBase = (lastY & 1) * stride;
        botBase = ((lastY + 1) & 1) * stride;
        final lastRow = lastY * dx;
        var t2 = f64[lastRow] >= value ? 1 : 0;
        mask = t2 << 2;
        if (mask != 0) _emitCell(mask, -1, lastY, topBase, botBase, vertBase);
        for (var x = 0; x < dxMinus1; ++x) {
          final t3 = t2;
          t2 = f64[lastRow + x + 1] >= value ? 1 : 0;
          mask = (t2 << 2) | (t3 << 3);
          if (mask != 0) _emitCell(mask, x, lastY, topBase, botBase, vertBase);
        }
        if (t2 != 0) {
          _emitCell(t2 << 3, dxMinus1, lastY, topBase, botBase, vertBase);
        }
      } else {
        var topBase = stride;
        var botBase = 0;
        var t1 = values[0] >= value ? 1 : 0;
        var mask = t1 << 1;
        if (mask != 0) _emitCell(mask, -1, -1, topBase, botBase, vertBase);
        for (var x = 0; x < dxMinus1; ++x) {
          final t0 = t1;
          t1 = values[x + 1] >= value ? 1 : 0;
          mask = t0 | (t1 << 1);
          if (mask != 0) _emitCell(mask, x, -1, topBase, botBase, vertBase);
        }
        if (t1 != 0) _emitCell(t1, dxMinus1, -1, topBase, botBase, vertBase);

        for (var y = 0; y < dyMinus1; ++y) {
          topBase = (y & 1) * stride;
          botBase = ((y + 1) & 1) * stride;
          final rowCurr = y * dx;
          final rowNext = rowCurr + dx;
          t1 = values[rowNext] >= value ? 1 : 0;
          var t2 = values[rowCurr] >= value ? 1 : 0;
          mask = (t1 << 1) | (t2 << 2);
          if (mask != 0) _emitCell(mask, -1, y, topBase, botBase, vertBase);
          for (var x = 0; x < dxMinus1; ++x) {
            final t0 = t1;
            t1 = values[rowNext + x + 1] >= value ? 1 : 0;
            final t3 = t2;
            t2 = values[rowCurr + x + 1] >= value ? 1 : 0;
            mask = t0 | (t1 << 1) | (t2 << 2) | (t3 << 3);
            if (mask != 0 && mask != 15) {
              _emitCell(mask, x, y, topBase, botBase, vertBase);
            }
          }
          mask = t1 | (t2 << 3);
          if (mask != 0) {
            _emitCell(mask, dxMinus1, y, topBase, botBase, vertBase);
          }
        }

        final lastY = dyMinus1;
        topBase = (lastY & 1) * stride;
        botBase = ((lastY + 1) & 1) * stride;
        final lastRow = lastY * dx;
        var t2 = values[lastRow] >= value ? 1 : 0;
        mask = t2 << 2;
        if (mask != 0) _emitCell(mask, -1, lastY, topBase, botBase, vertBase);
        for (var x = 0; x < dxMinus1; ++x) {
          final t3 = t2;
          t2 = values[lastRow + x + 1] >= value ? 1 : 0;
          mask = (t2 << 2) | (t3 << 3);
          if (mask != 0) _emitCell(mask, x, lastY, topBase, botBase, vertBase);
        }
        if (t2 != 0) {
          _emitCell(t2 << 3, dxMinus1, lastY, topBase, botBase, vertBase);
        }
      }
    }

    final numHoles = holes.length;
    final numPolys = polygons.length;
    for (var h = 0; h < numHoles; ++h) {
      final hBase = h << 2;
      final hMinX = holeBbox[hBase];
      final hMinY = holeBbox[hBase + 1];
      final hMaxX = holeBbox[hBase + 2];
      final hMaxY = holeBbox[hBase + 3];
      final hole = holes[h];
      for (var p = 0; p < numPolys; ++p) {
        final pBase = p << 2;
        if (hMinX < polyBbox[pBase] ||
            hMinY < polyBbox[pBase + 1] ||
            hMaxX > polyBbox[pBase + 2] ||
            hMaxY > polyBbox[pBase + 3]) {
          continue;
        }
        final polygon = polygons[p];
        if (contourContains(polygon[0], hole) != -1) {
          polygon.add(hole);
          break;
        }
      }
    }

    return ContourMultiPolygon(value: outputValue, coordinates: polygons);
  }
}

/// A configurable marching-squares contour polygon generator.
// DIVERGES(d3-contour): adapt-contour-typed-api, typed Contours class with
// separate `thresholdsCount`, `thresholdsValues`, `thresholdsGenerator`, and
// `thresholdsCountGenerator` properties instead of untyped JS union arguments.
final class Contours({
  (num, num) size = (1, 1),

  /// Whether generated contour rings are smoothed using linear interpolation.
  var bool smooth = true,
  int? thresholdsCount,
  List<double>? thresholdsValues,
  ContourThresholdsValues? thresholdsGenerator,
  ContourThresholdsCount? thresholdsCountGenerator,
}) {
  /// Creates a [Contours] generator with optional initial configuration.
  this {
    this.size = size;
    if (thresholdsValues != null) {
      this.thresholdsValues = thresholdsValues;
    } else if (thresholdsGenerator != null) {
      this.thresholdsGenerator = thresholdsGenerator;
    } else if (thresholdsCount != null) {
      this.thresholdsCount = thresholdsCount;
    } else if (thresholdsCountGenerator != null) {
      this.thresholdsCountGenerator = thresholdsCountGenerator;
    }
  }

  int _dx = 1;
  int _dy = 1;
  int? _thresholdsCount;
  List<double>? _thresholdsValues;
  ContourThresholdsValues? _thresholdsGenerator;
  ContourThresholdsCount? _thresholdsCountGenerator = _defaultThresholdsCount;

  /// The expected grid dimensions `(width, height)`.
  (int, int) get size => (_dx, _dy);

  /// Sets the expected grid dimensions `(width, height)`, flooring both values.
  ///
  /// Throws a [RangeError] if either dimension is negative or non-finite.
  set size((num, num) value) {
    final w = value.$1;
    final h = value.$2;
    if (!(w >= 0 && h >= 0) || !w.isFinite || !h.isFinite) {
      throw RangeError('invalid size');
    }
    _dx = w.floor();
    _dy = h.floor();
  }

  /// The configured constant approximate threshold count, if any.
  int? get thresholdsCount => _thresholdsCount;

  /// Sets an approximate constant threshold count, clearing other threshold
  /// configurations. Setting `null` restores the default Sturges rule.
  set thresholdsCount(int? count) {
    _thresholdsCount = count;
    _thresholdsValues = null;
    _thresholdsGenerator = null;
    _thresholdsCountGenerator = count == null ? _defaultThresholdsCount : null;
  }

  /// The configured explicit threshold values (defensively copied), if any.
  List<double>? get thresholdsValues => _thresholdsValues;

  /// Sets explicit threshold values (defensively copied), clearing other
  /// threshold configurations. Setting `null` restores the default Sturges
  /// rule.
  set thresholdsValues(List<double>? values) {
    if (values == null) {
      _thresholdsValues = null;
      _thresholdsCount = null;
      _thresholdsGenerator = null;
      _thresholdsCountGenerator = _defaultThresholdsCount;
    } else {
      _thresholdsValues = contourArraySlice(values);
      _thresholdsCount = null;
      _thresholdsGenerator = null;
      _thresholdsCountGenerator = null;
    }
  }

  /// The configured explicit threshold values generator callback, if any.
  ContourThresholdsValues? get thresholdsGenerator => _thresholdsGenerator;

  /// Sets a threshold values generator callback, clearing other threshold
  /// configurations. Setting `null` restores the default Sturges rule.
  set thresholdsGenerator(ContourThresholdsValues? fn) {
    _thresholdsGenerator = fn;
    _thresholdsCount = null;
    _thresholdsValues = null;
    _thresholdsCountGenerator = fn == null ? _defaultThresholdsCount : null;
  }

  /// The configured threshold count generator callback, if any.
  ContourThresholdsCount? get thresholdsCountGenerator =>
      _thresholdsCountGenerator;

  /// Sets a threshold count generator callback, clearing other threshold
  /// configurations. Setting `null` restores the default Sturges rule.
  set thresholdsCountGenerator(ContourThresholdsCount? fn) {
    _thresholdsCountGenerator = fn ?? _defaultThresholdsCount;
    _thresholdsCount = null;
    _thresholdsValues = null;
    _thresholdsGenerator = null;
  }

  /// Computes contour polygons for [values] across all resolved thresholds.
  List<ContourMultiPolygon> call(List<double> values) {
    final List<double> tz;
    final explicitValues = _thresholdsValues;
    final valuesGen = _thresholdsGenerator;
    var start = 0;
    var end = 0;
    if (explicitValues != null) {
      tz = contourArraySlice(explicitValues)..sort(contourAscending);
      end = tz.length;
    } else if (valuesGen != null) {
      tz = contourArraySlice(valuesGen(values))..sort(contourAscending);
      end = tz.length;
    } else {
      final count = _thresholdsCount ?? _thresholdsCountGenerator!(values);
      final e = _finiteExtent(values);
      if (e == null) return <ContourMultiPolygon>[];
      final (e0, e1) = e;
      final (n0, n1) = nice(e0, e1, count);
      tz = ticks(n0, n1, count);
      end = tz.length;
      while (end > start && tz[end - 1] >= e1) {
        --end;
      }
      while (end - start > 1 && tz[start + 1] < e0) {
        ++start;
      }
    }

    final count = end - start;
    if (count <= 0) return <ContourMultiPolygon>[];
    final ws = _StitchWorkspace(_dx);
    final result = List<ContourMultiPolygon>.generate(count, (i) {
      final v = tz[start + i];
      if (v.isNaN) {
        throw ArgumentError.value(v, 'value', 'invalid value: $v');
      }
      return ws.buildContour(
        values: values,
        dy: _dy,
        value: v,
        outputValue: v,
        smooth: smooth,
      );
    });
    return result;
  }

  /// Computes a single contour polygon where [values] are `>= value`.
  ///
  /// Throws an [ArgumentError] if [value] is `NaN`.
  ContourMultiPolygon contour(List<double> values, double value) {
    if (value.isNaN) {
      throw ArgumentError.value(value, 'value', 'invalid value: $value');
    }
    return _StitchWorkspace(_dx).buildContour(
      values: values,
      dy: _dy,
      value: value,
      outputValue: value,
      smooth: smooth,
    );
  }
}

/// Internal fused helper used by `density.dart` to compute contours across
/// [outputThresholds] (scaled by [thresholdScale] for marching squares) while
/// fusing the affine `(x * coordScale - coordOffset)` transform into ring
/// materialization and sharing one [_StitchWorkspace].
List<ContourMultiPolygon> buildDensityContoursBatch(
  List<double> values,
  int dx,
  int dy,
  List<double> outputThresholds,
  double thresholdScale,
  double coordScale,
  double coordOffset,
) {
  final count = outputThresholds.length;
  if (count == 0) return <ContourMultiPolygon>[];
  final ws = _StitchWorkspace(dx);
  return List<ContourMultiPolygon>.generate(count, (i) {
    final outVal = outputThresholds[i];
    final gridVal = outVal * thresholdScale;
    if (gridVal.isNaN) {
      throw ArgumentError.value(outVal, 'value', 'invalid value: $outVal');
    }
    return ws.buildContour(
      values: values,
      dy: dy,
      value: gridVal,
      outputValue: outVal,
      smooth: true,
      scale: coordScale,
      offset: coordOffset,
      applyTransform: true,
    );
  });
}

/// Internal fused helper used by `DensityContours.call` to compute a single
/// transformed density contour without allocating intermediate vertex lists.
ContourMultiPolygon buildDensityContourSingle(
  List<double> values,
  int dx,
  int dy,
  double gridValue,
  double outputValue,
  double coordScale,
  double coordOffset,
) {
  if (gridValue.isNaN) {
    throw ArgumentError.value(
      outputValue,
      'value',
      'invalid value: $outputValue',
    );
  }
  return _StitchWorkspace(dx).buildContour(
    values: values,
    dy: dy,
    value: gridValue,
    outputValue: outputValue,
    smooth: true,
    scale: coordScale,
    offset: coordOffset,
    applyTransform: true,
  );
}

/// Constructs a new marching-squares [Contours] generator.
Contours contours({
  (num, num) size = (1, 1),
  bool smooth = true,
  int? thresholdsCount,
  List<double>? thresholdsValues,
  ContourThresholdsValues? thresholdsGenerator,
  ContourThresholdsCount? thresholdsCountGenerator,
}) => Contours(
  size: size,
  smooth: smooth,
  thresholdsCount: thresholdsCount,
  thresholdsValues: thresholdsValues,
  thresholdsGenerator: thresholdsGenerator,
  thresholdsCountGenerator: thresholdsCountGenerator,
);
