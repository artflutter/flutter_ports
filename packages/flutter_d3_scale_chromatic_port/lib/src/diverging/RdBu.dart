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
final List<List<Rgb>?> schemeRdBu = List<List<Rgb>?>.unmodifiable([
  null,
  null,
  null,
  colors('ef8a62f7f7f767a9cf'),
  colors('ca0020f4a58292c5de0571b0'),
  colors('ca0020f4a582f7f7f792c5de0571b0'),
  colors('b2182bef8a62fddbc7d1e5f067a9cf2166ac'),
  colors('b2182bef8a62fddbc7f7f7f7d1e5f067a9cf2166ac'),
  colors('b2182bd6604df4a582fddbc7d1e5f092c5de4393c32166ac'),
  colors('b2182bd6604df4a582fddbc7f7f7f7d1e5f092c5de4393c32166ac'),
  colors('67001fb2182bd6604df4a582fddbc7d1e5f092c5de4393c32166ac053061'),
  colors('67001fb2182bd6604df4a582fddbc7f7f7f7d1e5f092c5de4393c32166ac053061'),
]);

/// diverging/RdBu.js the default export (`interpolateRdBu` of index.js): the
/// continuous RGB B-spline interpolator for [schemeRdBu].
final Rgb Function(double t) interpolateRdBu = ramp(schemeRdBu);
