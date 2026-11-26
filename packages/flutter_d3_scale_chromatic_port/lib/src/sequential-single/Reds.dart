// Ported from d3-scale-chromatic v3.1.0 src/sequential-single/Reds.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/sequential-single/Reds.js` of d3-scale-chromatic 3.1.0: the sequential single-hue
/// ColorBrewer color scheme [schemeReds] and interpolator [interpolateReds].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// sequential-single/Reds.js:4 `scheme` (`schemeReds` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 9);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
final List<List<Rgb>?> schemeReds = List<List<Rgb>?>.unmodifiable([
  null,
  null,
  null,
  colors('fee0d2fc9272de2d26'),
  colors('fee5d9fcae91fb6a4acb181d'),
  colors('fee5d9fcae91fb6a4ade2d26a50f15'),
  colors('fee5d9fcbba1fc9272fb6a4ade2d26a50f15'),
  colors('fee5d9fcbba1fc9272fb6a4aef3b2ccb181d99000d'),
  colors('fff5f0fee0d2fcbba1fc9272fb6a4aef3b2ccb181d99000d'),
  colors('fff5f0fee0d2fcbba1fc9272fb6a4aef3b2ccb181da50f1567000d'),
]);

/// sequential-single/Reds.js the default export (`interpolateReds` of index.js): the
/// continuous RGB B-spline interpolator for [schemeReds].
final Rgb Function(double t) interpolateReds = ramp(schemeReds);
