// Ported from d3-scale-chromatic v3.1.0 src/sequential-multi/OrRd.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/sequential-multi/OrRd.js` of d3-scale-chromatic 3.1.0: the sequential multi-hue
/// ColorBrewer color scheme [schemeOrRd] and interpolator [interpolateOrRd].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// sequential-multi/OrRd.js:4 `scheme` (`schemeOrRd` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 9);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
const List<List<Rgb>?> schemeOrRd = [
  null,
  null,
  null,
  [Rgb(254, 232, 200), Rgb(253, 187, 132), Rgb(227, 74, 51)],
  [Rgb(254, 240, 217), Rgb(253, 204, 138), Rgb(252, 141, 89), Rgb(215, 48, 31)],
  [
    Rgb(254, 240, 217),
    Rgb(253, 204, 138),
    Rgb(252, 141, 89),
    Rgb(227, 74, 51),
    Rgb(179, 0, 0),
  ],
  [
    Rgb(254, 240, 217),
    Rgb(253, 212, 158),
    Rgb(253, 187, 132),
    Rgb(252, 141, 89),
    Rgb(227, 74, 51),
    Rgb(179, 0, 0),
  ],
  [
    Rgb(254, 240, 217),
    Rgb(253, 212, 158),
    Rgb(253, 187, 132),
    Rgb(252, 141, 89),
    Rgb(239, 101, 72),
    Rgb(215, 48, 31),
    Rgb(153, 0, 0),
  ],
  [
    Rgb(255, 247, 236),
    Rgb(254, 232, 200),
    Rgb(253, 212, 158),
    Rgb(253, 187, 132),
    Rgb(252, 141, 89),
    Rgb(239, 101, 72),
    Rgb(215, 48, 31),
    Rgb(153, 0, 0),
  ],
  [
    Rgb(255, 247, 236),
    Rgb(254, 232, 200),
    Rgb(253, 212, 158),
    Rgb(253, 187, 132),
    Rgb(252, 141, 89),
    Rgb(239, 101, 72),
    Rgb(215, 48, 31),
    Rgb(179, 0, 0),
    Rgb(127, 0, 0),
  ],
];

/// sequential-multi/OrRd.js the default export (`interpolateOrRd` of index.js): the
/// continuous RGB B-spline interpolator for [schemeOrRd].
final Rgb Function(double t) interpolateOrRd = ramp(schemeOrRd);
