// Ported from Chart.js v4.6.1 src/core/core.scale.js (MIT, Chart.js Contributors).

/// Port of `src/core/core.scale.js`.
///
/// [Scale] is the base class of the scales. It extends the [Element] of
/// `core.element.dart` and implements `types.Scale` of `lib/src/types`.
///
/// - Options are the typed resolver views of `helpers.config` (Chart.js ADR
///   0054 §4). [Scale.options] is the view that [Scale.init] makes with
///   `setContext`, through the facade [CoreScaleOptions] of
///   `scale_options.dart`. The scale reads an option with a getter of the
///   facade (`options.ticks.padding`), the typed read `readKey` of its
///   [OptionKey], which gives the [undefined] sentinel for an option that
///   the resolver does not resolve. A sub-object such as `options.ticks` is
///   a view too, and `setContext` of its facade gives the view with a
///   context.
/// - Numbers are `double` (Chart.js ADR 0045). An option value goes through
///   `jsToNumber` before arithmetic, through `jsAdd` in a `+` (a string
///   option joins the other operand), through `jsTruthy` for a test, and
///   through the conversions of `lib/src/js/js_webidl.dart` before a canvas
///   setter. A scale property that starts JS `undefined` and holds a number
///   starts as NaN, the `ToNumber` of `undefined`. Each upstream reader of
///   such a property gives the same result for NaN and `undefined`.
///   [Scale.labelRotation] holds any JS value, the raw `minRotation` too,
///   and starts as [undefined]. [Scale.paddingTop] and [Scale.paddingBottom]
///   hold a number or a padding that a string option joins, and start as
///   NaN.
/// - A list index is an `int`. A tick index that a context or a callback
///   gets is a `double`.
/// - Upstream `_`-prefixed members that another module reads drop the
///   underscore and carry `@internal` (Chart.js ADR 0012): [Scale.startPixel],
///   [Scale.endPixel], [Scale.reversePixels], [Scale.length],
///   [Scale.maxLength], [Scale.userMin], [Scale.userMax],
///   [Scale.suggestedMin], [Scale.cache], [Scale.range], [Scale.tickSize],
///   [Scale.resolveTickFontOptions], [Scale.maxDigits] and [Scale.layers].
///   The other `_` members keep the underscore.
/// - The object literals of upstream that another module reads have a type:
///   a tick is a [Tick], a label item is a `types.LabelItem`. The object
///   literals that only this file reads are private classes. A layer of
///   [Scale.layers] is a Map `{z, draw}`, as Chart.js ADR 0043 makes a JS
///   plain object a Map: `core.controller.js:637` writes `_idx` into it, and
///   `compare2Level` reads its keys by name.
///
/// `core.scale.js:5` imports `helpers.extras`, which is not a pure layer
/// (Chart.js ADR 0016, decision 10). Thus this library is not a pure layer.
library;

import 'dart:math' as math;

import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/core/core.scale.autoskip.dart';
import 'package:flutter_chartjs_port/src/core/scale_options.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.canvas.dart'
    show alignPixel, clipArea, measureText, renderText, unclipArea;
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart'
    show ContextProxy, OptionView, readOption;
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart'
    show
        callback,
        finiteOrDefault,
        isArray,
        isFinite,
        isNullOrUndef,
        isObject,
        valueOrDefault;
import 'package:flutter_chartjs_port/src/helpers/helpers.extras.dart'
    show alignStartEnd, toLeftRightCenter;
import 'package:flutter_chartjs_port/src/helpers/helpers.math.dart'
    show MinMax, halfPi, int16Range, limitValue, toDegrees, toRadians;
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show ScriptableScaleContext, addGrace, createContext, toFont, toPadding;
import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_math.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/js/js_webidl.dart';
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart'
    show OptionKey;
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_chartjs_port/src/types/layout.dart'
    as types
    show
        LayoutItemBeforeLayout,
        LayoutItemConfigure,
        LayoutItemPadding,
        LayoutLayer;
import 'package:meta/meta.dart';

/// core.scale.js:9 `reverseAlign`.
String? _reverseAlign(String? align) => align == 'left'
    ? 'right'
    : align == 'right'
    ? 'left'
    : align;

/// core.scale.js:10 `offsetFromEdge`.
///
/// `scale[edge]` is the edge getter of the scale for `'top'`, `'left'`,
/// `'bottom'` and `'right'`. Another position (`'chartArea'`) names no edge.
/// JavaScript reads `undefined` there, and the arithmetic gives NaN.
double _offsetFromEdge(Scale scale, Object? edge, double offset) {
  final value = switch (edge) {
    'top' => scale.top,
    'left' => scale.left,
    'bottom' => scale.bottom,
    'right' => scale.right,
    _ => double.nan,
  };
  return edge == 'top' || edge == 'left' ? value + offset : value - offset;
}

/// core.scale.js:11 `getTicksLimit`.
///
/// `maxTicksLimit || ticksLength` tests the raw option value.
double _getTicksLimit(int ticksLength, Object? maxTicksLimit) => jsMin(
  jsTruthy(maxTicksLimit) ? jsToNumber(maxTicksLimit) : ticksLength.toDouble(),
  ticksLength.toDouble(),
);

/// The JS comparison `a >= b` of two option values (ECMAScript 13.10.1:
/// `IsLessThan(a, b, true)`, then the negation of a true or false result).
///
/// `ToPrimitive` with the hint `number` keeps a string, a number, a boolean,
/// `null` and [undefined]. It gives the time value for a `DateTime` (a JS
/// `Date`) and the `ToString` for the other objects. Two strings compare by
/// their code units: `'5' >= '30'` is true. Other operands compare as
/// numbers, and NaN gives false.
bool _jsGreaterOrEqual(Object? a, Object? b) {
  if (a is num && b is num) return a >= b;
  Object? toPrimitive(Object? value) => switch (value) {
    null || Undefined() || bool() || num() || String() || DateTime() => value,
    _ => jsToString(value),
  };
  final pa = toPrimitive(a);
  final pb = toPrimitive(b);
  if (pa is String && pb is String) return pa.compareTo(pb) >= 0;
  return jsToNumber(pa) >= jsToNumber(pb);
}

/// core.scale.js:15 the typedef `Tick`:
/// `{value:number | string, label?:string, major?:boolean, $context?:any}`.
///
/// Upstream makes a tick as an object literal, for example `{value}`
/// (scale.category.js:111) or `{value, major}` (scale.time.js:188-191). The
/// port makes a [Tick]. The scales of phase 6 construct it. `buildTicks`
/// returns a list of them, and the `afterBuildTicks` callback can replace the
/// list. The value is a number (`index.d.ts:1195`).
final class Tick implements types.Tick {
  /// The object literal `{value, label, major, significand}`. Dart `null`
  /// stands for an absent key, JS `undefined`.
  Tick({required this.value, this.label, this.major, this.significand});

  /// `value`, the value of the tick.
  @override
  double value;

  /// `label`, the label that `generateTickLabels` writes
  /// (core.scale.js:574): the result of the tick `callback`.
  ///
  /// A label is a `String`, a `List` of lines or another value of the
  /// callback. Dart `null` stands for both JS `null` and `undefined`, the
  /// start value: every reader tests the label with `isNullOrUndef` or
  /// `isArray` (core.scale.js:783, :829, :836, :839), so the two values give
  /// the same result. A callback that returns the [undefined] sentinel keeps
  /// it.
  Object? label;

  /// `major`, whether the tick is a major tick. Dart `null` stands for JS
  /// `undefined`, the start value. The readers test it for truthiness
  /// (core.scale.autoskip.js:89).
  bool? major;

  /// scale.logarithmic.js:55 `significand`. Dart `null` stands for JS
  /// `undefined`: the ticks of the other scales do not set it.
  @override
  double? significand;

  /// `$context`, the scriptable context of the tick that [Scale.getContext]
  /// makes (core.scale.js:966-967). Dart `null` stands for JS `undefined`,
  /// the start value. It is the typed context of index.d.ts:1419 (Chart.js
  /// ADR 0054 §11).
  ScriptableScaleContext? $context;
}

/// core.scale.js:23 `sample`.
///
/// Returns a new array containing numItems from arr
/// @param {any[]} arr
/// @param {number} numItems
///
/// The loop index is a number, which `Math.floor` makes an index.
List<Tick> _sample(List<Tick> arr, Object? numItems) {
  final result = <Tick>[];
  final increment = arr.length / jsToNumber(numItems);
  final len = arr.length;
  var i = 0.0;

  for (; i < len; i += increment) {
    result.add(arr[i.floorToDouble().toInt()]);
  }
  return result;
}

/// core.scale.js:40 `getPixelForGridLine`.
///
/// @param {Scale} scale
/// @param {number} index
/// @param {boolean} offsetGridLines
///
/// Dart `null` stands for the `undefined` of a pixel out of the range.
/// [Scale.getPixelForTick] gives Dart `null` for its JS `null`. The
/// arithmetic converts that `null` to 0, as `ToNumber(null)` does (Chart.js
/// ADR 0045). Upstream returns the `null` of a tick out of the range only
/// for a scale without ticks and with `offsetGridLines` false. Then
/// `_computeGridLineItems` makes no call: its loop has no index.
double? _getPixelForGridLine(Scale scale, int index, Object? offsetGridLines) {
  final length = scale.ticks!.length;
  final validIndex = math.min(index, length - 1);
  final start = scale.startPixel;
  final end = scale.endPixel;
  const epsilon = 1e-6; // 1e-6 is margin in pixels for accumulated error.
  var lineValue = scale.getPixelForTick(validIndex) ?? 0;
  double offset;

  if (jsTruthy(offsetGridLines)) {
    if (length == 1) {
      offset = jsMax(lineValue - start, end - lineValue);
    } else if (index == 0) {
      offset = ((scale.getPixelForTick(1) ?? 0) - lineValue) / 2;
    } else {
      offset = (lineValue - (scale.getPixelForTick(validIndex - 1) ?? 0)) / 2;
    }
    lineValue += validIndex < index ? offset : -offset;

    // Return undefined if the pixel is out of the range
    if (lineValue < start - epsilon || lineValue > end + epsilon) {
      return null;
    }
  }
  return lineValue;
}

/// The cache of one font in `_longestTextCache` (core.scale.js:832): the
/// object literal `{data: {}, gc: []}`.
final class _TextCache {
  /// `data`, the measured widths, keyed by text.
  final Map<String, double> data = {};

  /// `gc`, the measured texts, in order.
  final List<String> gc = [];
}

/// core.scale.js:71 `garbageCollect`.
///
/// @param {object} caches
/// @param {number} length
///
/// `each` gives the values of [caches] in the `Object.keys` order. The keys
/// are font strings, which are never array indexes. Thus the order is the
/// insertion order of the Map.
void _garbageCollect(Map<String, _TextCache> caches, int length) {
  for (final cache in caches.values) {
    final gc = cache.gc;
    final gcLen = gc.length / 2;
    if (gcLen > length) {
      // An odd length gives a fraction. The loop then deletes one more key
      // than `splice` removes from `gc`, whose `deleteCount` truncates it.
      for (var i = 0; i < gcLen; ++i) {
        cache.data.remove(gc[i]);
      }
      // gcLen is finite and positive: toInt() truncates it, as the
      // ToIntegerOrInfinity of `splice` does.
      gc.removeRange(0, gcLen.toInt());
    }
  }
}

/// core.scale.js:88 `getTickMarkLength`.
///
/// @param {object} options
///
/// The result is the raw `tickLength` option, or 0. A caller that subtracts
/// it applies [jsToNumber], as the JS `-` does. A caller that adds it
/// applies [jsAdd]: a string `tickLength` joins the other operand, for
/// example `'8' + 0` gives `'80'` (core.scale.js:649).
Object? _getTickMarkLength(GridLineOptions options) {
  return jsTruthy(options.drawTicks) ? options.tickLength : 0.0;
}

/// core.scale.js:95 `getTitleHeight`.
///
/// @param {object} options
double _getTitleHeight(ScaleTitleOptions options, Object? fallback) {
  if (!jsTruthy(options.display)) {
    return 0;
  }

  final font = toFont(options.font, fallback);
  final padding = toPadding(options.padding);
  final text = options.text;
  final lines = isArray(text) ? (text! as List<Object?>).length : 1;

  return (lines * font.lineHeight) + padding.height;
}

