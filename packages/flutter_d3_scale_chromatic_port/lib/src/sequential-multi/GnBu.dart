// Ported from d3-scale-chromatic v3.1.0 src/sequential-multi/GnBu.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/sequential-multi/GnBu.js` of d3-scale-chromatic 3.1.0: the sequential multi-hue
/// ColorBrewer color scheme [schemeGnBu] and interpolator [interpolateGnBu].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// sequential-multi/GnBu.js:4 `scheme` (`schemeGnBu` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 9);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
const List<List<Rgb>?> schemeGnBu = [
  null,
  null,
  null,
  [Rgb(224, 243, 219), Rgb(168, 221, 181), Rgb(67, 162, 202)],
  [
    Rgb(240, 249, 232),
    Rgb(186, 228, 188),
    Rgb(123, 204, 196),
    Rgb(43, 140, 190),
  ],
  [
    Rgb(240, 249, 232),
    Rgb(186, 228, 188),
    Rgb(123, 204, 196),
    Rgb(67, 162, 202),
    Rgb(8, 104, 172),
  ],
  [
    Rgb(240, 249, 232),
    Rgb(204, 235, 197),
    Rgb(168, 221, 181),
    Rgb(123, 204, 196),
    Rgb(67, 162, 202),
    Rgb(8, 104, 172),
  ],
  [
    Rgb(240, 249, 232),
    Rgb(204, 235, 197),
    Rgb(168, 221, 181),
    Rgb(123, 204, 196),
    Rgb(78, 179, 211),
    Rgb(43, 140, 190),
    Rgb(8, 88, 158),
  ],
  [
    Rgb(247, 252, 240),
    Rgb(224, 243, 219),
    Rgb(204, 235, 197),
    Rgb(168, 221, 181),
    Rgb(123, 204, 196),
    Rgb(78, 179, 211),
    Rgb(43, 140, 190),
    Rgb(8, 88, 158),
  ],
  [
    Rgb(247, 252, 240),
    Rgb(224, 243, 219),
    Rgb(204, 235, 197),
    Rgb(168, 221, 181),
    Rgb(123, 204, 196),
    Rgb(78, 179, 211),
    Rgb(43, 140, 190),
    Rgb(8, 104, 172),
    Rgb(8, 64, 129),
  ],
];

/// sequential-multi/GnBu.js the default export (`interpolateGnBu` of index.js): the
/// continuous RGB B-spline interpolator for [schemeGnBu].
final Rgb Function(double t) interpolateGnBu = ramp(schemeGnBu);
