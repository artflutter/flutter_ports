// Original code, not ported from d3-contour: twin tests for faster forms.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_d3_contour_port/d3_contour.dart';
import 'package:test/test.dart';

const List<List<((double, double), (double, double))>> _refCases =
    <List<((double, double), (double, double))>>[
      <((double, double), (double, double))>[],
      <((double, double), (double, double))>[((1.0, 1.5), (0.5, 1.0))],
      <((double, double), (double, double))>[((1.5, 1.0), (1.0, 1.5))],
      <((double, double), (double, double))>[((1.5, 1.0), (0.5, 1.0))],
      <((double, double), (double, double))>[((1.0, 0.5), (1.5, 1.0))],
      <((double, double), (double, double))>[
        ((1.0, 1.5), (0.5, 1.0)),
        ((1.0, 0.5), (1.5, 1.0)),
      ],
      <((double, double), (double, double))>[((1.0, 0.5), (1.0, 1.5))],
      <((double, double), (double, double))>[((1.0, 0.5), (0.5, 1.0))],
      <((double, double), (double, double))>[((0.5, 1.0), (1.0, 0.5))],
      <((double, double), (double, double))>[((1.0, 1.5), (1.0, 0.5))],
      <((double, double), (double, double))>[
        ((0.5, 1.0), (1.0, 0.5)),
        ((1.5, 1.0), (1.0, 1.5)),
      ],
      <((double, double), (double, double))>[((1.5, 1.0), (1.0, 0.5))],
      <((double, double), (double, double))>[((0.5, 1.0), (1.5, 1.0))],
      <((double, double), (double, double))>[((1.0, 1.5), (1.5, 1.0))],
      <((double, double), (double, double))>[((0.5, 1.0), (1.0, 1.5))],
      <((double, double), (double, double))>[],
    ];

final class _RefFrag(
  var int start,
  var int end,
  final List<(double, double)> ring,
);

double _refArea(List<(double, double)> ring) {
  var i = 0;
  final n = ring.length;
  var area = ring[n - 1].$2 * ring[0].$1 - ring[n - 1].$1 * ring[0].$2;
  while (++i < n) {
    area += ring[i - 1].$2 * ring[i].$1 - ring[i - 1].$1 * ring[i].$2;
  }
  return area;
}

bool _refWithin(double p, double q, double r) =>
    (p <= q && q <= r) || (r <= q && q <= p);

bool _refSegmentContains(
  (double, double) a,
  (double, double) b,
  (double, double) c,
) {
  final collinear =
      (b.$1 - a.$1) * (c.$2 - a.$2) == (c.$1 - a.$1) * (b.$2 - a.$2);
  if (!collinear) return false;
  return a.$1 == b.$1
      ? _refWithin(a.$2, c.$2, b.$2)
      : _refWithin(a.$1, c.$1, b.$1);
}

int _refRingContains(List<(double, double)> ring, (double, double) point) {
  final (x, y) = point;
  var contains = -1;
  for (var i = 0, n = ring.length, j = n - 1; i < n; j = i++) {
    final pi = ring[i];
    final pj = ring[j];
    if (_refSegmentContains(pi, pj, point)) return 0;
    if ((pi.$2 > y) != (pj.$2 > y) &&
        x < (pj.$1 - pi.$1) * (y - pi.$2) / (pj.$2 - pi.$2) + pi.$1) {
      contains = -contains;
    }
  }
  return contains;
}

int _refContains(List<(double, double)> ring, List<(double, double)> hole) {
  for (final p in hole) {
    final c = _refRingContains(ring, p);
    if (c != 0) return c;
  }
  return 0;
}

double _refValid(double v) => v.isNaN ? double.negativeInfinity : v;

double _refSmooth1(double x, double v0, double v1, double value) {
  final a = value - v0;
  final b = v1 - v0;
  final d = a.isFinite || b.isFinite ? a / b : a.sign / b.sign;
  return d.isNaN ? x : x + d - 0.5;
}

