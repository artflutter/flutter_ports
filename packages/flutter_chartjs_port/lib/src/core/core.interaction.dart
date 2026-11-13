// Ported from Chart.js v4.6.1 src/core/core.interaction.js (MIT, Chart.js Contributors).

/// Port of `src/core/core.interaction.js`.
///
/// The interaction modes find the elements at an event position. The chart,
/// its metas and their controllers are the interfaces of
/// `lib/src/types/index.dart` (Chart.js ADR 0003). An interaction item
/// holds the concrete [Element] of `core.element.dart`, the type that the
/// typedef of core.interaction.js:10 names.
///
/// A data element is an [Element] (index.d.ts:484). Upstream calls the
/// methods of `VisualElement` on it by name. The port casts it to
/// `types.VisualElement` at the call, and a cast that fails throws a
/// `TypeError`, as the call of an absent method does. `getAxisItems` tests
/// the method first (core.interaction.js:234). The port tests the type
/// there. The property read `element.skip` is the access by name of
/// [Element].
///
/// A coordinate of the event position is `double?`: Dart `null` is JS
/// `null` (geometric.dart, `Point`). The calls of `inRange`, `inXRange` and
/// `inYRange` pass it unchanged, as upstream does (core.interaction.js:125,
/// :174, :234, :236): `BarElement` reads a `null` coordinate as "ignore this
/// axis" (element.bar.js:103-111). Where this file does arithmetic or a
/// comparison on a coordinate, it writes the `ToNumber` as `x ?? 0`
/// (Chart.js ADR 0045).
///
/// Upstream imports `_isPointInArea` and `isNullOrUndef` from
/// `helpers/index.js`. The port imports `helpers.canvas.dart` and
/// `helpers.core.dart`, because `helpers/index.dart` also exports
/// `helpers.extras.dart`, which is not a pure layer. Thus this library is a
/// pure layer.
library;

import 'dart:math' as math;

import 'package:flutter_chartjs_port/src/core/chart_axis_reads.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.canvas.dart'
    show isPointInArea;
import 'package:flutter_chartjs_port/src/helpers/helpers.collection.dart'
    show lookupByAxis, rlookupByAxis;
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart'
    show readOption;
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart'
    show isNullOrUndef;
import 'package:flutter_chartjs_port/src/helpers/helpers.dom.dart'
    show getRelativePosition;
import 'package:flutter_chartjs_port/src/helpers/helpers.math.dart'
    show angleBetween, getAngleFromPoint;
import 'package:flutter_chartjs_port/src/js/js_math.dart' show jsSquare;
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/animated_prop.dart'
    show AnimatedProp;
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart'
    show OptionKey;
import 'package:flutter_chartjs_port/src/options/parsed.dart' show ParsedItem;
import 'package:flutter_chartjs_port/src/types/chart_axis.dart';
import 'package:flutter_chartjs_port/src/types/geometric.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:meta/meta.dart';

/// core.interaction.js:10 `InteractionItem`, the object
/// `{element, datasetIndex, index}` of an interaction mode
/// (index.d.ts:757).
///
/// It implements `types.ActiveElement`, because the chart keeps the items
/// as its active elements (index.d.ts:520-521). TypeScript accepts them by
/// structure. [datasetIndex] and [index] are numbers (Chart.js ADR 0045).
///
/// Two items are equal when their fields are equal, as the `toEqual` of a
/// spec compares two object literals. The elements compare by identity: the
/// specs compare an item with the elements of a meta.
@immutable
final class InteractionItem implements types.ActiveElement {
  /// The object literal `{element, datasetIndex, index}`
  /// (core.interaction.js:126).
  const InteractionItem({
    required this.element,
    required this.datasetIndex,
    required this.index,
  });

  /// core.interaction.js:10 `element`, the element of the item.
  @override
  final Element element;

  /// core.interaction.js:10 `datasetIndex`, the index of the dataset.
  @override
  final double datasetIndex;

  /// core.interaction.js:10 `index`, the index of the element in the data
  /// of the dataset.
  @override
  final double index;

  @override
  bool operator ==(Object other) =>
      other is InteractionItem &&
      identical(element, other.element) &&
      datasetIndex == other.datasetIndex &&
      index == other.index;

  @override
  int get hashCode =>
      Object.hash(identityHashCode(element), datasetIndex, index);

  /// The item as JavaScript prints its numbers, for test messages.
  @override
  String toString() =>
      '{element: ${element.runtimeType}, '
      'datasetIndex: ${jsNumberToString(datasetIndex)}, '
      'index: ${jsNumberToString(index)}}';
}

