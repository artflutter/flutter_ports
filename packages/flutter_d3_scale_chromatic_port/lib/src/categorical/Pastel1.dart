// Ported from d3-scale-chromatic v3.1.0 src/categorical/Pastel1.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/categorical/Pastel1.js` of d3-scale-chromatic 3.1.0: the
/// categorical color scheme [schemePastel1].
library;

import 'package:flutter_d3_color_port/d3_color.dart';

/// categorical/Pastel1.js:3 the default export (`schemePastel1` of index.js): an
/// unmodifiable list of 9 categorical [Rgb] colors.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
const List<Rgb> schemePastel1 = [
  Rgb(251, 180, 174),
  Rgb(179, 205, 227),
  Rgb(204, 235, 197),
  Rgb(222, 203, 228),
  Rgb(254, 217, 166),
  Rgb(255, 255, 204),
  Rgb(229, 216, 189),
  Rgb(253, 218, 236),
  Rgb(242, 242, 242),
];
