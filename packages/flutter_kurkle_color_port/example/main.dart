// Original code, not ported from @kurkle/color: the example of the package.

// The example prints its results.
// ignore_for_file: avoid_print

import 'dart:ui';

import 'package:flutter_kurkle_color_port/flutter_kurkle_color_port.dart';

/// Parses CSS colors, changes a color and prints the results as CSS texts.
void main() {
  // The parse functions read the CSS text forms into an RGBA, with the alpha
  // as a byte [0..255]. The string functions write an RGBA as CSS text.
  print(hexString(nameParse('steelblue'))); // #4682B4
  print(rgbString(hexParse('#36c8'))); // rgba(51, 102, 204, 0.53)
  print(hexString(hueParse('hsl(120deg 100% 25%)'))); // #008000

  // The methods of the extension KurkleColor work on a Flutter Color.
  const c = Color(0xFF3366CC);
  print(c.hslString()); // hsl(220, 60%, 50%)

  // Each manipulation method returns a new color.
  final changed = c.lighten(0.2).rotate(30).withAlphaRatio(0.5);
  print(changed.rgbString()); // rgba(112, 92, 214, 0.5)

  // A mix with the weight 0.25 takes 25% of red and 75% of blue.
  const red = Color(0xFFFF0000);
  const blue = Color(0xFF0000FF);
  print(red.mix(blue, 0.25).hexString()); // #4000BF
}
