// Ported from d3-scale-chromatic v3.1.0 src/categorical/Set3.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/categorical/Set3.js` of d3-scale-chromatic 3.1.0: the
/// categorical color scheme [schemeSet3].
library;

import 'package:flutter_d3_color_port/d3_color.dart';

/// categorical/Set3.js:3 the default export (`schemeSet3` of index.js): an
/// unmodifiable list of 12 categorical [Rgb] colors.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
const List<Rgb> schemeSet3 = [
  Rgb(141, 211, 199),
  Rgb(255, 255, 179),
  Rgb(190, 186, 218),
  Rgb(251, 128, 114),
  Rgb(128, 177, 211),
  Rgb(253, 180, 98),
  Rgb(179, 222, 105),
  Rgb(252, 205, 229),
  Rgb(217, 217, 217),
  Rgb(188, 128, 189),
  Rgb(204, 235, 197),
  Rgb(255, 237, 111),
];
