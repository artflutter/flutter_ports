// Ported from d3-scale-chromatic v3.1.0 src/sequential-single/Reds.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/sequential-single/Reds.js` of d3-scale-chromatic 3.1.0: the sequential single-hue
/// ColorBrewer color scheme [schemeReds] and interpolator [interpolateReds].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// sequential-single/Reds.js:4 `scheme` (`schemeReds` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 9);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
const List<List<Rgb>?> schemeReds = [
  null,
  null,
  null,
  [Rgb(254, 224, 210), Rgb(252, 146, 114), Rgb(222, 45, 38)],
  [Rgb(254, 229, 217), Rgb(252, 174, 145), Rgb(251, 106, 74), Rgb(203, 24, 29)],
  [
    Rgb(254, 229, 217),
    Rgb(252, 174, 145),
    Rgb(251, 106, 74),
    Rgb(222, 45, 38),
    Rgb(165, 15, 21),
  ],
  [
    Rgb(254, 229, 217),
    Rgb(252, 187, 161),
    Rgb(252, 146, 114),
    Rgb(251, 106, 74),
    Rgb(222, 45, 38),
    Rgb(165, 15, 21),
  ],
  [
    Rgb(254, 229, 217),
    Rgb(252, 187, 161),
    Rgb(252, 146, 114),
    Rgb(251, 106, 74),
    Rgb(239, 59, 44),
    Rgb(203, 24, 29),
    Rgb(153, 0, 13),
  ],
  [
    Rgb(255, 245, 240),
    Rgb(254, 224, 210),
    Rgb(252, 187, 161),
    Rgb(252, 146, 114),
    Rgb(251, 106, 74),
    Rgb(239, 59, 44),
    Rgb(203, 24, 29),
    Rgb(153, 0, 13),
  ],
  [
    Rgb(255, 245, 240),
    Rgb(254, 224, 210),
    Rgb(252, 187, 161),
    Rgb(252, 146, 114),
    Rgb(251, 106, 74),
    Rgb(239, 59, 44),
    Rgb(203, 24, 29),
    Rgb(165, 15, 21),
    Rgb(103, 0, 13),
  ],
];

/// sequential-single/Reds.js the default export (`interpolateReds` of index.js): the
/// continuous RGB B-spline interpolator for [schemeReds].
final Rgb Function(double t) interpolateReds = ramp(schemeReds);
