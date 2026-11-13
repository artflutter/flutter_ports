// Original code, not ported from Chart.js: frozen CSS color reference decoding.

/// Only upstream/reference tests decode CSS. The production Color constructor
/// rejects strings and charts accept native Flutter Color values.
library;

import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/kurkle_color/index.esm.dart' as legacy;
// The test harness decodes frozen upstream input through internal primitives.
// ignore_for_file: implementation_imports
import 'package:flutter_chartjs_port/src/types/chart_paint.dart';

legacy.RGBA? _function(String value) =>
    value.isNotEmpty && value.codeUnitAt(0) == 114
    ? legacy.rgbParse(value)
    : legacy.hueParse(value);

/// Reconstructs the old parser's numerical input for frozen upstream probes.
/// Non-string inputs keep the numerical Color constructor's behavior.
legacy.Color referenceColor(Object? input) {
  final value = input is SolidChartPaint ? input.color : input;
  if (value is! String) return legacy.Color(value);
  final legacy.RGBA? rgba;
  if (value.startsWith('#')) {
    rgba = legacy.hexParse(value);
  } else if (value.endsWith(')')) {
    rgba = _function(value);
  } else {
    rgba = legacy.nameParse(value) ?? _function(value);
  }
  return rgba == null
      ? legacy.Color(undefined)
      : legacy.Color.fromRgbaBytes(rgba);
}
