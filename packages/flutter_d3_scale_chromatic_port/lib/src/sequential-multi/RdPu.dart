// Ported from d3-scale-chromatic v3.1.0 src/sequential-multi/RdPu.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/sequential-multi/RdPu.js` of d3-scale-chromatic 3.1.0: the sequential multi-hue
/// ColorBrewer color scheme [schemeRdPu] and interpolator [interpolateRdPu].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// sequential-multi/RdPu.js:4 `scheme` (`schemeRdPu` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 9);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
final List<List<Rgb>?> schemeRdPu = List<List<Rgb>?>.unmodifiable([
  null,
  null,
  null,
  colors('fde0ddfa9fb5c51b8a'),
  colors('feebe2fbb4b9f768a1ae017e'),
  colors('feebe2fbb4b9f768a1c51b8a7a0177'),
  colors('feebe2fcc5c0fa9fb5f768a1c51b8a7a0177'),
  colors('feebe2fcc5c0fa9fb5f768a1dd3497ae017e7a0177'),
  colors('fff7f3fde0ddfcc5c0fa9fb5f768a1dd3497ae017e7a0177'),
  colors('fff7f3fde0ddfcc5c0fa9fb5f768a1dd3497ae017e7a017749006a'),
]);

/// sequential-multi/RdPu.js the default export (`interpolateRdPu` of index.js): the
/// continuous RGB B-spline interpolator for [schemeRdPu].
final Rgb Function(double t) interpolateRdPu = ramp(schemeRdPu);
