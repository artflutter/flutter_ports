// Ported from Chart.js v4.6.1 src/plugins/plugin.tooltip.js (MIT, Chart.js Contributors).

/// Port of `src/plugins/plugin.tooltip.js` (Chart.js ADR 0039).
///
/// [Tooltip] is the tooltip model, the element that the plugin makes,
/// animates and keeps in `chart.tooltip`. [tooltip] is the plugin object,
/// the default export of the upstream file and `Tooltip` of
/// `src/plugins/index.js:7` (Chart.js ADR 0038, section 1). It is a typed
/// `Plugin` (Chart.js ADR 0054 §12) with the upstream keys in the upstream
/// order: `id`, `_element`, `positioners`, `afterInit`, `beforeUpdate`,
/// `reset`, `afterDraw`, `afterEvent`, `defaults`, `defaultRoutes`,
/// `descriptors` and `additionalOptionScopes`.
///
/// Each hook is a private function of the hook type `(types.Chart chart,
/// args, AnyObject options)` (Chart.js ADR 0054 §12, in place of the
/// upstream parameter counts of Chart.js ADR 0038, section 3): `afterEvent`
/// takes the typed [EventHookArgs], the other hooks read no args and take
/// any args object. The draw hooks of the tooltip get a
/// [TooltipDrawHookArgs]. `chart.tooltip` is a field of `types.Chart` with
/// the type `types.TooltipModel?`: Dart `null` stands for JS `undefined`.
/// The hooks cast it to [Tooltip], the class of this library (Chart.js ADR
/// 0039, section 1).
///
/// The tooltip reads its options through the facade [TooltipOptions] of
/// `plugin_options.dart` (Chart.js ADR 0054 §4), in the upstream order of
/// the reads. The tooltip items, the body items, the label colors, the label
/// point styles and the positions of the built-in positioners are typed
/// classes with the upstream keys in the upstream order ([TooltipItem],
/// [TooltipBodyItem], [TooltipLabelStyle], [TooltipLabelPointStyle] and
/// [TooltipPosition], Chart.js ADR 0054 §12). Each has the face, so a user
/// callback reads them by name. A value of user code in their place (the
/// result of a user callback or positioner, an item of a spec) is read by
/// name. The positioners are function values in one Map (Chart.js ADR 0039,
/// section 4).
///
/// Not a pure layer: it imports `core.animations`.
library;

import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/core/core.animations.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/elements/element_options.dart'
    show PointOptions;
import 'package:flutter_chartjs_port/src/helpers/helpers.canvas.dart'
    show addRoundedRectPath, drawPoint;
import 'package:flutter_chartjs_port/src/helpers/helpers.collection.dart'
    show arrayUnique;
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart'
    show OptionResolver, OptionView;
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart'
    show each, elementsEqual, isArray, isNullOrUndef, isObject, noop;
import 'package:flutter_chartjs_port/src/helpers/helpers.math.dart'
    show distanceBetweenPoints, limitValue;
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show createContext, toFont, toPadding, toTRBLCorners;
import 'package:flutter_chartjs_port/src/helpers/helpers.rtl.dart'
    show RTLAdapter, getRtlAdapter, overrideTextDirection, restoreTextDirection;
import 'package:flutter_chartjs_port/src/js/js_array.dart'
    show jsObjectKeys, jsSort;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart';
import 'package:flutter_chartjs_port/src/js/js_math.dart' show jsMax, jsMin;
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart'
    show jsGet, jsGetIndex, jsObjectFreeze;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/js/js_webidl.dart'
    show canvasKeyword, canvasLineDash, canvasNumber, canvasStyle;
import 'package:flutter_chartjs_port/src/options/opt.dart'
    show OptFunction, optNull;
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart';
import 'package:flutter_chartjs_port/src/options/scopes.g.dart'
    show
        AnimationOptionsScope,
        AnimationsSpecScope,
        DescriptorsScope,
        FontSpecScope,
        TooltipCallbacksScope,
        TooltipOptionsScope;
import 'package:flutter_chartjs_port/src/options/typed_record.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin_options.dart'
    show TooltipOptions, optionOf;
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/geometric.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_chartjs_port/src/types/plugin.dart'
    show EventHookArgs, Plugin, TooltipDrawHookArgs;
import 'package:meta/meta.dart';

/// plugin.tooltip.js:17 `const positioners`.
///
/// `Tooltip.positioners`, the static `positioners` of [Tooltip.jsClass] and
/// the key `positioners` of the plugin Map are this Map (Chart.js ADR 0039,
/// section 4). The methods of [Tooltip] read it, as upstream reads the
/// module constant (:651, :1012, :1218). A user adds a positioner with a
/// write into it.
final AnyObject _positioners = <String, Object?>{
  'average': _average,
  'nearest': _nearest,
};

/// The element of the active item [item]: `items[i].element`.
///
/// A `types.ActiveElement` gives its member, with Dart `null` as JS
/// `undefined`. Another value gives the read by name ([jsGet]): a plain item
/// without an `element` gives [undefined] (`plugin.tooltip.tests.js:1152`).
Object? _elementOf(Object? item) => switch (item) {
  final types.ActiveElement active => active.element ?? undefined,
  _ => jsGet(item, 'element'),
};

/// The JS read `position.x` of a position or an event position [value]: a
/// [TooltipPosition] and a [Point] (a chart event) give their member, with
/// Dart `null` as JS `null` for a [Point]. Another value (the result of a
/// positioner of user code) gives the read by name. `undefined` and JS
/// `null` throw the [TypeError] of the read, as upstream.
Object? _readX(Object? value) => switch (value) {
  final TooltipPosition position => position.x,
  final Point point => point.x,
  _ => jsGet(value, 'x'),
};

/// The JS read `position.y`, as [_readX].
Object? _readY(Object? value) => switch (value) {
  final TooltipPosition position => position.y,
  final Point point => point.y,
  _ => jsGet(value, 'y'),
};

/// The JS read `items.length` of the active items [items] of a positioner:
/// the length of a List, else the read by name of a value of user code.
Object? _itemsLength(Object? items) =>
    items is List ? items.length.toDouble() : jsGet(items, 'length');

/// plugin.tooltip.js:21 `average(items)`: the average position of the
/// elements shown. Average mode places the tooltip at the average position
/// of the elements shown.
///
/// `new Set()` collects the x values: each value goes into a list through
/// the add step of `Set.prototype.add` (-0 becomes +0), and [arrayUnique]
/// removes the copies with SameValueZero (Chart.js ADR 0039, section 4).
/// The sum keeps the insertion order. The elements cast to [Element] at
/// `hasValue` and `tooltipPosition` (Chart.js ADR 0038, section 6).
Object? _average(Object? items) {
  if (!jsTruthy(_itemsLength(items))) {
    return false;
  }

  final xSet = <double>[];
  var y = 0.0;
  var count = 0;

  final len = jsToNumber(_itemsLength(items));
  for (var i = 0.0; i < len; ++i) {
    final el = _elementOf(jsGetIndex(items, i));
    if (jsTruthy(el) && (el! as Element).hasValue()) {
      final pos = (el as Element).tooltipPosition();
      // `Set.prototype.add` stores +0 for -0.
      xSet.add(pos.x == 0 ? 0.0 : pos.x);
      y += pos.y;
      ++count;
    }
  }

  // No visible items where found, return false so we don't have to divide
  // by 0 which reduces in NaN
  final unique = arrayUnique(xSet);
  if (count == 0 || unique.isEmpty) {
    return false;
  }

  final xAverage = unique.reduce((a, b) => a + b) / unique.length;

  return TooltipPosition()
    ..x = xAverage
    ..y = y / count;
}

/// plugin.tooltip.js:57 `nearest(items, eventPosition)`: the tooltip
/// position nearest of the item nearest to the event position.
///
/// `x` and `y` start as the raw `eventPosition.x` and `.y` ([_readX]).
/// `distanceBetweenPoints` gets their `ToNumber`, the conversion of the
/// upstream subtraction (Chart.js ADR 0039, section 4).
Object? _nearest(Object? items, Object? eventPosition) {
  if (!jsTruthy(_itemsLength(items))) {
    return false;
  }

  var x = _readX(eventPosition);
  var y = _readY(eventPosition);
  var minDistance = double.infinity;
  Element? nearestElement;

  final len = jsToNumber(_itemsLength(items));
  for (var i = 0.0; i < len; ++i) {
    final el = _elementOf(jsGetIndex(items, i));
    if (jsTruthy(el) && (el! as Element).hasValue()) {
      final center = (el as types.VisualElement).getCenterPoint();
      final d = distanceBetweenPoints(
        _NumberPoint(
          jsToNumber(_readX(eventPosition)),
          jsToNumber(_readY(eventPosition)),
        ),
        center,
      );

      if (d < minDistance) {
        minDistance = d;
        nearestElement = el as Element;
      }
    }
  }

  if (nearestElement != null) {
    final tp = nearestElement.tooltipPosition();
    x = tp.x;
    y = tp.y;
  }

  return TooltipPosition()
    ..x = x
    ..y = y;
}

/// The point that `distanceBetweenPoints` reads in [_nearest]: the
/// `ToNumber` of each coordinate of the event position.
final class _NumberPoint implements Point {
  const _NumberPoint(this.x, this.y);

  @override
  final double x;

  @override
  final double y;
}

/// plugin.tooltip.js:94 `pushOrConcat(base, toPush)`. Helper to push or
/// concat based on if the 2nd parameter is an array or not.
List<Object?> _pushOrConcat(List<Object?> base, Object? toPush) {
  if (jsTruthy(toPush)) {
    if (isArray(toPush)) {
      // base = base.concat(toPush);
      base.addAll(toPush! as List<Object?>);
    } else {
      base.add(toPush);
    }
  }

  return base;
}

/// plugin.tooltip.js:113 `splitNewlines(str)`.
///
/// Returns array of strings split by newline
/// @param {*} str - The value to split by newline.
/// @returns {string|string[]} value if newline present - Returned from
/// String split() method
Object? _splitNewlines(Object? str) {
  if (str is String && str.contains('\n')) {
    return str.split('\n');
  }
  return str;
}

/// plugin.tooltip.js:127 `createTooltipItem(chart, item)`.
///
/// Private helper to create a tooltip item model
/// @param {Chart} chart
/// @param {ActiveElement} item - {element, index, datasetIndex} to create
/// the tooltip item for
/// @return new tooltip item
///
/// The item is a [TooltipItem] in the upstream key order. It keeps the raw
/// `label` of `getLabelAndValue` (Chart.js ADR 0028, Open 2). A meta without
/// a controller throws the [TypeError] of the null check, as the call on JS
/// `null` throws. `raw` is a read of the data of the user, by name.
TooltipItem _createTooltipItem(types.Chart chart, types.ActiveElement item) {
  final types.ActiveElement(:element, :datasetIndex, :index) = item;
  final controller = chart.getDatasetMeta(datasetIndex).controller!;
  final (:label, :value) = controller.getLabelAndValue(index);

  return TooltipItem()
    ..chart = chart
    ..label = label
    ..parsed = controller.getParsed(index)
    ..raw = jsGetIndex(
      jsGet(jsGetIndex(jsGet(chart.data, 'datasets'), datasetIndex), 'data'),
      index,
    )
    ..formattedValue = value
    ..dataset = controller.getDataset()
    ..dataIndex = index
    ..datasetIndex = datasetIndex
    ..element = element ?? undefined;
}

/// The JS read `list.length` of a line list [list], as a number: the length
/// of a List, else the read by name of a value of user code.
double _lengthOf(Object? list) =>
    list is List ? list.length.toDouble() : jsToNumber(jsGet(list, 'length'));

/// plugin.tooltip.js:148 `getTooltipSize(tooltip, options)`: the size of
/// the tooltip, a record of the object `{width, height}`.
///
/// A numeric option goes through `ToNumber` ([jsToNumber]) before its
/// arithmetic, and `Math.max` is [jsMax] (Chart.js ADR 0039, section 7).
/// `measureText` gets the `ToString` of a line that is not a string.
({double width, double height}) _getTooltipSize(
  Tooltip tooltip,
  TooltipOptions options,
) {
  final ctx = tooltip.chart.ctx!;
  final Tooltip(:body, :footer, :title) = tooltip;
  final boxWidth = jsToNumber(options.boxWidth);
  final boxHeight = jsToNumber(options.boxHeight);
  final bodyFont = toFont(options.bodyFont);
  final titleFont = toFont(options.titleFont);
  final footerFont = toFont(options.footerFont);
  final titleLineCount = title!.length;
  final footerLineCount = footer!.length;
  final bodyLineItemCount = body!.length;

  final padding = toPadding(options.padding);
  var height = padding.height;
  var width = 0.0;

  // Count of all lines in the body
  var combinedBodyLength = body.fold<double>(
    0,
    (count, bodyItem) =>
        count +
        _lengthOf(_BodyItem(bodyItem).before) +
        _lengthOf(_BodyItem(bodyItem).lines) +
        _lengthOf(_BodyItem(bodyItem).after),
  );
  combinedBodyLength += tooltip.beforeBody!.length + tooltip.afterBody!.length;

  if (titleLineCount != 0) {
    height +=
        titleLineCount * titleFont.lineHeight +
        (titleLineCount - 1) * jsToNumber(options.titleSpacing) +
        jsToNumber(options.titleMarginBottom);
  }
  if (jsTruthy(combinedBodyLength)) {
    // Body lines may include some extra height depending on boxHeight
    final bodyLineHeight = jsTruthy(options.displayColors)
        ? jsMax(boxHeight, bodyFont.lineHeight)
        : bodyFont.lineHeight;
    height +=
        bodyLineItemCount * bodyLineHeight +
        (combinedBodyLength - bodyLineItemCount) * bodyFont.lineHeight +
        (combinedBodyLength - 1) * jsToNumber(options.bodySpacing);
  }
  if (footerLineCount != 0) {
    height +=
        jsToNumber(options.footerMarginTop) +
        footerLineCount * footerFont.lineHeight +
        (footerLineCount - 1) * jsToNumber(options.footerSpacing);
  }

  // Title width
  var widthPadding = 0.0;
  void maxLineWidth(Object? line) {
    width = jsMax(
      width,
      ctx.measureText(jsToString(line)).width + widthPadding,
    );
  }

  ctx
    ..save()
    ..font = titleFont.string;
  each(tooltip.title, maxLineWidth);

  // Body width
  ctx.font = bodyFont.string;
  each([...tooltip.beforeBody!, ...tooltip.afterBody!], maxLineWidth);

  // Body lines may include some extra width due to the color box
  widthPadding = jsTruthy(options.displayColors)
      ? (boxWidth + 2 + jsToNumber(options.boxPadding))
      : 0;
  each(body, (Object? bodyItem) {
    each(_BodyItem(bodyItem).before, maxLineWidth);
    each(_BodyItem(bodyItem).lines, maxLineWidth);
    each(_BodyItem(bodyItem).after, maxLineWidth);
  });

  // Reset back to 0
  widthPadding = 0;

  // Footer width
  ctx.font = footerFont.string;
  each(tooltip.footer, maxLineWidth);

  ctx.restore();

  // Add padding
  width += padding.width;

  return (width: width, height: height);
}

