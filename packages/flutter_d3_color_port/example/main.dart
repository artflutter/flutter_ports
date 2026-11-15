// Original code, not ported from d3-color: the example of the package.

// The example prints its results.
// ignore_for_file: avoid_print

import 'package:flutter_d3_color_port/d3_color.dart' as d3;

/// Parses a CSS color, converts it between color spaces and prints the
/// results as CSS texts.
void main() {
  final steelblue = d3.color('steelblue')!;
  print(steelblue.formatHex()); // #4682b4

  // Rotate the hue by 90°, bump up the saturation and fade the color.
  final c = d3.Hsl.from(steelblue)
    ..h += 90
    ..s += 0.2
    ..opacity = 0.8;
  print(c); // rgba(198, 45, 205, 0.8)

  // A brighter color in CIELCh: the lightness goes up by 18.
  print(d3.Hcl.from(steelblue).brighter().formatHex()); // #79b1e6

  // A gray of CIELAB lightness 50, and a Cubehelix color.
  print(d3.gray(50).formatRgb()); // rgb(119, 119, 119)
  print(d3.Cubehelix(300, 0.5, 0.5).formatHex()); // #ae629f
}