/// index.d.ts:763 `InteractionModeFunction`, the type of the function of a
/// mode ([InteractionMode.itemsAt]).
///
/// [e] is the event: a `types.ChartEvent`, or a `NativeEvent` of
/// `lib/src/platform/native_event.dart`, as `getRelativePosition` takes
/// (helpers.dom.ts:105). [options] are the `InteractionOptions` of
/// core.interaction.js:9: a view of the options or a plain object (Chart.js
/// ADR 0054 §5). Dart `null`
/// for [useFinalPosition] stands for an absent argument, JS `undefined`.
typedef InteractionModeFunction = List<InteractionItem> Function(
  types.Chart chart,
  Object e,
  Object options, [
  bool? useFinalPosition,
]);

/// The callback of [Interaction.evaluateInteractionItems]: the element, the
/// dataset index and the index of the element (index.d.ts:813).
typedef InteractionHandler = void Function(
  Element element,
  double datasetIndex,
  double index,
);

/// `position[axis]` of core.interaction.js:76: the coordinate of the axis
/// `'x'` or `'y'`.
///
/// Dart `null` stands for a JS `null` coordinate, and for the `undefined`
/// of another axis. `binarySearch` reads the value only for the axis of the
/// index scale, which is `'x'` or `'y'`.
double? _positionValue(Point position, InteractionAxis axis) => switch (axis) {
  InteractionAxis.x => position.x,
  InteractionAxis.y => position.y,
  InteractionAxis.xy || InteractionAxis.r => null,
};

/// The JS read `point[axis]` of a parsed item (`unknown[]`, index.d.ts:503):
/// the typed axis value of a [ParsedItem] (Chart.js ADR 0054 §8), else the
/// read of the key of the axis ([axisDataKey]): the Map read for a Map, else
/// [jsGet], an item of the user data with `parsing: false`. The Map read
/// gives Dart `null` for an absent key, where JavaScript gives `undefined`.
/// `isNullOrUndef` gives the same result for both. An axis of another class
/// gives [undefined].
Object? _parsedValue(Object? point, ScaleAxis axis) {
  if (point is ParsedItem) return point.valueOf(axis);
  final key = axisDataKey(axis);
  if (key == null) return undefined;
  return point is Map<dynamic, dynamic> ? point[key] : jsGet(point, key);
}

/// `element.skip` of core.interaction.js:85 and :188: the typed `skip` of a
/// point element (Chart.js ADR 0054 §9), else the read by name of the
/// element (the face of Chart.js ADR 0017 §5): another element class has no
/// `skip` of its own.
bool _skipped(Element element) => jsTruthy(switch (element) {
  final types.PointElement point => point.skip,
  _ => element['skip'],
});

/// core.interaction.js:22 `binarySearch`.
///
/// Helper function to do binary search when possible
/// @param {object} metaset - the dataset meta
/// @param {string} axis - the axis mode. x|y|xy|r
/// @param {number} value - the value to find
/// @param {boolean} [intersect] - should the element intersect
/// @returns {{lo:number, hi:number}} indices to search data array between
///
/// The indices are list indices, thus `int` values (Chart.js ADR 0045). The
/// search reads [value] as a number: Dart `null` gives 0, the `ToNumber` of
/// JS `null`. `getRange` follows Chart.js ADR 0020, section 9.
///
/// The `slice`, `reverse` and `findIndex` of :35-45 are `lastIndexWhere`
/// and `indexWhere` over `_parsed`, with the same distances and no copy. The
/// test reads `vScale.axis` for each point that it tests, as upstream does.
({int lo, int hi}) _binarySearch(
  types.ChartMeta metaset,
  InteractionAxis axis,
  double? value, [
  bool? intersect,
]) {
  final controller = metaset.controller!;
  final data = metaset.data;
  final sorted = metaset.sorted;
  final iScale = controller.cachedMeta.iScale;
  final dataset = metaset.dataset;
  final spanGaps = dataset != null
      ? dataset.options != null
            ? readOption(dataset.options, OptionKey.spanGaps)
            : null
      : null;

  // `axis === iScale.axis && axis !== 'r'`: the interaction axis x with a
  // scale of the axis x, or y with y.
  final sameAxis = switch ((axis, iScale?.axis)) {
    (InteractionAxis.x, XAxis()) || (InteractionAxis.y, YAxis()) => true,
    _ => false,
  };
  if (iScale != null && sameAxis && sorted && data.isNotEmpty) {
    // The key of the parsed items: the axis of the index scale.
    final key = iScale.axis;
    final lookupMethod = iScale.reversePixels ? rlookupByAxis : lookupByAxis;
    if (intersect != true) {
      final result = lookupMethod(data, key, value ?? 0);
      var lo = result.lo;
      var hi = result.hi;
      if (jsTruthy(spanGaps)) {
        final vScale = controller.cachedMeta.vScale;
        final parsed = metaset.parsed;

        // _parsed.slice(0, lo + 1).reverse().findIndex(...)
        final loStart = math.min(lo, parsed.length - 1);
        final definedLo = parsed.lastIndexWhere(
          (point) => !isNullOrUndef(_parsedValue(point, vScale!.axis)),
          loStart,
        );
        final distanceToDefinedLo = definedLo == -1 ? -1 : loStart - definedLo;
        lo -= math.max(0, distanceToDefinedLo);

        // _parsed.slice(hi).findIndex(...)
        final definedHi = parsed.indexWhere(
          (point) => !isNullOrUndef(_parsedValue(point, vScale!.axis)),
          hi,
        );
        final distanceToDefinedHi = definedHi == -1 ? -1 : definedHi - hi;
        hi += math.max(0, distanceToDefinedHi);
      }
      return (lo: lo, hi: hi);
    } else if (controller.sharedOptions != null) {
      // _sharedOptions indicates that each element has equal options ->
      // equal proportions
      // So we can do a ranged binary search based on the range of first
      // element and
      // be confident to get the full range of indices that can intersect
      // with the value.
      final el = data[0];
      // `typeof el.getRange === 'function' && el.getRange(axis)` (Chart.js
      // ADR 0020, section 9). A data element is a `types.Element`, which
      // `types.VisualElementRange` does not extend. Thus the test is a
      // pattern, and not `is`, which would not promote [el].
      final range = switch (el) {
        final types.VisualElementRange element => element.getRange(key),
        _ => false,
      };
      if (jsTruthy(range)) {
        // `value - range` applies `ToNumber` to a string range. `value +
        // range` is the JS `+` ([jsAdd]): a string range joins. The lookup
        // compares the joined text with a number through `<` or `>=`, which
        // apply `ToNumber` to it.
        final start = lookupMethod(data, key, (value ?? 0) - jsToNumber(range));
        final end = lookupMethod(data, key, jsToNumber(jsAdd(value, range)));
        return (lo: start.lo, hi: end.hi);
      }
    }
  }
  // Default to all elements, when binary search can not be used.
  return (lo: 0, hi: data.length - 1);
}

