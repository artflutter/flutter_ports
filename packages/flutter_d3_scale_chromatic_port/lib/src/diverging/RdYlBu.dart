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
final List<List<Rgb>?> schemeRdYlBu = List<List<Rgb>?>.unmodifiable([
  null,
  null,
  null,
  colors('fc8d59ffffbf91bfdb'),
  colors('d7191cfdae61abd9e92c7bb6'),
  colors('d7191cfdae61ffffbfabd9e92c7bb6'),
  colors('d73027fc8d59fee090e0f3f891bfdb4575b4'),
  colors('d73027fc8d59fee090ffffbfe0f3f891bfdb4575b4'),
  colors('d73027f46d43fdae61fee090e0f3f8abd9e974add14575b4'),
  colors('d73027f46d43fdae61fee090ffffbfe0f3f8abd9e974add14575b4'),
  colors('a50026d73027f46d43fdae61fee090e0f3f8abd9e974add14575b4313695'),
  colors('a50026d73027f46d43fdae61fee090ffffbfe0f3f8abd9e974add14575b4313695'),
]);

/// diverging/RdYlBu.js the default export (`interpolateRdYlBu` of index.js): the
/// continuous RGB B-spline interpolator for [schemeRdYlBu].
final Rgb Function(double t) interpolateRdYlBu = ramp(schemeRdYlBu);
