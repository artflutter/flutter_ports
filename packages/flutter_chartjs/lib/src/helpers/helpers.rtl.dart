// Ported from Chart.js v4.5.1 src/helpers/helpers.rtl.ts (MIT, Chart.js Contributors).

/// Port of `src/helpers/helpers.rtl.ts`.
///
/// [overrideTextDirection] and [restoreTextDirection] read and write the
/// `direction` property of `ctx.canvas.style`, a [CSSStyleDeclaration] of
/// the canvas layer (`lib/src/canvas/canvas.dart`). The `dart:ui` context
/// reads that property when its `direction` is `'inherit'`, as the DOM does.
/// This file stays a pure layer.
library;

import 'package:flutter_chartjs/src/canvas/canvas.dart';
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_object.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';

/// helpers.rtl.ts:1 `RTLAdapter`.
///
/// [textAlign] takes and returns an `Object?`, not a String. Upstream declares
/// `'center' | 'left' | 'right'`, but `plugin.legend.js:370` passes
/// `legendItem.textAlign`, which can be `undefined`, and `plugin.tooltip.js`
/// passes resolved option values (Chart.js ADR 0006).
abstract interface class RTLAdapter {
  /// helpers.rtl.ts:2 `x`.
  double x(double x);

  /// helpers.rtl.ts:3 `setWidth`.
  void setWidth(double w);

  /// helpers.rtl.ts:4 `textAlign`.
  Object? textAlign(Object? align);

  /// helpers.rtl.ts:5 `xPlus`.
  double xPlus(double x, double value);

  /// helpers.rtl.ts:6 `leftForLtr`.
  double leftForLtr(double x, double itemWidth);
}

/// helpers.rtl.ts:10 the object literal of `getRightToLeftAdapter`.
///
/// The object methods close over the parameters `rectX` and `width` of
/// `getRightToLeftAdapter`. Here they are fields. `setWidth` writes [_width],
/// as upstream writes the parameter `width`.
final class _RightToLeftAdapter implements RTLAdapter {
  _RightToLeftAdapter(this._rectX, this._width);

  final double _rectX;

  double _width;

  /// helpers.rtl.ts:11 `x`.
  @override
  double x(double x) {
    return _rectX + _rectX + _width - x;
  }

  /// helpers.rtl.ts:14 `setWidth`.
  @override
  void setWidth(double w) {
    _width = w;
  }

  /// helpers.rtl.ts:17 `textAlign`.
  @override
  Object? textAlign(Object? align) {
    if (align == 'center') {
      return align;
    }
    return align == 'right' ? 'left' : 'right';
  }

  /// helpers.rtl.ts:23 `xPlus`.
  @override
  double xPlus(double x, double value) {
    return x - value;
  }

  /// helpers.rtl.ts:26 `leftForLtr`.
  @override
  double leftForLtr(double x, double itemWidth) {
    return x - itemWidth;
  }
}

/// helpers.rtl.ts:9 `getRightToLeftAdapter`.
RTLAdapter _getRightToLeftAdapter(double rectX, double width) {
  return _RightToLeftAdapter(rectX, width);
}

/// helpers.rtl.ts:33 the object literal of `getLeftToRightAdapter`.
final class _LeftToRightAdapter implements RTLAdapter {
  const _LeftToRightAdapter();

  /// helpers.rtl.ts:34 `x`.
  @override
  double x(double x) {
    return x;
  }

  /// helpers.rtl.ts:37 `setWidth`.
  @override
  void setWidth(double w) {}

  /// helpers.rtl.ts:39 `textAlign`.
  @override
  Object? textAlign(Object? align) {
    return align;
  }

  /// helpers.rtl.ts:42 `xPlus`.
  @override
  double xPlus(double x, double value) {
    return x + value;
  }

  /// helpers.rtl.ts:45 `leftForLtr`.
  @override
  double leftForLtr(double x, double itemWidth) {
    return x;
  }
}

/// helpers.rtl.ts:32 `getLeftToRightAdapter`.
RTLAdapter _getLeftToRightAdapter() {
  return const _LeftToRightAdapter();
}

