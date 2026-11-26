// Ported from d3-scale-chromatic v3.1.0 src/sequential-single/Greens.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/sequential-single/Greens.js` of d3-scale-chromatic 3.1.0: the sequential single-hue
/// ColorBrewer color scheme [schemeGreens]
/// and interpolator [interpolateGreens].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// sequential-single/Greens.js:4 `scheme` (`schemeGreens` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 9);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
final List<List<Rgb>?> schemeGreens = List<List<Rgb>?>.unmodifiable([
  null,
  null,
  null,
  colors('e5f5e0a1d99b31a354'),
  colors('edf8e9bae4b374c476238b45'),
  colors('edf8e9bae4b374c47631a354006d2c'),
  colors('edf8e9c7e9c0a1d99b74c47631a354006d2c'),
  colors('edf8e9c7e9c0a1d99b74c47641ab5d238b45005a32'),
  colors('f7fcf5e5f5e0c7e9c0a1d99b74c47641ab5d238b45005a32'),
  colors('f7fcf5e5f5e0c7e9c0a1d99b74c47641ab5d238b45006d2c00441b'),
]);

/// sequential-single/Greens.js the default export (`interpolateGreens` of index.js): the
/// continuous RGB B-spline interpolator for [schemeGreens].
final Rgb Function(double t) interpolateGreens = ramp(schemeGreens);
