// Original code, not ported from d3-path: the pure Canvas 2D path interface.

/// The eight Canvas 2D path methods used by D3 generators (`Path`, `d3-shape`,
/// `d3-chord`, `d3-geo`, `d3-delaunay`, and `UiPathContext`).
///
/// Pure Dart with no Flutter import (D3 ADR 0014). Coordinates are typed
/// [double] values and `ccw` is a typed [bool].
library;

/// A Canvas 2D path sink implemented by `Path` (SVG path string) and
/// `UiPathContext` (Flutter `dart:ui.Path`).
abstract interface class CanvasPath() {
  /// Begins a new subpath at `(x, y)`.
  void moveTo(double x, double y);

  /// Closes the current subpath by connecting back to its starting point.
  void closePath();

  /// Connects the last point in the subpath to `(x, y)` with a straight line.
  void lineTo(double x, double y);

  /// Adds a quadratic Bézier curve with control point `(x1, y1)` to `(x, y)`.
  void quadraticCurveTo(double x1, double y1, double x, double y);

  /// Adds a cubic Bézier curve with control points `(x1, y1)` and `(x2, y2)`
  /// to `(x, y)`.
  void bezierCurveTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x,
    double y,
  );

  /// Adds a circular arc of radius [r] tangent to the segments from the current
  /// point to `(x1, y1)` and from `(x1, y1)` to `(x2, y2)`.
  void arcTo(double x1, double y1, double x2, double y2, double r);

  /// Adds a circular arc centered at `(x, y)` with radius [r] from angle [a0]
  /// to [a1], counter-clockwise when [ccw] is `true`.
  void arc(
    double x,
    double y,
    double r,
    double a0,
    double a1, [
    bool ccw = false,
  ]);

  /// Adds a closed rectangular subpath at `(x, y)` with size `w × h`.
  void rect(double x, double y, double w, double h);
}
