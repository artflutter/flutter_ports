// Ported from d3-scale-chromatic v3.1.0 src/sequential-single/Greys.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/sequential-single/Greys.js` of d3-scale-chromatic 3.1.0: the sequential single-hue
/// ColorBrewer color scheme [schemeGreys] and interpolator [interpolateGreys].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// sequential-single/Greys.js:4 `scheme` (`schemeGreys` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 9);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
final List<List<Rgb>?> schemeGreys = List<List<Rgb>?>.unmodifiable([
  null,
  null,
  null,
  colors('f0f0f0bdbdbd636363'),
  colors('f7f7f7cccccc969696525252'),
  colors('f7f7f7cccccc969696636363252525'),
  colors('f7f7f7d9d9d9bdbdbd969696636363252525'),
  colors('f7f7f7d9d9d9bdbdbd969696737373525252252525'),
  colors('fffffff0f0f0d9d9d9bdbdbd969696737373525252252525'),
  colors('fffffff0f0f0d9d9d9bdbdbd969696737373525252252525000000'),
]);

/// sequential-single/Greys.js the default export (`interpolateGreys` of index.js): the
/// continuous RGB B-spline interpolator for [schemeGreys].
final Rgb Function(double t) interpolateGreys = ramp(schemeGreys);