/// core.interaction.js:74 `evaluateInteractionItems`.
///
/// Helper function to select candidate elements for interaction
/// @param {Chart} chart - the chart
/// @param {string} axis - the axis mode. x|y|xy|r
/// @param {Point} position - the point to be nearest to, in relative
///   coordinates
/// @param {function} handler - the callback to execute for each visible item
/// @param {boolean} [intersect] - consider intersecting items
///
/// Each data element is an [Element] (see the library documentation). The
/// handler gets the index as a number. index.d.ts:815 declares a result,
/// but upstream returns `undefined`.
void _evaluateInteractionItems(
  types.Chart chart,
  InteractionAxis axis,
  Point position,
  InteractionHandler handler, [
  bool? intersect,
]) {
  final metasets = chart.getSortedVisibleDatasetMetas();
  final value = _positionValue(position, axis);
  for (var i = 0, ilen = metasets.length; i < ilen; ++i) {
    final types.ChartMeta(:index, :data) = metasets[i];
    final (:lo, :hi) = _binarySearch(metasets[i], axis, value, intersect);
    for (var j = lo; j <= hi; ++j) {
      final element = data[j] as Element;
      if (!_skipped(element)) {
        handler(element, index, j * 1.0);
      }
    }
  }
}

/// core.interaction.js:94 `getDistanceMetricForAxis`.
///
/// Get a distance metric function for two points based on the
/// axis mode setting
/// @param {string} axis - the axis mode. x|y|xy|r
///
/// `Math.pow(delta, 2)` is [jsSquare] (Chart.js ADR 0045).
double Function(Point pt1, Point pt2) _getDistanceMetricForAxis(
  InteractionAxis axis,
) {
  final useX = axis.usesX;
  final useY = axis.usesY;

  return (pt1, pt2) {
    final deltaX = useX ? ((pt1.x ?? 0) - (pt2.x ?? 0)).abs() : 0.0;
    final deltaY = useY ? ((pt1.y ?? 0) - (pt2.y ?? 0)).abs() : 0.0;
    return math.sqrt(jsSquare(deltaX) + jsSquare(deltaY));
  };
}

