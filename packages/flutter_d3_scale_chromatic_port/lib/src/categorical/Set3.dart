// Ported from d3-scale-chromatic v3.1.0 src/categorical/Set3.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/categorical/Set3.js` of d3-scale-chromatic 3.1.0: the
/// categorical color scheme [schemeSet3].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// categorical/Set3.js:3 the default export (`schemeSet3` of index.js): an
/// unmodifiable list of 12 categorical [Rgb] colors.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
final List<Rgb> schemeSet3 = colors(
  '8dd3c7ffffb3bebadafb807280b1d3fdb462b3de69fccde5d9d9d9bc80bdccebc5ffed6f',
);
