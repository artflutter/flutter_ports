// Ported from Chart.js v4.6.1 src/core/core.layouts.js (MIT, Chart.js Contributors).

/// Port of `src/core/core.layouts.js`.
///
/// The layout service places the boxes of a chart: the scales, the legend
/// and the title. The chart is `types.Chart` and each box is a [LayoutItem]
/// of `lib/src/types/layout.dart` (Chart.js ADR 0003).
///
/// The work objects of upstream are JavaScript object literals. The port
/// gives each a private class with the upstream keys as fields: the wrapper
/// of a box (`wrapBoxes`), a stack (`buildStacks`), the parameters of
/// `update`, the edges of a padding and the work area `chartArea` of
/// `update`. A key that upstream adds later, for example `layout.width`,
/// is a field with a start value that the readers treat as upstream treats
/// `undefined`.
///
/// The numbers are `double` (Chart.js ADR 0045). `Math.max` is [jsMax]. The
/// form `a || b` of two numbers is [_or].
///
/// This library is a pure layer. It imports `helpers.config.dart`
/// (`readOption`, the typed read of the options of a box, Chart.js ADR 0054
/// §4), `helpers.core.dart`, `helpers.options.dart`, the JS runtime, the
/// option keys and the type libraries.
library;

import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart'
    show readOption;
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart'
    show each, isObject;
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show toPadding;
import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsSort;
import 'package:flutter_chartjs_port/src/js/js_math.dart' show jsMax;
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart'
    show OptionKey;
import 'package:flutter_chartjs_port/src/types/geometric.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_chartjs_port/src/types/layout.dart';

/// core.layouts.js:8 `STATIC_POSITIONS`.
const List<String> _staticPositions = ['left', 'top', 'right', 'bottom'];

/// `a || b` for the numbers [a] and [b]: [a] when it is truthy, else [b]
/// (Chart.js ADR 0045, "ToBoolean").
double _or(double a, double b) => a != 0 && !a.isNaN ? a : b;

/// core.layouts.js:35-43 the wrapper `{index, box, pos, horizontal, weight,
/// stack, stackWeight}` of a box, with the keys `width` and `height` of
/// `setLayoutDims` (:75-79) and `size` of `updateDims` (:128).
final class _LayoutWrap {
  _LayoutWrap({
    required this.index,
    required this.box,
    required this.pos,
    required this.horizontal,
    required this.weight,
    required this.stack,
    required this.stackWeight,
  });

  /// `index`, the index of the box in `chart.boxes`. A list index.
  final int index;

  /// `box`.
  final LayoutItem box;

  /// `pos`, the [LayoutItem.position] of the box.
  final Object? pos;

  /// `horizontal`, the result of `box.isHorizontal()`.
  final bool horizontal;

  /// `weight`, the [LayoutItem.weight] of the box: the raw value.
  final Object? weight;

  /// `stack && (pos + stack)` (:41): the key of the stack, a `String`, or
  /// the falsy `stack` option.
  final Object? stack;

  /// `stackWeight`, the option with the default 1 (:34).
  final double stackWeight;

  /// `width` (:75, :78). Upstream also stores `false`, and a wrapper that
  /// `setLayoutDims` does not see keeps `undefined`. The one reader tests
  /// the truthiness (`layout.width || chartArea.w`, :188). Thus 0 stands for
  /// both.
  double width = 0;

  /// `height` (:76, :79), as [width].
  double height = 0;

  /// `size` (:128). 0 stands for `undefined`, the start value: the reader
  /// tests the truthiness (:122).
  double size = 0;
}

/// core.layouts.js:55 the stack `{count, placed, weight, size}`, with the
/// key `start` of `placeBoxes` (:237, :251).
///
/// `updateDims` (:126) and `placeBoxes` (:224) read a stack that does not
/// exist as a new object with some of the keys. [size] is 0 for the absent
/// `size` of :224: the reader tests the truthiness (:228, :242).
final class _Stack {
  _Stack({required this.count, required this.placed, required this.weight});

  /// `count`, the count of the boxes in the stack.
  double count;

  /// `placed`, the length that `placeBoxes` has placed.
  double placed;

  /// `weight`, the sum of the `stackWeight` of the boxes.
  double weight;