/// plugin.tooltip.js:661 `Object.assign({}, position, size)`: the keys that
/// the alignment helpers read (Chart.js ADR 0039, section 5, Chart.js ADR
/// 0003).
///
/// `x` and `y` are the `ToNumber` of the position coordinates, which each
/// upstream operator applies. `xAlign` and `yAlign` are the raw values of
/// the position.
typedef _PositionAndSize = ({
  double x,
  double y,
  double width,
  double height,
  Object? xAlign,
  Object? yAlign,
});

/// `Object.assign({}, position, size)` (plugin.tooltip.js:661, :1017).
///
/// `Object.assign` ignores `undefined`, JS `null` and a primitive source:
/// then `x`, `y`, `xAlign` and `yAlign` are `undefined` (NaN for the
/// coordinates). A [Point] gives its coordinates. Another object gives the
/// reads by name. The size gives `width` and `height`, after the position,
/// so it wins.
_PositionAndSize _positionAndSize(
  Object? position,
  ({double width, double height}) size,
) {
  final copies = position != null && position is! Undefined;
  return (
    x: copies ? jsToNumber(_readX(position)) : double.nan,
    y: copies ? jsToNumber(_readY(position)) : double.nan,
    width: size.width,
    height: size.height,
    xAlign: copies ? _readAlign(position, OptionKey.xAlign) : undefined,
    yAlign: copies ? _readAlign(position, OptionKey.yAlign) : undefined,
  );
}

/// The JS read `position.xAlign` or `position.yAlign` ([key]) of a
/// position: a [TooltipPosition] gives its field, a [Point] has neither
/// key, and another value (the result of a positioner of user code) gives
/// the read by name.
Object? _readAlign(Object? position, OptionKey key) => switch (position) {
  final TooltipPosition typed =>
    key == OptionKey.xAlign ? typed.xAlign : typed.yAlign,
  Point() => undefined,
  _ => jsGet(position, key.jsName),
};

/// plugin.tooltip.js:223 `determineYAlign(chart, size)`.
String _determineYAlign(types.Chart chart, _PositionAndSize size) {
  final (:y, :height, x: _, width: _, xAlign: _, yAlign: _) = size;

  if (y < height / 2) {
    return 'top';
  } else if (y > (chart.height - height / 2)) {
    return 'bottom';
  }
  return 'center';
}

/// plugin.tooltip.js:234 `doesNotFitWithAlign(xAlign, chart, options,
/// size)`. Upstream returns `true` or `undefined`: here `true` or `false`.
bool _doesNotFitWithAlign(
  Object? xAlign,
  types.Chart chart,
  TooltipOptions options,
  _PositionAndSize size,
) {
  final (:x, :width, y: _, height: _, xAlign: _, yAlign: _) = size;
  final caret =
      jsToNumber(options.caretSize) + jsToNumber(options.caretPadding);
  if (xAlign == 'left' && x + width + caret > chart.width) {
    return true;
  }

  if (xAlign == 'right' && x - width - caret < 0) {
    return true;
  }
  return false;
}

/// plugin.tooltip.js:246 `determineXAlign(chart, options, size, yAlign)`.
///
/// A chart without a chart area throws the [TypeError] of the null check,
/// as the destructuring of `undefined` throws.
String _determineXAlign(
  types.Chart chart,
  TooltipOptions options,
  _PositionAndSize size,
  Object? yAlign,
) {
  final (:x, :width, y: _, height: _, xAlign: _, yAlign: _) = size;
  final chartWidth = chart.width;
  final ChartArea(:left, :right) = chart.chartArea!;
  var xAlign = 'center';

  if (yAlign == 'center') {
    xAlign = x <= (left + right) / 2 ? 'left' : 'right';
  } else if (x <= width / 2) {
    xAlign = 'left';
  } else if (x >= chartWidth - width / 2) {
    xAlign = 'right';
  }

  if (_doesNotFitWithAlign(xAlign, chart, options, size)) {
    xAlign = 'center';
  }

  return xAlign;
}

/// plugin.tooltip.js:269 `determineAlignment(chart, options, size)`.
///
/// Helper to get the alignment of a tooltip given the size
///
/// The `||` chains apply ToBoolean to the raw values ([jsTruthy]), so a
/// positioner result and the options can give any value.
({Object? xAlign, Object? yAlign}) _determineAlignment(
  types.Chart chart,
  TooltipOptions options,
  _PositionAndSize size,
) {
  final yAlign = _or(
    _or(size.yAlign, () => options.yAlign),
    () => _determineYAlign(chart, size),
  );

  return (
    xAlign: _or(
      _or(size.xAlign, () => options.xAlign),
      () => _determineXAlign(chart, options, size, yAlign),
    ),
    yAlign: yAlign,
  );
}

/// The JS operator `a || b`: [a] when it is truthy, else the result of [b].
Object? _or(Object? a, Object? Function() b) => jsTruthy(a) ? a : b();

/// plugin.tooltip.js:278 `alignX(size, xAlign)`.
double _alignX(_PositionAndSize size, Object? xAlign) {
  var (:x, :width, y: _, height: _, xAlign: _, yAlign: _) = size;
  if (xAlign == 'right') {
    x -= width;
  } else if (xAlign == 'center') {
    x -= width / 2;
  }
  return x;
}

/// plugin.tooltip.js:288 `alignY(size, yAlign, paddingAndSize)`.
double _alignY(_PositionAndSize size, Object? yAlign, double paddingAndSize) {
  var (:y, :height, x: _, width: _, xAlign: _, yAlign: _) = size;
  if (yAlign == 'top') {
    y += paddingAndSize;
  } else if (yAlign == 'bottom') {
    y -= height + paddingAndSize;
  } else {
    y -= height / 2;
  }
  return y;
}

/// plugin.tooltip.js:304 `getBackgroundPoint(options, size, alignment,
/// chart)`.
///
/// Helper to get the location a tooltip needs to be placed at given the
/// initial position (via the vm) and the size and alignment
({double x, double y}) _getBackgroundPoint(
  TooltipOptions options,
  _PositionAndSize size,
  ({Object? xAlign, Object? yAlign}) alignment,
  types.Chart chart,
) {
  final caretSize = jsToNumber(options.caretSize);
  final caretPadding = jsToNumber(options.caretPadding);
  final cornerRadius = options.cornerRadius;
  final (:xAlign, :yAlign) = alignment;
  final paddingAndSize = caretSize + caretPadding;
  final TRBLCorners(:topLeft, :topRight, :bottomLeft, :bottomRight) =
      toTRBLCorners(cornerRadius);

  var x = _alignX(size, xAlign);
  final y = _alignY(size, yAlign, paddingAndSize);

  if (yAlign == 'center') {
    if (xAlign == 'left') {
      x += paddingAndSize;
    } else if (xAlign == 'right') {
      x -= paddingAndSize;
    }
  } else if (xAlign == 'left') {
    x -= jsMax(topLeft, bottomLeft) + caretSize;
  } else if (xAlign == 'right') {
    x += jsMax(topRight, bottomRight) + caretSize;
  }

  return (
    x: limitValue(x, 0, chart.width - size.width),
    y: limitValue(y, 0, chart.height - size.height),
  );
}

/// plugin.tooltip.js:331 `getAlignedX(tooltip, align, options)`.
double _getAlignedX(Tooltip tooltip, Object? align, TooltipOptions options) {
  final padding = toPadding(options.padding);

  return align == 'center'
      ? tooltip.x + tooltip.width / 2
      : align == 'right'
      ? tooltip.x + tooltip.width - padding.right
      : tooltip.x + padding.left;
}

/// plugin.tooltip.js:344 `getBeforeAfterBodyLines(callback)`. Helper to
/// build before and after body lines
List<Object?> _getBeforeAfterBodyLines(Object? callback) {
  return _pushOrConcat([], _splitNewlines(callback));
}

/// plugin.tooltip.js:348 `createTooltipContext(parent, tooltip,
/// tooltipItems)`.
AnyObject _createTooltipContext(
  AnyObject? parent,
  Tooltip tooltip,
  List<Object?> tooltipItems,
) {
  return createContext(parent, <String, Object?>{
    'tooltip': tooltip,
    'tooltipItems': tooltipItems,
    'type': 'tooltip',
  });
}

/// plugin.tooltip.js:356 `overrideCallbacks(callbacks, context)`.
///
/// The `&&` chain `context.dataset.tooltip.callbacks`: the typed `dataset`
/// of the tooltip item, then the typed reads of the dataset options of the
/// user and of its `tooltip` object ([optionOf]; by name for a Map).
/// `callbacks.override(override)` is the `override` member of a resolver,
/// and the call by name of the member of another callbacks object, with the
/// object as `this`.
Object? _overrideCallbacks(Object? callbacks, Object? context) {
  var override = context;
  if (jsTruthy(override)) override = _TooltipItemView(override).dataset;
  if (jsTruthy(override)) override = optionOf(override, OptionKey.tooltip);
  if (jsTruthy(override)) {
    override = optionOf(override, OptionKey.callbacks);
  }
  if (!jsTruthy(override)) return callbacks;
  return switch (callbacks) {
    final OptionView view => view.override(override! as AnyObject),
    final OptionResolver resolver => resolver.override(override! as AnyObject),
    _ => jsCall(jsGet(callbacks, 'override'), [override], thisArg: callbacks),
  };
}

/// `this.options` of a default callback (plugin.tooltip.js:370, :389,
/// :417).
///
/// A falsy `this` gives itself, so `this && this.options` short-circuits.
/// An element gives its typed `options` ([undefined] for Dart `null`),
/// another value the read by name. Thus a call without `this` throws the
/// [TypeError] of `undefined.options` at the read that follows, as upstream
/// (Chart.js ADR 0039, section 8).
Object? _thisOptions(Object? self) => !jsTruthy(self)
    ? self
    : self is Element
    ? (self.options ?? undefined)
    : jsGet(self, 'options');

/// `this && this.options && this.options.mode === 'dataset'`
/// (plugin.tooltip.js:370, :389).
bool _isDatasetMode(Object? self) {
  final options = _thisOptions(self);
  return jsTruthy(options) &&
      _strictEquals(TooltipOptions(options).mode, 'dataset');
}

/// The chart of a tooltip item: `item.chart`. A `types.Chart` stays as it
/// is. The defaults read its members through the interface (Chart.js ADR
/// 0028, section 1).
types.Chart _chartOf(Object? item) =>
    _TooltipItemView(item).chart! as types.Chart;

/// The JS read `item.chart.data` of a tooltip item: the `data` of a
/// `types.Chart`, else the read by name of a value of user code.
Object? _chartDataOf(Object? item) {
  final chart = _TooltipItemView(item).chart;
  return chart is types.Chart ? chart.data : jsGet(chart, 'data');
}

/// plugin.tooltip.js:364 the default `title(tooltipItems)`. Args are:
/// (tooltipItems, data)
///
/// The items are [TooltipItem]s, read through their fields, or values of
/// user code, read by name. The labels and the datasets are data of the
/// user, read by name.
Object? _defaultTitle(Object? self, Object? tooltipItems) {
  if (jsToNumber(_itemsLength(tooltipItems)) > 0) {
    final item = jsGetIndex(tooltipItems, 0);
    final labels = jsGet(_chartDataOf(item), 'labels');
    final labelCount = jsTruthy(labels) ? jsGet(labels, 'length') : 0.0;

    if (_isDatasetMode(self)) {
      final label = jsGet(_TooltipItemView(item).dataset, 'label');
      return jsTruthy(label) ? label : '';
    }
    final label = _TooltipItemView(item).label;
    if (jsTruthy(label)) {
      return label;
    }
    final dataIndex = _TooltipItemView(item).dataIndex;
    if (jsLessThan(0, labelCount) && jsLessThan(dataIndex, labelCount)) {
      return dataIndex is double
          ? jsGetIndex(labels, dataIndex)
          : jsGet(labels, dataIndex);
    }
  }

  return '';
}

