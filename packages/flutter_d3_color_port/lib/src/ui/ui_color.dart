// Original code, not ported from d3-color: the Flutter colors of d3-color.

/// The conversions between the colors of d3-color and the Flutter
/// [ui.Color] (D3 ADR 0008 §6).
library;

import 'dart:ui' as ui;

import 'package:flutter_d3_color_port/src/color.dart';

/// The Flutter color of a d3-color [Color].
extension D3ColorToUi on Color {
  /// This color as a Flutter sRGB color.
  ///
  /// The channels of [Color.rgb] map from [0, 255] to [0, 1] and the opacity
  /// stays in [0, 1], both clamped. The conversion does not round: a channel
  /// keeps its fraction. An undefined (NaN) channel is 0 and an undefined
  /// opacity is 1, as [Color.formatRgb] reads them.
  ui.Color toUiColor() {
    final c = rgb();
    return ui.Color.from(
      alpha: clampa(c.opacity),
      red: _unit(c.r),
      green: _unit(c.g),
      blue: _unit(c.b),
    );
  }
}

/// The d3-color [Rgb] of a Flutter color.
extension UiColorToD3 on ui.Color {
  /// This color as an [Rgb]: the channels of the extended sRGB space
  /// times 255, and the alpha as the opacity. The conversion does not round
  /// or clamp: a color outside the sRGB gamut gives channels outside
  /// [0, 255].
  Rgb toD3Rgb() {
    final c =
        colorSpace == ui.ColorSpace.sRGB ||
            colorSpace == ui.ColorSpace.extendedSRGB
        ? this
        : withValues(colorSpace: ui.ColorSpace.extendedSRGB);
    return Rgb(c.r * 255, c.g * 255, c.b * 255, c.a);
  }
}

/// The channel [value] of [0, 255] in [0, 1], clamped. NaN is 0.
double _unit(double value) {
  final v = value / 255;
  return v > 0 ? (v < 1 ? v : 1) : 0;
}
