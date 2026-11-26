// Original code, not ported from d3-scale-chromatic: the package example.

// The example prints its results.
// ignore_for_file: avoid_print

import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';

/// Reads categorical, diverging and sequential schemes and prints hex colors.
void main() {
  // Categorical palette: ten colors of Category10.
  print(schemeCategory10.map((c) => c.formatHex()).toList());

  // Diverging ColorBrewer palette of 5 classes and its continuous interpolator.
  print(schemeBrBG[5]!.map((c) => c.formatHex()).toList());
  print(interpolateBrBG(0.5).formatHex());

  // Perceptually uniform sequential interpolators.
  print(interpolateViridis(0).formatHex()); // #440154
  print(interpolateViridis(0.5).formatHex()); // #21918c
  print(interpolateViridis(1).formatHex()); // #fde725

  // Polynomial and cyclical interpolators.
  print(interpolateTurbo(0.5)); // rgb(164, 252, 60)
  print(interpolateRainbow(0.25).formatHex());
}
