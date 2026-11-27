// Original code, not ported from d3-chord: direct Flutter dart:ui Path helpers.

/// Direct Flutter `dart:ui.Path` helpers for `d3-chord` ribbon generators via
/// [UiPathContext] from `flutter_d3_path_port` (D3 ADR 0023).
///
/// Draws chord ribbons and arrow ribbons directly into a `dart:ui.Path` with
/// zero SVG string formatting or parsing.
library;

import 'dart:ui' as ui;

import 'package:flutter_d3_chord_port/d3_chord.dart';
import 'package:flutter_d3_path_port/flutter_d3_path_port.dart';

/// Direct `dart:ui.Path` rendering helpers for [RibbonGenerator].
extension RibbonUiPath<T, S> on RibbonGenerator<T, S> {
  /// Builds a [ui.Path] for [d] without formatting an SVG string.
  ///
  /// When [target] is provided, commands are appended into [target] (call
  /// `target.reset()` to reuse across frames).
  ui.Path toUiPath(T d, [UiPathContext? target]) {
    final ctx = target ?? UiPathContext();
    draw(d, ctx);
    return ctx.path;
  }

  /// Appends the ribbon geometry for [d] directly into [target] with zero
  /// intermediate allocations.
  void drawToUiPath(T d, UiPathContext target) => draw(d, target);
}
