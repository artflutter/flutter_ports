// Ported from d3-scale-chromatic v3.1.0 src/sequential-multi/PuBuGn.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/sequential-multi/PuBuGn.js` of d3-scale-chromatic 3.1.0: the sequential multi-hue
/// ColorBrewer color scheme [schemePuBuGn]
/// and interpolator [interpolatePuBuGn].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// sequential-multi/PuBuGn.js:4 `scheme` (`schemePuBuGn` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 9);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
const List<List<Rgb>?> schemePuBuGn = [
  null,
  null,
  null,
  [Rgb(236, 226, 240), Rgb(166, 189, 219), Rgb(28, 144, 153)],
  [
    Rgb(246, 239, 247),
    Rgb(189, 201, 225),
    Rgb(103, 169, 207),
    Rgb(2, 129, 138),
  ],
  [
    Rgb(246, 239, 247),
    Rgb(189, 201, 225),
    Rgb(103, 169, 207),
    Rgb(28, 144, 153),
    Rgb(1, 108, 89),
  ],
  [
    Rgb(246, 239, 247),
    Rgb(208, 209, 230),
    Rgb(166, 189, 219),
    Rgb(103, 169, 207),
    Rgb(28, 144, 153),
    Rgb(1, 108, 89),
  ],
  [
    Rgb(246, 239, 247),
    Rgb(208, 209, 230),
    Rgb(166, 189, 219),
    Rgb(103, 169, 207),
    Rgb(54, 144, 192),
    Rgb(2, 129, 138),
    Rgb(1, 100, 80),
  ],
  [
    Rgb(255, 247, 251),
    Rgb(236, 226, 240),
    Rgb(208, 209, 230),
    Rgb(166, 189, 219),
    Rgb(103, 169, 207),
    Rgb(54, 144, 192),
    Rgb(2, 129, 138),
    Rgb(1, 100, 80),
  ],
  [
    Rgb(255, 247, 251),
    Rgb(236, 226, 240),
    Rgb(208, 209, 230),
    Rgb(166, 189, 219),
    Rgb(103, 169, 207),
    Rgb(54, 144, 192),
    Rgb(2, 129, 138),
    Rgb(1, 108, 89),
    Rgb(1, 70, 54),
  ],
];

/// sequential-multi/PuBuGn.js the default export (`interpolatePuBuGn` of index.js): the
/// continuous RGB B-spline interpolator for [schemePuBuGn].
final Rgb Function(double t) interpolatePuBuGn = ramp(schemePuBuGn);
