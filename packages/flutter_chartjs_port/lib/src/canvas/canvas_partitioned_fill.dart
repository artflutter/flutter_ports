// Original code, not ported from Chart.js: alternate native fill capability.

import 'package:flutter_chartjs_port/src/canvas/canvas.dart';

/// Optional native fill of an equivalent compound path. The current Canvas 2D
/// path remains unchanged. A false result draws nothing and calls no writer.
// A single optional operation dispatched on the canvas context.
// ignore: one_member_abstracts
abstract interface class PartitionedFillCanvas {
  /// Fill an equivalent nonzero path with the current solid paint and clip.
  bool tryFillPartitionedPath(void Function(CanvasPath path) writePath);
}
