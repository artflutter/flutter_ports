// Ported from d3-scale-chromatic v3.1.0 src/sequential-multi/YlOrRd.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/sequential-multi/YlOrRd.js` of d3-scale-chromatic 3.1.0: the sequential multi-hue
/// ColorBrewer color scheme [schemeYlOrRd]
/// and interpolator [interpolateYlOrRd].
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// sequential-multi/YlOrRd.js:4 `scheme` (`schemeYlOrRd` of index.js): the discrete
/// ColorBrewer palettes indexed by class count (3 to 9);
/// indices 0, 1 and 2 are null.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-public-names, named export.
final List<List<Rgb>?> schemeYlOrRd = List<List<Rgb>?>.unmodifiable([
  null,
  null,
  null,
  colors('ffeda0feb24cf03b20'),
  colors('ffffb2fecc5cfd8d3ce31a1c'),
  colors('ffffb2fecc5cfd8d3cf03b20bd0026'),
  colors('ffffb2fed976feb24cfd8d3cf03b20bd0026'),
  colors('ffffb2fed976feb24cfd8d3cfc4e2ae31a1cb10026'),
  colors('ffffccffeda0fed976feb24cfd8d3cfc4e2ae31a1cb10026'),
  colors('ffffccffeda0fed976feb24cfd8d3cfc4e2ae31a1cbd0026800026'),
]);

/// sequential-multi/YlOrRd.js the default export (`interpolateYlOrRd` of index.js): the
/// continuous RGB B-spline interpolator for [schemeYlOrRd].
final Rgb Function(double t) interpolateYlOrRd = ramp(schemeYlOrRd);
