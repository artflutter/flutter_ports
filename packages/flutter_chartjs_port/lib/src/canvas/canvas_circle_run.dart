// Original code, not ported from Chart.js: native point marker capability.

/// Optional run of full circles for the markers of a dataset (Chart.js ADR
/// 0104).
///
/// A context that does not implement it gets the Canvas 2D calls of
/// `PointElement.draw` for each marker.
abstract interface class CircleRunCanvas {
  /// Starts a run of circles with the radius [radius] in user space, in the
  /// current fill style and, for [stroke], the current stroke style and line
  /// width. It gives the same draws as `beginPath`, `arc`, `closePath`, `fill`
  /// and `stroke` for each circle.
  ///
  /// A false result changes no observable canvas state and requests the
  /// Canvas 2D calls.
  bool tryStartCircleRun(double radius, {required bool stroke});

  /// Draws one circle of the run at (x, y) in user space. The current path does
  /// not change: the caller makes the path of the last circle.
  ///
  /// A false result draws nothing and requests the Canvas 2D calls for this
  /// circle. Call it only after a [tryStartCircleRun] that gave true, with no
  /// other canvas call between.
  bool tryAddRunCircle(double x, double y);
}