/// Literal translation of upstream `src/contours.js` `contour()` using maps.
List<List<List<(double, double)>>> _refContour(
  List<double> values,
  int dx,
  int dy,
  double value, {
  required bool smooth,
}) {
  final fragmentByStart = <int, _RefFrag>{};
  final fragmentByEnd = <int, _RefFrag>{};
  final polygons = <List<List<(double, double)>>>[];
  final holes = <List<(double, double)>>[];

  int index((double, double) p) => (p.$1 * 2 + p.$2 * (dx + 1) * 4).toInt();

  void finishRing(List<(double, double)> ring) {
    if (smooth) {
      for (var i = 0; i < ring.length; ++i) {
        final (x, y) = ring[i];
        final xt = x.truncate();
        final yt = y.truncate();
        if (x > 0 && x < dx && xt == x) {
          final idx = yt * dx + xt;
          ring[i] = (
            _refSmooth1(
              x,
              _refValid(values[idx - 1]),
              _refValid(values[idx]),
              value,
            ),
            y,
          );
        } else if (y > 0 && y < dy && yt == y) {
          final idx = yt * dx + xt;
          ring[i] = (
            x,
            _refSmooth1(
              y,
              _refValid(values[idx - dx]),
              _refValid(values[idx]),
              value,
            ),
          );
        }
      }
    }
    if (_refArea(ring) > 0) {
      polygons.add(<List<(double, double)>>[ring]);
    } else {
      holes.add(ring);
    }
  }

  var x = -1;
  var y = -1;
  void stitch(((double, double), (double, double)) line) {
    final start = (line.$1.$1 + x, line.$1.$2 + y);
    final end = (line.$2.$1 + x, line.$2.$2 + y);
    final si = index(start);
    final ei = index(end);
    final fEnd = fragmentByEnd[si];
    if (fEnd != null) {
      final gStart = fragmentByStart[ei];
      if (gStart != null) {
        fragmentByEnd.remove(fEnd.end);
        fragmentByStart.remove(gStart.start);
        if (identical(fEnd, gStart)) {
          fEnd.ring.add(end);
          finishRing(fEnd.ring);
        } else {
          final m = _RefFrag(fEnd.start, gStart.end, <(double, double)>[
            ...fEnd.ring,
            ...gStart.ring,
          ]);
          fragmentByStart[fEnd.start] = m;
          fragmentByEnd[gStart.end] = m;
        }
      } else {
        fragmentByEnd.remove(fEnd.end);
        fEnd.ring.add(end);
        fEnd.end = ei;
        fragmentByEnd[ei] = fEnd;
      }
    } else {
      final fStart = fragmentByStart[ei];
      if (fStart != null) {
        fragmentByStart.remove(fStart.start);
        fStart.ring.insert(0, start);
        fStart.start = si;
        fragmentByStart[si] = fStart;
      } else {
        final frag = _RefFrag(si, ei, <(double, double)>[start, end]);
        fragmentByStart[si] = frag;
        fragmentByEnd[ei] = frag;
      }
    }
  }

  var t1 = values[0] >= value ? 1 : 0;
  _refCases[t1 << 1].forEach(stitch);
  while (++x < dx - 1) {
    final t0 = t1;
    t1 = values[x + 1] >= value ? 1 : 0;
    _refCases[t0 | (t1 << 1)].forEach(stitch);
  }
  _refCases[t1].forEach(stitch);

  var t2 = 0;
  while (++y < dy - 1) {
    x = -1;
    t1 = values[y * dx + dx] >= value ? 1 : 0;
    t2 = values[y * dx] >= value ? 1 : 0;
    _refCases[(t1 << 1) | (t2 << 2)].forEach(stitch);
    while (++x < dx - 1) {
      final t0 = t1;
      t1 = values[y * dx + dx + x + 1] >= value ? 1 : 0;
      final t3 = t2;
      t2 = values[y * dx + x + 1] >= value ? 1 : 0;
      _refCases[t0 | (t1 << 1) | (t2 << 2) | (t3 << 3)].forEach(stitch);
    }
    _refCases[t1 | (t2 << 3)].forEach(stitch);
  }

  x = -1;
  t2 = values[y * dx] >= value ? 1 : 0;
  _refCases[t2 << 2].forEach(stitch);
  while (++x < dx - 1) {
    final t3 = t2;
    t2 = values[y * dx + x + 1] >= value ? 1 : 0;
    _refCases[(t2 << 2) | (t3 << 3)].forEach(stitch);
  }
  _refCases[t2 << 3].forEach(stitch);

  for (final hole in holes) {
    for (final poly in polygons) {
      if (_refContains(poly[0], hole) != -1) {
        poly.add(hole);
        break;
      }
    }
  }
  return polygons;
}

