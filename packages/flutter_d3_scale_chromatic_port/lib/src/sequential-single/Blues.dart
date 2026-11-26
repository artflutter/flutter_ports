// Ported from d3-scale-chromatic v3.1.0 src/sequential-single/Blues.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/sequential-single/Blues.js` of d3-scale-chromatic 3.1.0: the sequential single-hue
/// ColorBrewer color scheme [schemeBlues] and interpolator [interpolateBlues].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// sequential-single/Blues.js:4 `scheme` (`schemeBlues` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 9);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
final List<List<Rgb>?> schemeBlues = List<List<Rgb>?>.unmodifiable([
  null,
  null,
  null,
  colors('deebf79ecae13182bd'),
  colors('eff3ffbdd7e76baed62171b5'),
  colors('eff3ffbdd7e76baed63182bd08519c'),
  colors('eff3ffc6dbef9ecae16baed63182bd08519c'),
  colors('eff3ffc6dbef9ecae16baed64292c62171b5084594'),
  colors('f7fbffdeebf7c6dbef9ecae16baed64292c62171b5084594'),
  colors('f7fbffdeebf7c6dbef9ecae16baed64292c62171b508519c08306b'),
]);

/// sequential-single/Blues.js the default export (`interpolateBlues` of index.js): the
/// continuous RGB B-spline interpolator for [schemeBlues].
final Rgb Function(double t) interpolateBlues = ramp(schemeBlues);
