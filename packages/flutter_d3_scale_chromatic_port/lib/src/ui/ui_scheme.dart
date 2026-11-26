// Original code, not ported from d3-scale-chromatic: the Flutter layer.

/// Flutter [ui.Color] conversions for the schemes and interpolators of
/// d3-scale-chromatic (D3 ADR 0008 §6).
library;

import 'dart:ui' as ui;

import 'package:flutter_d3_color_port/flutter_d3_color_port.dart';

/// Flutter color list conversion for a d3-scale-chromatic palette.
extension D3ColorSchemeToUi on List<Color> {
  /// Converts each color in this palette to a Flutter [ui.Color] via
  /// [D3ColorToUi.toUiColor].
  List<ui.Color> toUiColors() => [for (final c in this) c.toUiColor()];
}

/// Flutter color conversion for a d3-scale-chromatic interpolator.
extension D3ColorInterpolatorToUi on Color Function(double t) {
  /// Wraps this interpolator so each call returns a Flutter [ui.Color].
  ui.Color Function(double t) toUiColorInterpolator() =>
      (t) => this(t).toUiColor();
}