/// core.interaction.js:114 `getIntersectItems`.
///
/// Helper function to get the items that intersect the event position
/// @param {Chart} chart - the chart
/// @param {Point} position - the point to be nearest to, in relative
///   coordinates
/// @param {string} axis - the axis mode. x|y|xy|r
/// @param {boolean} [useFinalPosition] - use the element's animation target
///   instead of current position
/// @param {boolean} [includeInvisible] - include invisible points that are
///   outside of the chart area
/// @return {InteractionItem[]} the nearest items
List<InteractionItem> _getIntersectItems(
  types.Chart chart,
  Point position,
  InteractionAxis axis,
  bool? useFinalPosition,
  bool includeInvisible,
) {
  final items = <InteractionItem>[];

  if (!includeInvisible && !chart.isPointInArea(position)) {
    return items;
  }

  void evaluationFunc(Element element, double datasetIndex, double index) {
    if (!includeInvisible && !isPointInArea(element, chart.chartArea, 0)) {
      return;
    }
    if ((element as types.VisualElement).inRange(
      position.x,
      position.y,
      useFinalPosition,
    )) {
      items.add(
        InteractionItem(
          element: element,
          datasetIndex: datasetIndex,
          index: index,
        ),
      );
    }
  }

  _evaluateInteractionItems(chart, axis, position, evaluationFunc, true);
  return items;
}

/// core.interaction.js:142 `getNearestRadialItems`.
///
/// Helper function to get the items nearest to the event position for a radial
/// chart
/// @param {Chart} chart - the chart to look at elements from
/// @param {Point} position - the point to be nearest to, in relative
///   coordinates
/// @param {string} axis - the axes along which to measure distance
/// @param {boolean} [useFinalPosition] - use the element's animation target
///   instead of current position
/// @return {InteractionItem[]} the nearest items
///
/// The literal `{x: position.x, y: position.y}` of :147 copies the two
/// coordinates. `getAngleFromPoint` reads only them. Thus the port passes
/// [position].
///
/// `getProps(['startAngle', 'endAngle'], useFinalPosition)` of :146 is the
/// typed form [Element.finalNumber] of each angle, with the current value of
/// [Element.numberOf] (Chart.js ADR 0054 §9): the `ToNumber` that the
/// arithmetic of `_angleBetween` applies. An element without angles (a
/// point of a radar) gives NaN, as the read of `undefined` does.
List<InteractionItem> _getNearestRadialItems(
  types.Chart chart,
  Point position,
  InteractionAxis axis, [
  bool? useFinalPosition,
]) {
  final items = <InteractionItem>[];

  void evaluationFunc(Element element, double datasetIndex, double index) {
    final startAngle = element.finalNumber(
      AnimatedProp.startAngle,
      element.numberOf(AnimatedProp.startAngle),
      useFinalPosition,
    );
    final endAngle = element.finalNumber(
      AnimatedProp.endAngle,
      element.numberOf(AnimatedProp.endAngle),
      useFinalPosition,
    );
    final (:angle, distance: _) = getAngleFromPoint(element, position);

    if (angleBetween(angle, startAngle, endAngle)) {
      items.add(
        InteractionItem(
          element: element,
          datasetIndex: datasetIndex,
          index: index,
        ),
      );
    }
  }

  _evaluateInteractionItems(chart, axis, position, evaluationFunc);
  return items;
}

/// core.interaction.js:168 `getNearestCartesianItems`.
///
/// Helper function to get the items nearest to the event position for a
/// cartesian chart
/// @param {Chart} chart - the chart to look at elements from
/// @param {Point} position - the point to be nearest to, in relative
///   coordinates
/// @param {string} axis - the axes along which to measure distance
/// @param {boolean} [intersect] - if true, only consider items that intersect
///   the position
/// @param {boolean} [useFinalPosition] - use the element's animation target
///   instead of current position
/// @param {boolean} [includeInvisible] - include invisible points that are
///   outside of the chart area
/// @return {InteractionItem[]} the nearest items
List<InteractionItem> _getNearestCartesianItems(
  types.Chart chart,
  Point position,
  InteractionAxis axis,
  bool intersect,
  bool? useFinalPosition,
  bool includeInvisible,
) {
  var items = <InteractionItem>[];
  final distanceMetric = _getDistanceMetricForAxis(axis);
  var minDistance = double.infinity;

  void evaluationFunc(Element element, double datasetIndex, double index) {
    final visual = element as types.VisualElement;
    final inRange = visual.inRange(position.x, position.y, useFinalPosition);
    if (intersect && !inRange) {
      return;
    }

    final center = visual.getCenterPoint(useFinalPosition);
    final pointInArea = includeInvisible || chart.isPointInArea(center);
    if (!pointInArea && !inRange) {
      return;
    }

    final distance = distanceMetric(position, center);
    if (distance < minDistance) {
      items = [
        InteractionItem(
          element: element,
          datasetIndex: datasetIndex,
          index: index,
        ),
      ];
      minDistance = distance;
    } else if (distance == minDistance) {
      // Can have multiple items at the same distance in which case we sort by
      // size
      items.add(
        InteractionItem(
          element: element,
          datasetIndex: datasetIndex,
          index: index,
        ),
      );
    }
  }

  _evaluateInteractionItems(chart, axis, position, evaluationFunc);
  return items;
}

