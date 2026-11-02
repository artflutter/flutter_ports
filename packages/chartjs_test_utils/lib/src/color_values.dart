// Original code, not ported from Chart.js: native color value comparisons.

import 'dart:ui' as ui;

/// Color value equality, or null when neither operand is a native color.
/// Other objects keep their JavaScript identity semantics in the test matchers.
bool? equalColorValues(Object? a, Object? b) {
  if (a is! ui.Color && b is! ui.Color) return null;
  return a is ui.Color && b is ui.Color && a == b;
}
