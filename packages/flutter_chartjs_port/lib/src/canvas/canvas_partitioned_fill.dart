// Original code, not ported from Chart.js: alternate native fill capability.

import 'package:flutter_chartjs_port/src/canvas/canvas.dart';

/// Optional native fill of an equivalent compound path. The current Canvas 2D
/// path remains unchanged. A false result draws nothing and calls no writer.
abstract interface class PartitionedFillCanvas {
  /// Whether [tryFillPartitionedPath] can draw on this context. The web
  /// declines it: one compound path takes the slow route of Skia there, and
  /// `fill` cuts a deferred path into pieces (Chart.js ADR 0113).
  bool get takesPartitionedFill;

  /// The fewest points of a line whose fill path [deferCurrentPath] keeps.
  int get deferredFillMinPoints;

  /// Keeps the current path out of the engine until a read of it: a successful
  /// [tryFillPartitionedPath] leaves it unread (Chart.js ADR 0104). A read gets
  /// the same path. Call it after `beginPath`.
  void deferCurrentPath();

  /// Fill an equivalent nonzero path with the current solid paint and clip.
  bool tryFillPartitionedPath(void Function(CanvasPath path) writePath);
}
