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
final List<List<Rgb>?> schemeRdYlGn = List<List<Rgb>?>.unmodifiable([
  null,
  null,
  null,
  colors('fc8d59ffffbf91cf60'),
  colors('d7191cfdae61a6d96a1a9641'),
  colors('d7191cfdae61ffffbfa6d96a1a9641'),
  colors('d73027fc8d59fee08bd9ef8b91cf601a9850'),
  colors('d73027fc8d59fee08bffffbfd9ef8b91cf601a9850'),
  colors('d73027f46d43fdae61fee08bd9ef8ba6d96a66bd631a9850'),
  colors('d73027f46d43fdae61fee08bffffbfd9ef8ba6d96a66bd631a9850'),
  colors('a50026d73027f46d43fdae61fee08bd9ef8ba6d96a66bd631a9850006837'),
  colors('a50026d73027f46d43fdae61fee08bffffbfd9ef8ba6d96a66bd631a9850006837'),
]);

/// diverging/RdYlGn.js the default export (`interpolateRdYlGn` of index.js): the
/// continuous RGB B-spline interpolator for [schemeRdYlGn].
final Rgb Function(double t) interpolateRdYlGn = ramp(schemeRdYlGn);
