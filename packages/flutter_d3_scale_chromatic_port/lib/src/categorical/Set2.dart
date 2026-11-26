// Ported from d3-scale-chromatic v3.1.0 src/categorical/Set2.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/categorical/Set2.js` of d3-scale-chromatic 3.1.0: the
/// categorical color scheme [schemeSet2].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// categorical/Set2.js:3 the default export (`schemeSet2` of index.js): an
/// unmodifiable list of 8 categorical [Rgb] colors.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
final List<Rgb> schemeSet2 = colors(
  '66c2a5fc8d628da0cbe78ac3a6d854ffd92fe5c494b3b3b3',
);
