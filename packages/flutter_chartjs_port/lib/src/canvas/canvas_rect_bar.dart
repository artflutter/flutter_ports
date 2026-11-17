// Original code, not ported from Chart.js: native bar drawing capability.

/// Optional fused drawing for already-computed ordinary bar rectangles.
/// A false result changes no observable canvas state and requests the normal
/// Canvas 2D sequence. A true result preserves its pixels, final current path,
/// saved drawing state, notifications and paint ordering.
abstract interface class RectBarCanvas() {
  /// Draw the border ring and inner fill as one guarded native operation.
  bool tryDrawRectBar({
    required double outerX,
    required double outerY,
    required double outerWidth,
    required double outerHeight,
    required double innerX,
    required double innerY,
    required double innerWidth,
    required double innerHeight,
    required Object? borderColor,
    required Object? backgroundColor,
  });

  /// Draw the border ring and the inner fill of a bar with rounded corners
  /// as one guarded native operation (Chart.js ADR 0158).
  ///
  /// The numbers are those of `boundingRects` (element.bar.js:73) for an
  /// `inflateAmount` of 0: the outer and the inner rectangle, each with the
  /// radii of its upper-left, upper-right, lower-right and lower-left
  /// corners. The ordinary sequence adds each rectangle with
  /// `addRoundedRectPath` (helpers.canvas.ts:498). [border] is the test
  /// `outer.w !== inner.w || outer.h !== inner.h` of element.bar.js:186: the
  /// sequence fills the border ring only when it is true.
  bool tryDrawRoundedBar({
    required bool border,
    required double outerX,
    required double outerY,
    required double outerWidth,
    required double outerHeight,
    required double outerUpperLeft,
    required double outerUpperRight,
    required double outerLowerRight,
    required double outerLowerLeft,
    required double innerX,
    required double innerY,
    required double innerWidth,
    required double innerHeight,
    required double innerUpperLeft,
    required double innerUpperRight,
    required double innerLowerRight,
    required double innerLowerLeft,
    required Object? borderColor,
    required Object? backgroundColor,
  });
}
