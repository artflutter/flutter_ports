// Ported from d3-scale-chromatic v3.1.0 src/sequential-multi/PuBuGn.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/sequential-multi/PuBuGn.js` of d3-scale-chromatic 3.1.0: the sequential multi-hue
/// ColorBrewer color scheme [schemePuBuGn]
/// and interpolator [interpolatePuBuGn].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// sequential-multi/PuBuGn.js:4 `scheme` (`schemePuBuGn` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 9);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
final List<List<Rgb>?> schemePuBuGn = List<List<Rgb>?>.unmodifiable([
  null,
  null,
  null,
  colors('ece2f0a6bddb1c9099'),
  colors('f6eff7bdc9e167a9cf02818a'),
  colors('f6eff7bdc9e167a9cf1c9099016c59'),
  colors('f6eff7d0d1e6a6bddb67a9cf1c9099016c59'),
  colors('f6eff7d0d1e6a6bddb67a9cf3690c002818a016450'),
  colors('fff7fbece2f0d0d1e6a6bddb67a9cf3690c002818a016450'),
  colors('fff7fbece2f0d0d1e6a6bddb67a9cf3690c002818a016c59014636'),
]);

/// sequential-multi/PuBuGn.js the default export (`interpolatePuBuGn` of index.js): the
/// continuous RGB B-spline interpolator for [schemePuBuGn].
final Rgb Function(double t) interpolatePuBuGn = ramp(schemePuBuGn);