/// core.scale.js:107 `createScaleContext`.
///
/// `createContext` gives the typed context of the type `'scale'`, a
/// [ScriptableScaleContext] (Chart.js ADR 0054 §11).
ScriptableScaleContext _createScaleContext(AnyObject parent, Scale scale) {
  return createContext(parent, <String, Object?>{
    'scale': scale,
    'type': 'scale',
  }) as ScriptableScaleContext;
}

/// core.scale.js:114 `createTickContext`.
///
/// The index of the context is a number, which a scriptable option reads.
/// The context of the type `'tick'` is a [ScriptableScaleContext] (Chart.js ADR
/// 0054 §11).
ScriptableScaleContext _createTickContext(
  AnyObject parent,
  int index,
  Tick tick,
) {
  return createContext(parent, <String, Object?>{
    'tick': tick,
    'index': index.toDouble(),
    'type': 'tick',
  }) as ScriptableScaleContext;
}

/// core.scale.js:122 `titleAlign`.
///
/// `_toLeftRightCenter` compares [align] with `'start'` and `'end'`. A value
/// that is not a `String` equals neither, so it passes as `''`.
String? _titleAlign(Object? align, Object? position, Object? reverse) {
  /** @type {CanvasTextAlign} */
  String? ret = toLeftRightCenter(align is String ? align : '');
  if ((jsTruthy(reverse) && position != 'right') ||
      (!jsTruthy(reverse) && position == 'right')) {
    ret = _reverseAlign(ret);
  }
  return ret;
}

/// core.scale.js:131 `titleArgs`: the object `{titleX, titleY, maxWidth,
/// rotation}`, a record. Dart `null` stands for the `undefined` of
/// `maxWidth` on a vertical scale.
({double titleX, double titleY, double? maxWidth, double rotation}) _titleArgs(
  Scale scale,
  double offset,
  Object? position,
  Object? align,
) {
  final Scale(:top, :left, :bottom, :right, :chart) = scale;
  final chartArea = chart.chartArea;
  final scales = chart.scales;
  var rotation = 0.0;
  double? maxWidth;
  double titleX;
  double titleY;
  final height = bottom - top;
  final width = right - left;
  final alignName = align is String ? align : '';

  if (scale.isHorizontal()) {
    titleX = alignStartEnd(alignName, left, right);

    if (isObject(position)) {
      final (:positionAxisID, :value) = _positionAxis(position);
      titleY =
          scales[positionAxisID]!.getPixelForValue(value) + height - offset;
    } else if (position == 'center') {
      titleY = (chartArea!.bottom + chartArea.top) / 2 + height - offset;
    } else {
      titleY = _offsetFromEdge(scale, position, offset);
    }
    maxWidth = right - left;
  } else {
    if (isObject(position)) {
      final (:positionAxisID, :value) = _positionAxis(position);
      titleX = scales[positionAxisID]!.getPixelForValue(value) - width + offset;
    } else if (position == 'center') {
      titleX = (chartArea!.left + chartArea.right) / 2 - width + offset;
    } else {
      titleX = _offsetFromEdge(scale, position, offset);
    }
    titleY = alignStartEnd(alignName, bottom, top);
    rotation = position == 'left' ? -halfPi : halfPi;
  }
  return (
    titleX: titleX,
    titleY: titleY,
    maxWidth: maxWidth,
    rotation: rotation,
  );
}

/// The two reads of an object position `{<scale id>: number}`
/// (core.scale.js:143-144, :154-155, :1062-1063, :1075-1076, :1180-1181,
/// :1189-1190):
/// `const positionAxisID = Object.keys(position)[0];` and
/// `const value = position[positionAxisID];`.
///
/// `positionAxisID` is Dart `null` for an object without keys, JS
/// `undefined`: the read of the value then reads the key `'undefined'`,
/// the scale lookup gives Dart `null`, and the call on it throws a
/// `TypeError`, as upstream does.
///
/// The key is the id of a scale that the user names, not a key of the
/// schema. Thus the object reads it by name.
({String? positionAxisID, Object? value}) _positionAxis(Object? position) {
  final keys = jsObjectKeys(position! as AnyObject);
  final positionAxisID = keys.isEmpty ? null : keys[0];
  return (
    positionAxisID: positionAxisID,
    value: jsGet(position, positionAxisID ?? undefined),
  );
}

/// The `{left, right, top, bottom}` object of `_margins`
/// (core.scale.js:198-203, :403-408).
final class _Margins {
  _Margins(this.left, this.right, this.top, this.bottom);

  double left;
  double right;
  double top;
  double bottom;
}

/// The label sizes of `_computeLabelSizes` (core.scale.js:862-869): the
/// object `{first, last, widest, highest, widths, heights}`.
final class _LabelSizes {
  _LabelSizes(
    this.first,
    this.last,
    this.widest,
    this.highest,
    this.widths,
    this.heights,
  );

  final ({double width, double height}) first;
  final ({double width, double height}) last;
  final ({double width, double height}) widest;
  final ({double width, double height}) highest;
  final List<double> widths;
  final List<double> heights;
}

/// The line style of `drawLine` in `drawGrid` (core.scale.js:1474): the
/// object `{width, color, borderDash, borderDashOffset}`.
///
/// The members keep the option values as they are. `drawLine` tests them for
/// truthiness and gives them to the canvas setters.
class _LineStyle {
  _LineStyle(this.width, this.color, this.borderDash, this.borderDashOffset);

  final Object? width;
  final Object? color;
  final Object? borderDash;
  final Object? borderDashOffset;
}

/// A grid line item of `_computeGridLineItems` (core.scale.js:1118-1135).
///
/// It is also the line style of the grid line (core.scale.js:1496-1500).
/// A coordinate that upstream leaves `undefined` is NaN, its `ToNumber`. The
/// canvas methods convert their arguments with `ToNumber` in JavaScript.
final class _GridLineItem extends _LineStyle {
  _GridLineItem({
    required this.tx1,
    required this.ty1,
    required this.tx2,
    required this.ty2,
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required Object? width,
    required Object? color,
    required Object? borderDash,
    required Object? borderDashOffset,
    required this.tickWidth,
    required this.tickColor,
    required this.tickBorderDash,
    required this.tickBorderDashOffset,
  }) : super(width, color, borderDash, borderDashOffset);

  final double tx1;
  final double ty1;
  final double tx2;
  final double ty2;
  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final Object? tickWidth;
  final Object? tickColor;
  final Object? tickBorderDash;
  final Object? tickBorderDashOffset;
}

/// The `backdrop` object of a label item (core.scale.js:1301-1308).
final class _LabelBackdrop implements types.BackdropOptions {
  _LabelBackdrop(this.left, this.top, this.width, this.height, this.color);

  @override
  final double left;

  @override
  final double top;

  @override
  final double width;

  @override
  final double height;

  @override
  final Object? color;
}

/// The text options of a label item (core.scale.js:1315-1324) and of the
/// title (core.scale.js:1611-1620). The members that the object literal
/// leaves out are Dart `null`, JS `undefined`.
///
/// [strokeWidth] is the [canvasNumber] of the option value. `renderText`
/// compares the value with 0 and gives it to the setter `lineWidth`. Both
/// apply `ToNumber`, and the [undefined] of an absent option gives Dart
/// `null`.
final class _RenderTextOpts implements types.RenderTextOpts {
  _RenderTextOpts({
    this.rotation,
    this.color,
    this.strokeColor,
    this.strokeWidth,
    this.textAlign,
    this.textBaseline,
    this.translation,
    this.backdrop,
    this.maxWidth,
  });

  @override
  final double? rotation;

  @override
  final Object? color;

  @override
  final Object? strokeColor;

  @override
  final double? strokeWidth;

  @override
  final String? textAlign;

  @override
  final String? textBaseline;

  @override
  final (double, double)? translation;

  @override
  final types.BackdropOptions? backdrop;

  @override
  final double? maxWidth;

  @override
  double? get decorationWidth => null;

  @override
  bool? get strikethrough => null;

  @override
  bool? get underline => null;
}

/// A label item of `_computeLabelItems` (core.scale.js:1311-1325), the
/// object literal `{label, font, textOffset, options}`.
final class _LabelItem implements types.LabelItem {
  _LabelItem(this.label, this.font, this.textOffset, this.options);

  @override
  final Object? label;

  @override
  final types.CanvasFontSpec font;

  @override
  final double textOffset;

  @override
  final types.RenderTextOpts options;
}

/// The area of `_computeLabelArea` (core.scale.js:1432, :1434): the object
/// `{top, left, bottom, right}`.
final class _LabelArea implements types.TRBL {
  _LabelArea(this.top, this.left, this.bottom, this.right);

  @override
  final double top;

  @override
  final double left;

  @override
  final double bottom;

  @override
  final double right;
}

/// A layer of `_layers` (core.scale.js:1647-1669): the object literal
/// `{z, draw}`.
///
/// `core.controller.js:637` writes `_idx` into the layer: [idx].
final class _ScaleLayer implements types.LayoutLayer {
  _ScaleLayer(this.z, this._draw);

  @override
  final double z;

  /// The `draw` function of the literal.
  final void Function(types.ChartArea chartArea) _draw;

  @override
  void draw(types.ChartArea chartArea) => _draw(chartArea);

  @override
  double idx = double.nan;
}

/// The `setContext` of an option resolver: `options.setContext(context)`.
///
/// The option objects of a scale are `ContextProxy` resolvers. Another value
/// has no `setContext`. JavaScript then throws a `TypeError` at the call.
/// Here the cast throws it.
ContextProxy _setContext(Object? options, AnyObject context) =>
    (options! as ContextProxy).setContext(context);

/// The holder of `Scale.prototype.draw` (core.scale.js:1623), for the test
/// `this.draw !== Scale.prototype.draw` of `_layers` (core.scale.js:1645).
///
/// Dart has no prototype objects. Two tear-offs of the same method from the
/// same object are equal (`==`). [Scale.layers] compares the tear-off `draw`
/// with the super tear-off `super.draw`, which is this method. The two are
/// equal unless a subclass of [Scale] overrides `draw`. The VM, dart2js and
/// dart2wasm give this result. [draw] calls [_draw], the upstream body in
/// [Scale]. A subclass that overrides `draw` can call `super.draw`.
abstract class _ScalePrototype extends Element {
  /// core.scale.js:1623 `draw(chartArea)`. [Scale] has the body.
  ///
  /// Dart `null` for [chartArea] stands for JS `undefined`.
  void draw([types.ChartArea? chartArea]) => _draw(chartArea);

  /// The body of `draw`.
  void _draw(types.ChartArea? chartArea);
}

