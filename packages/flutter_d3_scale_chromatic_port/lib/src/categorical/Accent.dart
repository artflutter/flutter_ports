// Ported from d3-scale-chromatic v3.1.0 src/categorical/Accent.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/categorical/Accent.js` of d3-scale-chromatic 3.1.0: the
/// categorical color scheme [schemeAccent].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// categorical/Accent.js:3 the default export (`schemeAccent` of index.js): an
/// unmodifiable list of 8 categorical [Rgb] colors.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
final List<Rgb> schemeAccent = colors(
  '7fc97fbeaed4fdc086ffff99386cb0f0027fbf5b17666666',
);
