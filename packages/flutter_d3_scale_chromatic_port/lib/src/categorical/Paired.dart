// Ported from d3-scale-chromatic v3.1.0 src/categorical/Paired.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/categorical/Paired.js` of d3-scale-chromatic 3.1.0: the
/// categorical color scheme [schemePaired].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// categorical/Paired.js:3 the default export (`schemePaired` of index.js): an
/// unmodifiable list of 12 categorical [Rgb] colors.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
final List<Rgb> schemePaired = colors(
  'a6cee31f78b4b2df8a33a02cfb9a99e31a1cfdbf6fff7f00cab2d66a3d9affff99b15928',
);
