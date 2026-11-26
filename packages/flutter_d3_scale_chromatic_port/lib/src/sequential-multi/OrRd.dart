// Ported from d3-scale-chromatic v3.1.0 src/sequential-multi/OrRd.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/sequential-multi/OrRd.js` of d3-scale-chromatic 3.1.0: the sequential multi-hue
/// ColorBrewer color scheme [schemeOrRd] and interpolator [interpolateOrRd].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// sequential-multi/OrRd.js:4 `scheme` (`schemeOrRd` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 9);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
final List<List<Rgb>?> schemeOrRd = List<List<Rgb>?>.unmodifiable([
  null,
  null,
  null,
  colors('fee8c8fdbb84e34a33'),
  colors('fef0d9fdcc8afc8d59d7301f'),
  colors('fef0d9fdcc8afc8d59e34a33b30000'),
  colors('fef0d9fdd49efdbb84fc8d59e34a33b30000'),
  colors('fef0d9fdd49efdbb84fc8d59ef6548d7301f990000'),
  colors('fff7ecfee8c8fdd49efdbb84fc8d59ef6548d7301f990000'),
  colors('fff7ecfee8c8fdd49efdbb84fc8d59ef6548d7301fb300007f0000'),
]);

/// sequential-multi/OrRd.js the default export (`interpolateOrRd` of index.js): the
/// continuous RGB B-spline interpolator for [schemeOrRd].
final Rgb Function(double t) interpolateOrRd = ramp(schemeOrRd);
