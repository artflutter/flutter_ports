// Ported from d3-scale-chromatic v3.1.0 src/sequential-multi/YlGn.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/sequential-multi/YlGn.js` of d3-scale-chromatic 3.1.0: the sequential multi-hue
/// ColorBrewer color scheme [schemeYlGn] and interpolator [interpolateYlGn].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// sequential-multi/YlGn.js:4 `scheme` (`schemeYlGn` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 9);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
final List<List<Rgb>?> schemeYlGn = List<List<Rgb>?>.unmodifiable([
  null,
  null,
  null,
  colors('f7fcb9addd8e31a354'),
  colors('ffffccc2e69978c679238443'),
  colors('ffffccc2e69978c67931a354006837'),
  colors('ffffccd9f0a3addd8e78c67931a354006837'),
  colors('ffffccd9f0a3addd8e78c67941ab5d238443005a32'),
  colors('ffffe5f7fcb9d9f0a3addd8e78c67941ab5d238443005a32'),
  colors('ffffe5f7fcb9d9f0a3addd8e78c67941ab5d238443006837004529'),
]);

/// sequential-multi/YlGn.js the default export (`interpolateYlGn` of index.js): the
/// continuous RGB B-spline interpolator for [schemeYlGn].
final Rgb Function(double t) interpolateYlGn = ramp(schemeYlGn);
