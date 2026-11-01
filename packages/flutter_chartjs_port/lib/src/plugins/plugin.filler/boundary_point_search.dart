// Original code, not ported from Chart.js: fill boundary endpoint search.

import 'package:flutter_chartjs_port/src/elements/element.line.dart';
import 'package:flutter_chartjs_port/src/elements/element.point.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:meta/meta.dart';

/// Allows differential tests to use the original boundary interpolation.
@visibleForTesting
bool boundaryPointSearchEnabled = true;

/// Exact endpoint lookup for a newly constructed, private linear fill boundary.
///
/// Only drawfill's origin/start/end targets qualify. They contain fresh points,
/// have no user callbacks, and cannot be reached by user code during the draw.
/// This index must not be retained on a chart or used for dataset targets.
final class BoundaryPointSearch {
  BoundaryPointSearch._(this._points, this._horizontal);

  final List<types.PointElement> _points;
  final bool _horizontal;

  /// Validates the private boundary once for this draw. Reversed, degenerate,
  /// non-finite and tolerance-adjacent coordinates use original interpolation.
  static BoundaryPointSearch? create(Object target, String property) {
    if (!boundaryPointSearchEnabled ||
        target.runtimeType != LineElement ||
        (property != 'x' && property != 'y')) {
      return null;
    }
    final line = target as LineElement;
    final points = line.points;
    // createBoundaryLine makes this ordinary growable list itself. Never read
    // a user list or overridden point getter while validating the shortcut.
    if (line.loop == true ||
        points.runtimeType != <types.PointElement>[].runtimeType ||
        points.length < 4 ||
        points.any((point) => point.runtimeType != PointElement)) {
      return null;
    }
    final horizontal = property == 'x';
    final fixed = horizontal ? points.first.y : points.first.x;
    if (!fixed.isFinite) return null;
    var previous = double.negativeInfinity;
    for (final point in points) {
      final value = horizontal ? point.x : point.y;
      if (!value.isFinite ||
          (horizontal ? point.y : point.x) != fixed ||
          (point.skip ?? false) ||
          (point.stop ?? false)) {
        return null;
      }
      if (previous.isFinite) {
        // Beyond isBetween's 1e-6 tolerance, including rounding at large
        // coordinates. An exact hit then gives only the bound segment [i, i].
        final margin = 1e-5 + (value.abs() + previous.abs()) * 1e-12;
        if (!(value - previous > margin)) return null;
      }
      previous = value;
    }
    return BoundaryPointSearch._(points, horizontal);
  }

  /// Returns the same point as interpolate's single [i, i] result. A miss
  /// leaves interpolation, including its tolerance and arithmetic, unchanged.
  types.PointElement? find(types.PointElement point) {
    if (point.runtimeType != PointElement) return null;
    final value = _horizontal ? point.x : point.y;
    if (!value.isFinite) return null;
    var low = 0;
    var high = _points.length;
    while (low < high) {
      final middle = (low + high) >> 1;
      final candidate = _horizontal ? _points[middle].x : _points[middle].y;
      if (candidate < value) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    if (low == _points.length) return null;
    final result = _points[low];
    return (_horizontal ? result.x : result.y) == value ? result : null;
  }
}
