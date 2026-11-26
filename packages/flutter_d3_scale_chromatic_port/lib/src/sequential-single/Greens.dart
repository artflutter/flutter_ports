// Ported from d3-scale-chromatic v3.1.0 src/sequential-single/Greens.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/sequential-single/Greens.js` of d3-scale-chromatic 3.1.0: the sequential single-hue
/// ColorBrewer color scheme [schemeGreens]
/// and interpolator [interpolateGreens].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// sequential-single/Greens.js:4 `scheme` (`schemeGreens` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 9);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
const List<List<Rgb>?> schemeGreens = [
  null,
  null,
  null,
  [Rgb(229, 245, 224), Rgb(161, 217, 155), Rgb(49, 163, 84)],
  [
    Rgb(237, 248, 233),
    Rgb(186, 228, 179),
    Rgb(116, 196, 118),
    Rgb(35, 139, 69),
  ],
  [
    Rgb(237, 248, 233),
    Rgb(186, 228, 179),
    Rgb(116, 196, 118),
    Rgb(49, 163, 84),
    Rgb(0, 109, 44),
  ],
  [
    Rgb(237, 248, 233),
    Rgb(199, 233, 192),
    Rgb(161, 217, 155),
    Rgb(116, 196, 118),
    Rgb(49, 163, 84),
    Rgb(0, 109, 44),
  ],
  [
    Rgb(237, 248, 233),
    Rgb(199, 233, 192),
    Rgb(161, 217, 155),
    Rgb(116, 196, 118),
    Rgb(65, 171, 93),
    Rgb(35, 139, 69),
    Rgb(0, 90, 50),
  ],
  [
    Rgb(247, 252, 245),
    Rgb(229, 245, 224),
    Rgb(199, 233, 192),
    Rgb(161, 217, 155),
    Rgb(116, 196, 118),
    Rgb(65, 171, 93),
    Rgb(35, 139, 69),
    Rgb(0, 90, 50),
  ],
  [
    Rgb(247, 252, 245),
    Rgb(229, 245, 224),
    Rgb(199, 233, 192),
    Rgb(161, 217, 155),
    Rgb(116, 196, 118),
    Rgb(65, 171, 93),
    Rgb(35, 139, 69),
    Rgb(0, 109, 44),
    Rgb(0, 68, 27),
  ],
];

/// sequential-single/Greens.js the default export (`interpolateGreens` of index.js): the
/// continuous RGB B-spline interpolator for [schemeGreens].
final Rgb Function(double t) interpolateGreens = ramp(schemeGreens);
