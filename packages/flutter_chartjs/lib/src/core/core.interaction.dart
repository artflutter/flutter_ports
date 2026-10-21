// Ported from Chart.js v4.5.1+7169e651 src/core/core.interaction.js (MIT, Chart.js Contributors).

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
/// (Chart.js ADR 0032).
///
/// Upstream imports `_isPointInArea` and `isNullOrUndef` from
/// `helpers/index.js`. The port imports `helpers.canvas.dart` and
/// `helpers.core.dart`, because `helpers/index.dart` also exports
/// `helpers.extras.dart`, which is not a pure layer. Thus this library is a
/// pure layer.
library;

import 'dart:math' as math;

import 'package:flutter_chartjs/src/core/core.element.dart';
import 'package:flutter_chartjs/src/helpers/helpers.canvas.dart'
    show isPointInArea;
import 'package:flutter_chartjs/src/helpers/helpers.collection.dart'
    show lookupByKey, rlookupByKey;
import 'package:flutter_chartjs/src/helpers/helpers.core.dart'
    show isNullOrUndef;
import 'package:flutter_chartjs/src/helpers/helpers.dom.dart'
    show getRelativePosition;
import 'package:flutter_chartjs/src/helpers/helpers.math.dart'
    show angleBetween, getAngleFromPoint;
import 'package:flutter_chartjs/src/js/js_math.dart' show jsSquare;
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_object.dart';
import 'package:flutter_chartjs/src/types/geometric.dart';
import 'package:flutter_chartjs/src/types/index.dart' as types;
import 'package:meta/meta.dart';

/// core.interaction.js:10 `InteractionItem`, the object
/// `{element, datasetIndex, index}` of an interaction mode
/// (index.d.ts:757).
///
/// It implements `types.ActiveElement`, because the chart keeps the items
/// as its active elements (index.d.ts:520-521). TypeScript accepts them by
/// structure. [datasetIndex] and [index] are numbers (Chart.js ADR 0032).
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

