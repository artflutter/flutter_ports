// Ported from d3-scale-chromatic v3.1.0 src/sequential-multi/PuRd.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/sequential-multi/PuRd.js` of d3-scale-chromatic 3.1.0: the sequential multi-hue
/// ColorBrewer color scheme [schemePuRd] and interpolator [interpolatePuRd].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// sequential-multi/PuRd.js:4 `scheme` (`schemePuRd` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 9);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
final List<List<Rgb>?> schemePuRd = List<List<Rgb>?>.unmodifiable([
  null,
  null,
  null,
  colors('e7e1efc994c7dd1c77'),
  colors('f1eef6d7b5d8df65b0ce1256'),
  colors('f1eef6d7b5d8df65b0dd1c77980043'),
  colors('f1eef6d4b9dac994c7df65b0dd1c77980043'),
  colors('f1eef6d4b9dac994c7df65b0e7298ace125691003f'),
  colors('f7f4f9e7e1efd4b9dac994c7df65b0e7298ace125691003f'),
  colors('f7f4f9e7e1efd4b9dac994c7df65b0e7298ace125698004367001f'),
]);

/// sequential-multi/PuRd.js the default export (`interpolatePuRd` of index.js): the
/// continuous RGB B-spline interpolator for [schemePuRd].
final Rgb Function(double t) interpolatePuRd = ramp(schemePuRd);
