// Ported from d3-scale-chromatic v3.1.0 src/sequential-multi/BuGn.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/sequential-multi/BuGn.js` of d3-scale-chromatic 3.1.0: the sequential multi-hue
/// ColorBrewer color scheme [schemeBuGn] and interpolator [interpolateBuGn].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// sequential-multi/BuGn.js:4 `scheme` (`schemeBuGn` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 9);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
const List<List<Rgb>?> schemeBuGn = [
  null,
  null,
  null,
  [Rgb(229, 245, 249), Rgb(153, 216, 201), Rgb(44, 162, 95)],
  [
    Rgb(237, 248, 251),
    Rgb(178, 226, 226),
    Rgb(102, 194, 164),
    Rgb(35, 139, 69),
  ],
  [
    Rgb(237, 248, 251),
    Rgb(178, 226, 226),
    Rgb(102, 194, 164),
    Rgb(44, 162, 95),
    Rgb(0, 109, 44),
  ],
  [
    Rgb(237, 248, 251),
    Rgb(204, 236, 230),
    Rgb(153, 216, 201),
    Rgb(102, 194, 164),
    Rgb(44, 162, 95),
    Rgb(0, 109, 44),
  ],
  [
    Rgb(237, 248, 251),
    Rgb(204, 236, 230),
    Rgb(153, 216, 201),
    Rgb(102, 194, 164),
    Rgb(65, 174, 118),
    Rgb(35, 139, 69),
    Rgb(0, 88, 36),
  ],
  [
    Rgb(247, 252, 253),
    Rgb(229, 245, 249),
    Rgb(204, 236, 230),
    Rgb(153, 216, 201),
    Rgb(102, 194, 164),
    Rgb(65, 174, 118),
    Rgb(35, 139, 69),
    Rgb(0, 88, 36),
  ],
  [
    Rgb(247, 252, 253),
    Rgb(229, 245, 249),
    Rgb(204, 236, 230),
    Rgb(153, 216, 201),
    Rgb(102, 194, 164),
    Rgb(65, 174, 118),
    Rgb(35, 139, 69),
    Rgb(0, 109, 44),
    Rgb(0, 68, 27),
  ],
];

/// sequential-multi/BuGn.js the default export (`interpolateBuGn` of index.js): the
/// continuous RGB B-spline interpolator for [schemeBuGn].
final Rgb Function(double t) interpolateBuGn = ramp(schemeBuGn);
