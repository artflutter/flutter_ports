// Ported from d3-scale-chromatic v3.1.0 src/categorical/Pastel2.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/categorical/Pastel2.js` of d3-scale-chromatic 3.1.0: the
/// categorical color scheme [schemePastel2].
library;

import 'package:flutter_d3_color_port/d3_color.dart';

/// categorical/Pastel2.js:3 the default export (`schemePastel2` of index.js): an
/// unmodifiable list of 8 categorical [Rgb] colors.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
const List<Rgb> schemePastel2 = [
  Rgb(179, 226, 205),
  Rgb(253, 205, 172),
  Rgb(203, 213, 232),
  Rgb(244, 202, 228),
  Rgb(230, 245, 201),
  Rgb(255, 242, 174),
  Rgb(241, 226, 204),
  Rgb(204, 204, 204),
];
