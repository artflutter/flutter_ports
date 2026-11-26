// Ported from d3-scale-chromatic v3.1.0 src/sequential-multi/BuPu.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/sequential-multi/BuPu.js` of d3-scale-chromatic 3.1.0: the sequential multi-hue
/// ColorBrewer color scheme [schemeBuPu] and interpolator [interpolateBuPu].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// sequential-multi/BuPu.js:4 `scheme` (`schemeBuPu` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 9);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
const List<List<Rgb>?> schemeBuPu = [
  null,
  null,
  null,
  [Rgb(224, 236, 244), Rgb(158, 188, 218), Rgb(136, 86, 167)],
  [
    Rgb(237, 248, 251),
    Rgb(179, 205, 227),
    Rgb(140, 150, 198),
    Rgb(136, 65, 157),
  ],
  [
    Rgb(237, 248, 251),
    Rgb(179, 205, 227),
    Rgb(140, 150, 198),
    Rgb(136, 86, 167),
    Rgb(129, 15, 124),
  ],
  [
    Rgb(237, 248, 251),
    Rgb(191, 211, 230),
    Rgb(158, 188, 218),
    Rgb(140, 150, 198),
    Rgb(136, 86, 167),
    Rgb(129, 15, 124),
  ],
  [
    Rgb(237, 248, 251),
    Rgb(191, 211, 230),
    Rgb(158, 188, 218),
    Rgb(140, 150, 198),
    Rgb(140, 107, 177),
    Rgb(136, 65, 157),
    Rgb(110, 1, 107),
  ],
  [
    Rgb(247, 252, 253),
    Rgb(224, 236, 244),
    Rgb(191, 211, 230),
    Rgb(158, 188, 218),
    Rgb(140, 150, 198),
    Rgb(140, 107, 177),
    Rgb(136, 65, 157),
    Rgb(110, 1, 107),
  ],
  [
    Rgb(247, 252, 253),
    Rgb(224, 236, 244),
    Rgb(191, 211, 230),
    Rgb(158, 188, 218),
    Rgb(140, 150, 198),
    Rgb(140, 107, 177),
    Rgb(136, 65, 157),
    Rgb(129, 15, 124),
    Rgb(77, 0, 75),
  ],
];

/// sequential-multi/BuPu.js the default export (`interpolateBuPu` of index.js): the
/// continuous RGB B-spline interpolator for [schemeBuPu].
final Rgb Function(double t) interpolateBuPu = ramp(schemeBuPu);