/// core.interaction.js:209 `getNearestItems`.
///
/// Helper function to get the items nearest to the event position considering
/// all visible items in the chart
/// @param {Chart} chart - the chart to look at elements from
/// @param {Point} position - the point to be nearest to, in relative
///   coordinates
/// @param {string} axis - the axes along which to measure distance
/// @param {boolean} [intersect] - if true, only consider items that intersect
///   the position
/// @param {boolean} [useFinalPosition] - use the element's animation target
///   instead of current position
/// @param {boolean} [includeInvisible] - include invisible points that are
///   outside of the chart area
/// @return {InteractionItem[]} the nearest items
List<InteractionItem> _getNearestItems(
  types.Chart chart,
  Point position,
  InteractionAxis axis,
  bool intersect,
  bool? useFinalPosition,
  bool includeInvisible,
) {
  if (!includeInvisible && !chart.isPointInArea(position)) {
    return [];
  }

  return axis == InteractionAxis.r && !intersect
      ? _getNearestRadialItems(chart, position, axis, useFinalPosition)
      : _getNearestCartesianItems(
          chart,
          position,
          axis,
          intersect,
          useFinalPosition,
          includeInvisible,
        );
}

/// core.interaction.js:228 `getAxisItems`.
///
/// Helper function to get the items matching along the given X or Y axis
/// @param {Chart} chart - the chart to look at elements from
/// @param {Point} position - the point to be nearest to, in relative
///   coordinates
/// @param {string} axis - the axis to match
/// @param {boolean} [intersect] - if true, only consider items that intersect
///   the position
/// @param {boolean} [useFinalPosition] - use the element's animation target
///   instead of current position
/// @return {InteractionItem[]} the nearest items
///
/// The modes `x` and `y` pass [InteractionAxis.x] or [InteractionAxis.y].
/// The test
/// `element[rangeMethod] &&` of :234 is a test for `types.VisualElement`,
/// which declares `inXRange` and `inYRange`. `ArcElement` gives false for
/// both (`adapt-arc-axis-range`, differences.md).
List<InteractionItem> _getAxisItems(
  types.Chart chart,
  Point position,
  InteractionAxis axis,
  bool intersect, [
  bool? useFinalPosition,
]) {
  final items = <InteractionItem>[];
  final rangeMethod = axis == InteractionAxis.x ? 'inXRange' : 'inYRange';
  var intersectsItem = false;

  _evaluateInteractionItems(chart, axis, position, (
    element,
    datasetIndex,
    index,
  ) {
    // An [Element] is not a `types.VisualElement` by its type. Thus the test
    // is a pattern, which binds [visual].
    if (element case final types.VisualElement visual
        when _inAxisRange(
          visual,
          rangeMethod,
          _positionValue(position, axis),
          useFinalPosition,
        )) {
      items.add(
        InteractionItem(
          element: element,
          datasetIndex: datasetIndex,
          index: index,
        ),
      );
      intersectsItem =
          intersectsItem ||
          visual.inRange(position.x, position.y, useFinalPosition);
    }
  });

  // If we want to trigger on an intersect and we don't have any items
  // that intersect the position, return nothing
  if (intersect && !intersectsItem) {
    return [];
  }
  return items;
}

/// `element[rangeMethod](value, useFinalPosition)` of core.interaction.js:234
/// for the method name `'inXRange'` or `'inYRange'`.
bool _inAxisRange(
  types.VisualElement element,
  String rangeMethod,
  double? value,
  bool? useFinalPosition,
) => rangeMethod == 'inXRange'
    ? element.inXRange(value, useFinalPosition)
    : element.inYRange(value, useFinalPosition);

/// The option `options.axis || fallback` of core.interaction.js:272, :308,
/// :338 and :354.
///
/// The option holds an [InteractionAxis]. A value that is not an axis gives
/// [fallback], as a falsy value does upstream.
InteractionAxis _axisOption(Object options, InteractionAxis fallback) =>
    InteractionAxis.of(readOption(options, OptionKey.axis)) ?? fallback;

/// The option `options.includeInvisible || false` of core.interaction.js:273,
/// :309, :339 and :355. The readers test only its truthiness.
bool _includeInvisibleOption(Object options) =>
    jsTruthy(readOption(options, OptionKey.includeInvisible));

/// The option `options.intersect`. The readers test only its truthiness
/// (core.interaction.js:274, :310, :175, :214, :242).
bool _intersectOption(Object options) =>
    jsTruthy(readOption(options, OptionKey.intersect));

/// `meta.data[index]` of core.interaction.js:285: the element at the number
/// [index], or Dart `null` for the `undefined` of an index outside the list.
///
/// [index] is the index of an interaction item: a whole number from 0.
Element? _dataAt(List<types.Element> data, double index) =>
    index < data.length ? data[index.toInt()] as Element : null;

