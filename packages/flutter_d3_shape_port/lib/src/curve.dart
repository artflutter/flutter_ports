// Original code, not ported from d3-shape: Curve interface and factory typedef.

/// The pure [Curve] interface and [CurveFactory] typedef (D3 ADR 0015).
library;

import 'package:flutter_d3_path_port/d3_path.dart';

/// A stateful curve interpolator that translates a sequence of `(x, y)` points
/// into [CanvasPath] commands.
abstract interface class Curve() {
  /// Signals the start of a new area segment.
  void areaStart();

  /// Signals the end of the current area segment.
  void areaEnd();

  /// Signals the start of a new line segment.
  void lineStart();

  /// Signals the end of the current line segment.
  void lineEnd();

  /// Adds a point `(x, y)` to the current line segment.
  void point(double x, double y);
}

/// Creates a [Curve] writing into [context].
typedef CurveFactory = Curve Function(CanvasPath context);
