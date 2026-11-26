// Ported from d3-scale-chromatic v3.1.0 src/categorical/Tableau10.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/categorical/Tableau10.js` of d3-scale-chromatic 3.1.0: the
/// categorical color scheme [schemeTableau10].
library;

import 'package:flutter_d3_color_port/d3_color.dart';

/// categorical/Tableau10.js:3 the default export (`schemeTableau10` of index.js): an
/// unmodifiable list of 10 categorical [Rgb] colors.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
const List<Rgb> schemeTableau10 = [
  Rgb(78, 121, 167),
  Rgb(242, 142, 44),
  Rgb(225, 87, 89),
  Rgb(118, 183, 178),
  Rgb(89, 161, 79),
  Rgb(237, 201, 73),
  Rgb(175, 122, 161),
  Rgb(255, 157, 167),
  Rgb(156, 117, 95),
  Rgb(186, 176, 171),
];