/// core.interaction.js:269 `modes.index`.
///
/// Returns items at the same index. If the options.intersect parameter is true,
/// we only return items if we intersect something
/// If the options.intersect mode is false, we find the nearest item and return
/// the items at the same index as that item
/// @function Chart.Interaction.modes.index
/// @since v2.4.0
/// @param {Chart} chart - the chart we are returning items from
/// @param {Event} e - the event we are find things at
/// @param {InteractionOptions} options - options to use
/// @param {boolean} [useFinalPosition] - use final element position (animation
///   target)
/// @return {InteractionItem[]} - items that are found
List<InteractionItem> _index(
  types.Chart chart,
  Object e,
  Object options, [
  bool? useFinalPosition,
]) {
  final position = getRelativePosition(e, chart);
  // Default axis for index mode is 'x' to match old behaviour
  final axis = _axisOption(options, InteractionAxis.x);
  final includeInvisible = _includeInvisibleOption(options);
  final items = _intersectOption(options)
      ? _getIntersectItems(
          chart,
          position,
          axis,
          useFinalPosition,
          includeInvisible,
        )
      : _getNearestItems(
          chart,
          position,
          axis,
          false,
          useFinalPosition,
          includeInvisible,
        );
  final elements = <InteractionItem>[];

  if (items.isEmpty) {
    return [];
  }

  for (final meta in chart.getSortedVisibleDatasetMetas()) {
    final index = items[0].index;
    final element = _dataAt(meta.data, index);

    // don't count items that are skipped (null data)
    if (element != null && !_skipped(element)) {
      elements.add(
        InteractionItem(
          element: element,
          datasetIndex: meta.index,
          index: index,
        ),
      );
    }
  }

  return elements;
}

/// core.interaction.js:306 `modes.dataset`.
///
/// Returns items in the same dataset. If the options.intersect parameter is
/// true, we only return items if we intersect something
/// If the options.intersect is false, we find the nearest item and return the
/// items in that dataset
/// @function Chart.Interaction.modes.dataset
/// @param {Chart} chart - the chart we are returning items from
/// @param {Event} e - the event we are find things at
/// @param {InteractionOptions} options - options to use
/// @param {boolean} [useFinalPosition] - use final element position (animation
///   target)
/// @return {InteractionItem[]} - items that are found
List<InteractionItem> _dataset(
  types.Chart chart,
  Object e,
  Object options, [
  bool? useFinalPosition,
]) {
  final position = getRelativePosition(e, chart);
  final axis = _axisOption(options, InteractionAxis.xy);
  final includeInvisible = _includeInvisibleOption(options);
  var items = _intersectOption(options)
      ? _getIntersectItems(
          chart,
          position,
          axis,
          useFinalPosition,
          includeInvisible,
        )
      : _getNearestItems(
          chart,
          position,
          axis,
          false,
          useFinalPosition,
          includeInvisible,
        );

  if (items.isNotEmpty) {
    final datasetIndex = items[0].datasetIndex;
    final data = chart.getDatasetMeta(datasetIndex).data;
    items = [];
    for (var i = 0; i < data.length; ++i) {
      items.add(
        InteractionItem(
          element: data[i] as Element,
          datasetIndex: datasetIndex,
          index: i * 1.0,
        ),
      );
    }
  }

  return items;
}

/// core.interaction.js:336 `modes.point`.
///
/// Point mode returns all elements that hit test based on the event position
/// of the event
/// @function Chart.Interaction.modes.intersect
/// @param {Chart} chart - the chart we are returning items from
/// @param {Event} e - the event we are find things at
/// @param {InteractionOptions} options - options to use
/// @param {boolean} [useFinalPosition] - use final element position (animation
///   target)
/// @return {InteractionItem[]} - items that are found
List<InteractionItem> _point(
  types.Chart chart,
  Object e,
  Object options, [
  bool? useFinalPosition,
]) {
  final position = getRelativePosition(e, chart);
  final axis = _axisOption(options, InteractionAxis.xy);
  final includeInvisible = _includeInvisibleOption(options);
  return _getIntersectItems(
    chart,
    position,
    axis,
    useFinalPosition,
    includeInvisible,
  );
}

/// core.interaction.js:352 `modes.nearest`.
///
/// nearest mode returns the element closest to the point
/// @function Chart.Interaction.modes.intersect
/// @param {Chart} chart - the chart we are returning items from
/// @param {Event} e - the event we are find things at
/// @param {InteractionOptions} options - options to use
/// @param {boolean} [useFinalPosition] - use final element position (animation
///   target)
/// @return {InteractionItem[]} - items that are found
List<InteractionItem> _nearest(
  types.Chart chart,
  Object e,
  Object options, [
  bool? useFinalPosition,
]) {
  final position = getRelativePosition(e, chart);
  final axis = _axisOption(options, InteractionAxis.xy);
  final includeInvisible = _includeInvisibleOption(options);
  return _getNearestItems(
    chart,
    position,
    axis,
    _intersectOption(options),
    useFinalPosition,
    includeInvisible,
  );
}

