// Ported from d3-scale-chromatic v3.1.0 src/sequential-multi/YlOrRd.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/sequential-multi/YlOrRd.js` of d3-scale-chromatic 3.1.0: the sequential multi-hue
/// ColorBrewer color scheme [schemeYlOrRd]
/// and interpolator [interpolateYlOrRd].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// sequential-multi/YlOrRd.js:4 `scheme` (`schemeYlOrRd` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 9);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
const List<List<Rgb>?> schemeYlOrRd = [
  null,
  null,
  null,
  [Rgb(255, 237, 160), Rgb(254, 178, 76), Rgb(240, 59, 32)],
  [Rgb(255, 255, 178), Rgb(254, 204, 92), Rgb(253, 141, 60), Rgb(227, 26, 28)],
  [
    Rgb(255, 255, 178),
    Rgb(254, 204, 92),
    Rgb(253, 141, 60),
    Rgb(240, 59, 32),
    Rgb(189, 0, 38),
  ],
  [
    Rgb(255, 255, 178),
    Rgb(254, 217, 118),
    Rgb(254, 178, 76),
    Rgb(253, 141, 60),
    Rgb(240, 59, 32),
    Rgb(189, 0, 38),
  ],
  [
    Rgb(255, 255, 178),
    Rgb(254, 217, 118),
    Rgb(254, 178, 76),
    Rgb(253, 141, 60),
    Rgb(252, 78, 42),
    Rgb(227, 26, 28),
    Rgb(177, 0, 38),
  ],
  [
    Rgb(255, 255, 204),
    Rgb(255, 237, 160),
    Rgb(254, 217, 118),
    Rgb(254, 178, 76),
    Rgb(253, 141, 60),
    Rgb(252, 78, 42),
    Rgb(227, 26, 28),
    Rgb(177, 0, 38),
  ],
  [
    Rgb(255, 255, 204),
    Rgb(255, 237, 160),
    Rgb(254, 217, 118),
    Rgb(254, 178, 76),
    Rgb(253, 141, 60),
    Rgb(252, 78, 42),
    Rgb(227, 26, 28),
    Rgb(189, 0, 38),
    Rgb(128, 0, 38),
  ],
];

/// sequential-multi/YlOrRd.js the default export (`interpolateYlOrRd` of index.js): the
/// continuous RGB B-spline interpolator for [schemeYlOrRd].
final Rgb Function(double t) interpolateYlOrRd = ramp(schemeYlOrRd);