/// core.scale.js:168 `Scale`.
///
/// The base class of the scales. A scale is an element and a layout box.
class Scale extends _ScalePrototype
    implements
        types.Scale,
        types.LayoutItemBeforeLayout,
        types.LayoutItemConfigure,
        types.LayoutItemPadding,
        MinMax {
  /// core.scale.js:171 `constructor(cfg)`.
  ///
  /// [cfg] is the object `{id, type, ctx, chart}` of `buildOrUpdateScales`
  /// (core.controller.js:357-362). `id` and `type` are strings, `ctx` is the
  /// canvas context or Dart `null` (JS `null`), and `chart` is the chart.
  /// A value of another type throws a `TypeError` at the cast.
  // eslint-disable-next-line max-statements
  Scale(AnyObject cfg)
    : id = cfg['id']! as String,
      type = cfg['type']! as String,
      ctx = cfg['ctx'] as CanvasRenderingContext2D?,
      chart = cfg['chart']! as types.Chart;

  /// core.scale.js:168 `class Scale` as a value (Chart.js ADR 0020, section
  /// 3).
  ///
  /// It extends [Element.jsClass]. It has no own statics. Its `construct`
  /// takes the `cfg` object: a Map. Another value throws a `TypeError`, as
  /// `cfg.id` of `undefined` throws (row `adapt-component-class-role`).
  static final JsClass jsClass = JsClass(
    'Scale',
    superclass: Element.jsClass,
    construct: (newTarget, args) => Scale(scaleCfgArg(args)),
  );

  /// core.scale.js:175 `id`.
  @override
  final String id;

  /// core.scale.js:177 `type`.
  @override
  final String type;

  /// core.scale.js:181 `ctx`. The specs replace it with a mock context
  /// (core.scale.tests.js:184). Dart `null` stands for JS `null`: a chart
  /// without a context.
  CanvasRenderingContext2D? ctx;

  /// core.scale.js:183 `chart`.
  @override
  final types.Chart chart;

  // implements box

  /// core.scale.js:187 `top`. NaN stands for JS `undefined`, the start
  /// value.
  @override
  double top = double.nan;

  /// core.scale.js:189 `bottom`. NaN stands for JS `undefined`.
  @override
  double bottom = double.nan;

  /// core.scale.js:191 `left`. NaN stands for JS `undefined`.
  @override
  double left = double.nan;

  /// core.scale.js:193 `right`. NaN stands for JS `undefined`.
  @override
  double right = double.nan;

  /// core.scale.js:195 `width`. NaN stands for JS `undefined`.
  @override
  double width = double.nan;

  /// core.scale.js:197 `height`. NaN stands for JS `undefined`.
  @override
  double height = double.nan;

  /// core.scale.js:198 `_margins`.
  _Margins _margins = _Margins(0, 0, 0, 0);

  /// core.scale.js:205 `maxWidth`. NaN stands for JS `undefined`.
  double maxWidth = double.nan;

  /// core.scale.js:207 `maxHeight`. NaN stands for JS `undefined`.
  double maxHeight = double.nan;

  /// core.scale.js:209 `paddingTop`. NaN stands for JS `undefined`.
  ///
  /// The value is a JS value, not a `double`. `_calculatePadding`
  /// (core.scale.js:734) writes `paddingTop + padding`: the option
  /// `ticks.padding: '3'` gives the string `'7.1999999999999993'`. The
  /// readers apply `ToNumber`: `_handleMargins` through `Math.max` (:746),
  /// and `core.layouts` through `Math.max` (core.layouts.js:111) after
  /// [getPadding], which returns `this.paddingTop || 0` (:340). A joined
  /// string that is not a number, for example `'7.199999999999999x'`, is
  /// truthy: [getPadding] gives NaN, and the top and the bottom of the chart
  /// area are NaN. A NaN number is falsy: [getPadding] gives 0. Thus the
  /// field keeps the value. Each reader runs one time for each layout. Both
  /// readers give the same result for NaN and `undefined`.
  Object? paddingTop = double.nan;

  /// core.scale.js:211 `paddingBottom`. NaN stands for JS `undefined`. It
  /// holds a JS value, as [paddingTop] does.
  Object? paddingBottom = double.nan;

  /// core.scale.js:213 `paddingLeft`. NaN stands for JS `undefined`.
  double paddingLeft = double.nan;

  /// core.scale.js:215 `paddingRight`. NaN stands for JS `undefined`.
  double paddingRight = double.nan;

  // scale-specific properties

  /// core.scale.js:219 `axis`, from the `axis` option (core.scale.js:259).
  ///
  /// `core.config` gives each scale an `axis` option, or throws. A read
  /// before [init] throws a `LateInitializationError`, where JavaScript
  /// reads `undefined`.
  @override
  late String axis;

  /// core.scale.js:221 `labelRotation`, in degrees. It starts as
  /// [undefined].
  ///
  /// The value is a JS value, not a `double`. `calculateLabelRotation`
  /// (core.scale.js:590-596) writes the raw `minRotation || 0` when it does
  /// not calculate a rotation: the option `minRotation: '0'` gives the
  /// string `'0'`. The readers apply `ToNumber` through `toRadians`
  /// (core.scale.js:659, :981, :1157, :1333), and `_calculatePadding` tests
  /// `labelRotation !== 0` (:691), which is true for the string `'0'`. Thus
  /// the field keeps the value: [_rotationRadians] and [_isRotated] are the
  /// readers. Each reader runs one time for each layout or each computation
  /// of the label items, not for each tick.
  Object? labelRotation = undefined;

  /// core.scale.js:222 `min`. NaN stands for JS `undefined`, the start
  /// value. The subclasses set it in `determineDataLimits`.
  ///
  /// It is the `min` of `MinMax` (helpers.math.ts:81): the scales call
  /// `setMinAndMaxByKey(ticks, this, 'value')` (scale.linearbase.js:274,
  /// scale.logarithmic.js:172).
  @override
  double min = double.nan;

  /// core.scale.js:223 `max`. NaN stands for JS `undefined`.
  ///
  /// It is the `max` of `MinMax` (helpers.math.ts:81): the scales call
  /// `setMinAndMaxByKey(ticks, this, 'value')` (scale.linearbase.js:274,
  /// scale.logarithmic.js:172).
  @override
  double max = double.nan;

  /// core.scale.js:224 `_range`: the result of `_addGrace`
  /// (core.scale.js:429). Dart `null` stands for JS `undefined`, the start
  /// value. scale.linearbase.js:268 reads it.
  @internal
  ({double min, double max})? range;

  /// core.scale.js:226 `ticks`.
  ///
  /// Dart `null` stands for the JS `null` of an update in progress
  /// (core.scale.js:410): the hooks before `buildTicks` read it.
  @override
  List<Tick>? ticks = [];

  /// core.scale.js:228 `_gridLineItems`.
  List<_GridLineItem>? _gridLineItems;

  /// core.scale.js:230 `_labelItems`.
  List<types.LabelItem>? _labelItems;

  /// core.scale.js:232 `_labelSizes`.
  _LabelSizes? _labelSizes;

  /// core.scale.js:233 `_length`. core.scale.autoskip.js:52 and
  /// controller.bar.js:27 read it.
  @internal
  @override
  double length = 0;

  /// core.scale.js:234 `_maxLength`. core.scale.autoskip.js:53 reads it.
  @internal
  @override
  double maxLength = 0;

  /// core.scale.js:235 `_longestTextCache`, the measured label widths of
  /// each font string.
  final Map<String, _TextCache> _longestTextCache = {};

  /// core.scale.js:237 `_startPixel`. NaN stands for JS `undefined`.
  /// controller.bar.js:549 reads it.
  @internal
  @override
  double startPixel = double.nan;

  /// core.scale.js:239 `_endPixel`. NaN stands for JS `undefined`.
  /// controller.bar.js:550 reads it.
  @internal
  @override
  double endPixel = double.nan;

  /// core.scale.js:240 `_reversePixels`.
  ///
  /// Upstream keeps the option value of `reverse`, or its negation. Every
  /// reader tests it for truthiness or negates it (core.scale.js:921,
  /// :935, scale.category.js:128, core.interaction.js:28). Thus it is the
  /// `ToBoolean` of that value.
  @internal
  @override
  bool reversePixels = false;

  /// core.scale.js:241 `_userMax`, the parsed `max` option.
  /// scale.logarithmic.js:165 and scale.time.js:376 read it.
  @internal
  Object? userMax = undefined;

  /// core.scale.js:242 `_userMin`, the parsed `min` option.
  /// scale.logarithmic.js:164 and scale.time.js:375 read it.
  @internal
  Object? userMin = undefined;

  /// core.scale.js:243 `_suggestedMax`, the parsed `suggestedMax` option.
  Object? _suggestedMax = undefined;

  /// core.scale.js:244 `_suggestedMin`, the parsed `suggestedMin` option.
  /// scale.logarithmic.js:124 reads it.
  @internal
  Object? suggestedMin = undefined;

  /// core.scale.js:245 `_ticksLength`.
  // Upstream writes it and never reads it.
  // ignore: unused_field
  int _ticksLength = 0;

  /// core.scale.js:246 `_borderValue`. NaN stands for the `undefined` of a
  /// position without a border.
  double _borderValue = 0;

  /// core.scale.js:247 `_cache`, the data caches of the scale.
  /// scale.time.js:251, scale.timeseries.js:138 and controller.bar.js:8 read
  /// and write it.
  @internal
  @override
  AnyObject cache = {};

  /// core.scale.js:248 `_dataLimitsCached`.
  bool _dataLimitsCached = false;

  /// core.scale.js:249 `$context`, the scriptable context of the scale.
  /// Dart `null` stands for JS `undefined`, the start value. It is the
  /// typed context of index.d.ts:1419 (Chart.js ADR 0054 §11).
  ScriptableScaleContext? $context;

  /// core.scale.js:497 `_alignToPixels`, the `alignToPixels` option that
  /// `configure` reads. The constructor does not declare it. It starts
  /// absent.
  Object? _alignToPixels = undefined;

  /// The `position` of the layout box (layout.d.ts:9). The constructor does
  /// not declare it. `layouts.configure` writes the `position` option
  /// (core.controller.js:376, core.layouts.js:333). The [undefined] sentinel
  /// stands for JS `undefined`, the start value. The scale itself reads the
  /// `position` option.
  @override
  Object? position = undefined;

  /// The `weight` of the layout box (layout.d.ts:13). The constructor does
  /// not declare it. `layouts.configure` writes it (core.layouts.js:334).
  /// The [undefined] sentinel stands for JS `undefined`, the start value.
  @override
  Object? weight = undefined;

  /// The `fullSize` of the layout box (layout.d.ts:17). The constructor does
  /// not declare it. `layouts.configure` writes it (core.layouts.js:332).
  /// False stands for JS `undefined`, the start value: the readers test
  /// only its truthiness.
  @override
  bool fullSize = false;

  /// core.scale.js:1639 `_layers`, the method that gives the drawing layers
  /// of the scale, as a property. `core.layouts.js:301` and
  /// `core.controller.js:633` read it.
  ///
  /// A JavaScript method is a property with a function value. The start
  /// value is the tear-off of the method [_layers]. `layouts.addBox` keeps
  /// it (core.layouts.js:301).
  @internal
  @override
  late List<types.LayoutLayer> Function()? layers = _layers;

  /// core.scale.js:179 `options`, the resolved options of the scale.
  ///
  /// [init] sets the `ContextProxy` of the options, an [OptionView]. The
  /// getter gives it through the facade [CoreScaleOptions] (Chart.js ADR
  /// 0054 §4), which is still the view and a Map. A subclass narrows the
  /// facade to the options of its type. A read before [init] throws a
  /// `TypeError`, as the JavaScript read of a property of the `undefined`
  /// start value does.
  @override
  CoreScaleOptions get options =>
      CoreScaleOptions(super.options! as OptionView);

  /// core.scale.js:256 `init(options)`.
  ///
  /// @param {any} options
  /// @since 3.0
  ///
  /// [options] is the `ContextProxy` of the scale options.
  /// `buildOrUpdateScales` also passes the chart options
  /// (core.controller.js:367), which JavaScript ignores here. [opts] takes
  /// them. `scale.time.js:266` reads them.
  ///
  /// `types.Scale` declares `axis` as a `String` (index.d.ts:1317). Thus an
  /// `axis` option that is not a string throws a [TypeError], where upstream
  /// keeps the value (differences.md row `adapt-scale-option-types`).
  /// index.d.ts:3286 types the option as `'x' | 'y' | 'r'`.
  ///
  /// [options] is an [OptionView]: the reads after `setContext` read the
  /// view of the parameter, as upstream does, through the facade
  /// [CoreScaleOptions].
  void init(AnyObject options, [AnyObject? opts]) {
    this.options = _setContext(options, getContext());
    final view = CoreScaleOptions(options as OptionView);

    // DIVERGES(chartjs): adapt-scale-option-types, a String axis only.
    axis = view.axis! as String;

    // parse min/max value, so we can properly determine min/max for other
    // scales
    userMin = parse(view.min);
    userMax = parse(view.max);
    suggestedMin = parse(view.suggestedMin);
    _suggestedMax = parse(view.suggestedMax);
  }

  /// core.scale.js:270 `parse(raw, index)`.
  ///
  /// Parse a supported input value to internal representation.
  /// @param {*} raw
  /// @param {number} [index]
  /// @since 3.0
  @override
  Object? parse(Object? raw, [double? index]) {
    // eslint-disable-line no-unused-vars
    return raw;
  }

  /// core.scale.js:283 `getUserBounds()`.
  ///
  /// @return {{min: number, max: number, minDefined: boolean, maxDefined:
  /// boolean}}
  /// @protected
  /// @since 3.0
  @override
  ({double min, double max, bool minDefined, bool maxDefined}) getUserBounds() {
    final userMin = finiteOrDefault(this.userMin, double.infinity);
    final userMax = finiteOrDefault(this.userMax, double.negativeInfinity);
    final suggestedMin = finiteOrDefault(this.suggestedMin, double.infinity);
    final suggestedMax = finiteOrDefault(
      _suggestedMax,
      double.negativeInfinity,
    );
    return (
      min: finiteOrDefault(userMin, suggestedMin),
      max: finiteOrDefault(userMax, suggestedMax),
      minDefined: isFinite(userMin),
      maxDefined: isFinite(userMax),
    );
  }

  /// core.scale.js:303 `getMinMax(canStack)`.
  ///
  /// @param {boolean} canStack
  /// @return {{min: number, max: number}}
  /// @protected
  /// @since 3.0
  // The upstream signature has a positional `canStack`.
  // ignore: avoid_positional_boolean_parameters
  ({double min, double max}) getMinMax(bool canStack) {
    var (:min, :max, :minDefined, :maxDefined) = getUserBounds();
    ({double min, double max}) range;

    if (minDefined && maxDefined) {
      return (min: min, max: max);
    }

    final metas = getMatchingVisibleMetas();
    for (var i = 0, ilen = metas.length; i < ilen; ++i) {
      range = metas[i].controller!.getMinMax(this, canStack);
      if (!minDefined) {
        min = jsMin(min, range.min);
      }
      if (!maxDefined) {
        max = jsMax(max, range.max);
      }
    }

    // Make sure min <= max when only min or max is defined by user and the
    // data is outside that range
    min = maxDefined && min > max ? max : min;
    max = minDefined && min > max ? min : max;

    return (
      min: finiteOrDefault(min, finiteOrDefault(max, min)),
      max: finiteOrDefault(max, finiteOrDefault(min, max)),
    );
  }

  /// core.scale.js:337 `getPadding()`.
  ///
  /// Get the padding needed for the scale
  /// @return {{top: number, left: number, bottom: number, right: number}}
  /// the necessary padding
  /// @private
  ///
  /// [paddingTop] and [paddingBottom] are JS values. [jsOrZero] gives the
  /// `ToNumber` of `value || 0`, the number that `Math.max` of the reader
  /// takes (core.layouts.js:111, :113).
  @override
  types.TRBL getPadding() {
    return _LabelArea(
      jsOrZero(paddingTop),
      _orZero(paddingLeft),
      jsOrZero(paddingBottom),
      _orZero(paddingRight),
    );
  }

  /// core.scale.js:351 `getTicks()`.
  ///
  /// Returns the scale tick objects
  /// @return {Tick[]}
  /// @since 2.7
  List<Tick>? getTicks() {
    return ticks;
  }

  /// core.scale.js:358 `getLabels()`.
  ///
  /// @return {string[]}
  ///
  /// The labels are the array of the options or of the chart data, not a
  /// copy: scale.category.js adds labels to it. A label is a `String`, a
  /// `List` of lines or another value.
  ///
  /// The result is a `List`, as `string[]` of the JSDoc. A truthy value that
  /// is not a `List` throws a [TypeError], where upstream returns the value
  /// (differences.md row `adapt-scale-option-types`).
  @override
  List<Object?> getLabels() {
    final data = chart.data;
    final labels = options.labels;
    // DIVERGES(chartjs): adapt-scale-option-types, a List of labels only.
    if (jsTruthy(labels)) return labels! as List<Object?>;
    final axisLabels = isHorizontal() ? data['xLabels'] : data['yLabels'];
    // DIVERGES(chartjs): adapt-scale-option-types, a List of labels only.
    if (jsTruthy(axisLabels)) return axisLabels! as List<Object?>;
    final dataLabels = data['labels'];
    // DIVERGES(chartjs): adapt-scale-option-types, a List of labels only.
    if (jsTruthy(dataLabels)) return dataLabels! as List<Object?>;
    return [];
  }

  /// core.scale.js:366 `getLabelItems(chartArea = this.chart.chartArea)`.
  ///
  /// @return {import('../types.js').LabelItem[]}
  ///
  /// Dart `null` for [chartArea] stands for JS `undefined`, which takes the
  /// default.
  List<types.LabelItem> getLabelItems([types.ChartArea? chartArea]) {
    chartArea ??= chart.chartArea;
    final items = _labelItems ?? (_labelItems = _computeLabelItems(chartArea));
    return items;
  }

  /// core.scale.js:372 `beforeLayout()`.
  ///
  /// When a new layout is created, reset the data limits cache
  @override
  void beforeLayout() {
    cache = {};
    _dataLimitsCached = false;
  }

  // These methods are ordered by lifecycle. Utilities then follow.
  // Any function defined here is inherited by all scale types.
  // Any function can be extended by the scale type

  /// core.scale.js:381 `beforeUpdate()`.
  void beforeUpdate() {
    callback(options.beforeUpdate, [this]);
  }

  /// core.scale.js:393 `update(maxWidth, maxHeight, margins)`.
  ///
  /// @param {number} maxWidth - the max width in pixels
  /// @param {number} maxHeight - the max height in pixels
  /// @param {{top: number, left: number, bottom: number, right: number}}
  /// margins - the space between the edge of the other scales and edge of
  /// the chart
  ///   This space comes from two sources:
  ///     - padding - space that's required to show the labels at the edges
  ///       of the scale
  ///     - thickness of scales or legends in another orientation
  ///
  /// Dart `null` for [margins] stands for JS `undefined`, which
  /// `Object.assign` ignores. `Object.assign` copies the four edges of
  /// [margins] into a new object.
  @override
  void update(double maxWidth, double maxHeight, [types.TRBL? margins]) {
    final options = this.options;
    final beginAtZero = options.beginAtZero;
    final grace = options.grace;
    final tickOpts = options.ticks;
    final sampleSize = tickOpts.sampleSize;

    // Update Lifecycle - Probably don't want to ever extend or overwrite this
    // function ;)
    beforeUpdate();

    // Absorb the master measurements
    this.maxWidth = maxWidth;
    this.maxHeight = maxHeight;
    final newMargins = _margins = margins == null
        ? _Margins(0, 0, 0, 0)
        : _Margins(margins.left, margins.right, margins.top, margins.bottom);

    ticks = null;
    _labelSizes = null;
    _gridLineItems = null;
    _labelItems = null;

    // Dimensions
    beforeSetDimensions();
    setDimensions();
    afterSetDimensions();

    maxLength = isHorizontal()
        ? width + newMargins.left + newMargins.right
        : height + newMargins.top + newMargins.bottom;

    // Data min/max
    if (!_dataLimitsCached) {
      beforeDataLimits();
      determineDataLimits();
      afterDataLimits();
      range = addGrace((min: min, max: max), grace, jsTruthy(beginAtZero));
      _dataLimitsCached = true;
    }

    beforeBuildTicks();

    ticks = buildTicks() ?? [];

    // Allow modification of ticks in callback.
    afterBuildTicks();

    // Compute tick rotation and fit using a sampled subset of labels
    // We generally don't need to compute the size of every single label for
    // determining scale size
    final samplingEnabled = jsToNumber(sampleSize) < ticks!.length;
    _convertTicksToLabels(
      samplingEnabled ? _sample(ticks!, sampleSize) : ticks!,
    );

    // configure is called twice, once here, once from
    // core.controller.updateLayout. Here we haven't been positioned yet, but
    // dimensions are correct. Variables set in configure are needed for
    // calculateLabelRotation, and it's ok that coordinates are not correct
    // there, only dimensions matter.
    configure();

    // Tick Rotation
    beforeCalculateLabelRotation();
    // Preconditions: number of ticks and sizes of largest labels must be
    // calculated beforehand
    calculateLabelRotation();
    afterCalculateLabelRotation();

    // Auto-skip
    if (jsTruthy(tickOpts.display) &&
        (jsTruthy(tickOpts.autoSkip) || tickOpts.source == 'auto')) {
      ticks = autoSkip(this, ticks!);
      _labelSizes = null;
      afterAutoSkip();
    }

    if (samplingEnabled) {
      // Generate labels using all non-skipped ticks
      _convertTicksToLabels(ticks!);
    }

    beforeFit();
    // Preconditions: label rotation and label sizes must be calculated
    // beforehand
    fit();
    afterFit();

    // IMPORTANT: after this point, we consider that `this.ticks` will NEVER
    // change!

    afterUpdate();
  }

  /// core.scale.js:480 `configure()`.
  ///
  /// @protected
  ///
  /// `core.controller.js:630-632` calls it through
  /// `types.LayoutItemConfigure`.
  @override
  @protected
  void configure() {
    var reversePixels = jsTruthy(options.reverse);
    double startPixel;
    double endPixel;

    if (isHorizontal()) {
      startPixel = left;
      endPixel = right;
    } else {
      startPixel = top;
      endPixel = bottom;
      // by default vertical scales are from bottom to top, so pixels are
      // reversed
      reversePixels = !reversePixels;
    }
    this.startPixel = startPixel;
    this.endPixel = endPixel;
    this.reversePixels = reversePixels;
    length = endPixel - startPixel;
    _alignToPixels = options.alignToPixels;
  }

  /// core.scale.js:500 `afterUpdate()`.
  void afterUpdate() {
    callback(options.afterUpdate, [this]);
  }

  //

  /// core.scale.js:506 `beforeSetDimensions()`.
  void beforeSetDimensions() {
    callback(options.beforeSetDimensions, [this]);
  }

  /// core.scale.js:509 `setDimensions()`.
  void setDimensions() {
    // Set the unconstrained dimension before label rotation
    if (isHorizontal()) {
      // Reset position before calculating rotation
      width = maxWidth;
      left = 0;
      right = width;
    } else {
      height = maxHeight;

      // Reset position before calculating rotation
      top = 0;
      bottom = height;
    }

    // Reset padding
    paddingLeft = 0;
    paddingTop = 0;
    paddingRight = 0;
    paddingBottom = 0;
  }

  /// core.scale.js:530 `afterSetDimensions()`.
  void afterSetDimensions() {
    callback(options.afterSetDimensions, [this]);
  }

  /// core.scale.js:534 `_callHooks(name)`.
  ///
  /// The name is the [OptionKey] of the hook option: its JS name is the
  /// name of the plugin hook, and the option reads with the typed key.
  void _callHooks(OptionKey name) {
    chart.notifyPlugins(name.jsName, getContext());
    callback(options.readKey(name), [this]);
  }

  // Data limits

  /// core.scale.js:540 `beforeDataLimits()`.
  void beforeDataLimits() {
    _callHooks(OptionKey.beforeDataLimits);
  }

  /// core.scale.js:543 `determineDataLimits()`.
  void determineDataLimits() {}

  /// core.scale.js:544 `afterDataLimits()`.
  void afterDataLimits() {
    _callHooks(OptionKey.afterDataLimits);
  }

  //

  /// core.scale.js:549 `beforeBuildTicks()`.
  void beforeBuildTicks() {
    _callHooks(OptionKey.beforeBuildTicks);
  }

  /// core.scale.js:555 `buildTicks()`.
  ///
  /// @return {object[]} the ticks
  ///
  /// Dart `null` stands for a subclass that returns no list:
  /// `this.buildTicks() || []` (core.scale.js:435) then takes an empty list.
  List<Tick>? buildTicks() {
    return [];
  }

  /// core.scale.js:558 `afterBuildTicks()`.
  void afterBuildTicks() {
    _callHooks(OptionKey.afterBuildTicks);
  }

  /// core.scale.js:562 `beforeTickToLabelConversion()`.
  void beforeTickToLabelConversion() {
    callback(options.beforeTickToLabelConversion, [this]);
  }

  /// core.scale.js:569 `generateTickLabels(ticks)`.
  ///
  /// Convert ticks to label strings
  /// @param {Tick[]} ticks
  ///
  /// The tick `callback` gets the value, the index as a number and the
  /// list, with the scale as `this`.
  void generateTickLabels(List<Tick> ticks) {
    final tickOpts = options.ticks;
    for (var i = 0, ilen = ticks.length; i < ilen; i++) {
      final tick = ticks[i];
      tick.label = callback(tickOpts.callback, [
        tick.value,
        i.toDouble(),
        ticks,
      ], this);
    }
  }

  /// core.scale.js:577 `afterTickToLabelConversion()`.
  void afterTickToLabelConversion() {
    callback(options.afterTickToLabelConversion, [this]);
  }

  //

  /// core.scale.js:583 `beforeCalculateLabelRotation()`.
  void beforeCalculateLabelRotation() {
    callback(options.beforeCalculateLabelRotation, [this]);
  }

  /// core.scale.js:586 `calculateLabelRotation()`.
  ///
  /// `Math.asin` is `dart:math` `asin`. Its last bit can differ from V8.
  /// The rotation is not a label pixel only. `_tickSize`
  /// (core.scale.js:977-993) reads it, and `autoSkip` (core.scale.js:452-458,
  /// core.scale.autoskip.js:51-56) uses `_tickSize` to select the ticks that
  /// stay. `fit` (core.scale.js:659-674) uses it for the size of the scale.
  /// But the input of the rotation is the label sizes. They come from the
  /// text layout of the platform, which differs from the browser by much more
  /// than one bit (Chart.js ADR 0015). Thus an exact `asin` cannot make the
  /// ticks agree.
  ///
  /// `minRotation` and `maxRotation` are the raw option values. Without a
  /// calculated rotation, [labelRotation] gets the raw `minRotation || 0`,
  /// for example the string `'0'`. `minRotation >= maxRotation` is the JS
  /// comparison ([_jsGreaterOrEqual]): two strings compare by their code
  /// units, so `'5' >= '30'` is true. `Math.max` and `Math.min` apply
  /// `ToNumber` to the options.
  void calculateLabelRotation() {
    final options = this.options;
    final tickOpts = options.ticks;
    final numTicks = _getTicksLimit(ticks!.length, tickOpts.maxTicksLimit);
    final minRotationOption = tickOpts.minRotation;
    final minRotation = jsTruthy(minRotationOption) ? minRotationOption : 0.0;
    final maxRotation = tickOpts.maxRotation;
    var labelRotation = minRotation;
    double tickWidth;
    double maxHeight;
    double maxLabelDiagonal;

    if (!_isVisible() ||
        !jsTruthy(tickOpts.display) ||
        _jsGreaterOrEqual(minRotation, maxRotation) ||
        numTicks <= 1 ||
        !isHorizontal()) {
      this.labelRotation = minRotation;
      return;
    }

    final labelSizes = _getLabelSizes();
    final maxLabelWidth = labelSizes.widest.width;
    final maxLabelHeight = labelSizes.highest.height;

    // Estimate the width of each grid based on the canvas width, the maximum
    // label width and the number of tick intervals
    final maxWidth = limitValue(
      chart.width - maxLabelWidth,
      0,
      this.maxWidth,
    );
    tickWidth = jsTruthy(options.offset)
        ? this.maxWidth / numTicks
        : maxWidth / (numTicks - 1);

    // Allow 3 pixels x2 padding either side for label readability
    if (maxLabelWidth + 6 > tickWidth) {
      tickWidth = maxWidth / (numTicks - (jsTruthy(options.offset) ? 0.5 : 1));
      maxHeight =
          this.maxHeight -
          jsToNumber(_getTickMarkLength(options.grid)) -
          jsToNumber(tickOpts.padding) -
          _getTitleHeight(
            options.title,
            readOption(chart.options, OptionKey.font),
          );
      maxLabelDiagonal = math.sqrt(
        maxLabelWidth * maxLabelWidth + maxLabelHeight * maxLabelHeight,
      );
      // The local `labelRotation` holds the raw option value until here.
      // Thus the calculated degrees have their own local.
      final degrees = toDegrees(
        jsMin(
          // js-ok: the label sizes differ more (Chart.js ADR 0015)
          math.asin(
            limitValue((labelSizes.highest.height + 6) / tickWidth, -1, 1),
          ),
          // js-ok: the label sizes differ more (Chart.js ADR 0015)
          math.asin(limitValue(maxHeight / maxLabelDiagonal, -1, 1)) -
              // js-ok: the label sizes differ more (Chart.js ADR 0015)
              math.asin(limitValue(maxLabelHeight / maxLabelDiagonal, -1, 1)),
        ),
      );
      labelRotation = jsMax(
        jsToNumber(minRotation),
        jsMin(jsToNumber(maxRotation), degrees),
      );
    }

    this.labelRotation = labelRotation;
  }

  /// `toRadians(this.labelRotation)` (core.scale.js:659, :981, :1157,
  /// :1333): the radians of the `ToNumber` of [labelRotation].
  double get _rotationRadians => toRadians(jsToNumber(labelRotation));

  /// `this.labelRotation !== 0` (core.scale.js:691). Only a number 0 (or
  /// -0) gives false. The string `'0'` gives true.
  bool get _isRotated {
    final rotation = labelRotation;
    return rotation is! num || rotation != 0;
  }

  /// core.scale.js:624 `afterCalculateLabelRotation()`.
  void afterCalculateLabelRotation() {
    callback(options.afterCalculateLabelRotation, [this]);
  }

  /// core.scale.js:627 `afterAutoSkip()`.
  void afterAutoSkip() {}

  //

  /// core.scale.js:631 `beforeFit()`.
  void beforeFit() {
    callback(options.beforeFit, [this]);
  }

  /// core.scale.js:634 `fit()`.
  ///
  /// The two sizes of `minSize` are JS values. The raw `tickLength`
  /// ([_getTickMarkLength]) starts them, and a string `tickLength` joins
  /// the other operands of each `+` ([jsAdd]). `Math.min` and the size
  /// fields take the [jsToNumber] of the result: with the labels, `'8' + 0 +
  /// 14.4 + 6` gives `'8014.46'`, and the size is `maxHeight`. Upstream
  /// keeps a joined string in `height` or `width` when it does not fit the
  /// labels. The port keeps its `ToNumber` (differences.md row
  /// `adapt-scale-option-types`).
  void fit() {
    // Reset
    Object minSizeWidth = 0.0;
    Object minSizeHeight = 0.0;

    final chart = this.chart;
    final options = this.options;
    final tickOpts = options.ticks;
    final titleOpts = options.title;
    final gridOpts = options.grid;
    final display = _isVisible();
    final isHorizontal = this.isHorizontal();

    if (display) {
      final titleHeight = _getTitleHeight(
        titleOpts,
        readOption(chart.options, OptionKey.font),
      );
      if (isHorizontal) {
        minSizeWidth = maxWidth;
        minSizeHeight = jsAdd(_getTickMarkLength(gridOpts), titleHeight);
      } else {
        minSizeHeight = maxHeight; // fill all the height
        minSizeWidth = jsAdd(_getTickMarkLength(gridOpts), titleHeight);
      }

      // Don't bother fitting the ticks if we are not showing the labels
      if (jsTruthy(tickOpts.display) && ticks!.isNotEmpty) {
        final _LabelSizes(:first, :last, :widest, :highest) = _getLabelSizes();
        final tickPadding = jsToNumber(tickOpts.padding) * 2;
        final angleRadians = _rotationRadians;
        final cos = jsCos(angleRadians);
        final sin = jsSin(angleRadians);

        if (isHorizontal) {
          // A horizontal axis is more constrained by the height.
          final labelHeight = jsTruthy(tickOpts.mirror)
              ? 0.0
              : sin * widest.width + cos * highest.height;
          minSizeHeight = jsMin(
            maxHeight,
            jsToNumber(jsAdd(jsAdd(minSizeHeight, labelHeight), tickPadding)),
          );
        } else {
          // A vertical axis is more constrained by the width. Labels are the
          // dominant factor here, so get that length first and account for
          // padding
          final labelWidth = jsTruthy(tickOpts.mirror)
              ? 0.0
              : cos * widest.width + sin * highest.height;

          minSizeWidth = jsMin(
            maxWidth,
            jsToNumber(jsAdd(jsAdd(minSizeWidth, labelWidth), tickPadding)),
          );
        }
        _calculatePadding(first, last, sin, cos);
      }
    }

    _handleMargins();

    if (isHorizontal) {
      width = length = chart.width - _margins.left - _margins.right;
      // DIVERGES(chartjs): adapt-scale-option-types, a number size only.
      height = jsToNumber(minSizeHeight);
    } else {
      // DIVERGES(chartjs): adapt-scale-option-types, a number size only.
      width = jsToNumber(minSizeWidth);
      height = length = chart.height - _margins.top - _margins.bottom;
    }
  }

  /// core.scale.js:689 `_calculatePadding(first, last, sin, cos)`.
  ///
  /// `padding` is the raw `ticks.padding` option. Each `+ padding` is
  /// [jsAdd]: a string padding joins the number. `Math.max` takes the
  /// [jsToNumber] of the result for [paddingLeft] and [paddingRight].
  /// [paddingTop] and [paddingBottom] keep the result, also a joined string.
  void _calculatePadding(
    ({double width, double height}) first,
    ({double width, double height}) last,
    double sin,
    double cos,
  ) {
    final options = this.options;
    final tickOpts = options.ticks;
    final align = tickOpts.align;
    final padding = tickOpts.padding;
    final position = options.position;
    final isRotated = _isRotated;
    final labelsBelowTicks = position != 'top' && axis == 'x';

    if (isHorizontal()) {
      final offsetLeft = (getPixelForTick(0) ?? 0) - left;
      final offsetRight = right - (getPixelForTick(ticks!.length - 1) ?? 0);
      var paddingLeft = 0.0;
      var paddingRight = 0.0;

      // Ensure that our ticks are always inside the canvas. When rotated,
      // ticks are right aligned which means that the right padding is
      // dominated by the font height
      if (isRotated) {
        if (labelsBelowTicks) {
          paddingLeft = cos * first.width;
          paddingRight = sin * last.height;
        } else {
          paddingLeft = sin * first.height;
          paddingRight = cos * last.width;
        }
      } else if (align == 'start') {
        paddingRight = last.width;
      } else if (align == 'end') {
        paddingLeft = first.width;
      } else if (align != 'inner') {
        paddingLeft = first.width / 2;
        paddingRight = last.width / 2;
      }

      // Adjust padding taking into account changes in offsets
      this.paddingLeft = jsMax(
        jsToNumber(jsAdd(paddingLeft - offsetLeft, padding)) *
            width /
            (width - offsetLeft),
        0,
      );
      this.paddingRight = jsMax(
        jsToNumber(jsAdd(paddingRight - offsetRight, padding)) *
            width /
            (width - offsetRight),
        0,
      );
    } else {
      var paddingTop = last.height / 2;
      var paddingBottom = first.height / 2;

      if (align == 'start') {
        paddingTop = 0;
        paddingBottom = first.height;
      } else if (align == 'end') {
        paddingTop = last.height;
        paddingBottom = 0;
      }

      this.paddingTop = jsAdd(paddingTop, padding);
      this.paddingBottom = jsAdd(paddingBottom, padding);
    }
  }

  /// core.scale.js:743 `_handleMargins()`.
  ///
  /// Handle margins and padding interactions
  /// @private
  ///
  /// `_margins` is always an object: `if (this._margins)` is true.
  void _handleMargins() {
    final margins = _margins;
    margins
      ..left = jsMax(paddingLeft, margins.left)
      ..top = jsMax(jsToNumber(paddingTop), margins.top)
      ..right = jsMax(paddingRight, margins.right)
      ..bottom = jsMax(jsToNumber(paddingBottom), margins.bottom);
  }

  /// core.scale.js:752 `afterFit()`.
  void afterFit() {
    callback(options.afterFit, [this]);
  }

  // Shared Methods

  /// core.scale.js:760 `isHorizontal()`.
  ///
  /// @return {boolean}
  @override
  bool isHorizontal() {
    final options = this.options;
    final axis = options.axis;
    final position = options.position;
    return position == 'top' || position == 'bottom' || axis == 'x';
  }

  /// core.scale.js:767 `isFullSize()`.
  ///
  /// @return {boolean}
  ///
  /// It returns the option value as it is, as upstream does: a `bool` for
  /// the options of `index.d.ts:1413`. No upstream source calls it.
  Object? isFullSize() {
    return options.fullSize;
  }

  /// core.scale.js:775 `_convertTicksToLabels(ticks)`.
  ///
  /// @param {Tick[]} ticks
  /// @private
  void _convertTicksToLabels(List<Tick> ticks) {
    beforeTickToLabelConversion();

    generateTickLabels(ticks);

    // Ticks should be skipped when callback returns null or undef, so lets
    // remove those.
    for (var i = 0, ilen = ticks.length; i < ilen; i++) {
      if (isNullOrUndef(ticks[i].label)) {
        ticks.removeAt(i);
        ilen--;
        i--;
      }
    }

    afterTickToLabelConversion();
  }

  /// core.scale.js:797 `_getLabelSizes()`.
  ///
  /// @return {{ first: object, last: object, widest: object, highest:
  /// object, widths: Array, heights: array }}
  /// @private
  _LabelSizes _getLabelSizes() {
    var labelSizes = _labelSizes;

    if (labelSizes == null) {
      final tickOpts = options.ticks;
      final sampleSize = tickOpts.sampleSize;
      var ticks = this.ticks!;
      if (jsToNumber(sampleSize) < ticks.length) {
        ticks = _sample(ticks, sampleSize);
      }

      _labelSizes = labelSizes = _computeLabelSizes(
        ticks,
        ticks.length,
        tickOpts.maxTicksLimit,
      );
    }

    return labelSizes;
  }

  /// core.scale.js:819 `_computeLabelSizes(ticks, length, maxTicksLimit)`.
  ///
  /// Returns {width, height, offset} objects for the first, last, widest,
  /// highest tick labels where offset indicates the anchor point offset from
  /// the top in pixels.
  /// @return {{ first: object, last: object, widest: object, highest:
  /// object, widths: Array, heights: array }}
  /// @private
  ///
  /// The loop index is a number: `Math.floor` of the increment can give NaN
  /// or Infinity for an odd `maxTicksLimit`. A label that is not a `String`
  /// is measured as its `ToString` ([jsToString]), as `ctx.measureText` and
  /// the cache key convert it.
  _LabelSizes _computeLabelSizes(
    List<Tick> ticks,
    int length,
    Object? maxTicksLimit,
  ) {
    final ctx = this.ctx;
    final caches = _longestTextCache;
    final widths = <double>[];
    final heights = <double>[];
    final increment = (length / _getTicksLimit(length, maxTicksLimit))
        .floorToDouble();
    var widestLabelSize = 0.0;
    var highestLabelSize = 0.0;
    double i;
    Object? label;
    types.CanvasFontSpec tickFont;
    String? fontString;
    _TextCache cache;
    double lineHeight;
    double width;
    double height;
    Object? nestedLabel;

    for (i = 0; i < length; i += increment) {
      final index = i.toInt();
      label = ticks[index].label;
      tickFont = resolveTickFontOptions(index);
      ctx!.font = fontString = tickFont.string;
      // `caches[fontString]` converts a `null` font string to the key
      // 'null'.
      final key = fontString ?? 'null';
      cache = caches[key] ??= _TextCache();
      lineHeight = jsToNumber(tickFont.lineHeight);
      width = height = 0;
      // Undefined labels and arrays should not be measured
      if (!isNullOrUndef(label) && !isArray(label)) {
        width = measureText(
          ctx,
          cache.data,
          cache.gc,
          width,
          jsToString(label),
        );
        height = lineHeight;
      } else if (isArray(label)) {
        // if it is an array let's measure each element
        final lines = label! as List<Object?>;
        for (var j = 0, jlen = lines.length; j < jlen; ++j) {
          nestedLabel = lines[j];
          // Undefined labels and arrays should not be measured
          if (!isNullOrUndef(nestedLabel) && !isArray(nestedLabel)) {
            width = measureText(
              ctx,
              cache.data,
              cache.gc,
              width,
              jsToString(nestedLabel),
            );
            height += lineHeight;
          }
        }
      }
      widths.add(width);
      heights.add(height);
      widestLabelSize = jsMax(width, widestLabelSize);
      highestLabelSize = jsMax(height, highestLabelSize);
    }
    _garbageCollect(caches, length);

    final widest = widths.indexOf(widestLabelSize);
    final highest = heights.indexOf(highestLabelSize);

    ({double width, double height}) valueAt(int idx) => (
      width: _orZero(_at(widths, idx)),
      height: _orZero(_at(heights, idx)),
    );

    return _LabelSizes(
      valueAt(0),
      valueAt(length - 1),
      valueAt(widest),
      valueAt(highest),
      widths,
      heights,
    );
  }

  /// core.scale.js:877 `getLabelForValue(value)`.
  ///
  /// Used to get the label to display in the tooltip for the given value
  /// @param {*} value
  /// @return {string}
  @override
  Object? getLabelForValue(Object? value) {
    return value;
  }

  /// core.scale.js:888 `getPixelForValue(value, index)`.
  ///
  /// Returns the location of the given data point. Value can either be an
  /// index or a numerical value
  /// The coordinate (0, 0) is at the upper-left corner of the canvas
  /// @param {*} value
  /// @param {number} [index]
  /// @return {number}
  ///
  /// [value] is any JS value (Chart.js ADR 0025).
  @override
  double getPixelForValue(Object? value, [double? index]) {
    // eslint-disable-line no-unused-vars
    return double.nan;
  }

  /// core.scale.js:898 `getValueForPixel(pixel)`.
  ///
  /// Used to get the data value from a given pixel. This is the inverse of
  /// getPixelForValue
  /// The coordinate (0, 0) is at the upper-left corner of the canvas
  /// @param {number} pixel
  /// @return {*}
  ///
  /// Dart `null` stands for the JS `undefined` of the base class.
  @override
  double? getValueForPixel(double pixel) => null;

  /// core.scale.js:906 `getPixelForTick(index)`.
  ///
  /// Returns the location of the tick at the given index
  /// The coordinate (0, 0) is at the upper-left corner of the canvas
  /// @param {number} index
  /// @return {number}
  ///
  /// Dart `null` stands for the JS `null` of an index out of the range.
  @override
  double? getPixelForTick(int index) {
    final ticks = this.ticks!;
    if (index < 0 || index > ticks.length - 1) {
      return null;
    }
    return getPixelForValue(ticks[index].value);
  }

  /// core.scale.js:920 `getPixelForDecimal(decimal)`.
  ///
  /// Utility for getting the pixel location of a percentage of scale
  /// The coordinate (0, 0) is at the upper-left corner of the canvas
  /// @param {number} decimal
  /// @return {number}
  @override
  double getPixelForDecimal(double decimal) {
    if (reversePixels) {
      // Upstream reassigns its parameter.
      // ignore: parameter_assignments
      decimal = 1 - decimal;
    }

    final pixel = startPixel + decimal * length;
    return int16Range(
      jsTruthy(_alignToPixels) ? alignPixel(chart, pixel, 0) : pixel,
    );
  }

  /// core.scale.js:933 `getDecimalForPixel(pixel)`.
  ///
  /// @param {number} pixel
  /// @return {number}
  double getDecimalForPixel(double pixel) {
    final decimal = (pixel - startPixel) / length;
    return reversePixels ? 1 - decimal : decimal;
  }

  /// core.scale.js:943 `getBasePixel()`.
  ///
  /// Returns the pixel for the minimum chart value
  /// The coordinate (0, 0) is at the upper-left corner of the canvas
  /// @return {number}
  @override
  double getBasePixel() {
    return getPixelForValue(getBaseValue());
  }

  /// core.scale.js:950 `getBaseValue()`.
  ///
  /// @return {number}
  @override
  double getBaseValue() {
    final min = this.min;
    final max = this.max;

    return min < 0 && max < 0
        ? max
        : min > 0 && max > 0
        ? min
        : 0;
  }

  /// core.scale.js:961 `getContext(index)`.
  ///
  /// @protected
  ///
  /// Dart `null` for [index] stands for JS `undefined`: the context of the
  /// scale.
  @protected
  ScriptableScaleContext getContext([int? index]) {
    final ticks = this.ticks ?? const <Tick>[];

    if (index != null && index >= 0 && index < ticks.length) {
      final tick = ticks[index];
      return tick.$context ??
          (tick.$context = _createTickContext(getContext(), index, tick));
    }
    return $context ??
        ($context = _createScaleContext(chart.getContext(), this));
  }

  /// core.scale.js:977 `_tickSize()`. core.scale.autoskip.js:51 reads it.
  ///
  /// @return {number}
  /// @private
  ///
  /// `padding` is the raw `autoSkipPadding || 0`. A string padding joins
  /// the label size ([jsAdd]), and the arithmetic after it takes the
  /// [jsToNumber]: `6.673828125 + '3'` gives `'6.6738281253'`.
  @internal
  @override
  double tickSize() {
    final optionTicks = options.ticks;

    // Calculate space needed by label in axis direction.
    final rot = _rotationRadians;
    final cos = jsCos(rot).abs();
    final sin = jsSin(rot).abs();

    final labelSizes = _getLabelSizes();
    final autoSkipPadding = optionTicks.autoSkipPadding;
    final padding = jsTruthy(autoSkipPadding) ? autoSkipPadding : 0.0;
    // A label sizes object is always truthy.
    final w = jsToNumber(jsAdd(labelSizes.widest.width, padding));
    final h = jsToNumber(jsAdd(labelSizes.highest.height, padding));

    // Calculate space needed for 1 tick in axis direction.
    return isHorizontal()
        ? h * cos > w * sin
              ? w / cos
              : h / sin
        : h * sin < w * cos
        ? h / cos
        : w / sin;
  }

  /// core.scale.js:1000 `_isVisible()`.
  ///
  /// @return {boolean}
  /// @private
  bool _isVisible() {
    final display = options.display;

    if (display != 'auto') {
      return jsTruthy(display);
    }

    return getMatchingVisibleMetas().isNotEmpty;
  }

  /// core.scale.js:1013 `_computeGridLineItems(chartArea)`.
  ///
  /// @private
  ///
  /// A position that matches no branch leaves the coordinates JS
  /// `undefined`. They are NaN here.
  ///
  /// `tl` is the raw `tickLength` ([_getTickMarkLength]). `x - tl` takes its
  /// [jsToNumber]. `x + tl` is [jsAdd]: a string `tickLength` joins the
  /// number, for example `this.top + '8'` gives `'4848'` for the top 484.
  /// The canvas call that draws the tick mark applies `ToNumber` to the
  /// coordinate, so the item keeps the [jsToNumber] of the result.
  List<_GridLineItem> _computeGridLineItems(types.ChartArea? chartArea) {
    final axis = this.axis;
    final chart = this.chart;
    final options = this.options;
    final grid = options.grid;
    final position = options.position;
    final border = options.border;
    final offset = grid.offset;
    final isHorizontal = this.isHorizontal();
    final ticks = this.ticks!;
    final ticksLength = ticks.length + (jsTruthy(offset) ? 1 : 0);
    final tl = _getTickMarkLength(grid);
    final items = <_GridLineItem>[];

    final borderOpts = border.setContext(getContext());
    final axisWidth = jsTruthy(borderOpts.display) ? borderOpts.width : 0.0;
    final axisHalfWidth = jsToNumber(axisWidth) / 2;
    // `_alignPixel` tests `width !== 0` and divides the width
    // (helpers.canvas.ts:127). For a number and for `undefined`, the ToNumber
    // of the width gives the same result: `undefined` gives NaN. The type of
    // `border.width` is number (index.d.ts:3056).
    final alignWidth = jsToNumber(axisWidth);
    double alignBorderValue(double pixel) {
      return alignPixel(chart, pixel, alignWidth);
    }

    var borderValue = double.nan;
    double i;
    double? lineValue;
    double alignedLineValue;
    var tx1 = double.nan;
    var ty1 = double.nan;
    var tx2 = double.nan;
    var ty2 = double.nan;
    var x1 = double.nan;
    var y1 = double.nan;
    var x2 = double.nan;
    var y2 = double.nan;

    if (position == 'top') {
      borderValue = alignBorderValue(bottom);
      ty1 = bottom - jsToNumber(tl);
      ty2 = borderValue - axisHalfWidth;
      y1 = alignBorderValue(chartArea!.top) + axisHalfWidth;
      y2 = chartArea.bottom;
    } else if (position == 'bottom') {
      borderValue = alignBorderValue(top);
      y1 = chartArea!.top;
      y2 = alignBorderValue(chartArea.bottom) - axisHalfWidth;
      ty1 = borderValue + axisHalfWidth;
      ty2 = jsToNumber(jsAdd(top, tl));
    } else if (position == 'left') {
      borderValue = alignBorderValue(right);
      tx1 = right - jsToNumber(tl);
      tx2 = borderValue - axisHalfWidth;
      x1 = alignBorderValue(chartArea!.left) + axisHalfWidth;
      x2 = chartArea.right;
    } else if (position == 'right') {
      borderValue = alignBorderValue(left);
      x1 = chartArea!.left;
      x2 = alignBorderValue(chartArea.right) - axisHalfWidth;
      tx1 = borderValue + axisHalfWidth;
      tx2 = jsToNumber(jsAdd(left, tl));
    } else if (axis == 'x') {
      if (position == 'center') {
        borderValue = alignBorderValue(
          (chartArea!.top + chartArea.bottom) / 2 + 0.5,
        );
      } else if (isObject(position)) {
        final (:positionAxisID, :value) = _positionAxis(position);
        borderValue = alignBorderValue(
          chart.scales[positionAxisID]!.getPixelForValue(value),
        );
      }

      y1 = chartArea!.top;
      y2 = chartArea.bottom;
      ty1 = borderValue + axisHalfWidth;
      ty2 = jsToNumber(jsAdd(ty1, tl));
    } else if (axis == 'y') {
      if (position == 'center') {
        borderValue = alignBorderValue(
          (chartArea!.left + chartArea.right) / 2,
        );
      } else if (isObject(position)) {
        final (:positionAxisID, :value) = _positionAxis(position);
        borderValue = alignBorderValue(
          chart.scales[positionAxisID]!.getPixelForValue(value),
        );
      }

      tx1 = borderValue - axisHalfWidth;
      tx2 = tx1 - jsToNumber(tl);
      x1 = chartArea!.left;
      x2 = chartArea.right;
    }

    final limit = valueOrDefault(options.ticks.maxTicksLimit, ticksLength);
    final step = jsMax(1, (ticksLength / jsToNumber(limit)).ceilToDouble());
    // The step is a number: Infinity or NaN for an odd `maxTicksLimit`
    // ends the loop after its first index.
    for (i = 0; i < ticksLength; i += step) {
      final index = i.toInt();
      final context = getContext(index);
      final optsAtIndex = grid.setContext(context);
      final optsAtIndexBorder = border.setContext(context);

      final lineWidth = optsAtIndex.lineWidth;
      final lineColor = optsAtIndex.color;
      final dash = optsAtIndexBorder.dash;
      final borderDash = jsTruthy(dash) ? dash : <Object?>[];
      final borderDashOffset = optsAtIndexBorder.dashOffset;

      final tickWidth = optsAtIndex.tickWidth;
      final tickColor = optsAtIndex.tickColor;
      final tickDash = optsAtIndex.tickBorderDash;
      final tickBorderDash = jsTruthy(tickDash) ? tickDash : <Object?>[];
      final tickBorderDashOffset = optsAtIndex.tickBorderDashOffset;

      lineValue = _getPixelForGridLine(this, index, offset);

      // Skip if the pixel is out of the range
      if (lineValue == null) {
        continue;
      }

      alignedLineValue = alignPixel(chart, lineValue, jsToNumber(lineWidth));

      if (isHorizontal) {
        tx1 = tx2 = x1 = x2 = alignedLineValue;
      } else {
        ty1 = ty2 = y1 = y2 = alignedLineValue;
      }

      items.add(
        _GridLineItem(
          tx1: tx1,
          ty1: ty1,
          tx2: tx2,
          ty2: ty2,
          x1: x1,
          y1: y1,
          x2: x2,
          y2: y2,
          width: lineWidth,
          color: lineColor,
          borderDash: borderDash,
          borderDashOffset: borderDashOffset,
          tickWidth: tickWidth,
          tickColor: tickColor,
          tickBorderDash: tickBorderDash,
          tickBorderDashOffset: tickBorderDashOffset,
        ),
      );
    }

    _ticksLength = ticksLength;
    _borderValue = borderValue;

    return items;
  }

  /// core.scale.js:1147 `_computeLabelItems(chartArea)`.
  ///
  /// @private
  ///
  /// `x`, `y` and `textAlign` keep their values from one tick to the next,
  /// as the `let` variables of upstream do. A coordinate that upstream
  /// leaves `undefined` is NaN.
  ///
  /// Dart `null` for [chartArea] stands for the JS `undefined` of a chart
  /// before its first layout. A branch that reads an edge of it throws a
  /// `TypeError`, as in JavaScript.
  ///
  /// `tl` ([_getTickMarkLength]), `padding` and `labelOffset` are raw option
  /// values. Thus `tickAndPadding`, `x`, `y` and `pixel` are JS values: each
  /// `+` is [jsAdd], and a string operand joins the other operand. Each `-`
  /// takes the [jsToNumber]: with `tickLength` 8 and `padding: '3'`, the
  /// position `'top'` gives `this.bottom - '83'`. The translation of the
  /// item is the [jsToNumber] of `x` and `y`, the values that the canvas
  /// call `translate` takes. Upstream keeps a joined string in the
  /// translation (differences.md row `adapt-scale-option-types`).
  List<types.LabelItem> _computeLabelItems(types.ChartArea? chartArea) {
    final axis = this.axis;
    final options = this.options;
    final position = options.position;
    final optionTicks = options.ticks;
    final isHorizontal = this.isHorizontal();
    final ticks = this.ticks!;
    final align = optionTicks.align;
    final crossAlign = optionTicks.crossAlign;
    final padding = optionTicks.padding;
    final mirror = jsTruthy(optionTicks.mirror);
    final tl = _getTickMarkLength(options.grid);
    final tickAndPadding = jsAdd(tl, padding);
    final hTickAndPadding = mirror ? -jsToNumber(padding) : tickAndPadding;
    final rotation = -_rotationRadians;
    final items = <types.LabelItem>[];
    Tick tick;
    Object? label;
    Object x = double.nan;
    Object y = double.nan;
    String? textAlign;
    Object pixel;
    types.CanvasFontSpec font;
    double lineHeight;
    int lineCount;
    double textOffset;
    var textBaseline = 'middle';

    if (position == 'top') {
      y = bottom - jsToNumber(hTickAndPadding);
      textAlign = _getXAxisLabelAlignment();
    } else if (position == 'bottom') {
      y = jsAdd(top, hTickAndPadding);
      textAlign = _getXAxisLabelAlignment();
    } else if (position == 'left') {
      final ret = _getYAxisLabelAlignment(tl);
      textAlign = ret.textAlign;
      x = ret.x;
    } else if (position == 'right') {
      final ret = _getYAxisLabelAlignment(tl);
      textAlign = ret.textAlign;
      x = ret.x;
    } else if (axis == 'x') {
      if (position == 'center') {
        y = jsAdd((chartArea!.top + chartArea.bottom) / 2, tickAndPadding);
      } else if (isObject(position)) {
        final (:positionAxisID, :value) = _positionAxis(position);
        y = jsAdd(
          chart.scales[positionAxisID]!.getPixelForValue(value),
          tickAndPadding,
        );
      }
      textAlign = _getXAxisLabelAlignment();
    } else if (axis == 'y') {
      if (position == 'center') {
        x =
            ((chartArea!.left + chartArea.right) / 2) -
            jsToNumber(tickAndPadding);
      } else if (isObject(position)) {
        final (:positionAxisID, :value) = _positionAxis(position);
        x = chart.scales[positionAxisID]!.getPixelForValue(value);
      }
      textAlign = _getYAxisLabelAlignment(tl).textAlign;
    }

    if (axis == 'y') {
      if (align == 'start') {
        textBaseline = 'top';
      } else if (align == 'end') {
        textBaseline = 'bottom';
      }
    }

    final labelSizes = _getLabelSizes();
    for (var i = 0, ilen = ticks.length; i < ilen; ++i) {
      tick = ticks[i];
      label = tick.label;

      final optsAtIndex = optionTicks.setContext(getContext(i));
      pixel = jsAdd(getPixelForTick(i), optionTicks.labelOffset);
      font = resolveTickFontOptions(i);
      lineHeight = jsToNumber(font.lineHeight);
      lineCount = isArray(label) ? (label! as List<Object?>).length : 1;
      final halfCount = lineCount / 2;
      final color = optsAtIndex.color;
      final strokeColor = optsAtIndex.textStrokeColor;
      final strokeWidth = optsAtIndex.textStrokeWidth;
      var tickTextAlign = textAlign;

      if (isHorizontal) {
        x = pixel;

        if (textAlign == 'inner') {
          if (i == ilen - 1) {
            tickTextAlign = !jsTruthy(this.options.reverse) ? 'right' : 'left';
          } else if (i == 0) {
            tickTextAlign = !jsTruthy(this.options.reverse) ? 'left' : 'right';
          } else {
            tickTextAlign = 'center';
          }
        }

        if (position == 'top') {
          if (crossAlign == 'near' || rotation != 0) {
            textOffset = -lineCount * lineHeight + lineHeight / 2;
          } else if (crossAlign == 'center') {
            textOffset =
                -labelSizes.highest.height / 2 -
                halfCount * lineHeight +
                lineHeight;
          } else {
            textOffset = -labelSizes.highest.height + lineHeight / 2;
          }
        } else {
          // eslint-disable-next-line no-lonely-if
          if (crossAlign == 'near' || rotation != 0) {
            textOffset = lineHeight / 2;
          } else if (crossAlign == 'center') {
            textOffset = labelSizes.highest.height / 2 - halfCount * lineHeight;
          } else {
            textOffset = labelSizes.highest.height - lineCount * lineHeight;
          }
        }
        if (mirror) {
          textOffset *= -1;
        }
        if (rotation != 0 && !jsTruthy(optsAtIndex.showLabelBackdrop)) {
          // js-ok: a label pixel of getLabelItems (Chart.js ADR 0045)
          x = jsAdd(x, (lineHeight / 2) * math.sin(rotation));
        }
      } else {
        y = pixel;
        textOffset = (1 - lineCount) * lineHeight / 2;
      }

      _LabelBackdrop? backdrop;

      if (jsTruthy(optsAtIndex.showLabelBackdrop)) {
        final labelPadding = toPadding(optsAtIndex.backdropPadding);
        final height = _at(labelSizes.heights, i) ?? double.nan;
        final width = _at(labelSizes.widths, i) ?? double.nan;

        var top = textOffset - labelPadding.top;
        var left = 0 - labelPadding.left;

        switch (textBaseline) {
          case 'middle':
            top -= height / 2;
          case 'bottom':
            top -= height;
          default:
            break;
        }

        switch (textAlign) {
          case 'center':
            left -= width / 2;
          case 'right':
            left -= width;
          case 'inner':
            if (i == ilen - 1) {
              left -= width;
            } else if (i > 0) {
              left -= width / 2;
            }
          default:
            break;
        }

        backdrop = _LabelBackdrop(
          left,
          top,
          width + labelPadding.width,
          height + labelPadding.height,
          optsAtIndex.backdropColor,
        );
      }

      items.add(
        _LabelItem(
          label,
          font,
          textOffset,
          _RenderTextOpts(
            rotation: rotation,
            color: color,
            strokeColor: strokeColor,
            strokeWidth: canvasNumber(strokeWidth),
            textAlign: tickTextAlign,
            textBaseline: textBaseline,
            // DIVERGES(chartjs): adapt-scale-option-types, numbers only.
            translation: (jsToNumber(x), jsToNumber(y)),
            backdrop: backdrop,
          ),
        ),
      );
    }

    return items;
  }

  /// core.scale.js:1331 `_getXAxisLabelAlignment()`.
  String _getXAxisLabelAlignment() {
    final options = this.options;
    final position = options.position;
    final ticks = options.ticks;
    final rotation = -_rotationRadians;

    if (rotation != 0 && !rotation.isNaN) {
      return position == 'top' ? 'left' : 'right';
    }

    var align = 'center';

    final ticksAlign = ticks.align;
    if (ticksAlign == 'start') {
      align = 'left';
    } else if (ticksAlign == 'end') {
      align = 'right';
    } else if (ticksAlign == 'inner') {
      align = 'inner';
    }

    return align;
  }

  /// core.scale.js:1352 `_getYAxisLabelAlignment(tl)`: the object
  /// `{textAlign, x}`, a record. NaN stands for the `undefined` of `x`.
  ///
  /// [tl] ([_getTickMarkLength]) and `padding` are raw option values. Thus
  /// `x` is a JS value: each `+` and `+=` is [jsAdd], and each `-` and `-=`
  /// takes the [jsToNumber]. With `mirror` and `padding: '3'`, the position
  /// `'left'` gives `this.right + '3'`, and `crossAlign: 'center'` then
  /// joins `widest / 2` to that string. The only reader puts `x` in the
  /// translation of the label items, which the canvas call `translate`
  /// converts with `ToNumber`. Thus the record has the [jsToNumber] of `x`.
  ({String textAlign, double x}) _getYAxisLabelAlignment(Object? tl) {
    final options = this.options;
    final position = options.position;
    final ticks = options.ticks;
    final crossAlign = ticks.crossAlign;
    final mirror = ticks.mirror;
    final padding = ticks.padding;
    final labelSizes = _getLabelSizes();
    final tickAndPadding = jsAdd(tl, padding);
    final widest = labelSizes.widest.width;

    String textAlign;
    Object x = double.nan;

    if (position == 'left') {
      if (jsTruthy(mirror)) {
        x = jsAdd(right, padding);

        if (crossAlign == 'near') {
          textAlign = 'left';
        } else if (crossAlign == 'center') {
          textAlign = 'center';
          x = jsAdd(x, widest / 2);
        } else {
          textAlign = 'right';
          x = jsAdd(x, widest);
        }
      } else {
        x = right - jsToNumber(tickAndPadding);

        if (crossAlign == 'near') {
          textAlign = 'right';
        } else if (crossAlign == 'center') {
          textAlign = 'center';
          x = jsToNumber(x) - widest / 2;
        } else {
          textAlign = 'left';
          x = left;
        }
      }
    } else if (position == 'right') {
      if (jsTruthy(mirror)) {
        x = jsAdd(left, padding);

        if (crossAlign == 'near') {
          textAlign = 'right';
        } else if (crossAlign == 'center') {
          textAlign = 'center';
          x = jsToNumber(x) - widest / 2;
        } else {
          textAlign = 'left';
          x = jsToNumber(x) - widest;
        }
      } else {
        x = jsAdd(left, tickAndPadding);

        if (crossAlign == 'near') {
          textAlign = 'left';
        } else if (crossAlign == 'center') {
          textAlign = 'center';
          x = jsAdd(x, widest / 2);
        } else {
          textAlign = 'right';
          x = right;
        }
      }
    } else {
      textAlign = 'right';
    }

    return (textAlign: textAlign, x: jsToNumber(x));
  }

  /// core.scale.js:1423 `_computeLabelArea()`.
  ///
  /// @private
  ///
  /// Dart `null` stands for JS `undefined`.
  _LabelArea? _computeLabelArea() {
    if (jsTruthy(options.ticks.mirror)) {
      return null;
    }

    final chart = this.chart;
    final position = options.position;

    if (position == 'left' || position == 'right') {
      return _LabelArea(0, left, chart.height, right);
    }
    if (position == 'top' || position == 'bottom') {
      return _LabelArea(top, 0, bottom, chart.width);
    }
    return null;
  }

  /// core.scale.js:1441 `drawBackground()`.
  ///
  /// @protected
  @protected
  void drawBackground() {
    final ctx = this.ctx;
    final backgroundColor = options.backgroundColor;
    if (jsTruthy(backgroundColor)) {
      ctx!
        ..save()
        ..fillStyle = canvasStyle(backgroundColor)
        ..fillRect(left, top, width, height)
        ..restore();
    }
  }

  /// core.scale.js:1451 `getLineWidthForValue(value)`.
  ///
  /// [value] is any JS value: controller.bar.js:620 passes the `base`
  /// option. `t.value == value` is the strict compare of core.scale.js:1457
  /// for a `double` tick value: a number of the same value is equal, and a
  /// `String` is not (Chart.js ADR 0025). The result is the `lineWidth`
  /// option as a number.
  @override
  double getLineWidthForValue(Object? value) {
    final grid = options.grid;
    if (!_isVisible() || !jsTruthy(grid.display)) {
      return 0;
    }
    final ticks = this.ticks!;
    final index = ticks.indexWhere((t) => t.value == value);
    if (index >= 0) {
      final opts = grid.setContext(getContext(index));
      return jsToNumber(opts.lineWidth);
    }
    return 0;
  }

  /// core.scale.js:1468 `drawGrid(chartArea)`.
  ///
  /// @protected
  @protected
  void drawGrid([types.ChartArea? chartArea]) {
    final grid = options.grid;
    final ctx = this.ctx;
    final items =
        _gridLineItems ?? (_gridLineItems = _computeGridLineItems(chartArea));

    void drawLine(
      ({double x, double y}) p1,
      ({double x, double y}) p2,
      _LineStyle style,
    ) {
      if (!jsTruthy(style.width) || !jsTruthy(style.color)) {
        return;
      }
      final borderDash = style.borderDash;
      ctx!
        ..save()
        ..lineWidth = canvasNumber(style.width)
        ..strokeStyle = canvasStyle(style.color)
        ..setLineDash(
          canvasLineDash(jsTruthy(borderDash) ? borderDash : <Object?>[]),
        )
        ..lineDashOffset = canvasNumber(style.borderDashOffset)
        ..beginPath()
        ..moveTo(p1.x, p1.y)
        ..lineTo(p2.x, p2.y)
        ..stroke()
        ..restore();
    }

    if (jsTruthy(grid.display)) {
      for (var i = 0, ilen = items.length; i < ilen; ++i) {
        final item = items[i];

        if (jsTruthy(grid.drawOnChartArea)) {
          drawLine((x: item.x1, y: item.y1), (x: item.x2, y: item.y2), item);
        }

        if (jsTruthy(grid.drawTicks)) {
          drawLine(
            (x: item.tx1, y: item.ty1),
            (x: item.tx2, y: item.ty2),
            _LineStyle(
              item.tickWidth,
              item.tickColor,
              item.tickBorderDash,
              item.tickBorderDashOffset,
            ),
          );
        }
      }
    }
  }

  /// core.scale.js:1522 `drawBorder()`.
  ///
  /// @protected
  @protected
  void drawBorder() {
    final chart = this.chart;
    final ctx = this.ctx;
    final options = this.options;
    final border = options.border;
    final grid = options.grid;
    final borderOpts = border.setContext(getContext());
    final axisWidth = jsTruthy(border.display) ? borderOpts.width : 0.0;
    if (!jsTruthy(axisWidth)) {
      return;
    }
    final width = jsToNumber(axisWidth);
    final lastLineWidth = jsToNumber(grid.setContext(getContext(0)).lineWidth);
    final borderValue = _borderValue;
    double x1;
    double x2;
    double y1;
    double y2;

    if (isHorizontal()) {
      x1 = alignPixel(chart, left, width) - width / 2;
      x2 = alignPixel(chart, right, lastLineWidth) + lastLineWidth / 2;
      y1 = y2 = borderValue;
    } else {
      y1 = alignPixel(chart, top, width) - width / 2;
      y2 = alignPixel(chart, bottom, lastLineWidth) + lastLineWidth / 2;
      x1 = x2 = borderValue;
    }
    ctx!
      ..save()
      ..lineWidth = canvasNumber(borderOpts.width)
      ..strokeStyle = canvasStyle(borderOpts.color)
      ..beginPath()
      ..moveTo(x1, y1)
      ..lineTo(x2, y2)
      ..stroke()
      ..restore();
  }

  /// core.scale.js:1557 `drawLabels(chartArea)`.
  ///
  /// @protected
  @protected
  void drawLabels([types.ChartArea? chartArea]) {
    final optionTicks = options.ticks;

    if (!jsTruthy(optionTicks.display)) {
      return;
    }

    final ctx = this.ctx;

    final area = _computeLabelArea();
    if (area != null) {
      clipArea(ctx!, area);
    }

    final items = getLabelItems(chartArea);
    for (final item in items) {
      final renderTextOptions = item.options;
      final tickFont = item.font;
      final label = item.label;
      final y = item.textOffset;
      renderText(ctx!, label, 0, y, tickFont, renderTextOptions);
    }

    if (area != null) {
      unclipArea(ctx!);
    }
  }

  /// core.scale.js:1588 `drawTitle()`.
  ///
  /// @protected
  ///
  /// `index.d.ts:1324` declares a [chartArea] parameter. The upstream body
  /// does not read it.
  @protected
  void drawTitle([types.ChartArea? chartArea]) {
    final ctx = this.ctx;
    final options = this.options;
    final position = options.position;
    final title = options.title;
    final reverse = options.reverse;

    if (!jsTruthy(title.display)) {
      return;
    }

    final font = toFont(title.font);
    final padding = toPadding(title.padding);
    final align = title.align;
    var offset = font.lineHeight / 2;

    if (position == 'bottom' || position == 'center' || isObject(position)) {
      offset += padding.bottom;
      final text = title.text;
      if (isArray(text)) {
        offset += font.lineHeight * ((text! as List<Object?>).length - 1);
      }
    } else {
      offset += padding.top;
    }

    final (:titleX, :titleY, :maxWidth, :rotation) = _titleArgs(
      this,
      offset,
      position,
      align,
    );

    renderText(
      ctx!,
      title.text,
      0,
      0,
      font,
      _RenderTextOpts(
        color: title.color,
        maxWidth: maxWidth,
        rotation: rotation,
        textAlign: _titleAlign(align, position, reverse),
        textBaseline: 'middle',
        translation: (titleX, titleY),
        strokeColor: title.strokeColor,
        strokeWidth: canvasNumber(title.strokeWidth),
      ),
    );
  }

  /// core.scale.js:1623 `draw(chartArea)`: the body. [draw] calls it.
  @override
  void _draw(types.ChartArea? chartArea) {
    if (!_isVisible()) {
      return;
    }

    drawBackground();
    drawGrid(chartArea);
    drawBorder();
    drawTitle();
    drawLabels(chartArea);
  }

  /// core.scale.js:1639 `_layers()`: the body of [layers].
  ///
  /// @return {object[]}
  /// @private
  ///
  /// A layer is the object literal `{z, draw}`, a [types.LayoutLayer]. `z`
  /// is a number. The test of an overridden `draw` compares two tear-offs
  /// (see [_ScalePrototype]).
  List<types.LayoutLayer> _layers() {
    final opts = options;
    final ticks = opts.ticks;
    final grid = opts.grid;
    final border = opts.border;
    final tz = jsOrZero(jsTruthy(ticks.raw) ? ticks.z : ticks.raw);
    final gz = jsToNumber(
      valueOrDefault<Object?>(jsTruthy(grid.raw) ? grid.z : grid.raw, -1.0),
    );
    final bz = jsToNumber(
      valueOrDefault<Object?>(
        jsTruthy(border.raw) ? border.z : border.raw,
        0.0,
      ),
    );

    if (!_isVisible() || draw != super.draw) {
      // backward compatibility: draw has been overridden by custom scale
      // The arrow functions call the methods: tear-offs, as Dart cannot
      // replace a method.
      return [_ScaleLayer(tz, draw)];
    }

    return [
      _ScaleLayer(gz, (chartArea) {
        drawBackground();
        drawGrid(chartArea);
        drawTitle();
      }),
      _ScaleLayer(bz, (chartArea) {
        drawBorder();
      }),
      _ScaleLayer(tz, drawLabels),
    ];
  }

  /// core.scale.js:1680 `getMatchingVisibleMetas(type)`.
  ///
  /// Returns visible dataset metas that are attached to this scale
  /// @param {string} [type] - if specified, also filter by dataset type
  /// @return {object[]}
  ///
  /// `meta[this.axis + 'AxisID']` reads `xAxisID`, `yAxisID` or `rAxisID`.
  /// `core.config` gives each scale one of these three axes. Another axis
  /// names no property of a meta: JavaScript reads `undefined`, which equals
  /// no scale id.
  @override
  List<types.ChartMeta> getMatchingVisibleMetas([String? type]) {
    final metas = chart.getSortedVisibleDatasetMetas();
    final axis = this.axis;
    final result = <types.ChartMeta>[];

    for (var i = 0, ilen = metas.length; i < ilen; ++i) {
      final meta = metas[i];
      final axisID = switch (axis) {
        'x' => meta.xAxisID,
        'y' => meta.yAxisID,
        'r' => meta.rAxisID,
        _ => null,
      };
      if (axisID == id && (type == null || type.isEmpty || meta.type == type)) {
        result.add(meta);
      }
    }
    return result;
  }

  /// core.scale.js:1700 `_resolveTickFontOptions(index)`.
  /// scale.linear.js:39 and scale.time.js:597 read it.
  ///
  /// @param {number} index
  /// @return {object}
  /// @protected
  @internal
  types.CanvasFontSpec resolveTickFontOptions(int index) {
    final opts = options.ticks.setContext(getContext(index));
    return toFont(opts.font);
  }

  /// core.scale.js:1708 `_maxDigits()`. scale.linearbase.js:263 reads it.
  ///
  /// @protected
  @internal
  double maxDigits() {
    final fontSize = jsToNumber(resolveTickFontOptions(0).lineHeight);
    return (isHorizontal() ? width : height) / fontSize;
  }
}

/// The `cfg` argument of the `construct` closure of [Scale.jsClass] and of a
/// subclass: the first argument, a Map.
///
/// An absent argument, [undefined] and another value throw a `TypeError`.
/// JavaScript throws for `undefined` and `null` at `cfg.id`
/// (core.scale.js:175). It reads `undefined` members from another value
/// (row `adapt-component-class-role`).
AnyObject scaleCfgArg(List<Object?> args) {
  final cfg = args.isEmpty ? undefined : args[0];
  return switch (cfg) {
    final AnyObject map => map,
    // A JavaScript TypeError: the read `cfg.id` of undefined or null.
    _ => throw TypeError(),
  };
}

/// `value || 0` of a number that is NaN for JS `undefined`.
double _orZero(double? value) =>
    value == null || value.isNaN || value == 0 ? 0 : value;

/// The JS read `arr[idx]` of a list of numbers: Dart `null` for an index out
/// of the range, JS `undefined`.
double? _at(List<double> arr, int idx) =>
    idx >= 0 && idx < arr.length ? arr[idx] : null;
