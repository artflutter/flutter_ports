// Ported from d3-scale-chromatic v3.1.0 src/diverging/Spectral.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/diverging/Spectral.js` of d3-scale-chromatic 3.1.0: the diverging
/// ColorBrewer color scheme [schemeSpectral]
/// and interpolator [interpolateSpectral].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// diverging/Spectral.js:4 `scheme` (`schemeSpectral` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 11);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
const List<List<Rgb>?> schemeSpectral = [
  null,
  null,
  null,
  [Rgb(252, 141, 89), Rgb(255, 255, 191), Rgb(153, 213, 148)],
  [Rgb(215, 25, 28), Rgb(253, 174, 97), Rgb(171, 221, 164), Rgb(43, 131, 186)],
  [
    Rgb(215, 25, 28),
    Rgb(253, 174, 97),
    Rgb(255, 255, 191),
    Rgb(171, 221, 164),
    Rgb(43, 131, 186),
  ],
  [
    Rgb(213, 62, 79),
    Rgb(252, 141, 89),
    Rgb(254, 224, 139),
    Rgb(230, 245, 152),
    Rgb(153, 213, 148),
    Rgb(50, 136, 189),
  ],
  [
    Rgb(213, 62, 79),
    Rgb(252, 141, 89),
    Rgb(254, 224, 139),
    Rgb(255, 255, 191),
    Rgb(230, 245, 152),
    Rgb(153, 213, 148),
    Rgb(50, 136, 189),
  ],
  [
    Rgb(213, 62, 79),
    Rgb(244, 109, 67),
    Rgb(253, 174, 97),
    Rgb(254, 224, 139),
    Rgb(230, 245, 152),
    Rgb(171, 221, 164),
    Rgb(102, 194, 165),
    Rgb(50, 136, 189),
  ],
  [
    Rgb(213, 62, 79),
    Rgb(244, 109, 67),
    Rgb(253, 174, 97),
    Rgb(254, 224, 139),
    Rgb(255, 255, 191),
    Rgb(230, 245, 152),
    Rgb(171, 221, 164),
    Rgb(102, 194, 165),
    Rgb(50, 136, 189),
  ],
  [
    Rgb(158, 1, 66),
    Rgb(213, 62, 79),
    Rgb(244, 109, 67),
    Rgb(253, 174, 97),
    Rgb(254, 224, 139),
    Rgb(230, 245, 152),
    Rgb(171, 221, 164),
    Rgb(102, 194, 165),
    Rgb(50, 136, 189),
    Rgb(94, 79, 162),
  ],
  [
    Rgb(158, 1, 66),
    Rgb(213, 62, 79),
    Rgb(244, 109, 67),
    Rgb(253, 174, 97),
    Rgb(254, 224, 139),
    Rgb(255, 255, 191),
    Rgb(230, 245, 152),
    Rgb(171, 221, 164),
    Rgb(102, 194, 165),
    Rgb(50, 136, 189),
    Rgb(94, 79, 162),
  ],
];

/// diverging/Spectral.js the default export (`interpolateSpectral` of index.js): the
/// continuous RGB B-spline interpolator for [schemeSpectral].
final Rgb Function(double t) interpolateSpectral = ramp(schemeSpectral);
