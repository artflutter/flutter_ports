// Ported from d3-scale-chromatic v3.1.0 src/categorical/Paired.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/categorical/Paired.js` of d3-scale-chromatic 3.1.0: the
/// categorical color scheme [schemePaired].
library;

import 'package:flutter_d3_color_port/d3_color.dart';

/// categorical/Paired.js:3 the default export (`schemePaired` of index.js): an
/// unmodifiable list of 12 categorical [Rgb] colors.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
const List<Rgb> schemePaired = [
  Rgb(166, 206, 227),
  Rgb(31, 120, 180),
  Rgb(178, 223, 138),
  Rgb(51, 160, 44),
  Rgb(251, 154, 153),
  Rgb(227, 26, 28),
  Rgb(253, 191, 111),
  Rgb(255, 127, 0),
  Rgb(202, 178, 214),
  Rgb(106, 61, 154),
  Rgb(255, 255, 153),
  Rgb(177, 89, 40),
];
