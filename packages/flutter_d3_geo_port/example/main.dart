// Original code, not ported from d3-geo: minimal package usage example.

import 'package:flutter_d3_geo_port/d3_geo.dart';

void main() {
  final proj = geoOrthographic()
    ..scale = 220
    ..translate = const (250, 250)
    ..rotate = const (-10, -25, 0);

  final path = geoPath(proj);
  final outlineSvg = path(const GeoSphere());
  final graticuleSvg = path(geoGraticule10());

  const london = (-0.1276, 51.5072);
  const tokyo = (139.6917, 35.6895);
  final distRad = geoDistance(london, tokyo);
  final interp = geoInterpolate(london, tokyo);
  final midpoint = interp(0.5);

  // Example output for CLI demonstration.
  // ignore: avoid_print
  print('Sphere outline length: ${outlineSvg?.length ?? 0}');
  // Example output for CLI demonstration.
  // ignore: avoid_print
  print('Graticule SVG length: ${graticuleSvg?.length ?? 0}');
  // Example output for CLI demonstration.
  // ignore: avoid_print
  print(
    'London -> Tokyo: ${(distRad * 6371).round()} km, '
    'midpoint: (${midpoint.$1.toStringAsFixed(2)}, '
    '${midpoint.$2.toStringAsFixed(2)})',
  );
}
