// Ported from d3-scale-chromatic v3.1.0 src/diverging/PuOr.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/diverging/PuOr.js` of d3-scale-chromatic 3.1.0: the diverging
/// ColorBrewer color scheme [schemePuOr] and interpolator [interpolatePuOr].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// diverging/PuOr.js:4 `scheme` (`schemePuOr` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 11);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
const List<List<Rgb>?> schemePuOr = [
  null,
  null,
  null,
  [Rgb(153, 142, 195), Rgb(247, 247, 247), Rgb(241, 163, 64)],
  [Rgb(94, 60, 153), Rgb(178, 171, 210), Rgb(253, 184, 99), Rgb(230, 97, 1)],
  [
    Rgb(94, 60, 153),
    Rgb(178, 171, 210),
    Rgb(247, 247, 247),
    Rgb(253, 184, 99),
    Rgb(230, 97, 1),
  ],
  [
    Rgb(84, 39, 136),
    Rgb(153, 142, 195),
    Rgb(216, 218, 235),
    Rgb(254, 224, 182),
    Rgb(241, 163, 64),
    Rgb(179, 88, 6),
  ],
  [
    Rgb(84, 39, 136),
    Rgb(153, 142, 195),
    Rgb(216, 218, 235),
    Rgb(247, 247, 247),
    Rgb(254, 224, 182),
    Rgb(241, 163, 64),
    Rgb(179, 88, 6),
  ],
  [
    Rgb(84, 39, 136),
    Rgb(128, 115, 172),
    Rgb(178, 171, 210),
    Rgb(216, 218, 235),
    Rgb(254, 224, 182),
    Rgb(253, 184, 99),
    Rgb(224, 130, 20),
    Rgb(179, 88, 6),
  ],
  [
    Rgb(84, 39, 136),
    Rgb(128, 115, 172),
    Rgb(178, 171, 210),
    Rgb(216, 218, 235),
    Rgb(247, 247, 247),
    Rgb(254, 224, 182),
    Rgb(253, 184, 99),
    Rgb(224, 130, 20),
    Rgb(179, 88, 6),
  ],
  [
    Rgb(45, 0, 75),
    Rgb(84, 39, 136),
    Rgb(128, 115, 172),
    Rgb(178, 171, 210),
    Rgb(216, 218, 235),
    Rgb(254, 224, 182),
    Rgb(253, 184, 99),
    Rgb(224, 130, 20),
    Rgb(179, 88, 6),
    Rgb(127, 59, 8),
  ],
  [
    Rgb(45, 0, 75),
    Rgb(84, 39, 136),
    Rgb(128, 115, 172),
    Rgb(178, 171, 210),
    Rgb(216, 218, 235),
    Rgb(247, 247, 247),
    Rgb(254, 224, 182),
    Rgb(253, 184, 99),
    Rgb(224, 130, 20),
    Rgb(179, 88, 6),
    Rgb(127, 59, 8),
  ],
];

/// diverging/PuOr.js the default export (`interpolatePuOr` of index.js): the
/// continuous RGB B-spline interpolator for [schemePuOr].
final Rgb Function(double t) interpolatePuOr = ramp(schemePuOr);
