// Ported from d3-scale-chromatic v3.1.0 src/diverging/BrBG.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/diverging/BrBG.js` of d3-scale-chromatic 3.1.0: the diverging
/// ColorBrewer color scheme [schemeBrBG] and interpolator [interpolateBrBG].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// diverging/BrBG.js:4 `scheme` (`schemeBrBG` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 11);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
final List<List<Rgb>?> schemeBrBG = List<List<Rgb>?>.unmodifiable([
  null,
  null,
  null,
  colors('d8b365f5f5f55ab4ac'),
  colors('a6611adfc27d80cdc1018571'),
  colors('a6611adfc27df5f5f580cdc1018571'),
  colors('8c510ad8b365f6e8c3c7eae55ab4ac01665e'),
  colors('8c510ad8b365f6e8c3f5f5f5c7eae55ab4ac01665e'),
  colors('8c510abf812ddfc27df6e8c3c7eae580cdc135978f01665e'),
  colors('8c510abf812ddfc27df6e8c3f5f5f5c7eae580cdc135978f01665e'),
  colors('5430058c510abf812ddfc27df6e8c3c7eae580cdc135978f01665e003c30'),
  colors('5430058c510abf812ddfc27df6e8c3f5f5f5c7eae580cdc135978f01665e003c30'),
]);

/// diverging/BrBG.js the default export (`interpolateBrBG` of index.js): the
/// continuous RGB B-spline interpolator for [schemeBrBG].
final Rgb Function(double t) interpolateBrBG = ramp(schemeBrBG);
