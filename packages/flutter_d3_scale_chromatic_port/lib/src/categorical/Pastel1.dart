// Ported from d3-scale-chromatic v3.1.0 src/categorical/Pastel1.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/categorical/Pastel1.js` of d3-scale-chromatic 3.1.0: the
/// categorical color scheme [schemePastel1].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// categorical/Pastel1.js:3 the default export (`schemePastel1` of index.js): an
/// unmodifiable list of 9 categorical [Rgb] colors.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
final List<Rgb> schemePastel1 = colors(
  'fbb4aeb3cde3ccebc5decbe4fed9a6ffffcce5d8bdfddaecf2f2f2',
);
