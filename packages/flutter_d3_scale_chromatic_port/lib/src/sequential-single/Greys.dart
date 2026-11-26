// Ported from d3-scale-chromatic v3.1.0 src/sequential-single/Greys.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/sequential-single/Greys.js` of d3-scale-chromatic 3.1.0: the sequential single-hue
/// ColorBrewer color scheme [schemeGreys] and interpolator [interpolateGreys].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// sequential-single/Greys.js:4 `scheme` (`schemeGreys` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 9);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
const List<List<Rgb>?> schemeGreys = [
  null,
  null,
  null,
  [Rgb(240, 240, 240), Rgb(189, 189, 189), Rgb(99, 99, 99)],
  [Rgb(247, 247, 247), Rgb(204, 204, 204), Rgb(150, 150, 150), Rgb(82, 82, 82)],
  [
    Rgb(247, 247, 247),
    Rgb(204, 204, 204),
    Rgb(150, 150, 150),
    Rgb(99, 99, 99),
    Rgb(37, 37, 37),
  ],
  [
    Rgb(247, 247, 247),
    Rgb(217, 217, 217),
    Rgb(189, 189, 189),
    Rgb(150, 150, 150),
    Rgb(99, 99, 99),
    Rgb(37, 37, 37),
  ],
  [
    Rgb(247, 247, 247),
    Rgb(217, 217, 217),
    Rgb(189, 189, 189),
    Rgb(150, 150, 150),
    Rgb(115, 115, 115),
    Rgb(82, 82, 82),
    Rgb(37, 37, 37),
  ],
  [
    Rgb(255, 255, 255),
    Rgb(240, 240, 240),
    Rgb(217, 217, 217),
    Rgb(189, 189, 189),
    Rgb(150, 150, 150),
    Rgb(115, 115, 115),
    Rgb(82, 82, 82),
    Rgb(37, 37, 37),
  ],
  [
    Rgb(255, 255, 255),
    Rgb(240, 240, 240),
    Rgb(217, 217, 217),
    Rgb(189, 189, 189),
    Rgb(150, 150, 150),
    Rgb(115, 115, 115),
    Rgb(82, 82, 82),
    Rgb(37, 37, 37),
    Rgb(0, 0, 0),
  ],
];

/// sequential-single/Greys.js the default export (`interpolateGreys` of index.js): the
/// continuous RGB B-spline interpolator for [schemeGreys].
final Rgb Function(double t) interpolateGreys = ramp(schemeGreys);