  /// `size`, the largest size of a box in the stack. The stacks of
  /// `buildStacks` (:55) and of `updateDims` (:126) start at 0.
  double size = 0;

  /// `start`, the position of the stack. Dart `null` stands for JS
  /// `undefined`, the start value that `defined` tests (:229, :243).
  double? start;
}

/// core.layouts.js:395-403 the frozen object `params` of `update`.
///
/// The fields are final. Thus no write can reach the object, as no
/// upstream code writes into it (Chart.js ADR 0021, section 5).
final class _LayoutParams {
  const _LayoutParams({
    required this.outerWidth,
    required this.outerHeight,
    required this.padding,
    required this.availableWidth,
    required this.availableHeight,
    required this.vBoxMaxWidth,
    required this.hBoxMaxHeight,
  });

  /// `outerWidth`.
  final double outerWidth;

  /// `outerHeight`.
  final double outerHeight;

  /// `padding`, the `toPadding` of the `layout.padding` option.
  final ChartArea padding;

  /// `availableWidth`.
  final double availableWidth;

  /// `availableHeight`.
  final double availableHeight;

  /// `vBoxMaxWidth`.
  final double vBoxMaxWidth;

  /// `hBoxMaxHeight`.
  final double hBoxMaxHeight;
}

/// The object `{left, top, right, bottom}` of an edge set: the `maxPadding`
/// of `update` (:404), a margin of `getMargins` (:167) and the margins of
/// the boxes of the position `'chartArea'` (:452).
///
/// The access by name reads and writes the four edges. Upstream reads and
/// writes them as `object[pos]` (:106, :153, :169).
final class _Edges implements TRBL {
  _Edges({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  /// `Object.assign({}, padding)` (:404). The copy also has the `width` and
  /// `height` of the padding. No reader reads them.
  _Edges.copy(TRBL padding)
    : top = padding.top,
      right = padding.right,
      bottom = padding.bottom,
      left = padding.left;

  @override
  double left;

  @override
  double top;

  @override
  double right;

  @override
  double bottom;

  /// `object[pos]` for the edge [pos].
  double operator [](String pos) => switch (pos) {
    'left' => left,
    'top' => top,
    'right' => right,
    _ => bottom,
  };

  /// `object[pos] = value` for the edge [pos].
  void operator []=(String pos, double value) {
    switch (pos) {
      case 'left':
        left = value;
      case 'top':
        top = value;
      case 'right':
        right = value;
      default:
        bottom = value;
    }
  }
}

/// core.layouts.js:406-412 the work area `chartArea` of `update`:
/// `Object.assign({maxPadding, w, h, x, y}, padding)`.
///
/// `updateDims` writes `chartArea[pos]` for the position of each box that
/// does not have the object form (:124, :129). For a static position, this
/// is an edge. For another string, for example `'center'`, upstream writes
/// a new key that no code reads. The port keeps these keys in [_other]. A
/// read of an absent key gives NaN, the `ToNumber` of `undefined`. The
/// copied `width` and `height` of the padding have no field: no code reads
/// them.
final class _LayoutArea {
  _LayoutArea({
    required this.maxPadding,
    required this.w,
    required this.h,
    required this.x,
    required this.y,
    required ChartArea padding,
  }) : top = padding.top,
       right = padding.right,
       bottom = padding.bottom,
       left = padding.left;

  /// `maxPadding`.
  final _Edges maxPadding;

  /// `w`, the width of the area.
  double w;

  /// `h`, the height of the area.
  double h;

  /// `x`, the position of the next box on the x axis.
  double x;

  /// `y`, the position of the next box on the y axis.
  double y;

  /// `top`.
  double top;

  /// `right`.
  double right;

  /// `bottom`.
  double bottom;

  /// `left`.
  double left;

  /// The keys of the positions that are not static (see [_LayoutArea]).
  final Map<Object?, double> _other = {};

  /// `chartArea[pos]`.
  double operator [](Object? pos) => switch (pos) {
    'left' => left,
    'top' => top,
    'right' => right,
    'bottom' => bottom,
    _ => _other[pos] ?? double.nan,
  };

  /// `chartArea[pos] = value`.
  void operator []=(Object? pos, double value) {
    switch (pos) {
      case 'left':
        left = value;
      case 'top':
        top = value;
      case 'right':
        right = value;
      case 'bottom':
        bottom = value;
      default:
        _other[pos] = value;
    }
  }
}

/// core.layouts.js:439-446 the object literal `{left, top, right, bottom,
/// height, width}` of `chart.chartArea`.
final class _ChartArea implements ChartArea {
  const _ChartArea({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.height,
    required this.width,
  });

  @override
  final double left;

  @override
  final double top;

  @override
  final double right;

  @override
  final double bottom;

  @override
  final double height;

  @override
  final double width;
}

/// core.layouts.js:302-307 the layer `{z: 0, draw(chartArea)}` of the
/// default `_layers` of `addBox`. Its [draw] calls `item.draw(chartArea)`.
final class _BoxLayer implements LayoutLayer {
  _BoxLayer(this._item);

  /// `item`, the box of the layer.
  final LayoutItem _item;

  @override
  final double z = 0;

  @override
  void draw(ChartArea chartArea) {
    _item.draw(chartArea);
  }

  @override
  double idx = double.nan;
}

/// core.layouts.js:10 `filterByPosition`.
List<_LayoutWrap> _filterByPosition(List<_LayoutWrap> array, String position) {
  return array.where((v) => v.pos == position).toList();
}

/// core.layouts.js:14 `filterDynamicPositionByAxis`.
List<_LayoutWrap> _filterDynamicPositionByAxis(
  List<_LayoutWrap> array,
  String axis,
) {
  return array
      .where((v) => !_staticPositions.contains(v.pos) && v.box.axis == axis)
      .toList();
}

/// core.layouts.js:18 `sortByWeight`.
///
/// `array.sort` is [jsSort], the stable sort of JavaScript (Chart.js ADR
/// 0045). The comparator compares the raw weights with `===`
/// ([_strictEquals]). Thus two `undefined` weights are equal, and a `null`
/// weight is not equal to 0. The subtraction `v0.weight - v1.weight` is the
/// difference of the two `ToNumber` values ([jsToNumber]). A NaN result
/// keeps the order: [jsSort] reads it as 0, as `Array.prototype.sort` does.
List<_LayoutWrap> _sortByWeight(List<_LayoutWrap> array, [bool? reverse]) {
  return jsSort(array, (a, b) {
    final v0 = reverse ?? false ? b : a;
    final v1 = reverse ?? false ? a : b;
    return _strictEquals(v0.weight, v1.weight)
        ? v0.index - v1.index
        : jsToNumber(v0.weight) - jsToNumber(v1.weight);
  });
}

/// The strict equality `a === b` of JavaScript.
///
/// Numbers compare by value: `0 === -0` is true and `NaN === NaN` is false,
/// as Dart `==` on `num` gives. Strings compare by value. Every other value
/// compares by identity: `true`, `false`, `null` and [undefined] are single
/// instances, and objects compare by reference. A number and a string are
/// never equal.
bool _strictEquals(Object? a, Object? b) {
  if (a is num && b is num) return a == b;
  if (a is String && b is String) return a == b;
  return identical(a, b);
}

/// core.layouts.js:28 `wrapBoxes`.
///
/// The destructuring `{position: pos, options: {stack, stackWeight = 1}}`
/// (:34) reads `box.position`, then `box.options`, then the two options. A
/// destructuring of an absent `options` throws a `TypeError`. [readOption]
/// throws it for Dart `null`. The default 1 replaces only `undefined`. The
/// `stackWeight` of another value is its `ToNumber`: `null` gives 0, which
/// the readers add and divide as upstream adds and divides `null`. The key
/// `pos + stack` joins the two strings: the position is a `String` or an
/// object (a `Map`), whose string is `'[object Object]'` ([jsToString]).
List<_LayoutWrap> _wrapBoxes(List<LayoutItem> boxes) {
  final layoutBoxes = <_LayoutWrap>[];

  for (var i = 0, ilen = boxes.length; i < ilen; ++i) {
    final box = boxes[i];
    final pos = box.position;
    final options = box.options;
    final stack = readOption(options, OptionKey.stack);
    final stackWeightOption = readOption(options, OptionKey.stackWeight);
    final stackWeight = identical(stackWeightOption, undefined)
        ? 1.0
        : jsToNumber(stackWeightOption);
    layoutBoxes.add(
      _LayoutWrap(
        index: i,
        box: box,
        pos: pos,
        horizontal: box.isHorizontal(),
        weight: box.weight,
        stack: jsTruthy(stack) ? jsToString(pos) + jsToString(stack) : stack,
        stackWeight: stackWeight,
      ),
    );
  }
  return layoutBoxes;
}

/// core.layouts.js:48 `buildStacks`.
///
/// A truthy key of a wrapper is the string `pos + stack`. The form
/// `stacks[stack] || (stacks[stack] = {...})` is `??=`, because an object
/// is always truthy.
Map<String, _Stack> _buildStacks(List<_LayoutWrap> layouts) {
  final stacks = <String, _Stack>{};
  for (final wrap in layouts) {
    final _LayoutWrap(:stack, :pos, :stackWeight) = wrap;
    if (!jsTruthy(stack) || !_staticPositions.contains(pos)) {
      continue;
    }
    final stackEntry = stacks[stack! as String] ??= _Stack(
      count: 0,
      placed: 0,
      weight: 0,
    );
    stackEntry.count++;
    stackEntry.weight += stackWeight;
  }
  return stacks;
}

/// core.layouts.js:65 `setLayoutDims`.
///
/// store dimensions used instead of available chartArea in fitBoxes
///
/// `stack && layout.stackWeight / stack.weight` (:73) is 0 for an absent
/// stack: both values are falsy. `fullSize && params.availableWidth` (:75)
/// is 0 for a falsy `fullSize` (see [_LayoutWrap.width]).
Map<String, _Stack> _setLayoutDims(
  List<_LayoutWrap> layouts,
  _LayoutParams params,
) {
  final stacks = _buildStacks(layouts);
  final _LayoutParams(:vBoxMaxWidth, :hBoxMaxHeight) = params;
  for (var i = 0, ilen = layouts.length; i < ilen; ++i) {
    final layout = layouts[i];
    final fullSize = layout.box.fullSize;
    final stack = stacks[layout.stack];
    final factor = stack != null ? layout.stackWeight / stack.weight : 0.0;
    final hasFactor = factor != 0 && !factor.isNaN;
    if (layout.horizontal) {
      layout
        ..width = hasFactor
            ? factor * vBoxMaxWidth
            : fullSize
            ? params.availableWidth
            : 0
        ..height = hBoxMaxHeight;
    } else {
      layout
        ..width = vBoxMaxWidth
        ..height = hasFactor
            ? factor * hBoxMaxHeight
            : fullSize
            ? params.availableHeight
            : 0;
    }
  }
  return stacks;
}

/// core.layouts.js:85 `buildLayoutBoxes`.
///
/// The result object is a record: the callers only read it (Chart.js ADR
/// 0003). `concat` is a new list.
({
  List<_LayoutWrap> fullSize,
  List<_LayoutWrap> leftAndTop,
  List<_LayoutWrap> rightAndBottom,
  List<_LayoutWrap> chartArea,
  List<_LayoutWrap> vertical,
  List<_LayoutWrap> horizontal,
})
_buildLayoutBoxes(List<LayoutItem> boxes) {
  final layoutBoxes = _wrapBoxes(boxes);
  final fullSize = _sortByWeight(
    layoutBoxes.where((wrap) => wrap.box.fullSize).toList(),
    true,
  );
  final left = _sortByWeight(_filterByPosition(layoutBoxes, 'left'), true);
  final right = _sortByWeight(_filterByPosition(layoutBoxes, 'right'));
  final top = _sortByWeight(_filterByPosition(layoutBoxes, 'top'), true);
  final bottom = _sortByWeight(_filterByPosition(layoutBoxes, 'bottom'));
  final centerHorizontal = _filterDynamicPositionByAxis(layoutBoxes, 'x');
  final centerVertical = _filterDynamicPositionByAxis(layoutBoxes, 'y');

  return (
    fullSize: fullSize,
    leftAndTop: [...left, ...top],
    rightAndBottom: [
      ...right,
      ...centerVertical,
      ...bottom,
      ...centerHorizontal,
    ],
    chartArea: _filterByPosition(layoutBoxes, 'chartArea'),
    vertical: [...left, ...right, ...centerVertical],
    horizontal: [...top, ...bottom, ...centerHorizontal],
  );
}

/// core.layouts.js:105 `getCombinedMax`.
double _getCombinedMax(
  _Edges maxPadding,
  _LayoutArea chartArea,
  String a,
  String b,
) {
  return jsMax(maxPadding[a], chartArea[a]) +
      jsMax(maxPadding[b], chartArea[b]);
}

/// core.layouts.js:109 `updateMaxPadding`.
void _updateMaxPadding(_Edges maxPadding, TRBL boxPadding) {
  maxPadding
    ..top = jsMax(maxPadding.top, boxPadding.top)
    ..left = jsMax(maxPadding.left, boxPadding.left)
    ..bottom = jsMax(maxPadding.bottom, boxPadding.bottom)
    ..right = jsMax(maxPadding.right, boxPadding.right);
}

/// core.layouts.js:116 `updateDims`.
///
/// `box.getPadding` (:132) is the test for [LayoutItemPadding]. The result
/// object is a record (Chart.js ADR 0003).
({bool same, bool other}) _updateDims(
  _LayoutArea chartArea,
  _LayoutParams params,
  _LayoutWrap layout,
  Map<String, _Stack> stacks,
) {
  final _LayoutWrap(:pos, :box) = layout;
  final maxPadding = chartArea.maxPadding;

  // dynamically placed boxes size is not considered
  if (!isObject(pos)) {
    if (layout.size != 0 && !layout.size.isNaN) {
      // this layout was already counted for, lets first reduce old size
      chartArea[pos] -= layout.size;
    }
    final stack =
        stacks[layout.stack] ?? _Stack(count: 1, placed: 0, weight: 0);
    stack.size = jsMax(
      stack.size,
      layout.horizontal ? box.height : box.width,
    );
    layout.size = stack.size / stack.count;
    chartArea[pos] += layout.size;
  }

  if (box is LayoutItemPadding) {
    _updateMaxPadding(maxPadding, box.getPadding());
  }

  final newWidth = jsMax(
    0,
    params.outerWidth - _getCombinedMax(maxPadding, chartArea, 'left', 'right'),
  );
  final newHeight = jsMax(
    0,
    params.outerHeight -
        _getCombinedMax(maxPadding, chartArea, 'top', 'bottom'),
  );
  final widthChanged = newWidth != chartArea.w;
  final heightChanged = newHeight != chartArea.h;
  chartArea
    ..w = newWidth
    ..h = newHeight;

  // return booleans on the changes per direction
  return layout.horizontal
      ? (same: widthChanged, other: heightChanged)
      : (same: heightChanged, other: widthChanged);
}

/// core.layouts.js:149 `handleMaxPadding`.
void _handleMaxPadding(_LayoutArea chartArea) {
  final maxPadding = chartArea.maxPadding;

  double updatePos(String pos) {
    final change = jsMax(maxPadding[pos] - chartArea[pos], 0);
    chartArea[pos] += change;
    return change;
  }

  chartArea
    ..y += updatePos('top')
    ..x += updatePos('left');
  updatePos('right');
  updatePos('bottom');
}

/// core.layouts.js:163 `getMargins`.
TRBL _getMargins(bool horizontal, _LayoutArea chartArea) {
  final maxPadding = chartArea.maxPadding;

  _Edges marginForPositions(List<String> positions) {
    final margin = _Edges(left: 0, top: 0, right: 0, bottom: 0);
    for (final pos in positions) {
      margin[pos] = jsMax(chartArea[pos], maxPadding[pos]);
    }
    return margin;
  }

  return horizontal
      ? marginForPositions(const ['left', 'right'])
      : marginForPositions(const ['top', 'bottom']);
}

/// core.layouts.js:179 `fitBoxes`.
///
/// `refit |= same && refitBoxes.length` (:196) is a bitwise OR of integers:
/// `false` gives 0. The result `refit && fitBoxes(...) || changed` (:206)
/// is a truth value for the caller (:423). `changed` starts `undefined`,
/// which is falsy. Thus it is a `bool` that starts false.
bool _fitBoxes(
  List<_LayoutWrap> boxes,
  _LayoutArea chartArea,
  _LayoutParams params,
  Map<String, _Stack> stacks,
) {
  final refitBoxes = <_LayoutWrap>[];
  var refit = 0;
  var changed = false;

  for (var i = 0, ilen = boxes.length; i < ilen; ++i) {
    final layout = boxes[i];
    final box = layout.box
      ..update(
        _or(layout.width, chartArea.w),
        _or(layout.height, chartArea.h),
        _getMargins(layout.horizontal, chartArea),
      );
    final (:same, :other) = _updateDims(chartArea, params, layout, stacks);

    // Dimensions changed and there were non full width boxes before this
    // -> we have to refit those
    refit |= same ? refitBoxes.length : 0;

    // Chart area changed in the opposite direction
    changed = changed || other;

    if (!box.fullSize) {
      // fullSize boxes don't need to be re-fitted in any case
      refitBoxes.add(layout);
    }
  }

  return refit != 0 && _fitBoxes(refitBoxes, chartArea, params, stacks) ||
      changed;
}

/// core.layouts.js:209 `setBoxDims`.
void _setBoxDims(
  LayoutItem box,
  double left,
  double top,
  double width,
  double height,
) {
  box
    ..top = top
    ..left = left
    ..right = left + width
    ..bottom = top + height
    ..width = width
    ..height = height;
}

/// core.layouts.js:218 `placeBoxes`.
///
/// `defined(stack.start)` (:229, :243) is a test for Dart `null`, which
/// stands for `undefined` ([_Stack.start]).
void _placeBoxes(
  List<_LayoutWrap> boxes,
  _LayoutArea chartArea,
  _LayoutParams params,
  Map<String, _Stack> stacks,
) {
  final userPadding = params.padding;
  var x = chartArea.x;
  var y = chartArea.y;

  for (final layout in boxes) {
    final box = layout.box;
    final stack =
        stacks[layout.stack] ?? _Stack(count: 1, placed: 0, weight: 1);
    final weight = _or(layout.stackWeight / stack.weight, 1);
    if (layout.horizontal) {
      final width = chartArea.w * weight;
      final height = _or(stack.size, box.height);
      final start = stack.start;
      if (start != null) {
        y = start;
      }
      if (box.fullSize) {
        _setBoxDims(
          box,
          userPadding.left,
          y,
          params.outerWidth - userPadding.right - userPadding.left,
          height,
        );
      } else {
        _setBoxDims(box, chartArea.left + stack.placed, y, width, height);
      }
      stack
        ..start = y
        ..placed += width;
      y = box.bottom;
    } else {
      final height = chartArea.h * weight;
      final width = _or(stack.size, box.width);
      final start = stack.start;
      if (start != null) {
        x = start;
      }
      if (box.fullSize) {
        _setBoxDims(
          box,
          x,
          userPadding.top,
          width,
          params.outerHeight - userPadding.bottom - userPadding.top,
        );
      } else {
        _setBoxDims(box, x, chartArea.top + stack.placed, width, height);
      }
      stack
        ..start = x
        ..placed += height;
      x = box.right;
    }
  }

  chartArea
    ..x = x
    ..y = y;
}

/// core.layouts.js:291 `addBox`.
///
/// Register a box to a chart.
/// A box is simply a reference to an object that requires layout. eg.
/// Scales, Legend, Title.
/// @param {Chart} chart - the chart to use
/// @param {LayoutItem} item - the item to add to be laid out
///
/// `chart.boxes` is always an array (`types.Chart.boxes`). Thus the test
/// `!chart.boxes` of :292-294 has no Dart form. The form `value || d`
/// keeps a truthy value ([jsTruthy]). `item._layers || function() {...}`
/// keeps a function that the box has.
void _addBox(types.Chart chart, LayoutItem item) {
  // initialize item with default values
  item
    // `item.fullSize || false` (:297) is `item.fullSize` for a bool.
    ..fullSize = item.fullSize
    ..position = jsTruthy(item.position) ? item.position : 'top'
    // `item.weight || 0` (:299) keeps a truthy value.
    ..weight = jsTruthy(item.weight) ? item.weight : 0.0
    // @ts-ignore
    ..layers = item.layers ?? () => [_BoxLayer(item)];

  chart.boxes.add(item);
}

/// core.layouts.js:318 `removeBox`.
///
/// Remove a layoutItem from a chart
/// @param {Chart} chart - the chart to remove the box from
/// @param {LayoutItem} layoutItem - the item to remove from the layout
///
/// `chart.boxes` is always an array (see [_addBox]). `indexOf` compares
/// with `==`, which is identity for a box, as `===` is.
///
/// Dart null stands for JS `undefined`: `indexOf` gives -1, and nothing
/// changes (core.layouts.js:318-323). A `List<LayoutItem>` does not take
/// null, so the index of null is -1 without the call.
void _removeBox(types.Chart chart, LayoutItem? layoutItem) {
  final index = layoutItem == null ? -1 : chart.boxes.indexOf(layoutItem);
  if (index != -1) {
    chart.boxes.removeAt(index);
  }
}

/// core.layouts.js:331 `configure`.
///
/// Sets (or updates) options on the given `item`.
/// @param {Chart} chart - the chart in which the item lives (or will be
///   added to)
/// @param {LayoutItem} item - the item to configure with the given options
/// @param {object} options - the new item options.
///
/// [LayoutItem.fullSize] is a `bool` (layout.d.ts:17). Thus `configure`
/// stores the truthiness of the `fullSize` option. The readers of
/// `core.layouts` test only its truthiness. [LayoutItem.weight] is an
/// `Object?`: `configure` stores the `weight` option as it is, as upstream
/// does, because `sortByWeight` compares the raw values with `===`.
void _configure(
  types.Chart chart,
  LayoutItem item,
  Map<String, Object?> options,
) {
  item
    // DIVERGES(chartjs): adapt-layout-configure-types, a bool, not the value.
    ..fullSize = jsTruthy(readOption(options, OptionKey.fullSize))
    ..position = readOption(options, OptionKey.position)
    ..weight = readOption(options, OptionKey.weight);
}

/// core.layouts.js:345 `update`.
///
/// Fits boxes of the given chart into the given size by having each box
/// measure itself
/// then running a fitting algorithm
/// @param {Chart} chart - the chart
/// @param {number} width - the width to fit into
/// @param {number} height - the height to fit into
/// @param {number} minPadding - minimum padding required for each side of
///   chart area
///
/// Dart `null` for [chart] stands for a falsy chart (:346). [minPadding] is
/// a number or a padding object for `toPadding`. The `Object.freeze` of
/// :395 is [jsObjectFreeze]. `typeof box.beforeLayout === 'function'`
/// (:360) is the test for [LayoutItemBeforeLayout]. `Object.assign(box,
/// chart.chartArea)` (:451) writes the six keys of the chart area in the
/// order of the literal of :439.
void _update(
  types.Chart? chart,
  double width,
  double height, [
  Object? minPadding = undefined,
]) {
  if (chart == null) {
    return;
  }

  final padding = toPadding(
    readOption(readOption(chart.options, OptionKey.layout), OptionKey.padding),
  );
  final availableWidth = jsMax(width - padding.width, 0);
  final availableHeight = jsMax(height - padding.height, 0);
  final boxes = _buildLayoutBoxes(chart.boxes);
  final verticalBoxes = boxes.vertical;
  final horizontalBoxes = boxes.horizontal;

  // Before any changes are made, notify boxes that an update is about to
  // being
  // This is used to clear any cached data (e.g. scale limits)
  each(chart.boxes, (Object? box) {
    if (box is LayoutItemBeforeLayout) {
      box.beforeLayout();
    }
  });

  // Essentially we now have any number of boxes on each of the 4 sides.
  // Our canvas looks like the following.
  // The areas L1 and L2 are the left axes. R1 is the right axis, T1 is the
  // top axis and
  // B1 is the bottom axis
  // There are also 4 quadrant-like locations (left to right instead of
  // clockwise) reserved for chart overlays
  // These locations are single-box locations only, when trying to register
  // a chartArea location that is already taken,
  // an error will be thrown.
  //
  // |----------------------------------------------------|
  // |                  T1 (Full Width)                   |
  // |----------------------------------------------------|
  // |    |    |                 T2                  |    |
  // |    |----|-------------------------------------|----|
  // |    |    | C1 |                           | C2 |    |
  // |    |    |----|                           |----|    |
  // |    |    |                                     |    |
  // | L1 | L2 |           ChartArea (C0)            | R1 |
  // |    |    |                                     |    |
  // |    |    |----|                           |----|    |
  // |    |    | C3 |                           | C4 |    |
  // |    |----|-------------------------------------|----|
  // |    |    |                 B1                  |    |
  // |----------------------------------------------------|
  // |                  B2 (Full Width)                   |
  // |----------------------------------------------------|
  //

  final visibleVerticalBoxCount = _or(
    verticalBoxes.fold<double>(0, (total, wrap) {
      final options = wrap.box.options;
      return options != null && readOption(options, OptionKey.display) == false
          ? total
          : total + 1;
    }),
    1,
  );

  final params = jsObjectFreeze(
    _LayoutParams(
      outerWidth: width,
      outerHeight: height,
      padding: padding,
      availableWidth: availableWidth,
      availableHeight: availableHeight,
      vBoxMaxWidth: availableWidth / 2 / visibleVerticalBoxCount,
      hBoxMaxHeight: availableHeight / 2,
    ),
  );
  final maxPadding = _Edges.copy(padding);
  _updateMaxPadding(maxPadding, toPadding(minPadding));
  final chartArea = _LayoutArea(
    maxPadding: maxPadding,
    w: availableWidth,
    h: availableHeight,
    x: padding.left,
    y: padding.top,
    padding: padding,
  );

  final stacks = _setLayoutDims([...verticalBoxes, ...horizontalBoxes], params);

  // First fit the fullSize boxes, to reduce probability of re-fitting.
  _fitBoxes(boxes.fullSize, chartArea, params, stacks);

  // Then fit vertical boxes
  _fitBoxes(verticalBoxes, chartArea, params, stacks);

  // Then fit horizontal boxes
  if (_fitBoxes(horizontalBoxes, chartArea, params, stacks)) {
    // if the area changed, re-fit vertical boxes
    _fitBoxes(verticalBoxes, chartArea, params, stacks);
  }

  _handleMaxPadding(chartArea);

  // Finally place the boxes to correct coordinates
  _placeBoxes(boxes.leftAndTop, chartArea, params, stacks);

  // Move to opposite side of chart
  chartArea
    ..x += chartArea.w
    ..y += chartArea.h;

  _placeBoxes(boxes.rightAndBottom, chartArea, params, stacks);

  chart.chartArea = _ChartArea(
    left: chartArea.left,
    top: chartArea.top,
    right: chartArea.left + chartArea.w,
    bottom: chartArea.top + chartArea.h,
    height: chartArea.h,
    width: chartArea.w,
  );

  // Finally update boxes in chartArea (radial scale for example)
  each(boxes.chartArea, (_LayoutWrap layout) {
    final box = layout.box;
    final area = chart.chartArea!;
    box
      ..left = area.left
      ..top = area.top
      ..right = area.right
      ..bottom = area.bottom
      ..height = area.height
      ..width = area.width
      ..update(
        chartArea.w,
        chartArea.h,
        _Edges(left: 0, top: 0, right: 0, bottom: 0),
      );
  });
}

/// core.layouts.js:283 the default export, `Chart.layouts` (index.d.ts:818).
///
/// The layout service is very self explanatory. It's responsible for the
/// layout within a chart.
/// Scales, Legends and Plugins all rely on the layout service and can
/// easily register to be placed anywhere they need
/// It is this service's responsibility of carrying out that layout.
///
/// Upstream exports an object of four functions, and no code changes it.
/// index.d.ts:818 declares it as an object type. Ported code only reads it.
/// Thus it is a record of the four functions (Chart.js ADR 0003).
/// `layouts.addBox(chart, item)` calls a function as upstream does.
const ({
  void Function(types.Chart chart, LayoutItem item) addBox,
  void Function(types.Chart chart, LayoutItem? layoutItem) removeBox,
  void Function(
    types.Chart chart,
    LayoutItem item,
    Map<String, Object?> options,
  )
  configure,
  void Function(
    types.Chart? chart,
    double width,
    double height, [
    Object? minPadding,
  ])
  update,
})
layouts = (
  addBox: _addBox,
  removeBox: _removeBox,
  configure: _configure,
  update: _update,
);
