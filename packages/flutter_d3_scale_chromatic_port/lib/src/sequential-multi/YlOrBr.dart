// Ported from d3-scale-chromatic v3.1.0 src/sequential-multi/YlOrBr.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/sequential-multi/YlOrBr.js` of d3-scale-chromatic 3.1.0: the sequential multi-hue
/// ColorBrewer color scheme [schemeYlOrBr]
/// and interpolator [interpolateYlOrBr].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// sequential-multi/YlOrBr.js:4 `scheme` (`schemeYlOrBr` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 9);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
final List<List<Rgb>?> schemeYlOrBr = List<List<Rgb>?>.unmodifiable([
  null,
  null,
  null,
  colors('fff7bcfec44fd95f0e'),
  colors('ffffd4fed98efe9929cc4c02'),
  colors('ffffd4fed98efe9929d95f0e993404'),
  colors('ffffd4fee391fec44ffe9929d95f0e993404'),
  colors('ffffd4fee391fec44ffe9929ec7014cc4c028c2d04'),
  colors('ffffe5fff7bcfee391fec44ffe9929ec7014cc4c028c2d04'),
  colors('ffffe5fff7bcfee391fec44ffe9929ec7014cc4c02993404662506'),
]);

/// sequential-multi/YlOrBr.js the default export (`interpolateYlOrBr` of index.js): the
/// continuous RGB B-spline interpolator for [schemeYlOrBr].
final Rgb Function(double t) interpolateYlOrBr = ramp(schemeYlOrBr);
