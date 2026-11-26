// Ported from d3-scale-chromatic v3.1.0 src/diverging/RdBu.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/diverging/RdBu.js` of d3-scale-chromatic 3.1.0: the diverging
/// ColorBrewer color scheme [schemeRdBu] and interpolator [interpolateRdBu].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// diverging/RdBu.js:4 `scheme` (`schemeRdBu` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 11);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
const List<List<Rgb>?> schemeRdBu = [
  null,
  null,
  null,
  [Rgb(239, 138, 98), Rgb(247, 247, 247), Rgb(103, 169, 207)],
  [Rgb(202, 0, 32), Rgb(244, 165, 130), Rgb(146, 197, 222), Rgb(5, 113, 176)],
  [
    Rgb(202, 0, 32),
    Rgb(244, 165, 130),
    Rgb(247, 247, 247),
    Rgb(146, 197, 222),
    Rgb(5, 113, 176),
  ],
  [
    Rgb(178, 24, 43),
    Rgb(239, 138, 98),
    Rgb(253, 219, 199),
    Rgb(209, 229, 240),
    Rgb(103, 169, 207),
    Rgb(33, 102, 172),
  ],
  [
    Rgb(178, 24, 43),
    Rgb(239, 138, 98),
    Rgb(253, 219, 199),
    Rgb(247, 247, 247),
    Rgb(209, 229, 240),
    Rgb(103, 169, 207),
    Rgb(33, 102, 172),
  ],
  [
    Rgb(178, 24, 43),
    Rgb(214, 96, 77),
    Rgb(244, 165, 130),
    Rgb(253, 219, 199),
    Rgb(209, 229, 240),
    Rgb(146, 197, 222),
    Rgb(67, 147, 195),
    Rgb(33, 102, 172),
  ],
  [
    Rgb(178, 24, 43),
    Rgb(214, 96, 77),
    Rgb(244, 165, 130),
    Rgb(253, 219, 199),
    Rgb(247, 247, 247),
    Rgb(209, 229, 240),
    Rgb(146, 197, 222),
    Rgb(67, 147, 195),
    Rgb(33, 102, 172),
  ],
  [
    Rgb(103, 0, 31),
    Rgb(178, 24, 43),
    Rgb(214, 96, 77),
    Rgb(244, 165, 130),
    Rgb(253, 219, 199),
    Rgb(209, 229, 240),
    Rgb(146, 197, 222),
    Rgb(67, 147, 195),
    Rgb(33, 102, 172),
    Rgb(5, 48, 97),
  ],
  [
    Rgb(103, 0, 31),
    Rgb(178, 24, 43),
    Rgb(214, 96, 77),
    Rgb(244, 165, 130),
    Rgb(253, 219, 199),
    Rgb(247, 247, 247),
    Rgb(209, 229, 240),
    Rgb(146, 197, 222),
    Rgb(67, 147, 195),
    Rgb(33, 102, 172),
    Rgb(5, 48, 97),
  ],
];

/// diverging/RdBu.js the default export (`interpolateRdBu` of index.js): the
/// continuous RGB B-spline interpolator for [schemeRdBu].
final Rgb Function(double t) interpolateRdBu = ramp(schemeRdBu);
