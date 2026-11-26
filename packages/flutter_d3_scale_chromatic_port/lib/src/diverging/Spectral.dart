// Ported from d3-scale-chromatic v3.1.0 src/diverging/Spectral.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/diverging/Spectral.js` of d3-scale-chromatic 3.1.0: the diverging
/// ColorBrewer color scheme [schemeSpectral]
/// and interpolator [interpolateSpectral].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// diverging/Spectral.js:4 `scheme` (`schemeSpectral` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 11);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
final List<List<Rgb>?> schemeSpectral = List<List<Rgb>?>.unmodifiable([
  null,
  null,
  null,
  colors('fc8d59ffffbf99d594'),
  colors('d7191cfdae61abdda42b83ba'),
  colors('d7191cfdae61ffffbfabdda42b83ba'),
  colors('d53e4ffc8d59fee08be6f59899d5943288bd'),
  colors('d53e4ffc8d59fee08bffffbfe6f59899d5943288bd'),
  colors('d53e4ff46d43fdae61fee08be6f598abdda466c2a53288bd'),
  colors('d53e4ff46d43fdae61fee08bffffbfe6f598abdda466c2a53288bd'),
  colors('9e0142d53e4ff46d43fdae61fee08be6f598abdda466c2a53288bd5e4fa2'),
  colors('9e0142d53e4ff46d43fdae61fee08bffffbfe6f598abdda466c2a53288bd5e4fa2'),
]);

/// diverging/Spectral.js the default export (`interpolateSpectral` of index.js): the
/// continuous RGB B-spline interpolator for [schemeSpectral].
final Rgb Function(double t) interpolateSpectral = ramp(schemeSpectral);
