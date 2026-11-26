// Ported from d3-scale-chromatic v3.1.0 src/sequential-single/Blues.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/sequential-single/Blues.js` of d3-scale-chromatic 3.1.0: the sequential single-hue
/// ColorBrewer color scheme [schemeBlues] and interpolator [interpolateBlues].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// sequential-single/Blues.js:4 `scheme` (`schemeBlues` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 9);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
const List<List<Rgb>?> schemeBlues = [
  null,
  null,
  null,
  [Rgb(222, 235, 247), Rgb(158, 202, 225), Rgb(49, 130, 189)],
  [
    Rgb(239, 243, 255),
    Rgb(189, 215, 231),
    Rgb(107, 174, 214),
    Rgb(33, 113, 181),
  ],
  [
    Rgb(239, 243, 255),
    Rgb(189, 215, 231),
    Rgb(107, 174, 214),
    Rgb(49, 130, 189),
    Rgb(8, 81, 156),
  ],
  [
    Rgb(239, 243, 255),
    Rgb(198, 219, 239),
    Rgb(158, 202, 225),
    Rgb(107, 174, 214),
    Rgb(49, 130, 189),
    Rgb(8, 81, 156),
  ],
  [
    Rgb(239, 243, 255),
    Rgb(198, 219, 239),
    Rgb(158, 202, 225),
    Rgb(107, 174, 214),
    Rgb(66, 146, 198),
    Rgb(33, 113, 181),
    Rgb(8, 69, 148),
  ],
  [
    Rgb(247, 251, 255),
    Rgb(222, 235, 247),
    Rgb(198, 219, 239),
    Rgb(158, 202, 225),
    Rgb(107, 174, 214),
    Rgb(66, 146, 198),
    Rgb(33, 113, 181),
    Rgb(8, 69, 148),
  ],
  [
    Rgb(247, 251, 255),
    Rgb(222, 235, 247),
    Rgb(198, 219, 239),
    Rgb(158, 202, 225),
    Rgb(107, 174, 214),
    Rgb(66, 146, 198),
    Rgb(33, 113, 181),
    Rgb(8, 81, 156),
    Rgb(8, 48, 107),
  ],
];

/// sequential-single/Blues.js the default export (`interpolateBlues` of index.js): the
/// continuous RGB B-spline interpolator for [schemeBlues].
final Rgb Function(double t) interpolateBlues = ramp(schemeBlues);
