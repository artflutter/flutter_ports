// Ported from d3-scale-chromatic v3.1.0 src/sequential-multi/BuPu.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/sequential-multi/BuPu.js` of d3-scale-chromatic 3.1.0: the sequential multi-hue
/// ColorBrewer color scheme [schemeBuPu] and interpolator [interpolateBuPu].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// sequential-multi/BuPu.js:4 `scheme` (`schemeBuPu` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 9);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
final List<List<Rgb>?> schemeBuPu = List<List<Rgb>?>.unmodifiable([
  null,
  null,
  null,
  colors('e0ecf49ebcda8856a7'),
  colors('edf8fbb3cde38c96c688419d'),
  colors('edf8fbb3cde38c96c68856a7810f7c'),
  colors('edf8fbbfd3e69ebcda8c96c68856a7810f7c'),
  colors('edf8fbbfd3e69ebcda8c96c68c6bb188419d6e016b'),
  colors('f7fcfde0ecf4bfd3e69ebcda8c96c68c6bb188419d6e016b'),
  colors('f7fcfde0ecf4bfd3e69ebcda8c96c68c6bb188419d810f7c4d004b'),
]);

/// sequential-multi/BuPu.js the default export (`interpolateBuPu` of index.js): the
/// continuous RGB B-spline interpolator for [schemeBuPu].
final Rgb Function(double t) interpolateBuPu = ramp(schemeBuPu);
