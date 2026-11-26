// Ported from d3-scale-chromatic v3.1.0 src/sequential-multi/rainbow.js (ISC, Mike Bostock).

/// Port of `src/sequential-multi/rainbow.js` of d3-scale-chromatic 3.1.0: the
/// less-angry rainbow, warm and cool Cubehelix color schemes.
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_interpolate_port/d3_interpolate.dart';

/// rainbow.js:4 `warm` (`interpolateWarm` of index.js:41): a 180-degree
/// Cubehelix rotation from purple to yellow.
// DIVERGES(d3-scale-chromatic): platform-chromatic-math-last-bit, libm trig.
final Cubehelix Function(double t) interpolateWarm = interpolateCubehelixLong(
  Cubehelix(-100, 0.75, 0.35),
  Cubehelix(80, 1.5, 0.8),
);

/// rainbow.js:6 `cool` (`interpolateCool` of index.js:41): a 180-degree
/// Cubehelix rotation from purple to green.
final Cubehelix Function(double t) interpolateCool = interpolateCubehelixLong(
  Cubehelix(260, 0.75, 0.35),
  Cubehelix(80, 1.5, 0.8),
);

/// rainbow.js:10 the default export (`interpolateRainbow` of index.js:41):
/// the cyclical less-angry rainbow color scheme, returning a new [Cubehelix]
/// at each call.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-color-values, fresh Cubehelix.
Cubehelix interpolateRainbow(double t) {
  var x = t;
  if (x < 0 || x > 1) x -= x.floorToDouble();
  final ts = (x - 0.5).abs();
  return Cubehelix(360 * x - 100, 1.5 - 1.5 * ts, 0.8 - 0.9 * ts);
}
