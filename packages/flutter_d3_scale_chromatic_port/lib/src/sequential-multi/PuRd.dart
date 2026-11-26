// Ported from d3-scale-chromatic v3.1.0 src/sequential-multi/PuRd.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/sequential-multi/PuRd.js` of d3-scale-chromatic 3.1.0: the sequential multi-hue
/// ColorBrewer color scheme [schemePuRd] and interpolator [interpolatePuRd].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// sequential-multi/PuRd.js:4 `scheme` (`schemePuRd` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 9);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
const List<List<Rgb>?> schemePuRd = [
  null,
  null,
  null,
  [Rgb(231, 225, 239), Rgb(201, 148, 199), Rgb(221, 28, 119)],
  [
    Rgb(241, 238, 246),
    Rgb(215, 181, 216),
    Rgb(223, 101, 176),
    Rgb(206, 18, 86),
  ],
  [
    Rgb(241, 238, 246),
    Rgb(215, 181, 216),
    Rgb(223, 101, 176),
    Rgb(221, 28, 119),
    Rgb(152, 0, 67),
  ],
  [
    Rgb(241, 238, 246),
    Rgb(212, 185, 218),
    Rgb(201, 148, 199),
    Rgb(223, 101, 176),
    Rgb(221, 28, 119),
    Rgb(152, 0, 67),
  ],
  [
    Rgb(241, 238, 246),
    Rgb(212, 185, 218),
    Rgb(201, 148, 199),
    Rgb(223, 101, 176),
    Rgb(231, 41, 138),
    Rgb(206, 18, 86),
    Rgb(145, 0, 63),
  ],
  [
    Rgb(247, 244, 249),
    Rgb(231, 225, 239),
    Rgb(212, 185, 218),
    Rgb(201, 148, 199),
    Rgb(223, 101, 176),
    Rgb(231, 41, 138),
    Rgb(206, 18, 86),
    Rgb(145, 0, 63),
  ],
  [
    Rgb(247, 244, 249),
    Rgb(231, 225, 239),
    Rgb(212, 185, 218),
    Rgb(201, 148, 199),
    Rgb(223, 101, 176),
    Rgb(231, 41, 138),
    Rgb(206, 18, 86),
    Rgb(152, 0, 67),
    Rgb(103, 0, 31),
  ],
];

/// sequential-multi/PuRd.js the default export (`interpolatePuRd` of index.js): the
/// continuous RGB B-spline interpolator for [schemePuRd].
final Rgb Function(double t) interpolatePuRd = ramp(schemePuRd);
