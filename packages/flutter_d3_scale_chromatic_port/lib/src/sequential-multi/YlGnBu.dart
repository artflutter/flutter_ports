// Ported from d3-scale-chromatic v3.1.0 src/sequential-multi/YlGnBu.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/sequential-multi/YlGnBu.js` of d3-scale-chromatic 3.1.0: the sequential multi-hue
/// ColorBrewer color scheme [schemeYlGnBu]
/// and interpolator [interpolateYlGnBu].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// sequential-multi/YlGnBu.js:4 `scheme` (`schemeYlGnBu` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 9);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
final List<List<Rgb>?> schemeYlGnBu = List<List<Rgb>?>.unmodifiable([
  null,
  null,
  null,
  colors('edf8b17fcdbb2c7fb8'),
  colors('ffffcca1dab441b6c4225ea8'),
  colors('ffffcca1dab441b6c42c7fb8253494'),
  colors('ffffccc7e9b47fcdbb41b6c42c7fb8253494'),
  colors('ffffccc7e9b47fcdbb41b6c41d91c0225ea80c2c84'),
  colors('ffffd9edf8b1c7e9b47fcdbb41b6c41d91c0225ea80c2c84'),
  colors('ffffd9edf8b1c7e9b47fcdbb41b6c41d91c0225ea8253494081d58'),
]);

/// sequential-multi/YlGnBu.js the default export (`interpolateYlGnBu` of index.js): the
/// continuous RGB B-spline interpolator for [schemeYlGnBu].
final Rgb Function(double t) interpolateYlGnBu = ramp(schemeYlGnBu);
