// Ported from d3-scale-chromatic v3.1.0 src/diverging/RdYlGn.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/diverging/RdYlGn.js` of d3-scale-chromatic 3.1.0: the diverging
/// ColorBrewer color scheme [schemeRdYlGn]
/// and interpolator [interpolateRdYlGn].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// diverging/RdYlGn.js:4 `scheme` (`schemeRdYlGn` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 11);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
const List<List<Rgb>?> schemeRdYlGn = [
  null,
  null,
  null,
  [Rgb(252, 141, 89), Rgb(255, 255, 191), Rgb(145, 207, 96)],
  [Rgb(215, 25, 28), Rgb(253, 174, 97), Rgb(166, 217, 106), Rgb(26, 150, 65)],
  [
    Rgb(215, 25, 28),
    Rgb(253, 174, 97),
    Rgb(255, 255, 191),
    Rgb(166, 217, 106),
    Rgb(26, 150, 65),
  ],
  [
    Rgb(215, 48, 39),
    Rgb(252, 141, 89),
    Rgb(254, 224, 139),
    Rgb(217, 239, 139),
    Rgb(145, 207, 96),
    Rgb(26, 152, 80),
  ],
  [
    Rgb(215, 48, 39),
    Rgb(252, 141, 89),
    Rgb(254, 224, 139),
    Rgb(255, 255, 191),
    Rgb(217, 239, 139),
    Rgb(145, 207, 96),
    Rgb(26, 152, 80),
  ],
  [
    Rgb(215, 48, 39),
    Rgb(244, 109, 67),
    Rgb(253, 174, 97),
    Rgb(254, 224, 139),
    Rgb(217, 239, 139),
    Rgb(166, 217, 106),
    Rgb(102, 189, 99),
    Rgb(26, 152, 80),
  ],
  [
    Rgb(215, 48, 39),
    Rgb(244, 109, 67),
    Rgb(253, 174, 97),
    Rgb(254, 224, 139),
    Rgb(255, 255, 191),
    Rgb(217, 239, 139),
    Rgb(166, 217, 106),
    Rgb(102, 189, 99),
    Rgb(26, 152, 80),
  ],
  [
    Rgb(165, 0, 38),
    Rgb(215, 48, 39),
    Rgb(244, 109, 67),
    Rgb(253, 174, 97),
    Rgb(254, 224, 139),
    Rgb(217, 239, 139),
    Rgb(166, 217, 106),
    Rgb(102, 189, 99),
    Rgb(26, 152, 80),
    Rgb(0, 104, 55),
  ],
  [
    Rgb(165, 0, 38),
    Rgb(215, 48, 39),
    Rgb(244, 109, 67),
    Rgb(253, 174, 97),
    Rgb(254, 224, 139),
    Rgb(255, 255, 191),
    Rgb(217, 239, 139),
    Rgb(166, 217, 106),
    Rgb(102, 189, 99),
    Rgb(26, 152, 80),
    Rgb(0, 104, 55),
  ],
];

/// diverging/RdYlGn.js the default export (`interpolateRdYlGn` of index.js): the
/// continuous RGB B-spline interpolator for [schemeRdYlGn].
final Rgb Function(double t) interpolateRdYlGn = ramp(schemeRdYlGn);
