// Original code, not ported from Chart.js: native line fan capability.

import 'dart:typed_data';

/// Optional fused drawing for a run of strokes of one style, each of one line
/// from one start point: the angle lines of a radial scale (Chart.js ADR 0103).
///
/// A context that does not implement it gets the Canvas 2D calls of the run.
// This is a capability dispatched on the context, not a standalone operation.
// ignore: one_member_abstracts
abstract interface class LineFanCanvas {
  /// Strokes [count] lines from ([x], [y]), in order, with the current style:
  /// `beginPath`, `moveTo(x, y)`, `lineTo` and `stroke` for each line.
  ///
  /// [writeEnds] writes the end points into its list of `2 * count` numbers, in
  /// user space: the x and the y of each line. It runs no user code and no call
  /// of the canvas. A context that declines from its state does not call it.
  ///
  /// A false result changes no observable canvas state and requests the normal
  /// Canvas 2D sequence. A true result keeps the pixels, the styles, the
  /// transform, the notifications and the paint order of that sequence, and
  /// leaves the path of its last line as the current path.
  bool tryStrokeLineFan(
    double x,
    double y,
    int count,
    void Function(Float64List ends) writeEnds,
  );
}
