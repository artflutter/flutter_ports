// Ported from d3-scale-chromatic v3.1.0 src/diverging/BrBG.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/diverging/BrBG.js` of d3-scale-chromatic 3.1.0: the diverging
/// ColorBrewer color scheme [schemeBrBG] and interpolator [interpolateBrBG].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// diverging/BrBG.js:4 `scheme` (`schemeBrBG` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 11);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
const List<List<Rgb>?> schemeBrBG = [
  null,
  null,
  null,
  [Rgb(216, 179, 101), Rgb(245, 245, 245), Rgb(90, 180, 172)],
  [Rgb(166, 97, 26), Rgb(223, 194, 125), Rgb(128, 205, 193), Rgb(1, 133, 113)],
  [
    Rgb(166, 97, 26),
    Rgb(223, 194, 125),
    Rgb(245, 245, 245),
    Rgb(128, 205, 193),
    Rgb(1, 133, 113),
  ],
  [
    Rgb(140, 81, 10),
    Rgb(216, 179, 101),
    Rgb(246, 232, 195),
    Rgb(199, 234, 229),
    Rgb(90, 180, 172),
    Rgb(1, 102, 94),
  ],
  [
    Rgb(140, 81, 10),
    Rgb(216, 179, 101),
    Rgb(246, 232, 195),
    Rgb(245, 245, 245),
    Rgb(199, 234, 229),
    Rgb(90, 180, 172),
    Rgb(1, 102, 94),
  ],
  [
    Rgb(140, 81, 10),
    Rgb(191, 129, 45),
    Rgb(223, 194, 125),
    Rgb(246, 232, 195),
    Rgb(199, 234, 229),
    Rgb(128, 205, 193),
    Rgb(53, 151, 143),
    Rgb(1, 102, 94),
  ],
  [
    Rgb(140, 81, 10),
    Rgb(191, 129, 45),
    Rgb(223, 194, 125),
    Rgb(246, 232, 195),
    Rgb(245, 245, 245),
    Rgb(199, 234, 229),
    Rgb(128, 205, 193),
    Rgb(53, 151, 143),
    Rgb(1, 102, 94),
  ],
  [
    Rgb(84, 48, 5),
    Rgb(140, 81, 10),
    Rgb(191, 129, 45),
    Rgb(223, 194, 125),
    Rgb(246, 232, 195),
    Rgb(199, 234, 229),
    Rgb(128, 205, 193),
    Rgb(53, 151, 143),
    Rgb(1, 102, 94),
    Rgb(0, 60, 48),
  ],
  [
    Rgb(84, 48, 5),
    Rgb(140, 81, 10),
    Rgb(191, 129, 45),
    Rgb(223, 194, 125),
    Rgb(246, 232, 195),
    Rgb(245, 245, 245),
    Rgb(199, 234, 229),
    Rgb(128, 205, 193),
    Rgb(53, 151, 143),
    Rgb(1, 102, 94),
    Rgb(0, 60, 48),
  ],
];

/// diverging/BrBG.js the default export (`interpolateBrBG` of index.js): the
/// continuous RGB B-spline interpolator for [schemeBrBG].
final Rgb Function(double t) interpolateBrBG = ramp(schemeBrBG);
