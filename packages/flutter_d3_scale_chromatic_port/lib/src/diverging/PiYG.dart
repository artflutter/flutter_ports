// Ported from d3-scale-chromatic v3.1.0 src/diverging/PiYG.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/diverging/PiYG.js` of d3-scale-chromatic 3.1.0: the diverging
/// ColorBrewer color scheme [schemePiYG] and interpolator [interpolatePiYG].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// diverging/PiYG.js:4 `scheme` (`schemePiYG` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 11);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
const List<List<Rgb>?> schemePiYG = [
  null,
  null,
  null,
  [Rgb(233, 163, 201), Rgb(247, 247, 247), Rgb(161, 215, 106)],
  [Rgb(208, 28, 139), Rgb(241, 182, 218), Rgb(184, 225, 134), Rgb(77, 172, 38)],
  [
    Rgb(208, 28, 139),
    Rgb(241, 182, 218),
    Rgb(247, 247, 247),
    Rgb(184, 225, 134),
    Rgb(77, 172, 38),
  ],
  [
    Rgb(197, 27, 125),
    Rgb(233, 163, 201),
    Rgb(253, 224, 239),
    Rgb(230, 245, 208),
    Rgb(161, 215, 106),
    Rgb(77, 146, 33),
  ],
  [
    Rgb(197, 27, 125),
    Rgb(233, 163, 201),
    Rgb(253, 224, 239),
    Rgb(247, 247, 247),
    Rgb(230, 245, 208),
    Rgb(161, 215, 106),
    Rgb(77, 146, 33),
  ],
  [
    Rgb(197, 27, 125),
    Rgb(222, 119, 174),
    Rgb(241, 182, 218),
    Rgb(253, 224, 239),
    Rgb(230, 245, 208),
    Rgb(184, 225, 134),
    Rgb(127, 188, 65),
    Rgb(77, 146, 33),
  ],
  [
    Rgb(197, 27, 125),
    Rgb(222, 119, 174),
    Rgb(241, 182, 218),
    Rgb(253, 224, 239),
    Rgb(247, 247, 247),
    Rgb(230, 245, 208),
    Rgb(184, 225, 134),
    Rgb(127, 188, 65),
    Rgb(77, 146, 33),
  ],
  [
    Rgb(142, 1, 82),
    Rgb(197, 27, 125),
    Rgb(222, 119, 174),
    Rgb(241, 182, 218),
    Rgb(253, 224, 239),
    Rgb(230, 245, 208),
    Rgb(184, 225, 134),
    Rgb(127, 188, 65),
    Rgb(77, 146, 33),
    Rgb(39, 100, 25),
  ],
  [
    Rgb(142, 1, 82),
    Rgb(197, 27, 125),
    Rgb(222, 119, 174),
    Rgb(241, 182, 218),
    Rgb(253, 224, 239),
    Rgb(247, 247, 247),
    Rgb(230, 245, 208),
    Rgb(184, 225, 134),
    Rgb(127, 188, 65),
    Rgb(77, 146, 33),
    Rgb(39, 100, 25),
  ],
];

/// diverging/PiYG.js the default export (`interpolatePiYG` of index.js): the
/// continuous RGB B-spline interpolator for [schemePiYG].
final Rgb Function(double t) interpolatePiYG = ramp(schemePiYG);
