// Ported from d3-scale-chromatic v3.1.0 src/categorical/Dark2.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/categorical/Dark2.js` of d3-scale-chromatic 3.1.0: the
/// categorical color scheme [schemeDark2].
library;

import 'package:flutter_d3_color_port/d3_color.dart';

/// categorical/Dark2.js:3 the default export (`schemeDark2` of index.js): an
/// unmodifiable list of 8 categorical [Rgb] colors.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
const List<Rgb> schemeDark2 = [
  Rgb(27, 158, 119),
  Rgb(217, 95, 2),
  Rgb(117, 112, 179),
  Rgb(231, 41, 138),
  Rgb(102, 166, 30),
  Rgb(230, 171, 2),
  Rgb(166, 118, 29),
  Rgb(102, 102, 102),
];
