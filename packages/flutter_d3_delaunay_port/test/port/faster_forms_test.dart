// Original code, not ported from d3-delaunay: twin tests for faster forms.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_d3_delaunay_port/d3_delaunay.dart';
import 'package:test/test.dart';

int _bruteFind(Float64List points, double x, double y) {
  var best = -1;
  var bestD2 = double.infinity;
  for (var i = 0, n = points.length >> 1; i < n; ++i) {
    final dx = x - points[2 * i];
    final dy = y - points[2 * i + 1];
    final d2 = dx * dx + dy * dy;
    if (d2 < bestD2) {
      bestD2 = d2;
      best = i;
    }
  }
  return best;
}

Set<int> _bruteFindAll(Float64List points, double x, double y, double r) {
  final r2 = r * r;
  final out = <int>{};
  for (var i = 0, n = points.length >> 1; i < n; ++i) {
    final dx = x - points[2 * i];
    final dy = y - points[2 * i + 1];
    if (dx * dx + dy * dy <= r2) out.add(i);
  }
  return out;
}

void main() {
  test(
    'Delaunay.find and findAll match brute-force scan across random sets',
    () {
      final rng = math.Random(42);
      final coords = Float64List(600);
      for (var i = 0; i < coords.length; ++i) {
        coords[i] = rng.nextDouble() * 1000.0;
      }
      final delaunay = Delaunay(coords);
      final voronoi = delaunay.voronoi((0, 0, 1000, 1000));

      for (var q = 0; q < 200; ++q) {
        final qx = rng.nextDouble() * 1200.0 - 100.0;
        final qy = rng.nextDouble() * 1200.0 - 100.0;
        final nearest = delaunay.find(qx, qy);
        final expected = _bruteFind(coords, qx, qy);
        expect(nearest, expected);
        expect(voronoi.contains(nearest, qx, qy), isTrue);

        final radius = 15.0 + rng.nextDouble() * 160.0;
        final found = delaunay.findAll(qx, qy, radius).toSet();
        final expectedAll = _bruteFindAll(coords, qx, qy, radius);
        expect(found, expectedAll);
      }
    },
  );

  test('findAll handles coincident, collinear, and degenerate point sets', () {
    // Coincident points
    final dCoinc = Delaunay.fromCoords(const <(double, double)>[
      (10, 10),
      (10, 10),
      (12, 10),
      (100, 100),
      (100, 100),
    ]);
    expect(dCoinc.findAll(10, 10, 0).toSet(), {0, 1});
    expect(dCoinc.findAll(10, 10, 3).toSet(), {0, 1, 2});
    expect(dCoinc.findAll(100, 100, 1).toSet(), {3, 4});
    expect(dCoinc.findAll(50, 50, 5), isEmpty);

    // Collinear points
    final dCol = Delaunay.fromCoords(const <(double, double)>[
      (0, 0),
      (10, 0),
      (20, 0),
      (30, 0),
      (40, 0),
    ]);
    expect(dCol.findAll(20, 0, 11).toSet(), {1, 2, 3});
    expect(dCol.findAll(20, 0, -1), isEmpty);
    expect(dCol.findAll(double.nan, 0, 10), isEmpty);

    // Empty / 1-point / 2-point
    final dEmpty = Delaunay.fromCoords(const []);
    expect(dEmpty.find(0, 0), -1);
    expect(dEmpty.findAll(0, 0, 10), isEmpty);
    expect(dEmpty.hullPolygon(), isEmpty);
    expect(dEmpty.renderToSvg(), isNull);
    expect(dEmpty.renderHullToSvg(), isNull);
    expect(dEmpty.renderPointsToSvg(), isNull);

    final dOne = Delaunay.fromCoords(const [(5, 5)]);
    expect(dOne.findAll(5, 5, 1).toList(), [0]);
    expect(dOne.neighbors(0), isEmpty);
  });

  test('Delaunay hullPolygon, trianglePolygons, and Voronoi bounds checks', () {
    final d = Delaunay.fromCoords(const <(double, double)>[
      (0, 0),
      (10, 0),
      (0, 10),
      (10, 10),
      (5, 5),
    ]);
    final hull = d.hullPolygon();
    expect(hull.first, hull.last);
    expect(hull.length, 5);

    final tris = d.trianglePolygons().toList();
    expect(tris, hasLength(4));
    for (final t in tris) {
      expect(t.length, 4);
      expect(t.first, t.last);
    }
    expect(d.renderToSvg(), isNotNull);
    expect(d.renderTriangleToSvg(0), isNotNull);

    expect(() => d.voronoi((10, 0, 5, 10)), throwsArgumentError);
    expect(() => d.voronoi((0, 10, 10, 5)), throwsArgumentError);
    expect(() => d.voronoi((double.nan, 0, 10, 10)), throwsArgumentError);

    final v = d.voronoi((0, 0, 10, 10));
    expect(v.renderBoundsToSvg(), 'M0,0h10v10h-10Z');
  });

  test('in-place update() matches fresh Delaunay and Voronoi construction', () {
    final rng = math.Random(99);
    final coords = Float64List(200);
    for (var i = 0; i < coords.length; ++i) {
      coords[i] = rng.nextDouble() * 500.0;
    }
    final d = Delaunay(coords);
    final v = d.voronoi((0, 0, 500, 500));

    // Perform 5 Lloyd relaxation steps in place and compare against fresh.
    for (var step = 0; step < 5; ++step) {
      for (var i = 0; i < 100; ++i) {
        final poly = v.cellPolygon(i);
        if (poly == null || poly.length < 3) continue;
        var sx = 0.0;
        var sy = 0.0;
        final m = poly.length - 1;
        for (var k = 0; k < m; ++k) {
          sx += poly[k].$1;
          sy += poly[k].$2;
        }
        coords[2 * i] = sx / m;
        coords[2 * i + 1] = sy / m;
      }
      v.update();

      final freshD = Delaunay(Float64List.fromList(coords));
      final freshV = freshD.voronoi((0, 0, 500, 500));
      expect(d.triangles, freshD.triangles);
      expect(d.halfedges, freshD.halfedges);
      expect(d.hull, freshD.hull);
      expect(v.circumcenters, freshV.circumcenters);
      expect(v.vectors, freshV.vectors);
      expect(v.renderToSvg(), freshV.renderToSvg());
    }
  });

  test(
    'orient2d near-collinear precision matches analytical sign everywhere',
    () {
      const r = 0.95;
      const q = 18.0;
      const p = 16.8;
      final w = math.pow(2, -43).toDouble();
      for (var i = 0; i < 32; ++i) {
        for (var j = 0; j < 32; ++j) {
          final x = r + w * i / 32;
          final y = r + w * j / 32;
          final o = orient2d(x, y, q, q, p, p);
          final expectedSign = y == x ? 0.0 : (y > x ? 1.0 : -1.0);
          expect(o.sign, expectedSign);
        }
      }
    },
  );
}
