// Ported from d3-scale-chromatic v3.1.0 src/categorical/Pastel2.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/categorical/Pastel2.js` of d3-scale-chromatic 3.1.0: the
/// categorical color scheme [schemePastel2].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// categorical/Pastel2.js:3 the default export (`schemePastel2` of index.js): an
/// unmodifiable list of 8 categorical [Rgb] colors.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
final List<Rgb> schemePastel2 = colors(
  'b3e2cdfdcdaccbd5e8f4cae4e6f5c9fff2aef1e2cccccccc',
);
