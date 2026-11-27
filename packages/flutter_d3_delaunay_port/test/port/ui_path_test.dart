// Original code, not ported from d3-delaunay: Flutter UiPathContext tests.

import 'dart:ui' as ui;

import 'package:flutter_d3_delaunay_port/flutter_d3_delaunay_port.dart';
import 'package:flutter_d3_path_port/flutter_d3_path_port.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DelaunayUiPath and VoronoiUiPath build valid dart:ui.Path objects', () {
    final delaunay = Delaunay.fromCoords(const <(double, double)>[
      (10, 10),
      (190, 15),
      (20, 180),
      (185, 190),
      (100, 95),
    ]);
    final voronoi = delaunay.voronoi((0, 0, 200, 200));

    final meshPath = delaunay.toUiPath();
    expect(meshPath.getBounds().width, closeTo(180, 1e-3));
    expect(meshPath.getBounds().height, closeTo(180, 1e-3));

    final hullPath = delaunay.hullToUiPath();
    expect(hullPath.contains(const ui.Offset(100, 95)), isTrue);
    expect(hullPath.contains(const ui.Offset(5, 5)), isFalse);

    final ptsPath = delaunay.pointsToUiPath(r: 4);
    expect(ptsPath.contains(const ui.Offset(100, 95)), isTrue);

    final triPath = delaunay.triangleToUiPath(0);
    expect(triPath.getBounds().isEmpty, isFalse);

    final voronoiPath = voronoi.toUiPath();
    expect(voronoiPath.getBounds().isEmpty, isFalse);

    final boundsPath = voronoi.boundsToUiPath();
    expect(boundsPath.getBounds(), const ui.Rect.fromLTRB(0, 0, 200, 200));

    final centerCell = voronoi.cellToUiPath(4);
    expect(centerCell.contains(const ui.Offset(100, 95)), isTrue);
    expect(centerCell.contains(const ui.Offset(5, 5)), isFalse);

    // Reusable UiPathContext across frames.
    final ctx = UiPathContext();
    voronoi.cellToUiPath(0, ctx);
    expect(ctx.path.contains(const ui.Offset(10, 10)), isTrue);
    ctx.reset();
    voronoi.cellToUiPath(3, ctx);
    expect(ctx.path.contains(const ui.Offset(185, 190)), isTrue);
    expect(ctx.path.contains(const ui.Offset(10, 10)), isFalse);
  });
}