/// core.interaction.js:368 `modes.x`.
///
/// x mode returns the elements that hit-test at the current x coordinate
/// @function Chart.Interaction.modes.x
/// @param {Chart} chart - the chart we are returning items from
/// @param {Event} e - the event we are find things at
/// @param {InteractionOptions} options - options to use
/// @param {boolean} [useFinalPosition] - use final element position (animation
///   target)
/// @return {InteractionItem[]} - items that are found
List<InteractionItem> _x(
  types.Chart chart,
  Object e,
  Object options, [
  bool? useFinalPosition,
]) {
  final position = getRelativePosition(e, chart);
  return _getAxisItems(
    chart,
    position,
    InteractionAxis.x,
    _intersectOption(options),
    useFinalPosition,
  );
}

/// core.interaction.js:382 `modes.y`.
///
/// y mode returns the elements that hit-test at the current y coordinate
/// @function Chart.Interaction.modes.y
/// @param {Chart} chart - the chart we are returning items from
/// @param {Event} e - the event we are find things at
/// @param {InteractionOptions} options - options to use
/// @param {boolean} [useFinalPosition] - use final element position (animation
///   target)
/// @return {InteractionItem[]} - items that are found
List<InteractionItem> _y(
  types.Chart chart,
  Object e,
  Object options, [
  bool? useFinalPosition,
]) {
  final position = getRelativePosition(e, chart);
  return _getAxisItems(
    chart,
    position,
    InteractionAxis.y,
    _intersectOption(options),
    useFinalPosition,
  );
}

/// The axes that an interaction mode uses for the distance from the event
/// position to an item: the value of the option `axis` of `interaction`,
/// `hover` and the tooltip (index.d.ts:752, `'x' | 'y' | 'xy' | 'r'`).
///
/// Upstream holds a keyword and tests it as text: `axis.indexOf('x')` for
/// the distance (core.interaction.js:95), `axis === iScale.axis` for the
/// binary search (:26) and `axis === 'r'` for the radial search (:214).
/// The port holds this enum. The set is closed: the search code of this
/// file reads it, and a mode of a program that needs another rule has its
/// own fields.
// DIVERGES(chartjs): adapt-interaction-axis-enum, an enum, not a keyword.
enum InteractionAxis {
  /// `'x'`: the distance along x only.
  x(usesX: true, usesY: false),

  /// `'y'`: the distance along y only.
  y(usesX: false, usesY: true),

  /// `'xy'`: the distance in the plane.
  xy(usesX: true, usesY: true),

  /// `'r'`: the angle around the center of a radial chart. The distance in
  /// the plane uses no coordinate, as `'r'.indexOf('x')` gives -1.
  r(usesX: false, usesY: false);

  InteractionAxis({required this.usesX, required this.usesY});

  /// `axis.indexOf('x') !== -1` (core.interaction.js:95).
  final bool usesX;

  /// `axis.indexOf('y') !== -1` (core.interaction.js:96).
  final bool usesY;

  /// The axis of [value], the value of an option `axis`, or Dart `null` for
  /// a value that is not an axis: the fallback of `options.axis || 'x'`
  /// then applies (core.interaction.js:272). A keyword of Chart.js is not
  /// an axis: a debug build stops on it.
  static InteractionAxis? of(Object? value) {
    assert(
      value is! String,
      'The option axis of the interaction takes an InteractionAxis, not '
      'the name "$value".',
    );
    return value is InteractionAxis ? value : null;
  }
}

/// An interaction mode: the value of the option `mode` of `interaction`,
/// `hover` and the tooltip. It finds the items at an event position.
///
/// Upstream holds the name of a mode in the option and reads the function
/// `Interaction.modes[mode]` (core.controller.js:821). The port holds the
/// mode itself: the chart calls [itemsAt] of the value of the option, and
/// reads no table. Each mode of upstream is a ready class
/// ([NearestInteractionMode]). A program gives its own mode as a subclass,
/// with no registration:
///
/// ```dart
/// final class FirstItemMode extends InteractionMode {
///   const FirstItemMode();
///
///   @override
///   List<InteractionItem> itemsAt(
///     Chart chart,
///     Object e,
///     Object options, [
///     bool? useFinalPosition,
///   ]) => const NearestInteractionMode()
///       .itemsAt(chart, e, options, useFinalPosition)
///       .take(1)
///       .toList();
/// }
/// ```
// DIVERGES(chartjs): adapt-interaction-mode-objects, a mode object.
@immutable
abstract class InteractionMode {
  /// A mode.
  const InteractionMode();

