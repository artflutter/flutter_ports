// Original code, not ported from Chart.js: frozen CSS color reference decoding.

/// Only upstream/reference tests decode CSS. The production Color constructor
/// rejects strings and charts accept native Flutter Color values.
library;

import 'dart:ui' as ui;

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

/// The paint of the CSS color text [value], or Dart `null` for a text that
/// is no color: the conversion of a color option of `nativeFixtureColors`.
ChartPaint? paintOfCss(String value) {
  final parsed = referenceColor(value);
  if (!parsed.valid) return null;
  final rgb = parsed.rgbaBytes!;
  return ChartPaint.solid(
    ui.Color.fromRGBO(rgb.r.round(), rgb.g.round(), rgb.b.round(), rgb.a / 255),
  );
}

/// The native paint of the upstream color text [value] of a fixture or a
/// reference config, as `nativeFixtureColors` gives it for a color option.
/// A split fill (`FillTarget.split`, Chart.js ADR 0140) holds its colors in
/// a native object, which the walk of `nativeFixtureColors` does not enter.
/// Throws an [ArgumentError] for a text that is no color.
ChartPaint nativeFixturePaint(String value) =>
    paintOfCss(value) ??
    (throw ArgumentError.value(value, 'value', 'no CSS color'));
