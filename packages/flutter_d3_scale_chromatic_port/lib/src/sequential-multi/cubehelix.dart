// Ported from d3-scale-chromatic v3.1.0 src/sequential-multi/cubehelix.js (ISC, Mike Bostock).

/// Port of `src/sequential-multi/cubehelix.js` of d3-scale-chromatic 3.1.0:
/// Dave Green's default Cubehelix sequential color scheme.
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_interpolate_port/d3_interpolate.dart';

/// cubehelix.js:4 the default export (`interpolateCubehelixDefault` of
/// index.js:40): Dave Green's default Cubehelix color scheme for `t` in
/// `[0, 1]`, returning a new [Cubehelix] at each call.
// DIVERGES(d3-scale-chromatic): platform-chromatic-math-last-bit, libm trig.
final Cubehelix Function(double t) interpolateCubehelixDefault =
    interpolateCubehelixLong(Cubehelix(300, 0.5, 0), Cubehelix(-240, 0.5, 1));
