// Ported from Chart.js v4.6.1 src/helpers/helpers.color.ts (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color values.

/// Port of `src/helpers/helpers.color.ts`.
///
/// Solid option colors are native Flutter colors
/// (Chart.js ADR 0057). The canvas layer also supports [CanvasGradient] and
/// [CanvasPattern]. CSS strings are rejected.
library;

import 'dart:ui' as ui;

import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/kurkle_color/index.esm.dart'
    show Color;
import 'package:flutter_chartjs_port/src/types/color.dart';

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
  if (isPatternOrGradient(value)) return value!;
  if (value is! ui.Color) {
    throw ArgumentError.value(value, 'color', 'Expected Flutter Color');
  }
  return Color(value);
}

/// helpers.color.ts:28 `getHoverColor`.
///
/// Returns a [CanvasGradient] or [CanvasPattern] unchanged. Else returns the
/// native color of [value], saturated by 0.5 and darkened by 0.1. An absent
/// value returns null. Strings and other non-color inputs throw (ADR 0057).
Object? getHoverColor(Object? value) {
  if (value is Undefined) return null;
  if (isPatternOrGradient(value)) return value;
  final hovered = (color(value) as Color).saturate(0.5).darken(0.1);
  final rgb = hovered.rgbaBytes!;
  return ui.Color.fromRGBO(
    // js-ok: color arithmetic produces finite non-negative byte channels.
    rgb.r.round(),
    // js-ok: color arithmetic produces finite non-negative byte channels.
    rgb.g.round(),
    // js-ok: color arithmetic produces finite non-negative byte channels.
    rgb.b.round(),
    rgb.a / 255,
  );
}
