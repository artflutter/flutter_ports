// Original code, not ported from d3-delaunay: package example.

// Example prints summary output.
// ignore_for_file: avoid_print

import 'package:flutter_d3_delaunay_port/d3_delaunay.dart';

void main() {
  final delaunay = Delaunay.fromCoords(const <(double, double)>[
    (0, 0),
    (300, 0),
    (0, 300),
    (300, 300),
    (100, 100),
  ]);

  print('Triangles: ${delaunay.triangles.length ~/ 3}');
  print('Hull indices: ${delaunay.hull}');
  print('Nearest to (51, 51): site ${delaunay.find(51, 51)}');
  print('Neighbors of site 4: ${delaunay.neighbors(4).toList()}');
  print('Within radius 180 of (100, 100): ${delaunay.findAll(100, 100, 180)}');

  final voronoi = delaunay.voronoi((0, 0, 300, 300));
  for (final cell in voronoi.cellPolygonsIndexed()) {
    print('Cell ${cell.index}: ${cell.polygon.length} vertices');
  }
  print('Voronoi SVG: ${voronoi.renderToSvg()}');
}
