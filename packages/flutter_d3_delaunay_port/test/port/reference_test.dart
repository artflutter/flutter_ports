// Original code, not ported from d3-delaunay: Node.js reference parity tests.

import 'package:flutter_d3_delaunay_port/d3_delaunay.dart';
import 'package:test/test.dart';

import 'd3_delaunay_reference.dart';

void _expectPolyClose(
  List<(double, double)>? actual,
  List<(double, double)>? expected,
  double tol,
) {
  if (expected == null) {
    expect(actual, isNull);
    return;
  }
  expect(actual, isNotNull);
  expect(actual!.length, expected.length);
  for (var i = 0; i < expected.length; ++i) {
    expect(actual[i].$1, closeTo(expected[i].$1, tol));
    expect(actual[i].$2, closeTo(expected[i].$2, tol));
  }
}

void main() {
  test('40 uniform points triangulation & Voronoi match Node.js v6.0.4', () {
    final d = Delaunay.fromCoords(refUniform40Points);
    final v = d.voronoi((0, 0, 500, 400));

    expect(d.triangles, refUniform40Triangles);
    expect(d.halfedges, refUniform40Halfedges);
    expect(d.hull, refUniform40Hull);
    expect(d.inedges, refUniform40Inedges);

    expect(v.circumcenters.length, refUniform40Circumcenters.length);
    for (var i = 0; i < refUniform40Circumcenters.length; ++i) {
      expect(v.circumcenters[i], closeTo(refUniform40Circumcenters[i], 1e-12));
    }
    expect(v.vectors.length, refUniform40Vectors.length);
    for (var i = 0; i < refUniform40Vectors.length; ++i) {
      expect(v.vectors[i], closeTo(refUniform40Vectors[i], 1e-12));
    }

    expect(d.renderToSvg(), refUniform40DelaunaySvg);
    expect(d.renderHullToSvg(), refUniform40HullSvg);
    expect(v.renderToSvg(), refUniform40VoronoiSvg);

    for (var i = 0; i < refUniform40Cells.length; ++i) {
      _expectPolyClose(v.cellPolygon(i), refUniform40Cells[i], 1e-12);
      expect(v.neighbors(i).toList(), refUniform40VoronoiNeighbors[i]);
    }

    for (final (qx, qy, expected) in refUniform40Find) {
      expect(d.find(qx, qy), expected);
    }
  });

  test('30 clustered points with duplicates match Node.js v6.0.4', () {
    final d = Delaunay.fromCoords(refClustered30Points);
    final v = d.voronoi((0, 0, 500, 400));

    expect(d.triangles, refClustered30Triangles);
    expect(d.inedges, refClustered30Inedges);
    expect(d.hull, refClustered30Hull);
    expect([
      for (var i = 0; i < refClustered30Points.length; ++i)
        v.cellPolygon(i)?.length ?? -1,
    ], refClustered30CellLengths);
  });

  test('16 collinear points match Node.js v6.0.4', () {
    final d = Delaunay.fromCoords(refCollinear16Points);
    final v = d.voronoi((0, 0, 500, 400));

    expect(d.collinear, refCollinear16Order);
    expect([
      for (var i = 0; i < refCollinear16Points.length; ++i)
        v.cellPolygon(i)?.length ?? -1,
    ], refCollinear16CellLengths);
  });

  test('50 hard robust-predicates orient2d fixtures match Node.js v3.0.3', () {
    for (final (ax, ay, bx, by, cx, cy, expectedSign) in refOrient2dHard50) {
      final res = orient2d(ax, ay, bx, by, cx, cy);
      final actualSign = res == 0 ? 0 : (res > 0 ? 1 : -1);
      expect(actualSign, expectedSign);
    }
  });
}
