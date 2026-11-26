// Ported from d3-scale-chromatic v3.1.0 src/sequential-multi/PuBu.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/sequential-multi/PuBu.js` of d3-scale-chromatic 3.1.0: the sequential multi-hue
/// ColorBrewer color scheme [schemePuBu] and interpolator [interpolatePuBu].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// sequential-multi/PuBu.js:4 `scheme` (`schemePuBu` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 9);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
const List<List<Rgb>?> schemePuBu = [
  null,
  null,
  null,
  [Rgb(236, 231, 242), Rgb(166, 189, 219), Rgb(43, 140, 190)],
  [
    Rgb(241, 238, 246),
    Rgb(189, 201, 225),
    Rgb(116, 169, 207),
    Rgb(5, 112, 176),
  ],
  [
    Rgb(241, 238, 246),
    Rgb(189, 201, 225),
    Rgb(116, 169, 207),
    Rgb(43, 140, 190),
    Rgb(4, 90, 141),
  ],
  [
    Rgb(241, 238, 246),
    Rgb(208, 209, 230),
    Rgb(166, 189, 219),
    Rgb(116, 169, 207),
    Rgb(43, 140, 190),
    Rgb(4, 90, 141),
  ],
  [
    Rgb(241, 238, 246),
    Rgb(208, 209, 230),
    Rgb(166, 189, 219),
    Rgb(116, 169, 207),
    Rgb(54, 144, 192),
    Rgb(5, 112, 176),
    Rgb(3, 78, 123),
  ],
  [
    Rgb(255, 247, 251),
    Rgb(236, 231, 242),
    Rgb(208, 209, 230),
    Rgb(166, 189, 219),
    Rgb(116, 169, 207),
    Rgb(54, 144, 192),
    Rgb(5, 112, 176),
    Rgb(3, 78, 123),
  ],
  [
    Rgb(255, 247, 251),
    Rgb(236, 231, 242),
    Rgb(208, 209, 230),
    Rgb(166, 189, 219),
    Rgb(116, 169, 207),
    Rgb(54, 144, 192),
    Rgb(5, 112, 176),
    Rgb(4, 90, 141),
    Rgb(2, 56, 88),
  ],
];

/// sequential-multi/PuBu.js the default export (`interpolatePuBu` of index.js): the
/// continuous RGB B-spline interpolator for [schemePuBu].
final Rgb Function(double t) interpolatePuBu = ramp(schemePuBu);
