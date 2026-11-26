// Ported from d3-scale-chromatic v3.1.0 src/sequential-multi/YlGn.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/sequential-multi/YlGn.js` of d3-scale-chromatic 3.1.0: the sequential multi-hue
/// ColorBrewer color scheme [schemeYlGn] and interpolator [interpolateYlGn].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// sequential-multi/YlGn.js:4 `scheme` (`schemeYlGn` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 9);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
const List<List<Rgb>?> schemeYlGn = [
  null,
  null,
  null,
  [Rgb(247, 252, 185), Rgb(173, 221, 142), Rgb(49, 163, 84)],
  [
    Rgb(255, 255, 204),
    Rgb(194, 230, 153),
    Rgb(120, 198, 121),
    Rgb(35, 132, 67),
  ],
  [
    Rgb(255, 255, 204),
    Rgb(194, 230, 153),
    Rgb(120, 198, 121),
    Rgb(49, 163, 84),
    Rgb(0, 104, 55),
  ],
  [
    Rgb(255, 255, 204),
    Rgb(217, 240, 163),
    Rgb(173, 221, 142),
    Rgb(120, 198, 121),
    Rgb(49, 163, 84),
    Rgb(0, 104, 55),
  ],
  [
    Rgb(255, 255, 204),
    Rgb(217, 240, 163),
    Rgb(173, 221, 142),
    Rgb(120, 198, 121),
    Rgb(65, 171, 93),
    Rgb(35, 132, 67),
    Rgb(0, 90, 50),
  ],
  [
    Rgb(255, 255, 229),
    Rgb(247, 252, 185),
    Rgb(217, 240, 163),
    Rgb(173, 221, 142),
    Rgb(120, 198, 121),
    Rgb(65, 171, 93),
    Rgb(35, 132, 67),
    Rgb(0, 90, 50),
  ],
  [
    Rgb(255, 255, 229),
    Rgb(247, 252, 185),
    Rgb(217, 240, 163),
    Rgb(173, 221, 142),
    Rgb(120, 198, 121),
    Rgb(65, 171, 93),
    Rgb(35, 132, 67),
    Rgb(0, 104, 55),
    Rgb(0, 69, 41),
  ],
];

/// sequential-multi/YlGn.js the default export (`interpolateYlGn` of index.js): the
/// continuous RGB B-spline interpolator for [schemeYlGn].
final Rgb Function(double t) interpolateYlGn = ramp(schemeYlGn);
