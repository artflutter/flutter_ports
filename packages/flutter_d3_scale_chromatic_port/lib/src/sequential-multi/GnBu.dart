// Ported from d3-scale-chromatic v3.1.0 src/sequential-multi/GnBu.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/sequential-multi/GnBu.js` of d3-scale-chromatic 3.1.0: the sequential multi-hue
/// ColorBrewer color scheme [schemeGnBu] and interpolator [interpolateGnBu].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// sequential-multi/GnBu.js:4 `scheme` (`schemeGnBu` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 9);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
final List<List<Rgb>?> schemeGnBu = List<List<Rgb>?>.unmodifiable([
  null,
  null,
  null,
  colors('e0f3dba8ddb543a2ca'),
  colors('f0f9e8bae4bc7bccc42b8cbe'),
  colors('f0f9e8bae4bc7bccc443a2ca0868ac'),
  colors('f0f9e8ccebc5a8ddb57bccc443a2ca0868ac'),
  colors('f0f9e8ccebc5a8ddb57bccc44eb3d32b8cbe08589e'),
  colors('f7fcf0e0f3dbccebc5a8ddb57bccc44eb3d32b8cbe08589e'),
  colors('f7fcf0e0f3dbccebc5a8ddb57bccc44eb3d32b8cbe0868ac084081'),
]);

/// sequential-multi/GnBu.js the default export (`interpolateGnBu` of index.js): the
/// continuous RGB B-spline interpolator for [schemeGnBu].
final Rgb Function(double t) interpolateGnBu = ramp(schemeGnBu);