/// plugin.tooltip.js:388 the default `label(tooltipItem)`. Args are:
/// (tooltipItem, data)
///
/// The `+` of a raw value is [jsAdd] (Chart.js ADR 0036).
Object? _defaultLabel(Object? self, Object? tooltipItem) {
  final item = _TooltipItemView(tooltipItem);
  if (_isDatasetMode(self)) {
    final text = jsAdd(jsAdd(item.label, ': '), item.formattedValue);
    return jsTruthy(text) ? text : item.formattedValue;
  }

  // The dataset of the user, read by name.
  final datasetLabel = jsGet(item.dataset, 'label');
  var label = jsTruthy(datasetLabel) ? datasetLabel : '';

  if (jsTruthy(label)) {
    label = jsAdd(label, ': ');
  }
  final value = item.formattedValue;
  if (!isNullOrUndef(value)) {
    label = jsAdd(label, value);
  }
  return label;
}

/// The style of the data element of a tooltip item: the reads
/// `tooltipItem.chart.getDatasetMeta(tooltipItem.datasetIndex)` and
/// `meta.controller.getStyle(tooltipItem.dataIndex)` of
/// plugin.tooltip.js:405-406 and :420-421.
AnyObject _styleOf(Object? tooltipItem) {
  final item = _TooltipItemView(tooltipItem);
  final meta = _chartOf(
    tooltipItem,
  ).getDatasetMeta(jsToNumber(item.datasetIndex));
  return meta.controller!.getStyle(jsToNumber(item.dataIndex));
}

/// plugin.tooltip.js:404 the default `labelColor(tooltipItem)`: a
/// [TooltipLabelStyle]. The style keys are the typed reads of the options.
TooltipLabelStyle _defaultLabelColor(Object? tooltipItem) {
  final options = _styleOf(tooltipItem);
  return TooltipLabelStyle()
    ..borderColor = optionOf(options, OptionKey.borderColor)
    ..backgroundColor = optionOf(options, OptionKey.backgroundColor)
    ..borderWidth = optionOf(options, OptionKey.borderWidth)
    ..borderDash = optionOf(options, OptionKey.borderDash)
    ..borderDashOffset = optionOf(options, OptionKey.borderDashOffset)
    ..borderRadius = 0.0;
}

/// plugin.tooltip.js:416 the default `labelTextColor()`: `this.options
/// .bodyColor`, with no guard. A call without `this` throws a [TypeError].
Object? _defaultLabelTextColor(Object? self) =>
    TooltipOptions(_thisOptions(self)).bodyColor;

/// plugin.tooltip.js:419 the default `labelPointStyle(tooltipItem)`: a
/// [TooltipLabelPointStyle].
TooltipLabelPointStyle _defaultLabelPointStyle(Object? tooltipItem) {
  final options = _styleOf(tooltipItem);
  return TooltipLabelPointStyle()
    ..pointStyle = optionOf(options, OptionKey.pointStyle)
    ..rotation = optionOf(options, OptionKey.rotation);
}

/// plugin.tooltip.js:361 `const defaultCallbacks`: the 14 callbacks in the
/// upstream order (Chart.js ADR 0039, section 8).
///
/// `title`, `label` and `labelTextColor` read `this`, so they are
/// [JsFunction] values. The 9 `noop` entries are `noop` of helpers.core. The
/// plugin `defaults` holds this object under `callbacks` (:1324): a typed
/// scope of the kind `TooltipCallbacks` (Chart.js ADR 0054 §3).
final TooltipCallbacksScope _defaultCallbacks = TooltipCallbacksScope()
  // Args are: (tooltipItems, data)
  ..beforeTitle = noop
  ..title = const JsFunction(_defaultTitle)
  ..afterTitle = noop
  // Args are: (tooltipItems, data)
  ..beforeBody = noop
  // Args are: (tooltipItem, data)
  ..beforeLabel = noop
  ..label = const JsFunction(_defaultLabel)
  ..labelColor = _defaultLabelColor
  ..labelTextColor = const JsFunction(_defaultLabelTextColor)
  ..labelPointStyle = _defaultLabelPointStyle
  ..afterLabel = noop
  // Args are: (tooltipItems, data)
  ..afterBody = noop
  // Args are: (tooltipItems, data)
  ..beforeFooter = noop
  ..footer = noop
  ..afterFooter = noop;

/// plugin.tooltip.js:447 `invokeCallbackWithFallback(callbacks, name, ctx,
/// arg)`.
///
/// Invoke callback from object with context and arguments. If callback
/// returns `undefined`, then will be invoked default callback.
///
/// The test of `noop` comes first (Chart.js ADR 0039, section 8): when the
/// callback and the default are both `noop`, both upstream calls call
/// `noop`, which has no effect and returns `undefined`. Thus the test gives
/// the result of the two calls for each input. It drops the underscore,
/// because the port test reads it (Chart.js ADR 0012).
///
/// The callback name is the typed key [name] (Chart.js ADR 0054 §4): the
/// typed read of the callbacks resolver and of the default callbacks.
@visibleForTesting
Object? invokeCallbackWithFallback(
  Object? callbacks,
  OptionKey name,
  Object? ctx,
  Object? arg,
) {
  final callback = optionOf(callbacks, name);
  final fallback = _defaultCallbacks.lookup(name)?.raw;
  // Both upstream calls call noop: no effect, and the result is undefined.
  if (identical(callback, noop) && identical(fallback, noop)) return undefined;
  final result = jsCall1(callback, arg, thisArg: ctx);

  if (identical(result, undefined)) {
    return jsCall1(fallback, arg, thisArg: ctx);
  }

  return result;
}

/// The JS operator `===` on two raw values: two numbers compare by value
/// (NaN is not equal to itself, and -0 equals +0), two strings by their
/// code units, and other values by identity (Chart.js ADR 0039, Open 3).
bool _strictEquals(Object? a, Object? b) {
  if (a is num && b is num) return a.toDouble() == b.toDouble();
  if (a is String && b is String) return a == b;
  return identical(a, b);
}

/// The object `{datasetIndex, element, index}` of `setActiveElements`
/// (plugin.tooltip.js:1115-1119).
final class _ActiveElement implements types.ActiveElement {
  _ActiveElement({
    required this.datasetIndex,
    required this.element,
    required this.index,
  });

  @override
  final double datasetIndex;

  /// Dart `null` stands for the `undefined` of an index without an element.
  @override
  final types.Element? element;

  @override
  final double index;
}

/// The element `meta.data[index]`, or Dart `null` for JS `undefined`.
types.Element? _elementAt(List<types.Element> data, double index) =>
    switch (jsGetIndex(data, index)) {
      final types.Element element => element,
      _ => null,
    };

/// `active.reverse()`: reverses [list] in place. The items come from the
/// same list, so the covariant store of a `List<InteractionItem>` accepts
/// them, and the list keeps its identity (Chart.js ADR 0039, section 12).
void _reverseInPlace(List<types.ActiveElement> list) {
  for (var i = 0, j = list.length - 1; i < j; i++, j--) {
    final item = list[i];
    list[i] = list[j];
    list[j] = item;
  }
}

/// The mutable point `pt` of `draw` (plugin.tooltip.js:1054-1057).
/// `drawTitle`, `drawBody` and `drawFooter` change it, as upstream changes
/// the literal (Chart.js ADR 0039, section 11).
///
/// The class is public because the upstream methods `drawTitle` (:756),
/// `drawBody` (:871), `drawFooter` (:935) and `drawBackground` (:961) are
/// public and take it (rule 2, Chart.js ADR 0012).
final class TooltipPoint {
  /// The literal `{x: this.x, y: this.y}` of :1054-1057.
  TooltipPoint(this.x, this.y);

  /// `pt.x`.
  double x;

  /// `pt.y`.
  double y;
}

/// The rounded box of a color box (:835-841, :848-854), the object literal
/// `{x, y, w, h, radius}` of the `addRoundedRectPath` call.
final class _RoundedRect implements RoundedRect {
  _RoundedRect({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.radius,
  });

  @override
  final double x;

  @override
  final double y;

  @override
  final double w;

  @override
  final double h;

  @override
  final TRBLCorners radius;
}

/// plugin.tooltip.js:457 `class Tooltip extends Element`.
///
/// ## Properties
///
/// The rules of Chart.js ADR 0017, sections 3-5, apply to the 28 own names
/// and to `_ignoreReplayEvents` (Chart.js ADR 0039, section 2). [Element]
/// handles `x`, `y`, `active`, `options` and `$animations`. [operator []]
/// and [operator []=] handle the other 24 names:
///
/// - `opacity` (start 0), `width`, `height`, `caretX`, `caretY`: numbers.
///   The getter gives NaN for `undefined`. A write by name takes a `num` or
///   [undefined].
/// - `xAlign`, `yAlign`: a `String` or [undefined]
///   (`index.d.ts:2655-2656`). Each write, also the writes of [update],
///   goes through the write by name. Thus a value that is not a string
///   throws an [ArgumentError] (Chart.js ADR 0017, section 5). Upstream
///   stores it.
/// - `title`, `beforeBody`, `body`, `afterBody`, `footer`, `dataPoints`,
///   `labelColors`, `labelPointStyles`, `labelTextColors`: a
///   `List<Object?>` or [undefined]. A line of text can be any JS value.
/// - `chart`: a `types.Chart` only. Another value, also [undefined], throws
///   an [ArgumentError].
/// - `_active` (start `[]`): a `List<types.ActiveElement>`, not
///   [undefined]. `_tooltipItems` (start `[]`): a `List<Object?>`, not
///   [undefined].
/// - `_eventPosition`: any value. `_size`: the size record or [undefined].
///   `_cachedAnimations`: an [Animations] or [undefined]. `$context`: a Map
///   or [undefined]. `_ignoreReplayEvents`: a `bool` or [undefined].
///
/// The private names keep their upstream spelling: only this library reads
/// them in Dart. Other code reads and writes them by name, for example
/// `tooltip['_active']` (`core.controller.tests.js:1719`).
///
/// ## `update`
///
/// [update] is a field that holds a function (differences.md
/// `harness-method-fields`): a spec replaces it on one tooltip
/// (`plugin.tooltip.tests.js:964`, `:1027`). Each internal call goes
/// through the field.
class Tooltip extends Element implements types.TooltipModel {
  /// plugin.tooltip.js:464 `constructor(config)`.
  ///
  /// The upstream `config` object is a record (Chart.js ADR 0038, section
  /// 4). The `construct` closure of [jsClass] reads it from a JS value. The
  /// start values follow the upstream order (:467-495). The other
  /// properties start in the `undefined` state.
  Tooltip(({types.Chart chart, AnyObject? options}) config)
    : chart = config.chart {
    _opacity = 0;
    _active = [];
    _tooltipItems = [];
    options = config.options;
  }

  /// plugin.tooltip.js:462 `static positioners = positioners`.
  ///
  /// The namespace Chart.Tooltip.positioners: the Map of the module
  /// (Chart.js ADR 0039, section 4).
  static final AnyObject positioners = _positioners;

  /// plugin.tooltip.js:457 `class Tooltip` as a value (Chart.js ADR 0020,
  /// section 3).
  ///
  /// Its superclass is [Element.jsClass]. Its one static property is
  /// `positioners`. Its `construct` reads the `config` argument with
  /// [_tooltipConfig].
  static final JsClass jsClass = JsClass(
    'Tooltip',
    superclass: Element.jsClass,
    statics: {'positioners': positioners},
    construct: (newTarget, args) => Tooltip(_tooltipConfig(args)),
  );

  /// plugin.tooltip.js:475 `chart`. Not final: the access by name writes it
  /// (Chart.js ADR 0039, section 2).
  @override
  types.Chart chart;

  double? _opacity;
  double? _width;
  double? _height;
  double? _caretX;
  double? _caretY;
  String? _xAlign;
  String? _yAlign;
  List<Object?>? _dataPoints;
  List<Object?>? _title;
  List<Object?>? _beforeBody;
  List<Object?>? _body;
  List<Object?>? _afterBody;
  List<Object?>? _footer;
  List<Object?>? _labelColors;
  List<Object?>? _labelPointStyles;
  List<Object?>? _labelTextColors;

  /// plugin.tooltip.js:468 `_active`, the active elements of the tooltip.
  List<types.ActiveElement> _active = const [];

  /// plugin.tooltip.js:469 `_eventPosition`, any JS value. The [undefined]
  /// sentinel stands for the start value.
  Object? _eventPosition = undefined;

  /// plugin.tooltip.js:470 `_size`. Dart `null` stands for JS `undefined`.
  ({double width, double height})? _size;

  /// plugin.tooltip.js:471 `_cachedAnimations`. Dart `null` stands for JS
  /// `undefined`.
  Animations? _cachedAnimations;

  /// plugin.tooltip.js:472 `_tooltipItems`.
  List<Object?> _tooltipItems = const [];

  /// plugin.tooltip.js:474 `$context`. Dart `null` stands for JS
  /// `undefined`.
  AnyObject? _context;

  /// plugin.tooltip.js:1127 `_ignoreReplayEvents`. Dart `null` stands for
  /// JS `undefined`, the value before the first event.
  bool? _ignoreReplayEvents;

  /// plugin.tooltip.js:467 `opacity`. NaN for JS `undefined`.
  @override
  double get opacity => _opacity ?? double.nan;

  set opacity(double value) => _opacity = value;

  /// plugin.tooltip.js:488 `width`. NaN for JS `undefined`.
  @override
  double get width => _width ?? double.nan;

  set width(double value) => _width = value;

  /// plugin.tooltip.js:487 `height`. NaN for JS `undefined`.
  @override
  double get height => _height ?? double.nan;

  set height(double value) => _height = value;

  /// plugin.tooltip.js:489 `caretX`. NaN for JS `undefined`.
  @override
  double get caretX => _caretX ?? double.nan;

  set caretX(double value) => _caretX = value;

  /// plugin.tooltip.js:490 `caretY`. NaN for JS `undefined`.
  @override
  double get caretY => _caretY ?? double.nan;

  set caretY(double value) => _caretY = value;

