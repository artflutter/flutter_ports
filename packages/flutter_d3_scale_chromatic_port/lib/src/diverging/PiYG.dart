// Ported from d3-scale-chromatic v3.1.0 src/diverging/PiYG.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/diverging/PiYG.js` of d3-scale-chromatic 3.1.0: the diverging
/// ColorBrewer color scheme [schemePiYG] and interpolator [interpolatePiYG].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// diverging/PiYG.js:4 `scheme` (`schemePiYG` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 11);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
final List<List<Rgb>?> schemePiYG = List<List<Rgb>?>.unmodifiable([
  null,
  null,
  null,
  colors('e9a3c9f7f7f7a1d76a'),
  colors('d01c8bf1b6dab8e1864dac26'),
  colors('d01c8bf1b6daf7f7f7b8e1864dac26'),
  colors('c51b7de9a3c9fde0efe6f5d0a1d76a4d9221'),
  colors('c51b7de9a3c9fde0eff7f7f7e6f5d0a1d76a4d9221'),
  colors('c51b7dde77aef1b6dafde0efe6f5d0b8e1867fbc414d9221'),
  colors('c51b7dde77aef1b6dafde0eff7f7f7e6f5d0b8e1867fbc414d9221'),
  colors('8e0152c51b7dde77aef1b6dafde0efe6f5d0b8e1867fbc414d9221276419'),
  colors('8e0152c51b7dde77aef1b6dafde0eff7f7f7e6f5d0b8e1867fbc414d9221276419'),
]);

/// diverging/PiYG.js the default export (`interpolatePiYG` of index.js): the
/// continuous RGB B-spline interpolator for [schemePiYG].
final Rgb Function(double t) interpolatePiYG = ramp(schemePiYG);
