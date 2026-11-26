// Ported from d3-scale-chromatic v3.1.0 src/diverging/PRGn.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/diverging/PRGn.js` of d3-scale-chromatic 3.1.0: the diverging
/// ColorBrewer color scheme [schemePRGn] and interpolator [interpolatePRGn].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// diverging/PRGn.js:4 `scheme` (`schemePRGn` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 11);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
const List<List<Rgb>?> schemePRGn = [
  null,
  null,
  null,
  [Rgb(175, 141, 195), Rgb(247, 247, 247), Rgb(127, 191, 123)],
  [Rgb(123, 50, 148), Rgb(194, 165, 207), Rgb(166, 219, 160), Rgb(0, 136, 55)],
  [
    Rgb(123, 50, 148),
    Rgb(194, 165, 207),
    Rgb(247, 247, 247),
    Rgb(166, 219, 160),
    Rgb(0, 136, 55),
  ],
  [
    Rgb(118, 42, 131),
    Rgb(175, 141, 195),
    Rgb(231, 212, 232),
    Rgb(217, 240, 211),
    Rgb(127, 191, 123),
    Rgb(27, 120, 55),
  ],
  [
    Rgb(118, 42, 131),
    Rgb(175, 141, 195),
    Rgb(231, 212, 232),
    Rgb(247, 247, 247),
    Rgb(217, 240, 211),
    Rgb(127, 191, 123),
    Rgb(27, 120, 55),
  ],
  [
    Rgb(118, 42, 131),
    Rgb(153, 112, 171),
    Rgb(194, 165, 207),
    Rgb(231, 212, 232),
    Rgb(217, 240, 211),
    Rgb(166, 219, 160),
    Rgb(90, 174, 97),
    Rgb(27, 120, 55),
  ],
  [
    Rgb(118, 42, 131),
    Rgb(153, 112, 171),
    Rgb(194, 165, 207),
    Rgb(231, 212, 232),
    Rgb(247, 247, 247),
    Rgb(217, 240, 211),
    Rgb(166, 219, 160),
    Rgb(90, 174, 97),
    Rgb(27, 120, 55),
  ],
  [
    Rgb(64, 0, 75),
    Rgb(118, 42, 131),
    Rgb(153, 112, 171),
    Rgb(194, 165, 207),
    Rgb(231, 212, 232),
    Rgb(217, 240, 211),
    Rgb(166, 219, 160),
    Rgb(90, 174, 97),
    Rgb(27, 120, 55),
    Rgb(0, 68, 27),
  ],
  [
    Rgb(64, 0, 75),
    Rgb(118, 42, 131),
    Rgb(153, 112, 171),
    Rgb(194, 165, 207),
    Rgb(231, 212, 232),
    Rgb(247, 247, 247),
    Rgb(217, 240, 211),
    Rgb(166, 219, 160),
    Rgb(90, 174, 97),
    Rgb(27, 120, 55),
    Rgb(0, 68, 27),
  ],
];

/// diverging/PRGn.js the default export (`interpolatePRGn` of index.js): the
/// continuous RGB B-spline interpolator for [schemePRGn].
final Rgb Function(double t) interpolatePRGn = ramp(schemePRGn);
