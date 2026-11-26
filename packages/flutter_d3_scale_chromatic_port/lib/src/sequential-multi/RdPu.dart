// Ported from d3-scale-chromatic v3.1.0 src/sequential-multi/RdPu.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/sequential-multi/RdPu.js` of d3-scale-chromatic 3.1.0: the sequential multi-hue
/// ColorBrewer color scheme [schemeRdPu] and interpolator [interpolateRdPu].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// sequential-multi/RdPu.js:4 `scheme` (`schemeRdPu` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 9);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
const List<List<Rgb>?> schemeRdPu = [
  null,
  null,
  null,
  [Rgb(253, 224, 221), Rgb(250, 159, 181), Rgb(197, 27, 138)],
  [
    Rgb(254, 235, 226),
    Rgb(251, 180, 185),
    Rgb(247, 104, 161),
    Rgb(174, 1, 126),
  ],
  [
    Rgb(254, 235, 226),
    Rgb(251, 180, 185),
    Rgb(247, 104, 161),
    Rgb(197, 27, 138),
    Rgb(122, 1, 119),
  ],
  [
    Rgb(254, 235, 226),
    Rgb(252, 197, 192),
    Rgb(250, 159, 181),
    Rgb(247, 104, 161),
    Rgb(197, 27, 138),
    Rgb(122, 1, 119),
  ],
  [
    Rgb(254, 235, 226),
    Rgb(252, 197, 192),
    Rgb(250, 159, 181),
    Rgb(247, 104, 161),
    Rgb(221, 52, 151),
    Rgb(174, 1, 126),
    Rgb(122, 1, 119),
  ],
  [
    Rgb(255, 247, 243),
    Rgb(253, 224, 221),
    Rgb(252, 197, 192),
    Rgb(250, 159, 181),
    Rgb(247, 104, 161),
    Rgb(221, 52, 151),
    Rgb(174, 1, 126),
    Rgb(122, 1, 119),
  ],
  [
    Rgb(255, 247, 243),
    Rgb(253, 224, 221),
    Rgb(252, 197, 192),
    Rgb(250, 159, 181),
    Rgb(247, 104, 161),
    Rgb(221, 52, 151),
    Rgb(174, 1, 126),
    Rgb(122, 1, 119),
    Rgb(73, 0, 106),
  ],
];

/// sequential-multi/RdPu.js the default export (`interpolateRdPu` of index.js): the
/// continuous RGB B-spline interpolator for [schemeRdPu].
final Rgb Function(double t) interpolateRdPu = ramp(schemeRdPu);
