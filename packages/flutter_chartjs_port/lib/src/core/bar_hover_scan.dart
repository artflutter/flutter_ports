// Original code, not ported from Chart.js: the typed hover scan.

/// The search of the bars and the points at an event position, for the two
/// callers of `evaluateInteractionItems` whose handler does nothing for an
/// element that the position does not intersect: `getIntersectItems` and
/// `getNearestCartesianItems` with `intersect` (core.interaction.js:114,
/// :168).
///
/// [scanBarInteractionItems] is the loop of `evaluateInteractionItems`
/// (core.interaction.js:74) with two changes for an element of the class
/// [BarElement] itself, and a test of its own for an element of the class
/// [PointElement] itself (below). Each other element takes the calls of that
/// loop at its own position.
///
/// 1. The read of `skip` is typed: such an element has `skip` only as an
///    extra property ([Element.hasExtras]).
/// 2. A miss returns before the handler: the bounds are scalar locals with
///    the expressions of `getBarBounds` and `_isBetween`, with no record. A
///    bar that this test does not reject takes the handler, which calls
///    `inRange` again.
///
/// For an element of the class [PointElement] itself, the scan reads `skip`
/// typed, and rejects a point whose distance to the position on the axis x
/// or y is above the reach `hitRadius + radius` with a margin
/// ([_pointMisses]). A point that this test does not reject takes the
/// handler, which calls `inRange` again (Chart.js ADR 0167).
///
/// The scan keeps no result of a search: it reads the pixels of each bar
/// and each point at each search (differences.md rows
/// `adapt-bar-hover-scan` and `adapt-point-hover-scan`).
library;

import 'dart:math' as math;

import 'package:flutter_chartjs_port/chartjs_core.dart';

/// `binarySearch` of `core.interaction.dart` (core.interaction.js:22).
typedef InteractionRangeSearch = ({int lo, int hi}) Function(
  ChartMeta metaset,
  InteractionAxis axis,
  double? value, [
  bool? intersect,
]);

/// `epsilon` of `_isBetween` (helpers.math.ts:205).
const double _epsilon = 1e-6;

/// Whether `bar.inRange(px, py)` is false with the current values of [bar]:
/// the expressions of `getBarBounds` and `_isBetween` (element.bar.js:15,
/// helpers.math.ts:205) with `useFinalPosition` false. A NaN makes each
/// test false, so such a bar is not rejected, and the handler decides.
@pragma('vm:prefer-inline')
bool _misses(BarElement bar, double? px, double? py) {
  final x = bar.x;
  final y = bar.y;
  final base = bar.base;
  final double left;
  final double right;
  final double top;
  final double bottom;
  if (bar.horizontal == true) {
    final half = bar.height / 2;
    left = math.min(x, base);
    right = math.max(x, base);
    top = y - half;
    bottom = y + half;
  } else {
    final half = bar.width / 2;
    left = x - half;
    right = x + half;
    top = math.min(y, base);
    bottom = math.max(y, base);
  }
  if (px != null &&
      (px < math.min(left, right) - _epsilon ||
          px > math.max(left, right) + _epsilon)) {
    return true;
  }
  if (py != null &&
      (py < math.min(top, bottom) - _epsilon ||
          py > math.max(top, bottom) + _epsilon)) {
    return true;
  }
  return false;
}

/// The relative margin of [_pointMisses]: far above one rounding step of
/// a `double` (2^-52), so a reject holds for each rounding of the upstream
/// `Math.pow` calls.
const double _reachMargin = 1e-6;

/// Whether `point.inRange(px, py)` is false with the current values of
/// [point] and `useFinalPosition` false, by a test with no `pow`
/// (element.point.ts:62-66).
///
/// [reach] is `|options.hitRadius + options.radius|` of plain numbers. The
/// test rejects when `|px - x|` or `|py - y|` is above
/// `reach * (1 + 1e-6) + 1e-6`. Then the square of that distance is above
/// `reach^2` by far more than the rounding of `Math.pow`, the sum
/// `dx^2 + dy^2` is not below it, and upstream gives false. A NaN makes each
/// comparison false, so such a point is not rejected, and the handler
/// decides. Dart `null` for [px] or [py] is JS `null`, which the upstream
/// subtraction reads as 0.
@pragma('vm:prefer-inline')
bool _pointMisses(PointElement point, double reach, double? px, double? py) {
  final bound = reach * (1 + _reachMargin) + _reachMargin;
  if (((px ?? 0) - point.x).abs() > bound) return true;
  return ((py ?? 0) - point.y).abs() > bound;
}

