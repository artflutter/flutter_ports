// Ported from Chart.js v4.6.1 src/helpers/helpers.color.ts (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color values.

/// Port of `src/helpers/helpers.color.ts`.
///
/// Solid option colors are native Flutter colors
/// (Chart.js ADR 0057). The canvas layer also supports [ChartGradient] and
/// [ChartPattern]. CSS strings are rejected.
library;

import 'dart:ui' as ui;

import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/types/chart_paint.dart';
import 'package:flutter_kurkle_color_port/flutter_kurkle_color_port.dart';

/// helpers.color.ts:3 `isPatternOrGradient`.
///
/// Upstream tests the `toString()` tag of a DOM object:
/// `'[object CanvasPattern]'` or `'[object CanvasGradient]'`. In the port,
/// a gradient is a [ChartGradient] and a pattern is a [ChartPattern], and
/// both are a [ChartShaderPaint] (`lib/src/types/chart_paint.dart`). Thus
/// the port tests the type.
bool isPatternOrGradient(Object? value) {
  // DIVERGES(chartjs): platform-color-brand, a Dart type test.
  return value is ChartShaderPaint;
}

/// helpers.color.ts:21 `color`.
///
/// Returns a [ChartGradient] or [ChartPattern] unchanged. Else returns the
/// Flutter color of [input], whose [KurkleColor] methods are the methods of
/// the upstream `Color` (Chart.js ADR 0171). As in JavaScript, a JS `null`
/// [input] (Dart `null`) throws.
Object color(Object? input) {
  if (isPatternOrGradient(input)) return input!;
  final value = input is SolidChartPaint ? input.color : input;
  if (value is! ui.Color) {
    throw ArgumentError.value(value, 'color', 'Expected Flutter Color');
  }
  return value;
}

/// helpers.color.ts:28 `getHoverColor`.
///
/// Returns a [ChartGradient] or [ChartPattern] unchanged. Else returns the
/// native color of [value], saturated by 0.5 and darkened by 0.1. An absent
/// value returns null. Strings and other non-color inputs throw (ADR 0057).
Object? getHoverColor(Object? value) {
  if (value is Undefined) return null;
  if (isPatternOrGradient(value)) return value;
  return ChartPaint.solid((color(value) as ui.Color).saturate(0.5).darken(0.1));
}
