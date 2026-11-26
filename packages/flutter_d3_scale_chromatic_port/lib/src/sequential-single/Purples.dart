// Ported from d3-scale-chromatic v3.1.0 src/sequential-single/Purples.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/sequential-single/Purples.js` of d3-scale-chromatic 3.1.0: the sequential single-hue
/// ColorBrewer color scheme [schemePurples]
/// and interpolator [interpolatePurples].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// sequential-single/Purples.js:4 `scheme` (`schemePurples` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 9);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
const List<List<Rgb>?> schemePurples = [
  null,
  null,
  null,
  [Rgb(239, 237, 245), Rgb(188, 189, 220), Rgb(117, 107, 177)],
  [
    Rgb(242, 240, 247),
    Rgb(203, 201, 226),
    Rgb(158, 154, 200),
    Rgb(106, 81, 163),
  ],
  [
    Rgb(242, 240, 247),
    Rgb(203, 201, 226),
    Rgb(158, 154, 200),
    Rgb(117, 107, 177),
    Rgb(84, 39, 143),
  ],
  [
    Rgb(242, 240, 247),
    Rgb(218, 218, 235),
    Rgb(188, 189, 220),
    Rgb(158, 154, 200),
    Rgb(117, 107, 177),
    Rgb(84, 39, 143),
  ],
  [
    Rgb(242, 240, 247),
    Rgb(218, 218, 235),
    Rgb(188, 189, 220),
    Rgb(158, 154, 200),
    Rgb(128, 125, 186),
    Rgb(106, 81, 163),
    Rgb(74, 20, 134),
  ],
  [
    Rgb(252, 251, 253),
    Rgb(239, 237, 245),
    Rgb(218, 218, 235),
    Rgb(188, 189, 220),
    Rgb(158, 154, 200),
    Rgb(128, 125, 186),
    Rgb(106, 81, 163),
    Rgb(74, 20, 134),
  ],
  [
    Rgb(252, 251, 253),
    Rgb(239, 237, 245),
    Rgb(218, 218, 235),
    Rgb(188, 189, 220),
    Rgb(158, 154, 200),
    Rgb(128, 125, 186),
    Rgb(106, 81, 163),
    Rgb(84, 39, 143),
    Rgb(63, 0, 125),
  ],
];

/// sequential-single/Purples.js the default export (`interpolatePurples` of index.js): the
/// continuous RGB B-spline interpolator for [schemePurples].
final Rgb Function(double t) interpolatePurples = ramp(schemePurples);
