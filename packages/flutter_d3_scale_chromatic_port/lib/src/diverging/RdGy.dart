// Ported from d3-scale-chromatic v3.1.0 src/diverging/RdGy.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/diverging/RdGy.js` of d3-scale-chromatic 3.1.0: the diverging
/// ColorBrewer color scheme [schemeRdGy] and interpolator [interpolateRdGy].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// diverging/RdGy.js:4 `scheme` (`schemeRdGy` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 11);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
final List<List<Rgb>?> schemeRdGy = List<List<Rgb>?>.unmodifiable([
  null,
  null,
  null,
  colors('ef8a62ffffff999999'),
  colors('ca0020f4a582bababa404040'),
  colors('ca0020f4a582ffffffbababa404040'),
  colors('b2182bef8a62fddbc7e0e0e09999994d4d4d'),
  colors('b2182bef8a62fddbc7ffffffe0e0e09999994d4d4d'),
  colors('b2182bd6604df4a582fddbc7e0e0e0bababa8787874d4d4d'),
  colors('b2182bd6604df4a582fddbc7ffffffe0e0e0bababa8787874d4d4d'),
  colors('67001fb2182bd6604df4a582fddbc7e0e0e0bababa8787874d4d4d1a1a1a'),
  colors('67001fb2182bd6604df4a582fddbc7ffffffe0e0e0bababa8787874d4d4d1a1a1a'),
]);

/// diverging/RdGy.js the default export (`interpolateRdGy` of index.js): the
/// continuous RGB B-spline interpolator for [schemeRdGy].
final Rgb Function(double t) interpolateRdGy = ramp(schemeRdGy);
