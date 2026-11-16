// Original code, not ported from Chart.js: the kept shadow objects.

/// The kept objects of the shadows of one `UiCanvasContext`
/// (`canvas_ui.dart`, Chart.js ADRs 0106 and 0149): one mask filter for
/// equal blur values, and the paint of the shadow of a rectangle with a
/// solid color.
///
/// The shadow of a rectangle is one `drawRect` with the kept paint, between
/// the `save`, the `translate` and the `restore` of each shadow. The display
/// list builder of the engine turns the rectangle path that the context
/// drew before into the same rectangle operation at record time
/// (`display_list/dl_builder.cc`, `DisplayListBuilder::DrawPath`), so the
/// recorded operations are equal (differences.md row
/// `adapt-rect-shadow-ops`).
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

/// The kept shadow objects of one context.
final class UiShadowKit() {
  /// A kit with no kept object.
  this;

  // A `MaskFilter` has value equality, so a kept filter records the same
  // operation. On the web each new filter object makes a native filter and
  // a finalizer entry at its first use.
  ui.MaskFilter? _filter;
  double _filterSigma = 0;

  /// The blur filter of [sigma], which is above 0. Equal values in a row get
  /// one object.
  ui.MaskFilter filter(double sigma) {
    final kept = _filter;
    if (kept != null && sigma == _filterSigma) return kept;
    _filterSigma = sigma;
    return _filter = ui.MaskFilter.blur(ui.BlurStyle.normal, sigma);
  }

  /// The paint of the shadow of a rectangle with a solid color. Its style
  /// stays `fill`, with no shader and no color filter, as the shadow paint
  /// of a solid fill. The first shadow of a rectangle makes it.
  late final ui.Paint rectPaint = ui.Paint();

  /// The fill color and the shadow color that gave the color of
  /// [rectPaint], with the global alpha [rectAlpha]. Null when one of them
  /// is not of the exact class `Color`: then no later draw takes the kept
  /// color.
  ui.Color? rectFill;

  /// See [rectFill].
  ui.Color? rectShadow;

  /// The global alpha that gave the color of [rectPaint].
  double rectAlpha = 0;

  /// The sigma of the mask filter of [rectPaint]. 0 is no filter.
  double rectSigma = 0;

  /// The blend mode of [rectPaint].
  ui.BlendMode rectBlend = ui.BlendMode.srcOver;

  /// Keeps [fill], [shadow] and [alpha] as the sources of the color of
  /// [rectPaint]. A color of another class than `Color` can change, so it is
  /// never kept.
  void keepRectColor(ui.Color fill, ui.Color shadow, double alpha) {
    final exact =
        fill.runtimeType == ui.Color && shadow.runtimeType == ui.Color;
    rectFill = exact ? fill : null;
    rectShadow = exact ? shadow : null;
    rectAlpha = alpha;
  }

  static final Float32List _narrow = Float32List(4);

  /// Whether [rect] has an area in the 32-bit numbers of the engine: its
  /// four edges are finite there, the left edge is below the right edge and
  /// the top edge is below the bottom edge.
  ///
  /// The engine reads a path and a rectangle as 32-bit numbers. A path of
  /// four corners is a rectangle for it only with an area in these numbers.
  /// A rectangle whose two edges round to one 32-bit number has an area in
  /// the 64-bit numbers of `Rect.isEmpty` and none in the engine.
  static bool hasFloat32Area(ui.Rect rect) {
    final narrow = _narrow
      ..[0] = rect.left
      ..[1] = rect.top
      ..[2] = rect.right
      ..[3] = rect.bottom;
    final width = narrow[2] - narrow[0];
    final height = narrow[3] - narrow[1];
    return width > 0 &&
        height > 0 &&
        width < double.infinity &&
        height < double.infinity;
  }
}
