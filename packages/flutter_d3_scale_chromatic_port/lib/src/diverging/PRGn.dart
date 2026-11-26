// Ported from d3-scale-chromatic v3.1.0 src/diverging/PRGn.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/diverging/PRGn.js` of d3-scale-chromatic 3.1.0: the diverging
/// ColorBrewer color scheme [schemePRGn] and interpolator [interpolatePRGn].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// diverging/PRGn.js:4 `scheme` (`schemePRGn` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 11);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
final List<List<Rgb>?> schemePRGn = List<List<Rgb>?>.unmodifiable([
  null,
  null,
  null,
  colors('af8dc3f7f7f77fbf7b'),
  colors('7b3294c2a5cfa6dba0008837'),
  colors('7b3294c2a5cff7f7f7a6dba0008837'),
  colors('762a83af8dc3e7d4e8d9f0d37fbf7b1b7837'),
  colors('762a83af8dc3e7d4e8f7f7f7d9f0d37fbf7b1b7837'),
  colors('762a839970abc2a5cfe7d4e8d9f0d3a6dba05aae611b7837'),
  colors('762a839970abc2a5cfe7d4e8f7f7f7d9f0d3a6dba05aae611b7837'),
  colors('40004b762a839970abc2a5cfe7d4e8d9f0d3a6dba05aae611b783700441b'),
  colors('40004b762a839970abc2a5cfe7d4e8f7f7f7d9f0d3a6dba05aae611b783700441b'),
]);

/// diverging/PRGn.js the default export (`interpolatePRGn` of index.js): the
/// continuous RGB B-spline interpolator for [schemePRGn].
final Rgb Function(double t) interpolatePRGn = ramp(schemePRGn);