  /// plugin.tooltip.js:483 `xAlign`. Dart `null` for JS `undefined`.
  @override
  String? get xAlign => _xAlign;

  set xAlign(String value) => _xAlign = value;

  /// plugin.tooltip.js:484 `yAlign`. Dart `null` for JS `undefined`.
  @override
  String? get yAlign => _yAlign;

  set yAlign(String value) => _yAlign = value;

  /// plugin.tooltip.js:477 `dataPoints`, the tooltip items. Dart `null` for
  /// JS `undefined`.
  @override
  List<Object?>? get dataPoints => _dataPoints;

  set dataPoints(List<Object?> value) => _dataPoints = value;

  /// plugin.tooltip.js:478 `title`. Dart `null` for JS `undefined`.
  @override
  List<Object?>? get title => _title;

  set title(List<Object?> value) => _title = value;

  /// plugin.tooltip.js:479 `beforeBody`. Dart `null` for JS `undefined`.
  @override
  List<Object?>? get beforeBody => _beforeBody;

  set beforeBody(List<Object?> value) => _beforeBody = value;

  /// plugin.tooltip.js:480 `body`. Dart `null` for JS `undefined`.
  @override
  List<Object?>? get body => _body;

  set body(List<Object?> value) => _body = value;

  /// plugin.tooltip.js:481 `afterBody`. Dart `null` for JS `undefined`.
  @override
  List<Object?>? get afterBody => _afterBody;

  set afterBody(List<Object?> value) => _afterBody = value;

  /// plugin.tooltip.js:482 `footer`. Dart `null` for JS `undefined`.
  @override
  List<Object?>? get footer => _footer;

  set footer(List<Object?> value) => _footer = value;

  /// plugin.tooltip.js:493 `labelColors`. Dart `null` for JS `undefined`.
  @override
  List<Object?>? get labelColors => _labelColors;

  set labelColors(List<Object?> value) => _labelColors = value;

  /// plugin.tooltip.js:494 `labelPointStyles`. Dart `null` for JS
  /// `undefined`.
  @override
  List<Object?>? get labelPointStyles => _labelPointStyles;

  set labelPointStyles(List<Object?> value) => _labelPointStyles = value;

  /// plugin.tooltip.js:495 `labelTextColors`. Dart `null` for JS
  /// `undefined`.
  @override
  List<Object?>? get labelTextColors => _labelTextColors;

  set labelTextColors(List<Object?> value) => _labelTextColors = value;

  /// plugin.tooltip.js:498 `initialize(options)`.
  void initialize(AnyObject? options) {
    this.options = options;
    _cachedAnimations = null;
    _context = null;
  }

  /// `this.options.setContext(this.getContext())` (plugin.tooltip.js:515,
  /// :639, :1041).
  ///
  /// The resolver of a chart gives its typed `setContext`. A plain Map with
  /// a `setContext` function (`plugin.tooltip.tests.js:1391`) gives the
  /// read by name and the call with the options as `this` (Chart.js ADR
  /// 0039, section 7). Options without `setContext` throw where upstream
  /// throws.
  TooltipOptions _resolveOptions() {
    final options = this.options ?? undefined;
    if (options is OptionView) {
      return TooltipOptions(options.setContext(getContext()));
    }
    // Options of a spec or of user code: the call by name.
    return TooltipOptions(
      jsCall(jsGet(options, 'setContext'), [getContext()], thisArg: options)!
          as AnyObject,
    );
  }

  /// plugin.tooltip.js:507 `_resolveAnimations()`.
  ///
  /// `opts` is the JS `&&` chain of the raw values. The cache and the freeze
  /// run only for options whose `_cacheable` is truthy: a chart gives a
  /// context resolver with `_cacheable` false (differences.md
  /// `js-semantics-object-freeze`). `opts._cacheable` of `undefined` throws
  /// the [TypeError] of [jsGet].
  Animations _resolveAnimations() {
    final cached = _cachedAnimations;

    if (cached != null) {
      return cached;
    }

    final chart = this.chart;
    final options = _resolveOptions();
    final enabled = options.enabled;
    final animation = jsTruthy(enabled)
        ? optionOf(chart.options, OptionKey.animation)
        : enabled;
    final opts = jsTruthy(animation) ? options.animations : animation;
    final animations = Animations(this.chart, opts);
    if (_isCacheable(opts)) {
      _cachedAnimations = jsObjectFreeze(animations);
    }

    return animations;
  }

  /// `opts._cacheable` with ToBoolean: the typed slot of a resolver, else
  /// the read by name. `undefined` and JS `null` throw the [TypeError] of
  /// the read.
  static bool _isCacheable(Object? opts) => switch (opts) {
    final OptionView view => view.cacheable,
    final OptionResolver resolver => resolver.cacheable,
    _ => jsTruthy(jsGet(opts, '_cacheable')),
  };

  /// plugin.tooltip.js:528 `getContext()`. @protected
  ///
  /// The context is cached until the next [update].
  AnyObject getContext() {
    return _context ??= _createTooltipContext(
      chart.getContext(),
      this,
      _tooltipItems,
    );
  }

  /// The position of the positioner of the option `position`:
  /// `positioners[options.position].call(this, active, eventPosition)`
  /// (plugin.tooltip.js:651, :1012, :1218).
  ///
  /// An unknown name gives [undefined], and [jsCall] throws an
  /// [ArgumentError] where upstream throws the `TypeError` of `.call`.
  ///
  /// The positioners are a dictionary by name (user positioners): the read
  /// by the name of the option, and the call with JS arity.
  Object? _position(
    TooltipOptions options,
    List<types.ActiveElement> active,
    Object? eventPosition,
  ) => jsCall(
    jsGet(_positioners, options.position),
    [active, eventPosition],
    thisArg: this,
  );

  /// plugin.tooltip.js:533 `getTitle(context, options)`.
  List<Object?> getTitle(Object? context, TooltipOptions options) {
    final callbacks = options.callbacks;

    final beforeTitle = invokeCallbackWithFallback(
      callbacks,
      OptionKey.beforeTitle,
      this,
      context,
    );
    final title = invokeCallbackWithFallback(
      callbacks,
      OptionKey.title,
      this,
      context,
    );
    final afterTitle = invokeCallbackWithFallback(
      callbacks,
      OptionKey.afterTitle,
      this,
      context,
    );

    var lines = <Object?>[];
    lines = _pushOrConcat(lines, _splitNewlines(beforeTitle));
    lines = _pushOrConcat(lines, _splitNewlines(title));
    lines = _pushOrConcat(lines, _splitNewlines(afterTitle));

    return lines;
  }

  /// plugin.tooltip.js:548 `getBeforeBody(tooltipItems, options)`.
  List<Object?> getBeforeBody(Object? tooltipItems, TooltipOptions options) {
    return _getBeforeAfterBodyLines(
      invokeCallbackWithFallback(
        options.callbacks,
        OptionKey.beforeBody,
        this,
        tooltipItems,
      ),
    );
  }

  /// plugin.tooltip.js:554 `getBody(tooltipItems, options)`.
  ///
  /// A body item is the [TooltipBodyItem] `{before, lines, after}`. The
  /// label lines skip `splitNewlines` (:566), as upstream.
  List<Object?> getBody(Object? tooltipItems, TooltipOptions options) {
    final callbacks = options.callbacks;
    final bodyItems = <Object?>[];

    each(tooltipItems, (Object? context) {
      final before = <Object?>[];
      final lines = <Object?>[];
      final after = <Object?>[];
      final bodyItem = TooltipBodyItem()
        ..before = before
        ..lines = lines
        ..after = after;
      final scoped = _overrideCallbacks(callbacks, context);
      _pushOrConcat(
        before,
        _splitNewlines(
          invokeCallbackWithFallback(
            scoped,
            OptionKey.beforeLabel,
            this,
            context,
          ),
        ),
      );
      _pushOrConcat(
        lines,
        invokeCallbackWithFallback(scoped, OptionKey.label, this, context),
      );
      _pushOrConcat(
        after,
        _splitNewlines(
          invokeCallbackWithFallback(
            scoped,
            OptionKey.afterLabel,
            this,
            context,
          ),
        ),
      );

      bodyItems.add(bodyItem);
    });

    return bodyItems;
  }

  /// plugin.tooltip.js:575 `getAfterBody(tooltipItems, options)`.
  List<Object?> getAfterBody(Object? tooltipItems, TooltipOptions options) {
    return _getBeforeAfterBodyLines(
      invokeCallbackWithFallback(
        options.callbacks,
        OptionKey.afterBody,
        this,
        tooltipItems,
      ),
    );
  }

  /// plugin.tooltip.js:582 `getFooter(tooltipItems, options)`. Get the
  /// footer and beforeFooter and afterFooter lines
  List<Object?> getFooter(Object? tooltipItems, TooltipOptions options) {
    final callbacks = options.callbacks;

    final beforeFooter = invokeCallbackWithFallback(
      callbacks,
      OptionKey.beforeFooter,
      this,
      tooltipItems,
    );
    final footer = invokeCallbackWithFallback(
      callbacks,
      OptionKey.footer,
      this,
      tooltipItems,
    );
    final afterFooter = invokeCallbackWithFallback(
      callbacks,
      OptionKey.afterFooter,
      this,
      tooltipItems,
    );

    var lines = <Object?>[];
    lines = _pushOrConcat(lines, _splitNewlines(beforeFooter));
    lines = _pushOrConcat(lines, _splitNewlines(footer));
    lines = _pushOrConcat(lines, _splitNewlines(afterFooter));

    return lines;
  }

  /// plugin.tooltip.js:600 `_createItems(options)`.
  ///
  /// `options.filter` gets the item, its index, the array and the chart
  /// data. `options.itemSort` goes through [jsSort], the stable
  /// `Array.prototype.sort`, with the `ToNumber` of the comparator result.
  /// Both are method calls of upstream (:615, :620): `this` is [options].
  /// Both are user functions, called with JS arity.
  List<Object?> _createItems(TooltipOptions options) {
    final active = _active;
    final data = chart.data;
    final labelColors = <Object?>[];
    final labelPointStyles = <Object?>[];
    final labelTextColors = <Object?>[];
    var tooltipItems = <Object?>[];

    for (var i = 0, len = active.length; i < len; ++i) {
      tooltipItems.add(_createTooltipItem(chart, active[i]));
    }

    // If the user provided a filter function, use it to modify the tooltip
    // items
    final filter = options.filter;
    if (jsTruthy(filter)) {
      final array = tooltipItems;
      tooltipItems = [
        for (var index = 0; index < array.length; index++)
          if (jsTruthy(
            jsCall(
              filter,
              [array[index], index.toDouble(), array, data],
              thisArg: options.object,
            ),
          ))
            array[index],
      ];
    }

    // If the user provided a sorting function, use it to modify the tooltip
    // items
    final itemSort = options.itemSort;
    if (jsTruthy(itemSort)) {
      tooltipItems = jsSort(
        tooltipItems,
        (a, b) => jsToNumber(
          jsCall(itemSort, [a, b, data], thisArg: options.object),
        ),
      );
    }

    // Determine colors for boxes
    each(tooltipItems, (Object? context) {
      final scoped = _overrideCallbacks(options.callbacks, context);
      labelColors.add(
        invokeCallbackWithFallback(scoped, OptionKey.labelColor, this, context),
      );
      labelPointStyles.add(
        invokeCallbackWithFallback(
          scoped,
          OptionKey.labelPointStyle,
          this,
          context,
        ),
      );
      labelTextColors.add(
        invokeCallbackWithFallback(
          scoped,
          OptionKey.labelTextColor,
          this,
          context,
        ),
      );
    });

    _labelColors = labelColors;
    _labelPointStyles = labelPointStyles;
    _labelTextColors = labelTextColors;
    _dataPoints = tooltipItems;
    return tooltipItems;
  }

  /// plugin.tooltip.js:638 `update(changed, replay)`.
  ///
  /// A field that holds a function: a spec replaces it on one tooltip
  /// (Chart.js ADR 0039, section 6). Both parameters are optional, as
  /// `update()` is a valid JS call. [setActiveElements] and [handleEvent]
  /// call the field.
  // DIVERGES(chartjs): harness-method-fields, a spec replaces it per tooltip.
  late void Function([Object? changed, Object? replay]) update = _updateMethod;

  /// The upstream body of `update(changed, replay)`
  /// (plugin.tooltip.js:638-689).
  ///
  /// `xAlign` and `yAlign` take the write by name: a value that is not a
  /// string throws an [ArgumentError] (Chart.js ADR 0039, section 2).
  /// `caretX` and `caretY` take the raw `position.x` and `position.y`, not
  /// the values of the record (section 5).
  void _updateMethod([
    Object? changed = undefined,
    Object? replay = undefined,
  ]) {
    final options = _resolveOptions();
    final active = _active;
    AnyObject? properties;
    var tooltipItems = <Object?>[];

    if (active.isEmpty) {
      if (!_strictEquals(_opacity ?? undefined, 0)) {
        properties = <String, Object?>{'opacity': 0.0};
      }
    } else {
      final position = _position(options, active, _eventPosition);
      tooltipItems = _createItems(options);

      _title = getTitle(tooltipItems, options);
      _beforeBody = getBeforeBody(tooltipItems, options);
      _body = getBody(tooltipItems, options);
      _afterBody = getAfterBody(tooltipItems, options);
      _footer = getFooter(tooltipItems, options);

      final size = _size = _getTooltipSize(this, options);
      final positionAndSize = _positionAndSize(position, size);
      final alignment = _determineAlignment(chart, options, positionAndSize);
      final backgroundPoint = _getBackgroundPoint(
        options,
        positionAndSize,
        alignment,
        chart,
      );

      _xAlign = toObjectProp<String>('xAlign', alignment.xAlign);
      _yAlign = toObjectProp<String>('yAlign', alignment.yAlign);

      properties = <String, Object?>{
        'opacity': 1.0,
        'x': backgroundPoint.x,
        'y': backgroundPoint.y,
        'width': size.width,
        'height': size.height,
        'caretX': _readX(position),
        'caretY': _readY(position),
      };
    }

    _tooltipItems = tooltipItems;
    _context = null;

    if (properties != null) {
      _resolveAnimations().update(this, properties);
    }

    if (jsTruthy(changed)) {
      final external = options.external;
      if (jsTruthy(external)) {
        jsCall(
          external,
          [
            <String, Object?>{
              'chart': chart,
              'tooltip': this,
              'replay': replay,
            },
          ],
          thisArg: this,
        );
      }
    }
  }

