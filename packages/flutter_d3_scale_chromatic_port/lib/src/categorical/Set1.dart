// Ported from d3-scale-chromatic v3.1.0 src/categorical/Set1.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/categorical/Set1.js` of d3-scale-chromatic 3.1.0: the
/// categorical color scheme [schemeSet1].
library;

import 'package:flutter_d3_color_port/d3_color.dart';

/// categorical/Set1.js:3 the default export (`schemeSet1` of index.js): an
/// unmodifiable list of 9 categorical [Rgb] colors.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
const List<Rgb> schemeSet1 = [
  Rgb(228, 26, 28),
  Rgb(55, 126, 184),
  Rgb(77, 175, 74),
  Rgb(152, 78, 163),
  Rgb(255, 127, 0),
  Rgb(255, 255, 51),
  Rgb(166, 86, 40),
  Rgb(247, 129, 191),
  Rgb(153, 153, 153),
];
