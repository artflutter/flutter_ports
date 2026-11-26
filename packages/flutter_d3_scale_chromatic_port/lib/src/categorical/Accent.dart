// Ported from d3-scale-chromatic v3.1.0 src/categorical/Accent.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/categorical/Accent.js` of d3-scale-chromatic 3.1.0: the
/// categorical color scheme [schemeAccent].
library;

import 'package:flutter_d3_color_port/d3_color.dart';

/// categorical/Accent.js:3 the default export (`schemeAccent` of index.js): an
/// unmodifiable list of 8 categorical [Rgb] colors.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
const List<Rgb> schemeAccent = [
  Rgb(127, 201, 127),
  Rgb(190, 174, 212),
  Rgb(253, 192, 134),
  Rgb(255, 255, 153),
  Rgb(56, 108, 176),
  Rgb(240, 2, 127),
  Rgb(191, 91, 23),
  Rgb(102, 102, 102),
];
