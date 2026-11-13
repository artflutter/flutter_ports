// Ported from Chart.js v4.6.1 src/plugins/plugin.tooltip.js (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-tooltip-callback-objects, native callbacks.
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.
// DIVERGES(chartjs): adapt-native-tooltip-item, native tooltip items.

/// Port of `src/plugins/plugin.tooltip.js` (Chart.js ADR 0039).
///
/// [Tooltip] is the tooltip model, the element that the plugin makes,
/// animates and keeps in `chart.tooltip`. [tooltip] is the plugin object,
/// the default export of the upstream file and `Tooltip` of
/// `src/plugins/index.js:7` (Chart.js ADR 0038, section 1). It is a typed
/// `Plugin` (Chart.js ADR 0054 §12) with the upstream keys in the upstream
/// order: `id`, `_element`, `afterInit`, `beforeUpdate`, `reset`,
/// `afterDraw`, `afterEvent`, `defaults`, `defaultRoutes`, `descriptors`
/// and `additionalOptionScopes`. It has no key `positioners`: a positioner
/// is a class ([TooltipPositioner], row `adapt-tooltip-positioner-objects`).
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
/// the reads. The tooltip items and the body items are the native
/// [types.TooltipItem] and [types.TooltipBodyItem] (row
/// `adapt-native-tooltip-item`). The label colors, the label point styles
/// and the positions of the built-in positioners are typed classes
/// ([TooltipLabelStyle], [TooltipLabelPointStyle] and [TooltipPosition]). A
/// positioner is an object of a subclass of [TooltipPositioner], the value
/// of the option `position`: [AverageTooltipPositioner] and
/// [NearestTooltipPositioner] are the two positioners of upstream, and the
/// library has no table of positioners.
///
/// Not a pure layer: it imports `core.animations`.
library;

import 'dart:ui' as ui;
import 'dart:ui' show TextAlign;

import 'package:flutter/animation.dart' show Curves;
import 'package:flutter/painting.dart' show EdgeInsets, TextStyle;
import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/core/core.animations.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/core/core.interaction.dart'
    show DatasetInteractionMode;
import 'package:flutter_chartjs_port/src/elements/element_options.dart'
    show PointOptions;
import 'package:flutter_chartjs_port/src/helpers/helpers.canvas.dart'
    show CirclePointStyle, addRoundedRectPath, drawPoint;
import 'package:flutter_chartjs_port/src/helpers/helpers.collection.dart'
    show arrayUnique;
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart'
    show OptionResolver, OptionView;
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart'
    show elementsEqual, isNullOrUndef, isObject;
import 'package:flutter_chartjs_port/src/helpers/helpers.math.dart'
    show distanceBetweenPoints, limitValue;
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show ContextObject, createContext, toFont, toTRBLCorners;
import 'package:flutter_chartjs_port/src/helpers/helpers.rtl.dart'
    show RTLAdapter, getRtlAdapter, overrideTextDirection, restoreTextDirection;
import 'package:flutter_chartjs_port/src/helpers/point_style.dart'
    show PointStyle;
import 'package:flutter_chartjs_port/src/js/js_array.dart'
    show jsObjectKeys, jsSort;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart';
import 'package:flutter_chartjs_port/src/js/js_math.dart' show jsMax, jsMin;
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart'
    show jsGet, jsGetIndex, jsIsObjectLike, jsObjectFreeze, jsObjectOrNull;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/js/js_webidl.dart'
    show canvasNumber, canvasStyle, canvasTextAlign;
import 'package:flutter_chartjs_port/src/options/opt.dart'
    show OptFunction, optNull;
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart';
import 'package:flutter_chartjs_port/src/options/scopes.g.dart'
    show
        AnimationOptionsScope,
        AnimationsSpecScope,
        DescriptorsScope,
        TooltipOptionsScope;
import 'package:flutter_chartjs_port/src/plugins/plugin_options.dart'
    show TooltipOptions, optionOf;
import 'package:flutter_chartjs_port/src/plugins/tooltip_position.dart';
import 'package:flutter_chartjs_port/src/types/align.dart'
    show TooltipXAlign, TooltipYAlign;
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/chart_paint.dart';
import 'package:flutter_chartjs_port/src/types/chart_text_style.dart';
import 'package:flutter_chartjs_port/src/types/geometric.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_chartjs_port/src/types/plugin.dart'
    show EventHookArgs, Plugin, TooltipDrawHookArgs;
import 'package:flutter_chartjs_port/src/types/tooltip_callbacks.dart';
import 'package:meta/meta.dart';

export 'package:flutter_chartjs_port/src/types/tooltip_callbacks.dart'
    show TooltipLabelPointStyle, TooltipLabelStyle;

/// plugin.tooltip.js:17 `positioners.average`: the average position of the
/// elements of the active items. The default of the option `position`.
// DIVERGES(chartjs): adapt-tooltip-positioner-objects, a positioner class.
final class const AverageTooltipPositioner() extends TooltipPositioner {
  /// The positioner.
  this;

  @override
  TooltipPosition? positionOf(
    types.TooltipModel tooltip,
    List<types.ActiveElement> items,
    Object? eventPosition,
  ) => _positionOrNull(_average(items));
}

/// plugin.tooltip.js:17 `positioners.nearest`: the tooltip position of the
/// element nearest to the event position.
// DIVERGES(chartjs): adapt-tooltip-positioner-objects, a positioner class.
final class const NearestTooltipPositioner() extends TooltipPositioner {
  /// The positioner.
  this;

  @override
  TooltipPosition? positionOf(
    types.TooltipModel tooltip,
    List<types.ActiveElement> items,
    Object? eventPosition,
  ) => _positionOrNull(_nearest(items, eventPosition));
}

/// The result of a ported positioner function as the result of
/// [TooltipPositioner.positionOf]: Dart `null` for its `false`.
TooltipPosition? _positionOrNull(Object? result) =>
    result is TooltipPosition ? result : null;

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