  /// plugin.tooltip.js:691 `drawCaret(tooltipPoint, ctx, size, options)`.
  void drawCaret(
    Point tooltipPoint,
    CanvasRenderingContext2D ctx,
    ({double width, double height}) size,
    TooltipOptions options,
  ) {
    final caretPosition = getCaretPosition(tooltipPoint, size, options);

    ctx
      ..lineTo(caretPosition.x1, caretPosition.y1)
      ..lineTo(caretPosition.x2, caretPosition.y2)
      ..lineTo(caretPosition.x3, caretPosition.y3);
  }

  /// plugin.tooltip.js:699 `getCaretPosition(tooltipPoint, size, options)`:
  /// the object `{x1, x2, x3, y1, y2, y3}`, a record.
  ({double x1, double x2, double x3, double y1, double y2, double y3})
  getCaretPosition(
    Point tooltipPoint,
    ({double width, double height}) size,
    TooltipOptions options,
  ) {
    final Tooltip(:xAlign, :yAlign) = this;
    final caretSize = jsToNumber(options.caretSize);
    final cornerRadius = options.cornerRadius;
    final TRBLCorners(:topLeft, :topRight, :bottomLeft, :bottomRight) =
        toTRBLCorners(cornerRadius);
    final ptX = tooltipPoint.x ?? 0;
    final ptY = tooltipPoint.y ?? 0;
    final (:width, :height) = size;
    double x1;
    double x2;
    double x3;
    double y1;
    double y2;
    double y3;

    if (yAlign == 'center') {
      y2 = ptY + (height / 2);

      if (xAlign == 'left') {
        x1 = ptX;
        x2 = x1 - caretSize;

        // Left draws bottom -> top, this y1 is on the bottom
        y1 = y2 + caretSize;
        y3 = y2 - caretSize;
      } else {
        x1 = ptX + width;
        x2 = x1 + caretSize;

        // Right draws top -> bottom, thus y1 is on the top
        y1 = y2 - caretSize;
        y3 = y2 + caretSize;
      }

      x3 = x1;
    } else {
      if (xAlign == 'left') {
        x2 = ptX + jsMax(topLeft, bottomLeft) + caretSize;
      } else if (xAlign == 'right') {
        x2 = ptX + width - jsMax(topRight, bottomRight) - caretSize;
      } else {
        x2 = caretX;
      }

      if (yAlign == 'top') {
        y1 = ptY;
        y2 = y1 - caretSize;

        // Top draws left -> right, thus x1 is on the left
        x1 = x2 - caretSize;
        x3 = x2 + caretSize;
      } else {
        y1 = ptY + height;
        y2 = y1 + caretSize;

        // Bottom draws right -> left, thus x1 is on the right
        x1 = x2 + caretSize;
        x3 = x2 - caretSize;
      }
      y3 = y1;
    }
    return (x1: x1, x2: x2, x3: x3, y1: y1, y2: y2, y3: y3);
  }

  /// plugin.tooltip.js:756 `drawTitle(pt, ctx, options)`.
  void drawTitle(
    TooltipPoint pt,
    CanvasRenderingContext2D ctx,
    TooltipOptions options,
  ) {
    final title = this.title!;
    final length = title.length;
    int i;

    if (length != 0) {
      final rtlHelper = getRtlAdapter(options.rtl, x, width);

      pt.x = _getAlignedX(this, options.titleAlign, options);

      ctx
        ..textAlign = canvasKeyword(rtlHelper.textAlign(options.titleAlign))
        ..textBaseline = 'middle';

      final titleFont = toFont(options.titleFont);
      final titleSpacing = jsToNumber(options.titleSpacing);

      ctx
        ..fillStyle = canvasStyle(options.titleColor)
        ..font = titleFont.string;

      for (i = 0; i < length; ++i) {
        ctx.fillText(
          jsToString(title[i]),
          rtlHelper.x(pt.x),
          pt.y + titleFont.lineHeight / 2,
        );
        pt.y += titleFont.lineHeight + titleSpacing; // Line Height and spacing

        if (i + 1 == length) {
          // If Last, add margin, remove spacing
          pt.y += jsToNumber(options.titleMarginBottom) - titleSpacing;
        }
      }
    }
  }

  /// plugin.tooltip.js:789 `_drawColorBox(ctx, pt, i, rtlHelper, options)`.
  void _drawColorBox(
    CanvasRenderingContext2D ctx,
    TooltipPoint pt,
    int i,
    RTLAdapter rtlHelper,
    TooltipOptions options,
  ) {
    final labelColor = _LabelStyleView(
      jsGetIndex(_labelColors ?? undefined, i.toDouble()),
    );
    final labelPointStyle = _PointStyleView(
      jsGetIndex(_labelPointStyles ?? undefined, i.toDouble()),
    );
    final boxHeight = jsToNumber(options.boxHeight);
    final boxWidth = jsToNumber(options.boxWidth);
    final bodyFont = toFont(options.bodyFont);
    final colorX = _getAlignedX(this, 'left', options);
    final rtlColorX = rtlHelper.x(colorX);
    final yOffSet = boxHeight < bodyFont.lineHeight
        ? (bodyFont.lineHeight - boxHeight) / 2
        : 0;
    final colorY = pt.y + yOffSet;

    if (jsTruthy(options.usePointStyle)) {
      final drawOptions = PointOptions()
        // fit the circle in the box
        ..storeKey(OptionKey.radius, jsMin(boxWidth, boxHeight) / 2)
        ..storeKey(OptionKey.pointStyle, labelPointStyle.pointStyle)
        ..storeKey(OptionKey.rotation, labelPointStyle.rotation)
        ..storeKey(OptionKey.borderWidth, 1.0);
      // Recalculate x and y for drawPoint() because its expecting
      // x and y to be center of figure (instead of top left)
      final centerX = rtlHelper.leftForLtr(rtlColorX, boxWidth) + boxWidth / 2;
      final centerY = colorY + boxHeight / 2;

      // Fill the point with white so that colours merge nicely if the
      // opacity is < 1
      ctx
        ..strokeStyle = canvasStyle(options.multiKeyBackground)
        ..fillStyle = canvasStyle(options.multiKeyBackground);
      drawPoint(ctx, drawOptions, centerX, centerY);

      // Draw the point
      ctx
        ..strokeStyle = canvasStyle(labelColor.borderColor)
        ..fillStyle = canvasStyle(labelColor.backgroundColor);
      drawPoint(ctx, drawOptions, centerX, centerY);
    } else {
      // Border
      final borderWidth = labelColor.borderWidth;
      ctx
        ..lineWidth = canvasNumber(
          isObject(borderWidth)
              ? _maxOfValues(borderWidth! as AnyObject)
              // TODO(chartjs): v4 remove fallback
              : (jsTruthy(borderWidth) ? borderWidth : 1.0),
        )
        ..strokeStyle = canvasStyle(labelColor.borderColor);
      final borderDash = labelColor.borderDash;
      ctx.setLineDash(
        canvasLineDash(jsTruthy(borderDash) ? borderDash : <Object?>[]),
      );
      final borderDashOffset = labelColor.borderDashOffset;
      ctx.lineDashOffset = canvasNumber(
        jsTruthy(borderDashOffset) ? borderDashOffset : 0.0,
      );

      // Fill a white rect so that colours merge nicely if the opacity is < 1
      final outerX = rtlHelper.leftForLtr(rtlColorX, boxWidth);
      final innerX = rtlHelper.leftForLtr(
        rtlHelper.xPlus(rtlColorX, 1),
        boxWidth - 2,
      );
      final borderRadius = toTRBLCorners(labelColor.borderRadius);

      // `Object.values(borderRadius).some(v => v !== 0)`: the four corners.
      if (borderRadius.topLeft != 0 ||
          borderRadius.topRight != 0 ||
          borderRadius.bottomLeft != 0 ||
          borderRadius.bottomRight != 0) {
        ctx
          ..beginPath()
          ..fillStyle = canvasStyle(options.multiKeyBackground);
        addRoundedRectPath(
          ctx,
          _RoundedRect(
            x: outerX,
            y: colorY,
            w: boxWidth,
            h: boxHeight,
            radius: borderRadius,
          ),
        );
        ctx
          ..fill()
          ..stroke()
          // Inner square
          ..fillStyle = canvasStyle(labelColor.backgroundColor)
          ..beginPath();
        addRoundedRectPath(
          ctx,
          _RoundedRect(
            x: innerX,
            y: colorY + 1,
            w: boxWidth - 2,
            h: boxHeight - 2,
            radius: borderRadius,
          ),
        );
        ctx.fill();
      } else {
        // Normal rect
        ctx
          ..fillStyle = canvasStyle(options.multiKeyBackground)
          ..fillRect(outerX, colorY, boxWidth, boxHeight)
          ..strokeRect(outerX, colorY, boxWidth, boxHeight)
          // Inner square
          ..fillStyle = canvasStyle(labelColor.backgroundColor)
          ..fillRect(innerX, colorY + 1, boxWidth - 2, boxHeight - 2);
      }
    }

    // restore fillStyle
    ctx.fillStyle = canvasStyle(
      jsGetIndex(_labelTextColors ?? undefined, i.toDouble()),
    );
  }

  /// `Math.max(...Object.values(object))` (plugin.tooltip.js:822): the
  /// values in the [jsObjectKeys] order, each through `ToNumber`. No value
  /// gives `-Infinity`. The object is the `borderWidth` of a label color of
  /// user code, read by name.
  static double _maxOfValues(AnyObject object) {
    var max = double.negativeInfinity;
    for (final key in jsObjectKeys(object)) {
      max = jsMax(max, jsToNumber(jsGet(object, key)));
    }
    return max;
  }

  /// plugin.tooltip.js:871 `drawBody(pt, ctx, options)`.
  void drawBody(
    TooltipPoint pt,
    CanvasRenderingContext2D ctx,
    TooltipOptions options,
  ) {
    final body = this.body;
    final bodySpacing = jsToNumber(options.bodySpacing);
    final bodyAlign = options.bodyAlign;
    final displayColors = options.displayColors;
    final boxHeight = jsToNumber(options.boxHeight);
    final boxWidth = jsToNumber(options.boxWidth);
    final boxPadding = jsToNumber(options.boxPadding);
    final bodyFont = toFont(options.bodyFont);
    var bodyLineHeight = bodyFont.lineHeight;
    var xLinePadding = 0.0;

    final rtlHelper = getRtlAdapter(options.rtl, x, width);

    void fillLineOfText(Object? line) {
      ctx.fillText(
        jsToString(line),
        rtlHelper.x(pt.x + xLinePadding),
        pt.y + bodyLineHeight / 2,
      );
      pt.y += bodyLineHeight + bodySpacing;
    }

    final bodyAlignForCalculation = rtlHelper.textAlign(bodyAlign);
    _BodyItem bodyItem;
    Object? textColor;
    List<Object?> lines;

    ctx
      ..textAlign = canvasKeyword(bodyAlign)
      ..textBaseline = 'middle'
      ..font = bodyFont.string;

    pt.x = _getAlignedX(this, bodyAlignForCalculation, options);

    // Before body lines
    ctx.fillStyle = canvasStyle(options.bodyColor);
    each(beforeBody, fillLineOfText);

    xLinePadding = jsTruthy(displayColors) && bodyAlignForCalculation != 'right'
        ? bodyAlign == 'center'
              ? (boxWidth / 2 + boxPadding)
              : (boxWidth + 2 + boxPadding)
        : 0;

    // Draw body lines now
    for (var i = 0, ilen = body!.length; i < ilen; ++i) {
      bodyItem = _BodyItem(body[i]);
      textColor = jsGetIndex(_labelTextColors ?? undefined, i.toDouble());

      ctx.fillStyle = canvasStyle(textColor);
      each(bodyItem.before, fillLineOfText);

      lines = bodyItem.lines! as List<Object?>;
      // Draw Legend-like boxes if needed
      if (jsTruthy(displayColors) && lines.isNotEmpty) {
        _drawColorBox(ctx, pt, i, rtlHelper, options);
        bodyLineHeight = jsMax(bodyFont.lineHeight, boxHeight);
      }

      for (var j = 0, jlen = lines.length; j < jlen; ++j) {
        fillLineOfText(lines[j]);
        // Reset for any lines that don't include colorbox
        bodyLineHeight = bodyFont.lineHeight;
      }

      each(bodyItem.after, fillLineOfText);
    }

    // Reset back to 0 for after body
    xLinePadding = 0;
    bodyLineHeight = bodyFont.lineHeight;

    // After body lines
    each(afterBody, fillLineOfText);
    pt.y -= bodySpacing; // Remove last body spacing
  }

