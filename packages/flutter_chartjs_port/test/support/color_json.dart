// Original code, not ported from Chart.js: color reference normalization.

/// Compare the color channels of native values against frozen upstream CSS
/// output. This is test/reference decoding, never a production input adapter.
library;

import 'dart:convert';
import 'dart:ui' as ui;

import 'package:chartjs_test_utils/pure.dart' show referenceColor;
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/kurkle_color/index.esm.dart' as legacy;
import 'package:flutter_chartjs_port/src/types/chart_paint.dart';
import 'package:test/test.dart';

/// RGBA bytes of a numerical/native color, or null for a non-color value.
List<int>? nativeColorBytes(Object? input) {
  final value = input is SolidChartPaint ? input.color : input;
  if (value is! ui.Color) return null;
  final color = value.withValues(colorSpace: ui.ColorSpace.extendedSRGB);
  return [
    (color.r * 255).round().clamp(0, 255),
    (color.g * 255).round().clamp(0, 255),
    (color.b * 255).round().clamp(0, 255),
    (color.a.clamp(0.0, 1.0) * 255).round(),
  ];
}

bool _key(String? key) =>
    key != null &&
    (key == 'color' ||
        key.endsWith('Color') ||
        key.endsWith('Colors') ||
        key == 'fillStyle' ||
        key == 'strokeStyle' ||
        key == 'multiKeyBackground');

/// Normalizes only color leaves. Non-color strings, object order and geometry
/// remain unchanged. The empty default text-stroke color becomes transparent.
Object? canonicalColors(Object? value, [String? key]) {
  final native = nativeColorBytes(value);
  if (native != null) return native;
  if (value is String && _key(key)) {
    if (value.isEmpty && key == 'textStrokeColor') return [0, 0, 0, 0];
    final color = referenceColor(value);
    if (color.valid) {
      final rgb = color.rgb!;
      return [
        rgb.r.round(),
        rgb.g.round(),
        rgb.b.round(),
        (rgb.a * 255).round(),
      ];
    }
  }
  if (value is List) {
    return [for (final item in value) canonicalColors(item, key)];
  }
  if (value is Map<String, Object?>) {
    return <String, Object?>{
      for (final entry in value.entries)
        entry.key: canonicalColors(entry.value, entry.key),
    };
  }
  if (value is JsObjectFace) {
    return <String, Object?>{
      for (final name in value.jsKeys())
        name: canonicalColors(value.jsRead(name), name),
    };
  }
  return value;
}

/// A frozen CSS scalar accepts its corresponding native Color, while ordinary
/// strings still compare exactly. Other object types are never coerced.
Matcher referenceColorOrString(String expected) => predicate<Object?>((actual) {
  if (actual is String) return actual == expected;
  final bytes = nativeColorBytes(actual);
  if (bytes == null) return false;
  if (expected.isEmpty) return bytes.every((byte) => byte == 0);
  final parsed = referenceColor(expected);
  if (!parsed.valid) return false;
  final rgb = parsed.rgb!;
  final wanted = [
    rgb.r.round(),
    rgb.g.round(),
    rgb.b.round(),
    (rgb.a * 255).round(),
  ];
  for (var i = 0; i < 4; i++) {
    if (bytes[i] != wanted[i]) return false;
  }
  return true;
}, 'reference string or native color $expected');

/// Canonicalizes one scalar/JSON line from a frozen upstream observation.
String referenceColorText(String text) {
  try {
    final decoded = jsonDecode(text);
    return jsonEncode(
      canonicalColors(decoded, decoded is List ? 'color' : null),
    );
  } on FormatException {
    final value = canonicalColors(text, 'color');
    return value is String ? value : jsonEncode(value);
  }
}

/// Parses only legacy reference data; native production values are converted
/// numerically, without sending Flutter Color objects to the old string parser.
legacy.Color referenceParsedColor(Object? value) =>
    referenceColor(value is SolidChartPaint ? value.color : value);

/// JSON/probe text with CSS scalar values normalized to RGBA bytes. Keys and
/// Other values keep their spelling; runtime values are untouched.
String referenceColorTokens(String text) {
  final source = text.replaceAll(
    '"textStrokeColor":""',
    '"textStrokeColor":[0,0,0,0]',
  );
  return source.replaceAllMapped(RegExp(r'"(?:\\.|[^"\\])*"'), (match) {
    if (source.substring(match.end).trimLeft().startsWith(':')) {
      return match[0]!;
    }
    final value = jsonDecode(match[0]!) as String;
    final parsed = referenceColor(value);
    if (!parsed.valid) return match[0]!;
    final rgb = parsed.rgb!;
    return jsonEncode([
      rgb.r.round(),
      rgb.g.round(),
      rgb.b.round(),
      (rgb.a * 255).round(),
    ]);
  });
}

/// Converts a supported frozen color input to the numerical/native contract.
/// Unsupported values stay unchanged so tests can assert their rejection.
Object? referenceColorInput(Object? value) {
  if (value is ui.Color) return ChartPaint.solid(value);
  if (value == null || value is ChartPaint || nativeColorBytes(value) != null) {
    return value;
  }
  if (value is! String &&
      value is! Map &&
      value is! List &&
      value is! legacy.RGBA) {
    return value;
  }
  final parsed = referenceColor(value);
  final rgba = parsed.rgbaBytes;
  if (rgba == null ||
      ![rgba.r, rgba.g, rgba.b, rgba.a].every((v) => v.isFinite)) {
    return value;
  }
  if (rgba.r < 0 ||
      rgba.r > 255 ||
      rgba.g < 0 ||
      rgba.g > 255 ||
      rgba.b < 0 ||
      rgba.b > 255 ||
      rgba.a < 0 ||
      rgba.a > 255) {
    return value;
  }
  if (rgba.r != rgba.r.roundToDouble() ||
      rgba.g != rgba.g.roundToDouble() ||
      rgba.b != rgba.b.roundToDouble()) {
    return value;
  }
  return ChartPaint.solid(
    ui.Color.fromRGBO(
      rgba.r.round(),
      rgba.g.round(),
      rgba.b.round(),
      rgba.a / 255,
    ),
  );
}

/// Whether a frozen string names a color value rather than a drawing opcode.
bool isReferenceColor(String value) =>
    value.isEmpty || referenceColor(value).valid;

/// The native color of a paint for frozen pre-migration observations only.
Object? referencePaintValue(ChartPaint paint) => switch (paint) {
  SolidChartPaint(:final color) => color,
  UnchangedChartPaint() => null,
  _ => paint,
};

/// Paint leaves of a frozen upstream element option object.
Map<String, Object?> referencePaintOptions(Map<String, Object?> options) => {
  for (final entry in options.entries)
    entry.key: entry.key == 'color' || entry.key.endsWith('Color')
        ? referenceColorInput(entry.value)
        : entry.value,
};
