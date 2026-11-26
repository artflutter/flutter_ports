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
final List<List<Rgb>?> schemePurples = List<List<Rgb>?>.unmodifiable([
  null,
  null,
  null,
  colors('efedf5bcbddc756bb1'),
  colors('f2f0f7cbc9e29e9ac86a51a3'),
  colors('f2f0f7cbc9e29e9ac8756bb154278f'),
  colors('f2f0f7dadaebbcbddc9e9ac8756bb154278f'),
  colors('f2f0f7dadaebbcbddc9e9ac8807dba6a51a34a1486'),
  colors('fcfbfdefedf5dadaebbcbddc9e9ac8807dba6a51a34a1486'),
  colors('fcfbfdefedf5dadaebbcbddc9e9ac8807dba6a51a354278f3f007d'),
]);

/// sequential-single/Purples.js the default export (`interpolatePurples` of index.js): the
/// continuous RGB B-spline interpolator for [schemePurples].
final Rgb Function(double t) interpolatePurples = ramp(schemePurples);