  /// plugin.tooltip.js:935 `drawFooter(pt, ctx, options)`.
  void drawFooter(
    TooltipPoint pt,
    CanvasRenderingContext2D ctx,
    TooltipOptions options,
  ) {
    final footer = this.footer!;
    final length = footer.length;
    int i;

    if (length != 0) {
      final rtlHelper = getRtlAdapter(options.rtl, x, width);

      pt
        ..x = _getAlignedX(this, options.footerAlign, options)
        ..y += jsToNumber(options.footerMarginTop);

      ctx
        ..textAlign = canvasKeyword(rtlHelper.textAlign(options.footerAlign))
        ..textBaseline = 'middle';

      final footerFont = toFont(options.footerFont);

      ctx
        ..fillStyle = canvasStyle(options.footerColor)
        ..font = footerFont.string;

      for (i = 0; i < length; ++i) {
        ctx.fillText(
          jsToString(footer[i]),
          rtlHelper.x(pt.x),
          pt.y + footerFont.lineHeight / 2,
        );
        pt.y += footerFont.lineHeight + jsToNumber(options.footerSpacing);
      }
    }
  }

  /// plugin.tooltip.js:961 `drawBackground(pt, ctx, tooltipSize,
  /// options)`.
  void drawBackground(
    TooltipPoint pt,
    CanvasRenderingContext2D ctx,
    ({double width, double height}) tooltipSize,
    TooltipOptions options,
  ) {
    final Tooltip(:xAlign, :yAlign) = this;
    final TooltipPoint(:x, :y) = pt;
    final (:width, :height) = tooltipSize;
    final TRBLCorners(:topLeft, :topRight, :bottomLeft, :bottomRight) =
        toTRBLCorners(options.cornerRadius);
    final caretPoint = _NumberPoint(x, y);

    ctx
      ..fillStyle = canvasStyle(options.backgroundColor)
      ..strokeStyle = canvasStyle(options.borderColor)
      ..lineWidth = canvasNumber(options.borderWidth)
      ..beginPath()
      ..moveTo(x + topLeft, y);
    if (yAlign == 'top') {
      drawCaret(caretPoint, ctx, tooltipSize, options);
    }
    ctx
      ..lineTo(x + width - topRight, y)
      ..quadraticCurveTo(x + width, y, x + width, y + topRight);
    if (yAlign == 'center' && xAlign == 'right') {
      drawCaret(caretPoint, ctx, tooltipSize, options);
    }
    ctx
      ..lineTo(x + width, y + height - bottomRight)
      ..quadraticCurveTo(
        x + width,
        y + height,
        x + width - bottomRight,
        y + height,
      );
    if (yAlign == 'bottom') {
      drawCaret(caretPoint, ctx, tooltipSize, options);
    }
    ctx
      ..lineTo(x + bottomLeft, y + height)
      ..quadraticCurveTo(x, y + height, x, y + height - bottomLeft);
    if (yAlign == 'center' && xAlign == 'left') {
      drawCaret(caretPoint, ctx, tooltipSize, options);
    }
    ctx
      ..lineTo(x, y + topLeft)
      ..quadraticCurveTo(x, y, x + topLeft, y)
      ..closePath()
      ..fill();

    if (jsLessThan(0, options.borderWidth)) {
      ctx.stroke();
    }
  }

  /// plugin.tooltip.js:1006 `_updateAnimationTarget(options)`. Update x/y
  /// animation targets when _active elements are animating too
  ///
  /// `animX._to !== point.x` reads the target value of the animation with a
  /// strict equality. When only `y` animates, the null check of `animX`
  /// throws the [TypeError] of `animX._to`, as upstream.
  void _updateAnimationTarget(TooltipOptions options) {
    final chart = this.chart;
    final anims = $animations;
    final animX = anims?['x'];
    final animY = anims?['y'];
    if (animX != null || animY != null) {
      final position = _position(options, _active, _eventPosition);
      if (!jsTruthy(position)) {
        return;
      }
      final size = _size = _getTooltipSize(this, options);
      final positionAndSize = _positionAndSize(position, size);
      final alignment = _determineAlignment(chart, options, positionAndSize);
      final point = _getBackgroundPoint(
        options,
        positionAndSize,
        alignment,
        chart,
      );
      if (!_strictEquals(animX!.to, point.x) ||
          !_strictEquals(animY!.to, point.y)) {
        _xAlign = toObjectProp<String>('xAlign', alignment.xAlign);
        _yAlign = toObjectProp<String>('yAlign', alignment.yAlign);
        _width = size.width;
        _height = size.height;
        _caretX = toNumberProp('caretX', _readX(position));
        _caretY = toNumberProp('caretY', _readY(position));
        _resolveAnimations().update(this, <String, Object?>{
          'x': point.x,
          'y': point.y,
        });
      }
    }
  }

  /// plugin.tooltip.js:1036 `_willRender()`. Determine if the tooltip will
  /// draw anything. @returns {boolean} True if the tooltip will render
  ///
  /// Only the plugin Map of this library reads it.
  bool _willRender() {
    return jsTruthy(_opacity ?? undefined);
  }

  /// plugin.tooltip.js:1040 `draw(ctx)`.
  ///
  /// The draw order of upstream: the background, the title, the body and
  /// the footer, between `save` and `restore`. The direction override reads
  /// the option `textDirection` by name: an absent key of plain options is
  /// [undefined], which `restoreTextDirection` ignores.
  void draw(CanvasRenderingContext2D ctx) {
    final options = _resolveOptions();
    var opacity = _opacity ?? double.nan;

    if (!jsTruthy(opacity)) {
      return;
    }

    _updateAnimationTarget(options);

    final tooltipSize = (width: width, height: height);
    final pt = TooltipPoint(x, y);

    // IE11/Edge does not like very small opacities, so snap to 0
    opacity = opacity.abs() < 1e-3 ? 0 : opacity;

    final padding = toPadding(options.padding);

    // Truthy/falsey value for empty tooltip
    final hasTooltipContent =
        title!.isNotEmpty ||
        beforeBody!.isNotEmpty ||
        body!.isNotEmpty ||
        afterBody!.isNotEmpty ||
        footer!.isNotEmpty;

    if (jsTruthy(options.enabled) && hasTooltipContent) {
      ctx
        ..save()
        ..globalAlpha = opacity;

      // Draw Background
      drawBackground(pt, ctx, tooltipSize, options);

      overrideTextDirection(ctx, options.textDirection);

      pt.y += padding.top;

      // Titles
      drawTitle(pt, ctx, options);

      // Body
      drawBody(pt, ctx, options);

      // Footer
      drawFooter(pt, ctx, options);

      restoreTextDirection(ctx, options.textDirection);

      ctx.restore();
    }
  }

  /// plugin.tooltip.js:1097 `getActiveElements()`. Get active elements in
  /// the tooltip. @returns {Array} Array of elements that are active in the
  /// tooltip
  @override
  List<types.ActiveElement> getActiveElements() {
    return _active;
  }

  /// plugin.tooltip.js:1106 `setActiveElements(activeElements,
  /// eventPosition)`. Set active elements in the tooltip
  /// @param {array} activeElements Array of active datasetIndex/index pairs.
  /// @param {object} eventPosition Synthetic event position used in
  /// positioning
  ///
  /// An item is a `types.ActiveDataPoint` or a Map `{datasetIndex, index}`
  /// of user code, read by name as `Chart.setActiveElements` reads it.
  /// `getDatasetMeta` always gives a meta, so the throw of :1112 cannot
  /// occur.
  @override
  void setActiveElements(
    List<Object?> activeElements, [
    Object? eventPosition = undefined,
  ]) {
    final lastActive = _active;
    final active = activeElements.map<types.ActiveElement>((item) {
      final double datasetIndex;
      final double index;
      if (item is types.ActiveDataPoint) {
        datasetIndex = item.datasetIndex;
        index = item.index;
      } else {
        // DIVERGES(chartjs): adapt-active-elements-number-index, a number.
        datasetIndex = jsToNumber(jsGet(item, 'datasetIndex'));
        index = jsToNumber(jsGet(item, 'index'));
      }
      final meta = chart.getDatasetMeta(datasetIndex);

      // `if (!meta) throw new Error('Cannot find a dataset at index ' + ...)`:
      // getDatasetMeta always gives a meta.

      return _ActiveElement(
        datasetIndex: datasetIndex,
        element: _elementAt(meta.data, index),
        index: index,
      );
    }).toList();
    final changed = !elementsEqual(lastActive, active);
    final positionChanged = _positionChanged(active, eventPosition);

    if (changed || positionChanged) {
      _active = active;
      _eventPosition = eventPosition;
      _ignoreReplayEvents = true;
      update(true);
    }
  }

  /// plugin.tooltip.js:1139 `handleEvent(e, replay, inChartArea = true)`.
  ///
  /// Handle an event
  /// @param {ChartEvent} e - The event to handle
  /// @param {boolean} [replay] - This is a replayed event (from update)
  /// @param {boolean} [inChartArea] - The event is inside chartArea
  /// @returns {boolean} true if the tooltip changed
  ///
  /// The default of [inChartArea] applies to [undefined] only, as the JS
  /// default parameter. [replay] is read with ToBoolean, and the call of
  /// [update] gets it as it is.
  bool handleEvent(
    types.ChartEvent e, [
    Object? replay = undefined,
    Object? inChartArea = undefined,
  ]) {
    final chartArea = identical(inChartArea, undefined) ? true : inChartArea;
    if (jsTruthy(replay) && jsTruthy(_ignoreReplayEvents ?? undefined)) {
      return false;
    }
    _ignoreReplayEvents = false;

    final options = TooltipOptions(this.options ?? undefined);
    final lastActive = _active;
    final active = _getActiveElements(e, lastActive, replay, chartArea);

    // When there are multiple items shown, but the tooltip position is
    // nearest mode an update may need to be made because our position may
    // have changed even though the items are the same as before.
    final positionChanged = _positionChanged(active, e);

    // Remember Last Actives
    final changed =
        jsTruthy(replay) ||
        !elementsEqual(active, lastActive) ||
        positionChanged;

    // Only handle target event on tooltip change
    if (changed) {
      _active = active;

      if (jsTruthy(options.enabled) || jsTruthy(options.external)) {
        _eventPosition = TooltipPosition()
          ..x = e.x
          ..y = e.y;

        update(true, replay);
      }
    }

    return changed;
  }

  /// plugin.tooltip.js:1183 `_getActiveElements(e, lastActive, replay,
  /// inChartArea)`.
  ///
  /// Helper for determining the active elements for event
  ///
  /// The result of `getElementsAtEventForMode` can be a covariant
  /// `List<InteractionItem>`: `options.reverse` reverses it in place, with
  /// the items of the same list.
  List<types.ActiveElement> _getActiveElements(
    types.ChartEvent e,
    List<types.ActiveElement> lastActive,
    Object? replay,
    Object? inChartArea,
  ) {
    final options = TooltipOptions(this.options ?? undefined);

    if (e.type == 'mouseout') {
      return [];
    }

    if (!jsTruthy(inChartArea)) {
      // Let user control the active elements outside chartArea. Eg. using
      // Legend. But make sure that active elements are still valid. The
      // datasets of the user are read by name.
      return lastActive
          .where(
            (i) =>
                jsTruthy(
                  jsGetIndex(jsGet(chart.data, 'datasets'), i.datasetIndex),
                ) &&
                !identical(
                  chart
                      .getDatasetMeta(i.datasetIndex)
                      .controller!
                      .getParsed(i.index),
                  undefined,
                ),
          )
          .toList();
    }

    // Find Active Elements for tooltips
    final active = chart.getElementsAtEventForMode(
      e,
      options.mode,
      options.object,
      replay is bool ? replay : (jsTruthy(replay) ? true : null),
    );

    if (jsTruthy(options.reverse)) {
      _reverseInPlace(active);
    }

    return active;
  }

  /// plugin.tooltip.js:1216 `_positionChanged(active, e)`.
  ///
  /// Determine if the active elements + event combination changes the
  /// tooltip position
  /// @param {array} active - Active elements
  /// @param {ChartEvent} e - Event that triggered the position change
  /// @returns {boolean} True if the position has changed
  bool _positionChanged(List<types.ActiveElement> active, Object? e) {
    final caretX = _caretX ?? undefined;
    final caretY = _caretY ?? undefined;
    final position = _position(TooltipOptions(options ?? undefined), active, e);
    return !identical(position, false) &&
        (!_strictEquals(caretX, _readX(position)) ||
            !_strictEquals(caretY, _readY(position)));
  }

  /// The JS property read `tooltip[prop]` (Chart.js ADR 0039, section 2).
  ///
  /// The 24 names of the class give their stored value, or [undefined] in
  /// the `undefined` state. Other names go to [Element].
  @override
  Object? operator [](String prop) => switch (prop) {
    'opacity' => _opacity ?? undefined,
    'width' => _width ?? undefined,
    'height' => _height ?? undefined,
    'caretX' => _caretX ?? undefined,
    'caretY' => _caretY ?? undefined,
    'xAlign' => _xAlign ?? undefined,
    'yAlign' => _yAlign ?? undefined,
    'title' => _title ?? undefined,
    'beforeBody' => _beforeBody ?? undefined,
    'body' => _body ?? undefined,
    'afterBody' => _afterBody ?? undefined,
    'footer' => _footer ?? undefined,
    'dataPoints' => _dataPoints ?? undefined,
    'labelColors' => _labelColors ?? undefined,
    'labelPointStyles' => _labelPointStyles ?? undefined,
    'labelTextColors' => _labelTextColors ?? undefined,
    'chart' => chart,
    '_active' => _active,
    '_eventPosition' => _eventPosition,
    '_size' => _size ?? undefined,
    '_cachedAnimations' => _cachedAnimations ?? undefined,
    '_tooltipItems' => _tooltipItems,
    r'$context' => _context ?? undefined,
    '_ignoreReplayEvents' => _ignoreReplayEvents ?? undefined,
    _ => super[prop],
  };

