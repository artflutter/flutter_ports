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
}
