// Ported from d3-scale-chromatic v3.1.0 src/categorical/Set1.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/categorical/Set1.js` of d3-scale-chromatic 3.1.0: the
/// categorical color scheme [schemeSet1].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// categorical/Set1.js:3 the default export (`schemeSet1` of index.js): an
/// unmodifiable list of 9 categorical [Rgb] colors.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
final List<Rgb> schemeSet1 = colors(
  'e41a1c377eb84daf4a984ea3ff7f00ffff33a65628f781bf999999',
);
