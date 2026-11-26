// Ported from d3-scale-chromatic v3.1.0 src/categorical/Set2.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/categorical/Set2.js` of d3-scale-chromatic 3.1.0: the
/// categorical color scheme [schemeSet2].
library;

import 'package:flutter_d3_color_port/d3_color.dart';

/// categorical/Set2.js:3 the default export (`schemeSet2` of index.js): an
/// unmodifiable list of 8 categorical [Rgb] colors.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
const List<Rgb> schemeSet2 = [
  Rgb(102, 194, 165),
  Rgb(252, 141, 98),
  Rgb(141, 160, 203),
  Rgb(231, 138, 195),
  Rgb(166, 216, 84),
  Rgb(255, 217, 47),
  Rgb(229, 196, 148),
  Rgb(179, 179, 179),
];
