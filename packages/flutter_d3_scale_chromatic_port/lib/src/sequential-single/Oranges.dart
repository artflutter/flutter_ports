// Ported from d3-scale-chromatic v3.1.0 src/sequential-single/Oranges.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/sequential-single/Oranges.js` of d3-scale-chromatic 3.1.0: the sequential single-hue
/// ColorBrewer color scheme [schemeOranges]
/// and interpolator [interpolateOranges].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// sequential-single/Oranges.js:4 `scheme` (`schemeOranges` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 9);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
const List<List<Rgb>?> schemeOranges = [
  null,
  null,
  null,
  [Rgb(254, 230, 206), Rgb(253, 174, 107), Rgb(230, 85, 13)],
  [Rgb(254, 237, 222), Rgb(253, 190, 133), Rgb(253, 141, 60), Rgb(217, 71, 1)],
  [
    Rgb(254, 237, 222),
    Rgb(253, 190, 133),
    Rgb(253, 141, 60),
    Rgb(230, 85, 13),
    Rgb(166, 54, 3),
  ],
  [
    Rgb(254, 237, 222),
    Rgb(253, 208, 162),
    Rgb(253, 174, 107),
    Rgb(253, 141, 60),
    Rgb(230, 85, 13),
    Rgb(166, 54, 3),
  ],
  [
    Rgb(254, 237, 222),
    Rgb(253, 208, 162),
    Rgb(253, 174, 107),
    Rgb(253, 141, 60),
    Rgb(241, 105, 19),
    Rgb(217, 72, 1),
    Rgb(140, 45, 4),
  ],
  [
    Rgb(255, 245, 235),
    Rgb(254, 230, 206),
    Rgb(253, 208, 162),
    Rgb(253, 174, 107),
    Rgb(253, 141, 60),
    Rgb(241, 105, 19),
    Rgb(217, 72, 1),
    Rgb(140, 45, 4),
  ],
  [
    Rgb(255, 245, 235),
    Rgb(254, 230, 206),
    Rgb(253, 208, 162),
    Rgb(253, 174, 107),
    Rgb(253, 141, 60),
    Rgb(241, 105, 19),
    Rgb(217, 72, 1),
    Rgb(166, 54, 3),
    Rgb(127, 39, 4),
  ],
];

/// sequential-single/Oranges.js the default export (`interpolateOranges` of index.js): the
/// continuous RGB B-spline interpolator for [schemeOranges].
final Rgb Function(double t) interpolateOranges = ramp(schemeOranges);
