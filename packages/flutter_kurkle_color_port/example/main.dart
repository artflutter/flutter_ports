// Original code, not ported from @kurkle/color: the example of the package.

// The example prints its results.
// ignore_for_file: avoid_print

import 'dart:ui' as ui;

import 'package:flutter_kurkle_color_port/flutter_kurkle_color_port.dart';

/// Parses CSS colors, changes a color and prints the results as CSS texts.
void main() {
  // The parse functions read the CSS text forms into an RGBA, with the alpha
  // as a byte [0..255]. The string functions write an RGBA as CSS text.
  print(hexString(nameParse('steelblue'))); // #4682B4
  print(rgbString(hexParse('#36c8'))); // rgba(51, 102, 204, 0.53)
  print(hexString(hueParse('hsl(120deg 100% 25%)'))); // #008000

  // The Color constructor takes a Flutter Color.
  final c = Color(const ui.Color(0xFF3366CC));
  print(c.hslString()); // hsl(220, 60%, 50%)

  // Each manipulation method changes the color and returns it.
  c
    ..lighten(0.2)
    ..rotate(30)
    ..alpha(0.5);
  print(c.rgbString()); // rgba(112, 92, 214, 0.5)

  // A mix with the weight 0.25 takes 25% of red and 75% of blue.
  final red = Color(const ui.Color(0xFFFF0000));
  final blue = Color(const ui.Color(0xFF0000FF));
  print(red.mix(blue, 0.25).hexString()); // #4000BF
}
