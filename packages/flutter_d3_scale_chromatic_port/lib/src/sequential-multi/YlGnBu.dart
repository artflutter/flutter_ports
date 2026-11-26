// Ported from d3-scale-chromatic v3.1.0 src/sequential-multi/YlGnBu.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/sequential-multi/YlGnBu.js` of d3-scale-chromatic 3.1.0: the sequential multi-hue
/// ColorBrewer color scheme [schemeYlGnBu]
/// and interpolator [interpolateYlGnBu].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// sequential-multi/YlGnBu.js:4 `scheme` (`schemeYlGnBu` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 9);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
const List<List<Rgb>?> schemeYlGnBu = [
  null,
  null,
  null,
  [Rgb(237, 248, 177), Rgb(127, 205, 187), Rgb(44, 127, 184)],
  [Rgb(255, 255, 204), Rgb(161, 218, 180), Rgb(65, 182, 196), Rgb(34, 94, 168)],
  [
    Rgb(255, 255, 204),
    Rgb(161, 218, 180),
    Rgb(65, 182, 196),
    Rgb(44, 127, 184),
    Rgb(37, 52, 148),
  ],
  [
    Rgb(255, 255, 204),
    Rgb(199, 233, 180),
    Rgb(127, 205, 187),
    Rgb(65, 182, 196),
    Rgb(44, 127, 184),
    Rgb(37, 52, 148),
  ],
  [
    Rgb(255, 255, 204),
    Rgb(199, 233, 180),
    Rgb(127, 205, 187),
    Rgb(65, 182, 196),
    Rgb(29, 145, 192),
    Rgb(34, 94, 168),
    Rgb(12, 44, 132),
  ],
  [
    Rgb(255, 255, 217),
    Rgb(237, 248, 177),
    Rgb(199, 233, 180),
    Rgb(127, 205, 187),
    Rgb(65, 182, 196),
    Rgb(29, 145, 192),
    Rgb(34, 94, 168),
    Rgb(12, 44, 132),
  ],
  [
    Rgb(255, 255, 217),
    Rgb(237, 248, 177),
    Rgb(199, 233, 180),
    Rgb(127, 205, 187),
    Rgb(65, 182, 196),
    Rgb(29, 145, 192),
    Rgb(34, 94, 168),
    Rgb(37, 52, 148),
    Rgb(8, 29, 88),
  ],
];

/// sequential-multi/YlGnBu.js the default export (`interpolateYlGnBu` of index.js): the
/// continuous RGB B-spline interpolator for [schemeYlGnBu].
final Rgb Function(double t) interpolateYlGnBu = ramp(schemeYlGnBu);
