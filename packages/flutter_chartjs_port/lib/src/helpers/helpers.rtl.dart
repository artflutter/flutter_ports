// Ported from Chart.js v4.6.1 src/helpers/helpers.rtl.ts (MIT, Chart.js Contributors).

/// Port of `src/helpers/helpers.rtl.ts`.
///
/// Text direction is a native canvas value. An override returns the previous
/// direction, which the caller restores after drawing. A null canvas
/// direction inherits the element style (Chart.js ADR 0124).
/// This file stays a pure layer.
library;

import 'dart:ui' show TextAlign, TextDirection;

import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';

/// helpers.rtl.ts:1 `RTLAdapter`.
///
/// [textAlign] takes and returns an `Object?`, not a String. Upstream declares
/// `'center' | 'left' | 'right'`, but `plugin.legend.js:370` passes
/// `legendItem.textAlign`, which can be `undefined`, and `plugin.tooltip.js`
/// passes resolved option values (Chart.js ADR 0043).
abstract interface class RTLAdapter {
  /// helpers.rtl.ts:2 `x`.
  double x(double x);

  /// helpers.rtl.ts:3 `setWidth`.
  void setWidth(double w);

  /// helpers.rtl.ts:4 `textAlign`: the Flutter [TextAlign] (row
  /// `adapt-flutter-text-align`). Dart `null` stands for the `undefined` of
  /// a legend item without an align.
  TextAlign? textAlign(TextAlign? align);

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
  // DIVERGES(chartjs): adapt-flutter-text-align, the Flutter enum.
  @override
  TextAlign? textAlign(TextAlign? align) {
    if (align == TextAlign.center) {
      return align;
    }
    return align == TextAlign.right ? TextAlign.left : TextAlign.right;
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
  TextAlign? textAlign(TextAlign? align) {
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
/// which is [jsTruthy] (Chart.js ADR 0045).
RTLAdapter getRtlAdapter(Object? rtl, double rectX, double width) {
  return jsTruthy(rtl)
      ? _getRightToLeftAdapter(rectX, width)
      : _getLeftToRightAdapter();
}

/// helpers.rtl.ts:55 `overrideTextDirection`.
///
/// Applies the optional native [direction] and returns the previous canvas
/// direction. A null option leaves the canvas unchanged. A null return value
/// means that the previous canvas direction inherited the element style.
// DIVERGES(chartjs): adapt-text-direction, native state instead of CSS writes.
TextDirection? overrideTextDirection(
  CanvasRenderingContext2D ctx,
  TextDirection? direction,
) {
  final original = ctx.direction;
  if (direction != null) ctx.direction = direction;
  return original;
}

/// helpers.rtl.ts:69 `restoreTextDirection`.
///
/// Restores the value returned by [overrideTextDirection], including null
/// for inheritance. Callers use a finally block, so a failed draw restores
/// the previous direction too. No style property or priority is changed.
// DIVERGES(chartjs): adapt-text-direction, restore the saved native value.
void restoreTextDirection(
  CanvasRenderingContext2D ctx,
  TextDirection? original,
) {
  ctx.direction = original;
}