  /// The items of [chart] at the position of the event [e]: the function of
  /// a mode (index.d.ts:763 `InteractionModeFunction`). [e] is a
  /// `types.ChartEvent` or a `NativeEvent`. [options] are the interaction
  /// options: a view of the options or a plain object. Dart `null` for
  /// [useFinalPosition] stands for an absent argument.
  List<InteractionItem> itemsAt(
    covariant types.Chart chart,
    Object e,
    Object options, [
    bool? useFinalPosition,
  ]);

  /// The mode of [value], the value of an option `mode`, or Dart `null` for
  /// a value that is not a mode: `Interaction.modes[mode]` of a name that
  /// is not a key gives no function (core.controller.js:821-826). A mode
  /// name of Chart.js is not a mode: a debug build stops on it.
  static InteractionMode? of(Object? value) {
    assert(
      value is! String,
      'The option mode takes an InteractionMode, not the name "$value".',
    );
    return value is InteractionMode ? value : null;
  }
}

/// core.interaction.js:269 `modes.index`: the items at the same index as
/// the item nearest to the event position.
final class IndexInteractionMode extends InteractionMode {
  /// The mode.
  const IndexInteractionMode();

  @override
  List<InteractionItem> itemsAt(
    types.Chart chart,
    Object e,
    Object options, [
    bool? useFinalPosition,
  ]) => _index(chart, e, options, useFinalPosition);
}

/// core.interaction.js:306 `modes.dataset`: the items of the dataset of the
/// item nearest to the event position. The chart gives the hover style to
/// the dataset, and the tooltip takes the title of the dataset
/// (core.controller.js:1070, plugin.tooltip.js:370, :389).
final class DatasetInteractionMode extends InteractionMode {
  /// The mode.
  const DatasetInteractionMode();

  @override
  List<InteractionItem> itemsAt(
    types.Chart chart,
    Object e,
    Object options, [
    bool? useFinalPosition,
  ]) => _dataset(chart, e, options, useFinalPosition);
}

/// core.interaction.js:336 `modes.point`: the items that intersect the
/// event position.
final class PointInteractionMode extends InteractionMode {
  /// The mode.
  const PointInteractionMode();

  @override
  List<InteractionItem> itemsAt(
    types.Chart chart,
    Object e,
    Object options, [
    bool? useFinalPosition,
  ]) => _point(chart, e, options, useFinalPosition);
}

/// core.interaction.js:352 `modes.nearest`: the items nearest to the event
/// position.
final class NearestInteractionMode extends InteractionMode {
  /// The mode.
  const NearestInteractionMode();

  @override
  List<InteractionItem> itemsAt(
    types.Chart chart,
    Object e,
    Object options, [
    bool? useFinalPosition,
  ]) => _nearest(chart, e, options, useFinalPosition);
}

/// core.interaction.js:368 `modes.x`: the items at the x position of the
/// event.
final class XInteractionMode extends InteractionMode {
  /// The mode.
  const XInteractionMode();

  @override
  List<InteractionItem> itemsAt(
    types.Chart chart,
    Object e,
    Object options, [
    bool? useFinalPosition,
  ]) => _x(chart, e, options, useFinalPosition);
}

/// core.interaction.js:382 `modes.y`: the items at the y position of the
/// event.
final class YInteractionMode extends InteractionMode {
  /// The mode.
  const YInteractionMode();

  @override
  List<InteractionItem> itemsAt(
    types.Chart chart,
    Object e,
    Object options, [
    bool? useFinalPosition,
  ]) => _y(chart, e, options, useFinalPosition);
}

/// core.interaction.js:252 the default export, `Chart.Interaction`
/// (index.d.ts:803).
///
/// Contains interaction related functions
/// @namespace Chart.Interaction
///
/// Upstream exports an object. Its name `Interaction` is a class name in
/// Dart (Chart.js ADR 0012). Thus the object is a class with a static
/// member. It has no `modes` (core.interaction.js:257): a mode is a class
/// ([InteractionMode]), and no table maps a name to a mode.
// DIVERGES(chartjs): adapt-interaction-mode-objects, no table of modes.
abstract final class Interaction {
  /// core.interaction.js:254 `evaluateInteractionItems`.
  ///
  /// Part of the public API to facilitate developers creating their own
  /// modes. See [_evaluateInteractionItems].
  static void evaluateInteractionItems(
    types.Chart chart,
    InteractionAxis axis,
    Point position,
    InteractionHandler handler, [
    bool? intersect,
  ]) => _evaluateInteractionItems(chart, axis, position, handler, intersect);
}
