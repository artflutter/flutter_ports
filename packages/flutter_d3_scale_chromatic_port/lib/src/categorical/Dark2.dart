// Ported from d3-scale-chromatic v3.1.0 src/categorical/Dark2.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/categorical/Dark2.js` of d3-scale-chromatic 3.1.0: the
/// categorical color scheme [schemeDark2].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// categorical/Dark2.js:3 the default export (`schemeDark2` of index.js): an
/// unmodifiable list of 8 categorical [Rgb] colors.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
final List<Rgb> schemeDark2 = colors(
  '1b9e77d95f027570b3e7298a66a61ee6ab02a6761d666666',
);
