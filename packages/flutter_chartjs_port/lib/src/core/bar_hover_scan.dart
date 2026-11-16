// Original code, not ported from Chart.js: the typed hover scan of bars.

/// The search of the bars at an event position, for the two callers of
/// `evaluateInteractionItems` whose handler does nothing for an element
/// that the position does not intersect: `getIntersectItems` and
/// `getNearestCartesianItems` with `intersect` (core.interaction.js:114,
/// :168).
///
/// [scanBarInteractionItems] is the loop of `evaluateInteractionItems`
/// (core.interaction.js:74) with two changes for an element of the class
/// [BarElement] itself. Each other element takes the calls of that loop at
/// its own position.
///
/// 1. The read of `skip` is typed: such an element has `skip` only as an
///    extra property ([Element.hasExtras]).
/// 2. A miss returns before the handler: the bounds are scalar locals with
///    the expressions of `getBarBounds` and `_isBetween`, with no record. A
///    bar that this test does not reject takes the handler, which calls
///    `inRange` again.
///
/// The scan keeps no result of a search: it reads the pixels of each bar at
/// each search (differences.md row `adapt-bar-hover-scan`).
library;

import 'dart:math' as math;

import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/core/core.interaction.dart'
    show InteractionAxis, InteractionHandler;
import 'package:flutter_chartjs_port/src/elements/element.bar.dart';
import 'package:flutter_chartjs_port/src/types/geometric.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:meta/meta.dart';

/// `binarySearch` of `core.interaction.dart` (core.interaction.js:22).
typedef InteractionRangeSearch = ({int lo, int hi}) Function(
  types.ChartMeta metaset,
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

/// Whether [element] is of the class [BarElement] itself.
@pragma('vm:prefer-inline')
bool _isBuiltInBar(types.Element element) =>
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
/// takes the handler at once: its bounds are those of its targets. A
/// dataset whose first element is not a built-in bar takes the loop of
/// upstream as it is.
@internal
void scanBarInteractionItems(
  types.Chart chart,
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
    final types.ChartMeta(:index, :data) = metasets[i];
    final (:lo, :hi) = search(metasets[i], axis, value, intersect);
    if (data.isEmpty || !_isBuiltInBar(data[0])) {
      // Not a dataset of built-in bars: the loop of upstream, with no test
      // of each element.
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