/// `|options.hitRadius + options.radius|` of the point options [options]
/// when both are plain numbers, else NaN: the reach of [_pointMisses]. NaN
/// rejects nothing.
@pragma('vm:prefer-inline')
double _pointReach(Object? options) {
  if (options is PointOptions &&
      plainOption(options, OptionKey.hitRadius) &&
      plainOption(options, OptionKey.radius)) {
    return (options.hitRadius + options.radius).abs();
  }
  return double.nan;
}

/// Whether [element] is of the class [PointElement] itself.
@pragma('vm:prefer-inline')
bool _isBuiltInPoint(IElement element) =>
    element is PointElement && element.typedWrites;

/// Whether [element] is of the class [BarElement] itself.
@pragma('vm:prefer-inline')
bool _isBuiltInBar(IElement element) =>
    element is BarElement && element.typedWrites;

/// `evaluateInteractionItems` of `core.interaction.dart` for a [handler]
/// that does nothing for an element whose `inRange(position.x, position.y,
/// useFinalPosition)` is false.
///
/// [intersect] is the argument of [search], as the loop of upstream gives
/// it. [skipped] is `element.skip` by name.
///
/// The loop reads the position one time, and again after each call that can
/// run code of a program: a handler call, and each call of an element of
/// another class. A bar with `$animations` and a true [useFinalPosition]
/// takes the handler at once: its bounds are those of its targets. A point
/// with `$animations` and a true [useFinalPosition] takes the handler at
/// once too. A dataset whose first element is neither a built-in bar nor a
/// built-in point takes the loop of upstream as it is.
void scanBarInteractionItems(
  IChart chart,
  InteractionAxis axis,
  Point position,
  InteractionHandler handler, {
  required bool? intersect,
  required bool? useFinalPosition,
  required InteractionRangeSearch search,
  required bool Function(Element element) skipped,
}) {
  final metasets = chart.getSortedVisibleDatasetMetas();
  // `position[axis]` of core.interaction.js:76.
  final value = switch (axis) {
    InteractionAxis.x => position.x,
    InteractionAxis.y => position.y,
    InteractionAxis.xy || InteractionAxis.r => null,
  };
  var px = position.x;
  var py = position.y;
  for (var i = 0, ilen = metasets.length; i < ilen; ++i) {
    final ChartMeta(:index, :data) = metasets[i];
    final (:lo, :hi) = search(metasets[i], axis, value, intersect);
    if (data.isNotEmpty && _isBuiltInPoint(data[0])) {
      _scanPoints(
        data,
        index,
        lo,
        hi,
        position,
        handler,
        useFinalPosition: useFinalPosition,
        skipped: skipped,
      );
      px = position.x;
      py = position.y;
      continue;
    }
    if (data.isEmpty || !_isBuiltInBar(data[0])) {
      // Not a dataset of built-in bars or points: the loop of upstream, with
      // no test of each element.
      for (var j = lo; j <= hi; ++j) {
        final element = data[j] as Element;
        if (!skipped(element)) {
          handler(element, index, j);
        }
      }
      px = position.x;
      py = position.y;
      continue;
    }
    for (var j = lo; j <= hi; ++j) {
      final element = data[j] as Element;
      if (element is BarElement && element.typedWrites) {
        if (element.hasExtras && skipped(element)) continue;
        if ((useFinalPosition != true || element.$animations == null) &&
            _misses(element, px, py)) {
          continue;
        }
        handler(element, index, j);
      } else if (!skipped(element)) {
        handler(element, index, j);
      }
      px = position.x;
      py = position.y;
    }
  }
}

/// The loop of `evaluateInteractionItems` over the range [lo] to [hi] of
/// the dataset [datasetIndex], whose first element is a built-in point.
///
/// An element of the class [PointElement] itself reads `skip` typed and
/// takes the test of [_pointMisses]. Each other element takes the calls of
/// upstream. The loop reads the options and the position of each point at
/// the point, and the position again after each handler call and each call
/// of an element of another class: these calls can run code of a program.
/// It keeps no value from one point to the next.
void _scanPoints(
  List<IElement> data,
  int datasetIndex,
  int lo,
  int hi,
  Point position,
  InteractionHandler handler, {
  required bool? useFinalPosition,
  required bool Function(Element element) skipped,
}) {
  var px = position.x;
  var py = position.y;
  for (var j = lo; j <= hi; ++j) {
    final element = data[j] as Element;
    if (element is PointElement && element.typedWrites) {
      // `_skipped`: `skip` of a point is a typed `bool?`.
      if (element.skip == true) continue;
      if (useFinalPosition != true || element.$animations == null) {
        final reach = _pointReach(element.options);
        if (_pointMisses(element, reach, px, py)) continue;
      }
      handler(element, datasetIndex, j);
    } else if (!skipped(element)) {
      handler(element, datasetIndex, j);
    }
    px = position.x;
    py = position.y;
  }
}
