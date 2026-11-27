// Original code, not ported from d3-geo: direct Flutter dart:ui Path helpers.

/// Direct Flutter `dart:ui.Path` helpers for `d3-geo` [GeoPath] via
/// [UiPathContext] from `flutter_d3_path_port` (D3 ADR 0024).
///
/// Draws projected geographic geometry directly into a `dart:ui.Path` with
/// zero SVG string formatting or parsing.
library;

import 'dart:ui' as ui;

import 'package:flutter_d3_geo_port/d3_geo.dart';
import 'package:flutter_d3_path_port/flutter_d3_path_port.dart';

/// Direct `dart:ui.Path` rendering helpers for [GeoPath].
extension GeoPathUi on GeoPath {
  /// Builds a [ui.Path] for [object] without formatting an SVG string.
  ///
  /// When [target] is provided, commands are appended into [target] (call
  /// `target.reset()` to reuse across frames).
  ui.Path toUiPath(GeoJsonObject? object, [UiPathContext? target]) {
    final ctx = target ?? UiPathContext();
    draw(object, ctx);
    return ctx.path;
  }

  /// Appends the projected path geometry for [object] directly into [target]
  /// with zero intermediate SVG string allocation.
  void drawToUiPath(GeoJsonObject? object, UiPathContext target) =>
      draw(object, target);
}
