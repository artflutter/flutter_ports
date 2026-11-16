// Original code, not ported from d3-interpolate: the example of the package.

// The example prints its results.
// ignore_for_file: avoid_print

import 'package:flutter_d3_color_port/d3_color.dart' as d3;
import 'package:flutter_d3_interpolate_port/d3_interpolate.dart' as d3;

/// Interpolates numbers, colors, zoom views and 2D transforms, and prints
/// the values half way.
void main() {
  // A number between 10 and 20.
  print(d3.interpolateNumber(10, 20)(0.25)); // 12.5

  // A color in RGB: the result is a d3-color Rgb, and its text is CSS.
  final rgb = d3.interpolateRgb(d3.color('steelblue')!, d3.color('brown')!);
  print(rgb(0.5)); // rgb(118, 86, 111)
  // The same with a gamma of 2.2.
  final gamma = d3.interpolateRgb.gamma(2.2)(
    d3.color('purple')!,
    d3.color('orange')!,
  );
  print(gamma(0.5)); // rgb(204, 120, 93)

  // A smooth zoom from the view (ux, uy, w) = (30, 30, 40) to
  // (135, 85, 60), and its recommended duration in milliseconds.
  // The path zooms out, pans and zooms in.
  final zoom = d3.interpolateZoom((30, 30, 40), (135, 85, 60));
  final (ux, uy, w) = zoom(0.5);
  print('${ux.round()} ${uy.round()} ${w.round()}'); // 72 52 126
  print(zoom.duration.round()); // 2291

  // The transform between matrix(2, 0, 0, 2, 0, 12) and a translation by
  // (48, 0): the parts half way.
  final transform = d3.interpolateTransform(
    d3.decompose(2, 0, 0, 2, 0, 12),
    d3.decompose(1, 0, 0, 1, 48, 0),
  );
  final p = transform(0.5);
  print('${p.translateX} ${p.translateY} ${p.scaleX}'); // 24.0 6.0 1.5
}
