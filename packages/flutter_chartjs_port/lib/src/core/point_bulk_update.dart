// Original code, not ported from Chart.js: the bulk point loop of ADR 0166.

/// The pixels of the bulk point loop of the scatter controller (Chart.js ADR
/// 0166, row `adapt-bulk-point-update`).
///
/// A scale of the exact class `LinearScale` gives the inputs of its pixel of a
/// number value ([LinearPixelScale.linearPixels]). The loop reads them once
/// when it starts: inside the loop no code of the app runs, so no input
/// changes.
library;

import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:meta/meta.dart';

/// A scale that can give the inputs of its pixel of a number value.
abstract interface class LinearPixelScale() {
  /// The inputs of `getPixelForValue` of a number for a loop that runs no
  /// code of the app, or Dart `null` unless the scale is of the exact class
  /// `LinearScale`.
  LinearPixels? get linearPixels;
}

/// The inputs of scale.linear.js:44 `getPixelForValue(value)` and of
/// core.scale.js:920 `getPixelForDecimal(decimal)`, read once.
final class LinearPixels({
  /// The scale, for an aligned pixel.
  required final IScale scale,

  /// `this._startValue`.
  required final double startValue,

  /// `this._valueRange`.
  required final double valueRange,

  /// `this._startPixel`.
  required final double startPixel,

  /// `this._length`.
  required final double length,

  /// `this._reversePixels`.
  required final bool reverse,

  /// `this._alignToPixels`.
  required final bool align,
}) {
  /// The inputs of one scale, read once before a loop.
  this;

  /// `getPixelForValue(value)` of a number [value]: the same expressions in
  /// the same order. An aligned pixel takes `getPixelForDecimal` itself.
  double pixelOf(double value) {
    var decimal = (value - startValue) / valueRange;
    if (align) return scale.getPixelForDecimal(decimal);
    if (reverse) decimal = 1 - decimal;
    return int16Range(startPixel + decimal * length);
  }
}

/// Differential test switch of Chart.js ADR 0166; not a chart option. With it
/// off, the scatter loop takes no bulk run.
@visibleForTesting
bool bulkPointUpdatesEnabled = true;

/// The points that a bulk run wrote, for differential tests.
@visibleForTesting
int bulkPointUpdatesTaken = 0;

/// Whether [bulkPointUpdatesEnabled] is on, for the loop.
bool get bulkPointUpdatesOn => bulkPointUpdatesEnabled;

/// Adds [count] to [bulkPointUpdatesTaken].
void countBulkPoints(int count) => bulkPointUpdatesTaken += count;
