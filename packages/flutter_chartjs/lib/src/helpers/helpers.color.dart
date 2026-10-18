// Ported from Chart.js v4.5.1 src/helpers/helpers.color.ts (MIT, Chart.js Contributors).

/// Port of `src/helpers/helpers.color.ts`.
///
/// The color values are option values (Chart.js ADR 0006): a CSS color
/// `String`, an RGBA object (`Map`), a `List`, or a [CanvasGradient] or
/// [CanvasPattern] of the canvas layer.
library;

import 'package:flutter_chartjs/src/kurkle_color/index.esm.dart' show Color;
import 'package:flutter_chartjs/src/types/color.dart';

/// helpers.color.ts:3 `isPatternOrGradient`.
///
/// Upstream tests the `toString()` tag of a DOM object:
/// `'[object CanvasPattern]'` or `'[object CanvasGradient]'`. In the port,
/// the canvas layer implements the interfaces [CanvasPattern] and
/// [CanvasGradient] (`lib/src/types/color.dart`). Thus the port tests the
/// type.
bool isPatternOrGradient(Object? value) {
  // DIVERGES(chartjs): platform-color-brand, a Dart type test.
  return value is CanvasPattern || value is CanvasGradient;
}

/// helpers.color.ts:21 `color`.
///
/// Returns a [CanvasGradient] or [CanvasPattern] unchanged. Else returns a
/// [Color] of [value]. As in JavaScript, a JS `null` [value] (Dart `null`)
/// throws.
Object color(Object? value) {
  return isPatternOrGradient(value) ? value! : Color(value);
}

/// helpers.color.ts:28 `getHoverColor`.
///
/// Returns a [CanvasGradient] or [CanvasPattern] unchanged. Else returns the
/// hex string of [value], saturated by 0.5 and darkened by 0.1. Dart `null`
/// stands for the JS `undefined` result of a [value] that does not parse. As
/// in JavaScript, a JS `null` [value] (Dart `null`) throws.
Object? getHoverColor(Object? value) {
  return isPatternOrGradient(value)
      ? value
      : Color(value).saturate(0.5).darken(0.1).hexString();
}