void main() {
  test('flat-array marching squares matches literal upstream algorithm across '
      'random, saddle, concentric-hole, and NaN/Infinity grids', () {
    final rng = math.Random(2026);
    for (final (w, h) in const <(int, int)>[
      (1, 1),
      (2, 3),
      (7, 5),
      (16, 16),
      (25, 19),
    ]) {
      final grid = Float64List(w * h);
      for (var i = 0; i < grid.length; ++i) {
        grid[i] = (rng.nextDouble() - 0.3) * 100.0;
      }
      if (grid.length > 10) {
        grid[3] = double.nan;
        grid[5] = double.negativeInfinity;
        grid[7] = double.infinity;
      }
      final listCopy = List<double>.of(grid);

      for (final smooth in const <bool>[true, false]) {
        final gen = contours(size: (w, h), smooth: smooth);
        for (final threshold in const <double>[-20, 0, 25.5, 60]) {
          final expected = _refContour(
            listCopy,
            w,
            h,
            threshold,
            smooth: smooth,
          );
          final fromF64 = gen.contour(grid, threshold).coordinates;
          final fromList = gen.contour(listCopy, threshold).coordinates;
          expect(fromF64, expected);
          expect(fromList, expected);
        }
      }
    }
  });

  test(
    'fast contourRingArea and contourContains match literal upstream helpers',
    () {
      const square = <(double, double)>[
        (0, 0),
        (0, 10),
        (10, 10),
        (10, 0),
        (0, 0),
      ];
      const innerHole = <(double, double)>[
        (3, 3),
        (7, 3),
        (7, 7),
        (3, 7),
        (3, 3),
      ];
      const outsideRing = <(double, double)>[
        (12, 12),
        (15, 12),
        (15, 15),
        (12, 15),
        (12, 12),
      ];
      const boundaryRing = <(double, double)>[
        (0, 0),
        (10, 0),
        (10, 10),
        (0, 10),
        (0, 0),
      ];

      expect(contourRingArea(square), _refArea(square));
      expect(contourRingArea(innerHole), _refArea(innerHole));
      expect(
        contourContains(square, innerHole),
        _refContains(square, innerHole),
      );
      expect(
        contourContains(square, outsideRing),
        _refContains(square, outsideRing),
      );
      expect(
        contourContains(square, boundaryRing),
        _refContains(square, boundaryRing),
      );
    },
  );

  test('contourDensity List<T> fast path matches generic Iterable<T> path', () {
    final pts = List<(double, double)>.generate(
      80,
      (i) => (50.0 + (i * 19) % 240, 40.0 + (i * 31) % 180),
    );
    final iterPts = pts.map((p) => p);
    final density = contourDensityPoints(
      size: (320, 240),
      bandwidth: 18,
      thresholdsCount: 8,
    );
    final fromList = density(pts);
    final fromIter = density(iterPts);
    expect(fromList.length, fromIter.length);
    for (var i = 0; i < fromList.length; ++i) {
      expect(fromList[i].value, fromIter[i].value);
      expect(fromList[i].coordinates, fromIter[i].coordinates);
    }
  });

  test('contourDensity indexed and constant accessors work as expected', () {
    final pts = <(double, double)>[(40, 50), (45, 55), (50, 60)];
    final d =
        contourDensity<(double, double)>(
            x: (p) => p.$1,
            y: (p) => p.$2,
            size: (120, 120),
            bandwidth: 10,
            thresholdsCount: 5,
          )
          ..xIndexed((p, i, _) => p.$1 + i)
          ..yIndexed((p, i, _) => p.$2 + i)
          ..weightIndexed((_, i, _) => i + 1.0);
    final res = d(pts);
    expect(res, isNotEmpty);

    d
      ..xConst(60)
      ..yConst(60)
      ..weightConst(2);
    final resConst = d(pts);
    expect(resConst, isNotEmpty);
  });
}