  /// The JS property write `tooltip[prop] = value` (Chart.js ADR 0039,
  /// section 2).
  ///
  /// Throws an [ArgumentError] for a value outside the type of the property
  /// (Chart.js ADR 0017, section 5): for example `xAlign: 5`, `title: 'a'`,
  /// `chart: undefined`, `_active: undefined`.
  @override
  void operator []=(String prop, Object? value) {
    switch (prop) {
      case 'opacity':
        _opacity = toNumberProp(prop, value);
      case 'width':
        _width = toNumberProp(prop, value);
      case 'height':
        _height = toNumberProp(prop, value);
      case 'caretX':
        _caretX = toNumberProp(prop, value);
      case 'caretY':
        _caretY = toNumberProp(prop, value);
      case 'xAlign':
        _xAlign = toObjectProp<String>(prop, value);
      case 'yAlign':
        _yAlign = toObjectProp<String>(prop, value);
      case 'title':
        _title = toObjectProp<List<Object?>>(prop, value);
      case 'beforeBody':
        _beforeBody = toObjectProp<List<Object?>>(prop, value);
      case 'body':
        _body = toObjectProp<List<Object?>>(prop, value);
      case 'afterBody':
        _afterBody = toObjectProp<List<Object?>>(prop, value);
      case 'footer':
        _footer = toObjectProp<List<Object?>>(prop, value);
      case 'dataPoints':
        _dataPoints = toObjectProp<List<Object?>>(prop, value);
      case 'labelColors':
        _labelColors = toObjectProp<List<Object?>>(prop, value);
      case 'labelPointStyles':
        _labelPointStyles = toObjectProp<List<Object?>>(prop, value);
      case 'labelTextColors':
        _labelTextColors = toObjectProp<List<Object?>>(prop, value);
      case 'chart':
        chart = switch (value) {
          final types.Chart chart => chart,
          _ => throw ArgumentError.value(value, prop, 'Not a Chart'),
        };
      case '_active':
        _active = switch (value) {
          final List<types.ActiveElement> active => active,
          _ => throw ArgumentError.value(
            value,
            prop,
            'Not a List<ActiveElement>',
          ),
        };
      case '_eventPosition':
        _eventPosition = value;
      case '_size':
        _size = toObjectProp<({double width, double height})>(prop, value);
      case '_cachedAnimations':
        _cachedAnimations = toObjectProp<Animations>(prop, value);
      case '_tooltipItems':
        _tooltipItems = switch (value) {
          final List<Object?> items => items,
          _ => throw ArgumentError.value(value, prop, 'Not a List'),
        };
      case r'$context':
        _context = toObjectProp<AnyObject>(prop, value);
      case '_ignoreReplayEvents':
        _ignoreReplayEvents = toBoolProp(prop, value);
      default:
        super[prop] = value;
    }
  }
}

/// The `config` of `new Tooltip(config)` from the arguments [args] of the
/// `construct` closure of [Tooltip.jsClass]: the reads `config.chart` and
/// `config.options` of plugin.tooltip.js:475-476.
///
/// An absent argument, [undefined] and JS `null` throw the [TypeError] of
/// the read `config.chart`, as upstream. A member with the value
/// [undefined] gives Dart `null`. A `chart` that is not a `types.Chart` and
/// an `options` that is not a Map throw a [TypeError]. Upstream stores such
/// a value and reads its members later.
// DIVERGES(chartjs): adapt-component-class-role, a non-Chart chart throws.
({types.Chart chart, AnyObject? options}) _tooltipConfig(List<Object?> args) {
  final config = args.isEmpty ? undefined : args[0];
  return (
    chart: _orNull(jsGet(config, 'chart'))! as types.Chart,
    options: _orNull(jsGet(config, 'options')) as AnyObject?,
  );
}

/// Dart `null` for the [undefined] sentinel, else [value].
Object? _orNull(Object? value) => identical(value, undefined) ? null : value;

/// plugin.tooltip.js:1303-1304 the default `boxHeight` and `boxWidth`:
/// `(ctx, opts) => opts.bodyFont.size`, the typed reads of the sub-resolver.
Object? _bodyFontSize(Object? ctx, Object? opts) =>
    optionOf(TooltipOptions(opts).bodyFont, OptionKey.size);

/// plugin.tooltip.js:1334 the `_scriptable` descriptor of the plugin.
bool _scriptableDescriptor(String name) =>
    name != 'filter' && name != 'itemSort' && name != 'external';

/// plugin.tooltip.js:1228 `afterInit(chart, _args, options)`.
void _afterInit(types.Chart chart, AnyObject _, AnyObject options) {
  if (jsTruthy(options)) {
    chart.tooltip = Tooltip((chart: chart, options: options));
  }
}

/// plugin.tooltip.js:1234 `beforeUpdate(chart, _args, options)`.
void _beforeUpdate(types.Chart chart, AnyObject _, AnyObject options) {
  if (chart.tooltip != null) {
    (chart.tooltip! as Tooltip).initialize(options);
  }
}

/// plugin.tooltip.js:1240 `reset(chart, _args, options)`.
void _reset(types.Chart chart, AnyObject _, AnyObject options) {
  if (chart.tooltip != null) {
    (chart.tooltip! as Tooltip).initialize(options);
  }
}

/// plugin.tooltip.js:1246 `afterDraw(chart)`. A `beforeTooltipDraw` hook
/// that returns false cancels the draw and `afterTooltipDraw`. The args
/// are [TooltipDrawHookArgs]: `{...args, cancelable: true}` is a new object
/// with the keys of `args` and `cancelable`, and `afterTooltipDraw` gets
/// `args` itself.
void _afterDraw(types.Chart chart, AnyObject _, AnyObject _) {
  final tooltip = chart.tooltip as Tooltip?;

  if (tooltip != null && tooltip._willRender()) {
    final args = TooltipDrawHookArgs(tooltip: tooltip);

    if (chart.notifyPlugins(
          'beforeTooltipDraw',
          TooltipDrawHookArgs(tooltip: args.tooltip, cancelable: true),
        ) ==
        false) {
      return;
    }

    tooltip.draw(chart.ctx!);

    chart.notifyPlugins('afterTooltipDraw', args);
  }
}

/// plugin.tooltip.js:1264 `afterEvent(chart, args)`: the typed `replay`,
/// `event` and `inChartArea` of [EventHookArgs], and the typed write of
/// `changed`. An event of Dart `null` throws the [TypeError] of the null
/// check, as `handleEvent` throws at `e.type` of `undefined` upstream.
void _afterEvent(types.Chart chart, EventHookArgs args, AnyObject _) {
  if (chart.tooltip != null) {
    // If the event is replayed from `update`, we should evaluate with the
    // final positions.
    final useFinalPosition = args.replay;
    if ((chart.tooltip! as Tooltip).handleEvent(
      args.event!,
      useFinalPosition,
      args.inChartArea,
    )) {
      // notify chart about the change, so it will render
      args.changed = true;
    }
  }
}

/// plugin.tooltip.js:1223 the default export, `Tooltip` of
/// `src/plugins/index.js:7` (Chart.js ADR 0038, section 1).
///
/// A typed [Plugin] with the upstream keys in the upstream order.
final Plugin tooltip = Plugin()
  ..id = 'tooltip'
  ..jsWrite('_element', Tooltip.jsClass)
  ..jsWrite('positioners', _positioners)
  ..afterInit = _afterInit
  ..beforeUpdate = _beforeUpdate
  ..reset = _reset
  ..afterDraw = _afterDraw
  ..afterEvent = _afterEvent
  // plugin.tooltip.js:1275-1325. A typed scope of the kind `TooltipOptions`
  // (Chart.js ADR 0054 §3).
  ..defaults = (TooltipOptionsScope()
    ..enabled = true
    ..externalCell = optNull
    ..position = 'average'
    ..backgroundColor = 'rgba(0,0,0,0.8)'
    ..titleColor = '#fff'
    ..titleFont = (FontSpecScope()..weight = 'bold')
    ..titleSpacing = 2.0
    ..titleMarginBottom = 6.0
    ..titleAlign = 'left'
    ..bodyColor = '#fff'
    ..bodySpacing = 2.0
    ..bodyFont = FontSpecScope()
    ..bodyAlign = 'left'
    ..footerColor = '#fff'
    ..footerSpacing = 2.0
    ..footerMarginTop = 6.0
    ..footerFont = (FontSpecScope()..weight = 'bold')
    ..footerAlign = 'left'
    ..padding = 6.0
    ..caretPadding = 2.0
    ..caretSize = 5.0
    ..cornerRadius = 6.0
    ..boxHeightCell = const OptFunction<double>(_bodyFontSize)
    ..boxWidthCell = const OptFunction<double>(_bodyFontSize)
    ..multiKeyBackground = '#fff'
    ..displayColors = true
    ..boxPadding = 0.0
    ..borderColor = 'rgba(0,0,0,0)'
    ..borderWidth = 0.0
    ..animation = (AnimationOptionsScope()
      ..duration = 400.0
      ..easing = 'easeOutQuart')
    ..animations = (AnimationsSpecScope()
      ..numbers = (AnimationOptionsScope()
        ..type = 'number'
        ..properties = <Object?>[
          'x',
          'y',
          'width',
          'height',
          'caretX',
          'caretY',
        ])
      ..opacity = (AnimationOptionsScope()
        ..easing = 'linear'
        ..duration = 200.0))
    ..callbacks = _defaultCallbacks)
  // plugin.tooltip.js:1327-1331.
  ..defaultRoutes = <String, Object?>{
    'bodyFont': 'font',
    'footerFont': 'font',
    'titleFont': 'font',
  }
  // plugin.tooltip.js:1333-1346. A typed scope of the kind `Descriptors`.
  ..descriptors = (DescriptorsScope()
    ..descScriptable = _scriptableDescriptor
    ..descIndexable = false
    ..jsWrite(
      'callbacks',
      DescriptorsScope()
        ..descScriptable = false
        ..descIndexable = false,
    )
    ..jsWrite('animation', DescriptorsScope()..descFallback = false)
    ..jsWrite('animations', DescriptorsScope()..descFallback = 'animation'))
  // Resolve additionally from `interaction` options and defaults.
  ..additionalOptionScopes = <Object?>['interaction'];

/// A tooltip item of any class: a [TooltipItem] gives its fields, and
/// another item (a value of user code or of a spec) gives the reads by name
/// of upstream ([_readByName]).
extension type const _TooltipItemView(Object? item) {
  /// `item.chart`.
  Object? get chart => switch (item) {
    final TooltipItem typed => typed.chart,
    _ => _readByName(item, 'chart'),
  };

  /// `item.label`.
  Object? get label => switch (item) {
    final TooltipItem typed => typed.label,
    _ => _readByName(item, 'label'),
  };

  /// `item.formattedValue`.
  Object? get formattedValue => switch (item) {
    final TooltipItem typed => typed.formattedValue,
    _ => _readByName(item, 'formattedValue'),
  };

  /// `item.dataset`.
  Object? get dataset => switch (item) {
    final TooltipItem typed => typed.dataset,
    _ => _readByName(item, 'dataset'),
  };

  /// `item.dataIndex`.
  Object? get dataIndex => switch (item) {
    final TooltipItem typed => typed.dataIndex,
    _ => _readByName(item, 'dataIndex'),
  };

  /// `item.datasetIndex`.
  Object? get datasetIndex => switch (item) {
    final TooltipItem typed => typed.datasetIndex,
    _ => _readByName(item, 'datasetIndex'),
  };
}

/// A body item of any class: a [TooltipBodyItem] gives its fields, and
/// another value (a body of user code) gives the reads by name.
extension type const _BodyItem(Object? item) {
  /// `item.before`.
  Object? get before => switch (item) {
    final TooltipBodyItem typed => typed.before,
    _ => _readByName(item, 'before'),
  };

  /// `item.lines`.
  Object? get lines => switch (item) {
    final TooltipBodyItem typed => typed.lines,
    _ => _readByName(item, 'lines'),
  };

  /// `item.after`.
  Object? get after => switch (item) {
    final TooltipBodyItem typed => typed.after,
    _ => _readByName(item, 'after'),
  };
}

/// A label color of any class: a [TooltipLabelStyle] gives its fields, and
/// another value (the result of a `labelColor` callback of user code) gives
/// the reads by name.
extension type const _LabelStyleView(Object? style) {
  /// `style.borderColor`.
  Object? get borderColor => switch (style) {
    final TooltipLabelStyle typed => typed.borderColor,
    _ => _readByName(style, 'borderColor'),
  };

  /// `style.backgroundColor`.
  Object? get backgroundColor => switch (style) {
    final TooltipLabelStyle typed => typed.backgroundColor,
    _ => _readByName(style, 'backgroundColor'),
  };

  /// `style.borderWidth`.
  Object? get borderWidth => switch (style) {
    final TooltipLabelStyle typed => typed.borderWidth,
    _ => _readByName(style, 'borderWidth'),
  };

  /// `style.borderDash`.
  Object? get borderDash => switch (style) {
    final TooltipLabelStyle typed => typed.borderDash,
    _ => _readByName(style, 'borderDash'),
  };

  /// `style.borderDashOffset`.
  Object? get borderDashOffset => switch (style) {
    final TooltipLabelStyle typed => typed.borderDashOffset,
    _ => _readByName(style, 'borderDashOffset'),
  };

  /// `style.borderRadius`.
  Object? get borderRadius => switch (style) {
    final TooltipLabelStyle typed => typed.borderRadius,
    _ => _readByName(style, 'borderRadius'),
  };
}

/// A label point style of any class: a [TooltipLabelPointStyle] gives its
/// fields, and another value (the result of a `labelPointStyle` callback of
/// user code) gives the reads by name.
extension type const _PointStyleView(Object? style) {
  /// `style.pointStyle`.
  Object? get pointStyle => switch (style) {
    final TooltipLabelPointStyle typed => typed.pointStyle,
    _ => _readByName(style, 'pointStyle'),
  };

