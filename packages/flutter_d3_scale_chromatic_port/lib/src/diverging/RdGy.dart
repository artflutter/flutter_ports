// Ported from d3-scale-chromatic v3.1.0 src/diverging/RdGy.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/diverging/RdGy.js` of d3-scale-chromatic 3.1.0: the diverging
/// ColorBrewer color scheme [schemeRdGy] and interpolator [interpolateRdGy].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// diverging/RdGy.js:4 `scheme` (`schemeRdGy` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 11);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
const List<List<Rgb>?> schemeRdGy = [
  null,
  null,
  null,
  [Rgb(239, 138, 98), Rgb(255, 255, 255), Rgb(153, 153, 153)],
  [Rgb(202, 0, 32), Rgb(244, 165, 130), Rgb(186, 186, 186), Rgb(64, 64, 64)],
  [
    Rgb(202, 0, 32),
    Rgb(244, 165, 130),
    Rgb(255, 255, 255),
    Rgb(186, 186, 186),
    Rgb(64, 64, 64),
  ],
  [
    Rgb(178, 24, 43),
    Rgb(239, 138, 98),
    Rgb(253, 219, 199),
    Rgb(224, 224, 224),
    Rgb(153, 153, 153),
    Rgb(77, 77, 77),
  ],
  [
    Rgb(178, 24, 43),
    Rgb(239, 138, 98),
    Rgb(253, 219, 199),
    Rgb(255, 255, 255),
    Rgb(224, 224, 224),
    Rgb(153, 153, 153),
    Rgb(77, 77, 77),
  ],
  [
    Rgb(178, 24, 43),
    Rgb(214, 96, 77),
    Rgb(244, 165, 130),
    Rgb(253, 219, 199),
    Rgb(224, 224, 224),
    Rgb(186, 186, 186),
    Rgb(135, 135, 135),
    Rgb(77, 77, 77),
  ],
  [
    Rgb(178, 24, 43),
    Rgb(214, 96, 77),
    Rgb(244, 165, 130),
    Rgb(253, 219, 199),
    Rgb(255, 255, 255),
    Rgb(224, 224, 224),
    Rgb(186, 186, 186),
    Rgb(135, 135, 135),
    Rgb(77, 77, 77),
  ],
  [
    Rgb(103, 0, 31),
    Rgb(178, 24, 43),
    Rgb(214, 96, 77),
    Rgb(244, 165, 130),
    Rgb(253, 219, 199),
    Rgb(224, 224, 224),
    Rgb(186, 186, 186),
    Rgb(135, 135, 135),
    Rgb(77, 77, 77),
    Rgb(26, 26, 26),
  ],
  [
    Rgb(103, 0, 31),
    Rgb(178, 24, 43),
    Rgb(214, 96, 77),
    Rgb(244, 165, 130),
    Rgb(253, 219, 199),
    Rgb(255, 255, 255),
    Rgb(224, 224, 224),
    Rgb(186, 186, 186),
    Rgb(135, 135, 135),
    Rgb(77, 77, 77),
    Rgb(26, 26, 26),
  ],
];

/// diverging/RdGy.js the default export (`interpolateRdGy` of index.js): the
/// continuous RGB B-spline interpolator for [schemeRdGy].
final Rgb Function(double t) interpolateRdGy = ramp(schemeRdGy);
