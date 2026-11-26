// Ported from d3-scale-chromatic v3.1.0 src/sequential-single/Oranges.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/sequential-single/Oranges.js` of d3-scale-chromatic 3.1.0: the sequential single-hue
/// ColorBrewer color scheme [schemeOranges]
/// and interpolator [interpolateOranges].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// sequential-single/Oranges.js:4 `scheme` (`schemeOranges` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 9);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
final List<List<Rgb>?> schemeOranges = List<List<Rgb>?>.unmodifiable([
  null,
  null,
  null,
  colors('fee6cefdae6be6550d'),
  colors('feeddefdbe85fd8d3cd94701'),
  colors('feeddefdbe85fd8d3ce6550da63603'),
  colors('feeddefdd0a2fdae6bfd8d3ce6550da63603'),
  colors('feeddefdd0a2fdae6bfd8d3cf16913d948018c2d04'),
  colors('fff5ebfee6cefdd0a2fdae6bfd8d3cf16913d948018c2d04'),
  colors('fff5ebfee6cefdd0a2fdae6bfd8d3cf16913d94801a636037f2704'),
]);

/// sequential-single/Oranges.js the default export (`interpolateOranges` of index.js): the
/// continuous RGB B-spline interpolator for [schemeOranges].
final Rgb Function(double t) interpolateOranges = ramp(schemeOranges);
