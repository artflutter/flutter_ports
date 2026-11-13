// Original code, not ported from Chart.js: native color value comparisons.

import 'dart:ui' as ui;

// The pure harness consumes paint value types without importing widgets.
// ignore: implementation_imports
import 'package:flutter_chartjs_port/src/types/chart_paint.dart'
    show SolidChartPaint;

/// Color value equality, or null when neither operand is a native color.
/// Other objects keep their JavaScript identity semantics in the test matchers.
bool? equalColorValues(Object? left, Object? right) {
  final a = left is SolidChartPaint ? left.color : left;
  final b = right is SolidChartPaint ? right.color : right;
  if (a is! ui.Color && b is! ui.Color) return null;
  return a is ui.Color && b is ui.Color && a == b;
}