  /// `style.rotation`.
  Object? get rotation => switch (style) {
    final TooltipLabelPointStyle typed => typed.rotation,
    _ => _readByName(style, 'rotation'),
  };
}

/// The read by name `object[name]` of an object of user code in the place
/// of a typed tooltip object: [jsGet]. `undefined` and JS `null` throw its
/// [TypeError], as upstream.
Object? _readByName(Object? object, String name) => jsGet(object, name);

/// `TooltipItem` (`index.d.ts`): an item of the tooltip, the object of
/// `createTooltipItem` (plugin.tooltip.js:127-146), with the upstream keys
/// in the upstream key order. Each field holds any JS value: a user callback
/// reads and writes the item by name through the face, and a key that user
/// code adds is an extra (Chart.js ADR 0054 §12).
final class TooltipItem extends TypedRecord {
  /// An object without own keys.
  TooltipItem();

  static const List<String> _fieldNames = [
    'chart',
    'label',
    'parsed',
    'raw',
    'formattedValue',
    'dataset',
    'dataIndex',
    'datasetIndex',
    'element',
  ];

  @override
  List<String> get fieldNames => _fieldNames;

  @override
  int slotOf(String name) => switch (name) {
    'chart' => 0,
    'label' => 1,
    'parsed' => 2,
    'raw' => 3,
    'formattedValue' => 4,
    'dataset' => 5,
    'dataIndex' => 6,
    'datasetIndex' => 7,
    'element' => 8,
    _ => -1,
  };

  Object? _chart;

  Object? _label;

  Object? _parsed;

  Object? _raw;

  Object? _formattedValue;

  Object? _dataset;

  Object? _dataIndex;

  Object? _datasetIndex;

  Object? _element;

  /// `chart`, or [undefined] when absent.
  Object? get chart => hasSlot(0) ? _chart : undefined;

  set chart(Object? value) {
    _chart = value;
    touchSlot(0);
  }

  /// `label`, or [undefined] when absent.
  Object? get label => hasSlot(1) ? _label : undefined;

  set label(Object? value) {
    _label = value;
    touchSlot(1);
  }

  /// `parsed`, or [undefined] when absent.
  Object? get parsed => hasSlot(2) ? _parsed : undefined;

  set parsed(Object? value) {
    _parsed = value;
    touchSlot(2);
  }

  /// `raw`, or [undefined] when absent.
  Object? get raw => hasSlot(3) ? _raw : undefined;

  set raw(Object? value) {
    _raw = value;
    touchSlot(3);
  }

  /// `formattedValue`, or [undefined] when absent.
  Object? get formattedValue => hasSlot(4) ? _formattedValue : undefined;

  set formattedValue(Object? value) {
    _formattedValue = value;
    touchSlot(4);
  }

  /// `dataset`, or [undefined] when absent.
  Object? get dataset => hasSlot(5) ? _dataset : undefined;

  set dataset(Object? value) {
    _dataset = value;
    touchSlot(5);
  }

  /// `dataIndex`, or [undefined] when absent.
  Object? get dataIndex => hasSlot(6) ? _dataIndex : undefined;

  set dataIndex(Object? value) {
    _dataIndex = value;
    touchSlot(6);
  }

  /// `datasetIndex`, or [undefined] when absent.
  Object? get datasetIndex => hasSlot(7) ? _datasetIndex : undefined;

  set datasetIndex(Object? value) {
    _datasetIndex = value;
    touchSlot(7);
  }

  /// `element`, or [undefined] when absent.
  Object? get element => hasSlot(8) ? _element : undefined;

  set element(Object? value) {
    _element = value;
    touchSlot(8);
  }

  @override
  Object? readSlot(int slot) => switch (slot) {
    0 => _chart,
    1 => _label,
    2 => _parsed,
    3 => _raw,
    4 => _formattedValue,
    5 => _dataset,
    6 => _dataIndex,
    7 => _datasetIndex,
    _ => _element,
  };

  @override
  bool writeSlot(int slot, Object? value) {
    switch (slot) {
      case 0:
        _chart = value;
      case 1:
        _label = value;
      case 2:
        _parsed = value;
      case 3:
        _raw = value;
      case 4:
        _formattedValue = value;
      case 5:
        _dataset = value;
      case 6:
        _dataIndex = value;
      case 7:
        _datasetIndex = value;
      default:
        _element = value;
    }
    return true;
  }

  @override
  void clearSlot(int slot) {
    switch (slot) {
      case 0:
        _chart = null;
      case 1:
        _label = null;
      case 2:
        _parsed = null;
      case 3:
        _raw = null;
      case 4:
        _formattedValue = null;
      case 5:
        _dataset = null;
      case 6:
        _dataIndex = null;
      case 7:
        _datasetIndex = null;
      default:
        _element = null;
    }
  }
}

/// A body item `{before, lines, after}` of the tooltip (plugin.tooltip.js:
/// 557-560): the lines of one tooltip item. `index.d.ts` types it inline
/// (`TooltipModel.body`).
final class TooltipBodyItem extends TypedRecord {
  /// An object without own keys.
  TooltipBodyItem();

  static const List<String> _fieldNames = [
    'before',
    'lines',
    'after',
  ];

  @override
  List<String> get fieldNames => _fieldNames;

  @override
  int slotOf(String name) => switch (name) {
    'before' => 0,
    'lines' => 1,
    'after' => 2,
    _ => -1,
  };

  Object? _before;

  Object? _lines;

  Object? _after;

  /// `before`, or [undefined] when absent.
  Object? get before => hasSlot(0) ? _before : undefined;

  set before(Object? value) {
    _before = value;
    touchSlot(0);
  }

  /// `lines`, or [undefined] when absent.
  Object? get lines => hasSlot(1) ? _lines : undefined;

  set lines(Object? value) {
    _lines = value;
    touchSlot(1);
  }

  /// `after`, or [undefined] when absent.
  Object? get after => hasSlot(2) ? _after : undefined;

  set after(Object? value) {
    _after = value;
    touchSlot(2);
  }

  @override
  Object? readSlot(int slot) => switch (slot) {
    0 => _before,
    1 => _lines,
    _ => _after,
  };

  @override
  bool writeSlot(int slot, Object? value) {
    switch (slot) {
      case 0:
        _before = value;
      case 1:
        _lines = value;
      default:
        _after = value;
    }
    return true;
  }

  @override
  void clearSlot(int slot) {
    switch (slot) {
      case 0:
        _before = null;
      case 1:
        _lines = null;
      default:
        _after = null;
    }
  }
}

/// `TooltipLabelStyle` (`index.d.ts`): the label color of the default
/// `labelColor` callback (plugin.tooltip.js:404-414), with the upstream keys
/// in the upstream key order.
final class TooltipLabelStyle extends TypedRecord {
  /// An object without own keys.
  TooltipLabelStyle();

  static const List<String> _fieldNames = [
    'borderColor',
    'backgroundColor',
    'borderWidth',
    'borderDash',
    'borderDashOffset',
    'borderRadius',
  ];

  @override
  List<String> get fieldNames => _fieldNames;

  @override
  int slotOf(String name) => switch (name) {
    'borderColor' => 0,
    'backgroundColor' => 1,
    'borderWidth' => 2,
    'borderDash' => 3,
    'borderDashOffset' => 4,
    'borderRadius' => 5,
    _ => -1,
  };

  Object? _borderColor;

  Object? _backgroundColor;

  Object? _borderWidth;

  Object? _borderDash;

  Object? _borderDashOffset;

  Object? _borderRadius;

  /// `borderColor`, or [undefined] when absent.
  Object? get borderColor => hasSlot(0) ? _borderColor : undefined;

  set borderColor(Object? value) {
    _borderColor = value;
    touchSlot(0);
  }

  /// `backgroundColor`, or [undefined] when absent.
  Object? get backgroundColor => hasSlot(1) ? _backgroundColor : undefined;

  set backgroundColor(Object? value) {
    _backgroundColor = value;
    touchSlot(1);
  }

  /// `borderWidth`, or [undefined] when absent.
  Object? get borderWidth => hasSlot(2) ? _borderWidth : undefined;

  set borderWidth(Object? value) {
    _borderWidth = value;
    touchSlot(2);
  }

  /// `borderDash`, or [undefined] when absent.
  Object? get borderDash => hasSlot(3) ? _borderDash : undefined;

  set borderDash(Object? value) {
    _borderDash = value;
    touchSlot(3);
  }

  /// `borderDashOffset`, or [undefined] when absent.
  Object? get borderDashOffset => hasSlot(4) ? _borderDashOffset : undefined;

  set borderDashOffset(Object? value) {
    _borderDashOffset = value;
    touchSlot(4);
  }

  /// `borderRadius`, or [undefined] when absent.
  Object? get borderRadius => hasSlot(5) ? _borderRadius : undefined;

  set borderRadius(Object? value) {
    _borderRadius = value;
    touchSlot(5);
  }

  @override
  Object? readSlot(int slot) => switch (slot) {
    0 => _borderColor,
    1 => _backgroundColor,
    2 => _borderWidth,
    3 => _borderDash,
    4 => _borderDashOffset,
    _ => _borderRadius,
  };

  @override
  bool writeSlot(int slot, Object? value) {
    switch (slot) {
      case 0:
        _borderColor = value;
      case 1:
        _backgroundColor = value;
      case 2:
        _borderWidth = value;
      case 3:
        _borderDash = value;
      case 4:
        _borderDashOffset = value;
      default:
        _borderRadius = value;
    }
    return true;
  }

  @override
  void clearSlot(int slot) {
    switch (slot) {
      case 0:
        _borderColor = null;
      case 1:
        _backgroundColor = null;
      case 2:
        _borderWidth = null;
      case 3:
        _borderDash = null;
      case 4:
        _borderDashOffset = null;
      default:
        _borderRadius = null;
    }
  }
}

/// The label point style `{pointStyle, rotation}` of the default
/// `labelPointStyle` callback (plugin.tooltip.js:419-425). `index.d.ts`
/// types it inline (`TooltipCallbacks.labelPointStyle`).
final class TooltipLabelPointStyle extends TypedRecord {
  /// An object without own keys.
  TooltipLabelPointStyle();

  static const List<String> _fieldNames = [
    'pointStyle',
    'rotation',
  ];

  @override
  List<String> get fieldNames => _fieldNames;

  @override
  int slotOf(String name) => switch (name) {
    'pointStyle' => 0,
    'rotation' => 1,
    _ => -1,
  };

  Object? _pointStyle;

  Object? _rotation;

  /// `pointStyle`, or [undefined] when absent.
  Object? get pointStyle => hasSlot(0) ? _pointStyle : undefined;

  set pointStyle(Object? value) {
    _pointStyle = value;
    touchSlot(0);
  }

  /// `rotation`, or [undefined] when absent.
  Object? get rotation => hasSlot(1) ? _rotation : undefined;

  set rotation(Object? value) {
    _rotation = value;
    touchSlot(1);
  }

  @override
  Object? readSlot(int slot) => switch (slot) {
    0 => _pointStyle,
    _ => _rotation,
  };

  @override
  bool writeSlot(int slot, Object? value) {
    switch (slot) {
      case 0:
        _pointStyle = value;
      default:
        _rotation = value;
    }
    return true;
  }

  @override
  void clearSlot(int slot) {
    switch (slot) {
      case 0:
        _pointStyle = null;
      default:
        _rotation = null;
    }
  }
}

/// `TooltipPosition` (`index.d.ts`): the position `{x, y}` of a built-in
/// positioner (plugin.tooltip.js:53, :90) and the event position `{x, y}`
/// of `handleEvent` (:1173), with the optional `xAlign` and `yAlign` of a
/// position. Each field holds any JS value.
final class TooltipPosition extends TypedRecord {
  /// An object without own keys.
  TooltipPosition();

  static const List<String> _fieldNames = [
    'x',
    'y',
    'xAlign',
    'yAlign',
  ];

  @override
  List<String> get fieldNames => _fieldNames;

  @override
  int slotOf(String name) => switch (name) {
    'x' => 0,
    'y' => 1,
    'xAlign' => 2,
    'yAlign' => 3,
    _ => -1,
  };

  Object? _x;

  Object? _y;

  Object? _xAlign;

  Object? _yAlign;

  /// `x`, or [undefined] when absent.
  Object? get x => hasSlot(0) ? _x : undefined;

  set x(Object? value) {
    _x = value;
    touchSlot(0);
  }

  /// `y`, or [undefined] when absent.
  Object? get y => hasSlot(1) ? _y : undefined;

  set y(Object? value) {
    _y = value;
    touchSlot(1);
  }

  /// `xAlign`, or [undefined] when absent.
  Object? get xAlign => hasSlot(2) ? _xAlign : undefined;

  set xAlign(Object? value) {
    _xAlign = value;
    touchSlot(2);
  }

  /// `yAlign`, or [undefined] when absent.
  Object? get yAlign => hasSlot(3) ? _yAlign : undefined;

  set yAlign(Object? value) {
    _yAlign = value;
    touchSlot(3);
  }

  @override
  Object? readSlot(int slot) => switch (slot) {
    0 => _x,
    1 => _y,
    2 => _xAlign,
    _ => _yAlign,
  };

  @override
  bool writeSlot(int slot, Object? value) {
    switch (slot) {
      case 0:
        _x = value;
      case 1:
        _y = value;
      case 2:
        _xAlign = value;
      default:
        _yAlign = value;
    }
    return true;
  }

  @override
  void clearSlot(int slot) {
    switch (slot) {
      case 0:
        _x = null;
      case 1:
        _y = null;
      case 2:
        _xAlign = null;
      default:
        _yAlign = null;
    }
  }
}