/// helpers.rtl.ts:51 `getRtlAdapter`.
///
/// Returns the right-to-left adapter of the rectangle at [rectX] with the
/// width [width] when [rtl] is truthy, else the left-to-right adapter.
///
/// [rtl] is an `Object?`, not a bool. Upstream declares `boolean`, but
/// `plugin.tooltip.js:762` passes `options.rtl`, which has no default and
/// thus can be `undefined`. The conditional `rtl ? … : …` applies ToBoolean,
/// which is [jsTruthy] (Chart.js ADR 0010).
RTLAdapter getRtlAdapter(Object? rtl, double rectX, double width) {
  return jsTruthy(rtl)
      ? _getRightToLeftAdapter(rectX, width)
      : _getLeftToRightAdapter();
}

/// The property `prevTextDirection` that [overrideTextDirection] writes on
/// the context (helpers.rtl.ts:65) and [restoreTextDirection] deletes
/// (:71).
///
/// Upstream adds the property to the context object. A Dart object has no
/// such property, so an [Expando] attaches the value. The value is the JS
/// array `[value, priority]`, a `List<String>` (Chart.js ADR 0006).
final Expando<List<String>> _prevTextDirection = Expando<List<String>>(
  'prevTextDirection',
);

/// The `prevTextDirection` property of [ctx], or `null` when [ctx] has none
/// (JS `undefined`). Upstream reads it nowhere. Tests read it.
List<String>? prevTextDirectionOf(CanvasRenderingContext2D ctx) =>
    _prevTextDirection[ctx];

/// helpers.rtl.ts:55 `overrideTextDirection`.
///
/// [direction] is an `Object?`, not a String: upstream declares
/// `'ltr' | 'rtl'`, but `plugin.legend.js:391` and `plugin.tooltip.js:1074`
/// pass the `textDirection` option, which can be `undefined`. A value other
/// than `'ltr'` and `'rtl'` does nothing.
void overrideTextDirection(CanvasRenderingContext2D ctx, Object? direction) {
  CSSStyleDeclaration style;
  List<String> original;
  if (direction == 'ltr' || direction == 'rtl') {
    style = ctx.canvas.style;
    original = [
      style.getPropertyValue('direction'),
      style.getPropertyPriority('direction'),
    ];

    style.setProperty('direction', direction! as String, 'important');
    _prevTextDirection[ctx] = original;
  }
}

/// helpers.rtl.ts:69 `restoreTextDirection`.
///
/// Upstream declares [original] as `[string, string]`, the
/// `[value, priority]` of [overrideTextDirection]. Its callers pass the
/// `textDirection` option instead (`plugin.legend.js:437`,
/// `plugin.tooltip.js:1087`): `undefined`, or a String such as `'rtl'`.
/// Thus [original] is an `Object?`, and `original[0]` and `original[1]` are
/// [jsGet] reads: for `'rtl'`, they give `'r'` and `'t'`. The DOM ignores a
/// call of `setProperty` with the priority `'t'`, so the call leaves the
/// style as [overrideTextDirection] set it, as in the browser.
///
/// The absent argument is [undefined], which does nothing. JS `null`
/// (Dart `null`) throws a `TypeError` at `original[0]`, as upstream.
///
/// The DOM converts the two values with `ToString`
/// (`[LegacyNullToEmptyString] CSSOMString`): `null` gives `''` and
/// `undefined` gives `'undefined'` for the value, and an `undefined`
/// priority is the default `''`.
void restoreTextDirection(
  CanvasRenderingContext2D ctx, [
  Object? original = undefined,
]) {
  if (!identical(original, undefined)) {
    _prevTextDirection[ctx] = null;
    final value = jsGet(original, 0);
    final priority = jsGet(original, 1);
    ctx.canvas.style.setProperty(
      'direction',
      value == null ? '' : jsToString(value),
      priority == null || identical(priority, undefined)
          ? ''
          : jsToString(priority),
    );
  }
}