/// plugin.tooltip.js:21 `average(items)`: the average position of the
/// elements shown. Average mode places the tooltip at the average position
/// of the elements shown.
///
/// `new Set()` collects the x values: each value goes into a list through
/// the add step of `Set.prototype.add` (-0 becomes +0), and [arrayUnique]
/// removes the copies with SameValueZero (Chart.js ADR 0039, section 4).
/// The sum keeps the insertion order. The elements cast to [Element] at
/// `hasValue` and `tooltipPosition` (Chart.js ADR 0038, section 6).
Object? _average(List<types.ActiveElement> items) {
  if (items.isEmpty) {
    return false;
  }

  final xSet = <double>[];
  var y = 0.0;
  var count = 0;

  for (var i = 0, len = items.length; i < len; ++i) {
    final el = items[i].element;
    if (el != null && (el as Element).hasValue()) {
      final pos = el.tooltipPosition();
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
Object? _nearest(List<types.ActiveElement> items, Object? eventPosition) {
  if (items.isEmpty) {
    return false;
  }

  var x = _readX(eventPosition);
  var y = _readY(eventPosition);
  var minDistance = double.infinity;
  Element? nearestElement;

  for (var i = 0, len = items.length; i < len; ++i) {
    final el = items[i].element;
    if (el != null && (el as Element).hasValue()) {
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
        nearestElement = el;
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
final class const _NumberPoint(
  @override final double x,
  @override final double y,
) implements Point;

/// plugin.tooltip.js:127 `createTooltipItem(chart, item)`.
///
/// Private helper to create a tooltip item model
/// @param {Chart} chart
/// @param {ActiveElement} item - {element, index, datasetIndex} to create
/// the tooltip item for
/// @return new tooltip item
///
/// The item is a native [types.TooltipItem]. `label` is the List of the
/// lines of the label of `getLabelAndValue`. A meta without a controller
/// throws the [TypeError] of the null check, as the call on JS `null`
/// throws. `raw` is a read of the data of the user, by name.
types.TooltipItem _createTooltipItem(
  types.Chart chart,
  types.ActiveElement item,
) {
  final types.ActiveElement(:element, :datasetIndex, :index) = item;
  final controller = chart.getDatasetMeta(datasetIndex).controller!;
  final (:label, :value) = controller.getLabelAndValue(index);

  return types.TooltipItem(
    chart: chart,
    label: label,
    parsed: _orNull(controller.getParsed(index)),
    raw: _orNull(
      jsGetIndex(
        jsGet(
          jsGetIndex(jsGet(chart.data, 'datasets'), datasetIndex.toDouble()),
          'data',
        ),
        index.toDouble(),
      ),
    ),
    formattedValue: value,
    dataset: controller.getDataset()!,
    dataIndex: index,
    datasetIndex: datasetIndex,
    element: element,
  );
}

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

  final padding = options.padding;
  var height = padding.vertical;
  var width = 0.0;

  // Count of all lines in the body
  var combinedBodyLength = body.fold<double>(
    0,
    (count, bodyItem) =>
        count +
        bodyItem.before.length +
        bodyItem.lines.length +
        bodyItem.after.length,
  );
  combinedBodyLength += tooltip.beforeBody!.length + tooltip.afterBody!.length;

  if (titleLineCount != 0) {
    height +=
        titleLineCount * titleFont.lineHeight! +
        (titleLineCount - 1) * jsToNumber(options.titleSpacing) +
        jsToNumber(options.titleMarginBottom);
  }
  if (jsTruthy(combinedBodyLength)) {
    // Body lines may include some extra height depending on boxHeight
    final bodyLineHeight = options.displayColors
        ? jsMax(boxHeight, bodyFont.lineHeight!)
        : bodyFont.lineHeight!;
    height +=
        bodyLineItemCount * bodyLineHeight +
        (combinedBodyLength - bodyLineItemCount) * bodyFont.lineHeight! +
        (combinedBodyLength - 1) * jsToNumber(options.bodySpacing);
  }
  if (footerLineCount != 0) {
    height +=
        jsToNumber(options.footerMarginTop) +
        footerLineCount * footerFont.lineHeight! +
        (footerLineCount - 1) * jsToNumber(options.footerSpacing);
  }

  // Title width
  var widthPadding = 0.0;
  void maxLineWidth(String line) {
    width = jsMax(width, ctx.measureText(line).width + widthPadding);
  }

  ctx
    ..save()
    ..font = titleFont;
  title.forEach(maxLineWidth);

  // Body width
  ctx.font = bodyFont;
  tooltip.beforeBody!.forEach(maxLineWidth);
  tooltip.afterBody!.forEach(maxLineWidth);

  // Body lines may include some extra width due to the color box
  widthPadding = options.displayColors
      ? (boxWidth + 2 + jsToNumber(options.boxPadding))
      : 0;
  for (final bodyItem in body) {
    bodyItem.before.forEach(maxLineWidth);
    bodyItem.lines.forEach(maxLineWidth);
    bodyItem.after.forEach(maxLineWidth);
  }

  // Reset back to 0
  widthPadding = 0;

  // Footer width
  ctx.font = footerFont;
  footer.forEach(maxLineWidth);

  ctx.restore();

  // Add padding
  width += padding.horizontal;

  return (width: width, height: height);
}

/// plugin.tooltip.js:661 `Object.assign({}, position, size)`: the keys that
/// the alignment helpers read (Chart.js ADR 0039, section 5, Chart.js ADR
/// 0003).
///
/// `x` and `y` are the `ToNumber` of the position coordinates, which each
/// upstream operator applies. `xAlign` and `yAlign` are the aligns of the
/// position, Dart `null` when it has none (row `adapt-tooltip-align-enums`).
typedef _PositionAndSize = ({
  double x,
  double y,
  double width,
  double height,
  TooltipXAlign? xAlign,
  TooltipYAlign? yAlign,
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
    xAlign: copies ? _readXAlign(position) : null,
    yAlign: copies ? _readYAlign(position) : null,
  );
}

/// The JS read `position.xAlign` of a position: a [TooltipPosition] gives
/// its field, a [Point] has no key, and another value gives the align of
/// its read by name (row `adapt-tooltip-align-enums`).
// DIVERGES(chartjs): adapt-tooltip-align-enums, the enum value.
TooltipXAlign? _readXAlign(Object? position) => switch (position) {
  final TooltipPosition typed => typed.xAlign,
  Point() => null,
  _ => TooltipXAlign.of(jsGet(position, 'xAlign')),
};

/// The JS read `position.yAlign`, as [_readXAlign] reads `xAlign`.
TooltipYAlign? _readYAlign(Object? position) => switch (position) {
  final TooltipPosition typed => typed.yAlign,
  Point() => null,
  _ => TooltipYAlign.of(jsGet(position, 'yAlign')),
};

/// plugin.tooltip.js:223 `determineYAlign(chart, size)`.
// DIVERGES(chartjs): adapt-tooltip-align-enums, the enum value.
TooltipYAlign _determineYAlign(types.Chart chart, _PositionAndSize size) {
  final (:y, :height, x: _, width: _, xAlign: _, yAlign: _) = size;

  if (y < height / 2) {
    return TooltipYAlign.top;
  } else if (y > (chart.height - height / 2)) {
    return TooltipYAlign.bottom;
  }
  return TooltipYAlign.center;
}

/// plugin.tooltip.js:234 `doesNotFitWithAlign(xAlign, chart, options,
/// size)`. Upstream returns `true` or `undefined`: here `true` or `false`.
bool _doesNotFitWithAlign(
  TooltipXAlign xAlign,
  types.Chart chart,
  TooltipOptions options,
  _PositionAndSize size,
) {
  final (:x, :width, y: _, height: _, xAlign: _, yAlign: _) = size;
  final caret =
      jsToNumber(options.caretSize) + jsToNumber(options.caretPadding);
  if (xAlign == TooltipXAlign.left && x + width + caret > chart.width) {
    return true;
  }

  if (xAlign == TooltipXAlign.right && x - width - caret < 0) {
    return true;
  }
  return false;
}

/// plugin.tooltip.js:246 `determineXAlign(chart, options, size, yAlign)`.
///
/// A chart without a chart area throws the [TypeError] of the null check,
/// as the destructuring of `undefined` throws.
TooltipXAlign _determineXAlign(
  types.Chart chart,
  TooltipOptions options,
  _PositionAndSize size,
  TooltipYAlign yAlign,
) {
  final (:x, :width, y: _, height: _, xAlign: _, yAlign: _) = size;
  final chartWidth = chart.width;
  final ChartArea(:left, :right) = chart.chartArea!;
  var xAlign = TooltipXAlign.center;

  if (yAlign == TooltipYAlign.center) {
    xAlign = x <= (left + right) / 2 ? TooltipXAlign.left : TooltipXAlign.right;
  } else if (x <= width / 2) {
    xAlign = TooltipXAlign.left;
  } else if (x >= chartWidth - width / 2) {
    xAlign = TooltipXAlign.right;
  }

  if (_doesNotFitWithAlign(xAlign, chart, options, size)) {
    xAlign = TooltipXAlign.center;
  }

  return xAlign;
}

/// plugin.tooltip.js:269 `determineAlignment(chart, options, size)`.
///
/// Helper to get the alignment of a tooltip given the size
///
/// The `||` chains take the first align that is present: an align of the
/// position, of the options, else the align that the tooltip finds. A
/// value that is not an align is Dart `null` (row
/// `adapt-tooltip-align-enums`), as a falsy value falls through upstream.
// DIVERGES(chartjs): adapt-tooltip-align-enums, the enum values.
({TooltipXAlign xAlign, TooltipYAlign yAlign}) _determineAlignment(
  types.Chart chart,
  TooltipOptions options,
  _PositionAndSize size,
) {
  final yAlign = size.yAlign ?? options.yAlign ?? _determineYAlign(chart, size);

  return (
    xAlign:
        size.xAlign ??
        options.xAlign ??
        _determineXAlign(chart, options, size, yAlign),
    yAlign: yAlign,
  );
}

/// plugin.tooltip.js:278 `alignX(size, xAlign)`.
double _alignX(_PositionAndSize size, TooltipXAlign xAlign) {
  var (:x, :width, y: _, height: _, xAlign: _, yAlign: _) = size;
  if (xAlign == TooltipXAlign.right) {
    x -= width;
  } else if (xAlign == TooltipXAlign.center) {
    x -= width / 2;
  }
  return x;
}

/// plugin.tooltip.js:288 `alignY(size, yAlign, paddingAndSize)`.
double _alignY(
  _PositionAndSize size,
  TooltipYAlign yAlign,
  double paddingAndSize,
) {
  var (:y, :height, x: _, width: _, xAlign: _, yAlign: _) = size;
  if (yAlign == TooltipYAlign.top) {
    y += paddingAndSize;
  } else if (yAlign == TooltipYAlign.bottom) {
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
  ({TooltipXAlign xAlign, TooltipYAlign yAlign}) alignment,
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

  if (yAlign == TooltipYAlign.center) {
    if (xAlign == TooltipXAlign.left) {
      x += paddingAndSize;
    } else if (xAlign == TooltipXAlign.right) {
      x -= paddingAndSize;
    }
  } else if (xAlign == TooltipXAlign.left) {
    x -= jsMax(topLeft, bottomLeft) + caretSize;
  } else if (xAlign == TooltipXAlign.right) {
    x += jsMax(topRight, bottomRight) + caretSize;
  }

  return (
    x: limitValue(x, 0, chart.width - size.width),
    y: limitValue(y, 0, chart.height - size.height),
  );
}

/// plugin.tooltip.js:331 `getAlignedX(tooltip, align, options)`.
// DIVERGES(chartjs): adapt-flutter-text-align, the Flutter enum.
double _getAlignedX(Tooltip tooltip, TextAlign? align, TooltipOptions options) {
  final padding = options.padding;

  return align == TextAlign.center
      ? tooltip.x + tooltip.width / 2
      : align == TextAlign.right
      ? tooltip.x + tooltip.width - padding.right
      : tooltip.x + padding.left;
}

/// plugin.tooltip.js:348 `createTooltipContext(parent, tooltip,
/// tooltipItems)`.
ContextObject _createTooltipContext(
  Object? parent,
  Tooltip tooltip,
  List<types.TooltipItem> tooltipItems,
) {
  return createContext(parent, <String, Object?>{
    'tooltip': tooltip,
    'tooltipItems': tooltipItems,
    'type': 'tooltip',
  });
}

/// The per-item callback overlay. The dataset only participates at the
/// six per-item call sites, never in the title/body/footer group hooks.
TooltipCallbacks _callbacksFor(TooltipOptions options, types.TooltipItem item) {
  final datasetOptions = optionOf(item.dataset, OptionKey.tooltip);
  if (isNullOrUndef(datasetOptions) || datasetOptions == false) {
    return options.callbacks;
  }
  return options.callbacks.merge(
    tooltipCallbacksOf(optionOf(datasetOptions, OptionKey.callbacks)),
  );
}

bool _isDatasetMode(types.TooltipModel tooltip) =>
    TooltipOptions(tooltip.options).mode is DatasetInteractionMode;

/// plugin.tooltip.js:364 the default `title(tooltipItems)`. Args are:
/// (tooltipItems, data)
///
/// A label of one line splits at each line break, as `splitNewlines` splits
/// a string label. The labels and the datasets are data of the user, read
/// by name.
List<String> _defaultTitle(
  types.TooltipModel tooltip,
  List<types.TooltipItem> items,
) {
  if (items.isNotEmpty) {
    final item = items[0];
    final labels = jsGet(item.chart.data, 'labels');
    final labelCount = labels is List ? labels.length : 0;

    if (_isDatasetMode(tooltip)) {
      return _defaultText(jsGet(item.dataset, 'label'));
    }
    final label = item.label;
    if (label.isNotEmpty) {
      return label.length == 1 ? label[0].split('\n') : label;
    }
    if (labels is List && item.dataIndex < labelCount) {
      return _defaultText(labels[item.dataIndex]);
    }
  }

  return const [];
}

/// plugin.tooltip.js:388 the default `label(tooltipItem)`. Args are:
/// (tooltipItem, data)
///
/// In the mode `dataset`, the lines of the label join with a comma, as the
/// string form of a JS array does.
List<String> _defaultLabel(types.TooltipModel tooltip, types.TooltipItem item) {
  if (_isDatasetMode(tooltip)) {
    return ['${item.label.join(',')}: ${item.formattedValue}'];
  }

  // The dataset of the user, read by name.
  final datasetLabel = jsGet(item.dataset, 'label');
  var label = jsTruthy(datasetLabel) ? jsToString(datasetLabel) : '';

  if (label.isNotEmpty) {
    label += ': ';
  }
  label += item.formattedValue;
  return label.isEmpty ? const [] : [label];
}

/// The style of the data element of a tooltip item: the reads
/// `tooltipItem.chart.getDatasetMeta(tooltipItem.datasetIndex)` and
/// `meta.controller.getStyle(tooltipItem.dataIndex)` of
/// plugin.tooltip.js:405-406 and :420-421.
Object _styleOf(types.TooltipItem item) {
  final meta = item.chart.getDatasetMeta(item.datasetIndex);
  return meta.controller!.getStyle(item.dataIndex);
}

/// plugin.tooltip.js:404 the default `labelColor(tooltipItem)`: a
/// [TooltipLabelStyle]. The style keys are the typed reads of the options.
TooltipLabelStyle _defaultLabelColor(
  types.TooltipModel tooltip,
  types.TooltipItem item,
) {
  final options = _styleOf(item);
  final width = optionOf(options, OptionKey.borderWidth);
  final dash = optionOf(options, OptionKey.borderDash);
  return TooltipLabelStyle(
    borderColor: chartPaintOf(
      optionOf(options, OptionKey.borderColor),
      strict: false,
    ),
    backgroundColor: chartPaintOf(
      optionOf(options, OptionKey.backgroundColor),
      strict: false,
    ),
    borderWidth: isObject(width)
        ? Tooltip._maxOfValues(width!)
        : jsToNumber(jsTruthy(width) ? width : 1.0),
    borderDash: dash is List ? dash.map(jsToNumber).toList() : const [],
    borderDashOffset: jsOrZero(optionOf(options, OptionKey.borderDashOffset)),
  );
}

ChartPaint _defaultLabelTextColor(
  types.TooltipModel tooltip,
  types.TooltipItem item,
) => chartPaintOf(TooltipOptions(tooltip.options).bodyColor, strict: false);

TooltipLabelPointStyle _defaultLabelPointStyle(
  types.TooltipModel tooltip,
  types.TooltipItem item,
) {
  final options = _styleOf(item);
  final style = optionOf(options, OptionKey.pointStyle);
  return style == false
      ? const TooltipLabelPointStyle.hidden()
      : TooltipLabelPointStyle.draw(
          PointStyle.of(style) ?? const CirclePointStyle(),
          rotation: jsOrZero(optionOf(options, OptionKey.rotation)),
        );
}

// Only the built-in data-label boundary retains JS text normalization.
List<String> _defaultText(Object? value) {
  if (!jsTruthy(value)) return const [];
  if (value is List) return value.map(jsToString).toList();
  return jsToString(value).split('\n');
}

List<String> _emptyItems(
  types.TooltipModel tooltip,
  List<types.TooltipItem> items,
) => const [];
List<String> _emptyItem(types.TooltipModel tooltip, types.TooltipItem item) =>
    const [];

/// The 14 built-in callbacks in their upstream declaration order.
const TooltipCallbacks _defaultCallbacks = TooltipCallbacks(
  beforeTitle: _emptyItems,
  title: _defaultTitle,
  afterTitle: _emptyItems,
  beforeBody: _emptyItems,
  beforeLabel: _emptyItem,
  label: _defaultLabel,
  labelColor: _defaultLabelColor,
  labelTextColor: _defaultLabelTextColor,
  labelPointStyle: _defaultLabelPointStyle,
  afterLabel: _emptyItem,
  afterBody: _emptyItems,
  beforeFooter: _emptyItems,
  footer: _emptyItems,
  afterFooter: _emptyItems,
);

/// The JS operator `===` on two raw values: two numbers compare by value
/// (NaN is not equal to itself, and -0 equals +0), two strings by their
/// code units, and other values by identity (Chart.js ADR 0039, Open 3).
bool _strictEquals(Object? a, Object? b) {
  if (a is num && b is num) return a.toDouble() == b.toDouble();
  if (a is String && b is String) return a == b;
  return identical(a, b);
}

/// The element `meta.data[index]`, or Dart `null` for JS `undefined`.
types.Element? _elementAt(List<types.Element> data, int index) =>
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
final class TooltipPoint(
  /// `pt.x`.
  var double x,

  /// `pt.y`.
  var double y,
) {
  /// The literal `{x: this.x, y: this.y}` of :1054-1057.
  this;
}

/// The rounded box of a color box (:835-841, :848-854), the object literal
/// `{x, y, w, h, radius}` of the `addRoundedRectPath` call.
final class _RoundedRect({
  @override required final double x,
  @override required final double y,
  @override required final double w,
  @override required final double h,
  @override required final TRBLCorners radius,
}) implements RoundedRect;

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
class Tooltip(({types.Chart chart, Object? options}) config)
    extends Element
    implements types.TooltipModel {
  /// plugin.tooltip.js:464 `constructor(config)`.
  ///
  /// The upstream `config` object is a record (Chart.js ADR 0038, section
  /// 4). The `construct` closure of [jsClass] reads it from a JS value. The
  /// start values follow the upstream order (:467-495). The other
  /// properties start in the `undefined` state.
  this {
    _opacity = 0;
    _active = [];
    _tooltipItems = [];
    options = config.options;
  }

  /// plugin.tooltip.js:457 `class Tooltip` as a value (Chart.js ADR 0020,
  /// section 3).
  ///
  /// Its superclass is [Element.jsClass]. It has no static `positioners`
  /// (plugin.tooltip.js:462): a positioner is a class, and no table maps a
  /// name to a positioner (row `adapt-tooltip-positioner-objects`). Its
  /// `construct` reads the `config` argument with [_tooltipConfig].
  static final JsClass jsClass = JsClass(
    'Tooltip',
    superclass: Element.jsClass,
    construct: (newTarget, args) => Tooltip(_tooltipConfig(args)),
  );

  /// plugin.tooltip.js:475 `chart`. Not final: the access by name writes it
  /// (Chart.js ADR 0039, section 2).
  @override
  types.Chart chart = config.chart;

  double? _opacity;
  double? _width;
  double? _height;
  double? _caretX;
  double? _caretY;
  TooltipXAlign? _xAlign;
  TooltipYAlign? _yAlign;
  List<types.TooltipItem>? _dataPoints;
  List<String>? _title;
  List<String>? _beforeBody;
  List<types.TooltipBodyItem>? _body;
  List<String>? _afterBody;
  List<String>? _footer;
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
  List<types.TooltipItem> _tooltipItems = const [];

  /// plugin.tooltip.js:474 `$context`. Dart `null` stands for JS
  /// `undefined`. The value is an object: the tooltip context, or an object
  /// that user code writes by name.
  Object? _context;

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
  TooltipXAlign? get xAlign => _xAlign;

  set xAlign(TooltipXAlign value) => _xAlign = value;

  /// plugin.tooltip.js:484 `yAlign`. Dart `null` for JS `undefined`.
  @override
  TooltipYAlign? get yAlign => _yAlign;

  set yAlign(TooltipYAlign value) => _yAlign = value;

  /// plugin.tooltip.js:477 `dataPoints`, the tooltip items. Dart `null` for
  /// JS `undefined`.
  @override
  List<types.TooltipItem>? get dataPoints => _dataPoints;

  set dataPoints(List<types.TooltipItem> value) => _dataPoints = value;

  /// plugin.tooltip.js:478 `title`. Dart `null` for JS `undefined`.
  @override
  List<String>? get title => _title;

  set title(List<String> value) => _title = value;

  /// plugin.tooltip.js:479 `beforeBody`. Dart `null` for JS `undefined`.
  @override
  List<String>? get beforeBody => _beforeBody;

  set beforeBody(List<String> value) => _beforeBody = value;

  /// plugin.tooltip.js:480 `body`. Dart `null` for JS `undefined`.
  @override
  List<types.TooltipBodyItem>? get body => _body;

  set body(List<types.TooltipBodyItem> value) => _body = value;

  /// plugin.tooltip.js:481 `afterBody`. Dart `null` for JS `undefined`.
  @override
  List<String>? get afterBody => _afterBody;

  set afterBody(List<String> value) => _afterBody = value;

  /// plugin.tooltip.js:482 `footer`. Dart `null` for JS `undefined`.
  @override
  List<String>? get footer => _footer;

  set footer(List<String> value) => _footer = value;

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
  void initialize(Object? options) {
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
      jsCall(jsGet(options, 'setContext'), [getContext()], thisArg: options),
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
    final animation = enabled
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
  Object getContext() {
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
  /// The option holds the positioner itself. Its Dart `null` result is the
  /// `false` of an upstream positioner. A value that is not a positioner
  /// throws a [TypeError], as the `.call` of `undefined` does upstream.
  // DIVERGES(chartjs): adapt-tooltip-positioner-objects, the positioner.
  Object? _position(
    TooltipOptions options,
    List<types.ActiveElement> active,
    Object? eventPosition,
  ) {
    final positioner = options.position;
    if (positioner == null) {
      throw TypeError();
    }
    return positioner.positionOf(this, active, eventPosition) ?? false;
  }

  /// plugin.tooltip.js:533 `getTitle(context, options)`.
  List<String> getTitle(List<types.TooltipItem> items, TooltipOptions options) {
    return <String>[
      ...?options.callbacks.beforeTitle?.call(this, items),
      ...(options.callbacks.title?.call(this, items) ??
          _defaultTitle(this, items)),
      ...?options.callbacks.afterTitle?.call(this, items),
    ];
  }

  /// plugin.tooltip.js:548 `getBeforeBody`.
  List<String> getBeforeBody(
    List<types.TooltipItem> items,
    TooltipOptions options,
  ) => [...?options.callbacks.beforeBody?.call(this, items)];

  /// plugin.tooltip.js:554 `getBody`: direct calls, with dataset overlays.
  List<types.TooltipBodyItem> getBody(
    List<types.TooltipItem> items,
    TooltipOptions options,
  ) {
    final bodies = <types.TooltipBodyItem>[];
    for (final item in items) {
      final callbacks = _callbacksFor(options, item);
      bodies.add(
        types.TooltipBodyItem(
          before: <String>[...?callbacks.beforeLabel?.call(this, item)],
          lines: <String>[
            ...(callbacks.label?.call(this, item) ?? _defaultLabel(this, item)),
          ],
          after: <String>[...?callbacks.afterLabel?.call(this, item)],
        ),
      );
    }
    return bodies;
  }

  /// plugin.tooltip.js:575 `getAfterBody`.
  List<String> getAfterBody(
    List<types.TooltipItem> items,
    TooltipOptions options,
  ) => [...?options.callbacks.afterBody?.call(this, items)];

  /// plugin.tooltip.js:582 `getFooter`.
  List<String> getFooter(
    List<types.TooltipItem> items,
    TooltipOptions options,
  ) {
    return <String>[
      ...?options.callbacks.beforeFooter?.call(this, items),
      ...?options.callbacks.footer?.call(this, items),
      ...?options.callbacks.afterFooter?.call(this, items),
    ];
  }

  /// plugin.tooltip.js:600 `_createItems(options)`.
  ///
  /// `options.filter` gets the item, its index, the List of each item and
  /// the chart data. `options.itemSort` goes through [jsSort], the stable
  /// `Array.prototype.sort`. Both are typed functions, called directly.
  List<types.TooltipItem> _createItems(TooltipOptions options) {
    final active = _active;
    final data = chart.data;
    final labelColors = <Object?>[];
    final labelPointStyles = <Object?>[];
    final labelTextColors = <Object?>[];
    var tooltipItems = <types.TooltipItem>[];

    for (var i = 0, len = active.length; i < len; ++i) {
      tooltipItems.add(_createTooltipItem(chart, active[i]));
    }

    // If the user provided a filter function, use it to modify the tooltip
    // items
    final filter = options.filter;
    if (filter != null) {
      final array = tooltipItems;
      tooltipItems = [
        for (var index = 0; index < array.length; index++)
          if (filter(array[index], index, array, data)) array[index],
      ];
    }

    // If the user provided a sorting function, use it to modify the tooltip
    // items
    final itemSort = options.itemSort;
    if (itemSort != null) {
      tooltipItems = jsSort(
        tooltipItems,
        (a, b) => itemSort(a, b, data).toDouble(),
      );
    }

    // Determine styles in the upstream order, through typed callback fields.
    for (final item in tooltipItems) {
      final callbacks = _callbacksFor(options, item);
      final style =
          callbacks.labelColor?.call(this, item) ??
          _defaultLabelColor(this, item);
      labelColors.add(_withDefaultPaints(style, item));
      labelPointStyles.add(
        callbacks.labelPointStyle?.call(this, item) ??
            _defaultLabelPointStyle(this, item),
      );
      final textPaint =
          callbacks.labelTextColor?.call(this, item) ??
          _defaultLabelTextColor(this, item);
      labelTextColors.add(
        textPaint is UnchangedChartPaint
            ? _defaultLabelTextColor(this, item)
            : textPaint,
      );
    }

    _labelColors = labelColors;
    _labelPointStyles = labelPointStyles;
    _labelTextColors = labelTextColors;
    _dataPoints = tooltipItems;
    return tooltipItems;
  }

  TooltipLabelStyle _withDefaultPaints(
    TooltipLabelStyle style,
    types.TooltipItem item,
  ) {
    if (style.borderColor is! UnchangedChartPaint &&
        style.backgroundColor is! UnchangedChartPaint) {
      return style;
    }
    final baseline = _defaultLabelColor(this, item);
    ChartPaint resolved(ChartPaint value, ChartPaint fallback) =>
        value is UnchangedChartPaint
        ? (fallback is UnchangedChartPaint
              ? const ChartPaint.solid(ui.Color(0xFF000000))
              : fallback)
        : value;
    return TooltipLabelStyle(
      borderColor: resolved(style.borderColor, baseline.borderColor),
      backgroundColor: resolved(
        style.backgroundColor,
        baseline.backgroundColor,
      ),
      borderWidth: style.borderWidth,
      borderDash: style.borderDash,
      borderDashOffset: style.borderDashOffset,
      borderRadius: style.borderRadius,
    );
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
    var tooltipItems = <types.TooltipItem>[];

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

      _xAlign = alignment.xAlign;
      _yAlign = alignment.yAlign;

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
      options.external?.call(this, jsTruthy(replay));
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

    if (yAlign == TooltipYAlign.center) {
      y2 = ptY + (height / 2);

      if (xAlign == TooltipXAlign.left) {
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
      if (xAlign == TooltipXAlign.left) {
        x2 = ptX + jsMax(topLeft, bottomLeft) + caretSize;
      } else if (xAlign == TooltipXAlign.right) {
        x2 = ptX + width - jsMax(topRight, bottomRight) - caretSize;
      } else {
        x2 = caretX;
      }

      if (yAlign == TooltipYAlign.top) {
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

      // DIVERGES(chartjs): adapt-flutter-text-align, the Flutter enum.
      final titleAlign = canvasTextAlign(options.titleAlign);
      pt.x = _getAlignedX(this, titleAlign, options);

      ctx
        ..textAlign = rtlHelper.textAlign(titleAlign)
        // DIVERGES(chartjs): adapt-canvas-text-baseline-enum, the enum value.
        ..textBaseline = CanvasTextBaseline.middle;

      final titleFont = toFont(options.titleFont);
      final titleSpacing = jsToNumber(options.titleSpacing);

      ctx
        ..fillStyle = canvasStyle(options.titleColor)
        ..font = titleFont;

      for (i = 0; i < length; ++i) {
        ctx.fillText(
          jsToString(title[i]),
          rtlHelper.x(pt.x),
          pt.y + titleFont.lineHeight! / 2,
        );
        pt.y += titleFont.lineHeight! + titleSpacing; // Line Height and spacing

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
    final labelColor = _labelColors![i]! as TooltipLabelStyle;
    final labelPointStyle = _labelPointStyles![i]! as TooltipLabelPointStyle;
    final boxHeight = jsToNumber(options.boxHeight);
    final boxWidth = jsToNumber(options.boxWidth);
    final bodyFont = toFont(options.bodyFont);
    final colorX = _getAlignedX(this, TextAlign.left, options);
    final rtlColorX = rtlHelper.x(colorX);
    final yOffSet = boxHeight < bodyFont.lineHeight!
        ? (bodyFont.lineHeight! - boxHeight) / 2
        : 0;
    final colorY = pt.y + yOffSet;

    if (options.usePointStyle) {
      final drawOptions = PointOptions()
        // fit the circle in the box
        ..storeKey(OptionKey.radius, jsMin(boxWidth, boxHeight) / 2)
        ..storeKey(OptionKey.pointStyle, labelPointStyle.pointStyle ?? false)
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
        ..strokeStyle = labelColor.borderColor
        ..fillStyle = labelColor.backgroundColor;
      drawPoint(ctx, drawOptions, centerX, centerY);
    } else {
      // Border
      final borderWidth = labelColor.borderWidth;
      ctx
        ..lineWidth = borderWidth
        ..strokeStyle = labelColor.borderColor;
      final borderDash = labelColor.borderDash;
      ctx.setLineDash(borderDash);
      final borderDashOffset = labelColor.borderDashOffset;
      ctx.lineDashOffset = borderDashOffset;

      // Fill a white rect so that colours merge nicely if the opacity is < 1
      final outerX = rtlHelper.leftForLtr(rtlColorX, boxWidth);
      final innerX = rtlHelper.leftForLtr(
        rtlHelper.xPlus(rtlColorX, 1),
        boxWidth - 2,
      );
      final borderRadius = labelColor.borderRadius;

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
        ctx.fill();
        if (borderWidth != 0) ctx.stroke();
        ctx
          // Inner square
          ..fillStyle = labelColor.backgroundColor
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
          ..fillRect(outerX, colorY, boxWidth, boxHeight);
        if (borderWidth != 0) {
          ctx.strokeRect(outerX, colorY, boxWidth, boxHeight);
        }
        ctx
          // Inner square
          ..fillStyle = labelColor.backgroundColor
          ..fillRect(innerX, colorY + 1, boxWidth - 2, boxHeight - 2);
      }
    }

    // restore fillStyle
    ctx.fillStyle = _labelTextColors![i]! as ChartPaint;
  }

  /// `Math.max(...Object.values(object))` (plugin.tooltip.js:822): the
  /// values in the [jsObjectKeys] order, each through `ToNumber`. No value
  /// gives `-Infinity`. The object is the `borderWidth` of a label color of
  /// user code, read by name.
  static double _maxOfValues(Object object) {
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
    // DIVERGES(chartjs): adapt-flutter-text-align, the Flutter enum.
    final bodyAlign = canvasTextAlign(options.bodyAlign);
    final displayColors = options.displayColors;
    final boxHeight = jsToNumber(options.boxHeight);
    final boxWidth = jsToNumber(options.boxWidth);
    final boxPadding = jsToNumber(options.boxPadding);
    final bodyFont = toFont(options.bodyFont);
    var bodyLineHeight = bodyFont.lineHeight!;
    var xLinePadding = 0.0;

    final rtlHelper = getRtlAdapter(options.rtl, x, width);

    void fillLineOfText(String line) {
      ctx.fillText(
        line,
        rtlHelper.x(pt.x + xLinePadding),
        pt.y + bodyLineHeight / 2,
      );
      pt.y += bodyLineHeight + bodySpacing;
    }

    final bodyAlignForCalculation = rtlHelper.textAlign(bodyAlign);
    types.TooltipBodyItem bodyItem;
    Object? textColor;
    List<String> lines;

    ctx
      ..textAlign = bodyAlign
      // DIVERGES(chartjs): adapt-canvas-text-baseline-enum, the enum value.
      ..textBaseline = CanvasTextBaseline.middle
      ..font = bodyFont;

    pt.x = _getAlignedX(this, bodyAlignForCalculation, options);

    // Before body lines
    ctx.fillStyle = canvasStyle(options.bodyColor);
    beforeBody!.forEach(fillLineOfText);

    xLinePadding = displayColors && bodyAlignForCalculation != TextAlign.right
        ? bodyAlign == TextAlign.center
              ? (boxWidth / 2 + boxPadding)
              : (boxWidth + 2 + boxPadding)
        : 0;

    // Draw body lines now
    for (var i = 0, ilen = body!.length; i < ilen; ++i) {
      bodyItem = body[i];
      textColor = jsGetIndex(_labelTextColors ?? undefined, i.toDouble());

      ctx.fillStyle = textColor! as ChartPaint;
      bodyItem.before.forEach(fillLineOfText);

      lines = bodyItem.lines;
      // Draw Legend-like boxes if needed
      if (displayColors && lines.isNotEmpty) {
        _drawColorBox(ctx, pt, i, rtlHelper, options);
        bodyLineHeight = jsMax(bodyFont.lineHeight!, boxHeight);
      }

      for (var j = 0, jlen = lines.length; j < jlen; ++j) {
        fillLineOfText(lines[j]);
        // Reset for any lines that don't include colorbox
        bodyLineHeight = bodyFont.lineHeight!;
      }

      bodyItem.after.forEach(fillLineOfText);
    }

    // Reset back to 0 for after body
    xLinePadding = 0;
    bodyLineHeight = bodyFont.lineHeight!;

    // After body lines
    afterBody!.forEach(fillLineOfText);
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

      // DIVERGES(chartjs): adapt-flutter-text-align, the Flutter enum.
      final footerAlign = canvasTextAlign(options.footerAlign);
      pt
        ..x = _getAlignedX(this, footerAlign, options)
        ..y += jsToNumber(options.footerMarginTop);

      ctx
        ..textAlign = rtlHelper.textAlign(footerAlign)
        // DIVERGES(chartjs): adapt-canvas-text-baseline-enum, the enum value.
        ..textBaseline = CanvasTextBaseline.middle;

      final footerFont = toFont(options.footerFont);

      ctx
        ..fillStyle = canvasStyle(options.footerColor)
        ..font = footerFont;

      for (i = 0; i < length; ++i) {
        ctx.fillText(
          jsToString(footer[i]),
          rtlHelper.x(pt.x),
          pt.y + footerFont.lineHeight! / 2,
        );
        pt.y += footerFont.lineHeight! + jsToNumber(options.footerSpacing);
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
    if (yAlign == TooltipYAlign.top) {
      drawCaret(caretPoint, ctx, tooltipSize, options);
    }
    ctx
      ..lineTo(x + width - topRight, y)
      ..quadraticCurveTo(x + width, y, x + width, y + topRight);
    if (yAlign == TooltipYAlign.center && xAlign == TooltipXAlign.right) {
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
    if (yAlign == TooltipYAlign.bottom) {
      drawCaret(caretPoint, ctx, tooltipSize, options);
    }
    ctx
      ..lineTo(x + bottomLeft, y + height)
      ..quadraticCurveTo(x, y + height, x, y + height - bottomLeft);
    if (yAlign == TooltipYAlign.center && xAlign == TooltipXAlign.left) {
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
        _xAlign = alignment.xAlign;
        _yAlign = alignment.yAlign;
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
  /// the footer, between `save` and `restore`. The optional native text
  /// direction is scoped to this draw and restored in a finally block.
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

    final padding = options.padding;

    // Truthy/falsey value for empty tooltip
    final hasTooltipContent =
        title!.isNotEmpty ||
        beforeBody!.isNotEmpty ||
        body!.isNotEmpty ||
        afterBody!.isNotEmpty ||
        footer!.isNotEmpty;

    if (options.enabled && hasTooltipContent) {
      ctx
        ..save()
        ..globalAlpha = opacity;

      // Draw Background
      drawBackground(pt, ctx, tooltipSize, options);

      final originalTextDirection = overrideTextDirection(
        ctx,
        options.textDirection,
      );
      try {
        pt.y += padding.top;

        // Titles
        drawTitle(pt, ctx, options);

        // Body
        drawBody(pt, ctx, options);

        // Footer
        drawFooter(pt, ctx, options);
      } finally {
        restoreTextDirection(ctx, originalTextDirection);
        ctx.restore();
      }
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
  /// An item is an `ActiveElement` with the two indexes (row
  /// `adapt-native-active-element`), as for `Chart.setActiveElements`.
  /// `getDatasetMeta` always gives a meta, so the throw of :1112 cannot
  /// occur.
  @override
  void setActiveElements(
    List<types.ActiveElement> activeElements, [
    Object? eventPosition = undefined,
  ]) {
    final lastActive = _active;
    final active = activeElements.map((item) {
      // DIVERGES(chartjs): adapt-native-active-element, int indexes.
      final types.ActiveElement(:datasetIndex, :index) = item;
      final meta = chart.getDatasetMeta(datasetIndex);

      // `if (!meta) throw new Error('Cannot find a dataset at index ' + ...)`:
      // getDatasetMeta always gives a meta.

      return types.ActiveElement(
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

  // DIVERGES(chartjs): adapt-live-mouse-move, a held move is a real move.
  @internal
  @override
  void endIgnoredReplays() => _ignoreReplayEvents = false;

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

      if (options.enabled || options.external != null) {
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
                  jsGetIndex(
                    jsGet(chart.data, 'datasets'),
                    i.datasetIndex.toDouble(),
                  ),
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

    if (options.reverse) {
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

  /// The write by name of a List of [T] into the property [prop]: Dart
  /// `null` for [undefined], a `List<T>` as it is, and a copy of another
  /// List whose items are each a [T] (the copy that `helpers.merge` makes).
  /// Another value throws an [ArgumentError].
  static List<T>? _listProp<T>(String prop, Object? value) => switch (value) {
    Undefined() => null,
    final List<T> list => list,
    final List<Object?> list when list.every((item) => item is T) => List<T>.of(
      list.cast<T>(),
    ),
    _ => throw ArgumentError.value(value, prop, 'Not a List<$T> or undefined'),
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
      // DIVERGES(chartjs): adapt-tooltip-align-enums, the enum value.
      case 'xAlign':
        _xAlign = toObjectProp<TooltipXAlign>(prop, value);
      case 'yAlign':
        _yAlign = toObjectProp<TooltipYAlign>(prop, value);
      case 'title':
        _title = _listProp<String>(prop, value);
      case 'beforeBody':
        _beforeBody = _listProp<String>(prop, value);
      case 'body':
        _body = _listProp<types.TooltipBodyItem>(prop, value);
      case 'afterBody':
        _afterBody = _listProp<String>(prop, value);
      case 'footer':
        _footer = _listProp<String>(prop, value);
      case 'dataPoints':
        _dataPoints = _listProp<types.TooltipItem>(prop, value);
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
          final List<types.TooltipItem> items => items,
          _ => throw ArgumentError.value(
            value,
            prop,
            'Not a List<TooltipItem>',
          ),
        };
      case r'$context':
        _context = switch (value) {
          Undefined() => null,
          _ when jsIsObjectLike(value) => value,
          _ => throw ArgumentError.value(value, prop, 'Not an object'),
        };
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
/// an `options` that is not an object (a Map or a typed object) throw a
/// [TypeError]. Upstream stores such a value and reads its members later.
// DIVERGES(chartjs): adapt-component-class-role, a non-Chart chart throws.
({types.Chart chart, Object? options}) _tooltipConfig(List<Object?> args) {
  final config = args.isEmpty ? undefined : args[0];
  return (
    chart: _orNull(jsGet(config, 'chart'))! as types.Chart,
    options: jsObjectOrNull(jsGet(config, 'options')),
  );
}

/// Dart `null` for the [undefined] sentinel, else [value].
Object? _orNull(Object? value) => identical(value, undefined) ? null : value;

/// plugin.tooltip.js:1303-1304 the default `boxHeight` and `boxWidth`:
/// `(ctx, opts) => opts.bodyFont.size`, the typed reads of the sub-resolver.
///
/// The font is a `TextStyle` (row `adapt-text-style-fonts`): the size is its
/// `fontSize`.
// DIVERGES(chartjs): adapt-text-style-fonts, the size of a TextStyle.
Object? _bodyFontSize(Object? ctx, Object? opts) {
  final font = TooltipOptions(opts).bodyFont;
  return font is TextStyle ? font.fontSize ?? undefined : undefined;
}

/// plugin.tooltip.js:1334 the `_scriptable` descriptor of the plugin.
bool _scriptableDescriptor(String name) =>
    name != 'filter' && name != 'itemSort' && name != 'external';

/// plugin.tooltip.js:1228 `afterInit(chart, _args, options)`.
void _afterInit(types.Chart chart, Object _, Object options) {
  if (jsTruthy(options)) {
    chart.tooltip = Tooltip((chart: chart, options: options));
  }
}

/// plugin.tooltip.js:1234 `beforeUpdate(chart, _args, options)`.
void _beforeUpdate(types.Chart chart, Object _, Object options) {
  if (chart.tooltip != null) {
    (chart.tooltip! as Tooltip).initialize(options);
  }
}

/// plugin.tooltip.js:1240 `reset(chart, _args, options)`.
void _reset(types.Chart chart, Object _, Object options) {
  if (chart.tooltip != null) {
    (chart.tooltip! as Tooltip).initialize(options);
  }
}

/// plugin.tooltip.js:1246 `afterDraw(chart)`. A `beforeTooltipDraw` hook
/// that returns false cancels the draw and `afterTooltipDraw`. The args
/// are [TooltipDrawHookArgs]: `{...args, cancelable: true}` is a new object
/// with the keys of `args` and `cancelable`, and `afterTooltipDraw` gets
/// `args` itself.
void _afterDraw(types.Chart chart, Object _, Object _) {
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
void _afterEvent(types.Chart chart, EventHookArgs args, Object _) {
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
// DIVERGES(chartjs): adapt-incremental-data-update, partial-lifecycle opt-in.
final Plugin tooltip = Plugin(supportsDataUpdates: true)
  ..id = 'tooltip'
  ..jsWrite('_element', Tooltip.jsClass)
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
    // DIVERGES(chartjs): adapt-tooltip-positioner-objects, the positioner.
    ..position = const AverageTooltipPositioner()
    ..backgroundColor = const ChartPaint.solid(ui.Color.fromRGBO(0, 0, 0, 0.8))
    ..titleColor = const ChartPaint.solid(ui.Color.fromRGBO(255, 255, 255, 1))
    // DIVERGES(chartjs): adapt-text-style-fonts, the font is a ChartTextStyle.
    ..titleFont = const ChartTextStyle(fontWeight: ui.FontWeight.bold)
    ..titleSpacing = 2.0
    ..titleMarginBottom = 6.0
    // DIVERGES(chartjs): adapt-flutter-text-align, the Flutter enum.
    ..titleAlign = TextAlign.left
    ..bodyColor = const ChartPaint.solid(ui.Color.fromRGBO(255, 255, 255, 1))
    ..bodySpacing = 2.0
    // DIVERGES(chartjs): adapt-text-style-fonts, the font is a ChartTextStyle.
    ..bodyFont = const ChartTextStyle()
    // DIVERGES(chartjs): adapt-flutter-text-align, the Flutter enum.
    ..bodyAlign = TextAlign.left
    ..footerColor = const ChartPaint.solid(ui.Color.fromRGBO(255, 255, 255, 1))
    ..footerSpacing = 2.0
    ..footerMarginTop = 6.0
    // DIVERGES(chartjs): adapt-text-style-fonts, the font is a ChartTextStyle.
    ..footerFont = const ChartTextStyle(fontWeight: ui.FontWeight.bold)
    // DIVERGES(chartjs): adapt-flutter-text-align, the Flutter enum.
    ..footerAlign = TextAlign.left
    ..padding = const EdgeInsets.all(6)
    ..caretPadding = 2.0
    ..caretSize = 5.0
    ..cornerRadius = 6.0
    ..boxHeightCell = const OptFunction<double>(_bodyFontSize)
    ..boxWidthCell = const OptFunction<double>(_bodyFontSize)
    ..multiKeyBackground = const ChartPaint.solid(
      ui.Color.fromRGBO(255, 255, 255, 1),
    )
    ..displayColors = true
    ..boxPadding = 0.0
    ..borderColor = const ChartPaint.solid(ui.Color.fromRGBO(0, 0, 0, 0))
    ..borderWidth = 0.0
    ..animation = (AnimationOptionsScope()
      ..duration = 400.0
      // DIVERGES(chartjs): adapt-flutter-curves, the curve of the name.
      ..easing = Curves.easeOutQuart)
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
        // DIVERGES(chartjs): adapt-flutter-curves, the curve of the name.
        ..easing = Curves.linear
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
