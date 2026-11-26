// Ported from d3-scale-chromatic v3.1.0 src/categorical/Tableau10.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/categorical/Tableau10.js` of d3-scale-chromatic 3.1.0: the
/// categorical color scheme [schemeTableau10].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// categorical/Tableau10.js:3 the default export (`schemeTableau10` of index.js): an
/// unmodifiable list of 10 categorical [Rgb] colors.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
final List<Rgb> schemeTableau10 = colors(
  '4e79a7f28e2ce1575976b7b259a14fedc949af7aa1ff9da79c755fbab0ab',
);
