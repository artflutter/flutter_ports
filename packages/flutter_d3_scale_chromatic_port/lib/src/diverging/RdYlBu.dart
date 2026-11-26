// Ported from d3-scale-chromatic v3.1.0 src/diverging/RdYlBu.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/diverging/RdYlBu.js` of d3-scale-chromatic 3.1.0: the diverging
/// ColorBrewer color scheme [schemeRdYlBu]
/// and interpolator [interpolateRdYlBu].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// diverging/RdYlBu.js:4 `scheme` (`schemeRdYlBu` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 11);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
const List<List<Rgb>?> schemeRdYlBu = [
  null,
  null,
  null,
  [Rgb(252, 141, 89), Rgb(255, 255, 191), Rgb(145, 191, 219)],
  [Rgb(215, 25, 28), Rgb(253, 174, 97), Rgb(171, 217, 233), Rgb(44, 123, 182)],
  [
    Rgb(215, 25, 28),
    Rgb(253, 174, 97),
    Rgb(255, 255, 191),
    Rgb(171, 217, 233),
    Rgb(44, 123, 182),
  ],
  [
    Rgb(215, 48, 39),
    Rgb(252, 141, 89),
    Rgb(254, 224, 144),
    Rgb(224, 243, 248),
    Rgb(145, 191, 219),
    Rgb(69, 117, 180),
  ],
  [
    Rgb(215, 48, 39),
    Rgb(252, 141, 89),
    Rgb(254, 224, 144),
    Rgb(255, 255, 191),
    Rgb(224, 243, 248),
    Rgb(145, 191, 219),
    Rgb(69, 117, 180),
  ],
  [
    Rgb(215, 48, 39),
    Rgb(244, 109, 67),
    Rgb(253, 174, 97),
    Rgb(254, 224, 144),
    Rgb(224, 243, 248),
    Rgb(171, 217, 233),
    Rgb(116, 173, 209),
    Rgb(69, 117, 180),
  ],
  [
    Rgb(215, 48, 39),
    Rgb(244, 109, 67),
    Rgb(253, 174, 97),
    Rgb(254, 224, 144),
    Rgb(255, 255, 191),
    Rgb(224, 243, 248),
    Rgb(171, 217, 233),
    Rgb(116, 173, 209),
    Rgb(69, 117, 180),
  ],
  [
    Rgb(165, 0, 38),
    Rgb(215, 48, 39),
    Rgb(244, 109, 67),
    Rgb(253, 174, 97),
    Rgb(254, 224, 144),
    Rgb(224, 243, 248),
    Rgb(171, 217, 233),
    Rgb(116, 173, 209),
    Rgb(69, 117, 180),
    Rgb(49, 54, 149),
  ],
  [
    Rgb(165, 0, 38),
    Rgb(215, 48, 39),
    Rgb(244, 109, 67),
    Rgb(253, 174, 97),
    Rgb(254, 224, 144),
    Rgb(255, 255, 191),
    Rgb(224, 243, 248),
    Rgb(171, 217, 233),
    Rgb(116, 173, 209),
    Rgb(69, 117, 180),
    Rgb(49, 54, 149),
  ],
];

/// diverging/RdYlBu.js the default export (`interpolateRdYlBu` of index.js): the
/// continuous RGB B-spline interpolator for [schemeRdYlBu].
final Rgb Function(double t) interpolateRdYlBu = ramp(schemeRdYlBu);