/// index.d.ts:763 `InteractionModeFunction`, the type of a function of
/// [Interaction.modes].
///
/// [e] is the event: a `types.ChartEvent`, or a `NativeEvent` of
/// `lib/src/platform/native_event.dart`, as `getRelativePosition` takes
/// (helpers.dom.ts:105). [options] are the `InteractionOptions` of
/// core.interaction.js:9, a plain object (Chart.js ADR 0006). Dart `null`
/// for [useFinalPosition] stands for an absent argument, JS `undefined`.
typedef InteractionModeFunction = List<InteractionItem> Function(
  types.Chart chart,
  Object e,
  Map<String, Object?> options, [
  // The upstream signature has a positional `useFinalPosition`.
  // ignore: avoid_positional_boolean_parameters
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
/// index scale, which is `'x'` or `'y'`. A key that is not a string is its
/// `ToString` ([jsToString]), as the `ToPropertyKey` of the read gives.
double? _positionValue(Point position, Object? axis) =>
    switch (axis is String ? axis : jsToString(axis)) {
      'x' => position.x,
      'y' => position.y,
      _ => null,
    };

/// The JS read `point[key]` of a parsed item (`unknown[]`, index.d.ts:503):
/// the Map read for a Map, else [jsGet]. The Map read gives Dart `null` for
/// an absent key, where JavaScript gives `undefined`. `isNullOrUndef` gives
/// the same result for both.
Object? _parsedValue(Object? point, String key) =>
    point is Map<dynamic, dynamic> ? point[key] : jsGet(point, key);

/// core.interaction.js:22 `binarySearch`.
///
/// Helper function to do binary search when possible
/// @param {object} metaset - the dataset meta
/// @param {string} axis - the axis mode. x|y|xy|r
/// @param {number} value - the value to find
/// @param {boolean} [intersect] - should the element intersect
/// @returns {{lo:number, hi:number}} indices to search data array between
///
/// The indices are list indices, thus `int` values (Chart.js ADR 0032). The
/// search reads [value] as a number: Dart `null` gives 0, the `ToNumber` of
/// JS `null`. `getRange` follows Chart.js ADR 0020, section 9.
///
/// The `slice`, `reverse` and `findIndex` of :35-45 are `lastIndexWhere`
/// and `indexWhere` over `_parsed`, with the same distances and no copy. The
/// test reads `vScale.axis` for each point that it tests, as upstream does.
({int lo, int hi}) _binarySearch(
  types.ChartMeta metaset,
  Object? axis,
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
            ? jsGet(dataset.options, 'spanGaps')
            : null
      : null;

  if (iScale != null &&
      axis == iScale.axis &&
      axis != 'r' &&
      sorted &&
      data.isNotEmpty) {
    // `axis === iScale.axis`. Thus the axis is a string here.
    final key = axis! as String;
    final lookupMethod = iScale.reversePixels ? rlookupByKey : lookupByKey;
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
        final start = lookupMethod(
          data,
          key,
          (value ?? 0) - jsToNumber(range),
        );
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
  Object? axis,
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
      if (!jsTruthy(element['skip'])) {
        handler(element, index, j.toDouble());
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
/// `Math.pow(delta, 2)` is [jsSquare] (Chart.js ADR 0032).
double Function(Point pt1, Point pt2) _getDistanceMetricForAxis(
  Object? axis,
) {
  final (useX, useY) = switch (axis) {
    final String name => (name.contains('x'), name.contains('y')),
    // Array.prototype.indexOf finds an item that is `===` to the string.
    final List<Object?> list => (list.contains('x'), list.contains('y')),
    // A JavaScript TypeError: the value has no `indexOf` method.
    _ => throw TypeError(),
  };

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
  Object? axis,
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
List<InteractionItem> _getNearestRadialItems(
  types.Chart chart,
  Point position,
  Object? axis, [
  bool? useFinalPosition,
]) {
  final items = <InteractionItem>[];

  void evaluationFunc(Element element, double datasetIndex, double index) {
    final props = element.getProps(const [
      'startAngle',
      'endAngle',
    ], useFinalPosition);
    final startAngle = jsToNumber(props['startAngle']);
    final endAngle = jsToNumber(props['endAngle']);
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
  Object? axis,
  bool intersect,
  bool? useFinalPosition,
  bool includeInvisible,
) {
  var items = <InteractionItem>[];
  final distanceMetric = _getDistanceMetricForAxis(axis);
  var minDistance = double.infinity;

  void evaluationFunc(Element element, double datasetIndex, double index) {
    final visual = element as types.VisualElement;
    final inRange = visual.inRange(
      position.x,
      position.y,
      useFinalPosition,
    );
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
  Object? axis,
  bool intersect,
  bool? useFinalPosition,
  bool includeInvisible,
) {
  if (!includeInvisible && !chart.isPointInArea(position)) {
    return [];
  }

  return axis == 'r' && !intersect
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
/// The modes `x` and `y` pass the axis `'x'` or `'y'`. The test
/// `element[rangeMethod] &&` of :234 is a test for `types.VisualElement`,
/// which declares `inXRange` and `inYRange`. `ArcElement` gives false for
/// both (`adapt-arc-axis-range`, differences.md).
List<InteractionItem> _getAxisItems(
  types.Chart chart,
  Point position,
  String axis,
  bool intersect, [
  bool? useFinalPosition,
]) {
  final items = <InteractionItem>[];
  final rangeMethod = axis == 'x' ? 'inXRange' : 'inYRange';
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
/// index.d.ts:752 types `axis` as a string. The functions of this library
/// take the value as it is, as upstream does: a value that is not a string
/// or a `List` throws a `TypeError` where upstream calls `axis.indexOf`
/// (core.interaction.js:95).
Object? _axisOption(Map<String, Object?> options, String fallback) {
  final axis = jsGet(options, 'axis');
  return jsTruthy(axis) ? axis : fallback;
}

/// The option `options.includeInvisible || false` of core.interaction.js:273,
/// :309, :339 and :355. The readers test only its truthiness.
bool _includeInvisibleOption(Map<String, Object?> options) =>
    jsTruthy(jsGet(options, 'includeInvisible'));

/// The option `options.intersect`. The readers test only its truthiness
/// (core.interaction.js:274, :310, :175, :214, :242).
bool _intersectOption(Map<String, Object?> options) =>
    jsTruthy(jsGet(options, 'intersect'));

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
  Map<String, Object?> options, [
  bool? useFinalPosition,
]) {
  final position = getRelativePosition(e, chart);
  // Default axis for index mode is 'x' to match old behaviour
  final axis = _axisOption(options, 'x');
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
    if (element != null && !jsTruthy(element['skip'])) {
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
  Map<String, Object?> options, [
  bool? useFinalPosition,
]) {
  final position = getRelativePosition(e, chart);
  final axis = _axisOption(options, 'xy');
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
          index: i.toDouble(),
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
  Map<String, Object?> options, [
  bool? useFinalPosition,
]) {
  final position = getRelativePosition(e, chart);
  final axis = _axisOption(options, 'xy');
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
  Map<String, Object?> options, [
  bool? useFinalPosition,
]) {
  final position = getRelativePosition(e, chart);
  final axis = _axisOption(options, 'xy');
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
  Map<String, Object?> options, [
  bool? useFinalPosition,
]) {
  final position = getRelativePosition(e, chart);
  return _getAxisItems(
    chart,
    position,
    'x',
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
  Map<String, Object?> options, [
  bool? useFinalPosition,
]) {
  final position = getRelativePosition(e, chart);
  return _getAxisItems(
    chart,
    position,
    'y',
    _intersectOption(options),
    useFinalPosition,
  );
}

/// core.interaction.js:252 the default export, `Chart.Interaction`
/// (index.d.ts:803).
///
/// Contains interaction related functions
/// @namespace Chart.Interaction
///
/// Upstream exports an object. Its name `Interaction` is a class name in
/// Dart (Chart.js ADR 0012). Thus the object is a class with two static
/// members.
abstract final class Interaction {
  /// core.interaction.js:254 `evaluateInteractionItems`.
  ///
  /// Part of the public API to facilitate developers creating their own
  /// modes. See [_evaluateInteractionItems].
  static void evaluateInteractionItems(
    types.Chart chart,
    String axis,
    Point position,
    InteractionHandler handler, [
    // The upstream signature has a positional `intersect`.
    // ignore: avoid_positional_boolean_parameters
    bool? intersect,
  ]) => _evaluateInteractionItems(chart, axis, position, handler, intersect);

  /// core.interaction.js:257 `modes`.
  ///
  /// Helper function for different modes
  ///
  /// A plain object of the six modes, in the upstream key order. The Map can
  /// change, as the JavaScript object can: a program adds a custom mode
  /// under its name.
  static final Map<String, InteractionModeFunction> modes = {
    'index': _index,
    'dataset': _dataset,
    'point': _point,
    'nearest': _nearest,
    'x': _x,
    'y': _y,
  };
}
