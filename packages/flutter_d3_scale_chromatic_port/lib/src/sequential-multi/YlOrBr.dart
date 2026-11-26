// Ported from d3-scale-chromatic v3.1.0 src/sequential-multi/YlOrBr.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/sequential-multi/YlOrBr.js` of d3-scale-chromatic 3.1.0: the sequential multi-hue
/// ColorBrewer color scheme [schemeYlOrBr]
/// and interpolator [interpolateYlOrBr].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// sequential-multi/YlOrBr.js:4 `scheme` (`schemeYlOrBr` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 9);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
const List<List<Rgb>?> schemeYlOrBr = [
  null,
  null,
  null,
  [Rgb(255, 247, 188), Rgb(254, 196, 79), Rgb(217, 95, 14)],
  [Rgb(255, 255, 212), Rgb(254, 217, 142), Rgb(254, 153, 41), Rgb(204, 76, 2)],
  [
    Rgb(255, 255, 212),
    Rgb(254, 217, 142),
    Rgb(254, 153, 41),
    Rgb(217, 95, 14),
    Rgb(153, 52, 4),
  ],
  [
    Rgb(255, 255, 212),
    Rgb(254, 227, 145),
    Rgb(254, 196, 79),
    Rgb(254, 153, 41),
    Rgb(217, 95, 14),
    Rgb(153, 52, 4),
  ],
  [
    Rgb(255, 255, 212),
    Rgb(254, 227, 145),
    Rgb(254, 196, 79),
    Rgb(254, 153, 41),
    Rgb(236, 112, 20),
    Rgb(204, 76, 2),
    Rgb(140, 45, 4),
  ],
  [
    Rgb(255, 255, 229),
    Rgb(255, 247, 188),
    Rgb(254, 227, 145),
    Rgb(254, 196, 79),
    Rgb(254, 153, 41),
    Rgb(236, 112, 20),
    Rgb(204, 76, 2),
    Rgb(140, 45, 4),
  ],
  [
    Rgb(255, 255, 229),
    Rgb(255, 247, 188),
    Rgb(254, 227, 145),
    Rgb(254, 196, 79),
    Rgb(254, 153, 41),
    Rgb(236, 112, 20),
    Rgb(204, 76, 2),
    Rgb(153, 52, 4),
    Rgb(102, 37, 6),
  ],
];

/// sequential-multi/YlOrBr.js the default export (`interpolateYlOrBr` of index.js): the
/// continuous RGB B-spline interpolator for [schemeYlOrBr].
final Rgb Function(double t) interpolateYlOrBr = ramp(schemeYlOrBr);
