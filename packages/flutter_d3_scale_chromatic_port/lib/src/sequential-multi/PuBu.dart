// Ported from d3-scale-chromatic v3.1.0 src/sequential-multi/PuBu.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/sequential-multi/PuBu.js` of d3-scale-chromatic 3.1.0: the sequential multi-hue
/// ColorBrewer color scheme [schemePuBu] and interpolator [interpolatePuBu].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// sequential-multi/PuBu.js:4 `scheme` (`schemePuBu` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 9);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
final List<List<Rgb>?> schemePuBu = List<List<Rgb>?>.unmodifiable([
  null,
  null,
  null,
  colors('ece7f2a6bddb2b8cbe'),
  colors('f1eef6bdc9e174a9cf0570b0'),
  colors('f1eef6bdc9e174a9cf2b8cbe045a8d'),
  colors('f1eef6d0d1e6a6bddb74a9cf2b8cbe045a8d'),
  colors('f1eef6d0d1e6a6bddb74a9cf3690c00570b0034e7b'),
  colors('fff7fbece7f2d0d1e6a6bddb74a9cf3690c00570b0034e7b'),
  colors('fff7fbece7f2d0d1e6a6bddb74a9cf3690c00570b0045a8d023858'),
]);

/// sequential-multi/PuBu.js the default export (`interpolatePuBu` of index.js): the
/// continuous RGB B-spline interpolator for [schemePuBu].
final Rgb Function(double t) interpolatePuBu = ramp(schemePuBu);
