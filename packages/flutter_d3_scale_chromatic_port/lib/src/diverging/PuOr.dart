// Ported from d3-scale-chromatic v3.1.0 src/diverging/PuOr.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/diverging/PuOr.js` of d3-scale-chromatic 3.1.0: the diverging
/// ColorBrewer color scheme [schemePuOr] and interpolator [interpolatePuOr].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// diverging/PuOr.js:4 `scheme` (`schemePuOr` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 11);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
final List<List<Rgb>?> schemePuOr = List<List<Rgb>?>.unmodifiable([
  null,
  null,
  null,
  colors('998ec3f7f7f7f1a340'),
  colors('5e3c99b2abd2fdb863e66101'),
  colors('5e3c99b2abd2f7f7f7fdb863e66101'),
  colors('542788998ec3d8daebfee0b6f1a340b35806'),
  colors('542788998ec3d8daebf7f7f7fee0b6f1a340b35806'),
  colors('5427888073acb2abd2d8daebfee0b6fdb863e08214b35806'),
  colors('5427888073acb2abd2d8daebf7f7f7fee0b6fdb863e08214b35806'),
  colors('2d004b5427888073acb2abd2d8daebfee0b6fdb863e08214b358067f3b08'),
  colors('2d004b5427888073acb2abd2d8daebf7f7f7fee0b6fdb863e08214b358067f3b08'),
]);

/// diverging/PuOr.js the default export (`interpolatePuOr` of index.js): the
/// continuous RGB B-spline interpolator for [schemePuOr].
final Rgb Function(double t) interpolatePuOr = ramp(schemePuOr);
