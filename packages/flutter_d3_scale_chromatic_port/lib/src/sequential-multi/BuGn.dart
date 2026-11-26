// Ported from d3-scale-chromatic v3.1.0 src/sequential-multi/BuGn.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/sequential-multi/BuGn.js` of d3-scale-chromatic 3.1.0: the sequential multi-hue
/// ColorBrewer color scheme [schemeBuGn] and interpolator [interpolateBuGn].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// sequential-multi/BuGn.js:4 `scheme` (`schemeBuGn` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 9);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
final List<List<Rgb>?> schemeBuGn = List<List<Rgb>?>.unmodifiable([
  null,
  null,
  null,
  colors('e5f5f999d8c92ca25f'),
  colors('edf8fbb2e2e266c2a4238b45'),
  colors('edf8fbb2e2e266c2a42ca25f006d2c'),
  colors('edf8fbccece699d8c966c2a42ca25f006d2c'),
  colors('edf8fbccece699d8c966c2a441ae76238b45005824'),
  colors('f7fcfde5f5f9ccece699d8c966c2a441ae76238b45005824'),
  colors('f7fcfde5f5f9ccece699d8c966c2a441ae76238b45006d2c00441b'),
]);

/// sequential-multi/BuGn.js the default export (`interpolateBuGn` of index.js): the
/// continuous RGB B-spline interpolator for [schemeBuGn].
final Rgb Function(double t) interpolateBuGn = ramp(schemeBuGn);
